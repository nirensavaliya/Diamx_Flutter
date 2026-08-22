import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

/// Helpers for saving / exporting print PDFs.
///
/// Android 10+: public Downloads via MediaStore (no storage permission).
/// Android 9-: public Downloads file API + storage permission before save.
/// iOS: app Documents + share sheet (Save to Files).
class PdfFileHelper {
  const PdfFileHelper._();

  static const MethodChannel _downloadsChannel = MethodChannel(
    'com.oozee.diamxpro/downloads',
  );

  static Future<Directory> resolveTempDirectory() => getTemporaryDirectory();

  static Future<Directory> resolveSaveDirectory() async {
    if (Platform.isAndroid) return getTemporaryDirectory();
    return getApplicationDocumentsDirectory();
  }

  /// Download [url] then save where the user expects.
  static Future<String> downloadAndSavePdf({
    required String url,
    required String fileName,
    required Future<String> Function({
      required String url,
      required String savePath,
    }) downloadFile,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final safeName = _safeFileName(fileName);
    final tempPath = '${tempDir.path}${Platform.pathSeparator}$safeName';

    final downloadedPath = await downloadFile(
      url: url,
      savePath: tempPath,
    );

    final downloaded = File(downloadedPath);
    if (!downloaded.existsSync() || downloaded.lengthSync() <= 0) {
      throw Exception('Downloaded PDF is empty');
    }

    if (Platform.isAndroid) {
      await _ensureLegacyStoragePermissionIfNeeded();
      try {
        return await saveToPublicDownloads(
          sourcePath: downloadedPath,
          fileName: safeName,
        );
      } on PlatformException catch (error) {
        debugPrint('Downloads MediaStore failed: ${error.code} ${error.message}');
        // Fallback: keep temp file and let caller share / still report path.
        rethrow;
      }
    }

    final docs = await getApplicationDocumentsDirectory();
    final destPath = '${docs.path}${Platform.pathSeparator}$safeName';
    if (downloaded.path != destPath) {
      await downloaded.copy(destPath);
    }
    return File(destPath).existsSync() ? destPath : downloadedPath;
  }

  /// Copy an existing local PDF into the public Downloads folder (Android).
  static Future<String> saveToPublicDownloads({
    required String sourcePath,
    required String fileName,
  }) async {
    if (!Platform.isAndroid) return sourcePath;

    await _ensureLegacyStoragePermissionIfNeeded();

    try {
      final result = await _downloadsChannel.invokeMethod<String>(
        'saveToDownloads',
        {
          'sourcePath': sourcePath,
          'fileName': _safeFileName(fileName),
        },
      );
      if (result == null || result.trim().isEmpty) {
        throw PlatformException(
          code: 'save_failed',
          message: 'Unable to save PDF to Downloads',
        );
      }
      return result;
    } on MissingPluginException {
      throw Exception(
        'Downloads plugin not ready. Please fully restart the app.',
      );
    }
  }

  static Future<int> _androidSdkInt() async {
    try {
      final value = await _downloadsChannel.invokeMethod<int>('getSdkInt');
      return value ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Storage permission only for Android 9 and below.
  static Future<void> _ensureLegacyStoragePermissionIfNeeded() async {
    if (!Platform.isAndroid) return;

    final sdk = await _androidSdkInt();
    if (sdk == 0 || sdk >= 29) return;

    var status = await Permission.storage.status;
    if (status.isGranted) return;

    status = await Permission.storage.request();
    if (!status.isGranted) {
      throw Exception(
        'Storage permission is required to save PDF to Downloads.',
      );
    }
  }

  static String _safeFileName(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    if (cleaned.isEmpty) {
      return 'Diamx_${DateTime.now().millisecondsSinceEpoch}.pdf';
    }
    return cleaned.toLowerCase().endsWith('.pdf') ? cleaned : '$cleaned.pdf';
  }

  static Future<void> shareLocalFile({
    required BuildContext context,
    required String filePath,
    required String title,
  }) async {
    final box = context.findRenderObject() as RenderBox?;
    final origin =
        box == null ? null : box.localToGlobal(Offset.zero) & box.size;

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath, mimeType: 'application/pdf')],
        subject: title,
        text: title,
        sharePositionOrigin: origin,
      ),
    );
  }

  static bool get needsUserSavePicker => Platform.isIOS;

  /// User-facing message from download/save failures.
  static String errorMessage(Object error) {
    if (error is PlatformException) {
      final msg = error.message?.trim();
      if (msg != null && msg.isNotEmpty) return msg;
      return error.code;
    }
    final text = error.toString().trim();
    if (text.startsWith('Exception: ')) {
      return text.substring('Exception: '.length);
    }
    if (text.startsWith('PlatformException')) {
      return 'Unable to save PDF to Downloads. Please restart the app.';
    }
    return text.isNotEmpty ? text : 'Unable to download PDF. Please try again.';
  }
}
