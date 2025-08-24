/*import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

class OrbitService {
  static const double EARTH_RADIUS = 6371000; // meters

  /// Generate satellite orbit KML
  static String generateSatelliteOrbit({
    required String satelliteName,
    required double altitude, // in meters
    required double inclination, // in degrees
    required double period, // in minutes
    Color orbitColor = Colors.cyan,
  }) {
    final points = _calculateOrbitPoints(altitude, inclination, 100);
    final colorHex = orbitColor.value.toRadixString(16).padLeft(8, '0');
    final kmlColor = 'ff${colorHex.substring(6)}${colorHex.substring(4, 6)}${colorHex.substring(2, 4)}';

    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
    <name>$satelliteName Orbit</name>
    <description>Satellite orbit visualization for Liquid Galaxy</description>

    <Style id="orbitLineStyle">
      <LineStyle>
        <color>$kmlColor</color>
        <width>3</width>
        <gx:labelVisibility>1</gx:labelVisibility>
      </LineStyle>
      <PolyStyle>
        <color>7f${colorHex.substring(6)}${colorHex.substring(4, 6)}${colorHex.substring(2, 4)}</color>
      </PolyStyle>
    </Style>

    <Style id="satelliteStyle">
      <IconStyle>
        <Icon>
          <href>http://maps.google.com/mapfiles/kml/shapes/placemark_circle.png</href>
        </Icon>
        <scale>1.5</scale>
        <color>$kmlColor</color>
      </IconStyle>
      <LabelStyle>
        <color>ffffffff</color>
        <scale>1.2</scale>
      </LabelStyle>
    </Style>

    <Placemark>
      <name>$satelliteName Orbit Path</name>
      <description><![CDATA[
        <b>Satellite:</b> $satelliteName<br/>
        <b>Altitude:</b> ${(altitude / 1000).toStringAsFixed(0)} km<br/>
        <b>Inclination:</b> ${inclination.toStringAsFixed(1)}°<br/>
        <b>Period:</b> ${period.toStringAsFixed(0)} minutes
      ]]></description>
      <styleUrl>#orbitLineStyle</styleUrl>
      <LineString>
        <extrude>1</extrude>
        <altitudeMode>absolute</altitudeMode>
        <coordinates>
          ${points.map((p) => '${p['lng']},${p['lat']},${p['alt']}').join('\n')}
        </coordinates>
      </LineString>
    </Placemark>

    <Placemark>
      <name>$satelliteName</name>
      <description>Current satellite position</description>
      <styleUrl>#satelliteStyle</styleUrl>
      <Point>
        <altitudeMode>absolute</altitudeMode>
        <coordinates>${points.first['lng']},${points.first['lat']},${points.first['alt']}</coordinates>
      </Point>
    </Placemark>
  </Document>
</kml>''';
  }

  /// Generate Earth orbit animation
  static String generateOrbitAnimation({
    required String objectName,
    required double altitude,
    required double inclination,
    required int steps,
    required double duration, // in seconds
  }) {
    final points = _calculateOrbitPoints(altitude, inclination, steps);

    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
    <name>$objectName Animated Orbit</name>

    <Style id="animatedSatelliteStyle">
      <IconStyle>
        <Icon>
          <href>http://maps.google.com/mapfiles/kml/shapes/placemark_circle_highlight.png</href>
        </Icon>
        <scale>2.0</scale>
      </IconStyle>
    </Style>

    <Placemark>
      <name>$objectName</name>
      <styleUrl>#animatedSatelliteStyle</styleUrl>
      <gx:Track>
        <altitudeMode>absolute</altitudeMode>
        ${_generateTimeStamps(duration, steps)}
        ${points.map((p) => '<gx:coord>${p['lng']} ${p['lat']} ${p['alt']}</gx:coord>').join('\n')}
      </gx:Track>
    </Placemark>
  </Document>
</kml>''';
  }

  static List<Map<String, double>> _calculateOrbitPoints(double altitude, double inclination, int numPoints) {
    final points = <Map<String, double>>[];
    final orbitalRadius = EARTH_RADIUS + altitude;
    final inclinationRad = inclination * math.pi / 180;

    for (int i = 0; i < numPoints; i++) {
      final angle = (i / numPoints) * 2 * math.pi;

      // Calculate 3D coordinates
      final x = orbitalRadius * math.cos(angle);
      final y = orbitalRadius * math.sin(angle) * math.cos(inclinationRad);
      final z = orbitalRadius * math.sin(angle) * math.sin(inclinationRad);

      // Convert to lat/lng
      final lat = math.asin(z / orbitalRadius) * 180 / math.pi;
      final lng = math.atan2(y, x) * 180 / math.pi;

      points.add({
        'lat': lat,
        'lng': lng,
        'alt': altitude,
      });
    }

    return points;
  }

  static String _generateTimeStamps(double duration, int steps) {
    final timeStep = duration / steps;
    final buffer = StringBuffer();

    for (int i = 0; i < steps; i++) {
      final seconds = (i * timeStep).round();
      buffer.writeln('<when>2024-01-01T00:${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}Z</when>');
    }

    return buffer.toString();
  }
}*/
