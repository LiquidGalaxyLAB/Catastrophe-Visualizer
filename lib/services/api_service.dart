import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/disaster_event.dart';

class ApiService {
  static const String _usgsBaseUrl = 'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary';
  static const String _nasaBaseUrl = 'https://eonet.gsfc.nasa.gov/api/v3';

  // For testing purposes, we'll use a timeout
  static const Duration _requestTimeout = Duration(seconds: 10);

  // Connection status
  bool _isConnected = true;

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Check internet connectivity
  Future<bool> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      _isConnected = connectivityResult != ConnectivityResult.none;
      return _isConnected;
    } catch (e) {
      print('Connectivity check failed: $e');
      _isConnected = false;
      return false;
    }
  }

  // USGS Earthquake API with enhanced error handling
  Future<List<DisasterEvent>> fetchEarthquakes({
    String timeframe = 'day',
    String magnitude = 'all',
  }) async {
    if (!await _checkConnectivity()) {
      return _getMockEarthquakes(); // Return mock data when offline
    }

    try {
      final url = '$_usgsBaseUrl/${magnitude}_$timeframe.geojson';
      print('Fetching earthquakes from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List? ?? [];

        print('Successfully fetched ${features.length} earthquakes');

        return features.map((feature) {
          try {
            return DisasterEvent.fromUSGSJson(feature);
          } catch (e) {
            print('Error parsing earthquake data: $e');
            return null;
          }
        }).where((event) => event != null).cast<DisasterEvent>().toList();
      } else {
        print('USGS API error: ${response.statusCode} - ${response.body}');
        return _getMockEarthquakes();
      }
    } catch (e) {
      print('Error fetching earthquakes: $e');
      return _getMockEarthquakes();
    }
  }

  // NASA EONET API for Wildfires with enhanced error handling
  Future<List<DisasterEvent>> fetchWildfires() async {
    if (!await _checkConnectivity()) {
      return _getMockWildfires();
    }

    try {
      final url = '$_nasaBaseUrl/events?category=wildfires&status=open&limit=50';
      print('Fetching wildfires from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final events = data['events'] as List? ?? [];

        print('Successfully fetched ${events.length} wildfires');

        return events.map((event) {
          try {
            return DisasterEvent.fromNASAJson(event);
          } catch (e) {
            print('Error parsing wildfire data: $e');
            return null;
          }
        }).where((event) => event != null).cast<DisasterEvent>().toList();
      } else {
        print('NASA API error: ${response.statusCode} - ${response.body}');
        return _getMockWildfires();
      }
    } catch (e) {
      print('Error fetching wildfires: $e');
      return _getMockWildfires();
    }
  }

  // Fetch all disasters with parallel requests
  Future<List<DisasterEvent>> fetchAllDisasters() async {
    print('Starting to fetch all disasters...');

    try {
      // Run requests in parallel for better performance
      final results = await Future.wait([
        fetchEarthquakes(),
        fetchWildfires(),
        // Add more API calls here as needed
      ]);

      final allDisasters = <DisasterEvent>[];
      for (final disasters in results) {
        allDisasters.addAll(disasters);
      }

      // Sort by timestamp (most recent first)
      allDisasters.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      print('Fetched total of ${allDisasters.length} disasters');
      return allDisasters;
    } catch (e) {
      print('Error in fetchAllDisasters: $e');
      return _getMockAllDisasters();
    }
  }

  // Mock data methods for testing and offline scenarios
  List<DisasterEvent> _getMockEarthquakes() {
    return [
      DisasterEvent.fromMockData({
        'id': 'mock_eq_1',
        'title': 'M 6.2 - 15km SW of Eureka, California',
        'description': 'Strong earthquake near the coast',
        'type': 0, // earthquake
        'latitude': 40.7589,
        'longitude': -124.2637,
        'timestamp': DateTime.now().subtract(Duration(hours: 2)).millisecondsSinceEpoch,
        'magnitude': 6.2,
        'location': 'Eureka, California',
        'severity': 2, // high
        'affectedAreas': ['Northern California', 'Coastal regions'],
        'isActive': true,
      }),
      DisasterEvent.fromMockData({
        'id': 'mock_eq_2',
        'title': 'M 4.8 - 25km NE of Los Angeles, California',
        'description': 'Moderate earthquake in urban area',
        'type': 0, // earthquake
        'latitude': 34.1522,
        'longitude': -118.1437,
        'timestamp': DateTime.now().subtract(Duration(hours: 6)).millisecondsSinceEpoch,
        'magnitude': 4.8,
        'location': 'Los Angeles, California',
        'severity': 1, // medium
        'affectedAreas': ['Los Angeles County'],
        'isActive': true,
      }),
    ];
  }

  List<DisasterEvent> _getMockWildfires() {
    return [
      DisasterEvent.fromMockData({
        'id': 'mock_fire_1',
        'title': 'Pacific Fire - Riverside County',
        'description': 'Large wildfire threatening residential areas',
        'type': 2, // wildfire
        'latitude': 33.7866,
        'longitude': -116.4091,
        'timestamp': DateTime.now().subtract(Duration(hours: 4)).millisecondsSinceEpoch,
        'magnitude': 0.0,
        'location': 'Riverside County, California',
        'severity': 3, // critical
        'affectedAreas': ['Riverside County', 'Desert communities'],
        'isActive': true,
      }),
      DisasterEvent.fromMockData({
        'id': 'mock_fire_2',
        'title': 'Mountain View Fire - Colorado',
        'description': 'Forest fire in mountainous region',
        'type': 2, // wildfire
        'latitude': 39.7392,
        'longitude': -105.0178,
        'timestamp': DateTime.now().subtract(Duration(days: 1)).millisecondsSinceEpoch,
        'magnitude': 0.0,
        'location': 'Colorado',
        'severity': 2, // high
        'affectedAreas': ['Jefferson County', 'Boulder County'],
        'isActive': true,
      }),
    ];
  }

  List<DisasterEvent> _getMockAllDisasters() {
    final all = <DisasterEvent>[];
    all.addAll(_getMockEarthquakes());
    all.addAll(_getMockWildfires());
    all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return all;
  }

  // Test API connectivity
  Future<Map<String, bool>> testApiConnectivity() async {
    final results = <String, bool>{};

    try {
      // Test USGS
      final usgsResponse = await http.get(
        Uri.parse('$_usgsBaseUrl/significant_month.geojson'),
      ).timeout(Duration(seconds: 5));
      results['USGS'] = usgsResponse.statusCode == 200;
    } catch (e) {
      results['USGS'] = false;
    }

    try {
      // Test NASA
      final nasaResponse = await http.get(
        Uri.parse('$_nasaBaseUrl/events?limit=1'),
      ).timeout(Duration(seconds: 5));
      results['NASA'] = nasaResponse.statusCode == 200;
    } catch (e) {
      results['NASA'] = false;
    }

    return results;
  }
}

