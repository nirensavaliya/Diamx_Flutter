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
  });

  final String id;
  final String stockNumber;
  final String shape;
  final double carat;
  final String color;
  final String clarity;
  final double pricePerCarat;
  final double total;

  factory InvoiceItem.fromApiJson(Map<String, dynamic> json) {
    final id = _firstNonEmpty([
      json['Stone_ID'],
      json['Stock_ID'],
      json['ID'],
      json['Id'],
      json['StoneId'],
    ]);
    final stockNumber = _firstNonEmpty([
      json['Stock_No'],
      json['StockNumber'],
      json['Stone_No'],
      json['Certificate_No'],
      json['Lab_Report_No'],
      json['RFId'],
      json['RFID'],
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
        json['Issue_Cts'],
        json['Carat'],
        json['Cts'],
        json['Weight'],
        json['Total_Carat'],
      ]),
      color: _firstNonEmpty([
        json['Color'],
        json['Colour'],
        json['Color_Name'],
      ]),
      clarity: _firstNonEmpty([
        json['Clarity'],
        json['Clarity_Name'],
      ]),
      pricePerCarat: _firstDouble([
        json['Price'],
        json['PPC'],
        json['Asking_Rate'],
        json['Price_Per_Cts'],
        json['Avg_Rate'],
        json['Average_Price'],
        json['Rate'],
      ]),
      total: _firstDouble([
        json['Total'],
        json['Net_Amt'],
        json['Total_Amt'],
        json['Amount'],
      ]),
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
    final rows = <Invoice>[];
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
            rows.add(Invoice.fromApiJson(item));
          } else if (item is Map) {
            rows.add(Invoice.fromApiJson(Map<String, dynamic>.from(item)));
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

  int get diamondCount => itemCount > 0 ? itemCount : items.length;

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
      json['Customer_Name'],
      json['Ledger_Name'],
    ]);
    final branchName = json['Branch_Name']?.toString() ?? '';
    final billType = json['BillType']?.toString() ?? '';
    final orderDate = _firstNonEmpty([
      json['Sale_Invoicedate'],
      json['Order_Date'],
      json['Invoice_Date'],
      json['Sales_Invoice_Date'],
      json['Voucher_Date'],
    ]);
    final statusRaw = _firstNonEmpty([
      json['Order_Status'],
      json['Invoice_Status'],
      json['Payment_Status'],
      json['Status'],
    ]);
    final totalCarat = _firstDouble([
      json['Total_Carat'],
      json['TotalCts'],
      json['Total_Cts'],
    ]);
    final itemCount = _asInt(
      _firstNonEmpty([
        json['TotalPcs'],
        json['Total_Stone'],
        json['PendingStone'],
        json['Total_Pcs'],
        json['Stone_Count'],
      ]),
    );
    final totalAmt = _firstDouble([
      json['Total_Amt'],
      json['Gross_Amt'],
      json['Amount'],
    ]);
    final netAmt = _firstDouble([
      json['Net_Amt'],
      json['Grand_Total'],
      json['Invoice_Amt'],
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
      if (billType.trim().isNotEmpty) billType.trim(),
      if (branchName.trim().isNotEmpty) branchName.trim(),
      if (totalCarat > 0) '${totalCarat.toStringAsFixed(3)} Cts',
      if (itemCount > 0) '$itemCount items',
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
    );
  }
}

InvoiceStatus _mapInvoiceStatus(String raw, dynamic isPaid) {
  final status = raw.trim().toUpperCase();
  if (status.contains('PAID') ||
      status.contains('SETTLE') ||
      status.contains('CLOSE') ||
      status.contains('COMPLETE') ||
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

double _firstDouble(List<dynamic> values) {
  for (final value in values) {
    final parsed = _asDouble(value);
    if (parsed != 0) return parsed;
  }
  return 0;
}

List<InvoiceItem> parseInvoiceItemsFromResponse(Map<String, dynamic> json) {
  final items = <InvoiceItem>[];
  final rawResult = json['Result'];
  if (rawResult is! Map) return items;

  final rawRows = Map<String, dynamic>.from(rawResult)['rows'];
  if (rawRows is! List) return items;

  for (final item in rawRows) {
    if (item is Map<String, dynamic>) {
      items.add(InvoiceItem.fromApiJson(item));
    } else if (item is Map) {
      items.add(InvoiceItem.fromApiJson(Map<String, dynamic>.from(item)));
    }
  }
  return items;
}
