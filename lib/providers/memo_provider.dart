import 'dart:convert';

import 'package:flutter/material.dart';

import '../constant/api_constants.dart';
import '../models/login.dart';
import '../models/memo.dart';
import '../models/party.dart';
import '../services/api_service.dart';
import '../services/client_code_storage.dart';
import '../services/get_stroage_data.dart';

class MemoProvider extends ChangeNotifier {
  MemoProvider({
    this.clientCodeStorage = const ClientCodeStorage(),
    ApiService? apiService,
  }) : apiService = apiService ?? ApiService.shared() {
    searchController.addListener(_filterMemos);
    _bootstrap();
  }

  final ClientCodeStorage clientCodeStorage;
  final ApiService apiService;

  final TextEditingController searchController = TextEditingController();
  List<Memo> _memos = [];
  List<Memo> _filteredMemos = [];

  bool _isPartiesLoading = false;
  bool _isMemosLoading = false;
  String? _partiesError;
  String? _memosError;
  List<Party> _parties = [];
  Party? _selectedParty;
  double _totalPcs = 0;
  double _totalRate = 0;
  int _totalCount = 0;

  List<Memo> get memos => List.unmodifiable(_filteredMemos);
  double get totalPcs => _totalPcs;
  double get totalRate => _totalRate;
  int get totalCount => _totalCount;
  int get totalMemos => _totalCount > 0 ? _totalCount : _memos.length;

  bool get isPartiesLoading => _isPartiesLoading;
  bool get isMemosLoading => _isMemosLoading;
  bool get isBusy => _isPartiesLoading || _isMemosLoading;
  String? get partiesError => _partiesError;
  String? get memosError => _memosError;
  List<Party> get parties => List.unmodifiable(_parties);
  Party? get selectedParty => _selectedParty;

  Future<void> _bootstrap() async {
    await loadParties();
    await loadMemos();
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

  Future<MemoIssueSummaryResponse> getMemoIssueSummary({
    required LoginUser loginUser,
    required String productId,
    String partyIds = '',
  }) async {
    final response = await apiService.postRequest(
      ApiConstants.getMemoIssueSummaryDetail,
      data: {
        'login': loginUser.toJson(),
        'filters': {
          'UserID': loginUser.userId,
          'BranchID': loginUser.branchId,
          'MemoNumbers': '',
          'PartyIDs': partyIds,
          'BrokerIDs': '',
          'StoneIDs': '',
          'FromDate': loginUser.fromYear,
          'ToDate': loginUser.toYear,
          'MemoStatus': 'PENDING',
          'EntryByIds': '',
          'UpdateByIds': '',
          'VoucherType': '',
          'IsOverDue': false,
          'CertificateStatus': 'ALL',
          'ActionBy': '',
          'CurrencyBy': '',
          'Type': 1,
          'SellerBy': '',
          'Diamond_Type': '',
          'Growth_Type': '',
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
      return MemoIssueSummaryResponse.fromJson(raw);
    }
    if (raw is Map) {
      return MemoIssueSummaryResponse.fromJson(Map<String, dynamic>.from(raw));
    }

    return const MemoIssueSummaryResponse(
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

  void _clearMemoSummary() {
    _memos = [];
    _filteredMemos = [];
    _totalPcs = 0;
    _totalRate = 0;
    _totalCount = 0;
  }

  Future<void> loadMemos() async {
    _isMemosLoading = true;
    _memosError = null;
    notifyListeners();

    try {
      final loginUser = _readSavedLoginUser();
      if (loginUser == null) {
        _memosError = 'Login session not found. Please login again.';
        _clearMemoSummary();
        _isMemosLoading = false;
        notifyListeners();
        return;
      }

      final productId = await clientCodeStorage.getClientCode();
      if (productId == null || productId.isEmpty) {
        _memosError = 'Product id not found.';
        _clearMemoSummary();
        _isMemosLoading = false;
        notifyListeners();
        return;
      }

      final partyIds = _selectedParty?.ledgerId.toString() ?? '';
      final response = await getMemoIssueSummary(
        loginUser: loginUser,
        productId: productId,
        partyIds: partyIds,
      );

      if (!response.isMemoListSuccess) {
        _memosError = response.error.isNotEmpty
            ? response.error
            : (response.message.isNotEmpty
                  ? response.message
                  : 'Unable to load memos');
        _clearMemoSummary();
        _isMemosLoading = false;
        notifyListeners();
        return;
      }

      _memos = response.rows;
      _totalPcs = response.totalPcs;
      _totalRate = response.totalRate;
      _totalCount = response.totalCount > 0
          ? response.totalCount
          : response.rows.length;
      _filterMemos();

      debugPrint(
        'Memo list loaded → count=${_memos.length}, '
        'TotalCount=$_totalCount, TotalPcs=$_totalPcs, '
        'TotalRate=$_totalRate, totalAmt=${response.totalAmt}, '
        'totalCts=${response.totalCts}',
      );
      for (final memo in _memos) {
        debugPrint(
          'Memo → id=${memo.id}, memoId=${memo.memoId}, '
          'party=${memo.customerName}, status=${memo.memoStatusRaw}, '
          'cts=${memo.totalCarat}, amt=${memo.dollarPrice}, '
          'pendingAmt=${memo.pendingAmount}, date=${memo.dateLabel}',
        );
      }

      _isMemosLoading = false;
      notifyListeners();
    } catch (error) {
      debugPrint('Memo list ERROR: $error');
      _memosError = 'Unable to load memos. Please try again.';
      _clearMemoSummary();
      _isMemosLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectParty(Party? party) async {
    _selectedParty = party;
    notifyListeners();
    await loadMemos();
  }

  void _filterMemos() {
    final query = searchController.text.trim().toLowerCase();
    _filteredMemos = query.isEmpty
        ? List<Memo>.from(_memos)
        : _memos.where((memo) {
            return memo.name.toLowerCase().contains(query) ||
                memo.id.toLowerCase().contains(query) ||
                memo.description.toLowerCase().contains(query) ||
                memo.customerName.toLowerCase().contains(query) ||
                memo.billType.toLowerCase().contains(query);
          }).toList();
    notifyListeners();
  }

  @override
  void dispose() {
    searchController
      ..removeListener(_filterMemos)
      ..dispose();
    super.dispose();
  }
}
