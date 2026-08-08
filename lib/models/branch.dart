class BranchListResponse {
  const BranchListResponse({
    required this.message,
    required this.error,
    required this.result,
  });

  final String message;
  final String error;
  final List<Branch> result;

  bool get hasError => error.trim().isNotEmpty;
  bool get isSuccess => !hasError && result.isNotEmpty;

  factory BranchListResponse.fromJson(Map<String, dynamic> json) {
    final rawResult = json['Result'];
    final branches = <Branch>[];

    if (rawResult is List) {
      for (final item in rawResult) {
        if (item is Map<String, dynamic>) {
          branches.add(Branch.fromJson(item));
        } else if (item is Map) {
          branches.add(Branch.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return BranchListResponse(
      message: json['Message']?.toString() ?? '',
      error: json['Error']?.toString() ?? '',
      result: branches,
    );
  }
}

class Branch {
  const Branch({
    required this.ledgerId,
    required this.ledgerName,
    required this.shortName,
    required this.groupName,
    required this.currencyId,
    required this.convertBy,
    required this.currencyName,
    this.stockCurrencyId,
    required this.isBillByBill,
    this.baseCurrency,
    this.mailAddress,
    required this.mailCountryId,
    required this.mailStateId,
    required this.mailCityId,
    this.shipAddress,
    required this.shipCountryId,
    required this.shipStateId,
    required this.shipCityId,
    this.countryName,
    this.location,
    this.shippingLocation,
    required this.discount,
    this.billType,
    required this.defaultStockLocationId,
  });

  final int ledgerId;
  final String ledgerName;
  final String shortName;
  final String groupName;
  final int currencyId;
  final double convertBy;
  final String currencyName;
  final int? stockCurrencyId;
  final bool isBillByBill;
  final int? baseCurrency;
  final String? mailAddress;
  final int mailCountryId;
  final int mailStateId;
  final int mailCityId;
  final String? shipAddress;
  final int shipCountryId;
  final int shipStateId;
  final int shipCityId;
  final String? countryName;
  final String? location;
  final String? shippingLocation;
  final double discount;
  final String? billType;
  final int defaultStockLocationId;

  String get displayName =>
      ledgerName.trim().isNotEmpty ? ledgerName : shortName;

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      ledgerId: _asInt(json['Ledger_Id']),
      ledgerName: json['Ledger_Name']?.toString() ?? '',
      shortName: json['Short_Name']?.toString() ?? '',
      groupName: json['Group_Name']?.toString() ?? '',
      currencyId: _asInt(json['Currency_Id']),
      convertBy: _asDouble(json['Convert_By']),
      currencyName: json['Currency_Name']?.toString() ?? '',
      stockCurrencyId: _asNullableInt(json['Stock_Currency_ID']),
      isBillByBill: _asBool(json['Is_Bill_By_Bill']),
      baseCurrency: _asNullableInt(json['Base_Currency']),
      mailAddress: _asNullableString(json['MailAddress']),
      mailCountryId: _asInt(json['Mail_Country_Id']),
      mailStateId: _asInt(json['Mail_State_Id']),
      mailCityId: _asInt(json['Mail_City_Id']),
      shipAddress: _asNullableString(json['ShipAddress']),
      shipCountryId: _asInt(json['Ship_Country_Id']),
      shipStateId: _asInt(json['Ship_State_Id']),
      shipCityId: _asInt(json['Ship_City_Id']),
      countryName: _asNullableString(json['Country_Name']),
      location: _asNullableString(json['Location']),
      shippingLocation: _asNullableString(json['ShippingLocation']),
      discount: _asDouble(json['Discount']),
      billType: _asNullableString(json['Bill_Type']),
      defaultStockLocationId: _asInt(json['DefaultStockLocationID']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Ledger_Id': ledgerId,
      'Ledger_Name': ledgerName,
      'Short_Name': shortName,
      'Group_Name': groupName,
      'Currency_Id': currencyId,
      'Convert_By': convertBy,
      'Currency_Name': currencyName,
      'Stock_Currency_ID': stockCurrencyId,
      'Is_Bill_By_Bill': isBillByBill,
      'Base_Currency': baseCurrency,
      'MailAddress': mailAddress,
      'Mail_Country_Id': mailCountryId,
      'Mail_State_Id': mailStateId,
      'Mail_City_Id': mailCityId,
      'ShipAddress': shipAddress,
      'Ship_Country_Id': shipCountryId,
      'Ship_State_Id': shipStateId,
      'Ship_City_Id': shipCityId,
      'Country_Name': countryName,
      'Location': location,
      'ShippingLocation': shippingLocation,
      'Discount': discount,
      'Bill_Type': billType,
      'DefaultStockLocationID': defaultStockLocationId,
    };
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _asNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().toLowerCase();
    return text == 'true' || text == '1';
  }

  static String? _asNullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString();
    if (text.isEmpty || text.toLowerCase() == 'null') return null;
    return text;
  }
}
