/*import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/hurricane_model.dart';
import '../utils/constants.dart';

class GDACSService {
  static final GDACSService _instance = GDACSService._internal();
  factory GDACSService() => _instance;
  GDACSService._internal();

  Future<List<HurricaneModel>> fetchGlobalDisasters() async {
    try {
      print('🌪️ Fetching GDACS data...');

      final response = await http.get(Uri.parse(APIConstants.gdacsBaseUrl));

      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final items = document.findAllElements('item');

        final hurricanes = <HurricaneModel>[];

        for (final item in items) {
          final title = item.findElements('title').first.text;
          final description = item.findElements('description').first.text;
          final link = item.findElements('link').first.text;

          // Parse coordinates from georss:point or other geo elements
          final geoPoint = item.findElements('point').firstOrNull?.text;
          if (geoPoint != null && title.toLowerCase().contains('cyclone')) {
            final coords = geoPoint.split(' ');
            if (coords.length >= 2) {
              final lat = double.tryParse(coords[0]) ?? 0.0;
              final lon = double.tryParse(coords[1]) ?? 0.0;

              // Extract wind speed and other data from description
              final windSpeed = _extractWindSpeed(description);
              final pressure = _extractPressure(description);

              hurricanes.add(HurricaneModel(
                id: link.hashCode.toString(),
                title: title,
                latitude: lat,
                longitude: lon,
                timestamp: DateTime.now(),
                windSpeed: windSpeed,
                pressure: pressure,
                category: _getCategory(windSpeed),
                properties: {'source': 'GDACS', 'link': link},
                description: description,
              ));
            }
          }
        }

        print('✅ Fetched ${hurricanes.length} hurricanes from GDACS');
        return hurricanes;
      } else {
        throw Exception('GDACS API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ GDACS Service Error: $e');
      return [];
    }
  }

  double _extractWindSpeed(String description) {
    final windRegex = RegExp(r'(\d+)\s*mph|(\d+)\s*km/h');
    final match = windRegex.firstMatch(description);
    if (match != null) {
      final speed = double.tryParse(match.group(1) ?? match.group(2) ?? '0') ?? 0;
      return match.group(1) != null ? speed : speed * 0.621371; // Convert km/h to mph
    }
    return 0.0;
  }

  double _extractPressure(String description) {
    final pressureRegex = RegExp(r'(\d+)\s*mb|(\d+)\s*hPa');
    final match = pressureRegex.firstMatch(description);
    return double.tryParse(match?.group(1) ?? match?.group(2) ?? '0') ?? 0.0;
  }

  String _getCategory(double windSpeed) {
    if (windSpeed >= 157) return 'Category 5';
    if (windSpeed >= 130) return 'Category 4';
    if (windSpeed >= 111) return 'Category 3';
    if (windSpeed >= 96) return 'Category 2';
    if (windSpeed >= 74) return 'Category 1';
    return 'Tropical Storm';
  }
}*/