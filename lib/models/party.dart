import 'dart:convert';

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
    final rawResult = json['Result'];
    final message = json['Message']?.toString() ?? '';
    var error = json['Error']?.toString() ?? '';

    // Backend sometimes returns Dapper/exception text inside Result with
    // IsSuccess=true and Error="". Treat that as a failed party load.
    if (rawResult is String) {
      final text = rawResult.trim();
      if (text.isNotEmpty &&
          (text.contains('Exception') ||
              text.contains('at Dapper') ||
              text.contains('at Repository') ||
              text.contains('at WEB_'))) {
        error = error.isNotEmpty ? error : text;
        return PartyListResponse(
          message: message,
          error: error,
          rows: const [],
          isSessionExpire: _asBool(json['IsSessionExpire']),
          isSuccess: false,
          statusCode: json['StatusCode']?.toString() ?? '',
        );
      }
    }

    final rows = _extractPartyMaps(rawResult).map(Party.fromJson).toList();

    return PartyListResponse(
      message: message,
      error: error,
      rows: rows,
      isSessionExpire: _asBool(json['IsSessionExpire']),
      isSuccess: _asBool(json['IsSuccess']),
      statusCode: json['StatusCode']?.toString() ?? '',
    );
  }

  /// Supports:
  /// - Result: [ {...}, ... ]
  /// - Result: { rows|Rows|Data|data|Table|PartyList: [ ... ] }
  /// - Result: "{...}" / "[{...}]" (JSON string)
  static List<Map<String, dynamic>> _extractPartyMaps(dynamic rawResult) {
    dynamic value = rawResult;

    if (value is String && value.trim().isNotEmpty) {
      try {
        value = jsonDecode(value);
      } catch (_) {
        return const [];
      }
    }

    if (value is List) {
      return _mapsFromList(value);
    }

    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      const listKeys = [
        'rows',
        'Rows',
        'Data',
        'data',
        'Table',
        'table',
        'PartyList',
        'partyList',
        'Parties',
        'parties',
        'List',
        'list',
      ];
      for (final key in listKeys) {
        final nested = map[key];
        if (nested is List) {
          return _mapsFromList(nested);
        }
      }

      // Some APIs nest once more: Result.Data.rows
      for (final key in listKeys) {
        final nested = map[key];
        if (nested is Map) {
          final inner = Map<String, dynamic>.from(nested);
          for (final innerKey in listKeys) {
            final innerList = inner[innerKey];
            if (innerList is List) {
              return _mapsFromList(innerList);
            }
          }
        }
      }

      // Single party object
      if (_looksLikeParty(map)) {
        return [map];
      }

      // Fallback: first list-valued entry in the map
      for (final entry in map.entries) {
        if (entry.value is List) {
          final parsed = _mapsFromList(entry.value as List);
          if (parsed.isNotEmpty) return parsed;
        }
      }
    }

    return const [];
  }

  static List<Map<String, dynamic>> _mapsFromList(List<dynamic> raw) {
    final rows = <Map<String, dynamic>>[];
    for (final item in raw) {
      if (item is Map<String, dynamic>) {
        rows.add(item);
      } else if (item is Map) {
        rows.add(Map<String, dynamic>.from(item));
      }
    }
    return rows;
  }

  static bool _looksLikeParty(Map<String, dynamic> map) {
    const idKeys = [
      'Ledger_Id',
      'LedgerId',
      'Ledger_ID',
      'Party_Id',
      'PartyId',
      'Party_ID',
      'ID',
      'Id',
    ];
    const nameKeys = [
      'Ledger_Name',
      'LedgerName',
      'Party_Name',
      'PartyName',
      'Name',
      'Full_Name',
      'Short_Name',
    ];
    final hasId = idKeys.any(map.containsKey);
    final hasName = nameKeys.any(map.containsKey);
    return hasId || hasName;
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
      ledgerId: _asInt(
        _pick(json, const [
          'Ledger_Id',
          'LedgerId',
          'Ledger_ID',
          'Party_Id',
          'PartyId',
          'Party_ID',
          'ID',
          'Id',
        ]),
      ),
      ledgerName: _asString(
        _pick(json, const [
          'Ledger_Name',
          'LedgerName',
          'Party_Name',
          'PartyName',
          'Name',
          'Full_Name',
          'FullName',
        ]),
      ),
      shortName: _asString(
        _pick(json, const [
          'Short_Name',
          'ShortName',
          'Party_Name',
          'PartyName',
          'Name',
        ]),
      ),
      groupName: _asString(
        _pick(json, const ['Group_Name', 'GroupName', 'Group']),
      ),
      currencyId: _asInt(
        _pick(json, const ['Currency_Id', 'CurrencyId', 'Currency_ID']),
      ),
      currencyName: _asString(
        _pick(json, const ['Currency_Name', 'CurrencyName', 'Currency']),
      ),
      convertBy: _asDouble(
        _pick(json, const ['Convert_By', 'ConvertBy']),
      ),
      mailAddress: _asNullableString(
        _pick(json, const ['MailAddress', 'Mail_Address', 'Address']),
      ),
      mailCountryId: _asInt(
        _pick(json, const ['Mail_Country_Id', 'MailCountryId']),
      ),
      mailStateId: _asInt(
        _pick(json, const ['Mail_State_Id', 'MailStateId']),
      ),
      mailCityId: _asInt(
        _pick(json, const ['Mail_City_Id', 'MailCityId']),
      ),
      shipAddress: _asNullableString(
        _pick(json, const ['ShipAddress', 'Ship_Address']),
      ),
      shipCountryId: _asInt(
        _pick(json, const ['Ship_Country_Id', 'ShipCountryId']),
      ),
      shipStateId: _asInt(
        _pick(json, const ['Ship_State_Id', 'ShipStateId']),
      ),
      shipCityId: _asInt(
        _pick(json, const ['Ship_City_Id', 'ShipCityId']),
      ),
      countryName: _asNullableString(
        _pick(json, const ['Country_Name', 'CountryName', 'Country']),
      ),
      location: _asNullableString(
        _pick(json, const ['Location', 'Loaction']),
      ),
      shippingLocation: _asNullableString(
        _pick(json, const ['ShippingLocation', 'Shipping_Location']),
      ),
      isBillByBill: _asBool(
        _pick(json, const ['Is_Bill_By_Bill', 'IsBillByBill']),
      ),
      discount: _asDouble(_pick(json, const ['Discount'])),
      billType: _asNullableString(
        _pick(json, const ['Bill_Type', 'BillType']),
      ),
      branchId: _asInt(
        _pick(json, const ['BranchId', 'Branch_Id', 'Branch_ID']),
      ),
      groupId: _asInt(
        _pick(json, const ['Group_Id', 'GroupId', 'Group_ID']),
      ),
    );
  }
}

dynamic _pick(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key) && json[key] != null) {
      return json[key];
    }
  }
  return null;
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

String _asString(dynamic value) {
  if (value == null) return '';
  final text = value.toString();
  if (text.toLowerCase() == 'null') return '';
  return text;
}

String? _asNullableString(dynamic value) {
  final text = _asString(value);
  return text.isEmpty ? null : text;
}
