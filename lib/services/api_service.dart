import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';

import '../constant/api_constants.dart';
import '../routes/app_routes.dart';
import 'get_stroage_data.dart';
import 'navigation_service.dart';

class ApiService {
  ApiService({this.navigationService}) {
    _createDio();
  }

  static ApiService? _instance;

  factory ApiService.shared({NavigationService? navigationService}) {
    return _instance ??= ApiService(navigationService: navigationService);
  }

  @visibleForTesting
  static void debugOverride(ApiService? service) {
    _instance = service;
  }

  final NavigationService? navigationService;
  late final Dio _dio;
  bool _isLoggingOut = false;

  void _createDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) async {
          if (_isUnauthorized(response)) {
            await _forceLogoutIfNeeded(response.requestOptions.path);
          }
          return handler.next(response);
        },
        onError: (error, handler) async {
          final response = error.response;
          if (response != null && _isUnauthorized(response)) {
            await _forceLogoutIfNeeded(error.requestOptions.path);
          } else if (error.response?.statusCode == 401) {
            await _forceLogoutIfNeeded(error.requestOptions.path);
          }
          return handler.next(error);
        },
      ),
    );
  }

  bool _shouldSkipAutoLogout(String path) {
    return path.contains(ApiConstants.login);
  }

  bool _isUnauthorized(Response response) {
    if (response.statusCode == 401) return true;

    final map = _asResponseMap(response.data);
    if (map == null) return false;

    final statusCode = map['StatusCode']?.toString().trim() ?? '';
    if (statusCode == '401') return true;

    if (_asBool(map['IsSessionExpire'])) return true;

    final message = map['Message']?.toString().toLowerCase() ?? '';
    if (message.contains('session is expire') ||
        message.contains('session expired') ||
        message.contains('session expire')) {
      return true;
    }

    return false;
  }

  Map<String, dynamic>? _asResponseMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String && data.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }

  bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().toLowerCase().trim() ?? '';
    return text == 'true' || text == '1' || text == 'yes';
  }

  Future<void> _forceLogoutIfNeeded(String path) async {
    if (_shouldSkipAutoLogout(path) || _isLoggingOut) return;

    _isLoggingOut = true;
    debugPrint('⚠️ Session expired / 401 → Auto logout');

    try {
      await GetStorageData.removeData(GetStorageData.loginData);
      await GetStorageData.removeData(GetStorageData.token);
      await GetStorageData.removeData(GetStorageData.userId);
      await GetStorageData.removeData(GetStorageData.currencyCode);
      await GetStorageData.removeData(GetStorageData.userType);
      await GetStorageData.removeData(GetStorageData.isOtpVerified);
      navigationService?.offAllNamed(AppRoutes.login);
    } finally {
      Future<void>.delayed(const Duration(seconds: 1), () {
        _isLoggingOut = false;
      });
    }
  }

  void updateBaseUrl(String url) {
    _dio.options.baseUrl = url;
  }

  /// Reusable GET Method
  Future<Response> getRequest(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
    ResponseType? responseType,
  }) async {
    try {
      return await _dio.get(
        endpoint,
        queryParameters: queryParams,
        options: Options(headers: headers, responseType: responseType),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'API Error');
    }
  }

  /// Generic POST
  Future<Response> postRequest(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParams,
        options: Options(headers: headers, validateStatus: (status) => true),
      );
      debugPrint('POST--API---$response');
      return response;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'POST API Error');
    }
  }

  /// Multipart POST (file + text fields) — e.g. signature upload.
  Future<Response> postMultipartRequest(
    String endpoint, {
    required FormData formData,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    try {

      final mergedHeaders = <String, dynamic>{
        ...?headers,
      };
      mergedHeaders.remove(Headers.contentTypeHeader);

      final response = await _dio.post(
        endpoint,
        data: formData,
        queryParameters: queryParams,
        options: Options(
          headers: mergedHeaders,
          contentType: null,
          validateStatus: (status) => true,
        ),
      );
      debugPrint('POST-MULTIPART--API--- status=${response.statusCode}');
      debugPrint('POST-MULTIPART--API--- data=${response.data}');
      return response;
    } on DioException catch (e) {
      debugPrint('POST-MULTIPART--ERROR--- $e');
      throw Exception(e.response?.data?['message'] ?? 'Multipart API Error');
    }
  }

  /// Upload digital signature for print URL path.
  Future<Map<String, dynamic>> savePrintUrlPath({
    required Uint8List signatureBytes,
    required Map<String, dynamic> loginJson,
    required String productId,
    required int transactionId,
    required String transactionNo,
    String transactionType = 'Memo Issue',
    int printId = 1,
    int digitalSignatureId = 0,
    String fileName = 'signature.png',
  }) async {
    final safeFileName =
        fileName.trim().isEmpty ? 'signature.png' : fileName.trim();
    final mimeSubtype = _imageMimeSubtype(safeFileName);

    final loginPayload = Map<String, dynamic>.from(loginJson);
    if ((loginPayload['Product_ID']?.toString() ?? '').trim().isEmpty) {
      loginPayload['Product_ID'] = productId;
    }

    final dataJson = jsonEncode({
      'login': loginPayload,
      'Obj': {
        'Digital_Signature_ID': digitalSignatureId,
        'Transaction_ID': transactionId,
        'Transaction_Type': transactionType,
        'Transaction_No': transactionNo,
        'Print_ID': printId,
      },
      'Product_ID': productId,
    });

    debugPrint(
      'savePrintUrlPath → file=$safeFileName '
      'bytes=${signatureBytes.length} mime=image/$mimeSubtype '
      'Transaction_ID=$transactionId Transaction_No=$transactionNo '
      'Transaction_Type=$transactionType Print_ID=$printId',
    );
    debugPrint('savePrintUrlPath → data=$dataJson');

    try {
      final formData = FormData.fromMap({
        'SignaturePath': MultipartFile.fromBytes(
          signatureBytes,
          filename: safeFileName,
          contentType: MediaType('image', mimeSubtype),
        ),
        'data': dataJson,
      });

      final response = await postMultipartRequest(
        ApiConstants.savePrintUrlPath,
        formData: formData,
      );

      final raw = response.data;
      if (raw is Map<String, dynamic>) return raw;
      if (raw is Map) return Map<String, dynamic>.from(raw);
      if (raw is String) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) return decoded;
          if (decoded is Map) return Map<String, dynamic>.from(decoded);
        } catch (_) {}
      }

      return {'IsSuccess': false, 'Message': 'Invalid response from server'};
    } catch (e) {
      debugPrint('savePrintUrlPath ERROR: $e');
      rethrow;
    }
  }

  String _imageMimeSubtype(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'jpeg';
    if (lower.endsWith('.webp')) return 'webp';
    if (lower.endsWith('.gif')) return 'gif';
    return 'png';
  }

  Future<Response> putRequest(
    String url, {
    dynamic data,
    Map<String, String>? headers,
  }) async {
    return _dio.put(
      url,
      data: data,
      options: Options(headers: headers),
    );
  }

  Future<Response> deleteRequest(
    String url, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  }) async {
    return _dio.delete(
      url,
      data: data,
      options: Options(headers: headers),
    );
  }

  Future<Response> patchRequest(
    String url, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  }) async {
    try {
      return await _dio.patch(
        url,
        data: data,
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'PATCH API Error');
    }
  }

  /// Confirm product / client id via common POST.
  Future<Map<String, dynamic>> confirmProductId({
    required String productId,
  }) async {
    final response = await postRequest(
      ApiConstants.confirmProductId,
      data: {'Product_ID': productId},
    );

    final raw = response.data;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);

    return {'IsSuccess': false, 'Message': 'Invalid response from server'};
  }

  /// Download a remote file (absolute URL) to [savePath].
  /// Uses a dedicated Dio so PDF bytes skip API log/auth interceptors.
  Future<String> downloadFile({
    required String url,
    required String savePath,
  }) async {
    try {
      final downloadDio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status != null && status >= 200 && status < 400,
        ),
      );

      final response = await downloadDio.get<List<int>>(url);
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Downloaded PDF is empty');
      }

      final file = File(savePath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
      return savePath;
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Unable to download file');
    }
  }
}
