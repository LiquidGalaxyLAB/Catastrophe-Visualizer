import '../models/disaster_event.dart';

class KmlService {
  static const String kmlNamespace = 'http://www.opengis.net/kml/2.2';
  static const String gxNamespace = 'http://www.google.com/kml/ext/2.2';

  // Generate complete KML document with styles and data
  static String generateDisasterKML(List<DisasterEvent> disasters) {
    final buffer = StringBuffer();

    // KML Header
    buffer.write(_generateKMLHeader());

    // Styles
    buffer.write(_generateStyles());

    // Group disasters by type for better organization
    final earthquakes = disasters.where((d) => d.type == DisasterType.earthquake).toList();
    final hurricanes = disasters.where((d) => d.type == DisasterType.hurricane).toList();
    final wildfires = disasters.where((d) => d.type == DisasterType.wildfire).toList();
    final floods = disasters.where((d) => d.type == DisasterType.flood).toList();

    // Generate folders for each disaster type
    if (earthquakes.isNotEmpty) {
      buffer.write(_generateFolder('Earthquakes 🌍', earthquakes, 'earthquake'));
    }

    if (hurricanes.isNotEmpty) {
      buffer.write(_generateFolder('Hurricanes 🌀', hurricanes, 'hurricane'));
    }

    if (wildfires.isNotEmpty) {
      buffer.write(_generateFolder('Wildfires 🔥', wildfires, 'wildfire'));
    }

    if (floods.isNotEmpty) {
      buffer.write(_generateFolder('Floods 🌊', floods, 'flood'));
    }

    // Summary statistics overlay
    buffer.write(_generateSummaryOverlay(disasters));

    // KML Footer
    buffer.write(_generateKMLFooter());

    return buffer.toString();
  }

  static String _generateKMLHeader() {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="$kmlNamespace" xmlns:gx="$gxNamespace">
<Document>
  <name>Catastrophe Visualizer - Global Disaster Monitoring</name>
  <description><![CDATA[
    Real-time global disaster visualization system.<br/>
    Generated on: ${DateTime.now().toIso8601String()}<br/>
    Source: USGS, NASA EONET, and other disaster monitoring APIs
  ]]></description>
  <open>1</open>
  
  <LookAt>
    <longitude>0</longitude>
    <latitude>20</latitude>
    <altitude>0</altitude>
    <heading>0</heading>
    <tilt>0</tilt>
    <range>15000000</range>
  </LookAt>
  
''';
  }

  static String _generateStyles() {
    final buffer = StringBuffer();

    // Earthquake styles
    for (final severity in SeverityLevel.values) {
      buffer.write(_generateIconStyle('earthquake', severity));
    }

    // Hurricane styles
    for (final severity in SeverityLevel.values) {
      buffer.write(_generateIconStyle('hurricane', severity));
    }

    // Wildfire styles
    for (final severity in SeverityLevel.values) {
      buffer.write(_generateIconStyle('wildfire', severity));
    }

    // Flood styles
    for (final severity in SeverityLevel.values) {
      buffer.write(_generateIconStyle('flood', severity));
    }

    // Folder styles
    buffer.write('''
  <Style id="folder-style">
    <ListStyle>
      <listItemType>checkHideChildren</listItemType>
    </ListStyle>
  </Style>
  
''');

    return buffer.toString();
  }

  static String _generateIconStyle(String disasterType, SeverityLevel severity) {
    final styleId = '$disasterType-${severity.name}';
    final color = _getSeverityColorKML(severity);
    final scale = _getSeverityScale(severity);
    final iconUrl = _getDisasterIconUrl(disasterType);

    return '''
  <Style id="$styleId">
    <IconStyle>
      <color>$color</color>
      <scale>$scale</scale>
      <Icon>
        <href>$iconUrl</href>
      </Icon>
      <hotSpot x="0.5" y="0" xunits="fraction" yunits="fraction"/>
    </IconStyle>
    <LabelStyle>
      <color>ffffffff</color>
      <scale>0.8</scale>
    </LabelStyle>
    <BalloonStyle>
      <bgColor>ff1e1e1e</bgColor>
      <textColor>ffffffff</textColor>
    </BalloonStyle>
  </Style>
  
''';
  }

  static String _getSeverityColorKML(SeverityLevel severity) {
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

  static double _getSeverityScale(SeverityLevel severity) {
    switch (severity) {
      case SeverityLevel.critical:
        return 1.5;
      case SeverityLevel.high:
        return 1.3;
      case SeverityLevel.medium:
        return 1.1;
      case SeverityLevel.low:
        return 1.0;
    }
  }

  static String _getDisasterIconUrl(String disasterType) {
    switch (disasterType) {
      case 'earthquake':
        return 'http://maps.google.com/mapfiles/kml/shapes/earthquake.png';
      case 'hurricane':
        return 'http://maps.google.com/mapfiles/kml/shapes/cyclone.png';
      case 'wildfire':
        return 'http://maps.google.com/mapfiles/kml/shapes/fire.png';
      case 'flood':
        return 'http://maps.google.com/mapfiles/kml/shapes/water.png';
      default:
        return 'http://maps.google.com/mapfiles/kml/shapes/placemark_circle.png';
    }
  }

  static String _generateFolder(String name, List<DisasterEvent> disasters, String type) {
    final buffer = StringBuffer();
    buffer.write('''
  <Folder>
    <n>$name (${disasters.length})</n>
    <open>1</open>
    <styleUrl>#folder-style</styleUrl>
    <description><![CDATA[
      <b>Total Events:</b> ${disasters.length}<br/>
      <b>Critical:</b> ${disasters.where((d) => d.severity == SeverityLevel.critical).length}<br/>
      <b>High:</b> ${disasters.where((d) => d.severity == SeverityLevel.high).length}<br/>
      <b>Medium:</b> ${disasters.where((d) => d.severity == SeverityLevel.medium).length}<br/>
      <b>Low:</b> ${disasters.where((d) => d.severity == SeverityLevel.low).length}
    ]]></description>
    
''');

    // Add each disaster as a placemark
    for (final disaster in disasters) {
      buffer.write(_generatePlacemark(disaster));
    }

    buffer.write('  </Folder>\n\n');
    return buffer.toString();
  }

  static String _generatePlacemark(DisasterEvent disaster) {
    final styleId = '${disaster.type.name}-${disaster.severity.name}';
    final description = disaster._generateKMLDescription();

    return '''
    <Placemark>
      <n><![CDATA[${disaster.title}]]></n>
      <description><![CDATA[$description]]></description>
      <styleUrl>#$styleId</styleUrl>
      <Point>
        <coordinates>${disaster.longitude},${disaster.latitude},0</coordinates>
      </Point>
      <TimeStamp>
        <when>${disaster.timestamp.toIso8601String()}</when>
      </TimeStamp>
      <ExtendedData>
        <Data name="id">
          <value>${disaster.id}</value>
        </Data>
        <Data name="magnitude">
          <value>${disaster.magnitude}</value>
        </Data>
        <Data name="severity">
          <value>${disaster.severity.displayName}</value>
        </Data>
        <Data name="type">
          <value>${disaster.type.displayName}</value>
        </Data>
        <Data name="isActive">
          <value>${disaster.isActive}</value>
        </Data>
        <Data name="location">
          <value>${disaster.location}</value>
        </Data>
      </ExtendedData>
    </Placemark>
    
''';
  }

  static String _generateSummaryOverlay(List<DisasterEvent> disasters) {
    if (disasters.isEmpty) return '';

    final criticalCount = disasters.where((d) => d.severity == SeverityLevel.critical).length;
    final highCount = disasters.where((d) => d.severity == SeverityLevel.high).length;
    final totalActive = disasters.where((d) => d.isActive).length;

    return '''
  <ScreenOverlay>
    <n>Disaster Summary</n>
    <Icon>
      <href></href>
    </Icon>
    <description><![CDATA[
      <div style="background: rgba(0,0,0,0.8); color: white; padding: 10px; font-family: Arial;">
        <h3>Global Disaster Status</h3>
        <p><b>Total Events:</b> ${disasters.length}</p>
        <p><b>Active Events:</b> $totalActive</p>
        <p><b>Critical:</b> $criticalCount</p>
        <p><b>High Risk:</b> $highCount</p>
        <p><small>Last Updated: ${DateTime.now().toIso8601String()}</small></p>
      </div>
    ]]></description>
    <overlayXY x="0" y="1" xunits="fraction" yunits="fraction"/>
    <screenXY x="0" y="1" xunits="fraction" yunits="fraction"/>
    <size x="300" y="150" xunits="pixels" yunits="pixels"/>
  </ScreenOverlay>
  
''';
  }

  static String _generateKMLFooter() {
    return '''
</Document>
</kml>''';
  }

  // Generate network link KML for auto-refresh
  static String generateNetworkLinkKML(String updateUrl, int refreshInterval) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="$kmlNamespace">
<Document>
  <n>Catastrophe Visualizer - Live Updates</n>
  <description>Auto-refreshing disaster data feed</description>
  <NetworkLink>
    <n>Live Disaster Data</n>
    <open>1</open>
    <refreshVisibility>0</refreshVisibility>
    <flyToView>0</flyToView>
    <Link>
      <href>$updateUrl</href>
      <refreshMode>onInterval</refreshMode>
      <refreshInterval>$refreshInterval</refreshInterval>
      <viewRefreshMode>never</viewRefreshMode>
    </Link>
  </NetworkLink>
</Document>
</kml>''';
  }

  // Generate tour KML for disaster flyover
  static String generateDisasterTourKML(List<DisasterEvent> disasters) {
    if (disasters.isEmpty) return generateDisasterKML([]);

    final buffer = StringBuffer();
    buffer.write(_generateKMLHeader());
    buffer.write(_generateStyles());

    // Sort by severity for tour
    final sortedDisasters = List<DisasterEvent>.from(disasters);
    sortedDisasters.sort((a, b) => b.severity.index.compareTo(a.severity.index));

    buffer.write('''
  <gx:Tour>
    <n>Global Disaster Tour</n>
    <description>Automated tour of major disaster events</description>
    <gx:Playlist>
''');

    for (int i = 0; i < sortedDisasters.length && i < 10; i++) {
      final disaster = sortedDisasters[i];
      buffer.write('''
      <gx:FlyTo>
        <gx:duration>4.0</gx:duration>
        <gx:flyToMode>smooth</gx:flyToMode>
        <LookAt>
          <longitude>${disaster.longitude}</longitude>
          <latitude>${disaster.latitude}</latitude>
          <altitude>0</altitude>
          <heading>0</heading>
          <tilt>45</tilt>
          <range>100000</range>
        </LookAt>
      </gx:FlyTo>
      <gx:Wait>
        <gx:duration>3.0</gx:duration>
      </gx:Wait>
''');
    }

    buffer.write('''
    </gx:Playlist>
  </gx:Tour>
  
''');

    // Add placemarks for visibility during tour
    for (final disaster in sortedDisasters.take(10)) {
      buffer.write(_generatePlacemark(disaster));
    }

    buffer.write(_generateKMLFooter());
    return buffer.toString();
  }
}



