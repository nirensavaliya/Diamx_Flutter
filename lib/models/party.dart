class PartyListResponse {
  const PartyListResponse({
    required this.message,
    required this.error,
    required this.rows,
    required this.isSessionExpire,
    required this.isSuccess,
    required this.statusCode,
  });

  final String message;
  final String error;
  final List<Party> rows;
  final bool isSessionExpire;
  final bool isSuccess;
  final String statusCode;

  bool get hasError => error.trim().isNotEmpty;
  bool get isPartyListSuccess => isSuccess && !hasError;

  factory PartyListResponse.fromJson(Map<String, dynamic> json) {
    final rows = <Party>[];
    final rawResult = json['Result'];

    if (rawResult is Map<String, dynamic>) {
      rows.addAll(_parseRows(rawResult['rows']));
    } else if (rawResult is Map) {
      rows.addAll(_parseRows(rawResult['rows']));
    }

    return PartyListResponse(
      message: json['Message']?.toString() ?? '',
      error: json['Error']?.toString() ?? '',
      rows: rows,
      isSessionExpire: _asBool(json['IsSessionExpire']),
      isSuccess: _asBool(json['IsSuccess']),
      statusCode: json['StatusCode']?.toString() ?? '',
    );
  }

  static List<Party> _parseRows(dynamic rawRows) {
    if (rawRows is! List) return [];
    return rawRows
        .whereType<Map>()
        .map((e) => Party.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

class Party {
  const Party({
    required this.ledgerId,
    required this.ledgerName,
    required this.shortName,
    required this.groupName,
    required this.currencyId,
    required this.currencyName,
    required this.convertBy,
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
    required this.isBillByBill,
    required this.discount,
    this.billType,
    required this.branchId,
    required this.groupId,
  });

  final int ledgerId;
  final String ledgerName;
  final String shortName;
  final String groupName;
  final int currencyId;
  final String currencyName;
  final double convertBy;
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
  final bool isBillByBill;
  final double discount;
  final String? billType;
  final int branchId;
  final int groupId;

  String get displayName =>
      ledgerName.trim().isNotEmpty ? ledgerName.trim() : shortName.trim();

  factory Party.fromJson(Map<String, dynamic> json) {
    return Party(
      ledgerId: _asInt(json['Ledger_Id']),
      ledgerName: json['Ledger_Name']?.toString() ?? '',
      shortName: json['Short_Name']?.toString() ?? '',
      groupName: json['Group_Name']?.toString() ?? '',
      currencyId: _asInt(json['Currency_Id']),
      currencyName: json['Currency_Name']?.toString() ?? '',
      convertBy: _asDouble(json['Convert_By']),
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
      isBillByBill: _asBool(json['Is_Bill_By_Bill']),
      discount: _asDouble(json['Discount']),
      billType: _asNullableString(json['Bill_Type']),
      branchId: _asInt(json['BranchId']),
      groupId: _asInt(json['Group_Id']),
    );
  }
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
  return text == 'true' || text == '1';
}

String? _asNullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  if (text.isEmpty || text.toLowerCase() == 'null') return null;
  return text;
}