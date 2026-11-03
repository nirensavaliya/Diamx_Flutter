import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/login.dart';
import '../../services/client_code_storage.dart';
import '../../services/get_stroage_data.dart';
import '../../utills/app_colors.dart';
import '../../utills/app_font.dart';
import '../../utills/global.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = _readSavedLoginUser();
    final fullName = _displayValue(user?.fullName);
    final loginName = _displayValue(user?.loginName);
    final companyName = _displayValue(user?.companyName);
    final accountType = _accountTypeLabel(user);

    return Column(
      children: [
        const _ProfileAppBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileHeroCard(
                  fullName: fullName,
                  accountType: accountType,
                ),
                const SizedBox(height: 26),
                Text(
                  'Account Information',
                  style: TextStyle(
                    fontFamily: FontFamily.montserratBold,
                    color: AppColors.textPrimary,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your diamond workspace details',
                  style: TextStyle(
                    fontFamily: FontFamily.montserratRegular,
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 14),
                _ProfileInfoTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Username',
                  value: loginName,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 11),
                _ProfileInfoTile(
                  icon: Icons.business_outlined,
                  title: 'Company',
                  value: companyName,
                  color: AppColors.accentDark,
                ),
                const SizedBox(height: 11),
                _ProfileInfoTile(
                  icon: Icons.verified_user_outlined,
                  title: 'Account Type',
                  value: accountType,
                  color: AppColors.success,
                ),
                const SizedBox(height: 11),
                const _ClientCodeTile(),
                const SizedBox(height: 26),
                Text(
                  'Settings',
                  style: TextStyle(
                    fontFamily: FontFamily.montserratBold,
                    color: AppColors.textPrimary,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 14),
                _LogoutTile(onTap: () => showLogoutDialog(context)),
              ],
            ),
          ),
        ),
      ],
    );
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

String _displayValue(String? value) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? '-' : text;
}

String _accountTypeLabel(LoginUser? user) {
  if (user == null) return '-';
  if (user.isSuperAdmin) return 'Super Admin';
  if (user.isAdmin) return 'Admin';
  return 'User';
}

class _ProfileAppBar extends StatelessWidget {
  const _ProfileAppBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -22,
            top: -20,
            child: Icon(
              Icons.person_outline_rounded,
              size: 120,
              color: AppColors.white.withValues(alpha: 0.08),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile',
                          style: TextStyle(
                            fontFamily: FontFamily.montserratBold,
                            color: AppColors.white,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your account',
                          style: TextStyle(
                            fontFamily: FontFamily.montserratRegular,
                            color: AppColors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.fullName,
    required this.accountType,
  });

  final String fullName;
  final String accountType;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 26, 0, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            bottom: -40,
            child: Icon(
              Icons.diamond_outlined,
              size: 130,
              color: AppColors.white.withValues(alpha: 0.08),
            ),
          ),
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.55),
                      width: 1.6,
                    ),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.white,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  fullName,
                  style: TextStyle(
                    fontFamily: FontFamily.montserratBold,
                    color: AppColors.white,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    accountType.toUpperCase(),
                    style: TextStyle(
                      fontFamily: FontFamily.montserratSemiBold,
                      color: AppColors.primaryDark,
                      fontSize: 9,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  const _ProfileInfoTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: FontFamily.montserratRegular,
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: FontFamily.montserratSemiBold,
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientCodeTile extends StatelessWidget {
  const _ClientCodeTile();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: const ClientCodeStorage().getClientCode(),
      builder: (context, snapshot) {
        final code = snapshot.data;
        return _ProfileInfoTile(
          icon: Icons.vpn_key_outlined,
          title: 'Client Code',
          value: (code == null || code.isEmpty) ? 'Not saved' : code,
          color: AppColors.primaryLight,
        );
      },
    );
  }
}

class _LogoutTile extends StatelessWidget {
  const _LogoutTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.error,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontFamily: FontFamily.montserratSemiBold,
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sign out from your account',
                      style: TextStyle(
                        fontFamily: FontFamily.montserratRegular,
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.error.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
