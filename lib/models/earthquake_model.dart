/*import '../utils/constants.dart';
import 'disaster_model.dart';

class EarthquakeModel extends DisasterModel {
  final double magnitude;
  final double depth;
  final String? place;

  EarthquakeModel({
    required String id,
    required String title,
    required double latitude,
    required double longitude,
    required DateTime timestamp,
    required this.magnitude,
    required this.depth,
    required Map<String, dynamic> properties,
    this.place,
  }) : super(
    id: id,
    title: title,
    type: DisasterTypes.earthquake,
    latitude: latitude,
    longitude: longitude,
    timestamp: timestamp,
    properties: properties,
    severity: _calculateSeverity(magnitude),
  );

  static String _calculateSeverity(double magnitude) {
    if (magnitude >= 7.0) return 'Extreme';
    if (magnitude >= 6.0) return 'Severe';
    if (magnitude >= 4.0) return 'Moderate';
    return 'Minor';
  }

  factory EarthquakeModel.fromUSGS(Map<String, dynamic> feature) {
    final properties = feature['properties'] as Map<String, dynamic>;
    final geometry = feature['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List<dynamic>;

    return EarthquakeModel(
      id: feature['id'] as String,
      title: properties['title'] as String,
      latitude: coordinates[1] as double,
      longitude: coordinates[0] as double,
      timestamp: DateTime.fromMillisecondsSinceEpoch(properties['time'] as int),
      magnitude: (properties['mag'] as num).toDouble(),
      depth: coordinates[2] as double,
      properties: properties,
      place: properties['place'] as String?,
    );
  }

  @override
  Map<String, dynamic> toKMLData() {
    return {
      'id': id,
      'name': title,
      'description': '''
        <![CDATA[
          <h3>Earthquake Details</h3>
          <p><strong>Magnitude:</strong> ${magnitude.toStringAsFixed(1)}</p>
          <p><strong>Depth:</strong> ${depth.toStringAsFixed(1)} km</p>
          <p><strong>Location:</strong> ${place ?? 'Unknown'}</p>
          <p><strong>Time:</strong> ${timestamp.toString()}</p>
          <p><strong>Severity:</strong> $severity</p>
        ]]>
      ''',
      'coordinates': '$longitude,$latitude,0',
      'styleUrl': '#earthquake-${severity.toLowerCase()}',
      'iconColor': getMarkerColor(),
    };
  }
}*/