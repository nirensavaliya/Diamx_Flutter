
import 'package:diamax_flutter/screens/admin/dashboard/transactions/transactions_screen.dart';
import 'package:diamax_flutter/screens/admin/reports/reports_screen.dart';
import 'package:diamax_flutter/screens/admin/stock/stock_screen.dart';
import 'package:flutter/material.dart';

import '../more/settings_screen.dart';
import 'app_bottom_nav.dart';
import '../dashboard/dashboard_screen.dart';

class AdminNavigationScreen extends StatefulWidget {
  const AdminNavigationScreen({super.key});

  @override
  State<AdminNavigationScreen> createState() =>
      _AdminNavigationScreenState();
}

class _AdminNavigationScreenState extends State<AdminNavigationScreen> {
  static const Color _backgroundColor = Color(0xFFF7F8FC);

  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = [
      DashboardScreen(
        onViewAllTransactions: () => _onTabChanged(1),
      ),
      TransactionsScreen(
        onBackTap: () => _onTabChanged(0),
      ),
      const StockScreen(),
      const ReportsScreen(),
      SettingsScreen(
        onBackTap: () => _onTabChanged(0),
      ),
    ];
  }

  void _onTabChanged(int index) {
    if (!mounted) return;

    if (index < 0 || index >= _screens.length) return;

    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: AppBottomNav(
                currentIndex: _currentIndex,
                onTap: _onTabChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
