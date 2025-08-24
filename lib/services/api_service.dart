
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../models/disaster_model.dart';

class DisasterApiService extends ChangeNotifier {
  List<Disaster> _disasters = [];
  bool _isLoading = false;
  String? _lastError;
  DateTime? _lastUpdate;

  List<Disaster> get disasters => _disasters;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  DateTime? get lastUpdate => _lastUpdate;

  /// Fetch earthquakes from USGS API
  Future<void> fetchEarthquakes({
    double minMagnitude = 2.5,
    int limit = 50,
  }) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      print(' Fetching earthquakes from USGS...');

      final uri = Uri.parse('https://earthquake.usgs.gov/fdsnws/event/1/query').replace(
        queryParameters: {
          'format': 'geojson',
          'limit': limit.toString(),
          'minmagnitude': minMagnitude.toString(),
          'orderby': 'time',
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>;

        _disasters = features
            .map((feature) => Disaster.fromUSGS(feature))
            .toList();

        _lastUpdate = DateTime.now();
        print(' Fetched ${_disasters.length} earthquakes');
      } else {
        throw Exception('USGS API Error: ${response.statusCode}');
      }
    } catch (e) {
      _lastError = 'Failed to fetch disasters: $e';
      print(' API Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Filter disasters by type
  List<Disaster> getDisastersByType(String type) {
    return _disasters.where((d) => d.type == type).toList();
  }

  /// Filter disasters by severity
  List<Disaster> getDisastersBySeverity(String severity) {
    return _disasters.where((d) => d.severity == severity).toList();
  }

  /// Filter disasters by minimum magnitude
  List<Disaster> getDisastersByMagnitude(double minMagnitude) {
    return _disasters.where((d) => d.magnitude >= minMagnitude).toList();
  }

  /// Get recent disasters (last N hours)
  List<Disaster> getRecentDisasters(int hours) {
    final cutoff = DateTime.now().subtract(Duration(hours: hours));
    return _disasters.where((d) => d.timestamp.isAfter(cutoff)).toList();
  }

  /// Get disaster statistics
  Map<String, int> getStatistics() {
    return {
      'total': _disasters.length,
      'extreme': _disasters.where((d) => d.severity == 'Extreme').length,
      'severe': _disasters.where((d) => d.severity == 'Severe').length,
      'moderate': _disasters.where((d) => d.severity == 'Moderate').length,
      'minor': _disasters.where((d) => d.severity == 'Minor').length,
      'recent_24h': getRecentDisasters(24).length,
    };
  }
}
