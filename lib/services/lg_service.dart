import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';

import '../helpers/lg_connection_shared_pref.dart';

class LiquidGalaxySSHService extends ChangeNotifier {
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

  Future<String?> connect({
    required String host,
    required String username,
    required String password,
    int port = 22,
    int rigCount = 3,
  }) async {
    try {
      print(' Establishing SSH Connection to Liquid Galaxy...');
      print('   Host: "$host:$port"');
      print('   Username: "$username"');
      print('   Password: "${password.length} characters"');
      print('   Rigs: $rigCount');

      // Store connection details first
      _host = host;
      _username = username;
      _password = password;
      _port = port;
      _rigCount = rigCount;

      // Dispose previous client if exists
      if (_client != null) {
        _client!.close();
        _client = null;
      }

      print('Creating SSH socket...');
      final socket = await SSHSocket.connect(host, port,
          timeout: const Duration(seconds: 30));
      print(' Socket created successfully');

      print(' Creating SSH client with password auth...');

      _client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () {
          print(' Password requested - providing credentials');
          return password;
        },
        identities: [], // Force password auth only
      );
      print(' SSH client created');

      // Using same timing as testConnection
      print(' Waiting for authentication...');
      await Future.delayed(const Duration(seconds: 10));
      print(' Authentication wait completed');

      print(' Testing connection with whoami...');
      final session = await _client!.execute('whoami');

      // Use EXACT same stream handling as testConnection
      final bytes = <int>[];
      await for (final chunk in session.stdout) {
        if (chunk is List<int>) {
          bytes.addAll(chunk);
        }
      }

      final result = utf8.decode(bytes);
      print(' Command result: "${result.trim()}"');
      print(' Expected result: "$username"');

      if (result.trim() == username) {
        _isConnected = true;
        print(' SSH Connection established successfully');
        await _saveConnectionPreferences();
        notifyListeners();
        return null; // Success
      } else {
        throw Exception('Authentication verification failed - got: "${result.trim()}", expected: "$username"');
      }
    } catch (e, stackTrace) {
      print(' SSH Connection failed: $e');
      print(' Stack trace: $stackTrace');
      _isConnected = false;

      // Cleanup on failure
      if (_client != null) {
        _client!.close();
        _client = null;
      }

      notifyListeners();
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

  /// Execute SSH command
  Future<String?> executeCommand(String command) async {
    if (!_isConnected || _client == null) {
      print(' Not connected to SSH server');
      return null;
    }

    try {
      print('⚡ Executing: $command');
      final session = await _client!.execute(command);

      // FIXED: Properly collect bytes from stdout stream
      final bytes = <int>[];
      await for (final chunk in session.stdout) {
        if (chunk is List<int>) {
          bytes.addAll(chunk);
        }
      }

      final result = utf8.decode(bytes);
      print(' Command executed successfully');
      return result;
    } catch (e) {
      print(' Command execution failed: $e');
      return null;
    }
  }

  /// Upload KML file to Liquid Galaxy
  Future<bool> uploadKMLFile(String kmlContent, String fileName) async {
    if (!_isConnected) {
      print(' Not connected to Liquid Galaxy');
      return false;
    }

    try {
      print(' Uploading KML file to Liquid Galaxy...');
      print('   File: $fileName.kml');
      print('   Size: ${kmlContent.length} characters');

      await _createKMLDirectory();

      final kmlPath = '/var/www/html/kmls/$fileName.kml';
      print(' KML Path: $kmlPath');

      final escapedContent = kmlContent.replaceAll("'", "'\"'\"'"); // Escape single quotes
      final writeCommand = '''cat > $kmlPath << 'EOF'
$kmlContent
EOF''';

      print(' Writing KML file...');
      final writeResult = await executeCommand(writeCommand);
      if (writeResult == null) {
        throw Exception('Failed to write KML file');
      }

      print('Setting file permissions...');
      await executeCommand('chmod 644 $kmlPath');

      print(' Verifying file creation...');
      final verifyResult = await executeCommand('ls -la $kmlPath');
      if (verifyResult == null || !verifyResult.contains(fileName)) {
        throw Exception('KML file was not created successfully');
      }
      print(' File verified: ${verifyResult.trim()}');

      await _sendKMLToGoogleEarth(fileName);

      if (_rigCount != null && _rigCount! > 1) {
        await _syncKMLToAllRigs(fileName);
      }

      print(' KML upload completed successfully');
      return true;
    } catch (e) {
      print(' KML upload failed: $e');
      return false;
    }
  }

  /// Create KML directory if it doesn't exist
  Future<void> _createKMLDirectory() async {
    try {
      print(' Creating KML directory...');
      await executeCommand('mkdir -p /var/www/html/kmls/');
      await executeCommand('chmod 755 /var/www/html/kmls/');
      print(' KML directory ready');
    } catch (e) {
      print(' Could not create KML directory: $e');
    }
  }

  /// Send KML to Google Earth
  Future<void> _sendKMLToGoogleEarth(String fileName) async {
    try {
      print(' Sending KML to Google Earth...');

      // Use correct LG query format (relative path from /var/www/html/)
      final queryCommand = 'echo "kmls/$fileName.kml" > /tmp/query.txt';
      await executeCommand(queryCommand);

      // Verify query file was created
      final verifyQuery = await executeCommand('cat /tmp/query.txt');
      print(' Query file content: ${verifyQuery?.trim()}');

      // Optional: Force Google Earth to refresh (if needed)
      await executeCommand('pkill -USR1 google-earth 2>/dev/null || true');

      print(' KML sent to Google Earth');
    } catch (e) {
      print(' Failed to send KML to Google Earth: $e');
    }
  }

  /// UNIVERSAL sync KML to all rigs - works with any screen count
  Future<void> _syncKMLToAllRigs(String fileName) async {
    if (_rigCount == null || _rigCount! <= 1) return;

    try {
      print(' Syncing KML to ${_rigCount! - 1} additional rigs...');

      // First, try to discover actual rig IPs
      final rigIPs = await _discoverRigIPs();

      if (rigIPs.isNotEmpty && rigIPs.length > 1) {
        // Use discovered IPs
        for (int i = 1; i < rigIPs.length; i++) {
          final rigIP = rigIPs[i];
          print(' Syncing to discovered rig ${i + 1} ($rigIP)...');

          // Copy KML file to slave rig
          final syncCommand = 'scp -o ConnectTimeout=5 /var/www/html/kmls/$fileName.kml lg@$rigIP:/var/www/html/kmls/ 2>/dev/null || true';
          await executeCommand(syncCommand);

          // Send query to slave rig
          final queryCommand = 'ssh -o ConnectTimeout=5 lg@$rigIP "echo \\"kmls/$fileName.kml\\" > /tmp/query.txt" 2>/dev/null || true';
          await executeCommand(queryCommand);

          print(' Synced to rig ${i + 1} ($rigIP)');
        }
      } else {
        // Fallback to calculated IPs using multiple patterns
        await _syncUsingCalculatedIPs(fileName);
      }

      print(' KML synced to all $_rigCount rigs');
    } catch (e) {
      print(' Rig sync failed: $e');
    }
  }


  Future<List<String>> _discoverRigIPs() async {
    try {

      final hostsResult = await executeCommand('cat /etc/hosts | grep lg');
      final rigIPs = <String>[];

      if (hostsResult != null) {
        final lines = hostsResult.split('\n');
        for (String line in lines) {
          if (line.contains('lg') && !line.startsWith('#')) {
            final parts = line.split(RegExp(r'\s+'));
            if (parts.isNotEmpty && parts[0].contains('.')) {
              rigIPs.add(parts[0]);
            }
          }
        }
      }

      // If no hosts file configuration, try discovering via network scan
      if (rigIPs.isEmpty) {
        rigIPs.addAll(await _networkDiscoverRigs());
      }

      print(' Discovered rig IPs for sync: $rigIPs');
      return rigIPs;
    } catch (e) {
      print(' Could not discover rig IPs: $e');
      return [];
    }
  }

  /// Network-based rig discovery for KML sync
  Future<List<String>> _networkDiscoverRigs() async {
    try {
      final baseIP = _getBaseIP();
      final rigIPs = <String>[];

      // Add master IP
      rigIPs.add(_host!);

      // Try common LG IP patterns
      final patterns = [
        // Sequential pattern: .100, .101, .102, etc.
            () => List.generate(_rigCount! - 1, (i) => '$baseIP${_getLastOctet() + i + 1}'),
        // Offset pattern: .42, .43, .44, etc.
            () => List.generate(_rigCount! - 1, (i) => '$baseIP${42 + i}'),
        // Standard LG pattern: .43, .44, .45 (if master is .42)
            () => List.generate(_rigCount! - 1, (i) => '$baseIP${_getLastOctet() + i + 1}'),
      ];

      for (var pattern in patterns) {
        final candidates = pattern();
        bool foundValidPattern = false;

        for (String ip in candidates) {
          if (ip == _host) continue; // Skip master

          final pingResult = await executeCommand('ping -c 1 -W 1 $ip 2>/dev/null');
          if (pingResult != null && pingResult.contains('1 received')) {
            // Quick SSH test to verify it's an LG rig
            final sshTest = await executeCommand('ssh -o ConnectTimeout=2 lg@$ip "echo ok" 2>/dev/null');
            if (sshTest != null && sshTest.contains('ok')) {
              rigIPs.add(ip);
              foundValidPattern = true;
            }
          }
        }

        if (foundValidPattern && rigIPs.length > 1) {
          print(' Found valid IP pattern: ${rigIPs.join(', ')}');
          break;
        } else {
          rigIPs.clear();
          rigIPs.add(_host!); // Reset to master only
        }
      }

      return rigIPs;
    } catch (e) {
      print('Network discovery failed: $e');
      return [_host!]; // Return at least master IP
    }
  }

  /// Fallback sync using calculated IPs
  Future<void> _syncUsingCalculatedIPs(String fileName) async {
    final baseIP = _getBaseIP();
    final masterLastOctet = _getLastOctet();

    // Try multiple IP calculation methods
    final ipPatterns = [
      // Pattern 1: Sequential (most common)
          () => List.generate(_rigCount! - 1, (i) => '$baseIP${masterLastOctet + i + 1}'),
      // Pattern 2: Traditional LG offset
          () => List.generate(_rigCount! - 1, (i) => '$baseIP${42 + i + 1}'),
      // Pattern 3: Round numbers
          () => List.generate(_rigCount! - 1, (i) => '$baseIP${masterLastOctet + (i + 1) * 10}'),
    ];

    for (var pattern in ipPatterns) {
      final slaveIPs = pattern();
      bool foundValidPattern = false;

      for (int i = 0; i < slaveIPs.length; i++) {
        final rigIP = slaveIPs[i];

        // Test connectivity first
        final pingResult = await executeCommand('ping -c 1 -W 1 $rigIP 2>/dev/null');

        if (pingResult != null && pingResult.contains('1 received')) {
          foundValidPattern = true;
          print(' Syncing to calculated rig ${i + 2} ($rigIP)...');

          // Copy KML file
          final syncCommand = 'scp -o ConnectTimeout=5 /var/www/html/kmls/$fileName.kml lg@$rigIP:/var/www/html/kmls/ 2>/dev/null || true';
          await executeCommand(syncCommand);

          // Send query
          final queryCommand = 'ssh -o ConnectTimeout=5 lg@$rigIP "echo \\"kmls/$fileName.kml\\" > /tmp/query.txt" 2>/dev/null || true';
          await executeCommand(queryCommand);

          print(' Synced to rig ${i + 2} ($rigIP)');
        }
      }

      if (foundValidPattern) {
        print(' Used calculated IP pattern: ${slaveIPs.join(', ')}');
        break;
      }
    }
  }

  /// Get base IP (everything except last octet)
  String _getBaseIP() {
    final host = _host ?? '192.168.1.100';
    final lastDot = host.lastIndexOf('.');
    return host.substring(0, lastDot + 1);
  }

  /// Get last octet of master IP
  int _getLastOctet() {
    final host = _host ?? '192.168.1.100';
    final lastDot = host.lastIndexOf('.');
    return int.tryParse(host.substring(lastDot + 1)) ?? 100;
  }

  /// Clear Google Earth display - UNIVERSAL VERSION
  Future<bool> clearGoogleEarth() async {
    if (!_isConnected) {
      print(' Not connected to Liquid Galaxy');
      return false;
    }

    try {
      print(' Clearing Google Earth display...');

      // Clear query file
      await executeCommand('echo "" > /tmp/query.txt');

      // Remove KML files from correct directory
      await executeCommand('rm -f /var/www/html/kmls/disaster_*.kml');
      await executeCommand('rm -f /var/www/html/disaster_*.kml'); // Legacy cleanup

      // Clear old files
      await executeCommand('rm -f /var/www/html/flyto.kml');
      await executeCommand('rm -f /var/www/html/kmls/flyto.kml');

      // Force Google Earth refresh
      await executeCommand('pkill -USR1 google-earth 2>/dev/null || true');

      print(' Google Earth cleared');
      return true;
    } catch (e) {
      print(' Failed to clear Google Earth: $e');
      return false;
    }
  }

  /// Test connection without full connection - UNIVERSAL VERSION
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
      print('   Port: $port');

      final socket = await SSHSocket.connect(host, port,
          timeout: const Duration(seconds: 30));
      print(' Socket connected successfully');

      testClient = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () {
          print(' Password requested - providing credentials');
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

  /// Disconnect from SSH
  Future<void> disconnect() async {
    try {
      if (_client != null) {
        _client!.close();
        print(' SSH connection closed');
      }
      _isConnected = false;
      _client = null;
      notifyListeners();
    } catch (e) {
      print(' Error during disconnect: $e');
    }
  }
}
