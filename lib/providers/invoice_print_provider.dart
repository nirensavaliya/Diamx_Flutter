import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../constant/api_constants.dart';
import '../models/invoice.dart';
import '../models/login.dart';
import '../models/print_template.dart';
import '../services/api_service.dart';
import '../services/client_code_storage.dart';
import '../services/get_stroage_data.dart';
import '../services/pdf_service.dart';
import '../utills/signature_image_helper.dart';

class InvoicePrintProvider extends ChangeNotifier {
  InvoicePrintProvider(
    this.invoice, {
    this.pdfService = const PdfService(),
    this.clientCodeStorage = const ClientCodeStorage(),
    ApiService? apiService,
    SignatureImageHelper? signatureImageHelper,
    bool bootstrap = true,
  }) : apiService = apiService ?? ApiService.shared(),
       signatureImageHelper = signatureImageHelper ?? SignatureImageHelper() {
    if (bootstrap) {
      Future.microtask(loadPrintList);
    }
  }

  static const int defaultPrintId = 1;
  static const String formName = 'Sale Invoice';

  final Invoice invoice;
  final PdfService pdfService;
  final ClientCodeStorage clientCodeStorage;
  final ApiService apiService;
  final SignatureImageHelper signatureImageHelper;
  final Set<String> _selectedItemIds = {};

  Uint8List? _signature;
  String? _uploadedSignaturePath;
  int _printId = defaultPrintId;
  List<PrintTemplate> _printOptions = [];
  PrintTemplate? _selectedPrint;
  bool _isLoadingPrintList = false;
  String? _printListError;
  bool _isGenerating = false;
  bool _isUploadingSignature = false;
  String? _lastSavedPath;
  String? _lastPdfUrl;
  String? _errorMessage;
  String? _signatureMessage;
  bool _shouldOpenSettings = false;

  Set<String> get selectedItemIds => Set.unmodifiable(_selectedItemIds);
  Uint8List? get signature => _signature;
  String? get uploadedSignaturePath => _uploadedSignaturePath;
  int get printId => _printId;
  List<PrintTemplate> get printOptions => List.unmodifiable(_printOptions);
  PrintTemplate? get selectedPrint => _selectedPrint;
  bool get isLoadingPrintList => _isLoadingPrintList;
  String? get printListError => _printListError;
  bool get hasSignature => _signature != null;
  bool get isGenerating => _isGenerating;
  bool get isUploadingSignature => _isUploadingSignature;
  bool get isBusy =>
      _isGenerating || _isUploadingSignature || _isLoadingPrintList;
  bool get isAllSelected =>
      _selectedItemIds.length == invoice.items.length &&
      invoice.items.isNotEmpty;
  String? get lastSavedPath => _lastSavedPath;
  String? get lastPdfUrl => _lastPdfUrl;
  String? get errorMessage => _errorMessage;
  String? get signatureMessage => _signatureMessage;
  bool get shouldOpenSettings => _shouldOpenSettings;

  void toggleItem(String itemId) {
    if (!_selectedItemIds.add(itemId)) {
      _selectedItemIds.remove(itemId);
    }
    _errorMessage = null;
    notifyListeners();
  }

  void toggleSelectAll() {
    if (isAllSelected) {
      _selectedItemIds.clear();
    } else {
      _selectedItemIds
        ..clear()
        ..addAll(invoice.items.map((item) => item.id));
    }
    _errorMessage = null;
    notifyListeners();
  }

  void clearSignature() {
    _signature = null;
    _uploadedSignaturePath = null;
    _signatureMessage = null;
    _shouldOpenSettings = false;
    notifyListeners();
  }

  void selectPrint(PrintTemplate? template) {
    if (template == null) return;
    _selectedPrint = template;
    _printId = template.printId;
    notifyListeners();
  }

  /// Load print templates when print screen opens — `get-Print-List-detail`.
  Future<void> loadPrintList() async {
    _isLoadingPrintList = true;
    _printListError = null;
    notifyListeners();

    try {
      final loginUser = _readSavedLoginUser();
      if (loginUser == null) {
        _printListError = 'Login session not found. Please login again.';
        return;
      }

      final productId = await clientCodeStorage.getClientCode();
      if (productId == null || productId.isEmpty) {
        _printListError = 'Product id not found.';
        return;
      }

      final loginPayload = loginUser.toJson();
      if ((loginPayload['Product_ID']?.toString() ?? '').trim().isEmpty) {
        loginPayload['Product_ID'] = productId;
      }

      final response = await apiService.postRequest(
        ApiConstants.getPrintListDetail,
        data: {
          'login': loginPayload,
          'Form_Name': formName,
          'Product_ID': productId,
        },
      );

      final raw = response.data;
      final map = raw is Map<String, dynamic>
          ? raw
          : (raw is Map ? Map<String, dynamic>.from(raw) : null);

      if (map == null) {
        _printListError = 'Invalid response from server';
        _printOptions = [];
        _selectedPrint = null;
        return;
      }

      final error = map['Error']?.toString().trim() ?? '';
      final message = map['Message']?.toString().trim() ?? '';
      if (!_isSuccess(map) || error.isNotEmpty) {
        _printListError = error.isNotEmpty
            ? error
            : (message.isNotEmpty ? message : 'Unable to load print list');
        _printOptions = [];
        _selectedPrint = null;
        return;
      }

      final result = map['Result'];
      final list = <PrintTemplate>[];
      if (result is List) {
        for (final item in result) {
          if (item is Map) {
            final template = PrintTemplate.fromJson(
              Map<String, dynamic>.from(item),
            );
            if (template.isActive && template.printId > 0) {
              list.add(template);
            }
          }
        }
      }
      list.sort((a, b) => a.seqNo.compareTo(b.seqNo));

      _printOptions = list;
      if (list.isEmpty) {
        _selectedPrint = null;
        _printId = defaultPrintId;
        _printListError = 'No print templates found';
      } else {
        PrintTemplate selected = list.first;
        for (final item in list) {
          if (item.printId == _printId) {
            selected = item;
            break;
          }
        }
        _selectedPrint = selected;
        _printId = selected.printId;
      }

      debugPrint(
        'Invoice print list loaded → count=${list.length}, '
        'selected Print_ID=$_printId',
      );
    } catch (error) {
      debugPrint('Invoice loadPrintList ERROR: $error');
      _printListError = 'Unable to load print list. Please try again.';
      _printOptions = [];
      _selectedPrint = null;
    } finally {
      _isLoadingPrintList = false;
      notifyListeners();
    }
  }

  /// Pick signature then upload via `save-Print-Url-Path` (same Print_ID).
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

      debugPrint(
        'Invoice signature upload → save-Print-Url-Path '
        'Transaction_ID=${invoice.invoiceId}, Transaction_No=${invoice.id}, '
        'Print_ID=$_printId',
      );

      final response = await apiService.savePrintUrlPath(
        signatureBytes: signatureBytes,
        loginJson: loginUser.toJson(),
        productId: productId,
        transactionId: invoice.invoiceId,
        transactionNo: invoice.id,
        transactionType: formName,
        printId: _printId,
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
      debugPrint('Invoice signature upload ERROR: $error');
      _signatureMessage = 'Unable to upload signature. Please try again.';
      return false;
    } finally {
      _isUploadingSignature = false;
      notifyListeners();
    }
  }

  /// Generate PDF via `get-Print-Url-Path`.
  /// When [autoDownload] is false, only the remote URL is stored (manual download later).
  Future<bool> generatePdf({
    Rect? sharePositionOrigin,
    bool autoDownload = true,
  }) async {
    if (invoice.items.isNotEmpty && _selectedItemIds.isEmpty) {
      _errorMessage = 'Select at least one diamond';
      notifyListeners();
      return false;
    }

    _isGenerating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loginUser = _readSavedLoginUser();
      if (loginUser == null) {
        _errorMessage = 'Login session not found. Please login again.';
        return false;
      }

      final productId = await clientCodeStorage.getClientCode();
      if (productId == null || productId.isEmpty) {
        _errorMessage = 'Product id not found.';
        return false;
      }

      debugPrint(
        'Invoice Generate PDF → get-Print-Url-Path '
        'Tran_Id=${invoice.invoiceId}, Sale_Invoice_No=${invoice.id}, '
        'PrintID=$_printId',
      );

      final map = await _callGetPrintUrlPath(
        loginUser: loginUser,
        productId: productId,
        printId: _printId,
      );

      if (map == null) {
        _errorMessage = 'Invalid response from server';
        return false;
      }

      final error = map['Error']?.toString().trim() ?? '';
      final message = map['Message']?.toString().trim() ?? '';
      if (!_isSuccess(map) || error.isNotEmpty) {
        _errorMessage = error.isNotEmpty
            ? error
            : (message.isNotEmpty ? message : 'Unable to get print PDF');
        return false;
      }

      final pdfUrl = map['Result']?.toString().trim() ?? '';
      if (pdfUrl.isEmpty) {
        _errorMessage = 'Print PDF url not found';
        return false;
      }

      debugPrint('Invoice Print PDF url → $pdfUrl');
      _lastPdfUrl = pdfUrl;
      _lastSavedPath = null;

      if (!autoDownload) {
        return true;
      }

      final directory = await getApplicationDocumentsDirectory();
      final safeInvoiceNo = invoice.id.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final fileName = 'Diamx_${safeInvoiceNo}_Invoice.pdf';
      final savePath = '${directory.path}${Platform.pathSeparator}$fileName';

      try {
        _lastSavedPath = await apiService.downloadFile(
          url: pdfUrl,
          savePath: savePath,
        );
        debugPrint('Invoice Print PDF saved → $_lastSavedPath');
      } catch (downloadError) {
        debugPrint('Invoice Print PDF download ERROR: $downloadError');
        _lastSavedPath = null;
      }

      return true;
    } catch (error) {
      debugPrint('Invoice PDF ERROR: $error');
      _errorMessage = 'Unable to generate PDF. Please try again.';
      return false;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> _callGetPrintUrlPath({
    required LoginUser loginUser,
    required String productId,
    required int printId,
  }) async {
    final response = await apiService.postRequest(
      ApiConstants.getPrintUrlPath,
      data: {
        'login': loginUser.toJson(),
        'Obj': {
          'FormType': formName,
          'Tran_Id': invoice.invoiceId.toString(),
          'Transaction_No': invoice.id,
          'PrintID': printId,
        },
        'Product_ID': productId,
      },
    );

    final raw = response.data;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
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
