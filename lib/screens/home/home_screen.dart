import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/login.dart';
import '../../models/memo.dart';
import '../../providers/memo_provider.dart';
import '../../providers/permission_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/get_stroage_data.dart';
import '../../utills/app_colors.dart';
import '../../utills/app_font.dart';
import '../../utills/app_images.dart';
import '../../utills/global.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MemoProvider()),
        ChangeNotifierProvider(create: (_) => PermissionProvider()),
      ],
      child: const _HomeContent(),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _HomeAppBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _WelcomeBanner(),
                const SizedBox(height: 26),
                const _SectionTitle(
                  title: 'Quick Access',
                  subtitle: 'Everything you need in one place',
                ),
                const SizedBox(height: 14),
                const _QuickAccessCards(),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickAccessCards extends StatelessWidget {
  const _QuickAccessCards();

  @override
  Widget build(BuildContext context) {
    return Consumer<PermissionProvider>(
      builder: (context, permissions, _) {
        final cards = <Widget>[
          if (permissions.canViewMemoDelivery)
            _FeatureCard(
              title: 'Memo Delivery',
              description: 'Create, review and share diamond memos',
              icon: Icons.description_outlined,
              color: AppColors.primary,
              onTap: () => Navigator.pushNamed(context, AppRoutes.memo),
            ),
          if (permissions.canViewSaleDelivery)
            _FeatureCard(
              title: 'Invoice Delivery',
              description: 'Track and manage all your invoices',
              icon: Icons.receipt_long_outlined,
              color: AppColors.accentDark,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.invoiceList),
            ),
          if (permissions.canViewMemoOfficeDelivery)
            _FeatureCard(
              title: 'Memo Office Delivery',
              description: 'Handle office memo deliveries',
              icon: Icons.business_center_outlined,
              color: AppColors.primaryLight,
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.memoOfficeDelivery,
              ),
            ),
          if (permissions.canViewSaleOfficeDelivery)
            _FeatureCard(
              title: 'Invoice Office Delivery',
              description: 'Handle office invoice deliveries',
              icon: Icons.apartment_outlined,
              color: AppColors.accent,
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.invoiceOfficeDelivery,
              ),
            ),
        ];

        if (cards.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
            child: Text(
              'No delivery modules are available for your account.',
              style: TextStyle(
                fontFamily: FontFamily.montserratRegular,
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 12.0;
            final cardWidth = (constraints.maxWidth - spacing) / 2;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final card in cards)
                  SizedBox(width: cardWidth, child: card),
              ],
            );
          },
        );
      },
    );
  }
}

class _HomeAppBar extends StatelessWidget {
  const _HomeAppBar();

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
            right: -24,
            top: -18,
            child: Icon(
              Icons.diamond_outlined,
              size: 120,
              color: AppColors.white.withValues(alpha: 0.08),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(9),
                      child: Image.asset(
                        AppImages.imgDiamond,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good afternoon',
                          style: TextStyle(
                            fontFamily: FontFamily.montserratRegular,
                            color: AppColors.white.withValues(alpha: 0.9),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Image.asset(
                          AppImages.appLogoTwo,
                          height: 30,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => showLogoutDialog(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.14),
                        ),
                      ),
                      child: const Icon(
                        Icons.logout,
                        color: AppColors.white,
                        size: 20,
                      ),
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

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner();

  LoginUser? _readLoginUser() {
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

  @override
  Widget build(BuildContext context) {
    final loginUser = _readLoginUser();
    final userName = loginUser?.fullName.trim() ?? '';
    final branchName = loginUser?.branchName.trim() ?? '';
    final infoParts = <String>[
      if (userName.isNotEmpty) userName,
      if (branchName.isNotEmpty) branchName,
    ];
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 190),
      padding: const EdgeInsets.fromLTRB(22, 23, 20, 21),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
          stops: [0, 0.58, 1],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -38,
            top: -46,
            child: Container(
              width: 148,
              height: 148,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.08),
                  width: 28,
                ),
              ),
            ),
          ),
          Positioned(
            right: -4,
            bottom: -20,
            child: Icon(
              Icons.diamond_outlined,
              color: AppColors.white.withValues(alpha: 0.11),
              size: 138,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Diamond Workspace',
                style: TextStyle(
                  fontFamily: FontFamily.montserratBold,
                  color: AppColors.white,
                  fontSize: 19,
                ),
              ),
              const SizedBox(height: 9),
              SizedBox(
                width: 215,
                child: Text(
                  'Manage every memo and invoice with clarity and confidence.',
                  style: TextStyle(
                    fontFamily: FontFamily.montserratRegular,
                    color: AppColors.white.withValues(alpha: 0.78),
                    fontSize: 11,
                    height: 1.55,
                  ),
                ),
              ),
              if (infoParts.isNotEmpty) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Text(
                    infoParts.join(' · '),
                    style: TextStyle(
                      fontFamily: FontFamily.montserratSemiBold,
                      color: AppColors.secondary,
                      fontSize: 10,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: FontFamily.montserratBold,
            color: AppColors.textPrimary,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontFamily: FontFamily.montserratRegular,
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.85)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 13),
          Text(
            value,
            style: TextStyle(
              fontFamily: FontFamily.montserratExtraBold,
              color: AppColors.textPrimary,
              fontSize: 21,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: FontFamily.montserratMedium,
              color: AppColors.textSecondary,
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 170,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.9),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.045),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: AppColors.white, size: 22),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.north_east_rounded,
                      color: color,
                      size: 15,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontFamily: FontFamily.montserratBold,
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: FontFamily.montserratRegular,
                  color: AppColors.textSecondary,
                  fontSize: 9.5,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentMemoCard extends StatelessWidget {
  const _RecentMemoCard({required this.memo, required this.onTap});

  final Memo memo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPending = memo.status == MemoStatus.pending;
    final statusColor = isPending ? AppColors.accentDark : AppColors.success;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.75),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Image.asset(
                    AppImages.imgDiamond,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memo.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: FontFamily.montserratSemiBold,
                        color: AppColors.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${memo.id}  •  ${memo.diamonds.length} diamonds',
                      style: TextStyle(
                        fontFamily: FontFamily.montserratRegular,
                        color: AppColors.textSecondary,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  memo.statusLabel,
                  style: TextStyle(
                    fontFamily: FontFamily.montserratSemiBold,
                    color: statusColor,
                    fontSize: 8.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
