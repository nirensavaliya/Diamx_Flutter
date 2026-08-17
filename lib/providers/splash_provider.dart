import 'package:flutter/foundation.dart';

import '../routes/app_routes.dart';
import '../services/client_code_storage.dart';
import '../services/get_stroage_data.dart';
import '../services/navigation_service.dart';

class SplashProvider extends ChangeNotifier {
  SplashProvider(
    this._navigationService, {
    this.clientCodeStorage = const ClientCodeStorage(),
  }) {
    _startFlow();
  }

  final NavigationService _navigationService;
  final ClientCodeStorage clientCodeStorage;

  Future<void> _startFlow() async {
    await Future.delayed(const Duration(seconds: 4));

    try {
      final token = GetStorageData.readString(GetStorageData.token);
      final loginData = GetStorageData.readString(GetStorageData.loginData);

      // Already logged in → home
      if (token != null &&
          token.isNotEmpty &&
          loginData != null &&
          loginData.isNotEmpty) {
        _navigationService.offAllNamed(AppRoutes.main);
        return;
      }

      // Client code already saved → login (logout does not clear this)
      final savedCode = await clientCodeStorage.getClientCode();
      if (savedCode != null && savedCode.isNotEmpty) {
        _navigationService.offAllNamed(AppRoutes.login);
        return;
      }

      // Fresh install / no client code → company code screen
      _navigationService.offAllNamed(AppRoutes.companyCode);
    } catch (error) {
      debugPrint('Splash navigation failed: $error');
      _navigationService.offAllNamed(AppRoutes.companyCode);
    }
  }
}
