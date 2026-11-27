
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:diamax_flutter/screens/admin/dashboard/transactions/transactions_screen.dart';
import 'package:diamax_flutter/screens/admin/reports/reports_screen.dart';
import 'package:diamax_flutter/screens/admin/stock/stock_screen.dart';

import '../../../providers/admin_bottom_navigation_proivder.dart';
import '../../../utills/app_colors.dart';
import '../more/settings_screen.dart';
import '../dashboard/dashboard_screen.dart';
import 'app_bottom_nav.dart';

class AdminNavigationScreen extends StatefulWidget {
  const AdminNavigationScreen({super.key});

  @override
  State<AdminNavigationScreen> createState() =>
      _AdminNavigationScreenState();
}

class _AdminNavigationScreenState extends State<AdminNavigationScreen> {
  late final List<Widget> screens;

  @override
  void initState() {
    super.initState();

    screens = [
      DashboardScreen(
        onViewAllTransactions: () {
          context.read<AdminNavigationProvider>().goToTransactions();
        },
      ),
      TransactionsScreen(
        onBackTap: () {
          context.read<AdminNavigationProvider>().goToDashboard();
        },
      ),
      const StockScreen(),
      const ReportsScreen(),
      SettingsScreen(
        onBackTap: () {
          context.read<AdminNavigationProvider>().goToDashboard();
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: context.select<AdminNavigationProvider, int>(
                    (provider) => provider.currentIndex,
              ),
              children: screens,
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Consumer<AdminNavigationProvider>(
                builder: (context, provider, child) {
                  return AppBottomNav(
                    currentIndex: provider.currentIndex,
                    onTap: provider.changeTab,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
