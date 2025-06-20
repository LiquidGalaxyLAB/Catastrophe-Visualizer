import 'package:flutter/foundation.dart';

import '../models/disaster_event.dart';
import '../services/api_service.dart';
import '../services/kml_service.dart';
import '../services/liquid_galaxy_service.dart';

class DisasterProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final KmlService _kmlService = KmlService();
  final LiquidGalaxyService _lgService = LiquidGalaxyService();

  List<DisasterEvent> _disasters = [];
  List<DisasterEvent> _filteredDisasters = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastUpdate;

  // Filters
  Set<DisasterType> _selectedTypes = DisasterType.values.toSet();
  String? _selectedCountry;
  String? _selectedContinent;
  DateTime? _startDate;
  DateTime? _endDate;

  // Getters
  List<DisasterEvent> get disasters => _disasters;
  List<DisasterEvent> get filteredDisasters => _filteredDisasters;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastUpdate => _lastUpdate;
  Set<DisasterType> get selectedTypes => _selectedTypes;
  String? get selectedCountry => _selectedCountry;
  String? get selectedContinent => _selectedContinent;
  LiquidGalaxyService get lgService => _lgService;

  // Statistics
  int get totalDisasters => _disasters.length;
  int get criticalDisasters => _disasters.where((d) => d.severity == SeverityLevel.critical).length;
  int get highRiskAreas => _disasters.where((d) => d.severity == SeverityLevel.high).length;
  int get peopleAffected => _disasters.length * 1000; // Simplified calculation

  Map<DisasterType, int> get disasterByType {
    final map = <DisasterType, int>{};
    for (final type in DisasterType.values) {
      map[type] = _disasters.where((d) => d.type == type).length;
    }
    return map;
  }

  Future<void> loadDisasters() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _disasters = await _apiService.fetchAllDisasters();
      _lastUpdate = DateTime.now();
      _applyFilters();
      _error = null;
    } catch (e) {
      _error = 'Failed to load disasters: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshData() async {
    await loadDisasters();
  }

  void _applyFilters() {
    _filteredDisasters = _disasters.where((disaster) {
      // Type filter
      if (!_selectedTypes.contains(disaster.type)) return false;

      // Country filter
      if (_selectedCountry != null &&
          !disaster.location.toLowerCase().contains(_selectedCountry!.toLowerCase())) {
        return false;
      }

      // Date filter
      if (_startDate != null && disaster.timestamp.isBefore(_startDate!)) return false;
      if (_endDate != null && disaster.timestamp.isAfter(_endDate!)) return false;

      return true;
    }).toList();

    notifyListeners();
  }

  void setTypeFilter(Set<DisasterType> types) {
    _selectedTypes = types;
    _applyFilters();
  }

  void setCountryFilter(String? country) {
    _selectedCountry = country;
    _applyFilters();
  }

  void setContinentFilter(String? continent) {
    _selectedContinent = continent;
    _applyFilters();
  }

  void setDateFilter(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    _applyFilters();
  }

  void clearFilters() {
    _selectedTypes = DisasterType.values.toSet();
    _selectedCountry = null;
    _selectedContinent = null;
    _startDate = null;
    _endDate = null;
    _applyFilters();
  }

  // Liquid Galaxy Integration
  Future<bool> connectToLiquidGalaxy({
    required String host,
    required String username,
    required String password,
    int port = 22,
    int rigCount = 3,
  }) async {
    final success = await _lgService.connect(
      host: host,
      username: username,
      password: password,
      port: port,
      rigCount: rigCount,
    );

    if (success) {
      await sendDisastersToLG();
    }

    notifyListeners();
    return success;
  }

  Future<void> disconnectFromLiquidGalaxy() async {
    await _lgService.disconnect();
    notifyListeners();
  }

  Future<bool> sendDisastersToLG() async {
    if (!_lgService.isConnected || _filteredDisasters.isEmpty) {
      return false;
    }

    try {
      final kmlContent = KmlService.generateDisasterKML(_filteredDisasters);
      return await _lgService.sendKMLToLG(kmlContent, 'catastrophe_visualizer');
    } catch (e) {
      print('Error sending disasters to LG: $e');
      return false;
    }
  }

  Future<bool> flyToDisaster(DisasterEvent disaster) async {
    if (!_lgService.isConnected) return false;

    return await _lgService.flyTo(
      latitude: disaster.latitude,
      longitude: disaster.longitude,
      altitude: 10000,
    );
  }

  Future<bool> startDisasterTour() async {
    if (!_lgService.isConnected || _filteredDisasters.isEmpty) return false;

    return await _lgService.sendTourKML(_filteredDisasters);
  }

  Future<bool> clearLiquidGalaxy() async {
    if (!_lgService.isConnected) return false;

    return await _lgService.clearLG();
  }
}