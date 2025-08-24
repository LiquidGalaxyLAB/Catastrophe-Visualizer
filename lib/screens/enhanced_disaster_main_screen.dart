/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class EnhancedDisasterMainScreen extends StatefulWidget {
  @override
  _EnhancedDisasterMainScreenState createState() => _EnhancedDisasterMainScreenState();
}

class _EnhancedDisasterMainScreenState extends State<EnhancedDisasterMainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late EnhancedLgService _lgService;
  late DisasterApiService _disasterService;
  late LiquidGalaxySSHService _sshService;

  // Filter options
  String _selectedSeverity = 'All';
  double _minMagnitude = 2.5;
  int _recentHours = 168; // 7 days

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _sshService = LiquidGalaxySSHService();
    _lgService = EnhancedLgService(_sshService);
    _disasterService = Provider.of<DisasterApiService>(context, listen: false);

    // Load initial data
    _disasterService.fetchEarthquakes();
    _tryAutoConnect();
  }

  Future<void> _tryAutoConnect() async {
    final result = await _sshService.initializeFromPreferences();
    if (result == null) {
      print(' Auto-connected to LG from saved preferences');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Disaster Visualizer with LG'),
        backgroundColor: Colors.blue[900],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.list), text: 'Disasters'),
            Tab(icon: Icon(Icons.computer), text: 'Liquid Galaxy'),
          ],
        ),
        actions: [
          ChangeNotifierProvider.value(
            value: _sshService,
            child: Consumer<LiquidGalaxySSHService>(
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
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDisasterTab(),
          _buildLGTab(),
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
      margin: EdgeInsets.all(8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Disaster Overview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  if (service.isLoading)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  SizedBox(width: 8),
                  IconButton(
                    onPressed: service.isLoading ? null : () => service.fetchEarthquakes(),
                    icon: Icon(Icons.refresh),
                    tooltip: 'Refresh Data',
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Total', '${stats['total']}', Colors.blue),
              _buildStatCard('Extreme', '${stats['extreme']}', Colors.red),
              _buildStatCard('Recent 24h', '${stats['recent_24h']}', Colors.green),
              _buildStatCard('Magnitude 5+', '${service.getDisastersByMagnitude(5.0).length}', Colors.orange),
            ],
          ),
          if (service.lastUpdate != null)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Last updated: ${DateFormat('HH:mm').format(service.lastUpdate!)}',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[400]),
        ),
      ],
    );
  }

  Widget _buildFilterPanel(DisasterApiService service) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              // Severity Filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSeverity,
                  decoration: InputDecoration(
                    labelText: 'Severity',
                    border: OutlineInputBorder(),
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
              // Recent Hours Filter
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _recentHours,
                  decoration: InputDecoration(
                    labelText: 'Time Range',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  items: [
                    DropdownMenuItem(value: 24, child: Text('24 hours')),
                    DropdownMenuItem(value: 72, child: Text('3 days')),
                    DropdownMenuItem(value: 168, child: Text('7 days')),
                    DropdownMenuItem(value: 720, child: Text('30 days')),
                  ],
                  onChanged: (value) {
                    setState(() => _recentHours = value!);
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          // Magnitude Slider
          Row(
            children: [
              Text('Min Magnitude: ${_minMagnitude.toStringAsFixed(1)}'),
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
            Text('No disasters match your filters'),
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
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: disaster.severityColor,
          child: Icon(disaster.typeIcon, color: Colors.white),
        ),
        title: Text(
          disaster.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Magnitude: ${disaster.magnitude.toStringAsFixed(1)} • ${disaster.severity}'),
            Text(
              DateFormat('MMM dd, HH:mm').format(disaster.timestamp),
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
        trailing: ChangeNotifierProvider.value(
          value: _sshService,
          child: Consumer<LiquidGalaxySSHService>(
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
        ),
        onTap: () => _showDisasterDetails(disaster),
      ),
    );
  }

  Widget _buildLGTab() {
    return ChangeNotifierProvider.value(
      value: _sshService,
      child: Consumer<LiquidGalaxySSHService>(
        builder: (context, sshService, child) {
          if (!sshService.isConnected) {
            return _buildLGConnectionForm();
          } else {
            return _buildLGControls();
          }
        },
      ),
    );
  }

  Widget _buildLGConnectionForm() {
    final _formKey = GlobalKey<FormState>();
    final _ipController = TextEditingController(text: LgConnectionSharedPref.getIP() ?? '192.168.1.100');
    final _portController = TextEditingController(text: LgConnectionSharedPref.getPort() ?? '22');
    final _usernameController = TextEditingController(text: LgConnectionSharedPref.getUserName() ?? 'lg');
    final _passwordController = TextEditingController(text: LgConnectionSharedPref.getPassword() ?? 'lqgalaxy');
    final _screensController = TextEditingController(text: (LgConnectionSharedPref.getScreenAmount() ?? 3).toString());

    bool _isConnecting = false;
    bool _obscurePassword = true;

    return StatefulBuilder(
      builder: (context, setFormState) {
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

                // Connection Test Button
                Card(
                  color: Colors.blue[800],
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Connection Test',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Test your connection before full setup',
                          style: TextStyle(color: Colors.white70),
                        ),
                        SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _isConnecting ? null : () async {
                            if (!_formKey.currentState!.validate()) return;

                            setFormState(() => _isConnecting = true);

                            final sshModel = SSHModel(
                              host: _ipController.text.trim(),
                              port: int.parse(_portController.text.trim()),
                              username: _usernameController.text.trim(),
                              passwordOrKey: _passwordController.text,
                              screenAmount: int.parse(_screensController.text.trim()),
                            );

                            final success = await _lgService.testConnection(sshModel);

                            setFormState(() => _isConnecting = false);

                            _showSnackBar(
                              success ? 'Connection test passed!' : ' Connection test failed',
                              success ? Colors.green : Colors.red,
                            );
                          },
                          icon: _isConnecting
                              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : Icon(Icons.wifi_protected_setup),
                          label: Text(_isConnecting ? 'Testing...' : 'Test Connection'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20),

                TextFormField(
                  controller: _ipController,
                  decoration: InputDecoration(
                    labelText: 'LG IP Address',
                    hintText: '192.168.1.100',
                    prefixIcon: Icon(Icons.computer),
                    border: OutlineInputBorder(),
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
                          labelText: 'SSH Port',
                          hintText: '22',
                          prefixIcon: Icon(Icons.settings_ethernet),
                          border: OutlineInputBorder(),
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
                          hintText: '3',
                          prefixIcon: Icon(Icons.desktop_windows),
                          border: OutlineInputBorder(),
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
                    hintText: 'lg',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'lqgalaxy',
                    prefixIcon: Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setFormState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isConnecting ? null : () async {
                      if (!_formKey.currentState!.validate()) return;

                      setFormState(() => _isConnecting = true);

                      final sshModel = SSHModel(
                        host: _ipController.text.trim(),
                        port: int.parse(_portController.text.trim()),
                        username: _usernameController.text.trim(),
                        passwordOrKey: _passwordController.text,
                        screenAmount: int.parse(_screensController.text.trim()),
                      );

                      final success = await _lgService.connect(sshModel);

                      setFormState(() => _isConnecting = false);

                      _showSnackBar(
                        success ? ' Connected to LG!' : ' Connection failed',
                        success ? Colors.green : Colors.red,
                      );
                    },
                    icon: _isConnecting
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(Icons.link),
                    label: Text(_isConnecting ? 'Connecting...' : 'Connect to LG'),
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
      },
    );
  }

  Widget _buildLGControls() {
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
                        'Connected to ${_sshService.host}',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Screens: ${_sshService.rigCount} • Logo Screen: ${_lgService.logoScreen}',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _lgService.disconnect();
                    _showSnackBar('Disconnected from LG', Colors.orange);
                  },
                  child: Text('Disconnect'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Logo Controls with Options
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Logo Controls',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Your hosted logo: https://ibb.co/SDn9GjMK',
                    style: TextStyle(color: Colors.blue[300], fontSize: 12),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final success = await _lgService.setLogo(useHostedImage: true);
                            _showSnackBar(
                              success ? ' Hosted logo set on LG!' : ' Failed to set logo',
                              success ? Colors.green : Colors.red,
                            );
                          },
                          icon: Icon(Icons.cloud),
                          label: Text('Set Hosted Logo'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final success = await _lgService.setLogo(useHostedImage: false);
                            _showSnackBar(
                              success ? ' Local logo set on LG!' : ' Failed to set logo',
                              success ? Colors.green : Colors.red,
                            );
                          },
                          icon: Icon(Icons.image),
                          label: Text('Set Local Logo'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _lgService.clearLogo();
                        _showSnackBar(' Logo cleared', Colors.blue);
                      },
                      icon: Icon(Icons.clear),
                      label: Text('Clear Logo'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Disaster Controls
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Disaster Controls',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _lgService.clearDisasters();
                        _showSnackBar(' Cleared all disasters from LG', Colors.blue);
                      },
                      icon: Icon(Icons.clear_all),
                      label: Text('Clear All Disasters'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

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
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Reboot LG System'),
                            content: Text('This will reboot all LG screens. Continue?'),
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
                          await _lgService.reboot();
                          _showSnackBar(' Rebooting LG system...', Colors.orange);
                        }
                      },
                      icon: Icon(Icons.restart_alt),
                      label: Text('Reboot LG System'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(vertical: 16),
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
  }

  // Helper Methods
  Future<void> _sendDisasterToLG(Disaster disaster) async {
    final success = await _lgService.sendDisasterToLG(disaster);
    _showSnackBar(
      success ? '📡 ${disaster.title} sent to LG!' : ' Failed to send disaster to LG',
      success ? Colors.blue : Colors.red,
    );
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
            if (disaster.place != null)
              _buildDetailRow('Place', disaster.place!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ChangeNotifierProvider.value(
            value: _sshService,
            child: Consumer<LiquidGalaxySSHService>(
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
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _sshService.disconnect();
    super.dispose();
  }
}*/