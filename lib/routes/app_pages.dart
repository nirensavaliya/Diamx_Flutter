import 'package:diamax_flutter/providers/admin_bottom_navigation_proivder.dart';
import 'package:diamax_flutter/screens/invoice-office-delivery/invoice_office_delivery_detail_screen.dart';
import 'package:diamax_flutter/screens/invoice-office-delivery/invoice_office_delivery_print_screen.dart';
import 'package:diamax_flutter/screens/invoice-office-delivery/invoice_office_delivery_screen.dart';
import 'package:diamax_flutter/screens/memo-office-delivery/memo_office_delivery_detail_screen.dart';
import 'package:diamax_flutter/screens/memo-office-delivery/memo_office_delivery_print_screen.dart';
import 'package:diamax_flutter/screens/memo-office-delivery/memo_office_delivery_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/invoice.dart';
import '../models/memo.dart';
import '../providers/bottom_navigation_provider.dart';
import '../providers/company_code_provider.dart';
import '../providers/invoice_office_delivery_print_provider.dart';
import '../providers/invoice_office_delivery_provider.dart';
import '../providers/invoice_print_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/login_provider.dart';
import '../providers/memo_office_delivery_print_provider.dart';
import '../providers/memo_office_delivery_provider.dart';
import '../providers/memo_print_provider.dart';
import '../providers/memo_provider.dart';
import '../screens/admin/navigation/admin_navigation_screen.dart';
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
      final args = ModalRoute.of(context)!.settings.arguments;
      late final Memo memo;
      String? listDeliveredStatus;
      if (args is Memo) {
        memo = args;
      } else if (args is Map) {
        memo = args['memo'] as Memo;
        listDeliveredStatus = args['deliveredStatus']?.toString();
      } else {
        throw StateError('MemoDetail requires Memo arguments');
      }

      final initialStatus =
          (listDeliveredStatus != null && listDeliveredStatus.trim().isNotEmpty)
          ? listDeliveredStatus
          : MemoProvider.deliveredStatusFromMemo(memo);

      return ChangeNotifierProvider(
        create: (_) => MemoProvider(
          bootstrap: false,
          initialDeliveredStatus: initialStatus,
        ),
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
      final args = ModalRoute.of(context)!.settings.arguments;
      late final Invoice invoice;
      String? listDeliveredStatus;
      if (args is Invoice) {
        invoice = args;
      } else if (args is Map) {
        invoice = args['invoice'] as Invoice;
        listDeliveredStatus = args['deliveredStatus']?.toString();
      } else {
        throw StateError('InvoiceDetail requires Invoice arguments');
      }

      final initialStatus =
          (listDeliveredStatus != null && listDeliveredStatus.trim().isNotEmpty)
          ? listDeliveredStatus
          : InvoiceProvider.deliveredStatusFromInvoice(invoice);

      return ChangeNotifierProvider(
        create: (_) => InvoiceProvider(
          bootstrap: false,
          initialDeliveredStatus: initialStatus,
        ),
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
    AppRoutes.memoOfficeDelivery: (_) => ChangeNotifierProvider(
      create: (_) => MemoOfficeDeliveryProvider(),
      child: const MemoOfficeDeliveryScreen(),
    ),
    AppRoutes.memoOfficeDeliveryDetail: (context) {
      final args = ModalRoute.of(context)!.settings.arguments;
      late final Memo memo;
      String? listDeliveredStatus;
      if (args is Memo) {
        memo = args;
      } else if (args is Map) {
        memo = args['memo'] as Memo;
        listDeliveredStatus = args['deliveredStatus']?.toString();
      } else {
        throw StateError('MemoOfficeDeliveryDetail requires Memo arguments');
      }

      final initialStatus =
          (listDeliveredStatus != null && listDeliveredStatus.trim().isNotEmpty)
          ? listDeliveredStatus
          : MemoOfficeDeliveryProvider.deliveredStatusFromMemo(memo);

      return ChangeNotifierProvider(
        create: (_) => MemoOfficeDeliveryProvider(
          bootstrap: false,
          initialDeliveredStatus: initialStatus,
        ),
        child: MemoOfficeDeliveryDetailScreen(memo: memo),
      );
    },
    AppRoutes.memoOfficeDeliveryPrint: (context) {
      final memo = ModalRoute.of(context)!.settings.arguments! as Memo;
      return ChangeNotifierProvider(
        create: (_) => MemoOfficeDeliveryPrintProvider(memo),
        child: const MemoOfficeDeliveryPrintScreen(),
      );
    },
    AppRoutes.invoiceOfficeDelivery: (_) => ChangeNotifierProvider(
      create: (_) => InvoiceOfficeDeliveryProvider(),
      child: const InvoiceOfficeDeliveryScreen(),
    ),
    AppRoutes.invoiceOfficeDeliveryDetail: (context) {
      final args = ModalRoute.of(context)!.settings.arguments;
      late final Invoice invoice;
      String? listDeliveredStatus;
      if (args is Invoice) {
        invoice = args;
      } else if (args is Map) {
        invoice = args['invoice'] as Invoice;
        listDeliveredStatus = args['deliveredStatus']?.toString();
      } else {
        throw StateError(
          'InvoiceOfficeDeliveryDetail requires Invoice arguments',
        );
      }

      final initialStatus =
          (listDeliveredStatus != null && listDeliveredStatus.trim().isNotEmpty)
          ? listDeliveredStatus
          : InvoiceOfficeDeliveryProvider.deliveredStatusFromInvoice(invoice);

      return ChangeNotifierProvider(
        create: (_) => InvoiceOfficeDeliveryProvider(
          bootstrap: false,
          initialDeliveredStatus: initialStatus,
        ),
        child: InvoiceOfficeDeliveryDetailScreen(invoice: invoice),
      );
    },
    AppRoutes.invoiceOfficeDeliveryPrint: (context) {
      final invoice = ModalRoute.of(context)!.settings.arguments! as Invoice;
      return ChangeNotifierProvider(
        create: (_) => InvoiceOfficeDeliveryPrintProvider(invoice),
        child: const InvoiceOfficeDeliveryPrintScreen(),
      );
    },

    AppRoutes.adminDashboard: (_)  => ChangeNotifierProvider(
      create: (_) => AdminNavigationProvider(),
      child: const AdminNavigationScreen(),
    ),
  };
}
