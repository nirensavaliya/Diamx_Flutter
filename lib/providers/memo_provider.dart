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
    bool bootstrap = true,
  }) : apiService = apiService ?? ApiService.shared() {
    searchController.addListener(_filterMemos);
    if (bootstrap) {
      _bootstrap();
    }
  }

  final ClientCodeStorage clientCodeStorage;
  final ApiService apiService;

  final TextEditingController searchController = TextEditingController();
  List<Memo> _memos = [];
  List<Memo> _filteredMemos = [];

  bool _isPartiesLoading = false;
  bool _isMemosLoading = false;
  bool _isLoadingMore = false;
  String? _partiesError;
  String? _memosError;
  List<Party> _parties = [];
  Party? _selectedParty;
  String _selectedDeliveredStatus = 'PENDING';
  double _totalPcs = 0;
  double _totalRate = 0;
  double _totalAmt = 0;
  double _totalCts = 0;
  int _totalCount = 0;
  int _pageNum = 1;
  bool _hasMore = true;

  static const int pageSize = 10;
  static const String listFormType = '';

  static const List<String> deliveredStatusOptions = [
    'ALL',
    'PENDING',
    'DELIVERED',
  ];

  List<Memo> get memos => List.unmodifiable(_filteredMemos);
  double get totalPcs => _totalPcs;
  double get totalRate => _totalRate;
  double get totalAmt => _totalAmt;
  double get totalCts => _totalCts;
  int get totalCount => _totalCount;
  int get totalMemos => _totalCount > 0 ? _totalCount : _memos.length;
  int get pageNum => _pageNum;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  bool get isPartiesLoading => _isPartiesLoading;
  bool get isMemosLoading => _isMemosLoading;
  bool get isBusy => _isPartiesLoading || _isMemosLoading;
  String? get partiesError => _partiesError;
  String? get memosError => _memosError;
  List<Party> get parties => List.unmodifiable(_parties);
  Party? get selectedParty => _selectedParty;
  String get selectedDeliveredStatus => _selectedDeliveredStatus;

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

  Future<MemoIssueSummaryResponse> getMemoIssueDelivery({
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
      filters['PageSize'] = pageSize ?? MemoProvider.pageSize;
      filters['PageNum'] = pageNum ?? 1;
    }

    final requestData = {
      'login': loginUser.toJson(),
      'filters': filters,
      'Product_ID': productId,
    };

    debugPrint(
      'Memo delivery REQUEST → Type=$type, PageNum=${filters['PageNum']}, '
      'PageSize=${filters['PageSize']}, PartyIDs=$partyIds, '
      'DeliveredStatus=$deliveredStatus',
    );

    final response = await apiService.postRequest(
      ApiConstants.getMemoIssueDelivery,
      data: requestData,
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

  Future<List<Diamond>> loadMemoDiamonds(String memoNumber) async {
    final loginUser = _readSavedLoginUser();
    if (loginUser == null) {
      throw StateError('Login session not found. Please login again.');
    }

    final productId = await clientCodeStorage.getClientCode();
    if (productId == null || productId.isEmpty) {
      throw StateError('Product id not found.');
    }

    debugPrint(
      'Memo detail filter → Type=2, Tran_No=$memoNumber, '
      'Product_ID=$productId',
    );

    final response = await getMemoIssueDelivery(
      loginUser: loginUser,
      productId: productId,
      type: 2,
      tranNo: memoNumber,
      deliveredStatus: deliveredStatusForApi,
    );

    if (!response.isMemoListSuccess) {
      throw StateError(
        response.error.isNotEmpty
            ? response.error
            : (response.message.isNotEmpty
                ? response.message
                : 'Unable to load diamond details'),
      );
    }

      final diamonds = <Diamond>[];
    for (final memo in response.rows) {
      diamonds.addAll(memo.diamonds);
    }

    debugPrint(
      'Memo diamonds loaded → memo=$memoNumber, count=${diamonds.length}',
    );
    return diamonds;
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
    _totalAmt = 0;
    _totalCts = 0;
    _totalCount = 0;
    _pageNum = 1;
    _hasMore = true;
  }

  Future<void> loadMemos({bool reset = true}) async {
    if (reset) {
      if (_isMemosLoading) return;
      _pageNum = 1;
      _hasMore = true;
      _isMemosLoading = true;
      _isLoadingMore = false;
      _memosError = null;
      notifyListeners();
    } else {
      if (!_hasMore || _isMemosLoading || _isLoadingMore) return;
      _isLoadingMore = true;
      _memosError = null;
      notifyListeners();
    }

    try {
      final loginUser = _readSavedLoginUser();
      if (loginUser == null) {
        _memosError = 'Login session not found. Please login again.';
        if (reset) _clearMemoSummary();
        _isMemosLoading = false;
        _isLoadingMore = false;
        notifyListeners();
        return;
      }

      final productId = await clientCodeStorage.getClientCode();
      if (productId == null || productId.isEmpty) {
        _memosError = 'Product id not found.';
        if (reset) _clearMemoSummary();
        _isMemosLoading = false;
        _isLoadingMore = false;
        notifyListeners();
        return;
      }

      final requestPage = reset ? 1 : _pageNum + 1;
      final partyIds = _selectedParty?.ledgerId.toString() ?? '';
      debugPrint(
        'Memo delivery filter → Type=1, PartyIDs=$partyIds, '
        'DeliveredStatus=$deliveredStatusForApi, '
        'PageNum=$requestPage, PageSize=$pageSize, '
        'party=${_selectedParty?.displayName ?? 'All'}',
      );
      final response = await getMemoIssueDelivery(
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

      if (!response.isMemoListSuccess) {
        _memosError = response.error.isNotEmpty
            ? response.error
            : (response.message.isNotEmpty
                  ? response.message
                  : 'Unable to load memos');
        if (reset) _clearMemoSummary();
        _isMemosLoading = false;
        _isLoadingMore = false;
        notifyListeners();
        return;
      }

      final rows = response.rows;
      if (reset) {
        _memos = rows;
      } else {
        final existingIds = _memos.map((m) => m.memoId).toSet();
        for (final memo in rows) {
          if (!existingIds.contains(memo.memoId)) {
            _memos.add(memo);
          }
        }
      }

      _pageNum = requestPage;
      _totalPcs = response.totalPcs;
      _totalRate = response.totalRate;
      _totalAmt = response.totalAmt;
      _totalCts = response.totalCts;
      _totalCount = response.totalCount > 0
          ? response.totalCount
          : _memos.length;
      _hasMore = rows.length >= pageSize &&
          (_totalCount <= 0 || _memos.length < _totalCount);
      _applyMemoFilter(notify: false);

      debugPrint(
        'Memo list loaded → page=$_pageNum, pageRows=${rows.length}, '
        'totalLoaded=${_memos.length}, hasMore=$_hasMore',
      );

      _isMemosLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    } catch (error) {
      debugPrint('Memo list ERROR: $error');
      _memosError = 'Unable to load memos. Please try again.';
      if (reset) _clearMemoSummary();
      _isMemosLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreMemos() => loadMemos(reset: false);

  Future<void> selectParty(Party? party) async {
    _selectedParty = party;
    notifyListeners();
    await loadMemos();
  }

  Future<void> selectDeliveredStatus(String status) async {
    final normalized = status.trim().toUpperCase();
    if (!deliveredStatusOptions.contains(normalized)) return;
    if (_selectedDeliveredStatus == normalized) return;
    _selectedDeliveredStatus = normalized;
    notifyListeners();
    await loadMemos();
  }

  /// UI shows ALL / PENDING / DELIVERED; API gets blank for ALL.
  String get deliveredStatusForApi =>
      _selectedDeliveredStatus == 'ALL' ? '' : _selectedDeliveredStatus;

  void _filterMemos() => _applyMemoFilter(notify: true);

  void _applyMemoFilter({required bool notify}) {
    final query = searchController.text.trim().toLowerCase();
    _filteredMemos = query.isEmpty
        ? List<Memo>.from(_memos)
        : _memos.where((memo) {
            return memo.name.toLowerCase().contains(query) ||
                memo.id.toLowerCase().contains(query) ||
                memo.description.toLowerCase().contains(query) ||
                memo.customerName.toLowerCase().contains(query) ||
                memo.entryBy.toLowerCase().contains(query) ||
                memo.billType.toLowerCase().contains(query);
          }).toList();
    if (notify) notifyListeners();
  }

  @override
  void dispose() {
    searchController
      ..removeListener(_filterMemos)
      ..dispose();
    super.dispose();
  }
}
