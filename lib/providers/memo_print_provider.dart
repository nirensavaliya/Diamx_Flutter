import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/login.dart';
import '../models/memo.dart';
import '../services/api_service.dart';
import '../services/client_code_storage.dart';
import '../services/get_stroage_data.dart';
import '../services/pdf_service.dart';
import '../utills/signature_image_helper.dart';

class MemoPrintProvider extends ChangeNotifier {
  MemoPrintProvider(
    this.memo, {
    this.pdfService = const PdfService(),
    this.clientCodeStorage = const ClientCodeStorage(),
    ApiService? apiService,
    SignatureImageHelper? signatureImageHelper,
  }) : apiService = apiService ?? ApiService.shared(),
       signatureImageHelper = signatureImageHelper ?? SignatureImageHelper();

  final Memo memo;
  final PdfService pdfService;
  final ClientCodeStorage clientCodeStorage;
  final ApiService apiService;
  final SignatureImageHelper signatureImageHelper;
  final Set<String> _selectedDiamondIds = {};

  Uint8List? _signature;
  String? _uploadedSignaturePath;
  bool _isGenerating = false;
  bool _isUploadingSignature = false;
  String? _lastSavedPath;
  String? _errorMessage;
  String? _signatureMessage;
  bool _shouldOpenSettings = false;

  Set<String> get selectedDiamondIds => Set.unmodifiable(_selectedDiamondIds);
  Uint8List? get signature => _signature;
  String? get uploadedSignaturePath => _uploadedSignaturePath;
  bool get hasSignature => _signature != null;
  bool get isGenerating => _isGenerating;
  bool get isUploadingSignature => _isUploadingSignature;
  bool get isBusy => _isGenerating || _isUploadingSignature;
  bool get isAllSelected =>
      _selectedDiamondIds.length == memo.diamonds.length &&
      memo.diamonds.isNotEmpty;
  String? get lastSavedPath => _lastSavedPath;
  String? get errorMessage => _errorMessage;
  String? get signatureMessage => _signatureMessage;
  bool get shouldOpenSettings => _shouldOpenSettings;

  void toggleDiamond(String diamondId) {
    if (!_selectedDiamondIds.add(diamondId)) {
      _selectedDiamondIds.remove(diamondId);
    }
    _errorMessage = null;
    notifyListeners();
  }

  void toggleSelectAll() {
    if (isAllSelected) {
      _selectedDiamondIds.clear();
    } else {
      _selectedDiamondIds
        ..clear()
        ..addAll(memo.diamonds.map((diamond) => diamond.id));
    }
    _errorMessage = null;
    notifyListeners();
  }

  // Old local-only signature (draw pad) — kept for reference.
  // void setSignature(Uint8List signature) {
  //   _signature = signature;
  //   notifyListeners();
  // }

  void clearSignature() {
    _signature = null;
    _uploadedSignaturePath = null;
    _signatureMessage = null;
    _shouldOpenSettings = false;
    notifyListeners();
  }

  Future<bool> pickAndUploadSignature(
    ImageSource source, {
    bool permissionAlreadyGranted = false,
  }) async {
    _signatureMessage = null;
    _errorMessage = null;
    _shouldOpenSettings = false;
    notifyListeners();

    final pickResult = await signatureImageHelper.pickCroppedSignature(
      source,
      permissionAlreadyGranted: permissionAlreadyGranted,
    );

    switch (pickResult.type) {
      case SignaturePickResultType.cancelled:
        return false;
      case SignaturePickResultType.permissionDenied:
        _signatureMessage = pickResult.message;
        _shouldOpenSettings = false;
        notifyListeners();
        return false;
      case SignaturePickResultType.permanentlyDenied:
        _signatureMessage = pickResult.message;
        _shouldOpenSettings = true;
        notifyListeners();
        return false;
      case SignaturePickResultType.empty:
      case SignaturePickResultType.failed:
        _signatureMessage = pickResult.message;
        notifyListeners();
        return false;
      case SignaturePickResultType.success:
        break;
    }

    return uploadSignature(
      signatureBytes: pickResult.bytes!,
      fileName: pickResult.fileName ?? 'signature.png',
    );
  }

  Future<bool> uploadSignature({
    required Uint8List signatureBytes,
    String fileName = 'signature.png',
  }) async {
    _isUploadingSignature = true;
    _signatureMessage = null;
    _shouldOpenSettings = false;
    notifyListeners();

    try {
      final loginUser = _readSavedLoginUser();
      if (loginUser == null) {
        _signatureMessage = 'Login session not found. Please login again.';
        return false;
      }

      final productId = await clientCodeStorage.getClientCode();
      if (productId == null || productId.isEmpty) {
        _signatureMessage = 'Product id not found.';
        return false;
      }

      final response = await apiService.savePrintUrlPath(
        signatureBytes: signatureBytes,
        loginJson: loginUser.toJson(),
        productId: productId,
        fileName: fileName,
      );

      final isSuccess = _isSuccess(response);
      final error = response['Error']?.toString().trim() ?? '';
      final message = response['Message']?.toString().trim() ?? '';

      if (!isSuccess || error.isNotEmpty) {
        _signatureMessage = error.isNotEmpty
            ? error
            : (message.isNotEmpty ? message : 'Signature upload failed');
        return false;
      }

      _signature = signatureBytes;
      _uploadedSignaturePath = _extractUploadedPath(response);
      _signatureMessage = message.isNotEmpty
          ? message
          : 'Signature uploaded successfully';
      return true;
    } catch (error) {
      debugPrint('Signature upload ERROR: $error');
      _signatureMessage = 'Unable to upload signature. Please try again.';
      return false;
    } finally {
      _isUploadingSignature = false;
      notifyListeners();
    }
  }

  Future<bool> generatePdf({Rect? sharePositionOrigin}) async {
    if (_selectedDiamondIds.isEmpty) {
      _errorMessage = 'Select at least one diamond';
      notifyListeners();
      return false;
    }

    _isGenerating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final selectedDiamonds = memo.diamonds
          .where((diamond) => _selectedDiamondIds.contains(diamond.id))
          .toList();
      _lastSavedPath = await pdfService.generateAndShareMemo(
        memo: memo,
        diamonds: selectedDiamonds,
        signature: _signature,
        sharePositionOrigin: sharePositionOrigin,
      );
      return true;
    } catch (error) {
      debugPrint('PDF ERROR: $error');
      _errorMessage = 'Unable to generate PDF. Please try again.';
      return false;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  LoginUser? _readSavedLoginUser() {
    final raw = GetStorageData.readString(GetStorageData.loginData);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final result = LoginResult.fromJson(Map<String, dynamic>.from(decoded));
      return result.login;
    } catch (_) {
      return null;
    }
  }

  String? _extractUploadedPath(Map<String, dynamic> response) {
    final result = response['Result'];
    if (result is String && result.isNotEmpty) return result;
    if (result is Map) {
      final map = Map<String, dynamic>.from(result);
      return map['SignaturePath']?.toString() ??
          map['Path']?.toString() ??
          map['Url']?.toString() ??
          map['url']?.toString();
    }
    return null;
  }

  bool _isSuccess(Map<String, dynamic> response) {
    final value = response['IsSuccess'];
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is num) return value != 0;
    return false;
  }
}
