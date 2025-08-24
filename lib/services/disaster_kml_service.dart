import 'dart:io';
import '../models/kml.dart';
import '../models/orbit.dart';
import '../models/look_at.dart';
import '../models/flyto.dart';
import '../models/disaster_model.dart';
import '../services/kml_generator.dart'; // Updated import
import '../services/lg_service.dart';

class DisasterKMLService {
  final LiquidGalaxySSHService _sshService;

  DisasterKMLService(this._sshService);

  /// Send disaster using the KML class
  Future<bool> sendDisasterKML(Disaster disaster) async {
    try {
      // Create disaster placemark content
      final disasterContent = '''
        <Placemark>
          <name>${disaster.title}</name>
          <description>
            Magnitude: ${disaster.magnitude.toStringAsFixed(1)}
            Severity: ${disaster.severity}
            Time: ${disaster.timestamp}
            Location: ${disaster.latitude.toStringAsFixed(4)}, ${disaster.longitude.toStringAsFixed(4)}
          </description>
          <Point>
            <coordinates>${disaster.longitude},${disaster.latitude},0</coordinates>
          </Point>
        </Placemark>
      ''';

      // Create KML using your KML class
      final kml = KML('Disaster Alert - ${disaster.title}', disasterContent);

      // Upload to LG
      final success = await _sshService.uploadKMLFile(
        kml.mount(),
        'disaster_${disaster.id}',
      );

      return success;
    } catch (e) {
      print('❌ Failed to send disaster KML: $e');
      return false;
    }
  }

  /// Create orbit around disaster location
  Future<bool> createDisasterOrbit(Disaster disaster) async {
    try {
      // Create LookAt for disaster location
      final lookAt = LookAt(
        disaster.longitude,
        disaster.latitude,
        '50000', // range
        '45',    // tilt
        '0',     // heading
      );

      // Generate orbit content
      final orbitContent = Orbit.generateOrbitTag(lookAt);
      final orbitKML = Orbit.buildOrbit(orbitContent);

      // Upload orbit to LG
      final success = await _sshService.uploadKMLFile(
        orbitKML,
        'orbit_${disaster.id}',
      );

      return success;
    } catch (e) {
      print('❌ Failed to create disaster orbit: $e');
      return false;
    }
  }

  /// Download KML to device using new SimpleKMLGenerator
  Future<File?> downloadDisasterKML(Disaster disaster) async {
    try {
      final disasterContent = '''
        <Placemark>
          <name>${disaster.title}</name>
          <description>
            Magnitude: ${disaster.magnitude.toStringAsFixed(1)}
            Severity: ${disaster.severity}
            Time: ${disaster.timestamp}
          </description>
          <Point>
            <coordinates>${disaster.longitude},${disaster.latitude},0</coordinates>
          </Point>
        </Placemark>
      ''';

      final kml = KML('Disaster - ${disaster.title}', disasterContent);

      // Use the new SimpleKMLGenerator instead of old KMLGenerator
      final file = await SimpleKMLGenerator.generateKML(
          kml.mount(),
          'disaster_${disaster.id}'
      );

      return file;
    } catch (e) {
      print('❌ Failed to download KML: $e');
      return null;
    }
  }

  /// Fly to disaster location
  Future<bool> flyToDisaster(Disaster disaster) async {
    try {
      final lookAt = LookAt(
        disaster.longitude,
        disaster.latitude,
        '25000',
        '45',
        '0',
      );

      final flyto = Flyto(lookAt);

      // Create simple flyto KML
      final flytoKML = '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
  <gx:Tour>
    <name>Fly to ${disaster.title}</name>
    <gx:Playlist>
      <gx:FlyTo>
        <gx:duration>3.0</gx:duration>
        <gx:flyToMode>smooth</gx:flyToMode>
        ${lookAt.generateTag()}
      </gx:FlyTo>
    </gx:Playlist>
  </gx:Tour>
</kml>
      ''';

      final success = await _sshService.uploadKMLFile(
        flytoKML,
        'flyto_${disaster.id}',
      );

      return success;
    } catch (e) {
      print('❌ Failed to fly to disaster: $e');
      return false;
    }
  }

  /// Save KML with download dialog (new feature)
  Future<bool> saveDisasterKMLWithDialog(Disaster disaster) async {
    try {
      final disasterContent = '''
        <Placemark>
          <name>${disaster.title}</name>
          <description><![CDATA[
            <h3>Disaster Report</h3>
            <p><strong>Type:</strong> ${disaster.type.toUpperCase()}</p>
            <p><strong>Magnitude:</strong> ${disaster.magnitude.toStringAsFixed(1)}</p>
            <p><strong>Severity:</strong> ${disaster.severity}</p>
            <p><strong>Time:</strong> ${disaster.timestamp}</p>
            <p><strong>Location:</strong> ${disaster.latitude.toStringAsFixed(4)}, ${disaster.longitude.toStringAsFixed(4)}</p>
            ${disaster.place != null ? '<p><strong>Place:</strong> ${disaster.place}</p>' : ''}
          ]]></description>
          <Point>
            <coordinates>${disaster.longitude},${disaster.latitude},0</coordinates>
          </Point>
        </Placemark>
      ''';

      final kml = KML('Disaster Report - ${disaster.title}', disasterContent);

      // Save with user-friendly dialog
      final file = await SimpleKMLGenerator.generateKML(
          kml.mount(),
          'disaster_report_${disaster.id}'
      );

      return file != null;
    } catch (e) {
      print('❌ Failed to save disaster KML: $e');
      return false;
    }
  }

  /// Get all saved disaster KML files
  Future<List<File>> getSavedDisasterKMLs() async {
    try {
      final allFiles = await SimpleKMLGenerator.getSavedKMLFiles();

      // Filter for disaster-related KML files
      final disasterFiles = allFiles
          .where((file) => file.path.contains('disaster'))
          .toList();

      return disasterFiles;
    } catch (e) {
      print('❌ Failed to get saved disaster KMLs: $e');
      return [];
    }
  }

  /// Delete saved disaster KML
  Future<bool> deleteSavedDisasterKML(File file) async {
    return await SimpleKMLGenerator.deleteKMLFile(file);
  }

  /// Create comprehensive disaster report KML
  Future<String> createDisasterReportKML(List<Disaster> disasters) async {
    try {
      String placemarks = '';

      for (int i = 0; i < disasters.length; i++) {
        final disaster = disasters[i];
        placemarks += '''
          <Placemark>
            <name>${disaster.title}</name>
            <description><![CDATA[
              <h3>Disaster #${i + 1}</h3>
              <p><strong>Type:</strong> ${disaster.type.toUpperCase()}</p>
              <p><strong>Magnitude:</strong> ${disaster.magnitude.toStringAsFixed(1)}</p>
              <p><strong>Severity:</strong> ${disaster.severity}</p>
              <p><strong>Time:</strong> ${disaster.timestamp}</p>
              <p><strong>Coordinates:</strong> ${disaster.latitude.toStringAsFixed(4)}, ${disaster.longitude.toStringAsFixed(4)}</p>
              ${disaster.place != null ? '<p><strong>Location:</strong> ${disaster.place}</p>' : ''}
            ]]></description>
            <Point>
              <coordinates>${disaster.longitude},${disaster.latitude},0</coordinates>
            </Point>
            <Style>
              <IconStyle>
                <color>${_getSeverityColor(disaster.severity)}</color>
                <scale>1.2</scale>
              </IconStyle>
            </Style>
          </Placemark>
        ''';
      }

      final reportKML = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Disaster Report - ${disasters.length} Events</name>
    <description>Comprehensive disaster report generated by Disaster Visualizer</description>
    $placemarks
  </Document>
</kml>''';

      return reportKML;
    } catch (e) {
      print('❌ Failed to create disaster report KML: $e');
      return '';
    }
  }

  /// Save comprehensive disaster report
  Future<File?> saveDisasterReport(List<Disaster> disasters) async {
    try {
      final reportKML = await createDisasterReportKML(disasters);

      if (reportKML.isNotEmpty) {
        final fileName = 'disaster_report_${DateTime.now().millisecondsSinceEpoch}';
        return await SimpleKMLGenerator.generateKML(reportKML, fileName);
      }

      return null;
    } catch (e) {
      print('❌ Failed to save disaster report: $e');
      return null;
    }
  }

  /// Get severity color for KML styling
  String _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'extreme':
        return 'ffff0000'; // Red
      case 'severe':
        return 'ffff6600'; // Orange
      case 'moderate':
        return 'ffffff00'; // Yellow
      case 'minor':
        return 'ff00ff00'; // Green
      default:
        return 'ffffffff'; // White
    }
  }
}
