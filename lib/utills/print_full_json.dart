import 'dart:convert';

/// Prints long JSON without Flutter truncating a single `print` call.
void printFullJson(String label, Object? data) {
  final text = () {
    try {
      if (data is Map || data is List) {
        return const JsonEncoder.withIndent('  ').convert(data);
      }
      return data?.toString() ?? 'null';
    } catch (_) {
      return data?.toString() ?? 'null';
    }
  }();

  print('========== $label ==========');
  const chunkSize = 800;
  for (var i = 0; i < text.length; i += chunkSize) {
    final end = i + chunkSize < text.length ? i + chunkSize : text.length;
    print(text.substring(i, end));
  }
  print('================================');
}
