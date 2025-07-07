import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../services/liquid_galaxy/liquid_galaxy_service.dart';
import '../services/enhanced_kml_service.dart';
import '../models/disaster_event.dart';
import '../helpers/lg_connection_shared_pref.dart';

class LiquidGalaxyProvider with ChangeNotifier {
  final LiquidGalaxySSHService _sshService = LiquidGalaxySSHService();

  // Connection state
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _connectionError;
  String? _lastConnectionStatus;

  // Connection details
  String? _currentHost;
  String? _currentUsername;
  int? _currentPort;
  int? _rigCount;

  // KML operation state
  bool _isUploadingKML = false;
  String? _lastUploadedKML;
  DateTime? _lastKMLUploadTime;
  String? _kmlUploadError;

  // Auto-sync settings
  bool _autoSyncEnabled = false;
  Timer? _autoSyncTimer;
  Duration _autoSyncInterval = const Duration(minutes: 5);

  // Statistics
  int _totalKMLUploads = 0;
  int _successfulUploads = 0;
  int _failedUploads = 0;

  // Getters
  bool get isConnected => _isConnected;

  bool get isConnecting => _isConnecting;

  String? get connectionError => _connectionError;

  String? get lastConnectionStatus => _lastConnectionStatus;

  String? get currentHost => _currentHost;

  String? get currentUsername => _currentUsername;

  int? get currentPort => _currentPort;

  int? get rigCount => _rigCount;

  bool get isUploadingKML => _isUploadingKML;

  String? get lastUploadedKML => _lastUploadedKML;

  DateTime? get lastKMLUploadTime => _lastKMLUploadTime;

  String? get kmlUploadError => _kmlUploadError;

  bool get autoSyncEnabled => _autoSyncEnabled;

  Duration get autoSyncInterval => _autoSyncInterval;

  int get totalKMLUploads => _totalKMLUploads;

  int get successfulUploads => _successfulUploads;

  int get failedUploads => _failedUploads;

  double get uploadSuccessRate =>
      _totalKMLUploads > 0 ? (_successfulUploads / _totalKMLUploads) * 100 : 0;

  /// Initialize provider and attempt auto-connection
  Future<void> initialize() async {
    await LgConnectionSharedPref.init();
    await _attemptAutoConnection();
  }

  /// Attempt automatic connection using saved preferences
  Future<void> _attemptAutoConnection() async {
    final savedHost = LgConnectionSharedPref.getIP();
    final savedUsername = LgConnectionSharedPref.getUserName();
    final savedPassword = LgConnectionSharedPref.getPassword();

    if (savedHost != null && savedUsername != null && savedPassword != null) {
      print(' Attempting auto-connection to saved Liquid Galaxy...');
      await connectToLiquidGalaxy(
        host: savedHost,
        username: savedUsername,
        password: savedPassword,
        port: int.tryParse(LgConnectionSharedPref.getPort() ?? '22') ?? 22,
        rigCount: LgConnectionSharedPref.getScreenAmount() ?? 3,
      );
    }
  }

  /// Connect to Liquid Galaxy system
  Future<bool> connectToLiquidGalaxy({
    required String host,
    required String username,
    required String password,
    int port = 22,
    int rigCount = 3,
  }) async {
    if (_isConnecting) return false;

    _setConnecting(true);
    _connectionError = null;

    try {
      print(' Connecting to Liquid Galaxy: $host:$port');

      final result = await _sshService.connect(
        host: host,
        username: username,
        password: password,
        port: port,
        rigCount: rigCount,
      );

      if (result == null) {
        // Success
        _isConnected = true;
        _currentHost = host;
        _currentUsername = username;
        _currentPort = port;
        _rigCount = rigCount;
        _lastConnectionStatus = 'Connected successfully at ${DateTime.now()}';

        print(' Connected to Liquid Galaxy successfully');
        _notifyListeners();
        return true;
      } else {
        // Failed
        _connectionError = result;
        _isConnected = false;
        print(' Connection failed: $result');
        _notifyListeners();
        return false;
      }
    } catch (e) {
      _connectionError = 'Connection error: $e';
      _isConnected = false;
      print(' Connection exception: $e');
      _notifyListeners();
      return false;
    } finally {
      _setConnecting(false);
    }
  }

  /// Test connection without establishing full connection - FIXED VERSION
  Future<bool> testConnection({
    required String host,
    required String username,
    required String password,
    int port = 22,
  }) async {
    SSHClient? testClient;
    try {
      print(' Testing SSH connection parameters...');
      print('   Host: $host:$port');
      print('   Username: $username');

      final socket = await SSHSocket.connect(host, port,
          timeout: const Duration(seconds: 30));

      testClient = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () {
          print(' Password requested for test connection []$password');
          return password;
        },
      );

      // Wait for authentication
      print(' Waiting for authentication...');
      await Future.delayed(const Duration(seconds: 8));

      // Try executing whoami
      print(' Executing test command...');
      final session = await testClient.execute('whoami');

      // FIXED: Properly handle the stream output
      final bytes = <int>[];
      await for (final chunk in session.stdout) {
        if (chunk is List<int>) {
          bytes.addAll(chunk);
        }
      }

      final output = utf8.decode(bytes);
      print('   Test result: "${output.trim()}"');

      if (output.trim() == username) {
        print(' Connection test successful');
        return true;
      } else {
        print(' Connection test failed - unexpected response: "$output"');
        return false;
      }
    } catch (e) {
      print(' Connection test failed: $e');
      return false;
    } finally {
      testClient?.close();
    }
  }

  /// Upload disaster KML to Liquid Galaxy
  Future<bool> uploadDisasterKML(List<DisasterEvent> disasters,
      {bool isTour = false}) async {
    if (!_isConnected) {
      _kmlUploadError = 'Not connected to Liquid Galaxy';
      _notifyListeners();
      return false;
    }

    if (disasters.isEmpty) {
      _kmlUploadError = 'No disaster data to upload';
      _notifyListeners();
      return false;
    }

    _setUploadingKML(true);
    _kmlUploadError = null;

    try {
      print(' Generating ${isTour ? 'tour' : 'standard'} KML for ${disasters
          .length} disasters...');

      // Generate appropriate KML
      final kmlContent = isTour
          ? EnhancedKmlService.generateEnhancedTourKML(disasters)
          : EnhancedKmlService.generateRealTimeDisasterKML(disasters);

      final fileName = isTour
          ? 'disaster_tour_${DateTime
          .now()
          .millisecondsSinceEpoch}'
          : 'disaster_data_${DateTime
          .now()
          .millisecondsSinceEpoch}';

      print(' Uploading KML to Liquid Galaxy...');
      final uploadSuccess = await _sshService.uploadKMLFile(
          kmlContent, fileName);

      _totalKMLUploads++;

      if (uploadSuccess) {
        _successfulUploads++;
        _lastUploadedKML = fileName;
        _lastKMLUploadTime = DateTime.now();
        print(' KML uploaded successfully: $fileName');
        _notifyListeners();
        return true;
      } else {
        _failedUploads++;
        _kmlUploadError = 'Failed to upload KML to Liquid Galaxy';
        print(' KML upload failed');
        _notifyListeners();
        return false;
      }
    } catch (e) {
      _failedUploads++;
      _kmlUploadError = 'KML upload error: $e';
      print(' KML upload exception: $e');
      _notifyListeners();
      return false;
    } finally {
      _setUploadingKML(false);
    }
  }

  /// Upload single disaster KML
  Future<bool> uploadSingleDisasterKML(DisasterEvent disaster) async {
    if (!_isConnected) {
      _kmlUploadError = 'Not connected to Liquid Galaxy';
      _notifyListeners();
      return false;
    }

    _setUploadingKML(true);
    _kmlUploadError = null;

    try {
      print(' Generating single disaster KML...');

      final kmlContent = EnhancedKmlService.generateSingleDisasterKML(disaster);
      final fileName = 'single_disaster_${disaster.id}_${DateTime
          .now()
          .millisecondsSinceEpoch}';

      print(' Uploading single disaster KML...');
      final uploadSuccess = await _sshService.uploadKMLFile(
          kmlContent, fileName);

      _totalKMLUploads++;

      if (uploadSuccess) {
        _successfulUploads++;
        _lastUploadedKML = fileName;
        _lastKMLUploadTime = DateTime.now();
        print(' Single disaster KML uploaded: $fileName');
        _notifyListeners();
        return true;
      } else {
        _failedUploads++;
        _kmlUploadError = 'Failed to upload single disaster KML';
        _notifyListeners();
        return false;
      }
    } catch (e) {
      _failedUploads++;
      _kmlUploadError = 'Single disaster KML upload error: $e';
      print(' Single disaster KML upload exception: $e');
      _notifyListeners();
      return false;
    } finally {
      _setUploadingKML(false);
    }
  }

  /// Fly to specific disaster location
  Future<bool> flyToDisaster(DisasterEvent disaster) async {
    if (!_isConnected) {
      print(' Cannot fly to disaster: Not connected to Liquid Galaxy');
      return false;
    }

    try {
      print(' Flying to disaster: ${disaster.title}');

      // Calculate appropriate range based on disaster type and severity
      double range = 50000; // Default range
      switch (disaster.severity) {
        case SeverityLevel.critical:
          range = 25000;
          break;
        case SeverityLevel.high:
          range = 50000;
          break;
        case SeverityLevel.medium:
          range = 100000;
          break;
        case SeverityLevel.low:
          range = 200000;
          break;
      }

      final success = await _sshService.flyToLocation(
        latitude: disaster.latitude,
        longitude: disaster.longitude,
        altitude: 1000,
        heading: 0,
        tilt: 60,
        range: range,
      );

      if (success) {
        print(' Successfully flew to disaster location');
      } else {
        print(' Failed to fly to disaster location');
      }

      return success;
    } catch (e) {
      print(' Fly to disaster error: $e');
      return false;
    }
  }

  /// Clear Liquid Galaxy display
  Future<bool> clearLiquidGalaxy() async {
    if (!_isConnected) {
      print(' Cannot clear display: Not connected to Liquid Galaxy');
      return false;
    }

    try {
      print('🧹 Clearing Liquid Galaxy display...');
      final success = await _sshService.clearGoogleEarth();

      if (success) {
        _lastUploadedKML = null;
        print(' Liquid Galaxy display cleared');
        _notifyListeners();
      }

      return success;
    } catch (e) {
      print(' Clear display error: $e');
      return false;
    }
  }

  /// Get Liquid Galaxy system status
  Future<String?> getLiquidGalaxyStatus() async {
    if (!_isConnected) return 'Not connected';

    try {
      return await _sshService.getGoogleEarthStatus();
    } catch (e) {
      print(' Status check error: $e');
      return 'Error checking status';
    }
  }

  /// Restart Google Earth on Liquid Galaxy
  Future<bool> restartGoogleEarth() async {
    if (!_isConnected) return false;

    try {
      print(' Restarting Google Earth...');
      final success = await _sshService.restartGoogleEarth();

      if (success) {
        print(' Google Earth restarted successfully');
      }

      return success;
    } catch (e) {
      print(' Restart Google Earth error: $e');
      return false;
    }
  }

  /// Enable/disable auto-sync
  void setAutoSync(bool enabled, {Duration? interval}) {
    _autoSyncEnabled = enabled;

    if (interval != null) {
      _autoSyncInterval = interval;
    }

    if (enabled && _isConnected) {
      _startAutoSync();
    } else {
      _stopAutoSync();
    }

    _notifyListeners();
  }

  /// Start auto-sync timer
  void _startAutoSync() {
    _stopAutoSync(); // Stop existing timer

    print(' Starting auto-sync every ${_autoSyncInterval.inMinutes} minutes');
    _autoSyncTimer = Timer.periodic(_autoSyncInterval, (timer) {
      if (_isConnected && !_isUploadingKML) {
        print(' Auto-sync triggered');
        // This would typically be called with current disaster data
        // For now, we just log that auto-sync is ready
      }
    });
  }

  /// Stop auto-sync timer
  void _stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  /// Disconnect from Liquid Galaxy
  Future<void> disconnect() async {
    try {
      _stopAutoSync();
      await _sshService.disconnect();

      _isConnected = false;
      _currentHost = null;
      _currentUsername = null;
      _currentPort = null;
      _rigCount = null;
      _lastConnectionStatus = 'Disconnected at ${DateTime.now()}';

      print('🔌 Disconnected from Liquid Galaxy');
      _notifyListeners();
    } catch (e) {
      print(' Disconnect error: $e');
    }
  }

  /// Get detailed connection information
  Map<String, dynamic> getConnectionInfo() {
    return {
      'isConnected': _isConnected,
      'isConnecting': _isConnecting,
      'host': _currentHost,
      'username': _currentUsername,
      'port': _currentPort,
      'rigCount': _rigCount,
      'lastConnectionStatus': _lastConnectionStatus,
      'connectionError': _connectionError,
      'autoSyncEnabled': _autoSyncEnabled,
      'autoSyncInterval': _autoSyncInterval.inMinutes,
      'lastKMLUpload': _lastUploadedKML,
      'lastKMLUploadTime': _lastKMLUploadTime?.toIso8601String(),
      'totalUploads': _totalKMLUploads,
      'successfulUploads': _successfulUploads,
      'failedUploads': _failedUploads,
      'uploadSuccessRate': uploadSuccessRate,
    };
  }

  /// Get upload statistics
  Map<String, dynamic> getUploadStatistics() {
    return {
      'totalUploads': _totalKMLUploads,
      'successfulUploads': _successfulUploads,
      'failedUploads': _failedUploads,
      'successRate': uploadSuccessRate,
      'lastUploadTime': _lastKMLUploadTime?.toIso8601String(),
      'lastUploadedKML': _lastUploadedKML,
    };
  }

  /// Reset upload statistics
  void resetStatistics() {
    _totalKMLUploads = 0;
    _successfulUploads = 0;
    _failedUploads = 0;
    _lastUploadedKML = null;
    _lastKMLUploadTime = null;
    _notifyListeners();
  }

  /// Helper methods
  void _setConnecting(bool connecting) {
    _isConnecting = connecting;
    _notifyListeners();
  }

  void _setUploadingKML(bool uploading) {
    _isUploadingKML = uploading;
    _notifyListeners();
  }

  void _notifyListeners() {
    notifyListeners();
  }

  @override
  void dispose() {
    _stopAutoSync();
    _sshService.dispose();
    super.dispose();
  }
}
