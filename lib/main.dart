// lib/main.dart - Week 1 Only Implementation
// GSOC 2025 - Catastrophe Visualizer - Saniya Singh

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import our Week 1 models and services
import 'models/disaster_event.dart';
import 'services/api_service.dart';
import 'services/kml_service.dart';
import 'services/liquid_galaxy_service.dart';
import 'providers/disaster_provider.dart';

void main() {
  runApp(CatastropheVisualizerApp());
}

class CatastropheVisualizerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DisasterProvider(),
      child: MaterialApp(
        title: 'Catastrophe Visualizer - Week 1',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Color(0xFF0D1421),
          appBarTheme: AppBarTheme(
            backgroundColor: Color(0xFF1E2832),
            elevation: 0,
          ),
          cardTheme: CardTheme(
            color: Color(0xFF1E2832),
            elevation: 4,
          ),
        ),
        home: Week1TestScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class Week1TestScreen extends StatefulWidget {
  @override
  _Week1TestScreenState createState() => _Week1TestScreenState();
}

class _Week1TestScreenState extends State<Week1TestScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-load disasters when screen starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DisasterProvider>().loadDisasters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Catastrophe Visualizer - Week 1 Test'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => context.read<DisasterProvider>().refreshData(),
          ),
        ],
      ),
      body: Consumer<DisasterProvider>(
        builder: (context, provider, child) {
          return Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusCard(
                        'Loading',
                        provider.isLoading ? 'Yes' : 'No',
                        provider.isLoading ? Colors.orange : Colors.green,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildStatusCard(
                        'Disasters',
                        '${provider.disasters.length}',
                        Colors.blue,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildStatusCard(
                        'LG Connected',
                        provider.lgService.isConnected ? 'Yes' : 'No',
                        provider.lgService.isConnected ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Error Display
                if (provider.error != null)
                  Card(
                    color: Colors.red.shade900,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Error: ${provider.error}',
                              style: TextStyle(color: Colors.red.shade100),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                SizedBox(height: 16),

                // Action Buttons
                Wrap(
                  spacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: provider.isLoading ? null : () => provider.loadDisasters(),
                      child: Text('Load Disasters'),
                    ),
                    ElevatedButton(
                      onPressed: provider.disasters.isEmpty ? null : () => _testKMLGeneration(provider),
                      child: Text('Test KML'),
                    ),
                    ElevatedButton(
                      onPressed: () => _showLGConnectionDialog(),
                      child: Text('Test LG Connection'),
                    ),
                    ElevatedButton(
                      onPressed: provider.disasters.isEmpty ? null : () => _testLGSend(provider),
                      child: Text('Send to LG'),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Disaster List
                if (provider.isLoading)
                  Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('Loading disasters...'),
                      ],
                    ),
                  )
                else if (provider.disasters.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.warning, size: 48, color: Colors.orange),
                        SizedBox(height: 8),
                        Text('No disasters loaded'),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => provider.loadDisasters(),
                          child: Text('Load Data'),
                        ),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent Disasters (${provider.disasters.length})',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: provider.disasters.length,
                            itemBuilder: (context, index) {
                              final disaster = provider.disasters[index];
                              return _buildDisasterCard(disaster);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisasterCard(DisasterEvent disaster) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getSeverityColor(disaster.severity),
          child: Icon(
            _getDisasterIcon(disaster.type),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          disaster.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${disaster.location} • ${disaster.type.displayName}'),
            Text(
              'Magnitude: ${disaster.magnitude} • ${disaster.severity.displayName}',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Text(
          _formatTime(disaster.timestamp),
          style: TextStyle(fontSize: 12),
        ),
        onTap: () => _showDisasterDetails(disaster),
      ),
    );
  }

  Color _getSeverityColor(SeverityLevel severity) {
    switch (severity) {
      case SeverityLevel.critical:
        return Colors.red;
      case SeverityLevel.high:
        return Colors.orange;
      case SeverityLevel.medium:
        return Colors.yellow.shade700;
      case SeverityLevel.low:
        return Colors.green;
    }
  }

  IconData _getDisasterIcon(DisasterType type) {
    switch (type) {
      case DisasterType.earthquake:
        return Icons.vibration;
      case DisasterType.hurricane:
        return Icons.cyclone;
      case DisasterType.wildfire:
        return Icons.local_fire_department;
      case DisasterType.flood:
        return Icons.water;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _testKMLGeneration(DisasterProvider provider) {
    if (provider.disasters.isEmpty) return;

    try {
      final testDisasters = provider.disasters.take(3).toList();
      final kml = KmlService.generateDisasterKML(testDisasters);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Generated KML'),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: SingleChildScrollView(
              child: Text(
                kml,
                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('KML copied to logs (check console)'),
                    backgroundColor: Colors.green,
                  ),
                );
                print('=== GENERATED KML ===');
                print(kml);
                print('=== END KML ===');
              },
              child: Text('Copy to Console'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('KML generation failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLGConnectionDialog() {
    final hostController = TextEditingController(text: '192.168.1.100');
    final usernameController = TextEditingController(text: 'lg');
    final passwordController = TextEditingController(text: 'lg');
    final portController = TextEditingController(text: '22');
    final rigCountController = TextEditingController(text: '3');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Test Liquid Galaxy Connection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: hostController,
              decoration: InputDecoration(
                labelText: 'IP Address',
                hintText: '192.168.1.100',
              ),
            ),
            TextField(
              controller: usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            TextField(
              controller: portController,
              decoration: InputDecoration(labelText: 'SSH Port'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: rigCountController,
              decoration: InputDecoration(labelText: 'Number of Rigs'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              final provider = context.read<DisasterProvider>();
              final success = await provider.connectToLiquidGalaxy(
                host: hostController.text,
                username: usernameController.text,
                password: passwordController.text,
                port: int.tryParse(portController.text) ?? 22,
                rigCount: int.tryParse(rigCountController.text) ?? 3,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Mock LG Connection: SUCCESS' : 'Mock LG Connection: FAILED'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
            child: Text('Test Connection'),
          ),
        ],
      ),
    );
  }

  void _testLGSend(DisasterProvider provider) async {
    if (provider.disasters.isEmpty) return;

    try {
      final success = await provider.sendDisastersToLG();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Mock KML sent to LG successfully!' : 'Failed to send KML to LG'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending to LG: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDisasterDetails(DisasterEvent disaster) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(disaster.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Type', disaster.type.displayName),
            _buildDetailRow('Location', disaster.location),
            _buildDetailRow('Magnitude', disaster.magnitude.toString()),
            _buildDetailRow('Severity', disaster.severity.displayName),
            _buildDetailRow('Time', disaster.timestamp.toString()),
            _buildDetailRow('Coordinates', '${disaster.latitude}, ${disaster.longitude}'),
            if (disaster.description.isNotEmpty)
              _buildDetailRow('Description', disaster.description),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          if (context.read<DisasterProvider>().lgService.isConnected)
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final provider = context.read<DisasterProvider>();
                final success = await provider.flyToDisaster(disaster);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Mock flying to disaster location' : 'Failed to fly to location'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              },
              child: Text('Fly To'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}