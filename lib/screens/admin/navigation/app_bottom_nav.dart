import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';

import '../../../utills/app_colors.dart';
import '../../../utills/app_font.dart';

class AppBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav> {
  static const int _itemCount = 5;

  late final NotchBottomBarController _controller;

  int _selectedIndex = 0;
  bool _isDisposed = false;

  int _validIndex(int index) {
    return index.clamp(0, _itemCount - 1);
  }

  @override
  void initState() {
    super.initState();

    _selectedIndex = _validIndex(widget.currentIndex);

    _controller = NotchBottomBarController(index: _selectedIndex);
  }

  @override
  void didUpdateWidget(covariant AppBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newIndex = _validIndex(widget.currentIndex);

    if (newIndex != _selectedIndex) {
      _selectedIndex = newIndex;
      _controller.jumpTo(newIndex);
    }
  }

  void _handleTap(int index) {
    if (_isDisposed) return;

    final newIndex = _validIndex(index);

    // Prevent duplicate taps on the selected tab.
    if (newIndex == _selectedIndex) return;

    // Update the selection immediately.
    setState(() {
      _selectedIndex = newIndex;
    });

    // Notify the parent screen.
    widget.onTap(newIndex);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      width: double.infinity,
      child: AnimatedNotchBottomBar(
        bottomBarWidth: MediaQuery.of(context).size.width,
        removeMargins: false,
        notchBottomBarController: _controller,
        color: AppColors.primaryDark,
        notchColor: AppColors.accent,
        notchGradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent, AppColors.primaryLight],
        ),
        showShadow: false,
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
            activeItem: Icon(Icons.home_rounded, color: AppColors.white),
            itemLabel: 'Home',
          ),
          BottomBarItem(
            inActiveItem: Icon(
              Icons.receipt_long_outlined,
              color: Colors.white70,
            ),
            activeItem: Icon(
              Icons.receipt_long_rounded,
              color:AppColors.white,
            ),
            itemLabel: 'Transactions',
          ),
          BottomBarItem(
            inActiveItem: Icon(
              Icons.inventory_2_outlined,
              color: Colors.white70,
            ),
            activeItem: Icon(
              Icons.inventory_2_rounded,
              color: AppColors.white,
            ),
            itemLabel: 'Stock',
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.bar_chart_outlined, color: Colors.white70),
            activeItem: Icon(
              Icons.bar_chart_rounded,
              color: AppColors.white,
            ),
            itemLabel: 'Reports',
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.more_horiz_rounded, color: Colors.white70),
            activeItem: Icon(
              Icons.more_horiz_rounded,
              color: AppColors.white,
            ),
            itemLabel: 'More',
          ),
        ],

        onTap: _handleTap,
      ),
    );
  }
}
