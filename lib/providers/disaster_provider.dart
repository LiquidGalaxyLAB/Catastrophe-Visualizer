/*import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/disaster_model.dart';
import '../services/api_service.dart';
import '../services/kml_service.dart';

class DisasterProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

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

  // Getters
  List<DisasterEvent> get disasters => List.unmodifiable(_disasters);
  List<DisasterEvent> get filteredDisasters => List.unmodifiable(_filteredDisasters);
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastUpdate => _lastUpdate;
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

  // Statistics getters
  int get totalDisasters => _disasters.length;
  int get filteredCount => _filteredDisasters.length;
  int get criticalDisasters => _disasters.where((d) => d.severity == SeverityLevel.critical).length;
  int get activeDisasters => _disasters.where((d) => d.isActive).length;

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

  get math => null;

  // Initialize provider
  Future<void> initialize() async {
    await _loadPreferences();
    await loadDisasters();
    _startAutoRefresh();
  }

  // Load disasters with enhanced error handling
  Future<void> loadDisasters() async {
    if (_isLoading) return;

    _setLoading(true);
    _error = null;

    try {
      print('Loading disasters...');

      // Test API connectivity first
      _apiStatus = await _apiService.testApiConnectivity();
      _isOnline = _apiStatus.values.any((status) => status);

      // Fetch disasters
      final disasters = await _apiService.fetchAllDisasters();

      _disasters = disasters;
      _lastUpdate = DateTime.now();

      // Apply filters and update statistics
      _applyFilters();
      _updateStatistics();

      // Save to preferences for offline access
      await _saveDisastersToCache();

      _error = null;
      print('Successfully loaded ${_disasters.length} disasters');

    } catch (e) {
      _error = 'Failed to load disasters: $e';
      print(_error);

      // Try to load from cache
      await _loadDisastersFromCache();
    } finally {
      _setLoading(false);
    }
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

    notifyListeners();
  }

  // Update statistics
  void _updateStatistics() {
    _statistics = {
      'total': _disasters.length,
      'active': activeDisasters,
      'critical': criticalDisasters,
      'byType': disastersByType,
      'bySeverity': disastersBySeverity,
      'lastUpdate': _lastUpdate?.toIso8601String(),
      'averageMagnitude': _disasters.isNotEmpty
          ? _disasters.map((d) => d.magnitude).reduce((a, b) => a + b) / _disasters.length
          : 0.0,
      'mostAffectedRegions': _getMostAffectedRegions(),
      'recentTrends': _getRecentTrends(),
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

  Map<String, int> _getRecentTrends() {
    final now = DateTime.now();
    final last24h = _disasters.where((d) => now.difference(d.timestamp).inHours <= 24).length;
    final last7days = _disasters.where((d) => now.difference(d.timestamp).inDays <= 7).length;
    final last30days = _disasters.where((d) => now.difference(d.timestamp).inDays <= 30).length;

    return {
      'last24Hours': last24h,
      'last7Days': last7days,
      'last30Days': last30days,
    };
  }

  // Filter methods
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
        print('Auto-refreshing disaster data...');
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

  // KML Generation
  String generateKML() {
    return KmlService.generateDisasterKML(_filteredDisasters);
  }

  String generateTourKML() {
    return KmlService.generateDisasterTourKML(_filteredDisasters);
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

          print('Loaded ${_disasters.length} disasters from cache');
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

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
}




















*/



