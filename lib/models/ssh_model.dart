import '../helpers/lg_connection_shared_pref.dart';

class SSHModel {
  String host;
  int port;
  String username;
  String passwordOrKey;
  int screenAmount;

  SSHModel({
    required this.host,
    required this.port,
    required this.username,
    required this.passwordOrKey,
    required this.screenAmount,
  });


  factory SSHModel.fromPreferences() {
    return SSHModel(
      host: LgConnectionSharedPref.getIP() ?? '192.168.1.42',
      port: int.tryParse(LgConnectionSharedPref.getPort() ?? '22') ?? 22,
      username: LgConnectionSharedPref.getUserName() ?? 'lg',
      passwordOrKey: LgConnectionSharedPref.getPassword() ?? 'lqgalaxy',
      screenAmount: LgConnectionSharedPref.getScreenAmount() ?? 3,
    );
  }

  /// Save SSH model to preferences
  Future<void> saveToPreferences() async {
    await LgConnectionSharedPref.setIP(host);
    await LgConnectionSharedPref.setPort(port.toString());
    await LgConnectionSharedPref.setUserName(username);
    await LgConnectionSharedPref.setPassword(passwordOrKey);
    await LgConnectionSharedPref.setScreenAmount(screenAmount);
  }

  /// Check if the model has valid connection info
  bool isValid() {
    return host.isNotEmpty &&
        username.isNotEmpty &&
        passwordOrKey.isNotEmpty &&
        port > 0 &&
        screenAmount > 0;
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'host': host,
      'port': port,
      'username': username,
      'passwordOrKey': passwordOrKey,
      'screenAmount': screenAmount,
    };
  }

  /// Create from map
  factory SSHModel.fromMap(Map<String, dynamic> map) {
    return SSHModel(
      host: map['host'] ?? '192.168.1.42',
      port: map['port'] ?? 22,
      username: map['username'] ?? 'lg',
      passwordOrKey: map['passwordOrKey'] ?? 'lqgalaxy',
      screenAmount: map['screenAmount'] ?? 3,
    );
  }

  @override
  String toString() {
    return 'SSHModel(host: $host, port: $port, username: $username, screens: $screenAmount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SSHModel &&
        other.host == host &&
        other.port == port &&
        other.username == username &&
        other.passwordOrKey == passwordOrKey &&
        other.screenAmount == screenAmount;
  }

  @override
  int get hashCode {
    return host.hashCode ^
    port.hashCode ^
    username.hashCode ^
    passwordOrKey.hashCode ^
    screenAmount.hashCode;
  }
}
