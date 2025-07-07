
import 'package:shared_preferences/shared_preferences.dart';

/// LgConnectionSharedPref to persist LG connection data locally
class LgConnectionSharedPref {
  static SharedPreferences? _prefs;
  static const String _keyIP = 'lg_ip';
  static const String _keyPort = 'lg_port';
  static const String _keyUserName = 'lg_userName';
  static const String _keyPassword = 'lg_password';
  static const String _keyScreenAmount = 'lg_screenAmount';

  /// Initializes the SharedPreferences instance for local data storage.
  static Future init() async => _prefs = await SharedPreferences.getInstance();

  /// Sets the IP address for the LG session.
  static Future<void> setIP(String ip) async =>
      await _prefs?.setString(_keyIP, ip);

  /// Sets the port number for the LG session.
  static Future<void> setPort(String port) async =>
      await _prefs?.setString(_keyPort, port);

  /// Sets the username for the LG session.
  static Future<void> setUserName(String userName) async =>
      await _prefs?.setString(_keyUserName, userName);

  /// Sets the password for the LG session.
  static Future<void> setPassword(String pass) async =>
      await _prefs?.setString(_keyPassword, pass);

  /// Sets the screen amount for the LG session.
  static Future<void> setScreenAmount(int screenAmount) async =>
      await _prefs?.setInt(_keyScreenAmount, screenAmount);

  /// Retrieves the saved IP address from the LG session.
  static String? getIP() => _prefs?.getString(_keyIP);

  /// Retrieves the saved port number from the LG session.
  static String? getPort() => _prefs?.getString(_keyPort);

  /// Retrieves the saved username from the LG session.
  static String? getUserName() => _prefs?.getString(_keyUserName);

  /// Retrieves the saved password from the LG session.
  static String? getPassword() => _prefs?.getString(_keyPassword);

  /// Retrieves the saved screen amount from the LG session.
  static int? getScreenAmount() => _prefs?.getInt(_keyScreenAmount);

  /// Removes the saved IP address from the LG session.
  static Future<void> removeIP() async => await _prefs?.remove(_keyIP);

  /// Removes the saved port number from the LG session.
  static Future<void> removePort() async => await _prefs?.remove(_keyPort);

  /// Removes the saved username from the LG session.
  static Future<void> removeUserName() async =>
      await _prefs?.remove(_keyUserName);

  /// Removes the saved password from the LG session.
  static Future<void> removePassword() async =>
      await _prefs?.remove(_keyPassword);

  /// Removes the saved screen amount from the LG session.
  static Future<void> removeScreenAmount() async =>
      await _prefs?.remove(_keyScreenAmount);

  /// Clear all LG connection data
  static Future<void> clearAll() async {
    await removeIP();
    await removePort();
    await removeUserName();
    await removePassword();
    await removeScreenAmount();
  }
}
