import 'package:flutter/foundation.dart';

import '../routes/app_routes.dart';
import '../services/api_service.dart';
import '../services/client_code_storage.dart';
import '../services/get_stroage_data.dart';
import '../services/navigation_service.dart';

class SplashProvider extends ChangeNotifier {
  SplashProvider(
    this._navigationService, {
    this.clientCodeStorage = const ClientCodeStorage(),
    ApiService? apiService,
    this.defaultProductId = 'LOC101',
  }) : apiService = apiService ?? ApiService.shared() {
    _startFlow();
  }

  final NavigationService _navigationService;
  final ClientCodeStorage clientCodeStorage;
  final ApiService apiService;
  final String defaultProductId;

  Future<void> _startFlow() async {
    await Future.delayed(const Duration(seconds: 4));

    try {
      final token = GetStorageData.readString(GetStorageData.token);
      final loginData = GetStorageData.readString(GetStorageData.loginData);
      print('token---${token}');
      print('loginData---${loginData}');
      if (token != null &&
          token.isNotEmpty &&
          loginData != null &&
          loginData.isNotEmpty) {
        _navigationService.offAllNamed(AppRoutes.main);
        return;
      }

      final savedCode = await clientCodeStorage.getClientCode();
      if (savedCode != null && savedCode.isNotEmpty) {
        _navigationService.offAllNamed(AppRoutes.login);
        return;
      }

      final response = await apiService.confirmProductId(
        productId: defaultProductId,
      );

      if (_isSuccess(response)) {
        await clientCodeStorage.saveClientCode(defaultProductId);
        _navigationService.offAllNamed(AppRoutes.login);
        return;
      }

      _navigationService.offAllNamed(AppRoutes.companyCode);
    } catch (error) {
      debugPrint('Splash confirmProductId failed: $error');
      _navigationService.offAllNamed(AppRoutes.companyCode);
    }
  }

  bool _isSuccess(Map<String, dynamic> response) {
    final value = response['IsSuccess'];
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is num) return value != 0;
    return false;
  }
}
