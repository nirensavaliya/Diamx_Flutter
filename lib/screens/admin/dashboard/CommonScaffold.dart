import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utills/app_colors.dart';
import '../../../utills/app_font.dart';
import '../../../utills/app_images.dart';

// One icon button on the right side of the app bar.
class AppBarAction {
  final IconData icon;
  final VoidCallback? onTap;

  // Badge number. Null or 0 = no badge.
  final int? badge;

  const AppBarAction({required this.icon, this.onTap, this.badge});

  factory AppBarAction.search({VoidCallback? onTap}) {
    return AppBarAction(icon: Icons.search_rounded, onTap: onTap);
  }

  factory AppBarAction.filter({VoidCallback? onTap, int? badge}) {
    return AppBarAction(icon: Icons.filter_alt_sharp, onTap: onTap, badge: badge);
  }

  factory AppBarAction.notification({VoidCallback? onTap, int? count}) {
    return AppBarAction(
      icon: Icons.notifications_rounded,
      onTap: onTap,
      badge: count,
    );
  }
}

// Reusable screen shell with HomeScreen-style gradient app bar.

class CommonScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<AppBarAction> actions;
  final bool showBack;
  final bool showLeading;

  final VoidCallback? onBackTap;
  final VoidCallback? onMenuTap;
  final VoidCallback? onLogoutTap;
  final Widget? drawer;
  final Widget? bottomNavigationBar;

  const CommonScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.showBack = false,
    this.showLeading = true,
    this.onBackTap,
    this.onMenuTap,
    this.onLogoutTap,
    this.drawer,
    this.bottomNavigationBar,
  });

  static const double contentHeight = 64;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final headerHeight = topPadding + contentHeight;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primaryDark,
        drawer: drawer,
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: CommonAppBar(
                title: title,
                topPadding: topPadding,
                height: headerHeight,
                actions: actions,
                onMenuTap: onMenuTap,
                onBackTap: onBackTap,
                onLogoutTap: onLogoutTap,
                showBack: showBack,
                showLeading: showLeading,
                hasDrawer: drawer != null,
              ),
            ),
            Positioned(
              top: headerHeight,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FC),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: body,
              ),
            ),
          ],
        ),
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}

// HomeScreen-style gradient app bar.
class CommonAppBar extends StatelessWidget {
  final String title;
  final double topPadding;
  final double height;
  final List<AppBarAction> actions;
  final VoidCallback? onMenuTap;
  final VoidCallback? onBackTap;
  final VoidCallback? onLogoutTap;
  final bool showBack;
  final bool showLeading;
  final bool hasDrawer;

  const CommonAppBar({
    super.key,
    required this.title,
    required this.topPadding,
    required this.height,
    this.actions = const [],
    this.onMenuTap,
    this.onBackTap,
    this.onLogoutTap,
    this.showBack = false,
    this.showLeading = true,
    this.hasDrawer = false,
  });

  @override
  Widget build(BuildContext context) {
    final isHome = title.toLowerCase() == 'home';
    final hasLeft = isHome || showLeading;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
            AppColors.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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

          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              topPadding + 14,
              20,
              10,
            ),
            child: Row(
              children: [
                if (isHome)
                  _buildDiamondLogo()
                else if (showLeading)
                  _CircleHeaderButton(
                    icon: showBack
                        ? Icons.arrow_back_ios_new_rounded
                        : Icons.menu_rounded,
                    iconSize: showBack ? 17 : 22,
                    onTap: () {
                      if (showBack) {
                        if (onBackTap != null) {
                          onBackTap!();
                        } else if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      } else if (onMenuTap != null) {
                        onMenuTap!();
                      } else if (hasDrawer) {
                        Scaffold.of(context).openDrawer();
                      }
                    },
                  ),

                if (hasLeft) const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isHome)
                        Image.asset(
                          AppImages.appLogoTwo,
                          height: 30,
                          fit: BoxFit.contain,
                          alignment: Alignment.centerLeft,
                        )
                      else
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: FontFamily.montserratBold,
                            color: AppColors.white,
                            fontSize: 19,
                          ),
                        ),
                    ],
                  ),
                ),

                if (isHome)
                  _CircleHeaderButton(
                    icon: Icons.logout_rounded,
                    onTap: onLogoutTap,
                  )
                else if (actions.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final action in actions)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _CircleHeaderButton(
                            icon: action.icon,
                            badge: action.badge,
                            onTap: action.onTap,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiamondLogo() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white.withValues(alpha: 0.14)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Image.asset(AppImages.imgDiamond, fit: BoxFit.contain),
      ),
    );
  }
}

class _CircleHeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double iconSize;
  final int? badge;

  const _CircleHeaderButton({
    required this.icon,
    this.onTap,
    this.iconSize = 20,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final count = badge ?? 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.14),
              ),
            ),
            child: Icon(icon, color: AppColors.white, size: iconSize),
          ),
          if (count > 0)
            Positioned(
              right: -2,
              top: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                padding: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryDark, width: 1.2),
                ),
                alignment: Alignment.center,
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
