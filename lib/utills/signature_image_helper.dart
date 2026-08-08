import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app_colors.dart';

enum SignaturePickResultType {
  success,
  cancelled,
  permissionDenied,
  permanentlyDenied,
  empty,
  failed,
}

class SignaturePickResult {
  const SignaturePickResult._({
    required this.type,
    this.bytes,
    this.fileName,
    this.message,
  });

  final SignaturePickResultType type;
  final Uint8List? bytes;
  final String? fileName;
  final String? message;

  bool get isSuccess =>
      type == SignaturePickResultType.success && bytes != null;

  factory SignaturePickResult.success({
    required Uint8List bytes,
    required String fileName,
  }) {
    return SignaturePickResult._(
      type: SignaturePickResultType.success,
      bytes: bytes,
      fileName: fileName,
    );
  }

  factory SignaturePickResult.cancelled() {
    return const SignaturePickResult._(type: SignaturePickResultType.cancelled);
  }

  factory SignaturePickResult.permissionDenied({
    required bool permanentlyDenied,
    required String message,
  }) {
    return SignaturePickResult._(
      type: permanentlyDenied
          ? SignaturePickResultType.permanentlyDenied
          : SignaturePickResultType.permissionDenied,
      message: message,
    );
  }

  factory SignaturePickResult.empty() {
    return const SignaturePickResult._(
      type: SignaturePickResultType.empty,
      message: 'Selected image is empty',
    );
  }

  factory SignaturePickResult.failed([String? message]) {
    return SignaturePickResult._(
      type: SignaturePickResultType.failed,
      message: message ?? 'Unable to pick image. Please try again.',
    );
  }
}

class SignatureImageHelper {
  SignatureImageHelper({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  /// Request camera/photos permission before opening picker.
  Future<SignaturePickResult?> ensurePermission(ImageSource source) {
    return _ensurePermission(source);
  }

  Future<SignaturePickResult> pickCroppedSignature(
    ImageSource source, {
    bool permissionAlreadyGranted = false,
  }) async {
    try {
      if (!permissionAlreadyGranted) {
        final permission = await _ensurePermission(source);
        if (permission != null) return permission;
      }

      // After first-time system permission dialog, wait so camera/gallery
      // can present without lag / missed open.
      await _waitForPickerReady();

      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 95,
      );
      if (picked == null) return SignaturePickResult.cancelled();

      final croppedPath = await _cropImage(picked.path);
      if (croppedPath == null) return SignaturePickResult.cancelled();

      final bytes = await File(croppedPath).readAsBytes();
      if (bytes.isEmpty) return SignaturePickResult.empty();

      final name = croppedPath.split(Platform.pathSeparator).last;
      return SignaturePickResult.success(
        bytes: bytes,
        fileName: name.isNotEmpty ? name : 'signature.png',
      );
    } catch (error) {
      debugPrint('Signature pick/crop ERROR: $error');
      return SignaturePickResult.failed();
    }
  }

  Future<void> _waitForPickerReady() async {
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 350));
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<SignaturePickResult?> _ensurePermission(ImageSource source) async {
    if (kIsWeb) return null;

    if (source == ImageSource.camera) {
      var status = await Permission.camera.status;
      if (!status.isGranted && !status.isLimited) {
        status = await Permission.camera.request();
      }
      if (status.isGranted || status.isLimited) return null;
      return SignaturePickResult.permissionDenied(
        permanentlyDenied: status.isPermanentlyDenied,
        message: status.isPermanentlyDenied
            ? 'Camera permission is permanently denied. Enable it from Settings.'
            : 'Camera permission is required to take a signature photo.',
      );
    }

    // Gallery
    if (Platform.isIOS) {
      var status = await Permission.photos.status;
      if (!status.isGranted && !status.isLimited) {
        status = await Permission.photos.request();
      }
      if (status.isGranted || status.isLimited) return null;

      return SignaturePickResult.permissionDenied(
        permanentlyDenied: status.isPermanentlyDenied,
        message: status.isPermanentlyDenied
            ? 'Photos permission is permanently denied. Enable it from Settings.'
            : 'Photos permission is required to upload a signature.',
      );
    }

    if (Platform.isAndroid) {
      var photos = await Permission.photos.status;
      if (photos.isGranted || photos.isLimited) return null;

      if (!photos.isGranted && !photos.isLimited && !photos.isPermanentlyDenied) {
        photos = await Permission.photos.request();
        if (photos.isGranted || photos.isLimited) return null;
      }

      var storage = await Permission.storage.status;
      if (storage.isGranted) return null;
      if (!storage.isGranted && !storage.isPermanentlyDenied) {
        storage = await Permission.storage.request();
        if (storage.isGranted) return null;
      }

      if (photos.isPermanentlyDenied || storage.isPermanentlyDenied) {
        return SignaturePickResult.permissionDenied(
          permanentlyDenied: true,
          message:
              'Storage permission is permanently denied. Enable it from Settings.',
        );
      }

      return null;
    }

    return null;
  }

  Future<String?> _cropImage(String sourcePath) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      compressFormat: ImageCompressFormat.png,
      compressQuality: 95,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Signature',
          toolbarColor: AppColors.primaryDark,
          toolbarWidgetColor: AppColors.white,
          statusBarLight: false,
          activeControlsWidgetColor: AppColors.primary,
          backgroundColor: AppColors.background,
          dimmedLayerColor: AppColors.primaryDark.withValues(alpha: 0.55),
          cropFrameColor: AppColors.primary,
          cropGridColor: AppColors.secondary,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
        IOSUiSettings(
          title: 'Crop Signature',
          doneButtonTitle: 'Done',
          cancelButtonTitle: 'Cancel',
          aspectRatioLockEnabled: false,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
      ],
    );

    return cropped?.path;
  }
}
