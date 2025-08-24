import 'package:flutter/foundation.dart';
import '../services/lg_service.dart';

class LGTasksService {
  final LiquidGalaxySSHService _sshService;

  LGTasksService(this._sshService);

  /// Clean visualization (clear KML files)
  Future<bool> cleanVisualization() async {
    if (!_sshService.isConnected) return false;

    try {
      print(' Cleaning visualization...');

      // Stop any running tours
      await _stopOrbit();

      // Clear main KML files
      await _sshService.executeCommand('> /var/www/html/kmls.txt');
      await _sshService.executeCommand('rm -f /var/www/html/kmls/*.kml');
      await _sshService.executeCommand('echo "" > /tmp/query.txt');

      // Clean balloon
      await cleanBalloon();

      print(' Visualization cleaned');
      return true;
    } catch (e) {
      print(' Failed to clean visualization: $e');
      return false;
    }
  }

  /// Clean logos from LG screens
  Future<bool> cleanLogos() async {
    if (!_sshService.isConnected) return false;

    try {
      print(' Cleaning logos...');

      final rigCount = _sshService.rigCount ?? 3;
      final logoScreen = (rigCount / 2).floor() + 2;

      const String blankKML = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
  </Document>
</kml>''';

      await _sshService.executeCommand("echo '$blankKML' > /var/www/html/kml/slave_$logoScreen.kml");

      print(' Logos cleaned');
      return true;
    } catch (e) {
      print(' Failed to clean logos: $e');
      return false;
    }
  }

  /// Relaunch Liquid Galaxy
  Future<bool> relaunchLG() async {
    if (!_sshService.isConnected) return false;

    try {
      print(' Relaunching Liquid Galaxy...');

      final rigCount = _sshService.rigCount ?? 3;
      final password = _sshService.client?.toString() ?? 'lqgalaxy'; // Get from stored credentials

      // Execute relaunch for all rigs
      for (int i = rigCount; i >= 1; i--) {
        final relaunchCommand = '''
RELAUNCH_CMD="\\
if [ -f /etc/init/lxdm.conf ]; then
  export SERVICE=lxdm
elif [ -f /etc/init/lightdm.conf ]; then
  export SERVICE=lightdm
else
  exit 1
fi
if  [[ \\\$(service \\\$SERVICE status) =~ 'stop' ]]; then
  echo $password | sudo -S service \\\${SERVICE} start
else
  echo $password | sudo -S service \\\${SERVICE} restart
fi
" && sshpass -p $password ssh -x -t lg@lg$i "\$RELAUNCH_CMD"
''';

        await _sshService.executeCommand('"/home/lg/bin/lg-relaunch" > /home/lg/log.txt');
        await _sshService.executeCommand(relaunchCommand);
      }

      print(' Liquid Galaxy relaunched');
      return true;
    } catch (e) {
      print(' Failed to relaunch LG: $e');
      return false;
    }
  }

  /// Reboot Liquid Galaxy
  Future<bool> rebootLG() async {
    if (!_sshService.isConnected) return false;

    try {
      print(' Rebooting Liquid Galaxy...');

      final rigCount = _sshService.rigCount ?? 3;
      final password = 'lqgalaxy'; // Use stored password

      // Reboot all rigs
      for (int i = rigCount; i >= 1; i--) {
        await _sshService.executeCommand(
            'sshpass -p $password ssh -t lg$i "echo $password | sudo -S reboot"'
        );
      }

      print(' Liquid Galaxy rebooted');
      return true;
    } catch (e) {
      print(' Failed to reboot LG: $e');
      return false;
    }
  }

  /// Shutdown Liquid Galaxy
  Future<bool> shutdownLG() async {
    if (!_sshService.isConnected) return false;

    try {
      print(' Shutting down Liquid Galaxy...');

      final rigCount = _sshService.rigCount ?? 3;
      final password = 'lqgalaxy'; // Use stored password

      // Shutdown all rigs
      for (int i = rigCount; i >= 1; i--) {
        await _sshService.executeCommand(
            'sshpass -p $password ssh -t lg$i "echo $password | sudo -S poweroff"'
        );
      }

      print(' Liquid Galaxy shutdown');
      return true;
    } catch (e) {
      print(' Failed to shutdown LG: $e');
      return false;
    }
  }

  /// Set refresh interval for KML files
  Future<bool> setRefresh() async {
    if (!_sshService.isConnected) return false;

    try {
      print('️ Setting refresh interval...');

      const search = '<href>##LG_PHPIFACE##kml\\/slave_{{slave}}.kml<\\/href>';
      const replace = '<href>##LG_PHPIFACE##kml\\/slave_{{slave}}.kml<\\/href><refreshMode>onInterval<\\/refreshMode><refreshInterval>2<\\/refreshInterval>';

      final rigCount = _sshService.rigCount ?? 3;
      final password = 'lqgalaxy';

      for (int i = 2; i <= rigCount; i++) {
        final clearCmd = 'echo $password | sudo -S sed -i "s/$replace/$search/" ~/earth/kml/slave/myplaces.kml'.replaceAll('{{slave}}', i.toString());
        final cmd = 'echo $password | sudo -S sed -i "s/$search/$replace/" ~/earth/kml/slave/myplaces.kml'.replaceAll('{{slave}}', i.toString());

        await _sshService.executeCommand('sshpass -p $password ssh -t lg$i \'$clearCmd\'');
        await _sshService.executeCommand('sshpass -p $password ssh -t lg$i \'$cmd\'');
      }

      print(' Refresh interval set');
      return true;
    } catch (e) {
      print(' Failed to set refresh: $e');
      return false;
    }
  }

  /// Reset refresh interval
  Future<bool> resetRefresh() async {
    if (!_sshService.isConnected) return false;

    try {
      print(' Resetting refresh interval...');

      const search = '<href>##LG_PHPIFACE##kml\\/slave_{{slave}}.kml<\\/href><refreshMode>onInterval<\\/refreshMode><refreshInterval>2<\\/refreshInterval>';
      const replace = '<href>##LG_PHPIFACE##kml\\/slave_{{slave}}.kml<\\/href>';

      final rigCount = _sshService.rigCount ?? 3;
      final password = 'lqgalaxy';

      for (int i = 2; i <= rigCount; i++) {
        final cmd = 'echo $password | sudo -S sed -i "s/$search/$replace/" ~/earth/kml/slave/myplaces.kml'.replaceAll('{{slave}}', i.toString());
        await _sshService.executeCommand('sshpass -p $password ssh -t lg$i \'$cmd\'');
      }

      print(' Refresh interval reset');
      return true;
    } catch (e) {
      print(' Failed to reset refresh: $e');
      return false;
    }
  }

  /// Stop orbit/tour
  Future<bool> _stopOrbit() async {
    try {
      await _sshService.executeCommand('echo "exittour=true" > /tmp/query.txt');
      return true;
    } catch (e) {
      print(' Failed to stop orbit: $e');
      return false;
    }
  }

  /// Clean balloon
  Future<bool> cleanBalloon() async {
    try {
      final rigCount = _sshService.rigCount ?? 3;
      final balloonScreen = (rigCount / 2).floor() + 1;

      const String blankKML = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
  </Document>
</kml>''';

      await _sshService.executeCommand("echo '$blankKML' > /var/www/html/kml/slave_$balloonScreen.kml");
      return true;
    } catch (e) {
      print(' Failed to clean balloon: $e');
      return false;
    }
  }

  /// Restart Google Earth on all rigs
  Future<bool> restartGoogleEarth() async {
    if (!_sshService.isConnected) return false;

    try {
      print(' Restarting Google Earth...');

      final rigCount = _sshService.rigCount ?? 3;
      final password = 'lqgalaxy';

      // Kill Google Earth on all rigs
      for (int i = 1; i <= rigCount; i++) {
        await _sshService.executeCommand('sshpass -p $password ssh -t lg$i "pkill -f google-earth"');
      }

      // Wait a moment
      await Future.delayed(Duration(seconds: 3));

      // Restart Google Earth on all rigs
      for (int i = 1; i <= rigCount; i++) {
        await _sshService.executeCommand('sshpass -p $password ssh -t lg$i "export DISPLAY=:0 && nohup google-earth-pro > /dev/null 2>&1 &"');
      }

      print('Google Earth restarted on all rigs');
      return true;
    } catch (e) {
      print(' Failed to restart Google Earth: $e');
      return false;
    }
  }

  /// Get system statistics
  Future<Map<String, dynamic>?> getSystemStats() async {
    if (!_sshService.isConnected) return null;

    try {
      final uptime = await _sshService.executeCommand('uptime');
      final memInfo = await _sshService.executeCommand('free -h');
      final diskInfo = await _sshService.executeCommand('df -h /');
      final googleEarthStatus = await _sshService.executeCommand('pgrep google-earth');

      return {
        'uptime': uptime?.trim(),
        'memory': memInfo?.trim(),
        'disk': diskInfo?.trim(),
        'googleEarthRunning': googleEarthStatus?.trim().isNotEmpty == true,
        'rigCount': _sshService.rigCount,
        'host': _sshService.host,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print(' Failed to get system stats: $e');
      return null;
    }
  }
}
