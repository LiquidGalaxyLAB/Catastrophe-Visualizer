// lib/services/enhanced_kml_service.dart
// Week 4 Implementation: Complete Enhanced KML Service - CLEAN VERSION

import 'dart:math' as math;
import '../models/disaster_event.dart';

class EnhancedKmlService {
  static const String kmlNamespace = 'http://www.opengis.net/kml/2.2';
  static const String gxNamespace = 'http://www.google.com/kml/ext/2.2';

  /// Generate enhanced KML with real-time disaster data and advanced features
  static String generateRealTimeDisasterKML(List<DisasterEvent> disasters) {
    final buffer = StringBuffer();

    buffer.write(_generateEnhancedKMLHeader(disasters));
    buffer.write(_generateAdvancedStyles());
    buffer.write(_generateNetworkLink());

    final groupedDisasters = _groupDisastersByTypeAndSeverity(disasters);
    groupedDisasters.forEach((type, severityMap) {
      buffer.write(_generateEnhancedFolder(type, severityMap));
    });

    buffer.write(_generateRealTimeStatsOverlay(disasters));
    buffer.write(_generateTimeSlider(disasters));
    buffer.write(_generateKMLFooter());

    return buffer.toString();
  }

  /// Generate enhanced tour KML with advanced camera movements
  static String generateEnhancedTourKML(List<DisasterEvent> disasters) {
    if (disasters.isEmpty) return generateRealTimeDisasterKML([]);

    final buffer = StringBuffer();
    buffer.write(_generateEnhancedKMLHeader(disasters));
    buffer.write(_generateAdvancedStyles());

    final sortedDisasters = List<DisasterEvent>.from(disasters);
    sortedDisasters.sort((a, b) {
      final severityCompare = b.severity.index.compareTo(a.severity.index);
      if (severityCompare != 0) return severityCompare;
      return b.timestamp.compareTo(a.timestamp);
    });

    buffer.write('''
  <gx:Tour>
    <n>🌍 Global Catastrophe Tour</n>
    <description><![CDATA[
      Automated immersive tour of major global disasters.<br/>
      🎯 Focusing on ${math.min(sortedDisasters.length, 15)} most significant events<br/>
      ⏱️ Duration: ${math.min(sortedDisasters.length, 15) * 7} seconds
    ]]></description>
    <gx:Playlist>
''');

    for (int i = 0; i < sortedDisasters.length && i < 15; i++) {
      final disaster = sortedDisasters[i];
      final duration = disaster.severity == SeverityLevel.critical ? 6.0 : 4.0;
      final range = _getTourRange(disaster);

      buffer.write('''
      <gx:FlyTo>
        <gx:duration>$duration</gx:duration>
        <gx:flyToMode>smooth</gx:flyToMode>
        <LookAt>
          <longitude>${disaster.longitude}</longitude>
          <latitude>${disaster.latitude}</latitude>
          <altitude>0</altitude>
          <heading>0</heading>
          <tilt>60</tilt>
          <range>$range</range>
          <gx:altitudeMode>relativeToSeaFloor</gx:altitudeMode>
        </LookAt>
      </gx:FlyTo>
      <gx:Wait>
        <gx:duration>${disaster.severity == SeverityLevel.critical ? 4.0 : 2.0}</gx:duration>
      </gx:Wait>
''');
    }

    buffer.write('''
    </gx:Playlist>
  </gx:Tour>
  
  <Folder>
    <n>🎬 Tour Locations</n>
    <open>1</open>
    <description>Disasters featured in the automated tour</description>
''');

    for (final disaster in sortedDisasters.take(15)) {
      buffer.write(_generateEnhancedPlacemark(disaster));
    }

    buffer.write('  </Folder>\n');
    buffer.write(_generateKMLFooter());
    return buffer.toString();
  }

  /// Generate KML for a single disaster with enhanced details
  static String generateSingleDisasterKML(DisasterEvent disaster) {
    final buffer = StringBuffer();

    buffer.write('''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="$kmlNamespace" xmlns:gx="$gxNamespace">
<Document>
  <n>🎯 ${disaster.title}</n>
  <description><![CDATA[
    Detailed view of individual disaster event
  ]]></description>
  
''');

    buffer.write(_generateAdvancedIconStyle(disaster.type, disaster.severity));
    buffer.write(_generateEnhancedPlacemark(disaster));

    buffer.write('''
  <LookAt>
    <longitude>${disaster.longitude}</longitude>
    <latitude>${disaster.latitude}</latitude>
    <altitude>0</altitude>
    <heading>0</heading>
    <tilt>45</tilt>
    <range>${_getTourRange(disaster)}</range>
  </LookAt>
  
''');

    buffer.write(_generateKMLFooter());
    return buffer.toString();
  }

  /// Generate network link KML for auto-refresh functionality
  static String generateNetworkLinkKML(String updateUrl, int refreshInterval) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="$kmlNamespace">
<Document>
  <n>🔄 Catastrophe Visualizer - Live Updates</n>
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

  /// Generate KML with clustering for large datasets
  static String generateClusteredDisasterKML(List<DisasterEvent> disasters, {double clusterRadius = 100000}) {
    final clusters = _clusterDisasters(disasters, clusterRadius);
    final buffer = StringBuffer();

    buffer.write(_generateEnhancedKMLHeader(disasters));
    buffer.write(_generateAdvancedStyles());
    buffer.write(_generateClusterStyles());

    for (final cluster in clusters) {
      if (cluster.length == 1) {
        buffer.write(_generateEnhancedPlacemark(cluster.first));
      } else {
        buffer.write(_generateClusterPlacemark(cluster));
      }
    }

    buffer.write(_generateRealTimeStatsOverlay(disasters));
    buffer.write(_generateKMLFooter());

    return buffer.toString();
  }

  /// Generate comparison KML for multiple time periods
  static String generateComparisonKML(
      List<DisasterEvent> currentPeriod,
      List<DisasterEvent> previousPeriod,
      String currentLabel,
      String previousLabel,
      ) {
    final buffer = StringBuffer();

    buffer.write('''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="$kmlNamespace" xmlns:gx="$gxNamespace">
<Document>
  <n>📊 Disaster Comparison: $currentLabel vs $previousLabel</n>
  <description><![CDATA[
    Comparative analysis of disaster events between different time periods
  ]]></description>
  <open>1</open>
  
''');

    buffer.write(_generateAdvancedStyles());
    buffer.write(_generateComparisonStyles());

    buffer.write('''
  <Folder>
    <n>🔵 $currentLabel (${currentPeriod.length} events)</n>
    <open>1</open>
    <styleUrl>#current-period-folder</styleUrl>
''');

    for (final disaster in currentPeriod) {
      buffer.write(_generateComparisonPlacemark(disaster, 'current'));
    }

    buffer.write('  </Folder>\n');

    buffer.write('''
  <Folder>
    <n>🔴 $previousLabel (${previousPeriod.length} events)</n>
    <open>0</open>
    <styleUrl>#previous-period-folder</styleUrl>
''');

    for (final disaster in previousPeriod) {
      buffer.write(_generateComparisonPlacemark(disaster, 'previous'));
    }

    buffer.write('  </Folder>\n');
    buffer.write(_generateComparisonStatsOverlay(currentPeriod, previousPeriod, currentLabel, previousLabel));
    buffer.write(_generateKMLFooter());
    return buffer.toString();
  }

  // Private helper methods

  static String _generateEnhancedKMLHeader(List<DisasterEvent> disasters) {
    final activeCount = disasters.where((d) => d.isActive).length;
    final criticalCount = disasters.where((d) => d.severity == SeverityLevel.critical).length;
    final lastUpdate = DateTime.now().toIso8601String();

    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="$kmlNamespace" xmlns:gx="$gxNamespace">
<Document>
  <n><![CDATA[🌍 Catastrophe Visualizer - Real-Time Global Disaster Monitoring]]></n>
  <description><![CDATA[
    <div style="font-family: Arial, sans-serif; background: linear-gradient(135deg, #1e3c72, #2a5298); color: white; padding: 20px; border-radius: 10px;">
      <h2 style="margin: 0 0 15px 0; color: #ffffff;">🚨 Global Disaster Dashboard</h2>
      <div style="display: flex; justify-content: space-between; margin-bottom: 15px;">
        <div style="text-align: center;">
          <h3 style="margin: 0; color: #ffeb3b;">${disasters.length}</h3>
          <p style="margin: 0; font-size: 12px;">Total Events</p>
        </div>
        <div style="text-align: center;">
          <h3 style="margin: 0; color: #4caf50;">$activeCount</h3>
          <p style="margin: 0; font-size: 12px;">Active</p>
        </div>
        <div style="text-align: center;">
          <h3 style="margin: 0; color: #f44336;">$criticalCount</h3>
          <p style="margin: 0; font-size: 12px;">Critical</p>
        </div>
      </div>
      <hr style="border: 1px solid #ffffff50; margin: 15px 0;">
      <p style="margin: 0; font-size: 12px;">
        📡 <strong>Live Data Sources:</strong> USGS, NASA EONET, GDACS<br/>
        🕒 <strong>Last Updated:</strong> $lastUpdate<br/>
        🖥️ <strong>Optimized for:</strong> Liquid Galaxy Multi-Screen Display
      </p>
    </div>
  ]]></description>
  <open>1</open>
  
  <LookAt>
    <longitude>0</longitude>
    <latitude>20</latitude>
    <altitude>0</altitude>
    <heading>0</heading>
    <tilt>0</tilt>
    <range>15000000</range>
    <gx:altitudeMode>relativeToSeaFloor</gx:altitudeMode>
  </LookAt>
  
''';
  }

  static String _generateAdvancedStyles() {
    final buffer = StringBuffer();

    for (final type in DisasterType.values) {
      for (final severity in SeverityLevel.values) {
        buffer.write(_generateAdvancedIconStyle(type, severity));
      }
    }

    buffer.write('''
  <Style id="critical-animated">
    <IconStyle>
      <color>ff0000ff</color>
      <scale>2.0</scale>
      <Icon>
        <href>http://maps.google.com/mapfiles/kml/shapes/shaded_dot.png</href>
      </Icon>
      <hotSpot x="0.5" y="0.5" xunits="fraction" yunits="fraction"/>
    </IconStyle>
    <LabelStyle>
      <color>ffffffff</color>
      <scale>1.2</scale>
    </LabelStyle>
    <BalloonStyle>
      <bgColor>ff000080</bgColor>
      <textColor>ffffffff</textColor>
      <text><![CDATA[
        <div style="font-family: Arial; background: #d32f2f; color: white; padding: 15px; border-radius: 8px;">
          <h3 style="margin: 0 0 10px 0;">🚨 CRITICAL DISASTER ALERT</h3>
          \$[description]
        </div>
      ]]></text>
    </BalloonStyle>
  </Style>

  <Style id="disaster-folder">
    <ListStyle>
      <listItemType>checkHideChildren</listItemType>
      <ItemIcon>
        <state>open</state>
        <href>http://maps.google.com/mapfiles/kml/shapes/open-diamond.png</href>
      </ItemIcon>
      <ItemIcon>
        <state>closed</state>
        <href>http://maps.google.com/mapfiles/kml/shapes/closed-diamond.png</href>
      </ItemIcon>
    </ListStyle>
  </Style>
  
''');

    return buffer.toString();
  }

  static String _generateAdvancedIconStyle(DisasterType type, SeverityLevel severity) {
    final styleId = '${type.name}-${severity.name}';
    final color = _getSeverityColorKML(severity);
    final scale = _getSeverityScale(severity);
    final iconUrl = _getEnhancedDisasterIconUrl(type);

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
      <scale>0.9</scale>
    </LabelStyle>
    <BalloonStyle>
      <bgColor>ff2d2d2d</bgColor>
      <textColor>ffffffff</textColor>
      <text><![CDATA[
        <div style="font-family: Arial, sans-serif; max-width: 350px;">
          <div style="background: ${_getSeverityColorCSS(severity)}; padding: 10px; margin: -10px -10px 10px -10px; border-radius: 5px 5px 0 0;">
            <h3 style="margin: 0; color: white;">\$[name]</h3>
            <span style="font-size: 12px; opacity: 0.9;">${type.displayName} • ${severity.displayName} Severity</span>
          </div>
          \$[description]
        </div>
      ]]></text>
    </BalloonStyle>
  </Style>
  
''';
  }

  static String _generateNetworkLink() {
    return '''
  <NetworkLink>
    <n>🔄 Real-Time Disaster Feed</n>
    <visibility>0</visibility>
    <open>0</open>
    <description>Automatic updates every 5 minutes</description>
    <refreshVisibility>0</refreshVisibility>
    <flyToView>0</flyToView>
    <Link>
      <href>http://localhost/disaster_data.kml</href>
      <refreshMode>onInterval</refreshMode>
      <refreshInterval>300</refreshInterval>
      <viewRefreshMode>never</viewRefreshMode>
    </Link>
  </NetworkLink>
  
''';
  }

  static Map<DisasterType, Map<SeverityLevel, List<DisasterEvent>>> _groupDisastersByTypeAndSeverity(
      List<DisasterEvent> disasters) {
    final grouped = <DisasterType, Map<SeverityLevel, List<DisasterEvent>>>{};

    for (final disaster in disasters) {
      grouped.putIfAbsent(disaster.type, () => {});
      grouped[disaster.type]!
          .putIfAbsent(disaster.severity, () => [])
          .add(disaster);
    }

    return grouped;
  }

  static String _generateEnhancedFolder(
      DisasterType type, Map<SeverityLevel, List<DisasterEvent>> severityMap) {
    final buffer = StringBuffer();
    final totalCount = severityMap.values.fold(0, (sum, list) => sum + list.length);
    final criticalCount = severityMap[SeverityLevel.critical]?.length ?? 0;
    final activeCount = severityMap.values
        .expand((list) => list)
        .where((d) => d.isActive)
        .length;

    buffer.write('''
  <Folder>
    <n>${_getDisasterEmoji(type)} ${type.displayName} ($totalCount)</n>
    <open>1</open>
    <styleUrl>#disaster-folder</styleUrl>
    <description><![CDATA[
      <div style="font-family: Arial; background: #f5f5f5; padding: 15px; border-radius: 8px; color: #333;">
        <h4 style="margin: 0 0 10px 0; color: ${_getSeverityColorCSS(SeverityLevel.high)};">${type.displayName} Events</h4>
        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin-bottom: 10px;">
          <div style="text-align: center; padding: 8px; background: white; border-radius: 4px;">
            <strong style="color: #333;">$totalCount</strong><br/>
            <small>Total Events</small>
          </div>
          <div style="text-align: center; padding: 8px; background: white; border-radius: 4px;">
            <strong style="color: #4caf50;">$activeCount</strong><br/>
            <small>Active</small>
          </div>
        </div>
        ${criticalCount > 0 ? '<div style="background: #ffebee; padding: 8px; border-left: 4px solid #f44336; border-radius: 4px;"><strong>⚠️ $criticalCount Critical Events</strong></div>' : ''}
      </div>
    ]]></description>
    
''');

    severityMap.forEach((severity, disasters) {
      buffer.write(_generateSeveritySubfolder(type, severity, disasters));
    });

    buffer.write('  </Folder>\n\n');
    return buffer.toString();
  }

  static String _generateSeveritySubfolder(
      DisasterType type, SeverityLevel severity, List<DisasterEvent> disasters) {
    final buffer = StringBuffer();

    buffer.write('''
    <Folder>
      <n>${_getSeverityEmoji(severity)} ${severity.displayName} (${disasters.length})</n>
      <open>${severity == SeverityLevel.critical ? 1 : 0}</open>
      <description>
        ${severity.displayName} severity ${type.displayName} events
      </description>
      
''');

    for (final disaster in disasters) {
      buffer.write(_generateEnhancedPlacemark(disaster));
    }

    buffer.write('    </Folder>\n');
    return buffer.toString();
  }

  static String _generateEnhancedPlacemark(DisasterEvent disaster) {
    final styleId = disaster.severity == SeverityLevel.critical
        ? 'critical-animated'
        : '${disaster.type.name}-${disaster.severity.name}';

    final description = _generateEnhancedDescription(disaster);

    return '''
    <Placemark>
      <n><![CDATA[${_getDisasterEmoji(disaster.type)} ${disaster.title}]]></n>
      <description><![CDATA[$description]]></description>
      <styleUrl>#$styleId</styleUrl>
      <Point>
        <coordinates>${disaster.longitude},${disaster.latitude},0</coordinates>
      </Point>
      <TimeStamp>
        <when>${disaster.timestamp.toIso8601String()}</when>
      </TimeStamp>
      <ExtendedData>
        <Data name="id"><value>${disaster.id}</value></Data>
        <Data name="magnitude"><value>${disaster.magnitude}</value></Data>
        <Data name="severity"><value>${disaster.severity.displayName}</value></Data>
        <Data name="type"><value>${disaster.type.displayName}</value></Data>
        <Data name="isActive"><value>${disaster.isActive}</value></Data>
        <Data name="location"><value>${disaster.location}</value></Data>
        <Data name="timeAgo"><value>${_getTimeAgo(disaster.timestamp)}</value></Data>
      </ExtendedData>
    </Placemark>
    
''';
  }

  static String _generateEnhancedDescription(DisasterEvent disaster) {
    final timeAgo = _getTimeAgo(disaster.timestamp);
    final severityColor = _getSeverityColorCSS(disaster.severity);

    return '''
<div style="font-family: Arial, sans-serif; max-width: 400px; color: #333;">
  <div style="background: $severityColor; color: white; padding: 12px; margin: -10px -10px 15px -10px; border-radius: 5px 5px 0 0;">
    <h3 style="margin: 0 0 5px 0;">${disaster.title}</h3>
    <div style="font-size: 12px; opacity: 0.9;">
      ${disaster.type.displayName} • ${disaster.severity.displayName} • $timeAgo
    </div>
  </div>
  
  <table style="width: 100%; border-collapse: collapse; margin-bottom: 15px;">
    <tr>
      <td style="padding: 6px 8px; border-bottom: 1px solid #eee; font-weight: bold; width: 35%;">📍 Location:</td>
      <td style="padding: 6px 8px; border-bottom: 1px solid #eee;">${disaster.location}</td>
    </tr>
    <tr>
      <td style="padding: 6px 8px; border-bottom: 1px solid #eee; font-weight: bold;">📏 Magnitude:</td>
      <td style="padding: 6px 8px; border-bottom: 1px solid #eee;">${disaster.magnitude}</td>
    </tr>
    <tr>
      <td style="padding: 6px 8px; border-bottom: 1px solid #eee; font-weight: bold;">🕒 Time:</td>
      <td style="padding: 6px 8px; border-bottom: 1px solid #eee;">${_formatDateTime(disaster.timestamp)}</td>
    </tr>
    <tr>
      <td style="padding: 6px 8px; border-bottom: 1px solid #eee; font-weight: bold;">📊 Status:</td>
      <td style="padding: 6px 8px; border-bottom: 1px solid #eee;">
        <span style="background: ${disaster.isActive ? '#4caf50' : '#9e9e9e'}; color: white; padding: 2px 8px; border-radius: 12px; font-size: 11px;">
          ${disaster.isActive ? '🟢 ACTIVE' : '⚫ INACTIVE'}
        </span>
      </td>
    </tr>
    <tr>
      <td style="padding: 6px 8px; font-weight: bold;">🌐 Coordinates:</td>
      <td style="padding: 6px 8px;">${disaster.latitude.toStringAsFixed(4)}, ${disaster.longitude.toStringAsFixed(4)}</td>
    </tr>
  </table>

  ${disaster.description.isNotEmpty ? '<div style="background: #f5f5f5; padding: 10px; border-radius: 5px; margin-bottom: 10px;"><strong>Details:</strong><br/>${disaster.description}</div>' : ''}

  ${disaster.affectedAreas.isNotEmpty ? '<div style="margin-bottom: 10px;"><strong>🏘️ Affected Areas:</strong><br/>${disaster.affectedAreas.map((area) => '• $area').join('<br/>')}</div>' : ''}

  ${disaster.additionalData.isNotEmpty ? '<details style="margin-top: 10px;"><summary style="cursor: pointer; font-weight: bold;">📋 Additional Information</summary><div style="margin-top: 5px; font-size: 12px;">${disaster.additionalData.entries.map((e) => '<strong>${e.key}:</strong> ${e.value}').join('<br/>')}</div></details>' : ''}
</div>''';
  }

  static String _generateRealTimeStatsOverlay(List<DisasterEvent> disasters) {
    if (disasters.isEmpty) return '';

    final criticalCount = disasters.where((d) => d.severity == SeverityLevel.critical).length;
    final activeCount = disasters.where((d) => d.isActive).length;
    final recentCount = disasters.where((d) =>
    DateTime.now().difference(d.timestamp).inHours <= 24).length;

    return '''
  <ScreenOverlay>
    <n>📊 Real-Time Disaster Statistics</n>
    <Icon>
      <href></href>
    </Icon>
    <description><![CDATA[
      <div style="background: rgba(0,0,0,0.85); color: white; padding: 20px; font-family: Arial; border-radius: 10px; backdrop-filter: blur(5px);">
        <h3 style="margin: 0 0 15px 0; color: #ffeb3b;">🌍 Global Disaster Dashboard</h3>
        
        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px; margin-bottom: 15px;">
          <div style="text-align: center; background: rgba(255,255,255,0.1); padding: 10px; border-radius: 8px;">
            <h2 style="margin: 0; color: #2196f3;">${disasters.length}</h2>
            <p style="margin: 0; font-size: 12px;">Total Events</p>
          </div>
          <div style="text-align: center; background: rgba(255,255,255,0.1); padding: 10px; border-radius: 8px;">
            <h2 style="margin: 0; color: #4caf50;">$activeCount</h2>
            <p style="margin: 0; font-size: 12px;">Active</p>
          </div>
          <div style="text-align: center; background: rgba(255,255,255,0.1); padding: 10px; border-radius: 8px;">
            <h2 style="margin: 0; color: #f44336;">$criticalCount</h2>
            <p style="margin: 0; font-size: 12px;">Critical</p>
          </div>
          <div style="text-align: center; background: rgba(255,255,255,0.1); padding: 10px; border-radius: 8px;">
            <h2 style="margin: 0; color: #ff9800;">$recentCount</h2>
            <p style="margin: 0; font-size: 12px;">Last 24h</p>
          </div>
        </div>
        
        <div style="font-size: 11px; opacity: 0.8; text-align: center;">
          🕒 Live Updates • 📡 Multi-Source Data • 🖥️ Liquid Galaxy Optimized
        </div>
      </div>
    ]]></description>
    <overlayXY x="0" y="1" xunits="fraction" yunits="fraction"/>
    <screenXY x="10" y="-10" xunits="pixels" yunits="pixels"/>
    <size x="320" y="200" xunits="pixels" yunits="pixels"/>
  </ScreenOverlay>
  
''';
  }

  static String _generateTimeSlider(List<DisasterEvent> disasters) {
    if (disasters.isEmpty) return '';

    final oldestEvent = disasters.map((d) => d.timestamp).reduce((a, b) => a.isBefore(b) ? a : b);
    final newestEvent = disasters.map((d) => d.timestamp).reduce((a, b) => a.isAfter(b) ? a : b);

    return '''
  <gx:TimeSpan>
    <begin>${oldestEvent.toIso8601String()}</begin>
    <end>${newestEvent.toIso8601String()}</end>
  </gx:TimeSpan>
  
''';
  }

  static String _generateKMLFooter() {
    return '''
</Document>
</kml>''';
  }

  // Clustering methods
  static String _generateClusterStyles() {
    return '''
  <Style id="cluster-normal">
    <IconStyle>
      <color>ff00ffff</color>
      <scale>1.5</scale>
      <Icon>
        <href>http://maps.google.com/mapfiles/kml/shapes/placemark_circle.png</href>
      </Icon>
    </IconStyle>
    <LabelStyle>
      <color>ffffffff</color>
      <scale>1.0</scale>
    </LabelStyle>
  </Style>
  <Style id="cluster-critical">
    <IconStyle>
      <color>ff0000ff</color>
      <scale>2.0</scale>
      <Icon>
        <href>http://maps.google.com/mapfiles/kml/shapes/placemark_circle.png</href>
      </Icon>
    </IconStyle>
    <LabelStyle>
      <color>ffffffff</color>
      <scale>1.2</scale>
    </LabelStyle>
  </Style>
  
''';
  }

  static List<List<DisasterEvent>> _clusterDisasters(List<DisasterEvent> disasters, double radius) {
    final clusters = <List<DisasterEvent>>[];
    final processed = <bool>[];

    for (int i = 0; i < disasters.length; i++) {
      processed.add(false);
    }

    for (int i = 0; i < disasters.length; i++) {
      if (processed[i]) continue;

      final cluster = <DisasterEvent>[disasters[i]];
      processed[i] = true;

      for (int j = i + 1; j < disasters.length; j++) {
        if (processed[j]) continue;

        final distance = _calculateDistance(
          disasters[i].latitude, disasters[i].longitude,
          disasters[j].latitude, disasters[j].longitude,
        );

        if (distance <= radius) {
          cluster.add(disasters[j]);
          processed[j] = true;
        }
      }

      clusters.add(cluster);
    }

    return clusters;
  }

  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) * math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  static String _generateClusterPlacemark(List<DisasterEvent> cluster) {
    final centerLat = cluster.map((d) => d.latitude).reduce((a, b) => a + b) / cluster.length;
    final centerLon = cluster.map((d) => d.longitude).reduce((a, b) => a + b) / cluster.length;
    final criticalCount = cluster.where((d) => d.severity == SeverityLevel.critical).length;

    final styleId = criticalCount > 0 ? 'cluster-critical' : 'cluster-normal';

    return '''
    <Placemark>
      <n><![CDATA[📍 Cluster: ${cluster.length} Events]]></n>
      <description><![CDATA[
        <div style="font-family: Arial; max-width: 300px;">
          <h4>Disaster Cluster (${cluster.length} events)</h4>
          <ul>
            ${cluster.map((d) => '<li>${d.title} (${d.severity.displayName})</li>').join('')}
          </ul>
        </div>
      ]]></description>
      <styleUrl>#$styleId</styleUrl>
      <Point>
        <coordinates>$centerLon,$centerLat,0</coordinates>
      </Point>
    </Placemark>
    
''';
  }

  // Comparison methods
  static String _generateComparisonStyles() {
    return '''
  <Style id="current-period">
    <IconStyle>
      <color>ffff0000</color>
      <scale>1.2</scale>
    </IconStyle>
  </Style>
  <Style id="previous-period">
    <IconStyle>
      <color>ff0000ff</color>
      <scale>1.0</scale>
    </IconStyle>
  </Style>
  <Style id="current-period-folder">
    <ListStyle>
      <listItemType>checkHideChildren</listItemType>
    </ListStyle>
  </Style>
  <Style id="previous-period-folder">
    <ListStyle>
      <listItemType>checkHideChildren</listItemType>
    </ListStyle>
  </Style>
  
''';
  }

  static String _generateComparisonPlacemark(DisasterEvent disaster, String period) {
    return '''
    <Placemark>
      <n><![CDATA[${disaster.title}]]></n>
      <description><![CDATA[${_generateEnhancedDescription(disaster)}]]></description>
      <styleUrl>#$period-period</styleUrl>
      <Point>
        <coordinates>${disaster.longitude},${disaster.latitude},0</coordinates>
      </Point>
    </Placemark>
    
''';
  }

  static String _generateComparisonStatsOverlay(
      List<DisasterEvent> current,
      List<DisasterEvent> previous,
      String currentLabel,
      String previousLabel,
      ) {
    final currentCritical = current.where((d) => d.severity == SeverityLevel.critical).length;
    final previousCritical = previous.where((d) => d.severity == SeverityLevel.critical).length;
    final change = previous.isNotEmpty
        ? ((current.length - previous.length) / previous.length * 100).toStringAsFixed(1)
        : '0.0';

    return '''
  <ScreenOverlay>
    <n>📊 Comparison Statistics</n>
    <Icon><href></href></Icon>
    <description><![CDATA[
      <div style="background: rgba(0,0,0,0.8); color: white; padding: 15px; font-family: Arial;">
        <h3>Period Comparison</h3>
        <table style="color: white; width: 100%;">
          <tr><td>$currentLabel:</td><td>${current.length} events</td></tr>
          <tr><td>$previousLabel:</td><td>${previous.length} events</td></tr>
          <tr><td>Change:</td><td>$change%</td></tr>
          <tr><td>Critical ($currentLabel):</td><td>$currentCritical</td></tr>
          <tr><td>Critical ($previousLabel):</td><td>$previousCritical</td></tr>
        </table>
      </div>
    ]]></description>
    <overlayXY x="1" y="1" xunits="fraction" yunits="fraction"/>
    <screenXY x="-10" y="-10" xunits="pixels" yunits="pixels"/>
    <size x="250" y="150" xunits="pixels" yunits="pixels"/>
  </ScreenOverlay>
  
''';
  }

  // Helper methods
  static String _getSeverityColorKML(SeverityLevel severity) {
    switch (severity) {
      case SeverityLevel.critical: return 'ff0000ff'; // Red
      case SeverityLevel.high: return 'ff0080ff';     // Orange
      case SeverityLevel.medium: return 'ff00ffff';   // Yellow
      case SeverityLevel.low: return 'ff00ff00';      // Green
    }
  }

  static String _getSeverityColorCSS(SeverityLevel severity) {
    switch (severity) {
      case SeverityLevel.critical: return '#d32f2f';
      case SeverityLevel.high: return '#f57c00';
      case SeverityLevel.medium: return '#fbc02d';
      case SeverityLevel.low: return '#388e3c';
    }
  }

  static double _getSeverityScale(SeverityLevel severity) {
    switch (severity) {
      case SeverityLevel.critical: return 2.0;
      case SeverityLevel.high: return 1.5;
      case SeverityLevel.medium: return 1.2;
      case SeverityLevel.low: return 1.0;
    }
  }

  static String _getEnhancedDisasterIconUrl(DisasterType type) {
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

  static String _getDisasterEmoji(DisasterType type) {
    switch (type) {
      case DisasterType.earthquake: return '🌍';
      case DisasterType.hurricane: return '🌀';
      case DisasterType.wildfire: return '🔥';
      case DisasterType.flood: return '🌊';
    }
  }

  static String _getSeverityEmoji(SeverityLevel severity) {
    switch (severity) {
      case SeverityLevel.critical: return '🔴';
      case SeverityLevel.high: return '🟠';
      case SeverityLevel.medium: return '🟡';
      case SeverityLevel.low: return '🟢';
    }
  }

  static double _getTourRange(DisasterEvent disaster) {
    switch (disaster.severity) {
      case SeverityLevel.critical: return 50000;
      case SeverityLevel.high: return 100000;
      case SeverityLevel.medium: return 200000;
      case SeverityLevel.low: return 300000;
    }
  }

  static String _getTimeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
