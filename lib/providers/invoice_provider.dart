import 'dart:convert';

import 'package:flutter/material.dart';

import '../constant/api_constants.dart';
import '../models/invoice.dart';
import '../models/login.dart';
import '../services/api_service.dart';
import '../services/client_code_storage.dart';
import '../services/get_stroage_data.dart';

class InvoiceProvider extends ChangeNotifier {
  InvoiceProvider({
    this.clientCodeStorage = const ClientCodeStorage(),
    ApiService? apiService,
    bool bootstrap = true,
  }) : apiService = apiService ?? ApiService.shared() {
    searchController.addListener(_filterInvoices);
    if (bootstrap) {
      _bootstrap();
    }
  }

  final ClientCodeStorage clientCodeStorage;
  final ApiService apiService;

  final TextEditingController searchController = TextEditingController();
  List<Invoice> _invoices = [];
  List<Invoice> _filteredInvoices = [];

  bool _isInvoicesLoading = false;
  String? _invoicesError;
  int _totalCount = 0;
  double _totalPcs = 0;
  double _totalRate = 0;

  List<Invoice> get invoices => List.unmodifiable(_filteredInvoices);
  int get totalInvoices => _totalCount > 0 ? _totalCount : _invoices.length;
  double get totalPcs => _totalPcs;
  double get totalRate => _totalRate;
  int get totalCount => _totalCount;
  int get pendingInvoices => _invoices
      .where((invoice) => invoice.status == InvoiceStatus.pending)
      .length;
  int get paidInvoices =>
      _invoices.where((invoice) => invoice.status == InvoiceStatus.paid).length;

  bool get isInvoicesLoading => _isInvoicesLoading;
  String? get invoicesError => _invoicesError;

  Future<void> _bootstrap() async {
    await loadInvoices();
  }

  LoginUser? _readSavedLoginUser() {
    final raw = GetStorageData.readString(GetStorageData.loginData);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final result = LoginResult.fromJson(Map<String, dynamic>.from(decoded));
      return result.login;
    } catch (_) {
      return null;
    }
  }

  Future<InvoiceSummaryResponse> getInvoiceSummary({
    required LoginUser loginUser,
    required String productId,
    String partyIds = '',
    String orderNumbers = '',
    int type = 1,
  }) async {
    final response = await apiService.postRequest(
      ApiConstants.getInvoiceSummaryDetail,
      data: {
        'login': loginUser.toJson(),
        'filters': {
          'UserID': loginUser.userId,
          'BranchID': loginUser.branchId,
          'OrderNumbers': orderNumbers,
          'PartyIDs': partyIds,
          'BrokerIDs': '',
          'StoneIDs': '',
          'FromDate': type == 1 ? loginUser.fromYear : '',
          'ToDate': type == 1 ? loginUser.toYear : '',
          'OrderStatus': 'INVOICE',
          'BillType': 'all',
          'EntryByIds': '',
          'UpdateByIds': '',
          'Type': type,
          'Fy_Id': loginUser.yearId,
          'PaymentType': 'ALL',
          'VoucherType': '',
          'CertificateStatus': 'ALL',
          'CurrencyBy': '',
          'SellerBy': '',
          'Diamond_Type': '',
          'Growth_Type': '',
          'E_Invoice_Status': 'ALL',
          'Acc_Transfer_Oracle': 'ALL',
          'Department_ID': '',
          'DeliverByIds': loginUser.userId.toString(),
          'DeliveredStatus': 'ALL',
          'ProductId': productId,
        },
        'Product_ID': productId,
      },
    );

    final raw = response.data;
    if (raw is Map<String, dynamic>) {
      return InvoiceSummaryResponse.fromJson(raw);
    }
    if (raw is Map) {
      return InvoiceSummaryResponse.fromJson(Map<String, dynamic>.from(raw));
    }

    return const InvoiceSummaryResponse(
      message: 'Invalid response from server',
      error: 'Invalid response from server',
      rows: [],
      totalPcs: 0,
      totalCts: 0,
      totalRate: 0,
      totalAmt: 0,
      totalCount: 0,
      isSessionExpire: false,
      isSuccess: false,
      statusCode: '',
    );
  }

  void _clearInvoiceSummary() {
    _invoices = [];
    _filteredInvoices = [];
    _totalCount = 0;
    _totalPcs = 0;
    _totalRate = 0;
  }

  Future<void> loadInvoices() async {
    _isInvoicesLoading = true;
    _invoicesError = null;
    notifyListeners();

    try {
      final loginUser = _readSavedLoginUser();
      if (loginUser == null) {
        _invoicesError = 'Login session not found. Please login again.';
        _clearInvoiceSummary();
        _isInvoicesLoading = false;
        notifyListeners();
        return;
      }

      final productId = await clientCodeStorage.getClientCode();
      if (productId == null || productId.isEmpty) {
        _invoicesError = 'Product id not found.';
        _clearInvoiceSummary();
        _isInvoicesLoading = false;
        notifyListeners();
        return;
      }

      debugPrint(
        'Invoice filter → Type=1, Product_ID=$productId, '
        'FromDate=${loginUser.fromYear}, ToDate=${loginUser.toYear}',
      );

      final response = await getInvoiceSummary(
        loginUser: loginUser,
        productId: productId,
      );

      if (!response.isInvoiceListSuccess) {
        _invoicesError = response.error.isNotEmpty
            ? response.error
            : (response.message.isNotEmpty
                  ? response.message
                  : 'Unable to load invoices');
        _clearInvoiceSummary();
        _isInvoicesLoading = false;
        notifyListeners();
        return;
      }

      _invoices = response.rows;
      _totalPcs = response.totalPcs;
      _totalRate = response.totalRate;
      _totalCount = response.totalCount > 0
          ? response.totalCount
          : response.rows.length;
      _filterInvoices();

      debugPrint(
        'Invoice list loaded → count=${_invoices.length}, '
        'TotalCount=$_totalCount, TotalPcs=$_totalPcs, '
        'TotalRate=$_totalRate, totalAmt=${response.totalAmt}, '
        'totalCts=${response.totalCts}',
      );
      for (final invoice in _invoices) {
        debugPrint(
          'Invoice → id=${invoice.id}, invoiceId=${invoice.invoiceId}, '
          'party=${invoice.customerName}, status=${invoice.orderStatusRaw}, '
          'amt=${invoice.listGrandTotal}, items=${invoice.itemCount}, '
          'date=${invoice.dateLabel}',
        );
      }

      _isInvoicesLoading = false;
      notifyListeners();
    } catch (error) {
      debugPrint('Invoice list ERROR: $error');
      _invoicesError = 'Unable to load invoices. Please try again.';
      _clearInvoiceSummary();
      _isInvoicesLoading = false;
      notifyListeners();
    }
  }

  Future<List<InvoiceItem>> loadInvoiceItems(String invoiceNumber) async {
    final loginUser = _readSavedLoginUser();
    if (loginUser == null) {
      throw StateError('Login session not found. Please login again.');
    }

    final productId = await clientCodeStorage.getClientCode();
    if (productId == null || productId.isEmpty) {
      throw StateError('Product id not found.');
    }

    debugPrint(
      'Invoice detail filter → Type=2, OrderNumbers=$invoiceNumber, '
      'Product_ID=$productId',
    );

    final response = await apiService.postRequest(
      ApiConstants.getInvoiceSummaryDetail,
      data: {
        'login': loginUser.toJson(),
        'filters': {
          'UserID': loginUser.userId,
          'BranchID': loginUser.branchId,
          'OrderNumbers': invoiceNumber,
          'PartyIDs': '',
          'BrokerIDs': '',
          'StoneIDs': '',
          'FromDate': '',
          'ToDate': '',
          'OrderStatus': 'INVOICE',
          'BillType': 'all',
          'EntryByIds': '',
          'UpdateByIds': '',
          'Type': 2,
          'Fy_Id': loginUser.yearId,
          'PaymentType': 'ALL',
          'VoucherType': '',
          'CertificateStatus': 'ALL',
          'CurrencyBy': '',
          'SellerBy': '',
          'Diamond_Type': '',
          'Growth_Type': '',
          'E_Invoice_Status': 'ALL',
          'Acc_Transfer_Oracle': 'ALL',
          'Department_ID': '',
          'DeliverByIds': loginUser.userId.toString(),
          'DeliveredStatus': 'ALL',
          'ProductId': productId,
        },
        'Product_ID': productId,
      },
    );

    final raw = response.data;
    final map = raw is Map<String, dynamic>
        ? raw
        : (raw is Map ? Map<String, dynamic>.from(raw) : null);

    if (map == null) {
      throw StateError('Invalid response from server');
    }

    final error = map['Error']?.toString().trim() ?? '';
    final isSuccess = _asApiSuccess(map['IsSuccess']);
    if (!isSuccess || error.isNotEmpty) {
      final message = map['Message']?.toString().trim() ?? '';
      throw StateError(
        error.isNotEmpty
            ? error
            : (message.isNotEmpty
                  ? message
                  : 'Unable to load diamond details'),
      );
    }

    final items = parseInvoiceItemsFromResponse(map);
    debugPrint(
      'Invoice items loaded → invoice=$invoiceNumber, count=${items.length}',
    );
    return items;
  }

  bool _asApiSuccess(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is num) return value != 0;
    return false;
  }

  void _filterInvoices() {
    final query = searchController.text.trim().toLowerCase();
    _filteredInvoices = query.isEmpty
        ? List<Invoice>.from(_invoices)
        : _invoices.where((invoice) {
            return invoice.title.toLowerCase().contains(query) ||
                invoice.id.toLowerCase().contains(query) ||
                invoice.description.toLowerCase().contains(query) ||
                invoice.customerName.toLowerCase().contains(query) ||
                invoice.billType.toLowerCase().contains(query);
          }).toList();
    notifyListeners();
  }

  @override
  void dispose() {
    searchController
      ..removeListener(_filterInvoices)
      ..dispose();
    super.dispose();
  }
}
