import 'package:flutter/material.dart';

class Disaster {
  final String id;
  final String title;
  final String type;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double magnitude;
  final String severity;
  final String? place;

  Disaster({
    required this.id,
    required this.title,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.magnitude,
    required this.severity,
    this.place,
  });

  factory Disaster.fromUSGS(Map<String, dynamic> feature) {
    final properties = feature['properties'] as Map<String, dynamic>;
    final geometry = feature['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List<dynamic>;
    final magnitude = (properties['mag'] as num?)?.toDouble() ?? 0.0;

    return Disaster(
      id: feature['id'] as String,
      title: properties['title'] as String,
      type: 'earthquake',
      latitude: coordinates[1] as double,
      longitude: coordinates[0] as double,
      timestamp: DateTime.fromMillisecondsSinceEpoch(properties['time'] as int),
      magnitude: magnitude,
      severity: _calculateSeverity(magnitude),
      place: properties['place'] as String?,
    );
  }

  static String _calculateSeverity(double magnitude) {
    if (magnitude >= 7.0) return 'Extreme';
    if (magnitude >= 6.0) return 'Severe';
    if (magnitude >= 4.0) return 'Moderate';
    return 'Minor';
  }

  Color get severityColor {
    switch (severity) {
      case 'Extreme': return Colors.red;
      case 'Severe': return Colors.orange;
      case 'Moderate': return Colors.yellow;
      default: return Colors.green;
    }
  }

  IconData get typeIcon {
    switch (type) {
      case 'earthquake': return Icons.landscape;
      case 'hurricane': return Icons.cyclone;
      case 'wildfire': return Icons.local_fire_department;
      default: return Icons.warning;
    }
  }
}
