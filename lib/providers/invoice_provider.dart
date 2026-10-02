import 'dart:convert';

import 'package:flutter/material.dart';

import '../constant/api_constants.dart';
import '../models/invoice.dart';
import '../models/login.dart';
import '../models/party.dart';
import '../services/api_service.dart';
import '../services/client_code_storage.dart';
import '../services/get_stroage_data.dart';
import '../utills/print_full_json.dart';

class InvoiceProvider extends ChangeNotifier {
  InvoiceProvider({
    this.clientCodeStorage = const ClientCodeStorage(),
    ApiService? apiService,
    bool bootstrap = true,
    String initialDeliveredStatus = 'PENDING',
  }) : apiService = apiService ?? ApiService.shared(),
       _selectedDeliveredStatus =
           _normalizeDeliveredStatus(initialDeliveredStatus) {
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
  bool _isLoadingMore = false;
  bool _isSilentRefreshing = false;
  String? _partiesError;
  String? _invoicesError;
  List<Party> _parties = [];
  Party? _selectedParty;
  String _selectedDeliveredStatus;  int _totalCount = 0;
  double _totalPcs = 0;
  double _totalRate = 0;
  double _totalAmt = 0;
  double _totalCts = 0;
  int _pageNum = 0;
  bool _hasMore = true;
  static const int pageSize = 10;
  static const String listFormType = '';
  /// Party list form-wise API (`get-PartyList-Form-Wise`).
  /// Swagger / SP expects exact value: "Sales Invoice".
  static const String partyFormType = 'Sales Invoice';
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
  int get pageNum => _pageNum;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
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

  /// Party picker — form-wise list (`get-PartyList-Form-Wise`).
  Future<PartyListResponse> getPartyListFormWise({
    required LoginUser loginUser,
    required String productId,
    String formType = partyFormType,
  }) async {
    final requestBody = {
      'login': loginUser.toJson(),
      'FormType': formType,
      'Product_ID': productId,
    };

    print('========== get-PartyList-Form-Wise REQUEST ==========');
    print(
      const JsonEncoder.withIndent('  ').convert(
        Map<String, dynamic>.from(requestBody)..remove('login'),
      ),
    );
    print('=====================================================');

    final response = await apiService.postRequest(
      ApiConstants.getPartyListFormWise,
      data: requestBody,
    );

    final raw = response.data;
    printFullJson('get-PartyList-Form-Wise RESPONSE', raw);

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
    String formType = listFormType,
    int? pageNum,
    int? pageSize,
  }) async {
    final filters = <String, dynamic>{
      'Type': type,
      'Tran_No': tranNo,
      'PartyIDs': partyIds,
      'DeliveredStatus': deliveredStatus,
    };

    // Pagination only for list (Type=1), not detail (Type=2).
    if (type == 1) {
      filters['FormType'] = formType;
      filters['PageSize'] = pageSize ?? InvoiceProvider.pageSize;
      filters['PageNum'] = pageNum ?? 0;
    }

    final requestData = {
      'login': loginUser.toJson(),
      'filters': filters,
      'Product_ID': productId,
    };

    final logVerbose = type != 1 || (pageNum ?? 0) == 0;
    if (logVerbose) {
      print('========== get-Sale-Invoice-Delivery REQUEST ==========');
      print(
        const JsonEncoder.withIndent('  ').convert(
          Map<String, dynamic>.from(requestData)..remove('login'),
        ),
      );
      print('======================================================');
    } else {
      debugPrint(
        'get-Sale-Invoice-Delivery page=${pageNum ?? 0} '
        'size=${pageSize ?? InvoiceProvider.pageSize}',
      );
    }

    final response = await apiService.postRequest(
      ApiConstants.getSaleInvoiceDelivery,
      data: requestData,
    );

    final raw = response.data;
    if (logVerbose) {
      printFullJson('get-Sale-Invoice-Delivery RESPONSE', raw);
    }

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

      final response = await getPartyListFormWise(
        loginUser: loginUser,
        productId: productId,
        formType: partyFormType,
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

      print(
        'Party list parsed → rawRows=${response.rows.length}, '
        'withName=${_parties.length}',
      );

      if (_parties.isEmpty) {
        _partiesError = 'No parties found';
      } else {
        _partiesError = null;
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
    _pageNum = 0;
    _hasMore = true;
  }

  Future<void> loadInvoices({bool reset = true, bool silent = false}) async {
    if (reset) {
      if (_isInvoicesLoading || _isSilentRefreshing) return;
      _pageNum = 0;
      _hasMore = true;
      _isLoadingMore = false;
      _invoicesError = null;
      if (silent) {
        _isSilentRefreshing = true;
      } else {
        _isInvoicesLoading = true;
        notifyListeners();
      }
    } else {
      if (!_hasMore ||
          _isInvoicesLoading ||
          _isLoadingMore ||
          _isSilentRefreshing) {
        return;
      }
      // Show bottom pagination loader (notify after flag so UI updates).
      _isLoadingMore = true;
      _invoicesError = null;
      notifyListeners();
    }

    try {
      final loginUser = _readSavedLoginUser();
      if (loginUser == null) {
        _invoicesError = 'Login session not found. Please login again.';
        if (reset && !silent) _clearInvoiceSummary();
        _isInvoicesLoading = false;
        _isLoadingMore = false;
        _isSilentRefreshing = false;
        notifyListeners();
        return;
      }

      final productId = await clientCodeStorage.getClientCode();
      if (productId == null || productId.isEmpty) {
        _invoicesError = 'Product id not found.';
        if (reset && !silent) _clearInvoiceSummary();
        _isInvoicesLoading = false;
        _isLoadingMore = false;
        _isSilentRefreshing = false;
        notifyListeners();
        return;
      }

      final requestPage = reset ? 0 : _pageNum + 1;
      final partyIds = _selectedParty?.ledgerId.toString() ?? '';
      debugPrint(
        'Invoice delivery filter → Type=1, PartyIDs=$partyIds, '
        'DeliveredStatus=$deliveredStatusForApi, '
        'PageNum=$requestPage, PageSize=$pageSize, '
        'party=${_selectedParty?.displayName ?? 'All'}',
      );

      final response = await getSaleInvoiceDelivery(
        loginUser: loginUser,
        productId: productId,
        partyIds: partyIds,
        type: 1,
        tranNo: '',
        deliveredStatus: deliveredStatusForApi,
        formType: listFormType,
        pageNum: requestPage,
        pageSize: pageSize,
      );

      if (!response.isInvoiceListSuccess) {
        _invoicesError = response.error.isNotEmpty
            ? response.error
            : (response.message.isNotEmpty
                  ? response.message
                  : 'Unable to load invoices');
        if (reset && !silent) _clearInvoiceSummary();
        _isInvoicesLoading = false;
        _isLoadingMore = false;
        _isSilentRefreshing = false;
        notifyListeners();
        return;
      }

      final rows = response.rows;
      var addedCount = 0;
      if (reset) {
        _invoices = rows;
        addedCount = rows.length;
      } else {
        final existingIds = _invoices.map((i) => i.invoiceId).toSet();
        for (final invoice in rows) {
          if (!existingIds.contains(invoice.invoiceId)) {
            _invoices.add(invoice);
            addedCount++;
          }
        }
      }

      _pageNum = requestPage;
      _totalPcs = response.totalPcs;
      _totalRate = response.totalRate;
      _totalAmt = response.totalAmt;
      _totalCts = response.totalCts;
      final apiTotalCount = response.totalCount;
      _totalCount = apiTotalCount > 0 ? apiTotalCount : _invoices.length;
      _hasMore = rows.isNotEmpty &&
          addedCount > 0 &&
          rows.length >= pageSize &&
          (apiTotalCount <= 0 || _invoices.length < apiTotalCount);
      _applyInvoiceFilter(notify: false);

      debugPrint(
        'Invoice list loaded → page=$_pageNum, pageRows=${rows.length}, '
        'added=$addedCount, totalLoaded=${_invoices.length}, '
        'apiTotal=$apiTotalCount, hasMore=$_hasMore',
      );

      _isInvoicesLoading = false;
      _isLoadingMore = false;
      _isSilentRefreshing = false;
      notifyListeners();
    } catch (error) {
      debugPrint('Invoice list ERROR: $error');
      _invoicesError = 'Unable to load invoices. Please try again.';
      if (reset && !silent) _clearInvoiceSummary();
      _isInvoicesLoading = false;
      _isLoadingMore = false;
      _isSilentRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreInvoices() => loadInvoices(reset: false);

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

  /// Map an invoice card status to list filter value for Type=2 detail calls.
  static String deliveredStatusFromInvoice(Invoice invoice) {
    final raw = invoice.orderStatusRaw.trim().toUpperCase();
    if (raw.contains('DELIVERED') ||
        raw.contains('DISPATCH') ||
        raw == 'RETURN') {
      return 'DELIVERED';
    }
    if (raw.contains('PENDING')) return 'PENDING';
    return invoice.status == InvoiceStatus.paid ? 'DELIVERED' : 'PENDING';
  }

  static String _normalizeDeliveredStatus(String status) {
    final normalized = status.trim().toUpperCase();
    if (deliveredStatusOptions.contains(normalized)) return normalized;
    return 'PENDING';
  }

  void _filterInvoices() => _applyInvoiceFilter(notify: true);

  void _applyInvoiceFilter({required bool notify}) {
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
    if (notify) notifyListeners();
  }

  @override
  void dispose() {
    searchController
      ..removeListener(_filterInvoices)
      ..dispose();
    super.dispose();
  }
}
