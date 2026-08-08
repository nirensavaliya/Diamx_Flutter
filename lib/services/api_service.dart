import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';

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
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            debugPrint('Token expired → clearing session');
            await GetStorageData.removeData(GetStorageData.token);
            await GetStorageData.removeData(GetStorageData.userType);
            await GetStorageData.removeData(GetStorageData.isOtpVerified);
            navigationService?.offAllNamed(AppRoutes.login);
          }
          return handler.next(error);
        },
      ),
    );
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
      // Force boundary so ASP.NET can parse multipart (BaseOptions JSON CT must not win).
      mergedHeaders[Headers.contentTypeHeader] =
          'multipart/form-data; boundary=${formData.boundary}';

      final response = await _dio.post(
        endpoint,
        data: formData,
        queryParameters: queryParams,
        options: Options(
          headers: mergedHeaders,
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
      'Product_ID': productId,
    });

    debugPrint(
      'savePrintUrlPath → file=$safeFileName '
      'bytes=${signatureBytes.length} mime=image/$mimeSubtype',
    );
    debugPrint('savePrintUrlPath → data=$dataJson');

    File? tempFile;
    try {
      final dir = await getTemporaryDirectory();
      tempFile = File(
        '${dir.path}/signature_upload_${DateTime.now().millisecondsSinceEpoch}_$safeFileName',
      );
      await tempFile.writeAsBytes(signatureBytes, flush: true);

      final formData = FormData.fromMap({
        'SignaturePath': await MultipartFile.fromFile(
          tempFile.path,
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
    } finally {
      try {
        if (tempFile != null && await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}
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
}
