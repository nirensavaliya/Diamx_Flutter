enum InvoiceStatus { pending, paid }

class InvoiceItem {
  const InvoiceItem({
    required this.id,
    required this.stockNumber,
    required this.shape,
    required this.carat,
    required this.color,
    required this.clarity,
    required this.pricePerCarat,
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
  final double pricePerCarat;
  final double total;
  final String lab;
  final String labReportNo;
  final String cut;
  final String polish;
  final String symm;
  final double discount;

  factory InvoiceItem.fromApiJson(Map<String, dynamic> json) {
    final id = _firstNonEmpty([
      json['Memo_Detail_ID'],
      json['Sale_Invoice_Detail_ID'],
      json['Invoice_Detail_ID'],
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
    final memoAmt = _asDouble(json['Memo_Amt']);
    final finalAmt = _asDouble(json['Final_Amt']);
    final saleAmt = _firstDouble([
      json['Sale_Amt'],
      json['Invoice_Amt'],
      json['Net_Amt'],
      json['Total_Amt'],
      json['Amount'],
    ]);
    final total = memoAmt != 0
        ? memoAmt
        : (finalAmt != 0 ? finalAmt : saleAmt);
    final rate = _firstDouble([
      json['Memo_Rate'],
      json['Sale_Rate'],
      json['Original_Rate'],
      json['Price'],
      json['PPC'],
      json['Asking_Rate'],
      json['Price_Per_Cts'],
      json['Avg_Rate'],
      json['Average_Price'],
      json['Rate'],
    ]);
    final discount = _asDouble(json['Memo_Discount']) != 0
        ? _asDouble(json['Memo_Discount'])
        : _firstDouble([
            json['Sale_Discount'],
            json['Original_Discount'],
            json['Discount'],
          ]);

    return InvoiceItem(
      id: id.isNotEmpty ? id : stockNumber,
      stockNumber: stockNumber.isNotEmpty ? stockNumber : id,
      shape: _firstNonEmpty([
        json['Shape_Name'],
        json['Shape'],
        json['ShapeName'],
      ]),
      carat: _firstDouble([
        json['Weight'],
        json['Issue_Cts'],
        json['Carat'],
        json['Cts'],
        json['Total_Carat'],
      ]),
      color: _firstNonEmpty([
        json['Color_Name'],
        json['Color'],
        json['Colour'],
      ]),
      clarity: _firstNonEmpty([
        json['Clarity_Name'],
        json['Clarity'],
      ]),
      pricePerCarat: rate,
      total: total,
      lab: _firstNonEmpty([json['Lab_Name'], json['Lab']]),
      labReportNo: _firstNonEmpty([
        json['Lab_Report_No'],
        json['Certificate_No'],
      ]),
      cut: _firstNonEmpty([json['Cut_Name'], json['Cut']]),
      polish: _firstNonEmpty([json['Polish_Name'], json['Polish']]),
      symm: _firstNonEmpty([
        json['Symm_Name'],
        json['Symmetry_Name'],
        json['Symm'],
      ]),
      discount: discount,
    );
  }
}

class InvoiceSummaryResponse {
  const InvoiceSummaryResponse({
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
  final List<Invoice> rows;
  final double totalPcs;
  final double totalCts;
  final double totalRate;
  final double totalAmt;
  final int totalCount;
  final bool isSessionExpire;
  final bool isSuccess;
  final String statusCode;

  bool get hasError => error.trim().isNotEmpty;
  bool get isInvoiceListSuccess => isSuccess && !hasError;

  factory InvoiceSummaryResponse.fromJson(Map<String, dynamic> json) {
    final resultRows = _extractResultRows(json['Result']);

    var totalPcs = 0.0;
    var totalCts = 0.0;
    var totalRate = 0.0;
    var totalAmt = 0.0;
    var totalCount = 0;

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

    final List<Invoice> rows;
    final isStoneLevel =
        resultRows.isNotEmpty && _isStoneDetailRow(resultRows.first);

    if (isStoneLevel) {
      rows = groupDeliveryStonesIntoInvoices(resultRows);
      if (totalPcs == 0) {
        for (final stone in resultRows) {
          final pcs = _asDouble(stone['PacketPcs']);
          totalPcs += pcs > 0 ? pcs : 1;
          totalCts += _asDouble(stone['Weight']);
          totalAmt += _firstDouble([
            stone['Memo_Amt'],
            stone['Final_Amt'],
            stone['Sale_Amt'],
            stone['Original_Amt'],
          ]);
          totalRate += _firstDouble([
            stone['Memo_Rate'],
            stone['Sale_Rate'],
            stone['Original_Rate'],
          ]);
        }
        if (resultRows.isNotEmpty) {
          totalRate = totalRate / resultRows.length;
        }
      }
    } else {
      rows = resultRows.map(Invoice.fromApiJson).toList();
      if (totalPcs == 0 && rows.isNotEmpty) {
        for (final invoice in rows) {
          totalPcs += invoice.totalPcs > 0
              ? invoice.totalPcs
              : invoice.itemCount.toDouble();
          totalCts += invoice.totalCarat;
          totalAmt += invoice.listGrandTotal;
          totalRate += invoice.averageRate;
        }
        if (rows.isNotEmpty) {
          totalRate = totalRate / rows.length;
        }
      }
    }

    // Do not fall back to rows.length — that breaks pagination when API
    // returns a full page without a TotalCount field.

    return InvoiceSummaryResponse(
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

class Invoice {
  const Invoice({
    required this.id,
    required this.invoiceId,
    required this.title,
    required this.description,
    required this.customerName,
    required this.date,
    required this.dateLabel,
    required this.dueDate,
    required this.status,
    required this.taxRate,
    required this.items,
    this.branchName = '',
    this.billType = '',
    this.orderStatusRaw = '',
    this.itemCount = 0,
    this.listGrandTotal = 0,
    this.currencyName = '',
    this.totalCarat = 0,
    this.totalPcs = 0,
    this.averageRate = 0,
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
  final int invoiceId;
  final String title;
  final String description;
  final String customerName;
  final DateTime date;
  final String dateLabel;
  final DateTime dueDate;
  final InvoiceStatus status;
  final double taxRate;
  final List<InvoiceItem> items;
  final String branchName;
  final String billType;
  final String orderStatusRaw;
  final int itemCount;
  final double listGrandTotal;
  final String currencyName;
  final double totalCarat;
  final double totalPcs;
  final double averageRate;
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

  int get diamondCount =>
      itemCount > 0 ? itemCount : (items.isNotEmpty ? items.length : totalPcs.toInt());

  double get subtotal => items.isNotEmpty
      ? items.fold<double>(0, (sum, item) => sum + item.total)
      : (listGrandTotal > 0 && taxRate > 0
            ? listGrandTotal / (1 + taxRate / 100)
            : listGrandTotal);

  double get taxAmount => items.isNotEmpty
      ? subtotal * taxRate / 100
      : (listGrandTotal > 0 && taxRate > 0 ? listGrandTotal - subtotal : 0);

  double get grandTotal =>
      items.isNotEmpty ? subtotal + taxAmount : listGrandTotal;

  String get statusLabel {
    if (orderStatusRaw.trim().isNotEmpty) {
      final raw = orderStatusRaw.trim();
      return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
    }
    return switch (status) {
      InvoiceStatus.pending => 'Pending',
      InvoiceStatus.paid => 'Paid',
    };
  }

  Invoice copyWith({List<InvoiceItem>? items}) {
    return Invoice(
      id: id,
      invoiceId: invoiceId,
      title: title,
      description: description,
      customerName: customerName,
      date: date,
      dateLabel: dateLabel,
      dueDate: dueDate,
      status: status,
      taxRate: taxRate,
      items: items ?? this.items,
      branchName: branchName,
      billType: billType,
      orderStatusRaw: orderStatusRaw,
      itemCount: itemCount,
      listGrandTotal: listGrandTotal,
      currencyName: currencyName,
      totalCarat: totalCarat,
      totalPcs: totalPcs,
      averageRate: averageRate,
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

  factory Invoice.fromApiJson(Map<String, dynamic> json) {
    final orderNo = _firstNonEmpty([
      json['Sale_Invoice_No'],
      json['Order_No'],
      json['Invoice_No'],
      json['Sales_Invoice_No'],
      json['Transaction_No'],
      json['Voucher_No'],
    ]);
    final partyName = _firstNonEmpty([
      json['Party_Name'],
      json['BillingCompanyName'],
      json['BillingName'],
      json['Customer_Name'],
      json['Ledger_Name'],
    ]);
    final branchName = json['Branch_Name']?.toString() ?? '';
    final billType = json['BillType']?.toString() ?? '';
    final orderDate = _firstNonEmpty([
      json['Sale_Invoicedate'],
      json['Sale_Invoice_Date'],
      json['Order_Date'],
      json['Invoice_Date'],
      json['Sales_Invoice_Date'],
      json['Voucher_Date'],
    ]);
    final statusRaw = _firstNonEmpty([
      json['Delivered_Status'],
      json['Order_Status'],
      json['Invoice_Status'],
      json['Payment_Status'],
      json['Status'],
    ]);
    final entryBy = _firstNonEmpty([json['Entry_By'], json['EntryBy']]);
    final deliverBy = _firstNonEmpty([json['Deliver_By'], json['DeliverBy']]);
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
    final mailTelephoneNo = _displayInvoicePhone(
      _sanitizeInvoicePhone(json['Mail_Telephone_No']?.toString() ?? ''),
    );
    final shipTelephoneNo = _displayInvoicePhone(
      _sanitizeInvoicePhone(json['ShipTelephoneNo']?.toString() ?? ''),
    );
    final totalCarat = _firstDouble([
      json['Total_Carat'],
      json['PendingCts'],
      json['TotalCts'],
      json['Total_Cts'],
    ]);
    final totalPcs = _firstDouble([
      json['Total_PacketPcs'],
      json['Total_Stone'],
      json['PendingStone'],
      json['TotalPcs'],
      json['Total_Pcs'],
    ]);
    final itemCount = totalPcs.toInt();
    final totalAmt = _firstDouble([
      json['Total_Amt'],
      json['Gross_Amt'],
      json['Net_Amt'],
      json['PendingAmount'],
      json['Amount'],
    ]);
    final netAmt = _firstDouble([
      json['Net_Amt'],
      json['Total_Amt'],
      json['PendingAmount'],
      json['Grand_Total'],
      json['Invoice_Amt'],
    ]);
    final averagePrice = _firstDouble([
      json['Price_Per_Cts'],
      json['PendindRate'],
      json['PendingRate'],
      json['Average_Price'],
    ]);
    final taxRate = _firstDouble([
      json['Tax_Rate'],
      json['Tax'],
      json['GST_Rate'],
      json['Tax_Percent'],
    ]);
    final invoiceId = _asInt(
      _firstNonEmpty([
        json['Sale_Invoice_ID'],
        json['Order_ID'],
        json['Invoice_ID'],
        json['Tran_Id'],
        json['Transaction_ID'],
        json['Sales_Invoice_ID'],
      ]),
    );

    final descriptionParts = <String>[
      if (entryBy.isNotEmpty) 'Entry: $entryBy',
      if (branchName.trim().isNotEmpty) branchName.trim(),
      if (totalCarat > 0) '${totalCarat.toStringAsFixed(3)} Cts',
    ];

    final parsedDate =
        _parseInvoiceDate(orderDate) ??
        DateTime.tryParse(
          json['TransactionSaleInvoiceDate']?.toString() ?? '',
        ) ??
        DateTime.tryParse(json['SearchOrderDate']?.toString() ?? '') ??
        DateTime.now();

    final dueDateLabel = _firstNonEmpty([json['Payment_Due_Date']]);
    final parsedDueDate =
        _parseInvoiceDate(dueDateLabel) ??
        parsedDate.add(const Duration(days: 15));

    return Invoice(
      id: orderNo.isNotEmpty ? orderNo : invoiceId.toString(),
      invoiceId: invoiceId,
      title: partyName.isNotEmpty ? partyName : 'Invoice',
      description: descriptionParts.isEmpty
          ? (json['Remark']?.toString() ?? '')
          : descriptionParts.join(' · '),
      customerName: partyName,
      date: parsedDate,
      dateLabel: orderDate.isNotEmpty ? orderDate : dueDateLabel,
      dueDate: parsedDueDate,
      status: _mapInvoiceStatus(statusRaw, json['Is_Paid']),
      taxRate: taxRate,
      items: const [],
      branchName: branchName,
      billType: billType,
      orderStatusRaw: statusRaw,
      itemCount: itemCount,
      listGrandTotal: netAmt != 0 ? netAmt : totalAmt,
      currencyName: json['Currency_Name']?.toString() ?? '',
      totalCarat: totalCarat,
      totalPcs: totalPcs,
      averageRate: averagePrice,
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

List<Invoice> groupDeliveryStonesIntoInvoices(
  List<Map<String, dynamic>> stoneRows,
) {
  if (stoneRows.isEmpty) return [];

  final grouped = <String, List<Map<String, dynamic>>>{};
  for (final stone in stoneRows) {
    final invoiceId = _asInt(
      _firstNonEmpty([
        stone['Sale_Invoice_ID'],
        stone['Invoice_ID'],
        stone['Memo_ID'],
      ]),
    );
    final invoiceNo = _firstNonEmpty([
      stone['Sale_Invoice_No'],
      stone['Invoice_No'],
      stone['Memo_No'],
    ]);
    final key = invoiceId > 0
        ? 'id_$invoiceId'
        : (invoiceNo.isNotEmpty ? 'no_$invoiceNo' : 'row_${grouped.length}');
    grouped.putIfAbsent(key, () => []).add(stone);
  }

  final invoices = <Invoice>[];
  for (final stones in grouped.values) {
    final first = stones.first;
    final items = stones.map(InvoiceItem.fromApiJson).toList();

    var totalCarat = 0.0;
    var totalAmt = 0.0;
    var totalRate = 0.0;
    var totalPcs = 0.0;
    for (final stone in stones) {
      final pcs = _asDouble(stone['PacketPcs']);
      totalPcs += pcs > 0 ? pcs : 1;
      totalCarat += _asDouble(stone['Weight']);
      totalAmt += _firstDouble([
        stone['Memo_Amt'],
        stone['Final_Amt'],
        stone['Sale_Amt'],
        stone['Original_Amt'],
      ]);
      totalRate += _firstDouble([
        stone['Memo_Rate'],
        stone['Sale_Rate'],
        stone['Original_Rate'],
      ]);
    }
    final avgRate = stones.isNotEmpty ? totalRate / stones.length : 0.0;
    final invoiceNo = _firstNonEmpty([
      first['Sale_Invoice_No'],
      first['Invoice_No'],
      first['Memo_No'],
    ]);
    final invoiceDate = _firstNonEmpty([
      first['Sale_Invoicedate'],
      first['Sale_Invoice_Date'],
      first['Invoice_Date'],
      first['Memo_Date'],
    ]);
    final partyName = _firstNonEmpty([
      first['Party_Name'],
      first['Customer_Name'],
      first['Ledger_Name'],
    ]);
    final statusRaw = _firstNonEmpty([
      first['Delivered_Status'],
      first['Order_Status'],
      first['Stone_Status'],
      first['StockStatus'],
    ]);
    final entryBy = _firstNonEmpty([first['Entry_By'], first['EntryBy']]);
    final parsedDate = _parseInvoiceDate(invoiceDate) ?? DateTime.now();

    invoices.add(
      Invoice(
        id: invoiceNo.isNotEmpty
            ? invoiceNo
            : _asInt(
                _firstNonEmpty([
                  first['Sale_Invoice_ID'],
                  first['Invoice_ID'],
                  first['Memo_ID'],
                ]),
              ).toString(),
        invoiceId: _asInt(
          _firstNonEmpty([
            first['Sale_Invoice_ID'],
            first['Invoice_ID'],
            first['Memo_ID'],
          ]),
        ),
        title: partyName.isNotEmpty
            ? partyName
            : (invoiceNo.isNotEmpty ? invoiceNo : 'Invoice'),
        description: [
          if (totalCarat > 0) '${totalCarat.toStringAsFixed(3)} Cts',
          if (items.isNotEmpty) '${items.length} stones',
        ].join(' · '),
        customerName: partyName.isNotEmpty ? partyName : invoiceNo,
        date: parsedDate,
        dateLabel: invoiceDate,
        dueDate: parsedDate.add(const Duration(days: 15)),
        status: _mapInvoiceStatus(statusRaw, first['Is_Paid']),
        taxRate: 0,
        items: items,
        branchName: first['Branch_Name']?.toString() ?? '',
        currencyName: first['Currency_Name']?.toString() ?? '',
        totalCarat: totalCarat,
        totalPcs: totalPcs,
        averageRate: avgRate,
        itemCount: items.length,
        listGrandTotal: totalAmt,
        orderStatusRaw: statusRaw,
        entryBy: entryBy,
        deliverBy: _firstNonEmpty([first['Deliver_By'], first['DeliverBy']]),
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
        mailTelephoneNo: _displayInvoicePhone(
          _sanitizeInvoicePhone(first['Mail_Telephone_No']?.toString() ?? ''),
        ),
        shipTelephoneNo: _displayInvoicePhone(
          _sanitizeInvoicePhone(first['ShipTelephoneNo']?.toString() ?? ''),
        ),
      ),
    );
  }

  invoices.sort((a, b) => b.date.compareTo(a.date));
  return invoices;
}

bool _isStoneDetailRow(Map<String, dynamic> json) {
  return _firstNonEmpty([
        json['Stone_NO'],
        json['Stone_No'],
        json['Memo_Detail_ID'],
        json['Sale_Invoice_Detail_ID'],
        json['Invoice_Detail_ID'],
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

InvoiceStatus _mapInvoiceStatus(String raw, dynamic isPaid) {
  final status = raw.trim().toUpperCase();
  if (status.contains('PAID') ||
      status.contains('SETTLE') ||
      status.contains('CLOSE') ||
      status.contains('COMPLETE') ||
      (status.contains('DELIVER') && !status.contains('PENDING')) ||
      _asBool(isPaid)) {
    return InvoiceStatus.paid;
  }
  return InvoiceStatus.pending;
}

DateTime? _parseInvoiceDate(String value) {
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

String _sanitizeInvoicePhone(String raw) {
  final text = raw.trim();
  if (text.isEmpty || text == '0' || text.toLowerCase() == 'null') {
    return '';
  }
  return text;
}

String _displayInvoicePhone(String sanitized) {
  return sanitized.isNotEmpty ? sanitized : '0000000000';
}

double _firstDouble(List<dynamic> values) {
  for (final value in values) {
    final parsed = _asDouble(value);
    if (parsed != 0) return parsed;
  }
  return 0;
}

List<InvoiceItem> parseInvoiceItemsFromResponse(Map<String, dynamic> json) {
  final stoneRows = _extractResultRows(json['Result']);
  if (stoneRows.isEmpty) return const [];
  if (_isStoneDetailRow(stoneRows.first)) {
    return stoneRows.map(InvoiceItem.fromApiJson).toList();
  }
  final invoices = stoneRows.map(Invoice.fromApiJson).toList();
  final items = <InvoiceItem>[];
  for (final invoice in invoices) {
    items.addAll(invoice.items);
  }
  return items;
}
