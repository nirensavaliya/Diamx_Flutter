import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/bottom_navigation_provider.dart';
import '../../utills/app_colors.dart';
import '../../utills/app_font.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final NotchBottomBarController _notchController;

  @override
  void initState() {
    super.initState();
    _notchController = NotchBottomBarController(
      index: context.read<BottomNavigationProvider>().currentIndex,
    );
  }

  @override
  void dispose() {
    _notchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BottomNavigationProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          extendBody: true,
          backgroundColor: AppColors.background,
          body: IndexedStack(
            index: provider.currentIndex,
            children: const [HomeScreen(), ProfileScreen()],
          ),
          bottomNavigationBar: AnimatedNotchBottomBar(
            notchBottomBarController: _notchController,
            color: AppColors.primaryDark,
            notchColor: AppColors.accent,
            notchGradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.accent, AppColors.primaryLight],
            ),
            showShadow: true,
            shadowElevation: 12,
            elevation: 8,
            showLabel: true,
            itemLabelStyle: TextStyle(
              fontFamily: FontFamily.montserratSemiBold,
              color: AppColors.white,
              fontSize: 11,
            ),
            durationInMilliSeconds: 300,
            bottomBarHeight: 72,
            kIconSize: 24,
            kBottomRadius: 28,
            circleMargin: 8,
            topMargin: 10,
            bottomBarItems: const [
              BottomBarItem(
                inActiveItem: Icon(Icons.home_outlined, color: Colors.white70),
                activeItem: Icon(
                  Icons.home_rounded,
                  color: AppColors.primaryDark,
                ),
                itemLabel: 'Home',
              ),
              BottomBarItem(
                inActiveItem: Icon(
                  Icons.person_outline_rounded,
                  color: Colors.white70,
                ),
                activeItem: Icon(
                  Icons.person_rounded,
                  color: AppColors.primaryDark,
                ),
                itemLabel: 'Profile',
              ),
            ],
            onTap: provider.changeTab,
          ),
        );
      },
    );
  }
}
