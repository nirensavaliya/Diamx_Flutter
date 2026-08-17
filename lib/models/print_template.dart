class PrintTemplate {
  const PrintTemplate({
    required this.printId,
    required this.formName,
    required this.printName,
    required this.fileName,
    required this.isActive,
    required this.seqNo,
  });

  final int printId;
  final String formName;
  final String printName;
  final String fileName;
  final bool isActive;
  final int seqNo;

  factory PrintTemplate.fromJson(Map<String, dynamic> json) {
    return PrintTemplate(
      printId: _asInt(json['Print_ID']),
      formName: json['Form_Name']?.toString() ?? '',
      printName: json['Print_Name']?.toString() ?? '',
      fileName: json['File_Name']?.toString() ?? '',
      isActive: _asBool(json['IsActive']),
      seqNo: _asInt(json['SeqNo']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().toLowerCase().trim() ?? '';
    return text == 'true' || text == '1' || text == 'yes';
  }
}
