import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../services/api_service.dart';
import '../services/client_code_storage.dart';

class CompanyCodeProvider extends ChangeNotifier {
  CompanyCodeProvider({
    this.clientCodeStorage = const ClientCodeStorage(),
    ApiService? apiService,
  }) : apiService = apiService ?? ApiService.shared();

  final ClientCodeStorage clientCodeStorage;
  final ApiService apiService;
  final TextEditingController clientCodeController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedCompany;
  List<String> _companies = [];
  bool _isProductConfirmed = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedCompany => _selectedCompany;
  List<String> get companies => List.unmodifiable(_companies);
  bool get isProductConfirmed => _isProductConfirmed;

  Future<void> loadCompanies(BuildContext context) async {
    final code = clientCodeController.text.trim();

    if (code.isEmpty) {
      _errorMessage = 'Please enter a client code';
      notifyListeners();
      return;
    }

    _errorMessage = null;
    _isLoading = true;
    _companies = [];
    _selectedCompany = null;
    notifyListeners();

    try {
      final response = await apiService.confirmProductId(productId: code);
      final isSuccess = _isSuccess(response);

      if (!isSuccess) {
        _errorMessage =
            response['Message']?.toString() ?? 'Product id not found';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final saved = await clientCodeStorage.saveClientCode(code);
      if (!saved) {
        _errorMessage = 'Unable to save client code. Please try again.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      _isProductConfirmed = true;
      _isLoading = false;
      notifyListeners();

      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectCompany(String? company) {
    _selectedCompany = company;
    notifyListeners();
  }

  bool _isSuccess(Map<String, dynamic> response) {
    final value = response['IsSuccess'];
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is num) return value != 0;
    return false;
  }

  @override
  void dispose() {
    clientCodeController.dispose();
    super.dispose();
  }
}
