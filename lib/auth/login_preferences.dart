import 'package:shared_preferences/shared_preferences.dart';

class RescuerLoginPreferences {
  static const _keyUsername = 'rescuer_username';
  static const _keyPassword = 'rescuer_password';
  static const _keyRememberMe = 'rescuer_rememberMe';

  static Future<void> saveLoginState(String username, String password, bool rememberMe) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyPassword, password);
    await prefs.setBool(_keyRememberMe, rememberMe);
  }

  static Future<Map<String, dynamic>?> getLoginState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool rememberMe = prefs.getBool(_keyRememberMe) ?? false;

    if (rememberMe) {
      String? username = prefs.getString(_keyUsername);
      String? password = prefs.getString(_keyPassword);
      if (username != null && password != null) {
        return {'Username': username, 'Password': password};
      }
    }
    return null;
  }

  static Future<void> clearLoginState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyPassword);
    await prefs.remove(_keyRememberMe);
  }
}