import 'branch.dart';

class LoginApiResponse {
  const LoginApiResponse({
    required this.message,
    required this.error,
    this.result,
    required this.isSessionExpire,
    required this.isSuccess,
    required this.statusCode,
  });

  final String message;
  final String error;
  final LoginResult? result;
  final bool isSessionExpire;
  final bool isSuccess;
  final String statusCode;

  bool get hasError => error.trim().isNotEmpty;
  bool get isLoginSuccess =>
      isSuccess && !hasError && result?.login != null;

  factory LoginApiResponse.fromJson(Map<String, dynamic> json) {
    LoginResult? result;
    final rawResult = json['Result'];
    if (rawResult is Map<String, dynamic>) {
      result = LoginResult.fromJson(rawResult);
    } else if (rawResult is Map) {
      result = LoginResult.fromJson(Map<String, dynamic>.from(rawResult));
    }

    return LoginApiResponse(
      message: json['Message']?.toString() ?? '',
      error: json['Error']?.toString() ?? '',
      result: result,
      isSessionExpire: _asBool(json['IsSessionExpire']),
      isSuccess: _asBool(json['IsSuccess']),
      statusCode: json['StatusCode']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Message': message,
      'Error': error,
      'Result': result?.toJson(),
      'IsSessionExpire': isSessionExpire,
      'IsSuccess': isSuccess,
      'StatusCode': statusCode,
    };
  }
}

class LoginResult {
  const LoginResult({
    required this.login,
    required this.departmentList,
    required this.branchList,
    required this.yearList,
    required this.notification,
    required this.currencyCalculationFlags,
    required this.branchCurrencyRoundOffDetail,
    required this.rfidDevices,
  });

  final LoginUser login;
  final List<LoginDepartment> departmentList;
  final List<Branch> branchList;
  final List<LoginYear> yearList;
  final List<LoginNotification> notification;
  final List<CurrencyCalculationFlag> currencyCalculationFlags;
  final List<BranchCurrencyRoundOff> branchCurrencyRoundOffDetail;
  final List<RfidDevice> rfidDevices;

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    final rawLogin = json['login'];
    final loginMap = rawLogin is Map<String, dynamic>
        ? rawLogin
        : Map<String, dynamic>.from(rawLogin as Map);

    return LoginResult(
      login: LoginUser.fromJson(loginMap),
      departmentList: _mapList(json['DepartmentList'], LoginDepartment.fromJson),
      branchList: _mapList(json['BranchList'], Branch.fromJson),
      yearList: _mapList(json['Yearlist'], LoginYear.fromJson),
      notification: _mapList(json['Notification'], LoginNotification.fromJson),
      currencyCalculationFlags: _mapList(
        json['CurrancyCalCulationFlags'],
        CurrencyCalculationFlag.fromJson,
      ),
      branchCurrencyRoundOffDetail: _mapList(
        json['Branch_CurrancyRoundOffdetail'],
        BranchCurrencyRoundOff.fromJson,
      ),
      rfidDevices: _mapList(json['RfidDevices'], RfidDevice.fromJson),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'login': login.toJson(),
      'DepartmentList': departmentList.map((e) => e.toJson()).toList(),
      'BranchList': branchList.map((e) => e.toJson()).toList(),
      'Yearlist': yearList.map((e) => e.toJson()).toList(),
      'Notification': notification.map((e) => e.toJson()).toList(),
      'CurrancyCalCulationFlags':
          currencyCalculationFlags.map((e) => e.toJson()).toList(),
      'Branch_CurrancyRoundOffdetail':
          branchCurrencyRoundOffDetail.map((e) => e.toJson()).toList(),
      'RfidDevices': rfidDevices.map((e) => e.toJson()).toList(),
    };
  }
}

class LoginUser {
  const LoginUser({
    required this.userId,
    required this.fullName,
    required this.loginName,
    required this.branchName,
    required this.branchId,
    required this.departmentId,
    required this.departmentName,
    required this.locationId,
    required this.defaultStockLocationId,
    required this.location,
    required this.baseCurrency,
    required this.currencyDecimal,
    required this.yearId,
    required this.yearName,
    required this.loginToken,
    required this.companyName,
    required this.isShowAllLedger,
    required this.roleId,
    required this.fromYear,
    required this.toYear,
    required this.lang,
    required this.stockCurrencyId,
    required this.currencyName,
    required this.branchIds,
    required this.departmentIds,
    required this.enableNotificationAlert,
    required this.mfgDeptId,
    required this.isSuperAdmin,
    required this.idealTime,
    required this.mixCurrencyDecimal,
    required this.roughCurrencyDecimal,
    required this.certifiedCaratDecimal,
    required this.mixCertifiedCaratDecimal,
    required this.roughCertifiedCaratDecimal,
    required this.timeOut,
    required this.twoFaAuth,
    required this.isVerifyTwoFaAuth,
    required this.partyKycApprove,
    required this.stoneHoldDays,
    required this.isNotAllowBackDays,
    required this.notAllowBackDays,
    required this.productId,
    required this.eProduct,
    required this.isPriceWise,
    required this.isAdmin,
    required this.mailStateId,
    this.stateName,
    required this.notEditDeleteDays,
  });

  final int userId;
  final String fullName;
  final String loginName;
  final String branchName;
  final int branchId;
  final int departmentId;
  final String departmentName;
  final int locationId;
  final int defaultStockLocationId;
  final String location;
  final int baseCurrency;
  final int currencyDecimal;
  final int yearId;
  final String yearName;
  final String loginToken;
  final String companyName;
  final bool isShowAllLedger;
  final int roleId;
  final String fromYear;
  final String toYear;
  final String lang;
  final int stockCurrencyId;
  final String currencyName;
  final String branchIds;
  final String departmentIds;
  final String enableNotificationAlert;
  final int mfgDeptId;
  final bool isSuperAdmin;
  final String idealTime;
  final int mixCurrencyDecimal;
  final int roughCurrencyDecimal;
  final int certifiedCaratDecimal;
  final int mixCertifiedCaratDecimal;
  final int roughCertifiedCaratDecimal;
  final int timeOut;
  final bool twoFaAuth;
  final bool isVerifyTwoFaAuth;
  final bool partyKycApprove;
  final int stoneHoldDays;
  final bool isNotAllowBackDays;
  final int notAllowBackDays;
  final String productId;
  final bool eProduct;
  final bool isPriceWise;
  final bool isAdmin;
  final int mailStateId;
  final String? stateName;
  final int notEditDeleteDays;

  factory LoginUser.fromJson(Map<String, dynamic> json) {
    return LoginUser(
      userId: _asInt(json['UserID']),
      fullName: json['Full_Name']?.toString() ?? '',
      loginName: json['Login_Name']?.toString() ?? '',
      branchName: json['Branch_Name']?.toString() ?? '',
      branchId: _asInt(json['Branch_Id']),
      departmentId: _asInt(json['Department_ID']),
      departmentName: json['Department_Name']?.toString() ?? '',
      locationId: _asInt(json['Location_ID']),
      defaultStockLocationId: _asInt(json['DefaultStockLocationID']),
      location: json['Loaction']?.toString() ?? '',
      baseCurrency: _asInt(json['Base_Currency']),
      currencyDecimal: _asInt(json['Currency_Decimal']),
      yearId: _asInt(json['YearID']),
      yearName: json['YearName']?.toString() ?? '',
      loginToken: json['LoginToken']?.toString() ?? '',
      companyName: json['Company_Name']?.toString() ?? '',
      isShowAllLedger: _asBool(json['Is_show_all_Ledger']),
      roleId: _asInt(json['Role_ID']),
      fromYear: json['FromYear']?.toString() ?? '',
      toYear: json['ToYear']?.toString() ?? '',
      lang: json['lang']?.toString() ?? '',
      stockCurrencyId: _asInt(json['Stock_Currency_ID']),
      currencyName: json['Currency_Name']?.toString() ?? '',
      branchIds: json['BranchIDs']?.toString() ?? '',
      departmentIds: json['Department_IDs']?.toString() ?? '',
      enableNotificationAlert: json['Enable_Notifcation_Alert']?.toString() ?? '',
      mfgDeptId: _asInt(json['MFG_Dept_ID']),
      isSuperAdmin: _asBool(json['Is_SuperAdmin']),
      idealTime: json['IdealTime']?.toString() ?? '',
      mixCurrencyDecimal: _asInt(json['Mix_Currency_Decimal']),
      roughCurrencyDecimal: _asInt(json['Rough_Currency_Decimal']),
      certifiedCaratDecimal: _asInt(json['Certified_Carat_Decimal']),
      mixCertifiedCaratDecimal: _asInt(json['Mix_Certified_Carat_Decimal']),
      roughCertifiedCaratDecimal: _asInt(json['Rough_Certified_Carat_Decimal']),
      timeOut: _asInt(json['Time_Out']),
      twoFaAuth: _asBool(json['TwoFA_Auth']),
      isVerifyTwoFaAuth: _asBool(json['Is_VerifyTwoFA_Auth']),
      partyKycApprove: _asBool(json['PartyKYC_Approve']),
      stoneHoldDays: _asInt(json['StoneHoldDays']),
      isNotAllowBackDays: _asBool(json['Is_Not_Allow_BackDays']),
      notAllowBackDays: _asInt(json['Not_Allow_Back_Days']),
      productId: json['Product_ID']?.toString() ?? '',
      eProduct: _asBool(json['E_Product']),
      isPriceWise: _asBool(json['Is_PriceWise']),
      isAdmin: _asBool(json['Is_Admin']),
      mailStateId: _asInt(json['Mail_State_Id']),
      stateName: _asNullableString(json['State_Name']),
      notEditDeleteDays: _asInt(json['Not_Edit_Delete_Days']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'UserID': userId,
      'Full_Name': fullName,
      'Login_Name': loginName,
      'Branch_Name': branchName,
      'Branch_Id': branchId,
      'Department_ID': departmentId,
      'Department_Name': departmentName,
      'Location_ID': locationId,
      'DefaultStockLocationID': defaultStockLocationId,
      'Loaction': location,
      'Base_Currency': baseCurrency,
      'Currency_Decimal': currencyDecimal,
      'YearID': yearId,
      'YearName': yearName,
      'LoginToken': loginToken,
      'Company_Name': companyName,
      'Is_show_all_Ledger': isShowAllLedger,
      'Role_ID': roleId,
      'FromYear': fromYear,
      'ToYear': toYear,
      'lang': lang,
      'Stock_Currency_ID': stockCurrencyId,
      'Currency_Name': currencyName,
      'BranchIDs': branchIds,
      'Department_IDs': departmentIds,
      'Enable_Notifcation_Alert': enableNotificationAlert,
      'MFG_Dept_ID': mfgDeptId,
      'Is_SuperAdmin': isSuperAdmin,
      'IdealTime': idealTime,
      'Mix_Currency_Decimal': mixCurrencyDecimal,
      'Rough_Currency_Decimal': roughCurrencyDecimal,
      'Certified_Carat_Decimal': certifiedCaratDecimal,
      'Mix_Certified_Carat_Decimal': mixCertifiedCaratDecimal,
      'Rough_Certified_Carat_Decimal': roughCertifiedCaratDecimal,
      'Time_Out': timeOut,
      'TwoFA_Auth': twoFaAuth,
      'Is_VerifyTwoFA_Auth': isVerifyTwoFaAuth,
      'PartyKYC_Approve': partyKycApprove,
      'StoneHoldDays': stoneHoldDays,
      'Is_Not_Allow_BackDays': isNotAllowBackDays,
      'Not_Allow_Back_Days': notAllowBackDays,
      'Product_ID': productId,
      'E_Product': eProduct,
      'Is_PriceWise': isPriceWise,
      'Is_Admin': isAdmin,
      'Mail_State_Id': mailStateId,
      'State_Name': stateName,
      'Not_Edit_Delete_Days': notEditDeleteDays,
    };
  }
}

class LoginDepartment {
  const LoginDepartment({
    required this.departmentId,
    required this.deptCode,
    required this.departmentName,
    required this.isDefault,
    required this.branchId,
    required this.branchName,
    required this.mfgDeptId,
  });

  final int departmentId;
  final String deptCode;
  final String departmentName;
  final bool isDefault;
  final int branchId;
  final String branchName;
  final int mfgDeptId;

  factory LoginDepartment.fromJson(Map<String, dynamic> json) {
    return LoginDepartment(
      departmentId: _asInt(json['Department_ID']),
      deptCode: json['Dept_Code']?.toString() ?? '',
      departmentName: json['Department_Name']?.toString() ?? '',
      isDefault: _asBool(json['Is_Default']),
      branchId: _asInt(json['Branch_ID']),
      branchName: json['BranchName']?.toString() ?? '',
      mfgDeptId: _asInt(json['MFG_Dept_ID']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Department_ID': departmentId,
      'Dept_Code': deptCode,
      'Department_Name': departmentName,
      'Is_Default': isDefault,
      'Branch_ID': branchId,
      'BranchName': branchName,
      'MFG_Dept_ID': mfgDeptId,
    };
  }
}

class LoginYear {
  const LoginYear({
    required this.id,
    required this.fromDate,
    required this.toDate,
    required this.yearName,
    required this.pixel,
    required this.isDef,
    this.remark,
    required this.isActive,
  });

  final int id;
  final String fromDate;
  final String toDate;
  final String yearName;
  final String pixel;
  final bool isDef;
  final String? remark;
  final bool isActive;

  factory LoginYear.fromJson(Map<String, dynamic> json) {
    return LoginYear(
      id: _asInt(json['ID']),
      fromDate: json['From_Date']?.toString() ?? '',
      toDate: json['To_Date']?.toString() ?? '',
      yearName: json['YearName']?.toString() ?? '',
      pixel: json['Pixel']?.toString() ?? '',
      isDef: _asBool(json['Is_Def']),
      remark: _asNullableString(json['Remark']),
      isActive: _asBool(json['IsActive']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'From_Date': fromDate,
      'To_Date': toDate,
      'YearName': yearName,
      'Pixel': pixel,
      'Is_Def': isDef,
      'Remark': remark,
      'IsActive': isActive,
    };
  }
}

class LoginNotification {
  const LoginNotification({
    required this.notificationId,
    required this.title,
    required this.title2,
    required this.description,
    required this.description2,
    required this.actionBy,
    required this.notifyTime,
    required this.formActionId,
    required this.formCode,
  });

  final int notificationId;
  final String title;
  final String title2;
  final String description;
  final String description2;
  final String actionBy;
  final String notifyTime;
  final int formActionId;
  final String formCode;

  factory LoginNotification.fromJson(Map<String, dynamic> json) {
    return LoginNotification(
      notificationId: _asInt(json['Notification_ID']),
      title: json['Title']?.toString() ?? '',
      title2: json['Title_2']?.toString() ?? '',
      description: json['Description']?.toString() ?? '',
      description2: json['Description_2']?.toString() ?? '',
      actionBy: json['ActionBy']?.toString() ?? '',
      notifyTime: json['NotifyTime']?.toString() ?? '',
      formActionId: _asInt(json['Form_Action_ID']),
      formCode: json['Form_Code']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Notification_ID': notificationId,
      'Title': title,
      'Title_2': title2,
      'Description': description,
      'Description_2': description2,
      'ActionBy': actionBy,
      'NotifyTime': notifyTime,
      'Form_Action_ID': formActionId,
      'Form_Code': formCode,
    };
  }
}

class CurrencyCalculationFlag {
  const CurrencyCalculationFlag({
    required this.transId,
    required this.mCurrencyId,
    required this.toCurrencyId,
    required this.convertRate,
    required this.convertFlag,
    required this.isTemp,
  });

  final int transId;
  final int mCurrencyId;
  final int toCurrencyId;
  final double convertRate;
  final String convertFlag;
  final bool isTemp;

  factory CurrencyCalculationFlag.fromJson(Map<String, dynamic> json) {
    return CurrencyCalculationFlag(
      transId: _asInt(json['Trans_Id']),
      mCurrencyId: _asInt(json['MCurrency_Id']),
      toCurrencyId: _asInt(json['ToCurrency_Id']),
      convertRate: _asDouble(json['Convert_Rate']),
      convertFlag: json['Convert_Flag']?.toString() ?? '',
      isTemp: _asBool(json['Is_Temp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Trans_Id': transId,
      'MCurrency_Id': mCurrencyId,
      'ToCurrency_Id': toCurrencyId,
      'Convert_Rate': convertRate,
      'Convert_Flag': convertFlag,
      'Is_Temp': isTemp,
    };
  }
}

class BranchCurrencyRoundOff {
  const BranchCurrencyRoundOff({
    required this.ledgerId,
    required this.currencyRoundOff,
  });

  final int ledgerId;
  final bool currencyRoundOff;

  factory BranchCurrencyRoundOff.fromJson(Map<String, dynamic> json) {
    return BranchCurrencyRoundOff(
      ledgerId: _asInt(json['Ledger_Id']),
      currencyRoundOff: _asBool(json['Currency_Round_Off']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Ledger_Id': ledgerId,
      'Currency_Round_Off': currencyRoundOff,
    };
  }
}

class RfidDevice {
  const RfidDevice({
    required this.rfidId,
    required this.deviceName,
    required this.clientId,
    required this.machineIp,
    required this.make,
    required this.portNumber,
    required this.branchId,
    this.rfidDeviceType,
    required this.isContinousMode,
    required this.bluetoothClear,
  });

  final int rfidId;
  final String deviceName;
  final String clientId;
  final String machineIp;
  final String make;
  final int portNumber;
  final int branchId;
  final String? rfidDeviceType;
  final bool isContinousMode;
  final bool bluetoothClear;

  factory RfidDevice.fromJson(Map<String, dynamic> json) {
    return RfidDevice(
      rfidId: _asInt(json['RFID_ID']),
      deviceName: json['Device_Name']?.toString() ?? '',
      clientId: json['ClientID']?.toString() ?? '',
      machineIp: json['Machine_IP']?.toString() ?? '',
      make: json['Make']?.toString() ?? '',
      portNumber: _asInt(json['Port_Number']),
      branchId: _asInt(json['Branch_ID']),
      rfidDeviceType: _asNullableString(json['RFID_DeviceType']),
      isContinousMode: _asBool(json['IsContinousMode']),
      bluetoothClear: _asBool(json['BluetoothClear']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'RFID_ID': rfidId,
      'Device_Name': deviceName,
      'ClientID': clientId,
      'Machine_IP': machineIp,
      'Make': make,
      'Port_Number': portNumber,
      'Branch_ID': branchId,
      'RFID_DeviceType': rfidDeviceType,
      'IsContinousMode': isContinousMode,
      'BluetoothClear': bluetoothClear,
    };
  }
}

List<T> _mapList<T>(
  dynamic raw,
  T Function(Map<String, dynamic> json) mapper,
) {
  if (raw is! List) return <T>[];
  final items = <T>[];
  for (final item in raw) {
    if (item is Map<String, dynamic>) {
      items.add(mapper(item));
    } else if (item is Map) {
      items.add(mapper(Map<String, dynamic>.from(item)));
    }
  }
  return items;
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
