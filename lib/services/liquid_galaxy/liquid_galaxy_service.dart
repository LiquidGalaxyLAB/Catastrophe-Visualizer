import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
//import 'package:catastrophe_visualizer/services/helpers/lg_connection_shared_pref.dart';

import '../../helpers/lg_connection_shared_pref.dart';

class LiquidGalaxySSHService {
  // SSH Connection Properties
  String? _host;
  String? _username;
  String? _password;
  int? _port;
  int? _rigCount;
  SSHClient? _client;
  bool _isConnected = false;

  // Getters
  bool get isConnected => _isConnected;
  String? get host => _host;
  String? get username => _username;
  int? get rigCount => _rigCount;
  SSHClient? get client => _client;

  /// Initialize connection with stored preferences
  Future<String?> initializeFromPreferences() async {
    final host = LgConnectionSharedPref.getIP();
    final username = LgConnectionSharedPref.getUserName();
    final password = LgConnectionSharedPref.getPassword();
    final port = int.tryParse(LgConnectionSharedPref.getPort() ?? '22') ?? 22;
    final rigCount = LgConnectionSharedPref.getScreenAmount() ?? 3;

    if (host != null && username != null && password != null) {
      return await connect(
        host: host,
        username: username,
        password: password,
        port: port,
        rigCount: rigCount,
      );
    }
    return 'No saved connection preferences found';
  }

  /// Establish SSH connection to Liquid Galaxy - ENHANCED DEBUG VERSION
  Future<String?> connect({
    required String host,
    required String username,
    required String password,
    int port = 22,
    int rigCount = 3,
  }) async {
    try {
      print('🔗 Establishing SSH Connection to Liquid Galaxy...');
      print('   Host: "$host:$port"');
      print('   Username: "$username"');
      print('   Password: "${password.length} characters"');
      print('   Password: "$password"');
      print('   Rigs: $rigCount');

      // Store connection details
      _host = host;
      _username = username;
      _password = password;
      _port = port;
      _rigCount = rigCount;

      print(' Creating SSH socket...');
      // Create SSH socket
      final socket = await SSHSocket.connect(host, port,
          timeout: const Duration(seconds: 60));
      print(' Socket created successfully');

      print(' Creating SSH client...');
      // Create SSH client with ONLY password authentication
      _client = SSHClient(
        socket,
        username: username,
        printDebug: ( e){ print (e);},
        onPasswordRequest: () {
          print(' Password requested for user: $username');
          print(' Providing password: "$password"');
          return password;
        },
        // keepAliveInterval: const Duration(seconds: 30),
        // Force password auth only
      );

      print(' SSH client created');

      // Wait for authentication
      print(' Authenticating with password...');
      await Future.delayed(const Duration(seconds: 12)); // Increased wait time
      print(' Authentication wait completed');

      print(' Testing connection with whoami command...');
      // Test connection with whoami command
      final testResult = await executeCommand('whoami');
      print(' Test command result: "$testResult"');
      print(' Expected result: "$username"');

      if (testResult != null && testResult.trim() == username) {
        _isConnected = true;
        print(' SSH Connection established with password authentication');
        await _saveConnectionPreferences();
        return null; // Success
      } else {
        throw Exception('Password authentication test failed - got: "$testResult", expected: "$username"');
      }
    } catch (e, stackTrace) {
      print(' SSH Connection failed: $e');
      print(' Stack trace: $stackTrace');
      _isConnected = false;
      await disconnect();
      return 'SSH Connection failed: $e';
    }
  }

  /// Save connection preferences
  Future<void> _saveConnectionPreferences() async {
    if (_host != null) await LgConnectionSharedPref.setIP(_host!);
    if (_username != null) await LgConnectionSharedPref.setUserName(_username!);
    if (_password != null) await LgConnectionSharedPref.setPassword(_password!);
    if (_port != null) await LgConnectionSharedPref.setPort(_port.toString());
    if (_rigCount != null) await LgConnectionSharedPref.setScreenAmount(_rigCount!);
  }

  /// Execute SSH command - FIXED VERSION
  Future<String?> executeCommand(String command) async {
    if (!_isConnected || _client == null) {
      print(' Not connected to SSH server');
      return null;
    }

    try {
      print('  Executing: $command');
      final session = await _client!.execute(command);

      // FIXED: Properly collect bytes from stdout stream
      final bytes = <int>[];
      await for (final chunk in session.stdout) {
        if (chunk is List<int>) {
          bytes.addAll(chunk);
        }
      }

      final result = utf8.decode(bytes);
      print('    Command executed successfully');
      print('    Result: $result');
      return result;
    } catch (e) {
      print(' Command execution failed: $e');
      return null;
    }
  }

  /// Upload KML file to Liquid Galaxy - FIXED VERSION
  Future<bool> uploadKMLFile(String kmlContent, String fileName) async {
    if (!_isConnected) {
      print(' Not connected to Liquid Galaxy');
      return false;
    }

    try {
      print(' Uploading KML file to Liquid Galaxy...');
      print('   File: $fileName.kml');
      print('   Size: ${kmlContent.length} characters');

      // Create KML file path
      final kmlPath = '/var/www/html/$fileName.kml';

      // Upload KML content using SFTP
      final sftp = await _client!.sftp();
      final file = await sftp.open(
        kmlPath,
        mode: SftpFileOpenMode.create |
        SftpFileOpenMode.truncate |
        SftpFileOpenMode.write,
      );

      // FIXED: Write KML content properly
      final kmlBytes = utf8.encode(kmlContent);
      await file.write(Stream.fromIterable([kmlBytes]));
      await file.close();

      print(' KML file uploaded successfully');

      // Send KML to Google Earth
      await _sendKMLToGoogleEarth(fileName);

      // Sync to all rigs if multiple screens
      if (_rigCount != null && _rigCount! > 1) {
        await _syncKMLToAllRigs(fileName);
      }

      return true;
    } catch (e) {
      print(' KML upload failed: $e');
      return false;
    }
  }

  /// Send KML to Google Earth
  Future<void> _sendKMLToGoogleEarth(String fileName) async {
    try {
      final command = 'echo "http://localhost/$fileName.kml" > /tmp/query.txt';
      await executeCommand(command);
      print(' KML sent to Google Earth');
    } catch (e) {
      print(' Failed to send KML to Google Earth: $e');
    }
  }

  /// Sync KML to all rigs in the Liquid Galaxy setup
  Future<void> _syncKMLToAllRigs(String fileName) async {
    if (_rigCount == null || _rigCount! <= 1) return;

    try {
      print(' Syncing KML to ${_rigCount! - 1} additional rigs...');

      for (int i = 2; i <= _rigCount!; i++) {
        final rigIP = _host!.substring(0, _host!.lastIndexOf('.') + 1) + i.toString();
        final syncCommand = 'scp /var/www/html/$fileName.kml lg@$rigIP:/var/www/html/';
        await executeCommand(syncCommand);
        print(' Synced to rig $i ($rigIP)');
      }

      print(' KML synced to all $_rigCount rigs');
    } catch (e) {
      print(' Rig sync failed: $e');
    }
  }

  /// Clear Google Earth display
  Future<bool> clearGoogleEarth() async {
    if (!_isConnected) {
      print(' Not connected to Liquid Galaxy');
      return false;
    }

    try {
      print(' Clearing Google Earth display...');

      // Clear query file
      await executeCommand('echo "" > /tmp/query.txt');

      // Remove temporary KML files
      await executeCommand('rm -f /var/www/html/disaster_*.kml');

      print('Google Earth cleared');
      return true;
    } catch (e) {
      print(' Failed to clear Google Earth: $e');
      return false;
    }
  }

  /// Fly to specific coordinates
  Future<bool> flyToLocation({
    required double latitude,
    required double longitude,
    double altitude = 1000,
    double heading = 0,
    double tilt = 0,
    double range = 10000,
  }) async {
    if (!_isConnected) {
      print(' Not connected to Liquid Galaxy');
      return false;
    }

    try {
      print('  Flying to coordinates: $latitude, $longitude');

      final flyToKML = _generateFlyToKML(
          latitude, longitude, altitude, heading, tilt, range);

      return await uploadKMLFile(flyToKML, 'flyto');
    } catch (e) {
      print(' Fly to failed: $e');
      return false;
    }
  }

  /// Generate fly-to KML
  String _generateFlyToKML(
      double lat, double lng, double altitude,
      double heading, double tilt, double range) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
<Document>
  <name>Fly To Location</name>
  <LookAt>
    <longitude>$lng</longitude>
    <latitude>$lat</latitude>
    <altitude>$altitude</altitude>
    <heading>$heading</heading>
    <tilt>$tilt</tilt>
    <range>$range</range>
  </LookAt>
  <Placemark>
    <name>Target</name>
    <Point>
      <coordinates>$lng,$lat,$altitude</coordinates>
    </Point>
  </Placemark>
</Document>
</kml>''';
  }

  /// Get Google Earth status
  Future<String?> getGoogleEarthStatus() async {
    if (!_isConnected) return 'Not connected';

    try {
      final result = await executeCommand('pgrep -f google-earth');
      if (result != null && result.trim().isNotEmpty) {
        return 'Google Earth is running (PID: ${result.trim()})';
      } else {
        return 'Google Earth is not running';
      }
    } catch (e) {
      return 'Error checking status: $e';
    }
  }

  /// Restart Google Earth
  Future<bool> restartGoogleEarth() async {
    if (!_isConnected) return false;

    try {
      print(' Restarting Google Earth...');

      // Kill existing Google Earth processes
      await executeCommand('pkill -f google-earth');
      await Future.delayed(const Duration(seconds: 2));

      // Start Google Earth
      await executeCommand('DISPLAY=:0 google-earth &');
      await Future.delayed(const Duration(seconds: 5));

      print(' Google Earth restarted');
      return true;
    } catch (e) {
      print(' Failed to restart Google Earth: $e');
      return false;
    }
  }

  /// Test connection without full connection - ENHANCED DEBUG VERSION
  Future<bool> testConnection({
    required String host,
    required String username,
    required String password,
    int port = 22,
  }) async {
    SSHClient? testClient;
    try {
      print(' Testing connection with exact parameters:');
      print('   Host: "$host"');
      print('   Username: "$username"');
      print('   Password: "${password.length} characters"');
      print('   Password being used: "${password}"');
      print('   Port: $port');

      final socket = await SSHSocket.connect(host, port,
          timeout: const Duration(seconds: 30));
      print(' Socket connected successfully');

      testClient = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () {
          print(' Password requested - providing password: "$password"');
          return password;
        },
        // Force only password authentication
        identities: [], // Empty identities to prevent key auth
      );
      print(' SSH client created');

      print(' Waiting for authentication...');
      await Future.delayed(const Duration(seconds: 10)); // Increased delay
      print(' Authentication wait completed');

      print(' Executing test command...');
      final session = await testClient.execute('whoami');
      print(' Command executed');

      // FIXED: Properly handle stream output
      final bytes = <int>[];
      await for (final chunk in session.stdout) {
        if (chunk is List<int>) {
          bytes.addAll(chunk);
        }
      }

      final output = utf8.decode(bytes);
      print(' Command output: "${output.trim()}"');
      print(' Expected: "$username"');

      if (output.trim() == username) {
        print(' Test successful - output matches username');
        return true;
      } else {
        print(' Test failed - output does not match username');
        return false;
      }
    } catch (e, stackTrace) {
      print(' Test connection failed with error: $e');
      print(' Stack trace: $stackTrace');
      return false;
    } finally {
      testClient?.close();
      print(' Test client closed');
    }
  }

  /// Get connection information
  Map<String, dynamic> getConnectionInfo() {
    return {
      'isConnected': _isConnected,
      'host': _host,
      'username': _username,
      'port': _port,
      'rigCount': _rigCount,
      'hasClient': _client != null,
      'authMethod': 'password',
    };
  }

  /// Disconnect from SSH
  Future<void> disconnect() async {
    try {
      if (_client != null) {
        _client!.close();
        print(' SSH connection closed');
      }
      _isConnected = false;
      _client = null;
    } catch (e) {
      print(' Error during disconnect: $e');
    }
  }

  /// Cleanup resources
  void dispose() {
    disconnect();
  }
}
