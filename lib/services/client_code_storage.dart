import 'package:shared_preferences/shared_preferences.dart';

class ClientCodeStorage {
  const ClientCodeStorage();

  static const String _clientCodeKey = 'client_code';

  Future<String?> getClientCode() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_clientCodeKey);
  }

  Future<bool> hasClientCode() async {
    final code = await getClientCode();
    return code != null && code.isNotEmpty;
  }

  Future<bool> saveClientCode(String clientCode) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.setString(_clientCodeKey, clientCode);
  }
}
