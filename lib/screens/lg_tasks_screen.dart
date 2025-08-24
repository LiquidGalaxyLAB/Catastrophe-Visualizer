// lib/screens/lg_tasks_screen.dart
// SIMPLIFIED VERSION: Only essential working LG tasks
/*
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ssh_provider.dart';

class LGTasksScreen extends StatefulWidget {
  @override
  _LGTasksScreenState createState() => _LGTasksScreenState();
}

class _LGTasksScreenState extends State<LGTasksScreen> {
  bool _isLogoVisible = false;
  String? _lastResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(' Liquid Galaxy Control'),
        elevation: 2,
      ),
      body: Consumer<HybridLiquidGalaxyProvider>(
        builder: (context, lgProvider, child) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Connection Status
                _buildConnectionCard(lgProvider),

                SizedBox(height: 20),

                // Essential Tasks
                _buildTasksCard(lgProvider),

                SizedBox(height: 20),

                // Result Display
                if (_lastResult != null) _buildResultCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnectionCard(HybridLiquidGalaxyProvider lgProvider) {
    return Card(
      color: lgProvider.isConnected ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  lgProvider.isConnected ? Icons.wifi : Icons.wifi_off,
                  color: lgProvider.isConnected ? Colors.green : Colors.red,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  lgProvider.isConnected ? 'Connected to Liquid Galaxy' : 'Not Connected',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: lgProvider.isConnected ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
              ],
            ),
            if (lgProvider.isConnected) ...[
              SizedBox(height: 8),
              Text(' Host: ${lgProvider.currentHost}'),
              Text(' Screens: ${lgProvider.rigCount}'),
              Text(' Leftmost Screen: ${lgProvider.detectedLeftmostScreen ?? 'Auto'}'),
              Text(' Slaves Detected: ${lgProvider.detectedSlaveIPs.length}'),
            ],
            if (!lgProvider.isConnected) ...[
              SizedBox(height: 8),
              Text(
                'Connect to Liquid Galaxy first to use these controls',
                style: TextStyle(color: Colors.red.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTasksCard(HybridLiquidGalaxyProvider lgProvider) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎮 Essential LG Controls',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),

            // Logo Controls
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: lgProvider.isConnected && !lgProvider.isExecutingSystemCommand
                        ? () => _testLogo(lgProvider)
                        : null,
                    icon: Icon(Icons.image),
                    label: Text('Show Logo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: Size(0, 50),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: lgProvider.isConnected && !lgProvider.isExecutingSystemCommand
                        ? () => _clearDisplay(lgProvider)
                        : null,
                    icon: Icon(Icons.clear_all),
                    label: Text('Clear Display'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      minimumSize: Size(0, 50),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // System Controls
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: lgProvider.isConnected && !lgProvider.isExecutingSystemCommand
                        ? () => _restartGoogleEarth(lgProvider)
                        : null,
                    icon: lgProvider.isExecutingSystemCommand
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Icon(Icons.restart_alt),
                    label: Text('Restart Google Earth'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: Size(0, 50),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // Advanced Controls (with confirmation)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: lgProvider.isConnected && !lgProvider.isExecutingSystemCommand
                        ? () => _relaunchSystem(lgProvider)
                        : null,
                    icon: lgProvider.isExecutingSystemCommand
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Icon(Icons.refresh),
                    label: Text('Relaunch LG System'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      minimumSize: Size(0, 50),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: lgProvider.isConnected && !lgProvider.isExecutingSystemCommand
                        ? () => _shutdownSystem(lgProvider)
                        : null,
                    icon: lgProvider.isExecutingSystemCommand
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Icon(Icons.power_off),
                    label: Text('Shutdown LG'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: Size(0, 50),
                    ),
                  ),
                ),
              ],
            ),

            if (lgProvider.isExecutingSystemCommand) ...[
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text(
                      'Executing system command...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final isSuccess = _lastResult!.contains('');

    return Card(
      color: isSuccess ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess ? Colors.green : Colors.red,
                ),
                SizedBox(width: 8),
                Text(
                  'Task Result',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(_lastResult!),
            SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _lastResult = null;
                });
              },
              child: Text('Clear'),
            ),
          ],
        ),
      ),
    );
  }

  // Essential Task Methods
  Future<void> _testLogo(HybridLiquidGalaxyProvider lgProvider) async {
    try {
      final success = await lgProvider.displayLogo();
      setState(() {
        _lastResult = success
            ? ' Logo displayed successfully on leftmost screen!'
            : ' Failed to display logo. Check connection.';
      });
    } catch (e) {
      setState(() {
        _lastResult = 'Logo error: $e';
      });
    }
  }

  Future<void> _clearDisplay(HybridLiquidGalaxyProvider lgProvider) async {
    try {
      final success = await lgProvider.clearLiquidGalaxy();
      setState(() {
        _lastResult = success
            ? ' Display cleared successfully!'
            : ' Failed to clear display.';
      });
    } catch (e) {
      setState(() {
        _lastResult = ' Clear error: $e';
      });
    }
  }

  Future<void> _restartGoogleEarth(HybridLiquidGalaxyProvider lgProvider) async {
    try {
      final success = await lgProvider.restartGoogleEarth();
      setState(() {
        _lastResult = success
            ? ' Google Earth restarted successfully!'
            : ' Failed to restart Google Earth.';
      });
    } catch (e) {
      setState(() {
        _lastResult = ' Restart error: $e';
      });
    }
  }

  Future<void> _relaunchSystem(HybridLiquidGalaxyProvider lgProvider) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Relaunch'),
        content: Text('This will restart the entire Liquid Galaxy system. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: Text('Relaunch'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await lgProvider.relaunchSystem();
        setState(() {
          _lastResult = success
              ? 'LG System relaunch completed!'
              : ' Failed to relaunch LG system.';
        });
      } catch (e) {
        setState(() {
          _lastResult = ' Relaunch error: $e';
        });
      }
    }
  }

  Future<void> _shutdownSystem(HybridLiquidGalaxyProvider lgProvider) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(' Confirm Shutdown'),
        content: Text('This will shutdown the entire Liquid Galaxy system. You will need to manually restart it. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Shutdown'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await lgProvider.shutdownSystem();
        setState(() {
          _lastResult = success
              ? ' LG System shutdown initiated. You will need to manually restart.'
              : ' Failed to shutdown LG system.';
        });
      } catch (e) {
        setState(() {
          _lastResult = ' Shutdown error: $e';
        });
      }
    }
  }
}


 */