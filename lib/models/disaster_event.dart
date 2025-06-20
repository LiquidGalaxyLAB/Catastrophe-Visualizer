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
  });

  factory DisasterEvent.fromJson(Map<String, dynamic> json, DisasterType type) {
    switch (type) {
      case DisasterType.earthquake:
        return DisasterEvent._fromUSGSJson(json);
      case DisasterType.hurricane:
        return DisasterEvent._fromGDACSJson(json);
      case DisasterType.wildfire:
        return DisasterEvent._fromNASAJson(json);
      case DisasterType.flood:
        return DisasterEvent._fromNOAAJson(json);
    }
  }

  factory DisasterEvent._fromUSGSJson(Map<String, dynamic> json) {
    final properties = json['properties'];
    final geometry = json['geometry'];
    final coordinates = geometry['coordinates'];

    return DisasterEvent(
      id: json['id'] ?? '',
      title: properties['title'] ?? 'Unknown Earthquake',
      description: properties['place'] ?? '',
      type: DisasterType.earthquake,
      latitude: coordinates[1]?.toDouble() ?? 0.0,
      longitude: coordinates[0]?.toDouble() ?? 0.0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(properties['time'] ?? 0),
      magnitude: properties['mag']?.toDouble() ?? 0.0,
      location: properties['place'] ?? 'Unknown Location',
      severity: _calculateEarthquakeSeverity(properties['mag']?.toDouble() ?? 0.0),
      additionalData: {
        'depth': coordinates[2]?.toDouble() ?? 0.0,
        'url': properties['url'] ?? '',
        'alert': properties['alert'] ?? '',
      },
    );
  }

  factory DisasterEvent._fromGDACSJson(Map<String, dynamic> json) {
    return DisasterEvent(
      id: json['id']?.toString() ?? '',
      title: json['name'] ?? 'Hurricane Event',
      description: json['description'] ?? '',
      type: DisasterType.hurricane,
      latitude: json['lat']?.toDouble() ?? 0.0,
      longitude: json['lon']?.toDouble() ?? 0.0,
      timestamp: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      magnitude: json['severity']?.toDouble() ?? 0.0,
      location: json['country'] ?? 'Unknown Location',
      severity: _calculateHurricaneSeverity(json['severity']?.toDouble() ?? 0.0),
      additionalData: {
        'windSpeed': json['windSpeed'] ?? 0,
        'category': json['category'] ?? '',
        'status': json['status'] ?? 'active',
      },
    );
  }

  factory DisasterEvent._fromNASAJson(Map<String, dynamic> json) {
    final geometry = json['geometry'];
    final coordinates = geometry?['coordinates'] ?? [0, 0];

    return DisasterEvent(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Wildfire Event',
      description: json['description'] ?? '',
      type: DisasterType.wildfire,
      latitude: coordinates[1]?.toDouble() ?? 0.0,
      longitude: coordinates[0]?.toDouble() ?? 0.0,
      timestamp: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      magnitude: json['brightness']?.toDouble() ?? 0.0,
      location: json['location'] ?? 'Unknown Location',
      severity: _calculateWildfireSeverity(json['brightness']?.toDouble() ?? 0.0),
      additionalData: {
        'brightness': json['brightness'] ?? 0,
        'scan': json['scan'] ?? 0,
        'track': json['track'] ?? 0,
        'frp': json['frp'] ?? 0, // Fire Radiative Power
      },
    );
  }

  factory DisasterEvent._fromNOAAJson(Map<String, dynamic> json) {
    return DisasterEvent(
      id: json['id']?.toString() ?? '',
      title: json['event'] ?? 'Flood Event',
      description: json['description'] ?? '',
      type: DisasterType.flood,
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      timestamp: DateTime.tryParse(json['issued'] ?? '') ?? DateTime.now(),
      magnitude: json['severity']?.toDouble() ?? 0.0,
      location: json['areaDesc'] ?? 'Unknown Location',
      severity: _calculateFloodSeverity(json['severity']?.toDouble() ?? 0.0),
      additionalData: {
        'urgency': json['urgency'] ?? '',
        'certainty': json['certainty'] ?? '',
        'expires': json['expires'] ?? '',
      },
    );
  }

  static SeverityLevel _calculateEarthquakeSeverity(double magnitude) {
    if (magnitude >= 7.0) return SeverityLevel.critical;
    if (magnitude >= 6.0) return SeverityLevel.high;
    if (magnitude >= 4.0) return SeverityLevel.medium;
    return SeverityLevel.low;
  }

  static SeverityLevel _calculateHurricaneSeverity(double category) {
    if (category >= 4) return SeverityLevel.critical;
    if (category >= 3) return SeverityLevel.high;
    if (category >= 2) return SeverityLevel.medium;
    return SeverityLevel.low;
  }

  static SeverityLevel _calculateWildfireSeverity(double brightness) {
    if (brightness >= 400) return SeverityLevel.critical;
    if (brightness >= 350) return SeverityLevel.high;
    if (brightness >= 300) return SeverityLevel.medium;
    return SeverityLevel.low;
  }

  static SeverityLevel _calculateFloodSeverity(double severity) {
    if (severity >= 4) return SeverityLevel.critical;
    if (severity >= 3) return SeverityLevel.high;
    if (severity >= 2) return SeverityLevel.medium;
    return SeverityLevel.low;
  }

  String toKML() {
    final color = _getSeverityColor();
    final icon = _getDisasterIcon();

    return '''
<Placemark>
  <name>$title</name>
  <description><![CDATA[
    <h3>$title</h3>
    <p><b>Type:</b> ${type.displayName}</p>
    <p><b>Location:</b> $location</p>
    <p><b>Magnitude:</b> $magnitude</p>
    <p><b>Severity:</b> ${severity.displayName}</p>
    <p><b>Time:</b> ${timestamp.toIso8601String()}</p>
    <p><b>Description:</b> $description</p>
  ]]></description>
  <Point>
    <coordinates>$longitude,$latitude,0</coordinates>
  </Point>
  <Style>
    <IconStyle>
      <color>$color</color>
      <scale>1.2</scale>
      <Icon>
        <href>$icon</href>
      </Icon>
    </IconStyle>
  </Style>
</Placemark>
''';
  }

  String _getSeverityColor() {
    switch (severity) {
      case SeverityLevel.critical:
        return 'ff0000ff'; // Red
      case SeverityLevel.high:
        return 'ff0080ff'; // Orange
      case SeverityLevel.medium:
        return 'ff00ffff'; // Yellow
      case SeverityLevel.low:
        return 'ff00ff00'; // Green
    }
  }

  String _getDisasterIcon() {
    switch (type) {
      case DisasterType.earthquake:
        return 'http://maps.google.com/mapfiles/kml/shapes/earthquake.png';
      case DisasterType.hurricane:
        return 'http://maps.google.com/mapfiles/kml/shapes/cyclone.png';
      case DisasterType.wildfire:
        return 'http://maps.google.com/mapfiles/kml/shapes/fire.png';
      case DisasterType.flood:
        return 'http://maps.google.com/mapfiles/kml/shapes/water.png';
    }
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