import 'dart:convert';

import 'package:flutter/material.dart';

import '../constant/api_constants.dart';
import '../models/branch.dart';
import '../models/login.dart';
import '../services/api_service.dart';
import '../services/client_code_storage.dart';
import '../services/get_stroage_data.dart';

class LoginProvider extends ChangeNotifier {
  LoginProvider({
    this.clientCodeStorage = const ClientCodeStorage(),
    ApiService? apiService,
  }) : apiService = apiService ?? ApiService.shared() {
    loadBranches();
  }

  final ClientCodeStorage clientCodeStorage;
  final ApiService apiService;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isBranchesLoading = false;
  String? _usernameError;
  String? _passwordError;
  String? _branchError;
  String? _branchesError;
  String? _loginError;
  List<Branch> _branches = [];
  Branch? _selectedBranch;
  LoginResult? _loginResult;

  bool get isPasswordVisible => _isPasswordVisible;
  bool get isLoading => _isLoading;
  bool get isBranchesLoading => _isBranchesLoading;
  String? get usernameError => _usernameError;
  String? get passwordError => _passwordError;
  String? get branchError => _branchError;
  String? get branchesError => _branchesError;
  String? get loginError => _loginError;
  List<Branch> get branches => List.unmodifiable(_branches);
  Branch? get selectedBranch => _selectedBranch;
  LoginResult? get loginResult => _loginResult;

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void selectBranch(Branch? branch) {
    _selectedBranch = branch;
    _branchError = null;
    notifyListeners();
  }

  Future<BranchListResponse> getAllBranches({
    required String productId,
    int userId = 0,
  }) async {
    final response = await apiService.postRequest(
      ApiConstants.getAllBranch,
      data: {'Product_ID': productId, 'UserID': userId},
    );

    final raw = response.data;
    if (raw is Map<String, dynamic>) {
      return BranchListResponse.fromJson(raw);
    }
    if (raw is Map) {
      return BranchListResponse.fromJson(Map<String, dynamic>.from(raw));
    }

    return const BranchListResponse(
      message: 'Invalid response from server',
      error: 'Invalid response from server',
      result: [],
    );
  }

  Future<LoginApiResponse> postLogin({
    required String productId,
    required String loginName,
    required String password,
    required int branchId,
  }) async {
    final response = await apiService.postRequest(
      ApiConstants.login,
      data: {
        'loginModel': {
          'LoginName': loginName,
          'Password': password,
          'BranchID': branchId,
          'OTP': 0,
          'UserOTP': 0,
        },
        'Product_ID': productId,
      },
    );

    final raw = response.data;
    if (raw is Map<String, dynamic>) {
      return LoginApiResponse.fromJson(raw);
    }
    if (raw is Map) {
      return LoginApiResponse.fromJson(Map<String, dynamic>.from(raw));
    }

    return const LoginApiResponse(
      message: 'Invalid response from server',
      error: 'Invalid response from server',
      isSessionExpire: false,
      isSuccess: false,
      statusCode: '',
    );
  }

  Future<void> loadBranches() async {
    _isBranchesLoading = true;
    _branchesError = null;
    _branches = [];
    _selectedBranch = null;
    notifyListeners();

    try {
      final productId = await clientCodeStorage.getClientCode();
      if (productId == null || productId.isEmpty) {
        _branchesError =
            'Product id not found. Please enter client code again.';
        _isBranchesLoading = false;
        notifyListeners();
        return;
      }

      final response = await getAllBranches(productId: productId);

      if (response.hasError && response.result.isEmpty) {
        _branchesError = response.error.isNotEmpty
            ? response.error
            : (response.message.isNotEmpty
                  ? response.message
                  : 'Unable to load branches');
        _isBranchesLoading = false;
        notifyListeners();
        return;
      }

      _branches = response.result
          .where((branch) => branch.displayName.isNotEmpty)
          .toList();

      if (_branches.isEmpty) {
        _branchesError = response.message.isNotEmpty
            ? response.message
            : 'No branches found for this product';
      }

      _isBranchesLoading = false;
      notifyListeners();
    } catch (_) {
      _branchesError = 'Unable to load branches. Please try again.';
      _isBranchesLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login() async {
    _usernameError = usernameController.text.trim().isEmpty
        ? 'Username is required'
        : null;
    _passwordError = passwordController.text.isEmpty
        ? 'Password is required'
        : null;
    _branchError = _selectedBranch == null ? 'Branch is required' : null;
    _loginError = null;
    notifyListeners();

    if (_usernameError != null ||
        _passwordError != null ||
        _branchError != null) {
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final productId = await clientCodeStorage.getClientCode();
      if (productId == null || productId.isEmpty) {
        _loginError = 'Product id not found. Please enter client code again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await postLogin(
        productId: productId,
        loginName: usernameController.text.trim(),
        password: passwordController.text,
        branchId: _selectedBranch!.ledgerId,
      );

      if (!response.isLoginSuccess || response.result == null) {
        _loginError = response.error.isNotEmpty
            ? response.error
            : (response.message.isNotEmpty
                  ? response.message
                  : 'Login failed. Please try again.');
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _saveLoginSession(response.result!);
      _loginResult = response.result;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (_) {
      _loginError = 'Unable to login. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _saveLoginSession(LoginResult result) async {
    final user = result.login;
    await GetStorageData.saveString(
      GetStorageData.loginData,
      jsonEncode(result.toJson()),
    );
    await GetStorageData.saveString(
      GetStorageData.token,
      user.loginToken,
    );
    await GetStorageData.saveString(
      GetStorageData.userId,
      user.userId.toString(),
    );
    await GetStorageData.saveString(
      GetStorageData.currencyCode,
      user.currencyName,
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
