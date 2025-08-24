import 'dart:convert';
import 'package:flutter/material.dart';

import '../models/disaster_model.dart';

class KMLBalloonService {
  static const String BALLOON_CSS = '''
    <style>
      body { 
        font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
        margin: 0; 
        padding: 20px; 
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
        border-radius: 10px;
      }
      .header { 
        background: rgba(255,255,255,0.1); 
        padding: 15px; 
        border-radius: 8px; 
        margin-bottom: 15px;
        backdrop-filter: blur(10px);
      }
      .title { 
        font-size: 24px; 
        font-weight: bold; 
        margin-bottom: 5px;
        text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
      }
      .subtitle { 
        font-size: 16px; 
        opacity: 0.9; 
        margin-bottom: 10px;
      }
      .info-grid { 
        display: grid; 
        grid-template-columns: 1fr 1fr; 
        gap: 15px; 
        margin-bottom: 15px;
      }
      .info-item { 
        background: rgba(255,255,255,0.1); 
        padding: 10px; 
        border-radius: 6px;
        backdrop-filter: blur(5px);
      }
      .info-label { 
        font-weight: bold; 
        font-size: 12px; 
        text-transform: uppercase; 
        opacity: 0.8; 
        margin-bottom: 5px;
      }
      .info-value { 
        font-size: 16px; 
        font-weight: 600;
      }
      .severity-extreme { background: linear-gradient(45deg, #ff4757, #ff3838); }
      .severity-severe { background: linear-gradient(45deg, #ff6b35, #f79800); }
      .severity-moderate { background: linear-gradient(45deg, #f1c40f, #f39c12); }
      .severity-minor { background: linear-gradient(45deg, #2ed573, #1e90ff); }
      .coordinates { 
        font-family: 'Courier New', monospace; 
        background: rgba(0,0,0,0.3); 
        padding: 8px; 
        border-radius: 4px;
        font-size: 14px;
      }
      .timestamp { 
        text-align: center; 
        font-style: italic; 
        opacity: 0.8; 
        margin-top: 15px;
        padding-top: 15px;
        border-top: 1px solid rgba(255,255,255,0.2);
      }
      .pulse {
        animation: pulse 2s infinite;
      }
      @keyframes pulse {
        0% { transform: scale(1); }
        50% { transform: scale(1.05); }
        100% { transform: scale(1); }
      }
    </style>
  ''';

  /// Generate enhanced KML balloon for disaster
  static String generateDisasterBalloon(Disaster disaster) {
    final severityClass = 'severity-${disaster.severity.toLowerCase()}';
    final magnitudeIcon = _getMagnitudeIcon(disaster.magnitude);

    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
    <name>Disaster Alert - ${disaster.title}</name>
    <description><![CDATA[
      Enhanced disaster visualization balloon for Liquid Galaxy
    ]]></description>
    
    <Style id="disasterBalloonStyle">
      <BalloonStyle>
        <bgColor>ff1e1e1e</bgColor>
        <textColor>ffffffff</textColor>
        <text><![CDATA[
          $BALLOON_CSS
          <div class="$severityClass">
            <div class="header pulse">
              <div class="title">$magnitudeIcon ${disaster.title}</div>
              <div class="subtitle">${disaster.type.toUpperCase()} Alert - ${disaster.severity} Level</div>
            </div>
            
            <div class="info-grid">
              <div class="info-item">
                <div class="info-label">Magnitude</div>
                <div class="info-value">${disaster.magnitude.toStringAsFixed(1)}</div>
              </div>
              <div class="info-item">
                <div class="info-label">Severity</div>
                <div class="info-value">${disaster.severity}</div>
              </div>
              <div class="info-item">
                <div class="info-label">Location</div>
                <div class="info-value coordinates">
                  ${disaster.latitude.toStringAsFixed(4)}°N<br>
                  ${disaster.longitude.toStringAsFixed(4)}°E
                </div>
              </div>
              <div class="info-item">
                <div class="info-label">Region</div>
                <div class="info-value">${disaster.place ?? 'Unknown Region'}</div>
              </div>
            </div>
            
            <div class="timestamp">
              Detected: ${disaster.timestamp.toString().substring(0, 19)} UTC
            </div>
          </div>
        ]]></text>
      </BalloonStyle>
      <IconStyle>
        <Icon>
          <href>http://maps.google.com/mapfiles/kml/shapes/earthquake.png</href>
        </Icon>
        <scale>${_getIconScale(disaster.magnitude)}</scale>
        <hotSpot x="0.5" y="0" xunits="fraction" yunits="fraction"/>
      </IconStyle>
      <LabelStyle>
        <color>ffffffff</color>
        <scale>1.2</scale>
      </LabelStyle>
    </Style>
    
    <Placemark>
      <name>${disaster.title}</name>
      <description><![CDATA[
        Magnitude ${disaster.magnitude.toStringAsFixed(1)} ${disaster.type} 
        detected at ${disaster.timestamp}
      ]]></description>
      <styleUrl>#disasterBalloonStyle</styleUrl>
      <Point>
        <coordinates>${disaster.longitude},${disaster.latitude},0</coordinates>
      </Point>
      <gx:balloonVisibility>1</gx:balloonVisibility>
    </Placemark>
  </Document>
</kml>''';
  }

  /// Generate enhanced logo balloon with company info
  static String generateLogoBalloon({
    String companyName = 'Disaster Visualizer',
    String version = '2.0.0',
    String description = 'Advanced Liquid Galaxy Integration',
    String logoUrl = 'https://ibb.co/SDn9GjMK',
  }) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Company Logo Balloon</name>
    
    <Style id="logoBalloonStyle">
      <BalloonStyle>
        <bgColor>ff2c3e50</bgColor>
        <textColor>ffffffff</textColor>
        <text><![CDATA[
          <style>
            body { 
              font-family: 'Arial', sans-serif; 
              margin: 0; 
              padding: 15px; 
              background: linear-gradient(135deg, #2c3e50, #34495e);
              border-radius: 10px;
            }
            .logo-container { 
              text-align: center; 
              margin-bottom: 20px;
            }
            .company-name { 
              font-size: 28px; 
              font-weight: bold; 
              color: #3498db;
              margin-bottom: 5px;
              text-shadow: 2px 2px 4px rgba(0,0,0,0.5);
            }
            .version { 
              font-size: 14px; 
              color: #95a5a6; 
              margin-bottom: 15px;
            }
            .description { 
              font-size: 16px; 
              color: #ecf0f1; 
              text-align: center;
              line-height: 1.4;
            }
            .features {
              margin-top: 15px;
              padding-top: 15px;
              border-top: 1px solid rgba(255,255,255,0.2);
            }
            .feature-item {
              display: inline-block;
              background: rgba(52, 152, 219, 0.2);
              padding: 5px 10px;
              margin: 3px;
              border-radius: 15px;
              font-size: 12px;
            }
          </style>
          <div class="logo-container">
            <div class="company-name">$companyName</div>
            <div class="version">Version $version</div>
            <div class="description">$description</div>
            <div class="features">
              <span class="feature-item">🌍 Real-time Data</span>
              <span class="feature-item">🎯 LG Integration</span>
              <span class="feature-item">📊 Advanced Visualization</span>
              <span class="feature-item">🔄 Auto-sync</span>
            </div>
          </div>
        ]]></text>
      </BalloonStyle>
    </Style>
    
    <ScreenOverlay>
      <name>Company Logo</name>
      <Icon>
        <href>$logoUrl</href>
      </Icon>
      <overlayXY x="0" y="1" xunits="fraction" yunits="fraction"/>
      <screenXY x="0" y="1" xunits="fraction" yunits="fraction"/>
      <size x="250" y="150" xunits="pixels" yunits="pixels"/>
    </ScreenOverlay>
  </Document>
</kml>''';
  }

  static String _getMagnitudeIcon(double magnitude) {
    if (magnitude >= 7.0) return '🔥';
    if (magnitude >= 6.0) return '⚠️';
    if (magnitude >= 4.0) return '⚡';
    return '📍';
  }

  static double _getIconScale(double magnitude) {
    if (magnitude >= 7.0) return 2.0;
    if (magnitude >= 6.0) return 1.5;
    if (magnitude >= 4.0) return 1.2;
    return 1.0;
  }
}
