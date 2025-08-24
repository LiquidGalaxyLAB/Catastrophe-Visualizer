/*import '../utils/constants.dart';
import 'disaster_model.dart';

class HurricaneModel extends DisasterModel {
  final double windSpeed;
  final double pressure;
  final String category;
  final List<Map<String, dynamic>>? trackData;

  HurricaneModel({
    required String id,
    required String title,
    required double latitude,
    required double longitude,
    required DateTime timestamp,
    required this.windSpeed,
    required this.pressure,
    required this.category,
    required Map<String, dynamic> properties,
    this.trackData,
    String? description,
  }) : super(
    id: id,
    title: title,
    type: DisasterTypes.hurricane,
    latitude: latitude,
    longitude: longitude,
    timestamp: timestamp,
    properties: properties,
    severity: _calculateSeverity(windSpeed),
    description: description,
  );

  static String _calculateSeverity(double windSpeed) {
    if (windSpeed >= 157) return 'Extreme'; // Category 5
    if (windSpeed >= 130) return 'Severe';  // Category 4
    if (windSpeed >= 111) return 'Moderate'; // Category 3
    if (windSpeed >= 96) return 'Minor';    // Category 2
    return 'Minor'; // Category 1 or below
  }

  @override
  Map<String, dynamic> toKMLData() {
    return {
      'id': id,
      'name': title,
      'description': '''
        <![CDATA[
          <h3>Hurricane Details</h3>
          <p><strong>Category:</strong> $category</p>
          <p><strong>Wind Speed:</strong> ${windSpeed.toInt()} mph</p>
          <p><strong>Pressure:</strong> ${pressure.toInt()} mb</p>
          <p><strong>Time:</strong> ${timestamp.toString()}</p>
          <p><strong>Severity:</strong> $severity</p>
        ]]>
      ''',
      'coordinates': '$longitude,$latitude,0',
      'styleUrl': '#hurricane-${severity.toLowerCase()}',
      'iconColor': getMarkerColor(),
      'trackData': trackData,
    };
  }
}*/