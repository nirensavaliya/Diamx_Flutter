import 'dart:convert';

import 'package:flutter/material.dart';

import '../constant/api_constants.dart';
import '../models/login.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';
import '../services/client_code_storage.dart';
import '../services/get_stroage_data.dart';
import '../widgets/app_loader.dart';
import 'app_colors.dart';
import 'app_font.dart';
import 'app_toast.dart';

Future<void> showLogoutDialog(BuildContext context) async {
  final shouldLogout = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.primaryDark.withValues(alpha: 0.65),
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: AppColors.surface,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.secondary),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.error,
                size: 30,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Logout',
              style: TextStyle(
                fontFamily: FontFamily.montserratBold,
                color: AppColors.textPrimary,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Are you sure you want to logout from your account?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: FontFamily.montserratRegular,
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(
                        color: AppColors.secondary,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: FontFamily.montserratSemiBold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Logout',
                      style: TextStyle(
                        fontFamily: FontFamily.montserratSemiBold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );

  if (shouldLogout != true || !context.mounted) return;

  await _performLogout(context);
}

Future<void> _performLogout(BuildContext context) async {
  AppLoader.show(context, message: 'Logging out...');

  var isSuccess = true;
  var toastMessage = 'Logged out successfully';

  try {
    final loginUser = _readSavedLoginUser();
    final productId =
        await const ClientCodeStorage().getClientCode() ?? '';

    if (loginUser != null) {
      final response = await ApiService.shared().postRequest(
        ApiConstants.logout,
        data: {
          'login': loginUser.toJson(),
          'Product_ID': productId,
        },
      );

      final raw = response.data;
      final map = raw is Map<String, dynamic>
          ? raw
          : (raw is Map ? Map<String, dynamic>.from(raw) : null);

      if (map != null) {
        final apiSuccess = _isSuccess(map);
        final message = map['Message']?.toString().trim() ?? '';
        final error = map['Error']?.toString().trim() ?? '';

        isSuccess = apiSuccess && error.isEmpty;
        if (isSuccess) {
          toastMessage = message.isNotEmpty
              ? message
              : 'Logged out successfully';
        } else {
          toastMessage = error.isNotEmpty
              ? error
              : (message.isNotEmpty ? message : 'Logout failed');
        }
      }
    }
  } catch (error) {
    debugPrint('Logout API failed: $error');
    isSuccess = false;
    toastMessage = 'Unable to logout. Please try again.';
  } finally {
    AppLoader.hide();
    await _clearSession();
    if (context.mounted) {
      final navigator = Navigator.of(context, rootNavigator: true);
      navigator.pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final toastContext = navigator.context;
        Utils().showToast(
          context: toastContext,
          title: isSuccess ? 'Success' : 'Error',
          message: toastMessage,
          isSuccess: isSuccess,
        );
      });
    }
  }
}

bool _isSuccess(Map<String, dynamic> response) {
  final value = response['IsSuccess'];
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  if (value is num) return value != 0;
  return false;
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

Future<void> _clearSession() async {
  await GetStorageData.removeData(GetStorageData.loginData);
  await GetStorageData.removeData(GetStorageData.formPermissions);
  await GetStorageData.removeData(GetStorageData.token);
  await GetStorageData.removeData(GetStorageData.userId);
  await GetStorageData.removeData(GetStorageData.currencyCode);
  await GetStorageData.removeData(GetStorageData.userType);
  await GetStorageData.removeData(GetStorageData.isOtpVerified);
}
