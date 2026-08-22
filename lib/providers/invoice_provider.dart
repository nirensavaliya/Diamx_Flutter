import 'dart:convert';

import 'package:flutter/material.dart';

import '../constant/api_constants.dart';
import '../models/invoice.dart';
import '../models/login.dart';
import '../models/party.dart';
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

  bool _isPartiesLoading = false;
  bool _isInvoicesLoading = false;
  String? _partiesError;
  String? _invoicesError;
  List<Party> _parties = [];
  Party? _selectedParty;
  String _selectedDeliveredStatus = 'PENDING';
  int _totalCount = 0;
  double _totalPcs = 0;
  double _totalRate = 0;
  double _totalAmt = 0;
  double _totalCts = 0;

  static const List<String> deliveredStatusOptions = [
    'ALL',
    'PENDING',
    'DELIVERED',
  ];

  List<Invoice> get invoices => List.unmodifiable(_filteredInvoices);
  int get totalInvoices => _totalCount > 0 ? _totalCount : _invoices.length;
  double get totalPcs => _totalPcs;
  double get totalRate => _totalRate;
  double get totalAmt => _totalAmt;
  double get totalCts => _totalCts;
  int get totalCount => _totalCount;
  int get pendingInvoices => _invoices
      .where((invoice) => invoice.status == InvoiceStatus.pending)
      .length;
  int get paidInvoices =>
      _invoices.where((invoice) => invoice.status == InvoiceStatus.paid).length;

  bool get isPartiesLoading => _isPartiesLoading;
  bool get isInvoicesLoading => _isInvoicesLoading;
  bool get isBusy => _isPartiesLoading || _isInvoicesLoading;
  String? get partiesError => _partiesError;
  String? get invoicesError => _invoicesError;
  List<Party> get parties => List.unmodifiable(_parties);
  Party? get selectedParty => _selectedParty;
  String get selectedDeliveredStatus => _selectedDeliveredStatus;
  String get deliveredStatusForApi =>
      _selectedDeliveredStatus == 'ALL' ? '' : _selectedDeliveredStatus;

  Future<void> _bootstrap() async {
    await loadParties();
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

  Future<PartyListResponse> getPartyList({
    required LoginUser loginUser,
    required String productId,
    String groupName = '',
    String query = '',
    String filterType = '',
  }) async {
    final response = await apiService.postRequest(
      ApiConstants.getPartyList,
      data: {
        'login': loginUser.toJson(),
        'GroupName': groupName,
        'BranchID': loginUser.branchId,
        'Query': query,
        'FilterType': filterType,
        'Product_ID': productId,
        'UserID': loginUser.userId,
      },
    );

    final raw = response.data;
    if (raw is Map<String, dynamic>) {
      return PartyListResponse.fromJson(raw);
    }
    if (raw is Map) {
      return PartyListResponse.fromJson(Map<String, dynamic>.from(raw));
    }

    return const PartyListResponse(
      message: 'Invalid response from server',
      error: 'Invalid response from server',
      rows: [],
      isSessionExpire: false,
      isSuccess: false,
      statusCode: '',
    );
  }

  Future<InvoiceSummaryResponse> getSaleInvoiceDelivery({
    required LoginUser loginUser,
    required String productId,
    String partyIds = '',
    String tranNo = '',
    int type = 1,
    String deliveredStatus = 'PENDING',
  }) async {
    final requestData = {
      'login': loginUser.toJson(),
      'filters': {
        'Type': type,
        'Tran_No': tranNo,
        'PartyIDs': partyIds,
        'DeliveredStatus': deliveredStatus,
      },
      'Product_ID': productId,
    };

    debugPrint(
      'Invoice delivery REQUEST → '
      '${const JsonEncoder.withIndent('  ').convert(requestData)}',
    );

    final response = await apiService.postRequest(
      ApiConstants.getSaleInvoiceDelivery,
      data: requestData,
    );

    debugPrint('Invoice delivery RESPONSE → ${response.data}');

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

  Future<void> loadParties({String query = ''}) async {
    _isPartiesLoading = true;
    _partiesError = null;
    notifyListeners();

    try {
      final loginUser = _readSavedLoginUser();
      if (loginUser == null) {
        _partiesError = 'Login session not found. Please login again.';
        _isPartiesLoading = false;
        notifyListeners();
        return;
      }

      final productId = await clientCodeStorage.getClientCode();
      if (productId == null || productId.isEmpty) {
        _partiesError = 'Product id not found.';
        _isPartiesLoading = false;
        notifyListeners();
        return;
      }

      final response = await getPartyList(
        loginUser: loginUser,
        productId: productId,
        query: query,
      );

      if (!response.isPartyListSuccess) {
        _partiesError = response.error.isNotEmpty
            ? response.error
            : (response.message.isNotEmpty
                  ? response.message
                  : 'Unable to load parties');
        _parties = [];
        _isPartiesLoading = false;
        notifyListeners();
        return;
      }

      _parties = response.rows
          .where((party) => party.displayName.isNotEmpty)
          .toList();

      if (_parties.isEmpty) {
        _partiesError = response.message.isNotEmpty
            ? response.message
            : 'No parties found';
      }

      _isPartiesLoading = false;
      notifyListeners();
    } catch (_) {
      _partiesError = 'Unable to load parties. Please try again.';
      _parties = [];
      _isPartiesLoading = false;
      notifyListeners();
    }
  }

  void _clearInvoiceSummary() {
    _invoices = [];
    _filteredInvoices = [];
    _totalCount = 0;
    _totalPcs = 0;
    _totalRate = 0;
    _totalAmt = 0;
    _totalCts = 0;
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

      final partyIds = _selectedParty?.ledgerId.toString() ?? '';
      debugPrint(
        'Invoice delivery filter → Type=1, PartyIDs=$partyIds, '
        'DeliveredStatus=$deliveredStatusForApi, '
        'party=${_selectedParty?.displayName ?? 'All'}',
      );

      final response = await getSaleInvoiceDelivery(
        loginUser: loginUser,
        productId: productId,
        partyIds: partyIds,
        type: 1,
        tranNo: '',
        deliveredStatus: deliveredStatusForApi,
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
      _totalAmt = response.totalAmt;
      _totalCts = response.totalCts;
      _totalCount = response.totalCount > 0
          ? response.totalCount
          : response.rows.length;
      _filterInvoices();

      debugPrint(
        'Invoice list loaded → count=${_invoices.length}, '
        'TotalCount=$_totalCount, TotalPcs=$_totalPcs, '
        'TotalRate=$_totalRate, TotalAmt=$_totalAmt, TotalCts=$_totalCts',
      );

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
      'Invoice detail filter → Type=2, Tran_No=$invoiceNumber, '
      'Product_ID=$productId',
    );

    final response = await getSaleInvoiceDelivery(
      loginUser: loginUser,
      productId: productId,
      type: 2,
      tranNo: invoiceNumber,
      deliveredStatus: deliveredStatusForApi,
    );

    if (!response.isInvoiceListSuccess) {
      throw StateError(
        response.error.isNotEmpty
            ? response.error
            : (response.message.isNotEmpty
                ? response.message
                : 'Unable to load diamond details'),
      );
    }

    final items = <InvoiceItem>[];
    for (final invoice in response.rows) {
      items.addAll(invoice.items);
    }

    debugPrint(
      'Invoice items loaded → invoice=$invoiceNumber, count=${items.length}',
    );
    return items;
  }

  Future<void> selectParty(Party? party) async {
    _selectedParty = party;
    notifyListeners();
    await loadInvoices();
  }

  Future<void> selectDeliveredStatus(String status) async {
    final normalized = status.trim().toUpperCase();
    if (!deliveredStatusOptions.contains(normalized)) return;
    if (_selectedDeliveredStatus == normalized) return;
    _selectedDeliveredStatus = normalized;
    notifyListeners();
    await loadInvoices();
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
                invoice.entryBy.toLowerCase().contains(query) ||
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
