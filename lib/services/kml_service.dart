import '../models/disaster_event.dart';

class KmlService {
  static String generateKMLHeader() {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
<Document>
  <name>Catastrophe Visualizer</name>
  <description>Real-time global disaster monitoring</description>
  
  <!-- Earthquake Style -->
  <Style id="earthquake-critical">
    <IconStyle>
      <color>ff0000ff</color>
      <scale>1.5</scale>
      <Icon>
        <href>http://maps.google.com/mapfiles/kml/shapes/earthquake.png</href>
      </Icon>
    </IconStyle>
  </Style>
  
  <Style id="earthquake-high">
    <IconStyle>
      <color>ff0080ff</color>
      <scale>1.3</scale>
      <Icon>
        <href>http://maps.google.com/mapfiles/kml/shapes/earthquake.png</href>
      </Icon>
    </IconStyle>
  </Style>
  
  <Style id="earthquake-medium">
    <IconStyle>
      <color>ff00ffff</color>
      <scale>1.1</scale>
      <Icon>
        <href>http://maps.google.com/mapfiles/kml/shapes/earthquake.png</href>
      </Icon>
    </IconStyle>
  </Style>
  
  <Style id="earthquake-low">
    <IconStyle>
      <color>ff00ff00</color>
      <scale>1.0</scale>
      <Icon>
        <href>http://maps.google.com/mapfiles/kml/shapes/earthquake.png</href>
      </Icon>
    </IconStyle>
  </Style>
  
  <!-- Hurricane Styles -->
  <Style id="hurricane-critical">
    <IconStyle>
      <color>ff0000ff</color>
      <scale>1.5</scale>
      <Icon>
        <href>http://maps.google.com/mapfiles/kml/shapes/cyclone.png</href>
      </Icon>
    </IconStyle>
  </Style>
  
  <!-- Wildfire Styles -->
  <Style id="wildfire-critical">
    <IconStyle>
      <color>ff0000ff</color>
      <scale>1.5</scale>
      <Icon>
        <href>http://maps.google.com/mapfiles/kml/shapes/fire.png</href>
      </Icon>
    </IconStyle>
  </Style>
  
  <!-- Flood Styles -->
  <Style id="flood-critical">
    <IconStyle>
      <color>ff0000ff</color>
      <scale>1.5</scale>
      <Icon>
        <href>http://maps.google.com/mapfiles/kml/shapes/water.png</href>
      </Icon>
    </IconStyle>
  </Style>
''';
  }

  static String generateKMLFooter() {
    return '''
</Document>
</kml>''';
  }

  static String generateDisasterKML(List<DisasterEvent> disasters) {
    final buffer = StringBuffer();
    buffer.write(generateKMLHeader());

    // Group disasters by type
    final earthquakes = disasters.where((d) => d.type == DisasterType.earthquake).toList();
    final hurricanes = disasters.where((d) => d.type == DisasterType.hurricane).toList();
    final wildfires = disasters.where((d) => d.type == DisasterType.wildfire).toList();
    final floods = disasters.where((d) => d.type == DisasterType.flood).toList();

    // Add folders for each disaster type
    if (earthquakes.isNotEmpty) {
      buffer.write(_generateFolder('Earthquakes', earthquakes));
    }

    if (hurricanes.isNotEmpty) {
      buffer.write(_generateFolder('Hurricanes', hurricanes));
    }

    if (wildfires.isNotEmpty) {
      buffer.write(_generateFolder('Wildfires', wildfires));
    }

    if (floods.isNotEmpty) {
      buffer.write(_generateFolder('Floods', floods));
    }

    buffer.write(generateKMLFooter());
    return buffer.toString();
  }

  static String _generateFolder(String name, List<DisasterEvent> disasters) {
    final buffer = StringBuffer();
    buffer.write('<Folder>\n');
    buffer.write('<name>$name</name>\n');
    buffer.write('<open>1</open>\n');

    for (final disaster in disasters) {
      buffer.write(_generatePlacemark(disaster));
    }

    buffer.write('</Folder>\n');
    return buffer.toString();
  }

  static String _generatePlacemark(DisasterEvent disaster) {
    final styleId = '${disaster.type.name}-${disaster.severity.name}';

    return '''
<Placemark>
  <name><![CDATA[${disaster.title}]]></name>
  <description><![CDATA[
    <div style="font-family: Arial, sans-serif;">
      <h3 style="color: #2c3e50; margin-bottom: 10px;">${disaster.title}</h3>
      <table style="width: 100%; border-collapse: collapse;">
        <tr><td style="font-weight: bold; padding: 5px;">Type:</td><td style="padding: 5px;">${disaster.type.displayName}</td></tr>
        <tr><td style="font-weight: bold; padding: 5px;">Location:</td><td style="padding: 5px;">${disaster.location}</td></tr>
        <tr><td style="font-weight: bold; padding: 5px;">Magnitude:</td><td style="padding: 5px;">${disaster.magnitude}</td></tr>
        <tr><td style="font-weight: bold; padding: 5px;">Severity:</td><td style="padding: 5px;">${disaster.severity.displayName}</td></tr>
        <tr><td style="font-weight: bold; padding: 5px;">Time:</td><td style="padding: 5px;">${_formatDateTime(disaster.timestamp)}</td></tr>
      </table>
      <p style="margin-top: 10px; color: #555;">${disaster.description}</p>
    </div>
  ]]></description>
  <styleUrl>#$styleId</styleUrl>
  <Point>
    <coordinates>${disaster.longitude},${disaster.latitude},0</coordinates>
  </Point>
  <TimeStamp>
    <when>${disaster.timestamp.toIso8601String()}</when>
  </TimeStamp>
</Placemark>
''';
  }

  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Generate network link KML for real-time updates
  static String generateNetworkLinkKML(String updateUrl, int refreshInterval) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
<Document>
  <name>Catastrophe Visualizer - Live Updates</name>
  <NetworkLink>
    <name>Live Disaster Data</name>
    <open>1</open>
    <Link>
      <href>$updateUrl</href>
      <refreshMode>onInterval</refreshMode>
      <refreshInterval>$refreshInterval</refreshInterval>
    </Link>
  </NetworkLink>
</Document>
</kml>''';
  }
}