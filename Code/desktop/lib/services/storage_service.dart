import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  Future<void> saveString(String key, String value) async {
    final prefs = await _prefs;
    await prefs.setString(key, value);
  }

  Future<String?> getString(String key) async {
    final prefs = await _prefs;
    return prefs.getString(key);
  }

  Future<void> remove(String key) async {
    final prefs = await _prefs;
    await prefs.remove(key);
  }
}
