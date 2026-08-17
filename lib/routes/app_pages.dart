import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/invoice.dart';
import '../models/memo.dart';
import '../providers/bottom_navigation_provider.dart';
import '../providers/company_code_provider.dart';
import '../providers/invoice_print_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/login_provider.dart';
import '../providers/memo_print_provider.dart';
import '../providers/memo_provider.dart';
import '../screens/company_code/company_code_screen.dart';
import '../screens/invoice/invoice_detail_screen.dart';
import '../screens/invoice/invoice_list_screen.dart';
import '../screens/invoice/invoice_print_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/main/main_screen.dart';
import '../screens/memo/memo_detail_screen.dart';
import '../screens/memo/memo_print_screen.dart';
import '../screens/memo/memo_screen.dart';
import '../screens/splash/splash_screen.dart';
import 'app_routes.dart';

class AppPages {
  static Map<String, WidgetBuilder> get routes => {
    AppRoutes.splash: (_) => const SplashScreen(),
    AppRoutes.companyCode: (_) => ChangeNotifierProvider(
      create: (_) => CompanyCodeProvider(),
      child: const CompanyCodeScreen(),
    ),
    AppRoutes.login: (_) => ChangeNotifierProvider(
      create: (_) => LoginProvider(),
      child: const LoginScreen(),
    ),
    AppRoutes.main: (_) => ChangeNotifierProvider(
      create: (_) => BottomNavigationProvider(),
      child: const MainScreen(),
    ),
    AppRoutes.memo: (_) => ChangeNotifierProvider(
      create: (_) => MemoProvider(),
      child: const MemoScreen(),
    ),
    AppRoutes.memoDetail: (context) {
      final memo = ModalRoute.of(context)!.settings.arguments! as Memo;
      return ChangeNotifierProvider(
        create: (_) => MemoProvider(bootstrap: false),
        child: MemoDetailScreen(memo: memo),
      );
    },
    AppRoutes.memoPrint: (context) {
      final memo = ModalRoute.of(context)!.settings.arguments! as Memo;
      return ChangeNotifierProvider(
        create: (_) => MemoPrintProvider(memo),
        child: const MemoPrintScreen(),
      );
    },
    AppRoutes.invoiceList: (_) => ChangeNotifierProvider(
      create: (_) => InvoiceProvider(),
      child: const InvoiceListScreen(),
    ),
    AppRoutes.invoiceDetail: (context) {
      final invoice = ModalRoute.of(context)!.settings.arguments! as Invoice;
      return ChangeNotifierProvider(
        create: (_) => InvoiceProvider(bootstrap: false),
        child: InvoiceDetailScreen(invoice: invoice),
      );
    },
    AppRoutes.invoicePrint: (context) {
      final invoice = ModalRoute.of(context)!.settings.arguments! as Invoice;
      return ChangeNotifierProvider(
        create: (_) => InvoicePrintProvider(invoice),
        child: const InvoicePrintScreen(),
      );
    },
  };
}
