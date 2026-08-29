import 'dart:convert';

import 'package:flutter/material.dart';

import '../constant/api_constants.dart';
import '../models/form_permission.dart';
import '../models/login.dart';
import '../services/api_service.dart';
import '../services/client_code_storage.dart';
import '../services/get_stroage_data.dart';

class PermissionProvider extends ChangeNotifier {
  PermissionProvider({
    this.clientCodeStorage = const ClientCodeStorage(),
    ApiService? apiService,
    bool bootstrap = true,
  }) : apiService = apiService ?? ApiService.shared() {
    _restoreFromStorage();
    if (bootstrap) {
      loadPermissions();
    }
  }

  final ClientCodeStorage clientCodeStorage;
  final ApiService apiService;

  Map<String, FormPermission> _byCode = {};
  bool _isLoading = false;
  bool _hasLoadedFromApi = false;
  String? _error;

  bool get isLoading => _isLoading;
  bool get hasLoadedFromApi => _hasLoadedFromApi;
  String? get error => _error;
  List<FormPermission> get permissions =>
      List.unmodifiable(_byCode.values.toList());

  bool get canViewMemoDelivery => canView(FormCodes.memoDelivery);
  bool get canViewSaleDelivery => canView(FormCodes.saleDelivery);
  bool get canViewMemoOfficeDelivery =>
      canView(FormCodes.memoOfficeDelivery);
  bool get canViewSaleOfficeDelivery =>
      canView(FormCodes.saleOfficeDelivery);

  bool get canPrintMemoDelivery => canPrint(FormCodes.memoDelivery);
  bool get canPrintSaleDelivery => canPrint(FormCodes.saleDelivery);
  bool get canPrintMemoOfficeDelivery =>
      canPrint(FormCodes.memoOfficeDelivery);
  bool get canPrintSaleOfficeDelivery =>
      canPrint(FormCodes.saleOfficeDelivery);

  /// After a successful API load, missing form = no access.
  /// Before first successful load, keep cards visible (fail-open).
  bool canView(String formCode) {
    final permission = _byCode[formCode];
    if (permission != null) return permission.canView;
    if (!_hasLoadedFromApi) return true;
    return false;
  }

  bool canPrint(String formCode) {
    final permission = _byCode[formCode];
    if (permission != null) return permission.canPrint;
    if (!_hasLoadedFromApi) return true;
    return false;
  }

  FormPermission? permissionFor(String formCode) => _byCode[formCode];

  Future<void> loadPermissions() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final loginUser = _readSavedLoginUser();
      final productId = await clientCodeStorage.getClientCode();
      if (loginUser == null || productId == null || productId.isEmpty) {
        _error = 'Session or product id missing';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await fetchUserPermissions(
        loginUser: loginUser,
        productId: productId,
      );

      if (!response.isPermissionSuccess) {
        _error = response.error.isNotEmpty
            ? response.error
            : (response.message.isNotEmpty
                ? response.message
                : 'Unable to load permissions');
        _isLoading = false;
        notifyListeners();
        return;
      }

      await savePermissions(response.permissions);
      _applyPermissions(response.permissions);
      _hasLoadedFromApi = true;
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _error = 'Unable to load permissions';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<FormPermissionListResponse> fetchUserPermissions({
    required LoginUser loginUser,
    required String productId,
  }) async {
    final response = await apiService.postRequest(
      ApiConstants.getUserPermission,
      data: {
        'login': loginUser.toJson(),
        'Product_ID': productId,
      },
    );

    final raw = response.data;
    if (raw is Map<String, dynamic>) {
      return FormPermissionListResponse.fromJson(raw);
    }
    if (raw is Map) {
      return FormPermissionListResponse.fromJson(
        Map<String, dynamic>.from(raw),
      );
    }

    return const FormPermissionListResponse(
      message: 'Invalid response from server',
      error: 'Invalid response from server',
      permissions: [],
      isSessionExpire: false,
      isSuccess: false,
      statusCode: '',
    );
  }

  static Future<void> savePermissions(List<FormPermission> permissions) async {
    await GetStorageData.saveString(
      GetStorageData.formPermissions,
      jsonEncode(permissions.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> clearPermissions() async {
    await GetStorageData.removeData(GetStorageData.formPermissions);
  }

  void _restoreFromStorage() {
    final raw = GetStorageData.readString(GetStorageData.formPermissions);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final permissions = decoded
          .whereType<Map>()
          .map((e) => FormPermission.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _applyPermissions(permissions);
      if (permissions.isNotEmpty) {
        _hasLoadedFromApi = true;
      }
    } catch (_) {
      // Ignore corrupt cache.
    }
  }

  void _applyPermissions(List<FormPermission> permissions) {
    _byCode = {
      for (final permission in permissions)
        if (permission.formCode.isNotEmpty) permission.formCode: permission,
    };
  }

  LoginUser? _readSavedLoginUser() {
    final raw = GetStorageData.readString(GetStorageData.loginData);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return LoginResult.fromJson(Map<String, dynamic>.from(decoded)).login;
    } catch (_) {
      return null;
    }
  }
}
