import 'package:diamax_flutter/utills/global.dart';
import 'package:flutter/material.dart';

import '../../../utills/app_colors.dart';
import '../../../utills/app_font.dart';
import '../dashboard/CommonScaffold.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onBackTap;
  final VoidCallback? onClientsManagementTap;
  final VoidCallback? onUserManagementTap;
  final VoidCallback? onPermissionsTap;
  final VoidCallback? onAuditLogTap;
  final VoidCallback? onAppSettingsTap;
  final VoidCallback? onAboutUsTap;

  const SettingsScreen({
    super.key,
    this.onBackTap,
    this.onClientsManagementTap,
    this.onUserManagementTap,
    this.onPermissionsTap,
    this.onAuditLogTap,
    this.onAppSettingsTap,
    this.onAboutUsTap,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  void _showComingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title tapped'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      title: 'Settings',
      showLeading: true,
      showBack: false,
      onBackTap: widget.onBackTap,
      body: Container(
        color: AppColors.background,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          children: [
            _buildProfileCard(),
            const SizedBox(height: 12),

            _SettingsTile(
              icon: Icons.groups_rounded,
              title: 'Clients Management',
              onTap:
                  widget.onClientsManagementTap ??
                  () => _showComingSoon('Clients Management'),
            ),
            _SettingsTile(
              icon: Icons.person_rounded,
              title: 'User Management',
              onTap:
                  widget.onUserManagementTap ??
                  () => _showComingSoon('User Management'),
            ),
            _SettingsTile(
              icon: Icons.admin_panel_settings_rounded,
              title: 'Permissions',
              onTap:
                  widget.onPermissionsTap ??
                  () => _showComingSoon('Permissions'),
            ),
            _SettingsTile(
              icon: Icons.assignment_rounded,
              title: 'Audit Log',
              onTap: widget.onAuditLogTap ?? () => _showComingSoon('Audit Log'),
            ),
            _SettingsTile(
              icon: Icons.settings_rounded,
              title: 'App Settings',
              onTap:
                  widget.onAppSettingsTap ??
                  () => _showComingSoon('App Settings'),
            ),
            _SettingsTile(
              icon: Icons.info_rounded,
              title: 'About Us',
              onTap: widget.onAboutUsTap ?? () => _showComingSoon('About Us'),
            ),
            _SettingsTile(
              icon: Icons.logout_rounded,
              title: 'Logout',
              isLogout: true,
              onTap: () => showLogoutDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.65)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: const Color(0xFFE6EFFD),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 29,
              color: Color(0xFF4777B9),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin',
                  style: TextStyle(
                    fontFamily: FontFamily.montserratBold,
                    fontSize: 13,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'admin@diamonds.com',
                  style: TextStyle(
                    fontFamily: FontFamily.montserratRegular,
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 22,
            color: AppColors.primaryDark,
          ),
        ],
      ),
    );
  }
}


class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isLogout;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    final itemColor = isLogout ? Colors.red : AppColors.primaryDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.65),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.035),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 42,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 17,
                    color: itemColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontFamily: FontFamily.montserratSemiBold,
                        fontSize: 11.5,
                        color: itemColor,
                      ),
                    ),
                  ),
                  if (!isLogout)
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 19,
                      color: AppColors.primaryDark,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

