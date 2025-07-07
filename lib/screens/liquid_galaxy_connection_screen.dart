// lib/screens/liquid_galaxy_connection_screen.dart
// Week 4 Implementation: Complete Liquid Galaxy connection management screen

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/liquid_galaxy_provider.dart';
import '../providers/updated_disaster_provider.dart';

class LiquidGalaxyConnectionScreen extends StatefulWidget {
  @override
  _LiquidGalaxyConnectionScreenState createState() => _LiquidGalaxyConnectionScreenState();
}

class _LiquidGalaxyConnectionScreenState extends State<LiquidGalaxyConnectionScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _portController = TextEditingController(text: '22');
  final _rigCountController = TextEditingController(text: '3');

  bool _passwordVisible = false;
  bool _isTestingConnection = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSavedCredentials();
  }

  void _loadSavedCredentials() {
    final lgProvider = context.read<LiquidGalaxyProvider>();
    final connectionInfo = lgProvider.getConnectionInfo();

    if (connectionInfo['host'] != null) {
      _hostController.text = connectionInfo['host'];
    }
    if (connectionInfo['username'] != null) {
      _usernameController.text = connectionInfo['username'];
    }
    if (connectionInfo['port'] != null) {
      _portController.text = connectionInfo['port'].toString();
    }
    if (connectionInfo['rigCount'] != null) {
      _rigCountController.text = connectionInfo['rigCount'].toString();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _hostController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _portController.dispose();
    _rigCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🖥️ Liquid Galaxy Connection'),
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.settings_ethernet), text: 'Connect'),
            Tab(icon: Icon(Icons.monitor), text: 'Status'),
            Tab(icon: Icon(Icons.analytics), text: 'Statistics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConnectionTab(),
          _buildStatusTab(),
          _buildStatisticsTab(),
        ],
      ),
    );
  }

  Widget _buildConnectionTab() {
    return Consumer<LiquidGalaxyProvider>(
      builder: (context, lgProvider, child) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Connection Status Card
                _buildConnectionStatusCard(lgProvider),

                SizedBox(height: 20),

                // Connection Form
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🔧 Connection Settings',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 20),

                        // Host IP
                        TextFormField(
                          controller: _hostController,
                          decoration: InputDecoration(
                            labelText: 'Host IP Address',
                            hintText: '192.168.1.42',
                            prefixIcon: Icon(Icons.computer),
                            border: OutlineInputBorder(),
                            helperText: 'IP address of the Liquid Galaxy master',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter host IP address';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 16),

                        // Username
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Username',
                            hintText: 'lg',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                            helperText: 'SSH username for the Liquid Galaxy system',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter username';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 16),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_passwordVisible,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock),
                            border: OutlineInputBorder(),
                            helperText: 'SSH password for the Liquid Galaxy system',
                            suffixIcon: IconButton(
                              icon: Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter password';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 16),

                        // Port and Rig Count Row
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _portController,
                                decoration: InputDecoration(
                                  labelText: 'SSH Port',
                                  prefixIcon: Icon(Icons.fort),
                                  border: OutlineInputBorder(),
                                  helperText: 'Usually 22',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  final port = int.tryParse(value);
                                  if (port == null || port <= 0 || port > 65535) {
                                    return 'Invalid port';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _rigCountController,
                                decoration: InputDecoration(
                                  labelText: 'Screen Count',
                                  prefixIcon: Icon(Icons.monitor),
                                  border: OutlineInputBorder(),
                                  helperText: 'Number of screens',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  final count = int.tryParse(value);
                                  if (count == null || count < 1 || count > 10) {
                                    return 'Invalid count';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isTestingConnection ? null : _testConnection,
                                icon: _isTestingConnection
                                    ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                    : Icon(Icons.wifi_protected_setup),
                                label: Text(_isTestingConnection ? 'Testing...' : 'Test Connection'),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: lgProvider.isConnecting ? null : _connect,
                                icon: lgProvider.isConnecting
                                    ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                    : Icon(lgProvider.isConnected ? Icons.refresh : Icons.connect_without_contact),
                                label: Text(lgProvider.isConnecting
                                    ? 'Connecting...'
                                    : lgProvider.isConnected ? 'Reconnect' : 'Connect'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: lgProvider.isConnected ? Colors.orange : Colors.green,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (lgProvider.isConnected) ...[
                          SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _disconnect,
                              icon: Icon(Icons.power_off),
                              label: Text('Disconnect'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Quick Actions (when connected)
                if (lgProvider.isConnected) _buildQuickActionsCard(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConnectionStatusCard(LiquidGalaxyProvider lgProvider) {
    final isConnected = lgProvider.isConnected;
    final connectionInfo = lgProvider.getConnectionInfo();

    return Card(
      color: isConnected ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isConnected ? Icons.check_circle : Icons.error,
                  color: isConnected ? Colors.green : Colors.red,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  isConnected ? '🟢 Connected' : '🔴 Disconnected',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isConnected ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
              ],
            ),

            if (isConnected) ...[
              SizedBox(height: 12),
              Text('📡 Host: ${connectionInfo['host']}:${connectionInfo['port']}'),
              Text('👤 User: ${connectionInfo['username']}'),
              Text('🖥️ Screens: ${connectionInfo['rigCount']}'),
              if (connectionInfo['lastConnectionStatus'] != null)
                Text('🕒 ${connectionInfo['lastConnectionStatus']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],

            if (!isConnected && lgProvider.connectionError != null) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Text(
                  '❌ ${lgProvider.connectionError}',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚡ Quick Actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 12),

            Consumer2<LiquidGalaxyProvider, UpdatedDisasterProvider>(
              builder: (context, lgProvider, disasterProvider, child) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: lgProvider.isUploadingKML ? null : () => _syncCurrentData(disasterProvider),
                      icon: lgProvider.isUploadingKML
                          ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.sync),
                      label: Text('Sync Current Data'),
                    ),
                    ElevatedButton.icon(
                      onPressed: lgProvider.isUploadingKML ? null : () => _syncCurrentData(disasterProvider, forceTour: true),
                      icon: Icon(Icons.tour),
                      label: Text('Send Tour'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _clearLG(lgProvider),
                      icon: Icon(Icons.clear_all),
                      label: Text('Clear Display'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _restartGoogleEarth(lgProvider),
                      icon: Icon(Icons.restart_alt),
                      label: Text('Restart GE'),
                    ),
                  ],
                );
              },
            ),

            SizedBox(height: 12),

            // Auto-sync toggle
            Consumer<UpdatedDisasterProvider>(
              builder: (context, disasterProvider, child) {
                return SwitchListTile(
                  title: Text('Auto-sync to Liquid Galaxy'),
                  subtitle: Text('Automatically sync disaster data updates'),
                  value: disasterProvider.autoSyncToLG,
                  onChanged: (value) => disasterProvider.setAutoSyncToLG(value),
                  secondary: Icon(Icons.sync),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTab() {
    return Consumer<LiquidGalaxyProvider>(
      builder: (context, lgProvider, child) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // System Status Card
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🖥️ System Status',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 16),

                      if (lgProvider.isConnected) ...[
                        FutureBuilder<String?>(
                          future: lgProvider.getLiquidGalaxyStatus(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Row(
                                children: [
                                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                  SizedBox(width: 8),
                                  Text('Checking system status...'),
                                ],
                              );
                            }

                            final status = snapshot.data ?? 'Unknown';
                            return Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: status.contains('running') ? Colors.green.shade50 : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: status.contains('running') ? Colors.green.shade300 : Colors.orange.shade300,
                                ),
                              ),
                              child: Text(
                                '📊 $status',
                                style: TextStyle(
                                  color: status.contains('running') ? Colors.green.shade700 : Colors.orange.shade700,
                                ),
                              ),
                            );
                          },
                        ),

                        SizedBox(height: 16),

                        // Connection Details
                        _buildStatusRow('Host', '${lgProvider.currentHost}:${lgProvider.currentPort}'),
                        _buildStatusRow('Username', lgProvider.currentUsername ?? 'Unknown'),
                        _buildStatusRow('Screen Count', '${lgProvider.rigCount ?? 0}'),
                        _buildStatusRow('Connection Time', 'Active'),

                      ] else ...[
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Text(
                            '❌ Not connected to Liquid Galaxy',
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Last Upload Info
              if (lgProvider.lastUploadedKML != null) ...[
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📤 Last Upload',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: 12),
                        _buildStatusRow('File Name', lgProvider.lastUploadedKML!),
                        _buildStatusRow('Upload Time', _formatDateTime(lgProvider.lastKMLUploadTime!)),
                        if (lgProvider.kmlUploadError != null)
                          _buildStatusRow('Error', lgProvider.kmlUploadError!, isError: true),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],

              // Actions
              if (lgProvider.isConnected) ...[
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🔧 System Actions',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _refreshStatus(),
                                icon: Icon(Icons.refresh),
                                label: Text('Refresh Status'),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _restartGoogleEarth(lgProvider),
                                icon: Icon(Icons.restart_alt),
                                label: Text('Restart GE'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatisticsTab() {
    return Consumer<LiquidGalaxyProvider>(
      builder: (context, lgProvider, child) {
        final stats = lgProvider.getUploadStatistics();

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Upload Statistics
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📊 Upload Statistics',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total Uploads',
                              '${stats['totalUploads']}',
                              Icons.upload,
                              Colors.blue,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                              'Successful',
                              '${stats['successfulUploads']}',
                              Icons.check_circle,
                              Colors.green,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                              'Failed',
                              '${stats['failedUploads']}',
                              Icons.error,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Success Rate
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade300),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Success Rate',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${stats['successRate'].toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (stats['lastUploadTime'] != null) ...[
                        SizedBox(height: 12),
                        Text(
                          'Last Upload: ${_formatDateTime(DateTime.parse(stats['lastUploadTime']))}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Actions
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔧 Statistics Actions',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            lgProvider.resetStatistics();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Statistics reset successfully')),
                            );
                          },
                          icon: Icon(Icons.refresh),
                          label: Text('Reset Statistics'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isError ? Colors.red : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Action Methods
  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isTestingConnection = true;
    });

    final lgProvider = context.read<LiquidGalaxyProvider>();

    final success = await lgProvider.testConnection(
      host: _hostController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      port: int.parse(_portController.text),
    );

    setState(() {
      _isTestingConnection = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? ' Connection test successful!'
            : ' Connection test failed'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;

    final lgProvider = context.read<LiquidGalaxyProvider>();

    final success = await lgProvider.connectToLiquidGalaxy(
      host: _hostController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      port: int.parse(_portController.text),
      rigCount: int.parse(_rigCountController.text),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? ' Connected to Liquid Galaxy successfully!'
            : ' Failed to connect to Liquid Galaxy'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      _tabController.animateTo(1); // Switch to status tab
    }
  }

  Future<void> _disconnect() async {
    final lgProvider = context.read<LiquidGalaxyProvider>();
    await lgProvider.disconnect();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🔌 Disconnected from Liquid Galaxy')),
    );
  }

  Future<void> _syncCurrentData(UpdatedDisasterProvider disasterProvider, {bool forceTour = false}) async {
    final success = await disasterProvider.syncToLiquidGalaxy(forceTour: forceTour);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? ' Data synced to Liquid Galaxy!'
            : ' Failed to sync data'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _clearLG(LiquidGalaxyProvider lgProvider) async {
    final success = await lgProvider.clearLiquidGalaxy();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? ' Liquid Galaxy display cleared!'
            : ' Failed to clear display'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _restartGoogleEarth(LiquidGalaxyProvider lgProvider) async {
    final success = await lgProvider.restartGoogleEarth();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? ' Google Earth restarted!'
            : ' Failed to restart Google Earth'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  void _refreshStatus() {
    setState(() {}); // Trigger rebuild to refresh FutureBuilder
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
