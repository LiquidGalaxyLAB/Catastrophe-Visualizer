
import 'dart:convert';
import 'package:flutter/services.dart';

import '../models/disaster_model.dart';
import '../models/ssh_model.dart';
import 'lg_service.dart';

class EnhancedLgService {
  final LiquidGalaxySSHService _sshService;

  //  hosted logo URL + local asset
  static const String HOSTED_LOGO_URL = 'https://ibb.co/SDn9GjMK';
  static const String LOCAL_LOGO_ASSET = 'assets/images/disaster_logo.png';

  EnhancedLgService(this._sshService);

  bool get isConnected => _sshService.isConnected;
  int get screenAmount => _sshService.rigCount ?? 3;

  /// Get logo screen (leftmost screen)
  int get logoScreen {
    if (screenAmount == 1) return 1;
    return (screenAmount / 2).floor() + 2;
  }

  /// Connect using SSH model
  Future<bool> connect(SSHModel sshModel) async {
    final result = await _sshService.connect(
      host: sshModel.host,
      username: sshModel.username,
      password: sshModel.passwordOrKey,
      port: sshModel.port,
      rigCount: sshModel.screenAmount,
    );
    return result == null; // null means success
  }

  /// Test connection
  Future<bool> testConnection(SSHModel sshModel) async {
    return await _sshService.testConnection(
      host: sshModel.host,
      username: sshModel.username,
      password: sshModel.passwordOrKey,
      port: sshModel.port,
    );
  }

  /// Disconnect
  Future<void> disconnect() async {
    await _sshService.disconnect();
  }

  /// Set logo with URL or local asset options
  Future<bool> setLogo({
    String logoName = 'Catastrophe  Visualizer',
    bool useHostedImage = true,
  }) async {
    if (!isConnected) return false;

    try {
      print(' Setting logo: $logoName');
      print(' Using ${useHostedImage ? 'hosted URL' : 'local asset'}');

      String logoKml;

      if (useHostedImage) {
        // Using your hosted image URL
        logoKml = _generateLogoKmlWithURL(HOSTED_LOGO_URL, logoName);
        print(' Using hosted logo: $HOSTED_LOGO_URL');
      } else {
        // Using local asset as base64
        final logoBase64 = await _loadAssetAsBase64(LOCAL_LOGO_ASSET);
        logoKml = _generateLogoKmlWithBase64(logoBase64, logoName);
        print('Using local asset: $LOCAL_LOGO_ASSET');
      }

      // Send logo KML to LG
      final success = await _sshService.uploadKMLFile(logoKml, 'disaster_logo');

      if (success) {
        print(' Logo set successfully on screen $logoScreen');
      }

      return success;
    } catch (e) {
      print(' Failed to set logo: $e');
      return false;
    }
  }

  /// Generate logo KML with hosted URL
  String _generateLogoKmlWithURL(String imageUrl, String logoName) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>$logoName</name>
    <ScreenOverlay>
      <name>Logo</name>
      <Icon>
        <href>$imageUrl</href>
      </Icon>
      <overlayXY x="0" y="1" xunits="fraction" yunits="fraction"/>
      <screenXY x="0" y="1" xunits="fraction" yunits="fraction"/>
      <size x="200" y="120" xunits="pixels" yunits="pixels"/>
    </ScreenOverlay>
  </Document>
</kml>''';
  }

  /// Generate logo KML with base64 image
  String _generateLogoKmlWithBase64(String imageBase64, String logoName) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>$logoName</name>
    <ScreenOverlay>
      <name>Logo</name>
      <Icon>
        <href>data:image/png;base64,$imageBase64</href>
      </Icon>
      <overlayXY x="0" y="1" xunits="fraction" yunits="fraction"/>
      <screenXY x="0" y="1" xunits="fraction" yunits="fraction"/>
      <size x="200" y="120" xunits="pixels" yunits="pixels"/>
    </ScreenOverlay>
  </Document>
</kml>''';
  }

  /// Load asset as base64
  Future<String> _loadAssetAsBase64(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      return base64Encode(bytes);
    } catch (e) {
      print(' Failed to load asset: $assetPath');
      return 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChAGAWDYb4QAAAABJRU5ErkJggg==';
    }
  }

  /// Clear logo
  Future<void> clearLogo() async {
    if (!isConnected) return;

    final blankKml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <n>Clear</n>
  </Document>
</kml>''';

    await _sshService.uploadKMLFile(blankKml, 'clear_logo');
    print(' Logo cleared');
  }

  /// Send disaster data to LG
  Future<bool> sendDisasterToLG(Disaster disaster) async {
    if (!isConnected) return false;

    try {
      final disasterKml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <n>Disaster Alert</n>
    <Placemark>
      <n>${disaster.title}</n>
      <description><![CDATA[
        <h3>${disaster.type.toUpperCase()} - ${disaster.severity}</h3>
        <p><strong>Magnitude:</strong> ${disaster.magnitude.toStringAsFixed(1)}</p>
        <p><strong>Location:</strong> ${disaster.latitude.toStringAsFixed(4)}, ${disaster.longitude.toStringAsFixed(4)}</p>
        <p><strong>Time:</strong> ${disaster.timestamp}</p>
        ${disaster.place != null ? '<p><strong>Place:</strong> ${disaster.place}</p>' : ''}
      ]]></description>
      <Point>
        <coordinates>${disaster.longitude},${disaster.latitude},0</coordinates>
      </Point>
    </Placemark>
  </Document>
</kml>''';

      return await _sshService.uploadKMLFile(disasterKml, 'disaster_${disaster.id}');
    } catch (e) {
      print(' Failed to send disaster to LG: $e');
      return false;
    }
  }

  /// Clear all disasters from LG
  Future<void> clearDisasters() async {
    await _sshService.clearGoogleEarth();
  }

  /// Get connection status
  Map<String, dynamic> getStatus() {
    return {
      'connected': isConnected,
      'host': _sshService.host,
      'username': _sshService.username,
      'screens': screenAmount,
      'logoScreen': logoScreen,
      'hostedLogoUrl': HOSTED_LOGO_URL,
      'localLogoAsset': LOCAL_LOGO_ASSET,
    };
  }
}
