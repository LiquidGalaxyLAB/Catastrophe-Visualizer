import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/disaster_model.dart';
import '../models/ssh_model.dart';
import '../services/api_service.dart';
import '../services/lg_service.dart';

class DisasterMainScreen extends StatefulWidget {
  @override
  _DisasterMainScreenState createState() => _DisasterMainScreenState();
}

class _DisasterMainScreenState extends State<DisasterMainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Filter options
  String _selectedSeverity = 'All';
  double _minMagnitude = 2.5;
  int _recentHours = 168; // 7 days

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Auto-fetch disasters on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DisasterApiService>().fetchEarthquakes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Disaster Visualizer'),
        backgroundColor: Colors.blue[900],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.list), text: 'Disasters'),
            Tab(icon: Icon(Icons.computer), text: 'Liquid Galaxy'),
            Tab(icon: Icon(Icons.info), text: 'About'),
          ],
        ),
        actions: [
          Consumer<LiquidGalaxySSHService>(
            builder: (context, sshService, child) {
              return Container(
                margin: EdgeInsets.only(right: 16),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: sshService.isConnected ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      sshService.isConnected ? Icons.link : Icons.link_off,
                      size: 16,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      sshService.isConnected ? 'LG' : 'OFF',
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDisasterTab(),
          _buildLGTab(),
          _buildAboutTab(),
        ],
      ),
    );
  }

  Widget _buildDisasterTab() {
    return Consumer<DisasterApiService>(
      builder: (context, disasterService, child) {
        return Column(
          children: [
            _buildStatsHeader(disasterService),
            _buildFilterPanel(disasterService),
            Expanded(child: _buildDisasterList(disasterService)),
          ],
        );
      },
    );
  }

  Widget _buildStatsHeader(DisasterApiService service) {
    final stats = service.getStatistics();

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Disaster Monitor',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: service.isLoading ? null : () => service.fetchEarthquakes(),
                icon: service.isLoading
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Icon(Icons.refresh, color: Colors.white),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Total', '${stats['total']}', Colors.white),
              _buildStatCard('Extreme', '${stats['extreme']}', Colors.red[300]!),
              _buildStatCard('24h', '${stats['recent_24h']}', Colors.green[300]!),
              _buildStatCard('5.0+', '${service.getDisastersByMagnitude(5.0).length}', Colors.orange[300]!),
            ],
          ),
          if (service.lastUpdate != null)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Updated: ${DateFormat('HH:mm').format(service.lastUpdate!)}',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildFilterPanel(DisasterApiService service) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filters', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSeverity,
                  decoration: InputDecoration(
                    labelText: 'Severity',
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  items: ['All', 'Extreme', 'Severe', 'Moderate', 'Minor']
                      .map((severity) => DropdownMenuItem(
                    value: severity,
                    child: Text(severity),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedSeverity = value!);
                  },
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _recentHours,
                  decoration: InputDecoration(
                    labelText: 'Time',
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  items: [
                    DropdownMenuItem(value: 24, child: Text('24h')),
                    DropdownMenuItem(value: 72, child: Text('3d')),
                    DropdownMenuItem(value: 168, child: Text('7d')),
                    DropdownMenuItem(value: 720, child: Text('30d')),
                  ],
                  onChanged: (value) {
                    setState(() => _recentHours = value!);
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Text('Min Mag: ${_minMagnitude.toStringAsFixed(1)}'),
              Expanded(
                child: Slider(
                  value: _minMagnitude,
                  min: 1.0,
                  max: 8.0,
                  divisions: 14,
                  onChanged: (value) {
                    setState(() => _minMagnitude = value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDisasterList(DisasterApiService service) {
    if (service.isLoading && service.disasters.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }

    if (service.lastError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('Error loading disasters'),
            SizedBox(height: 8),
            Text(
              service.lastError!,
              style: TextStyle(color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => service.fetchEarthquakes(),
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Apply filters
    List<Disaster> filteredDisasters = service.disasters;

    if (_selectedSeverity != 'All') {
      filteredDisasters = filteredDisasters
          .where((d) => d.severity == _selectedSeverity)
          .toList();
    }

    filteredDisasters = filteredDisasters
        .where((d) => d.magnitude >= _minMagnitude)
        .toList();

    final cutoff = DateTime.now().subtract(Duration(hours: _recentHours));
    filteredDisasters = filteredDisasters
        .where((d) => d.timestamp.isAfter(cutoff))
        .toList();

    if (filteredDisasters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No disasters match filters'),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedSeverity = 'All';
                  _minMagnitude = 2.5;
                  _recentHours = 168;
                });
              },
              child: Text('Clear Filters'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredDisasters.length,
      itemBuilder: (context, index) {
        final disaster = filteredDisasters[index];
        return _buildDisasterCard(disaster);
      },
    );
  }

  Widget _buildDisasterCard(Disaster disaster) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: disaster.severityColor,
          child: Icon(disaster.typeIcon, color: Colors.white),
        ),
        title: Text(
          disaster.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mag: ${disaster.magnitude.toStringAsFixed(1)} • ${disaster.severity}'),
            Text(
              DateFormat('MMM dd, HH:mm').format(disaster.timestamp),
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
        trailing: Consumer<LiquidGalaxySSHService>(
          builder: (context, sshService, child) {
            return sshService.isConnected
                ? IconButton(
              onPressed: () => _sendDisasterToLG(disaster),
              icon: Icon(Icons.send, color: Colors.blue),
              tooltip: 'Send to LG',
            )
                : SizedBox.shrink();
          },
        ),
        onTap: () => _showDisasterDetails(disaster),
      ),
    );
  }

  Widget _buildLGTab() {
    return Consumer<LiquidGalaxySSHService>(
      builder: (context, sshService, child) {
        if (!sshService.isConnected) {
          return _buildLGConnectionForm();
        } else {
          return _buildLGControls(sshService);
        }
      },
    );
  }

  Widget _buildLGConnectionForm() {
    final _formKey = GlobalKey<FormState>();
    final _hostController = TextEditingController(text: '192.168.1.42');
    final _portController = TextEditingController(text: '22');
    final _usernameController = TextEditingController(text: 'lg');
    final _passwordController = TextEditingController(text: 'lqgalaxy');
    final _screensController = TextEditingController(text: '3');

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connect to Liquid Galaxy',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _hostController,
              decoration: InputDecoration(
                labelText: 'LG IP Address',
                prefixIcon: Icon(Icons.computer),
              ),
              validator: (value) => value?.isEmpty == true ? 'Enter IP' : null,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _portController,
                    decoration: InputDecoration(
                      labelText: 'Port',
                      prefixIcon: Icon(Icons.settings_ethernet),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _screensController,
                    decoration: InputDecoration(
                      labelText: 'Screens',
                      prefixIcon: Icon(Icons.desktop_windows),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final sshModel = SSHModel(
                      host: _hostController.text.trim(),
                      port: int.parse(_portController.text.trim()),
                      username: _usernameController.text.trim(),
                      passwordOrKey: _passwordController.text,
                      screenAmount: int.parse(_screensController.text.trim()),
                    );

                    final success = await context.read<LiquidGalaxySSHService>().connect(
                      host: sshModel.host,
                      username: sshModel.username,
                      password: sshModel.passwordOrKey,
                      port: sshModel.port,
                      rigCount: sshModel.screenAmount,
                    );

                    _showSnackBar(
                      success == null ? 'Connected to LG!' : 'Connection failed: $success',
                      success == null ? Colors.green : Colors.red,
                    );
                  }
                },
                icon: Icon(Icons.link),
                label: Text('Connect to LG'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLGControls(LiquidGalaxySSHService sshService) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Liquid Galaxy Controls',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),

          // Connection Status
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connected to ${sshService.host}',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Screens: ${sshService.rigCount}',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await sshService.disconnect();
                    _showSnackBar('Disconnected from LG', Colors.orange);
                  },
                  child: Text('Disconnect'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // System Controls
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Controls',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _restartGoogleEarth(),
                      icon: Icon(Icons.refresh),
                      label: Text('Restart Google Earth'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    ),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _clearGoogleEarth(),
                      icon: Icon(Icons.clear),
                      label: Text('Clear Google Earth'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    ),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _rebootSystem(),
                      icon: Icon(Icons.power_settings_new),
                      label: Text('Reboot System'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // App Logo and Header
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/disaster_logo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[600]!, Colors.blue[800]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.public, size: 60, color: Colors.white),
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 20),

          Text(
            'Disaster Visualizer',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Real-time Disaster Monitoring with Liquid Galaxy',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[400],
            ),
          ),

          SizedBox(height: 30),

          // App Info Card
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[400]),
                      SizedBox(width: 10),
                      Text(
                        'About',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  Text(
                    'This application provides real-time monitoring of global disasters with advanced visualization capabilities through Liquid Galaxy integration.',
                    style: TextStyle(fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Features Card
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.orange[400]),
                      SizedBox(width: 10),
                      Text(
                        'Features',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  _buildFeatureItem('Real-time earthquake data from USGS'),
                  _buildFeatureItem('Advanced filtering and search'),
                  _buildFeatureItem('Liquid Galaxy cluster integration'),
                  _buildFeatureItem('Interactive KML visualization'),
                  _buildFeatureItem('System management tools'),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Technical Info Card
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.code, color: Colors.green[400]),
                      SizedBox(width: 10),
                      Text(
                        'Technical Information',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  _buildInfoRow('Platform', 'Flutter & Dart'),
                  _buildInfoRow('Data Source', 'USGS Earthquake API'),
                  _buildInfoRow('Visualization', 'Google Earth & KML'),
                  _buildInfoRow('Connection', 'SSH Protocol'),
                  _buildInfoRow('Real-time Updates', 'Live Data Feed'),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Data Source Card
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.public, color: Colors.blue[400]),
                      SizedBox(width: 10),
                      Text(
                        'Data Sources',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  _buildLinkItem('USGS Earthquake Hazards Program', 'earthquake.usgs.gov'),
                  _buildLinkItem('Liquid Galaxy Project', 'liquidgalaxy.eu'),
                  _buildLinkItem('Google Earth Platform', 'earth.google.com'),
                ],
              ),
            ),
          ),

          SizedBox(height: 30),

          // Footer
          Text(
            'Built for Liquid Galaxy Organization',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Disaster Monitoring & Visualization System',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green[400], size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkItem(String title, String url) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.link, color: Colors.blue[400], size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  url,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[300],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendDisasterToLG(Disaster disaster) async {
    final sshService = context.read<LiquidGalaxySSHService>();
    final success = await _sendDisasterKML(sshService, disaster);

    _showSnackBar(
      success ? 'Disaster sent to LG!' : 'Failed to send disaster',
      success ? Colors.blue : Colors.red,
    );
  }

  Future<bool> _sendDisasterKML(LiquidGalaxySSHService sshService, Disaster disaster) async {
    final kmlContent = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Disaster Alert</name>
    <Placemark>
      <name>${disaster.title}</name>
      <description><![CDATA[
        <h3>${disaster.type.toUpperCase()} - ${disaster.severity}</h3>
        <p><strong>Magnitude:</strong> ${disaster.magnitude.toStringAsFixed(1)}</p>
        <p><strong>Location:</strong> ${disaster.latitude.toStringAsFixed(4)}, ${disaster.longitude.toStringAsFixed(4)}</p>
        <p><strong>Time:</strong> ${DateFormat('yyyy-MM-dd HH:mm').format(disaster.timestamp)}</p>
        ${disaster.place != null ? '<p><strong>Place:</strong> ${disaster.place}</p>' : ''}
      ]]></description>
      <Point>
        <coordinates>${disaster.longitude},${disaster.latitude},0</coordinates>
      </Point>
    </Placemark>
  </Document>
</kml>''';

    return await sshService.uploadKMLFile(kmlContent, 'disaster_${disaster.id}');
  }

  Future<void> _restartGoogleEarth() async {
    final sshService = context.read<LiquidGalaxySSHService>();

    await sshService.executeCommand('pkill -f google-earth');
    await Future.delayed(Duration(seconds: 2));
    await sshService.executeCommand('export DISPLAY=:0 && nohup google-earth-pro > /dev/null 2>&1 &');

    _showSnackBar('Google Earth restarted', Colors.blue);
  }

  Future<void> _clearGoogleEarth() async {
    final sshService = context.read<LiquidGalaxySSHService>();
    await sshService.clearGoogleEarth();
    _showSnackBar('Google Earth cleared', Colors.orange);
  }

  Future<void> _rebootSystem() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reboot System'),
        content: Text('This will reboot the LG system. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Reboot'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final sshService = context.read<LiquidGalaxySSHService>();
      await sshService.executeCommand('sudo reboot');
      _showSnackBar('Reboot command sent', Colors.red);
    }
  }

  void _showDisasterDetails(Disaster disaster) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(disaster.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Type', disaster.type.toUpperCase()),
            _buildDetailRow('Magnitude', disaster.magnitude.toStringAsFixed(1)),
            _buildDetailRow('Severity', disaster.severity),
            _buildDetailRow('Location', '${disaster.latitude.toStringAsFixed(4)}, ${disaster.longitude.toStringAsFixed(4)}'),
            _buildDetailRow('Time', DateFormat('MMM dd, yyyy HH:mm').format(disaster.timestamp)),
            if (disaster.place != null) _buildDetailRow('Place', disaster.place!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          Consumer<LiquidGalaxySSHService>(
            builder: (context, sshService, child) {
              return sshService.isConnected
                  ? ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _sendDisasterToLG(disaster);
                },
                child: Text('Send to LG'),
              )
                  : SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontWeight: FontWeight.w400)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
