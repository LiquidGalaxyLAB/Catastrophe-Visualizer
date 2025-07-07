// lib/providers/updated_disaster_provider.dart
// Week 4 Implementation: Enhanced Disaster Provider with Liquid Galaxy integration

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/disaster_event.dart';
import '../services/api_service.dart';
import '../services/enhanced_kml_service.dart';
import 'liquid_galaxy_provider.dart';

class UpdatedDisasterProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final LiquidGalaxyProvider _lgProvider = LiquidGalaxyProvider();

  // Core data
  List<DisasterEvent> _disasters = [];
  List<DisasterEvent> _filteredDisasters = [];

  // State management
  bool _isLoading = false;
  String? _error;
  DateTime? _lastUpdate;

  // Auto-refresh functionality
  Timer? _autoRefreshTimer;
  Duration _refreshInterval = Duration(minutes: 5);
  bool _autoRefreshEnabled = true;

  // Auto-sync with Liquid Galaxy
  bool _autoSyncToLG = false;
  Timer? _autoSyncTimer;
  DateTime? _lastLGSync;

  // Filters
  Set<DisasterType> _selectedTypes = DisasterType.values.toSet();
  Set<SeverityLevel> _selectedSeverities = SeverityLevel.values.toSet();
  String? _selectedCountry;
  String? _selectedContinent;
  DateTime? _startDate;
  DateTime? _endDate;
  double _minimumMagnitude = 0.0;
  bool _showActiveOnly = true;

  // Statistics
  Map<String, dynamic> _statistics = {};

  // Connection status
  bool _isOnline = true;
  Map<String, bool> _apiStatus = {};

  // Week 4: Enhanced real-time tracking
  Map<String, DisasterEvent> _disasterCache = {};
  List<DisasterEvent> _recentUpdates = [];
  int _maxRecentUpdates = 50;

  // Getters
  List<DisasterEvent> get disasters => List.unmodifiable(_disasters);
  List<DisasterEvent> get filteredDisasters => List.unmodifiable(_filteredDisasters);
  List<DisasterEvent> get recentUpdates => List.unmodifiable(_recentUpdates);
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastUpdate => _lastUpdate;
  DateTime? get lastLGSync => _lastLGSync;
  bool get autoSyncToLG => _autoSyncToLG;
  Set<DisasterType> get selectedTypes => Set.from(_selectedTypes);
  Set<SeverityLevel> get selectedSeverities => Set.from(_selectedSeverities);
  String? get selectedCountry => _selectedCountry;
  String? get selectedContinent => _selectedContinent;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  double get minimumMagnitude => _minimumMagnitude;
  bool get showActiveOnly => _showActiveOnly;
  bool get autoRefreshEnabled => _autoRefreshEnabled;
  Duration get refreshInterval => _refreshInterval;
  Map<String, dynamic> get statistics => Map.from(_statistics);
  bool get isOnline => _isOnline;
  Map<String, bool> get apiStatus => Map.from(_apiStatus);
  LiquidGalaxyProvider get lgProvider => _lgProvider;

  // Statistics getters
  int get totalDisasters => _disasters.length;
  int get filteredCount => _filteredDisasters.length;
  int get criticalDisasters => _disasters.where((d) => d.severity == SeverityLevel.critical).length;
  int get activeDisasters => _disasters.where((d) => d.isActive).length;
  int get recentUpdatesCount => _recentUpdates.length;

  Map<DisasterType, int> get disastersByType {
    final map = <DisasterType, int>{};
    for (final type in DisasterType.values) {
      map[type] = _disasters.where((d) => d.type == type).length;
    }
    return map;
  }

  Map<SeverityLevel, int> get disastersBySeverity {
    final map = <SeverityLevel, int>{};
    for (final severity in SeverityLevel.values) {
      map[severity] = _disasters.where((d) => d.severity == severity).length;
    }
    return map;
  }

  // Initialize provider
  Future<void> initialize() async {
    await _loadPreferences();
    await _lgProvider.initialize();
    await loadDisasters();
    _startAutoRefresh();

    if (_autoSyncToLG && _lgProvider.isConnected) {
      _startAutoSyncToLG();
    }
  }

  // Week 4: Enhanced disaster loading with real-time tracking
  Future<void> loadDisasters() async {
    if (_isLoading) return;

    _setLoading(true);
    _error = null;

    try {
      print(' Loading disaster data (Week 4 Enhanced)...');

      // Test API connectivity first
      _apiStatus = await _apiService.testApiConnectivity();
      _isOnline = _apiStatus.values.any((status) => status);

      // Fetch disasters with enhanced tracking
      final newDisasters = await _apiService.fetchAllDisasters();

      // Week 4: Track new and updated disasters
      _trackDisasterChanges(newDisasters);

      _disasters = newDisasters;
      _lastUpdate = DateTime.now();

      // Apply filters and update statistics
      _applyFilters();
      _updateStatistics();

      // Save to cache for offline access
      await _saveDisastersToCache();

      // Auto-sync to Liquid Galaxy if enabled
      if (_autoSyncToLG && _lgProvider.isConnected && _filteredDisasters.isNotEmpty) {
        await syncToLiquidGalaxy();
      }

      _error = null;
      print(' Successfully loaded ${_disasters.length} disasters');
      print(' Recent updates: ${_recentUpdates.length}');

    } catch (e) {
      _error = 'Failed to load disasters: $e';
      print(' $_error');

      // Try to load from cache
      await _loadDisastersFromCache();
    } finally {
      _setLoading(false);
    }
  }

  // Week 4: Track changes in disaster data
  void _trackDisasterChanges(List<DisasterEvent> newDisasters) {
    final currentTime = DateTime.now();
    _recentUpdates.clear();

    for (final disaster in newDisasters) {
      final existingDisaster = _disasterCache[disaster.id];

      if (existingDisaster == null) {
        // New disaster
        _recentUpdates.add(disaster);
        print(' New disaster detected: ${disaster.title}');
      } else {
        // Check for updates
        if (_hasDisasterChanged(existingDisaster, disaster)) {
          _recentUpdates.add(disaster);
          print(' Disaster updated: ${disaster.title}');
        }
      }

      // Update cache
      _disasterCache[disaster.id] = disaster;
    }

    // Limit recent updates
    if (_recentUpdates.length > _maxRecentUpdates) {
      _recentUpdates = _recentUpdates.take(_maxRecentUpdates).toList();
    }

    // Sort by timestamp (most recent first)
    _recentUpdates.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // Check if disaster data has changed
  bool _hasDisasterChanged(DisasterEvent old, DisasterEvent updated) {
    return old.magnitude != updated.magnitude ||
        old.severity != updated.severity ||
        old.isActive != updated.isActive ||
        old.description != updated.description;
  }

  // Week 4: Sync disasters to Liquid Galaxy
  Future<bool> syncToLiquidGalaxy({bool forceTour = false}) async {
    if (!_lgProvider.isConnected) {
      print(' Cannot sync to Liquid Galaxy: Not connected');
      return false;
    }

    if (_filteredDisasters.isEmpty) {
      print(' No filtered disasters to sync');
      return false;
    }

    try {
      print(' Syncing ${_filteredDisasters.length} disasters to Liquid Galaxy...');

      final success = await _lgProvider.uploadDisasterKML(
          _filteredDisasters,
          isTour: forceTour || _filteredDisasters.length <= 10
      );

      if (success) {
        _lastLGSync = DateTime.now();
        print(' Successfully synced disasters to Liquid Galaxy');
        _notifyListeners();
        return true;
      } else {
        print(' Failed to sync disasters to Liquid Galaxy');
        return false;
      }
    } catch (e) {
      print(' Sync to Liquid Galaxy error: $e');
      return false;
    }
  }

  // Week 4: Sync specific disaster to Liquid Galaxy
  Future<bool> syncSingleDisasterToLG(DisasterEvent disaster) async {
    if (!_lgProvider.isConnected) {
      print(' Cannot sync disaster: Not connected to Liquid Galaxy');
      return false;
    }

    try {
      print(' Syncing single disaster to Liquid Galaxy: ${disaster.title}');

      final success = await _lgProvider.uploadSingleDisasterKML(disaster);

      if (success) {
        // Also fly to the disaster location
        await _lgProvider.flyToDisaster(disaster);
        _lastLGSync = DateTime.now();
        print(' Successfully synced and flew to disaster');
        _notifyListeners();
        return true;
      } else {
        print(' Failed to sync single disaster');
        return false;
      }
    } catch (e) {
      print(' Single disaster sync error: $e');
      return false;
    }
  }

  // Week 4: Enable/disable auto-sync to Liquid Galaxy
  void setAutoSyncToLG(bool enabled) {
    _autoSyncToLG = enabled;

    if (enabled && _lgProvider.isConnected) {
      _startAutoSyncToLG();
    } else {
      _stopAutoSyncToLG();
    }

    _savePreferences();
    _notifyListeners();
  }

  // Start auto-sync timer for Liquid Galaxy
  void _startAutoSyncToLG() {
    _stopAutoSyncToLG(); // Stop existing timer

    print(' Starting auto-sync to Liquid Galaxy every ${_refreshInterval.inMinutes} minutes');
    _autoSyncTimer = Timer.periodic(_refreshInterval, (timer) async {
      if (_autoSyncToLG && _lgProvider.isConnected && !_lgProvider.isUploadingKML && _filteredDisasters.isNotEmpty) {
        print(' Auto-sync to Liquid Galaxy triggered');
        await syncToLiquidGalaxy();
      }
    });
  }

  // Stop auto-sync timer
  void _stopAutoSyncToLG() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  // Refresh data
  Future<void> refreshData() async {
    await loadDisasters();
  }

  // Apply filters to disaster list
  void _applyFilters() {
    _filteredDisasters = _disasters.where((disaster) {
      // Type filter
      if (!_selectedTypes.contains(disaster.type)) return false;

      // Severity filter
      if (!_selectedSeverities.contains(disaster.severity)) return false;

      // Country filter
      if (_selectedCountry != null && _selectedCountry!.isNotEmpty) {
        if (!disaster.location.toLowerCase().contains(_selectedCountry!.toLowerCase())) {
          return false;
        }
      }

      // Date filter
      if (_startDate != null && disaster.timestamp.isBefore(_startDate!)) return false;
      if (_endDate != null && disaster.timestamp.isAfter(_endDate!)) return false;

      // Magnitude filter
      if (disaster.magnitude < _minimumMagnitude) return false;

      // Active status filter
      if (_showActiveOnly && !disaster.isActive) return false;

      return true;
    }).toList();

    // Sort by timestamp (most recent first)
    _filteredDisasters.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Auto-sync to LG if enabled and filters changed
    if (_autoSyncToLG && _lgProvider.isConnected && !_lgProvider.isUploadingKML) {
      Timer(Duration(seconds: 2), () => syncToLiquidGalaxy());
    }

    notifyListeners();
  }

  // Update statistics with Week 4 enhancements
  void _updateStatistics() {
    final now = DateTime.now();
    final last1Hour = _disasters.where((d) => now.difference(d.timestamp).inHours <= 1).length;
    final last6Hours = _disasters.where((d) => now.difference(d.timestamp).inHours <= 6).length;
    final last24Hours = _disasters.where((d) => now.difference(d.timestamp).inHours <= 24).length;

    _statistics = {
      'total': _disasters.length,
      'active': activeDisasters,
      'critical': criticalDisasters,
      'recentUpdates': _recentUpdates.length,
      'byType': disastersByType,
      'bySeverity': disastersBySeverity,
      'lastUpdate': _lastUpdate?.toIso8601String(),
      'lastLGSync': _lastLGSync?.toIso8601String(),
      'averageMagnitude': _disasters.isNotEmpty
          ? _disasters.map((d) => d.magnitude).reduce((a, b) => a + b) / _disasters.length
          : 0.0,
      'mostAffectedRegions': _getMostAffectedRegions(),
      'recentTrends': {
        'last1Hour': last1Hour,
        'last6Hours': last6Hours,
        'last24Hours': last24Hours,
        'last7Days': _disasters.where((d) => now.difference(d.timestamp).inDays <= 7).length,
        'last30Days': _disasters.where((d) => now.difference(d.timestamp).inDays <= 30).length,
      },
      'severityDistribution': _getSeverityDistribution(),
      'typeDistribution': _getTypeDistribution(),
    };
  }

  Map<String, double> _getSeverityDistribution() {
    final total = _disasters.length;
    if (total == 0) return {};

    return {
      'critical': (_disasters.where((d) => d.severity == SeverityLevel.critical).length / total) * 100,
      'high': (_disasters.where((d) => d.severity == SeverityLevel.high).length / total) * 100,
      'medium': (_disasters.where((d) => d.severity == SeverityLevel.medium).length / total) * 100,
      'low': (_disasters.where((d) => d.severity == SeverityLevel.low).length / total) * 100,
    };
  }

  Map<String, double> _getTypeDistribution() {
    final total = _disasters.length;
    if (total == 0) return {};

    return {
      'earthquake': (_disasters.where((d) => d.type == DisasterType.earthquake).length / total) * 100,
      'hurricane': (_disasters.where((d) => d.type == DisasterType.hurricane).length / total) * 100,
      'wildfire': (_disasters.where((d) => d.type == DisasterType.wildfire).length / total) * 100,
      'flood': (_disasters.where((d) => d.type == DisasterType.flood).length / total) * 100,
    };
  }

  List<String> _getMostAffectedRegions() {
    final regionCount = <String, int>{};
    for (final disaster in _disasters) {
      final region = disaster.location.split(',').last.trim();
      regionCount[region] = (regionCount[region] ?? 0) + 1;
    }

    final sorted = regionCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(5).map((e) => '${e.key} (${e.value})').toList();
  }

  // Filter methods (unchanged but with auto-sync integration)
  void setTypeFilter(Set<DisasterType> types) {
    _selectedTypes = types;
    _applyFilters();
    _savePreferences();
  }

  void setSeverityFilter(Set<SeverityLevel> severities) {
    _selectedSeverities = severities;
    _applyFilters();
    _savePreferences();
  }

  void setCountryFilter(String? country) {
    _selectedCountry = country;
    _applyFilters();
    _savePreferences();
  }

  void setContinentFilter(String? continent) {
    _selectedContinent = continent;
    _applyFilters();
    _savePreferences();
  }

  void setDateFilter(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    _applyFilters();
    _savePreferences();
  }

  void setMagnitudeFilter(double minimum) {
    _minimumMagnitude = minimum;
    _applyFilters();
    _savePreferences();
  }

  void setActiveOnlyFilter(bool activeOnly) {
    _showActiveOnly = activeOnly;
    _applyFilters();
    _savePreferences();
  }

  void clearAllFilters() {
    _selectedTypes = DisasterType.values.toSet();
    _selectedSeverities = SeverityLevel.values.toSet();
    _selectedCountry = null;
    _selectedContinent = null;
    _startDate = null;
    _endDate = null;
    _minimumMagnitude = 0.0;
    _showActiveOnly = true;
    _applyFilters();
    _savePreferences();
  }

  // Auto-refresh functionality
  void _startAutoRefresh() {
    if (!_autoRefreshEnabled) return;

    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(_refreshInterval, (timer) {
      if (_autoRefreshEnabled && !_isLoading) {
        print(' Auto-refresh triggered');
        refreshData();
      }
    });
  }

  void setAutoRefresh(bool enabled, {Duration? interval}) {
    _autoRefreshEnabled = enabled;
    if (interval != null) {
      _refreshInterval = interval;
    }

    if (enabled) {
      _startAutoRefresh();
    } else {
      _autoRefreshTimer?.cancel();
    }

    _savePreferences();
    notifyListeners();
  }

  // KML Generation (now using Enhanced KML Service)
  String generateKML() {
    return EnhancedKmlService.generateRealTimeDisasterKML(_filteredDisasters);
  }

  String generateTourKML() {
    return EnhancedKmlService.generateEnhancedTourKML(_filteredDisasters);
  }

  String generateSingleDisasterKML(DisasterEvent disaster) {
    return EnhancedKmlService.generateSingleDisasterKML(disaster);
  }

  // Utility methods
  DisasterEvent? getDisasterById(String id) {
    try {
      return _disasters.firstWhere((disaster) => disaster.id == id);
    } catch (e) {
      return null;
    }
  }

  List<DisasterEvent> getDisastersByType(DisasterType type) {
    return _filteredDisasters.where((d) => d.type == type).toList();
  }

  List<DisasterEvent> getDisastersBySeverity(SeverityLevel severity) {
    return _filteredDisasters.where((d) => d.severity == severity).toList();
  }

  List<DisasterEvent> getNearbyDisasters(double lat, double lng, double radiusKm) {
    return _filteredDisasters.where((disaster) {
      final distance = _calculateDistance(lat, lng, disaster.latitude, disaster.longitude);
      return distance <= radiusKm;
    }).toList();
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    // Simplified distance calculation (Haversine formula would be more accurate)
    final deltaLat = (lat2 - lat1) * 111.0; // Rough km per degree
    final deltaLng = (lng2 - lng1) * 111.0 * math.cos(lat1 * math.pi / 180);
    return math.sqrt(deltaLat * deltaLat + deltaLng * deltaLng);
  }

  // Persistence methods
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('selectedTypes', _selectedTypes.map((t) => t.name).toList());
      await prefs.setStringList('selectedSeverities', _selectedSeverities.map((s) => s.name).toList());
      await prefs.setString('selectedCountry', _selectedCountry ?? '');
      await prefs.setString('selectedContinent', _selectedContinent ?? '');
      await prefs.setDouble('minimumMagnitude', _minimumMagnitude);
      await prefs.setBool('showActiveOnly', _showActiveOnly);
      await prefs.setBool('autoRefreshEnabled', _autoRefreshEnabled);
      await prefs.setInt('refreshIntervalMinutes', _refreshInterval.inMinutes);
      await prefs.setBool('autoSyncToLG', _autoSyncToLG);
    } catch (e) {
      print('Error saving preferences: $e');
    }
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final typeNames = prefs.getStringList('selectedTypes') ?? DisasterType.values.map((t) => t.name).toList();
      _selectedTypes = typeNames.map((name) => DisasterType.values.firstWhere((t) => t.name == name)).toSet();

      final severityNames = prefs.getStringList('selectedSeverities') ?? SeverityLevel.values.map((s) => s.name).toList();
      _selectedSeverities = severityNames.map((name) => SeverityLevel.values.firstWhere((s) => s.name == name)).toSet();

      _selectedCountry = prefs.getString('selectedCountry')?.isEmpty == true ? null : prefs.getString('selectedCountry');
      _selectedContinent = prefs.getString('selectedContinent')?.isEmpty == true ? null : prefs.getString('selectedContinent');
      _minimumMagnitude = prefs.getDouble('minimumMagnitude') ?? 0.0;
      _showActiveOnly = prefs.getBool('showActiveOnly') ?? true;
      _autoRefreshEnabled = prefs.getBool('autoRefreshEnabled') ?? true;
      _autoSyncToLG = prefs.getBool('autoSyncToLG') ?? false;

      final intervalMinutes = prefs.getInt('refreshIntervalMinutes') ?? 5;
      _refreshInterval = Duration(minutes: intervalMinutes);
    } catch (e) {
      print('Error loading preferences: $e');
    }
  }

  Future<void> _saveDisastersToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _disasters.map((d) => json.encode(d.toJson())).toList();
      await prefs.setStringList('cachedDisasters', jsonList);
      await prefs.setString('cacheTimestamp', DateTime.now().toIso8601String());
    } catch (e) {
      print('Error saving disasters to cache: $e');
    }
  }

  Future<void> _loadDisastersFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList('cachedDisasters') ?? [];
      final cacheTimestamp = prefs.getString('cacheTimestamp');

      if (jsonList.isNotEmpty && cacheTimestamp != null) {
        final cacheTime = DateTime.parse(cacheTimestamp);
        if (DateTime.now().difference(cacheTime).inHours < 24) {
          _disasters = jsonList.map((jsonStr) {
            final jsonData = json.decode(jsonStr);
            return DisasterEvent.fromJson(jsonData);
          }).toList();

          _lastUpdate = cacheTime;
          _applyFilters();
          _updateStatistics();

          print('📱 Loaded ${_disasters.length} disasters from cache');
        }
      }
    } catch (e) {
      print('Error loading disasters from cache: $e');
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _notifyListeners() {
    notifyListeners();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _stopAutoSyncToLG();
    _lgProvider.dispose();
    super.dispose();
  }
}
