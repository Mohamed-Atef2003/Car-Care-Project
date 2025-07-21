import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _isFirstTimeKey = 'isFirstTime';
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _userIdKey = 'userId';

  // Check if this is the first time using the app
  static Future<bool> isFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    // If the key doesn't exist, this means it's the first use
    return prefs.getBool(_isFirstTimeKey) ?? true;
  }

  // Update first use status
  static Future<void> setFirstTimeCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isFirstTimeKey, false);
  }
  
  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }
  
  // Login
  static Future<void> setLoggedIn(bool value, {String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, value);
    
    if (userId != null && userId.isNotEmpty) {
      await prefs.setString(_userIdKey, userId);
    }
  }
  
  // Get user ID
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }
  
  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
    // You can also delete the user ID if you want
    // await prefs.remove(_userIdKey);
  }
} 