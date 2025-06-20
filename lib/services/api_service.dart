import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/disaster_event.dart';

class ApiService {
  static const String _usgsBaseUrl = 'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary';
  static const String _gdacsBaseUrl = 'https://www.gdacs.org/gdacsapi/api';
  static const String _nasaBaseUrl = 'https://eonet.gsfc.nasa.gov/api/v3';
  static const String _noaaBaseUrl = 'https://api.weather.gov';

  // USGS Earthquake API
  Future<List<DisasterEvent>> fetchEarthquakes({
    String timeframe = 'day',
    String magnitude = 'all',
  }) async {
    try {
      final url = '$_usgsBaseUrl/${magnitude}_$timeframe.geojson';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;

        return features.map((feature) =>
            DisasterEvent.fromJson(feature, DisasterType.earthquake)
        ).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching earthquakes: $e');
      return [];
    }
  }

  // GDACS API for Hurricanes/Cyclones
  Future<List<DisasterEvent>> fetchHurricanes() async {
    try {
      final url = '$_gdacsBaseUrl/events/geteventlist/CYCLONE';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final events = data['features'] as List? ?? [];

        return events.map((event) =>
            DisasterEvent.fromJson(event, DisasterType.hurricane)
        ).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching hurricanes: $e');
      return [];
    }
  }

  // NASA EONET API for Wildfires
  Future<List<DisasterEvent>> fetchWildfires() async {
    try {
      final url = '$_nasaBaseUrl/events?category=wildfires&status=open&limit=100';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final events = data['events'] as List? ?? [];

        return events.map((event) =>
            DisasterEvent.fromJson(event, DisasterType.wildfire)
        ).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching wildfires: $e');
      return [];
    }
  }

  // NOAA API for Floods and Weather Alerts
  Future<List<DisasterEvent>> fetchFloods() async {
    try {
      final url = '$_noaaBaseUrl/alerts/active?event=flood';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List? ?? [];

        return features.map((feature) =>
            DisasterEvent.fromJson(feature['properties'], DisasterType.flood)
        ).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching floods: $e');
      return [];
    }
  }

  // Fetch all disasters
  Future<List<DisasterEvent>> fetchAllDisasters() async {
    final results = await Future.wait([
      fetchEarthquakes(),
      fetchHurricanes(),
      fetchWildfires(),
      fetchFloods(),
    ]);

    final allDisasters = <DisasterEvent>[];
    for (final disasters in results) {
      allDisasters.addAll(disasters);
    }

    // Sort by timestamp (most recent first)
    allDisasters.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return allDisasters;
  }

  // Filter disasters by location
  Future<List<DisasterEvent>> fetchDisastersByCountry(String country) async {
    final allDisasters = await fetchAllDisasters();
    return allDisasters.where((disaster) =>
        disaster.location.toLowerCase().contains(country.toLowerCase())
    ).toList();
  }

  // Filter disasters by continent
  Future<List<DisasterEvent>> fetchDisastersByContinent(String continent) async {
    final allDisasters = await fetchAllDisasters();
    // This is a simplified implementation - you might want to use a more sophisticated
    // geolocation service to determine continent from coordinates
    return allDisasters.where((disaster) =>
    _getContinentFromCoordinates(disaster.latitude, disaster.longitude) == continent
    ).toList();
  }

  String _getContinentFromCoordinates(double lat, double lng) {
    // Simplified continent detection based on coordinates
    // In a production app, you'd use a proper geolocation service
    if (lat >= 35 && lat <= 70 && lng >= -25 && lng <= 40) return 'Europe';
    if (lat >= -55 && lat <= 37 && lng >= -20 && lng <= 55) return 'Africa';
    if (lat >= 5 && lat <= 80 && lng >= 25 && lng <= 180) return 'Asia';
    if (lat >= 15 && lat <= 80 && lng >= -170 && lng <= -50) return 'North America';
    if (lat >= -60 && lat <= 15 && lng >= -85 && lng <= -30) return 'South America';
    if (lat >= -50 && lat <= -10 && lng >= 110 && lng <= 180) return 'Australia';
    return 'Unknown';
  }
}