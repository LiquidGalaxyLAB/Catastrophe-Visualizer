/*import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/earthquake_model.dart';
import '../utils/constants.dart';

class USGSService {
  static final USGSService _instance = USGSService._internal();
  factory USGSService() => _instance;
  USGSService._internal();

  Future<List<EarthquakeModel>> fetchEarthquakes({
    double? minMagnitude,
    int? limit,
    String? startTime,
    String? endTime,
  }) async {
    try {
      final queryParams = <String, String>{
        'format': APIConstants.usgsFormat,
        'limit': (limit ?? 100).toString(),
      };

      if (minMagnitude != null) {
        queryParams['minmagnitude'] = minMagnitude.toString();
      }

      if (startTime != null) {
        queryParams['starttime'] = startTime;
      }

      if (endTime != null) {
        queryParams['endtime'] = endTime;
      }

      final uri = Uri.parse(APIConstants.usgsBaseUrl).replace(
        queryParameters: queryParams,
      );

      print('🌍 Fetching earthquakes from: $uri');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>;

        final earthquakes = features
            .map((feature) => EarthquakeModel.fromUSGS(feature))
            .toList();

        print('✅ Fetched ${earthquakes.length} earthquakes');
        return earthquakes;
      } else {
        throw Exception('USGS API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ USGS Service Error: $e');
      return [];
    }
  }

  Future<List<EarthquakeModel>> fetchRecentEarthquakes() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    return fetchEarthquakes(
      minMagnitude: 2.5,
      limit: 50,
      startTime: sevenDaysAgo.toIso8601String(),
      endTime: now.toIso8601String(),
    );
  }
}*/