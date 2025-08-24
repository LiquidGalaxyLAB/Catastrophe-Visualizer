import 'package:shared_preferences/shared_preferences.dart';

class LgConnectionSharedPref {
  static SharedPreferences? _prefs;

  static const String _keyIP = 'lg_ip';
  static const String _keyPort = 'lg_port';
  static const String _keyUserName = 'lg_username';
  static const String _keyPassword = 'lg_password';
  static const String _keyScreenAmount = 'lg_screen_amount';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Setters
  static Future<void> setIP(String ip) async =>
      await _prefs?.setString(_keyIP, ip);
  static Future<void> setPort(String port) async =>
      await _prefs?.setString(_keyPort, port);
  static Future<void> setUserName(String userName) async =>
      await _prefs?.setString(_keyUserName, userName);
  static Future<void> setPassword(String password) async =>
      await _prefs?.setString(_keyPassword, password);
  static Future<void> setScreenAmount(int screenAmount) async =>
      await _prefs?.setInt(_keyScreenAmount, screenAmount);

  // Getters
  static String? getIP() => _prefs?.getString(_keyIP);
  static String? getPort() => _prefs?.getString(_keyPort);
  static String? getUserName() => _prefs?.getString(_keyUserName);
  static String? getPassword() => _prefs?.getString(_keyPassword);
  static int? getScreenAmount() => _prefs?.getInt(_keyScreenAmount);
}
