import 'dart:io';

import 'package:diamax_flutter/constant/api_constants.dart';
import 'package:diamax_flutter/main.dart';
import 'package:diamax_flutter/providers/login_provider.dart';
import 'package:diamax_flutter/providers/splash_provider.dart';
import 'package:diamax_flutter/services/api_service.dart';
import 'package:diamax_flutter/services/get_stroage_data.dart';
import 'package:diamax_flutter/services/navigation_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePathProvider extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }
}

class _FakeApiService extends ApiService {
  _FakeApiService() : super();

  @override
  Future<Map<String, dynamic>> confirmProductId({
    required String productId,
  }) async {
    if (productId == 'LOC101') {
      return {'IsSuccess': false, 'Message': 'Manual entry required'};
    }
    return {'IsSuccess': true, 'Message': 'OK'};
  }

  @override
  Future<Response> postRequest(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
  }) async {
    if (endpoint == ApiConstants.getAllBranch) {
      return Response(
        requestOptions: RequestOptions(path: endpoint),
        statusCode: 200,
        data: {
          'Message': 'Get data successfully',
          'Error': '',
          'Result': [
            {
              'Ledger_Id': 1,
              'Ledger_Name': 'HONG KONG',
              'Short_Name': 'HK',
              'Group_Name': 'Branch / Divisions',
              'Currency_Id': 6,
              'Convert_By': 1,
              'Currency_Name': 'USD',
              'Stock_Currency_ID': 6,
              'Is_Bill_By_Bill': true,
              'Base_Currency': 6,
              'MailAddress': null,
              'Mail_Country_Id': 98,
              'Mail_State_Id': 1636,
              'Mail_City_Id': 0,
              'ShipAddress': null,
              'Ship_Country_Id': 98,
              'Ship_State_Id': 1636,
              'Ship_City_Id': 0,
              'Country_Name': 'Hong Kong S.A.R.',
              'Location': 'HONG KONG, HONG KONG S.A.R.',
              'ShippingLocation': 'HONG KONG, HONG KONG S.A.R.',
              'Discount': 0,
              'Bill_Type': null,
              'DefaultStockLocationID': 450,
            },
            {
              'Ledger_Id': 1265,
              'Ledger_Name': 'MUMBAI',
              'Short_Name': 'MUMBAI',
              'Group_Name': 'Branch / Divisions',
              'Currency_Id': 1,
              'Convert_By': 75,
              'Currency_Name': 'INR',
              'Stock_Currency_ID': 6,
              'Is_Bill_By_Bill': false,
              'Base_Currency': 1,
              'MailAddress': null,
              'Mail_Country_Id': 0,
              'Mail_State_Id': 0,
              'Mail_City_Id': 0,
              'ShipAddress': null,
              'Ship_Country_Id': 0,
              'Ship_State_Id': 0,
              'Ship_City_Id': 0,
              'Country_Name': null,
              'Location': null,
              'ShippingLocation': null,
              'Discount': 0,
              'Bill_Type': null,
              'DefaultStockLocationID': 451,
            },
          ],
        },
      );
    }

    if (endpoint == ApiConstants.login) {
      return Response(
        requestOptions: RequestOptions(path: endpoint),
        statusCode: 200,
        data: {
          'Message': 'Login Successfully',
          'Error': '',
          'Result': {
            'login': {
              'UserID': 1022,
              'Full_Name': 'demo',
              'Login_Name': 'demo',
              'Branch_Name': 'HONG KONG',
              'Branch_Id': 1,
              'Department_ID': 1,
              'Department_Name': 'ADMIN HK',
              'Location_ID': 450,
              'DefaultStockLocationID': 450,
              'Loaction': 'HK',
              'Base_Currency': 6,
              'Currency_Decimal': 2,
              'YearID': 18,
              'YearName': '22 - 27',
              'LoginToken': 'TEST-TOKEN',
              'Company_Name': 'Cravita Technologies',
              'Is_show_all_Ledger': false,
              'Role_ID': 2,
              'FromYear': '01/04/2022',
              'ToYear': '31/03/2027',
              'lang': 'en',
              'Stock_Currency_ID': 6,
              'Currency_Name': 'USD',
              'BranchIDs': '1',
              'Department_IDs': '1',
              'Enable_Notifcation_Alert': '1',
              'MFG_Dept_ID': 1,
              'Is_SuperAdmin': false,
              'IdealTime': '2026-08-07T11:20:37.457',
              'Mix_Currency_Decimal': 0,
              'Rough_Currency_Decimal': 0,
              'Certified_Carat_Decimal': 1,
              'Mix_Certified_Carat_Decimal': 0,
              'Rough_Certified_Carat_Decimal': 2,
              'Time_Out': 0,
              'TwoFA_Auth': false,
              'Is_VerifyTwoFA_Auth': false,
              'PartyKYC_Approve': false,
              'StoneHoldDays': 0,
              'Is_Not_Allow_BackDays': false,
              'Not_Allow_Back_Days': 0,
              'Product_ID': '',
              'E_Product': false,
              'Is_PriceWise': false,
              'Is_Admin': false,
              'Mail_State_Id': 0,
              'State_Name': null,
              'Not_Edit_Delete_Days': 0,
            },
            'DepartmentList': [],
            'BranchList': [],
            'Yearlist': [],
            'Notification': [],
            'CurrancyCalCulationFlags': [],
            'Branch_CurrancyRoundOffdetail': [],
            'RfidDevices': [],
          },
          'IsSessionExpire': false,
          'IsSuccess': true,
          'StatusCode': '200',
        },
      );
    }

    if (endpoint == ApiConstants.getPartyList) {
      return Response(
        requestOptions: RequestOptions(path: endpoint),
        statusCode: 200,
        data: {
          'Message': 'Get data successfully',
          'Error': '',
          'Result': {
            'rows': [
              {
                'Ledger_Id': 6454,
                'Ledger_Name': 'RUSHITA',
                'Short_Name': 'RUSHITA',
                'Group_Name': 'Sundry Debitors',
                'Currency_Id': 6,
                'Currency_Name': 'USD',
                'Convert_By': 1,
                'MailAddress': null,
                'Mail_Country_Id': 0,
                'Mail_State_Id': 0,
                'Mail_City_Id': 0,
                'ShipAddress': null,
                'Ship_Country_Id': 0,
                'Ship_State_Id': 0,
                'Ship_City_Id': 0,
                'Country_Name': null,
                'Location': null,
                'ShippingLocation': null,
                'Is_Bill_By_Bill': true,
                'Discount': 0,
                'Bill_Type': null,
                'BranchId': 1,
                'Group_Id': 10,
              },
            ],
          },
          'IsSessionExpire': false,
          'IsSuccess': true,
          'StatusCode': '200',
        },
      );
    }

    if (endpoint == ApiConstants.getMemoIssueDelivery) {
      return Response(
        requestOptions: RequestOptions(path: endpoint),
        statusCode: 200,
        data: {
          'Message': 'Get data successfully',
          'Error': '',
          'Result': [
            {
              'Memo_ID': 1001,
              'Memo_No': 'MEM-1001',
              'Memo_Date': '28/07/2026',
              'Branch_Name': 'HONG KONG',
              'Party_Name': 'Round Diamond Selection',
              'Total_Stone': 2,
              'Total_PacketPcs': 2,
              'Total_Carat': 1.800,
              'Total_Amt': 8730.00,
              'Price_Per_Cts': 4850.00,
              'Gross_Amt': 8730.00,
              'Net_Amt': 8730.00,
              'PendingStone': 2,
              'PendingCts': 1.800,
              'PendindRate': 4850.00,
              'PendingAmount': 8730.00,
              'Entry_By': 'demo',
              'Deliver_By': 'mehul',
              'Delivered_Status': 'PENDING',
            },
          ],
          'IsSessionExpire': false,
          'IsSuccess': true,
          'StatusCode': '200',
        },
      );
    }

    // if (endpoint == ApiConstants.getMemoIssueSummaryDetail) {
    //   return Response(
    //     requestOptions: RequestOptions(path: endpoint),
    //     statusCode: 200,
    //     data: {
    //       'Message': 'Get data successfully',
    //       'Error': '',
    //       'Result': {
    //         'rows': [
    //           {
    //             'available': false,
    //             'Memo_ID': 1001,
    //             'Memo_No': 'MEM-1001',
    //             'Memo_Date': '28/07/2026',
    //             'SearchMemoDate': '2026-07-28T00:00:00',
    //             'Branch_Name': 'HONG KONG',
    //             'Party_Name': 'Round Diamond Selection',
    //             'Party_Country': 'India',
    //             'Party_ID': 6454,
    //             'Currency_Name': 'USD',
    //             'Convert_By': 1,
    //             'Total_Stone': 3,
    //             'Total_Carat': 1.800,
    //             'Total_Amt': 8730.00,
    //             'Price_Per_Cts': 4850.00,
    //             'Gross_Amt': 8730.00,
    //             'Net_Amt': 8730.00,
    //             'Average_Price': 4850.00,
    //             'AfterCurrencyValue': 8730.00,
    //             'Voucher_Name': 'MEMO',
    //             'Memo_Status': 'PENDING',
    //             'PendingStone': 3,
    //             'BillType': 'LOCAL SALES',
    //             'PendingCts': 1.800,
    //             'PendingAmount': 8730.00,
    //             'Is_Delivered': false,
    //             'Sales_Person': 'demo',
    //             'Remark': 'Premium round diamonds selected for client approval.',
    //           },
    //         ],
    //         'TotalPcs': 3,
    //         'TotalCts': 1.8,
    //         'TotalRate': 4850,
    //         'TotalAmt': 8730,
    //         'TotalCount': 1,
    //       },
    //       'IsSessionExpire': false,
    //       'IsSuccess': true,
    //       'StatusCode': '200',
    //     },
    //   );
    // }

    return Response(
      requestOptions: RequestOptions(path: endpoint),
      statusCode: 404,
      data: {'IsSuccess': false, 'Message': 'Unknown endpoint'},
    );
  }
}

void main() {
  setUpAll(() async {
    PathProviderPlatform.instance = _FakePathProvider();
    await GetStorage.init();
  });

  setUp(() {
    ApiService.debugOverride(_FakeApiService());
  });

  tearDown(() {
    ApiService.debugOverride(null);
    GetStorageData.removeData(GetStorageData.token);
    GetStorageData.removeData(GetStorageData.loginData);
  });

  testWidgets('navigates from splash through memo print flow', (
    WidgetTester tester,
  ) async {
    await _launchToHome(tester);

    expect(find.text('Quick Access'), findsOneWidget);
    expect(find.text('Memo'), findsOneWidget);
    expect(find.text('Invoice List'), findsOneWidget);

    await tester.ensureVisible(find.text('Memo'));
    await tester.tap(find.text('Memo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Pcs'), findsWidgets);
    expect(find.text('Count'), findsWidgets);
    expect(find.text('Rate'), findsWidgets);

    await tester.ensureVisible(find.text('Round Diamond Selection'));
    await tester.tap(find.text('Round Diamond Selection'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Memo Details'), findsOneWidget);
    expect(find.text('Diamond Details'), findsOneWidget);
    expect(find.text('PRINT MEMO'), findsOneWidget);

    await tester.tap(find.text('PRINT MEMO'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Select Diamonds'), findsOneWidget);
    expect(find.text('Upload Signature'), findsOneWidget);
    expect(find.text('GENERATE & DOWNLOAD PDF'), findsOneWidget);
  });

  testWidgets('navigates from home through invoice print flow', (
    WidgetTester tester,
  ) async {
    await _launchToHome(tester);

    await tester.ensureVisible(find.text('Invoice List'));
    await tester.tap(find.text('Invoice List'));
    await tester.pumpAndSettle();

    expect(find.text('Invoices'), findsOneWidget);
    expect(find.text('All Invoices'), findsOneWidget);
    expect(find.text('Round Diamond Invoice'), findsOneWidget);

    await tester.tap(find.text('Round Diamond Invoice'));
    await tester.pumpAndSettle();

    expect(find.text('Invoice Details'), findsOneWidget);
    expect(find.text('Diamond Details'), findsOneWidget);
    expect(find.text('PRINT INVOICE'), findsOneWidget);

    await tester.tap(find.text('PRINT INVOICE'));
    await tester.pumpAndSettle();

    expect(find.text('Print Invoice'), findsOneWidget);
    expect(find.text('Select Diamonds'), findsOneWidget);
    expect(find.text('Add Signature'), findsOneWidget);
    expect(find.text('GENERATE & DOWNLOAD INVOICE'), findsOneWidget);
  });

  testWidgets('saves client code and skips company screen on next launch', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    var navigationService = NavigationService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: navigationService),
          ChangeNotifierProvider(
            lazy: false,
            create: (_) => SplashProvider(navigationService),
          ),
        ],
        child: MyApp(navigationService: navigationService),
      ),
    );

    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(find.text('Enter Your Client Code'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ABC123');
    await tester.tap(find.text('Save Client Code'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('client_code'), 'ABC123');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    navigationService = NavigationService();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: navigationService),
          ChangeNotifierProvider(
            lazy: false,
            create: (_) => SplashProvider(navigationService),
          ),
        ],
        child: MyApp(navigationService: navigationService),
      ),
    );

    await tester.pump(const Duration(seconds: 5));
    await tester.pump();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Enter Your Client Code'), findsNothing);
  });
}

Future<void> _launchToHome(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({'client_code': 'ABC123'});
  final navigationService = NavigationService();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider.value(value: navigationService),
        ChangeNotifierProvider(
          lazy: false,
          create: (_) => SplashProvider(navigationService),
        ),
      ],
      child: MyApp(navigationService: navigationService),
    ),
  );

  expect(find.text('DIAMX'), findsOneWidget);
  await tester.pump(const Duration(seconds: 5));
  await tester.pump();

  expect(find.text('Welcome Back'), findsOneWidget);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));

  await tester.enterText(find.byType(TextField).at(0), 'demo');
  await tester.enterText(find.byType(TextField).at(1), 'password');

  final loginContext = tester.element(find.text('Welcome Back'));
  final loginProvider = Provider.of<LoginProvider>(loginContext, listen: false);
  expect(loginProvider.branches, isNotEmpty);
  loginProvider.selectBranch(loginProvider.branches.first);
  await tester.pump();

  await tester.ensureVisible(find.text('LOGIN'));
  await tester.tap(find.text('LOGIN'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pumpAndSettle();
}
