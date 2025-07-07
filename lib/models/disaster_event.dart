import 'dart:convert';

class DisasterEvent {
  final String id;
  final String title;
  final String description;
  final DisasterType type;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double magnitude;
  final String location;
  final SeverityLevel severity;
  final Map<String, dynamic> additionalData;
  final String? imageUrl;
  final List<String> affectedAreas;
  final bool isActive;
  final DateTime? estimatedEnd;

  DisasterEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.magnitude,
    required this.location,
    required this.severity,
    this.additionalData = const {},
    this.imageUrl,
    this.affectedAreas = const [],
    this.isActive = true,
    this.estimatedEnd,
  });

  // Factory constructors for different API sources
  factory DisasterEvent.fromUSGSJson(Map<String, dynamic> json) {
    final properties = json['properties'] ?? {};
    final geometry = json['geometry'] ?? {};
    final coordinates = geometry['coordinates'] ?? [0, 0, 0];

    final magnitude = properties['mag']?.toDouble() ?? 0.0;
    final depth = coordinates.length > 2 ? coordinates[2]?.toDouble() ?? 0.0 : 0.0;

    return DisasterEvent(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: properties['title'] ?? 'Earthquake Event',
      description: properties['place'] ?? 'Location unknown',
      type: DisasterType.earthquake,
      latitude: coordinates.length > 1 ? coordinates[1]?.toDouble() ?? 0.0 : 0.0,
      longitude: coordinates.length > 0 ? coordinates[0]?.toDouble() ?? 0.0 : 0.0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(properties['time'] ?? DateTime.now().millisecondsSinceEpoch),
      magnitude: magnitude,
      location: properties['place'] ?? 'Unknown Location',
      severity: _calculateEarthquakeSeverity(magnitude),
      imageUrl: properties['url'],
      additionalData: {
        'depth': depth,
        'alert': properties['alert'] ?? 'green',
        'felt': properties['felt'] ?? 0,
        'tsunami': properties['tsunami'] ?? 0,
        'net': properties['net'] ?? 'us',
        'code': properties['code'] ?? '',
        'status': properties['status'] ?? 'reviewed',
      },
      affectedAreas: _calculateAffectedAreas(coordinates[1]?.toDouble() ?? 0.0, coordinates[0]?.toDouble() ?? 0.0, magnitude),
      isActive: (properties['status'] ?? 'reviewed') != 'deleted',
    );
  }

  factory DisasterEvent.fromNASAJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] ?? [];
    final coordinates = geometry.isNotEmpty ? geometry[0]['coordinates'] ?? [0, 0] : [0, 0];

    // Parse date from NASA EONET format
    DateTime eventDate = DateTime.now();
    try {
      if (json['geometry'] != null && json['geometry'].isNotEmpty) {
        final dateStr = json['geometry'][0]['date'];
        if (dateStr != null) {
          eventDate = DateTime.parse(dateStr);
        }
      }
    } catch (e) {
      print('Error parsing NASA date: $e');
    }

    return DisasterEvent(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? 'Wildfire Event',
      description: json['description'] ?? 'Natural event detected',
      type: DisasterType.wildfire,
      latitude: coordinates.length > 1 ? coordinates[1]?.toDouble() ?? 0.0 : 0.0,
      longitude: coordinates.length > 0 ? coordinates[0]?.toDouble() ?? 0.0 : 0.0,
      timestamp: eventDate,
      magnitude: 0.0, // NASA doesn't provide magnitude for wildfires
      location: _extractLocationFromTitle(json['title'] ?? ''),
      severity: _calculateWildfireSeverity(json),
      additionalData: {
        'categories': json['categories'] ?? [],
        'sources': json['sources'] ?? [],
        'closed': json['closed'],
        'link': json['link'],
      },
      affectedAreas: [_extractLocationFromTitle(json['title'] ?? '')],
      isActive: json['closed'] == null,
    );
  }

  factory DisasterEvent.fromMockData(Map<String, dynamic> data) {
    return DisasterEvent(
      id: data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: data['title'] ?? 'Mock Disaster Event',
      description: data['description'] ?? 'Mock disaster for testing',
      type: DisasterType.values[data['type'] ?? 0],
      latitude: data['latitude']?.toDouble() ?? 0.0,
      longitude: data['longitude']?.toDouble() ?? 0.0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch),
      magnitude: data['magnitude']?.toDouble() ?? 0.0,
      location: data['location'] ?? 'Mock Location',
      severity: SeverityLevel.values[data['severity'] ?? 0],
      additionalData: data['additionalData'] ?? {},
      affectedAreas: List<String>.from(data['affectedAreas'] ?? []),
      isActive: data['isActive'] ?? true,
    );
  }

  // Severity calculation methods
  static SeverityLevel _calculateEarthquakeSeverity(double magnitude) {
    if (magnitude >= 7.0) return SeverityLevel.critical;
    if (magnitude >= 6.0) return SeverityLevel.high;
    if (magnitude >= 4.0) return SeverityLevel.medium;
    return SeverityLevel.low;
  }

  static SeverityLevel _calculateWildfireSeverity(Map<String, dynamic> json) {
    // For NASA EONET wildfires, we determine severity based on categories and description
    final categories = json['categories'] ?? [];
    final title = (json['title'] ?? '').toLowerCase();

    if (title.contains('major') || title.contains('large') || title.contains('extreme')) {
      return SeverityLevel.critical;
    } else if (title.contains('significant') || title.contains('growing')) {
      return SeverityLevel.high;
    } else if (title.contains('moderate') || title.contains('contained')) {
      return SeverityLevel.medium;
    }
    return SeverityLevel.low;
  }

  static List<String> _calculateAffectedAreas(double lat, double lng, double magnitude) {
    // Simplified affected area calculation based on earthquake magnitude
    List<String> areas = [];
    if (magnitude >= 6.0) {
      areas.add('Regional impact');
    }
    if (magnitude >= 7.0) {
      areas.add('Multi-state impact');
    }
    if (magnitude >= 8.0) {
      areas.add('International impact');
    }
    return areas;
  }

  static String _extractLocationFromTitle(String title) {
    // Extract location from NASA EONET title format
    final parts = title.split(' - ');
    if (parts.length > 1) {
      return parts[1].trim();
    }
    return title;
  }

  // Convert to JSON for storage/transmission
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.index,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'magnitude': magnitude,
      'location': location,
      'severity': severity.index,
      'additionalData': additionalData,
      'imageUrl': imageUrl,
      'affectedAreas': affectedAreas,
      'isActive': isActive,
      'estimatedEnd': estimatedEnd?.millisecondsSinceEpoch,
    };
  }

  // Create from JSON
  factory DisasterEvent.fromJson(Map<String, dynamic> json) {
    return DisasterEvent(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: DisasterType.values[json['type'] ?? 0],
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
      magnitude: json['magnitude']?.toDouble() ?? 0.0,
      location: json['location'] ?? '',
      severity: SeverityLevel.values[json['severity'] ?? 0],
      additionalData: Map<String, dynamic>.from(json['additionalData'] ?? {}),
      imageUrl: json['imageUrl'],
      affectedAreas: List<String>.from(json['affectedAreas'] ?? []),
      isActive: json['isActive'] ?? true,
      estimatedEnd: json['estimatedEnd'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['estimatedEnd'])
          : null,
    );
  }

  // Generate KML for this disaster event
  String toKML() {
    final styleId = '${type.name}-${severity.name}';
    final description = _generateKMLDescription();

    return '''
<Placemark>
  <name><![CDATA[$title]]></name>
  <description><![CDATA[$description]]></description>
  <styleUrl>#$styleId</styleUrl>
  <Point>
    <coordinates>$longitude,$latitude,0</coordinates>
  </Point>
  <TimeStamp>
    <when>${timestamp.toIso8601String()}</when>
  </TimeStamp>
  <ExtendedData>
    <Data name="magnitude">
      <value>$magnitude</value>
    </Data>
    <Data name="severity">
      <value>${severity.displayName}</value>
    </Data>
    <Data name="type">
      <value>${type.displayName}</value>
    </Data>
    <Data name="isActive">
      <value>$isActive</value>
    </Data>
  </ExtendedData>
</Placemark>
''';
  }

  String _generateKMLDescription() {
    final buffer = StringBuffer();
    buffer.write('<div style="font-family: Arial, sans-serif; max-width: 400px;">');
    buffer.write('<h3 style="color: ${_getSeverityColor()}; margin-bottom: 10px;">$title</h3>');
    buffer.write('<table style="width: 100%; border-collapse: collapse;">');

    buffer.write('<tr><td style="font-weight: bold; padding: 5px; border-bottom: 1px solid #ddd;">Type:</td><td style="padding: 5px; border-bottom: 1px solid #ddd;">${type.displayName}</td></tr>');
    buffer.write('<tr><td style="font-weight: bold; padding: 5px; border-bottom: 1px solid #ddd;">Location:</td><td style="padding: 5px; border-bottom: 1px solid #ddd;">$location</td></tr>');
    buffer.write('<tr><td style="font-weight: bold; padding: 5px; border-bottom: 1px solid #ddd;">Magnitude:</td><td style="padding: 5px; border-bottom: 1px solid #ddd;">$magnitude</td></tr>');
    buffer.write('<tr><td style="font-weight: bold; padding: 5px; border-bottom: 1px solid #ddd;">Severity:</td><td style="padding: 5px; border-bottom: 1px solid #ddd;">${severity.displayName}</td></tr>');
    buffer.write('<tr><td style="font-weight: bold; padding: 5px; border-bottom: 1px solid #ddd;">Time:</td><td style="padding: 5px; border-bottom: 1px solid #ddd;">${_formatDateTime(timestamp)}</td></tr>');
    buffer.write('<tr><td style="font-weight: bold; padding: 5px; border-bottom: 1px solid #ddd;">Status:</td><td style="padding: 5px; border-bottom: 1px solid #ddd;">${isActive ? 'Active' : 'Inactive'}</td></tr>');

    if (affectedAreas.isNotEmpty) {
      buffer.write('<tr><td style="font-weight: bold; padding: 5px; border-bottom: 1px solid #ddd;">Affected Areas:</td><td style="padding: 5px; border-bottom: 1px solid #ddd;">${affectedAreas.join(', ')}</td></tr>');
    }

    buffer.write('</table>');

    if (description.isNotEmpty) {
      buffer.write('<p style="margin-top: 10px; color: #555; font-size: 14px;">$description</p>');
    }

    buffer.write('</div>');
    return buffer.toString();
  }

  String _getSeverityColor() {
    switch (severity) {
      case SeverityLevel.critical:
        return '#dc3545';
      case SeverityLevel.high:
        return '#fd7e14';
      case SeverityLevel.medium:
        return '#ffc107';
      case SeverityLevel.low:
        return '#28a745';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

enum DisasterType {
  earthquake,
  hurricane,
  wildfire,
  flood;

  String get displayName {
    switch (this) {
      case DisasterType.earthquake:
        return 'Earthquake';
      case DisasterType.hurricane:
        return 'Hurricane';
      case DisasterType.wildfire:
        return 'Wildfire';
      case DisasterType.flood:
        return 'Flood';
    }
  }

  String get iconName {
    switch (this) {
      case DisasterType.earthquake:
        return 'earthquake';
      case DisasterType.hurricane:
        return 'cyclone';
      case DisasterType.wildfire:
        return 'fire';
      case DisasterType.flood:
        return 'water';
    }
  }
}

enum SeverityLevel {
  low,
  medium,
  high,
  critical;

  String get displayName {
    switch (this) {
      case SeverityLevel.low:
        return 'Low';
      case SeverityLevel.medium:
        return 'Medium';
      case SeverityLevel.high:
        return 'High';
      case SeverityLevel.critical:
        return 'Critical';
    }
  }
}
