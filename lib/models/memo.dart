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
    this.lab = '',
    this.labReportNo = '',
    this.cut = '',
    this.polish = '',
    this.symm = '',
    this.discount = 0,
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
  final String lab;
  final String labReportNo;
  final String cut;
  final String polish;
  final String symm;
  final double discount;

  factory Diamond.fromApiJson(Map<String, dynamic> json) {
    final id = _firstNonEmpty([
      json['Memo_Detail_ID'],
      json['Stone_ID'],
      json['Stock_ID'],
      json['ID'],
      json['Id'],
      json['StoneId'],
    ]);
    final stockNumber = _firstNonEmpty([
      json['Stone_NO'],
      json['Stone_No'],
      json['Stock_No'],
      json['StockNumber'],
      json['RFId'],
      json['RFID'],
    ]);
    final shape = _firstNonEmpty([
      json['Shape_Name'],
      json['Shape'],
      json['ShapeName'],
    ]);
    final color = _firstNonEmpty([
      json['Color_Name'],
      json['Color'],
      json['Colour'],
    ]);
    final clarity = _firstNonEmpty([
      json['Clarity_Name'],
      json['Clarity'],
    ]);
    final lab = _firstNonEmpty([
      json['Lab_Name'],
      json['Lab'],
    ]);
    final labReportNo = _firstNonEmpty([
      json['Lab_Report_No'],
      json['Certificate_No'],
    ]);
    final cut = _firstNonEmpty([
      json['Cut_Name'],
      json['Cut'],
    ]);
    final polish = _firstNonEmpty([
      json['Polish_Name'],
      json['Polish'],
    ]);
    final symm = _firstNonEmpty([
      json['Symm_Name'],
      json['Symmetry_Name'],
      json['Symm'],
    ]);
    final carat = _firstDouble([
      json['Weight'],
      json['Issue_Cts'],
      json['Carat'],
      json['Cts'],
      json['Total_Carat'],
      json['PendingCts'],
    ]);
    final discount = _asDouble(json['Memo_Discount']) != 0
        ? _asDouble(json['Memo_Discount'])
        : _asDouble(json['Original_Discount']);
    final ppc = _firstDouble([
      json['Memo_Rate'],
      json['Original_Rate'],
      json['Price'],
      json['PPC'],
      json['Asking_Rate'],
      json['Price_Per_Cts'],
      json['Avg_Rate'],
      json['Average_Price'],
      json['Rate'],
    ]);
    final memoAmt = _asDouble(json['Memo_Amt']);
    final finalAmt = _asDouble(json['Final_Amt']);
    final dollarPrice = _firstDouble([
      json['Memo_Amt'],
      json['Final_Amt'],
      json['Original_Amt'],
      json['Dollar_Price'],
      json['Dollar_Amt'],
      json['Amount'],
      json['Total_Amt'],
      json['Net_Amt'],
    ]);
    final total = memoAmt != 0
        ? memoAmt
        : (finalAmt != 0
              ? finalAmt
              : _firstDouble([
                  json['Original_Amt'],
                  json['Total'],
                  json['Net_Amt'],
                  json['Total_Amt'],
                  json['PendingAmount'],
                  json['Amount'],
                ]));

    return Diamond(
      id: id.isNotEmpty ? id : stockNumber,
      stockNumber: stockNumber.isNotEmpty ? stockNumber : id,
      shape: shape,
      carat: carat,
      color: color,
      clarity: clarity,
      ppc: ppc,
      dollarPrice: dollarPrice != 0 ? dollarPrice : total,
      total: total != 0 ? total : dollarPrice,
      lab: lab,
      labReportNo: labReportNo,
      cut: cut,
      polish: polish,
      symm: symm,
      discount: discount,
    );
  }
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
    final resultRows = _extractResultRows(json['Result']);

    var totalPcs = 0.0;
    var totalCts = 0.0;
    var totalRate = 0.0;
    var totalAmt = 0.0;
    var totalCount = 0;

    // Legacy summary shape: Result = { rows, TotalPcs, ... }
    final rawResult = json['Result'];
    if (rawResult is Map) {
      final map = Map<String, dynamic>.from(rawResult);
      totalPcs = _asDouble(map['TotalPcs']);
      totalCts = _asDouble(map['TotalCts']);
      totalRate = _asDouble(map['TotalRate']);
      totalAmt = _asDouble(map['TotalAmt']);
      totalCount = _asInt(map['TotalCount']);
    }
    if (totalCount <= 0) {
      totalCount = _asInt(json['TotalCount']);
    }
    if (totalCount <= 0 && resultRows.isNotEmpty) {
      totalCount = _asInt(resultRows.first['TotalCount']);
    }

    final List<Memo> rows;
    final isStoneLevel =
        resultRows.isNotEmpty && _isStoneDetailRow(resultRows.first);

    if (isStoneLevel) {
      // Type 2 — stone / diamond rows
      rows = groupDeliveryStonesIntoMemos(resultRows);
      if (totalPcs == 0) {
        for (final stone in resultRows) {
          final pcs = _asDouble(stone['PacketPcs']);
          totalPcs += pcs > 0 ? pcs : 1;
          totalCts += _asDouble(stone['Weight']);
          totalAmt += _firstDouble([
            stone['Memo_Amt'],
            stone['Final_Amt'],
            stone['Original_Amt'],
          ]);
          totalRate += _firstDouble([
            stone['Memo_Rate'],
            stone['Original_Rate'],
          ]);
        }
        if (resultRows.isNotEmpty) {
          totalRate = totalRate / resultRows.length;
        }
      }
    } else {
      // Type 1 — memo summary rows
      rows = resultRows.map(Memo.fromApiJson).toList();
      if (totalPcs == 0 && rows.isNotEmpty) {
        for (final memo in rows) {
          totalPcs += memo.totalPcs > 0 ? memo.totalPcs : memo.pendingStone;
          totalCts += memo.totalCarat;
          totalAmt += memo.dollarPrice != 0 ? memo.dollarPrice : memo.total;
          totalRate += memo.ppc;
        }
        if (rows.isNotEmpty) {
          totalRate = totalRate / rows.length;
        }
      }
    }

    // Do not fall back to rows.length — that breaks pagination when API
    // returns a full page without a TotalCount field.

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
    this.totalPcs = 0,
    this.pendingStone = 0,
    this.pendingCts = 0,
    this.pendingAmount = 0,
    this.billType = '',
    this.memoStatusRaw = '',
    this.salesPerson = '',
    this.entryBy = '',
    this.deliverBy = '',
    this.billingCompanyName = '',
    this.billingName = '',
    this.billingAddress = '',
    this.shippingCompanyName = '',
    this.shippingAddress = '',
    this.cityName = '',
    this.stateName = '',
    this.deliverAssignBy = '',
    this.deliverDate = '',
    this.deliveredDate = '',
    this.mailTelephoneNo = '',
    this.shipTelephoneNo = '',
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
  final double totalPcs;
  final int pendingStone;
  final double pendingCts;
  final double pendingAmount;
  final String billType;
  final String memoStatusRaw;
  final String salesPerson;
  final String entryBy;
  final String deliverBy;
  final String billingCompanyName;
  final String billingName;
  final String billingAddress;
  final String shippingCompanyName;
  final String shippingAddress;
  final String cityName;
  final String stateName;
  final String deliverAssignBy;
  final String deliverDate;
  final String deliveredDate;
  final String mailTelephoneNo;
  final String shipTelephoneNo;

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

  Memo copyWith({List<Diamond>? diamonds}) {
    return Memo(
      id: id,
      memoId: memoId,
      name: name,
      description: description,
      customerName: customerName,
      date: date,
      dateLabel: dateLabel,
      ppc: ppc,
      dollarPrice: dollarPrice,
      total: total,
      status: status,
      diamonds: diamonds ?? this.diamonds,
      branchName: branchName,
      currencyName: currencyName,
      totalCarat: totalCarat,
      totalPcs: totalPcs,
      pendingStone: pendingStone,
      pendingCts: pendingCts,
      pendingAmount: pendingAmount,
      billType: billType,
      memoStatusRaw: memoStatusRaw,
      salesPerson: salesPerson,
      entryBy: entryBy,
      deliverBy: deliverBy,
      billingCompanyName: billingCompanyName,
      billingName: billingName,
      billingAddress: billingAddress,
      shippingCompanyName: shippingCompanyName,
      shippingAddress: shippingAddress,
      cityName: cityName,
      stateName: stateName,
      deliverAssignBy: deliverAssignBy,
      deliverDate: deliverDate,
      deliveredDate: deliveredDate,
      mailTelephoneNo: mailTelephoneNo,
      shipTelephoneNo: shipTelephoneNo,
    );
  }

  factory Memo.fromApiJson(Map<String, dynamic> json) {
    final memoNo = json['Memo_No']?.toString() ?? '';
    final partyName = _firstNonEmpty([
      json['Party_Name'],
      json['BillingCompanyName'],
      json['BillingName'],
    ]);
    final branchName = json['Branch_Name']?.toString() ?? '';
    final billType = json['BillType']?.toString() ?? '';
    final memoDate = json['Memo_Date']?.toString() ?? '';
    final statusRaw = _firstNonEmpty([
      json['Delivered_Status'],
      json['Memo_Status'],
      json['Stone_Status'],
      json['StockStatus'],
    ]);
    final entryBy = _firstNonEmpty([
      json['Entry_By'],
      json['EntryBy'],
    ]);
    final deliverBy = _firstNonEmpty([
      json['Deliver_By'],
      json['DeliverBy'],
    ]);
    final billingCompanyName = json['BillingCompanyName']?.toString() ?? '';
    final billingName = json['BillingName']?.toString() ?? '';
    final billingAddress = json['BillingAddress']?.toString() ?? '';
    final shippingCompanyName = json['ShippingCompanyName']?.toString() ?? '';
    final shippingAddress = json['ShippingAddress']?.toString() ?? '';
    final cityName = json['City_Name']?.toString() ?? '';
    final stateName = json['State_Name']?.toString() ?? '';
    final deliverAssignBy = json['Deliver_Assign_By']?.toString() ?? '';
    final deliverDate = json['Deliver_Date']?.toString() ?? '';
    final deliveredDate = json['Delivered_Date']?.toString() ?? '';
    final mailTelephoneNo = _displayPhone(
      _sanitizePhone(json['Mail_Telephone_No']?.toString() ?? ''),
    );
    final shipTelephoneNo = _displayPhone(
      _sanitizePhone(json['ShipTelephoneNo']?.toString() ?? ''),
    );
    final totalCarat = _firstDouble([
      json['Total_Carat'],
      json['PendingCts'],
    ]);
    final totalPcs = _firstDouble([
      json['Total_PacketPcs'],
      json['Total_Stone'],
      json['PendingStone'],
    ]);
    final pendingStone = _asInt(json['PendingStone']);
    final pendingCts = _asDouble(json['PendingCts']);
    final pendingAmount = _asDouble(json['PendingAmount']);
    final totalAmt = _firstDouble([
      json['Total_Amt'],
      json['Gross_Amt'],
      json['Net_Amt'],
      json['PendingAmount'],
    ]);
    final netAmt = _firstDouble([
      json['Net_Amt'],
      json['Total_Amt'],
      json['PendingAmount'],
    ]);
    final averagePrice = _firstDouble([
      json['Price_Per_Cts'],
      json['PendindRate'],
      json['PendingRate'],
      json['Average_Price'],
    ]);

    final descriptionParts = <String>[
      if (entryBy.isNotEmpty) 'Entry: $entryBy',
      if (branchName.trim().isNotEmpty) branchName.trim(),
      if (totalCarat > 0) '${totalCarat.toStringAsFixed(3)} Cts',
    ];

    return Memo(
      id: memoNo.trim().isNotEmpty
          ? memoNo.trim()
          : _asInt(json['Memo_ID']).toString(),
      memoId: _asInt(json['Memo_ID']),
      name: partyName.isNotEmpty ? partyName : 'Memo',
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
      totalPcs: totalPcs,
      pendingStone: pendingStone > 0 ? pendingStone : totalPcs.toInt(),
      pendingCts: pendingCts > 0 ? pendingCts : totalCarat,
      pendingAmount: pendingAmount > 0 ? pendingAmount : totalAmt,
      billType: billType,
      memoStatusRaw: statusRaw,
      salesPerson: json['Sales_Person']?.toString() ?? '',
      entryBy: entryBy,
      deliverBy: deliverBy,
      billingCompanyName: billingCompanyName,
      billingName: billingName,
      billingAddress: billingAddress,
      shippingCompanyName: shippingCompanyName,
      shippingAddress: shippingAddress,
      cityName: cityName,
      stateName: stateName,
      deliverAssignBy: deliverAssignBy,
      deliverDate: deliverDate,
      deliveredDate: deliveredDate,
      mailTelephoneNo: mailTelephoneNo,
      shipTelephoneNo: shipTelephoneNo,
    );
  }
}

/// Groups flat delivery stone rows into memo list items (Type 2).
List<Memo> groupDeliveryStonesIntoMemos(List<Map<String, dynamic>> stoneRows) {
  if (stoneRows.isEmpty) return [];

  final grouped = <String, List<Map<String, dynamic>>>{};
  for (final stone in stoneRows) {
    final memoId = _asInt(stone['Memo_ID']);
    final memoNo = stone['Memo_No']?.toString().trim() ?? '';
    final key = memoId > 0
        ? 'id_$memoId'
        : (memoNo.isNotEmpty ? 'no_$memoNo' : 'row_${grouped.length}');
    grouped.putIfAbsent(key, () => []).add(stone);
  }

  final memos = <Memo>[];
  for (final stones in grouped.values) {
    final first = stones.first;
    final diamonds = stones.map(Diamond.fromApiJson).toList();

    var totalCarat = 0.0;
    var totalAmt = 0.0;
    var totalRate = 0.0;
    var totalPcs = 0.0;
    var pendingStone = 0;
    for (final stone in stones) {
      final pcs = _asDouble(stone['PacketPcs']);
      totalPcs += pcs > 0 ? pcs : 1;
      totalCarat += _asDouble(stone['Weight']);
      totalAmt += _firstDouble([
        stone['Memo_Amt'],
        stone['Final_Amt'],
        stone['Original_Amt'],
      ]);
      totalRate += _firstDouble([
        stone['Memo_Rate'],
        stone['Original_Rate'],
      ]);
      final status = (stone['Stone_Status']?.toString() ?? '').toUpperCase();
      if (status.contains('PENDING') || status.isEmpty) {
        pendingStone++;
      }
    }
    final avgRate = stones.isNotEmpty ? totalRate / stones.length : 0.0;
    final memoNo = first['Memo_No']?.toString().trim() ?? '';
    final memoDate = first['Memo_Date']?.toString() ?? '';
    final partyName = _firstNonEmpty([
      first['Party_Name'],
      first['Customer_Name'],
      first['Ledger_Name'],
    ]);
    final statusRaw = _firstNonEmpty([
      first['Delivered_Status'],
      first['Memo_Status'],
      first['Stone_Status'],
      first['StockStatus'],
    ]);
    final entryBy = _firstNonEmpty([
      first['Entry_By'],
      first['EntryBy'],
    ]);

    final descriptionParts = <String>[
      if (totalCarat > 0) '${totalCarat.toStringAsFixed(3)} Cts',
      if (diamonds.isNotEmpty) '${diamonds.length} stones',
    ];

    memos.add(
      Memo(
        id: memoNo.isNotEmpty ? memoNo : _asInt(first['Memo_ID']).toString(),
        memoId: _asInt(first['Memo_ID']),
        name: partyName.isNotEmpty
            ? partyName
            : (memoNo.isNotEmpty ? memoNo : 'Memo'),
        description: descriptionParts.join(' · '),
        customerName: partyName.isNotEmpty ? partyName : memoNo,
        date: _parseMemoDate(memoDate) ?? DateTime.now(),
        dateLabel: memoDate,
        ppc: avgRate,
        dollarPrice: totalAmt,
        total: totalAmt,
        status: _mapStatus(statusRaw, first['Is_Delivered']),
        diamonds: diamonds,
        branchName: first['Branch_Name']?.toString() ?? '',
        currencyName: first['Currency_Name']?.toString() ?? '',
        totalCarat: totalCarat,
        totalPcs: totalPcs,
        pendingStone: pendingStone > 0 ? pendingStone : diamonds.length,
        pendingCts: totalCarat,
        pendingAmount: totalAmt,
        billType: first['BillType']?.toString() ?? '',
        memoStatusRaw: statusRaw,
        salesPerson: first['Sales_Person']?.toString() ?? '',
        entryBy: entryBy,
        deliverBy: _firstNonEmpty([
          first['Deliver_By'],
          first['DeliverBy'],
        ]),
        billingCompanyName: first['BillingCompanyName']?.toString() ?? '',
        billingName: first['BillingName']?.toString() ?? '',
        billingAddress: first['BillingAddress']?.toString() ?? '',
        shippingCompanyName: first['ShippingCompanyName']?.toString() ?? '',
        shippingAddress: first['ShippingAddress']?.toString() ?? '',
        cityName: first['City_Name']?.toString() ?? '',
        stateName: first['State_Name']?.toString() ?? '',
        deliverAssignBy: first['Deliver_Assign_By']?.toString() ?? '',
        deliverDate: first['Deliver_Date']?.toString() ?? '',
        deliveredDate: first['Delivered_Date']?.toString() ?? '',
        mailTelephoneNo: _displayPhone(
          _sanitizePhone(first['Mail_Telephone_No']?.toString() ?? ''),
        ),
        shipTelephoneNo: _displayPhone(
          _sanitizePhone(first['ShipTelephoneNo']?.toString() ?? ''),
        ),
      ),
    );
  }

  memos.sort((a, b) => b.date.compareTo(a.date));
  return memos;
}

bool _isStoneDetailRow(Map<String, dynamic> json) {
  return _firstNonEmpty([
        json['Stone_NO'],
        json['Stone_No'],
        json['Memo_Detail_ID'],
      ]).isNotEmpty ||
      (json.containsKey('Weight') &&
          !json.containsKey('Party_Name') &&
          !json.containsKey('Entry_By'));
}

List<Map<String, dynamic>> _extractResultRows(dynamic rawResult) {
  final rows = <Map<String, dynamic>>[];
  if (rawResult is List) {
    for (final item in rawResult) {
      if (item is Map<String, dynamic>) {
        rows.add(item);
      } else if (item is Map) {
        rows.add(Map<String, dynamic>.from(item));
      }
    }
    return rows;
  }
  if (rawResult is Map) {
    final map = Map<String, dynamic>.from(rawResult);
    final nested = map['rows'];
    if (nested is List) {
      for (final item in nested) {
        if (item is Map<String, dynamic>) {
          rows.add(item);
        } else if (item is Map) {
          rows.add(Map<String, dynamic>.from(item));
        }
      }
    }
  }
  return rows;
}

MemoStatus _mapStatus(String raw, dynamic isDelivered) {
  final status = raw.trim().toUpperCase();
  if (status.contains('DISPATCH') ||
      (status.contains('DELIVER') && !status.contains('PENDING')) ||
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

String _firstNonEmpty(List<dynamic> values) {
  for (final value in values) {
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
  }
  return '';
}

String _sanitizePhone(String raw) {
  final text = raw.trim();
  if (text.isEmpty || text == '0' || text.toLowerCase() == 'null') {
    return '';
  }
  return text;
}

String _displayPhone(String sanitized) {
  return sanitized.isNotEmpty ? sanitized : '0000000000';
}

double _firstDouble(List<dynamic> values) {
  for (final value in values) {
    final parsed = _asDouble(value);
    if (parsed != 0) return parsed;
  }
  return 0;
}

List<Diamond> parseMemoDiamondsFromResponse(Map<String, dynamic> json) {
  final stoneRows = _extractResultRows(json['Result']);
  if (stoneRows.isEmpty) return const [];
  if (_isStoneDetailRow(stoneRows.first)) {
    return stoneRows.map(Diamond.fromApiJson).toList();
  }
  return const [];
}
