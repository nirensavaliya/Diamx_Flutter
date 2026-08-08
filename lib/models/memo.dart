enum MemoStatus { pending, dispatched }

class Diamond {
  const Diamond({
    required this.id,
    required this.stockNumber,
    required this.shape,
    required this.carat,
    required this.color,
    required this.clarity,
    required this.ppc,
    required this.dollarPrice,
    required this.total,
  });

  final String id;
  final String stockNumber;
  final String shape;
  final double carat;
  final String color;
  final String clarity;
  final double ppc;
  final double dollarPrice;
  final double total;
}

class MemoIssueSummaryResponse {
  const MemoIssueSummaryResponse({
    required this.message,
    required this.error,
    required this.rows,
    required this.totalPcs,
    required this.totalCts,
    required this.totalRate,
    required this.totalAmt,
    required this.totalCount,
    required this.isSessionExpire,
    required this.isSuccess,
    required this.statusCode,
  });

  final String message;
  final String error;
  final List<Memo> rows;
  final double totalPcs;
  final double totalCts;
  final double totalRate;
  final double totalAmt;
  final int totalCount;
  final bool isSessionExpire;
  final bool isSuccess;
  final String statusCode;

  bool get hasError => error.trim().isNotEmpty;
  bool get isMemoListSuccess => isSuccess && !hasError;

  factory MemoIssueSummaryResponse.fromJson(Map<String, dynamic> json) {
    final rows = <Memo>[];
    var totalPcs = 0.0;
    var totalCts = 0.0;
    var totalRate = 0.0;
    var totalAmt = 0.0;
    var totalCount = 0;

    final rawResult = json['Result'];
    if (rawResult is Map) {
      final map = Map<String, dynamic>.from(rawResult);
      final rawRows = map['rows'];
      if (rawRows is List) {
        for (final item in rawRows) {
          if (item is Map<String, dynamic>) {
            rows.add(Memo.fromApiJson(item));
          } else if (item is Map) {
            rows.add(Memo.fromApiJson(Map<String, dynamic>.from(item)));
          }
        }
      }
      totalPcs = _asDouble(map['TotalPcs']);
      totalCts = _asDouble(map['TotalCts']);
      totalRate = _asDouble(map['TotalRate']);
      totalAmt = _asDouble(map['TotalAmt']);
      totalCount = _asInt(map['TotalCount']);
      if (totalCount == 0 && rows.isNotEmpty) {
        totalCount = rows.length;
      }
    }

    return MemoIssueSummaryResponse(
      message: json['Message']?.toString() ?? '',
      error: json['Error']?.toString() ?? '',
      rows: rows,
      totalPcs: totalPcs,
      totalCts: totalCts,
      totalRate: totalRate,
      totalAmt: totalAmt,
      totalCount: totalCount,
      isSessionExpire: _asBool(json['IsSessionExpire']),
      isSuccess: _asBool(json['IsSuccess']),
      statusCode: json['StatusCode']?.toString() ?? '',
    );
  }
}

class Memo {
  const Memo({
    required this.id,
    required this.memoId,
    required this.name,
    required this.description,
    required this.customerName,
    required this.date,
    required this.dateLabel,
    required this.ppc,
    required this.dollarPrice,
    required this.total,
    required this.status,
    required this.diamonds,
    this.branchName = '',
    this.currencyName = '',
    this.totalCarat = 0,
    this.pendingStone = 0,
    this.pendingCts = 0,
    this.pendingAmount = 0,
    this.billType = '',
    this.memoStatusRaw = '',
    this.salesPerson = '',
  });

  final String id;
  final int memoId;
  final String name;
  final String description;
  final String customerName;
  final DateTime date;
  final String dateLabel;
  final double ppc;
  final double dollarPrice;
  final double total;
  final MemoStatus status;
  final List<Diamond> diamonds;
  final String branchName;
  final String currencyName;
  final double totalCarat;
  final int pendingStone;
  final double pendingCts;
  final double pendingAmount;
  final String billType;
  final String memoStatusRaw;
  final String salesPerson;

  String get statusLabel {
    if (memoStatusRaw.trim().isNotEmpty) {
      final raw = memoStatusRaw.trim();
      return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
    }
    return switch (status) {
      MemoStatus.pending => 'Pending',
      MemoStatus.dispatched => 'Dispatched',
    };
  }

  factory Memo.fromApiJson(Map<String, dynamic> json) {
    final memoNo = json['Memo_No']?.toString() ?? '';
    final partyName = json['Party_Name']?.toString() ?? '';
    final branchName = json['Branch_Name']?.toString() ?? '';
    final billType = json['BillType']?.toString() ?? '';
    final memoDate = json['Memo_Date']?.toString() ?? '';
    final statusRaw = json['Memo_Status']?.toString() ?? '';
    final totalCarat = _asDouble(json['Total_Carat']);
    final pendingStone = _asInt(json['PendingStone']);
    final pendingCts = _asDouble(json['PendingCts']);
    final pendingAmount = _asDouble(json['PendingAmount']);
    final totalAmt = _asDouble(json['Total_Amt']);
    final netAmt = _asDouble(json['Net_Amt']);
    final averagePrice = _asDouble(json['Average_Price']);

    final descriptionParts = <String>[
      if (billType.trim().isNotEmpty) billType.trim(),
      if (branchName.trim().isNotEmpty) branchName.trim(),
      if (totalCarat > 0) '${totalCarat.toStringAsFixed(3)} Cts',
      if (pendingStone > 0) '$pendingStone pending',
    ];

    return Memo(
      id: memoNo.trim().isNotEmpty
          ? memoNo.trim()
          : _asInt(json['Memo_ID']).toString(),
      memoId: _asInt(json['Memo_ID']),
      name: partyName.trim().isNotEmpty ? partyName.trim() : 'Memo',
      description: descriptionParts.isEmpty
          ? (json['Remark']?.toString() ?? '')
          : descriptionParts.join(' · '),
      customerName: partyName,
      date: _parseMemoDate(memoDate) ??
          DateTime.tryParse(json['SearchMemoDate']?.toString() ?? '') ??
          DateTime.now(),
      dateLabel: memoDate,
      ppc: averagePrice,
      dollarPrice: totalAmt,
      total: netAmt != 0 ? netAmt : pendingAmount,
      status: _mapStatus(statusRaw, json['Is_Delivered']),
      diamonds: const [],
      branchName: branchName,
      currencyName: json['Currency_Name']?.toString() ?? '',
      totalCarat: totalCarat,
      pendingStone: pendingStone,
      pendingCts: pendingCts,
      pendingAmount: pendingAmount,
      billType: billType,
      memoStatusRaw: statusRaw,
      salesPerson: json['Sales_Person']?.toString() ?? '',
    );
  }
}

MemoStatus _mapStatus(String raw, dynamic isDelivered) {
  final status = raw.trim().toUpperCase();
  if (status.contains('DISPATCH') ||
      status.contains('DELIVER') ||
      status == 'RETURN' ||
      _asBool(isDelivered)) {
    return MemoStatus.dispatched;
  }
  return MemoStatus.pending;
}

DateTime? _parseMemoDate(String value) {
  final text = value.trim();
  if (text.isEmpty) return null;
  final parts = text.split('/');
  if (parts.length == 3) {
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day != null && month != null && year != null) {
      return DateTime(year, month, day);
    }
  }
  return DateTime.tryParse(text);
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().toLowerCase();
  return text == 'true' || text == '1' || text == 'yes';
}
