class FormCodes {
  static const String memoDelivery = 'MemoDelivery';
  static const String saleDelivery = 'SaleDelivery';
  static const String memoOfficeDelivery = 'MemoOfficeDelivery';
  static const String saleOfficeDelivery = 'SaleOfficeDelivery';
}

class FormPermissionListResponse {
  const FormPermissionListResponse({
    required this.message,
    required this.error,
    required this.permissions,
    required this.isSessionExpire,
    required this.isSuccess,
    required this.statusCode,
  });

  final String message;
  final String error;
  final List<FormPermission> permissions;
  final bool isSessionExpire;
  final bool isSuccess;
  final String statusCode;

  bool get hasError => error.trim().isNotEmpty;
  bool get isPermissionSuccess =>
      !hasError && (isSuccess || permissions.isNotEmpty);

  factory FormPermissionListResponse.fromJson(Map<String, dynamic> json) {
    final permissions = <FormPermission>[];
    final rawResult = json['Result'];
    if (rawResult is List) {
      for (final item in rawResult) {
        if (item is Map<String, dynamic>) {
          permissions.add(FormPermission.fromJson(item));
        } else if (item is Map) {
          permissions.add(FormPermission.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return FormPermissionListResponse(
      message: json['Message']?.toString() ?? '',
      error: json['Error']?.toString() ?? '',
      permissions: permissions,
      isSessionExpire: _asBool(json['IsSessionExpire']),
      isSuccess: _asBool(json['IsSuccess']),
      statusCode: json['StatusCode']?.toString() ?? '',
    );
  }
}

class FormPermission {
  const FormPermission({
    required this.userId,
    required this.groupName,
    required this.formCode,
    required this.formName,
    required this.canView,
    required this.canAdd,
    required this.canEdit,
    required this.canDelete,
    required this.canExport,
    required this.canMail,
    required this.canPrint,
  });

  final int userId;
  final String groupName;
  final String formCode;
  final String formName;
  final bool canView;
  final bool canAdd;
  final bool canEdit;
  final bool canDelete;
  final bool canExport;
  final bool canMail;
  final bool canPrint;

  factory FormPermission.fromJson(Map<String, dynamic> json) {
    return FormPermission(
      userId: _asInt(json['User_Id']),
      groupName: json['Group_Name']?.toString() ?? '',
      formCode: json['Form_Code']?.toString() ?? '',
      formName: json['Form_Name']?.toString() ?? '',
      canView: _asBool(json['Can_View']),
      canAdd: _asBool(json['Can_Add']),
      canEdit: _asBool(json['Can_Edit']),
      canDelete: _asBool(json['Can_Delete']),
      canExport: _asBool(json['Can_Export']),
      canMail: _asBool(json['Can_Mail']),
      canPrint: _asBool(json['Can_Print']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'User_Id': userId,
      'Group_Name': groupName,
      'Form_Code': formCode,
      'Form_Name': formName,
      'Can_View': canView,
      'Can_Add': canAdd,
      'Can_Edit': canEdit,
      'Can_Delete': canDelete,
      'Can_Export': canExport,
      'Can_Mail': canMail,
      'Can_Print': canPrint,
    };
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().trim().toLowerCase() ?? '';
  return text == 'true' || text == '1' || text == 'yes';
}
