// lib/main.dart
// Week 4 Implementation: Fixed all errors - Complete main app with Liquid Galaxy integration

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import 'models/disaster_event.dart';
import 'providers/updated_disaster_provider.dart';
import 'providers/liquid_galaxy_provider.dart';
import 'screens/liquid_galaxy_connection_screen.dart';

void main() {
  runApp(CatastropheVisualizerApp());
}

class CatastropheVisualizerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LiquidGalaxyProvider()),
        ChangeNotifierProvider(create: (context) => UpdatedDisasterProvider()..initialize()),
      ],
      child: MaterialApp(
        title: 'Catastrophe Visualizer - Week 4',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Color(0xFF0D1421),
          appBarTheme: AppBarTheme(
            backgroundColor: Color(0xFF1E2832),
            elevation: 2,
          ),
          cardTheme: CardTheme(
            color: Color(0xFF1E2832),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        home: Week4TestScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class Week4TestScreen extends StatefulWidget {
  @override
  _Week4TestScreenState createState() => _Week4TestScreenState();
}

class _Week4TestScreenState extends State<Week4TestScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🌍 Catastrophe Visualizer - Week 4'),
        actions: [
          Consumer2<UpdatedDisasterProvider, LiquidGalaxyProvider>(
            builder: (context, disasterProvider, lgProvider, child) {
              return Row(
                children: [
                  // LG Connection Status
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: lgProvider.isConnected ? Colors.green.withOpacity(
                          0.2) : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: lgProvider.isConnected ? Colors.green : Colors
                            .red,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          lgProvider.isConnected ? Icons.wifi : Icons.wifi_off,
                          size: 16,
                          color: lgProvider.isConnected ? Colors.green : Colors
                              .red,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'LG',
                          style: TextStyle(
                            fontSize: 12,
                            color: lgProvider.isConnected
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: 8),

                  // Loading indicator
                  if (disasterProvider.isLoading)
                    Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),

                  // Refresh button
                  IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: disasterProvider.isLoading ? null : () =>
                        disasterProvider.refreshData(),
                    tooltip: 'Refresh disaster data',
                  ),

                  // Auto-refresh toggle
                  IconButton(
                    icon: Icon(disasterProvider.autoRefreshEnabled
                        ? Icons.pause
                        : Icons.play_arrow),
                    onPressed: () => disasterProvider.setAutoRefresh(
                        !disasterProvider.autoRefreshEnabled),
                    tooltip: disasterProvider.autoRefreshEnabled
                        ? 'Pause auto-refresh'
                        : 'Start auto-refresh',
                  ),

                  // LG Connection screen
                  IconButton(
                    icon: Icon(Icons.monitor),
                    onPressed: () =>
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) =>
                              LiquidGalaxyConnectionScreen()),
                        ),
                    tooltip: 'Liquid Galaxy Settings',
                  ),
                ],
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.filter_list), text: 'Filters'),
            Tab(icon: Icon(Icons.code), text: 'KML'),
            Tab(icon: Icon(Icons.analytics), text: 'Stats'),
            Tab(icon: Icon(Icons.monitor), text: 'Liquid Galaxy'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildFiltersTab(),
          _buildKMLTab(),
          _buildStatisticsTab(),
          _buildLiquidGalaxyTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer<UpdatedDisasterProvider>(
      builder: (context, provider, child) {
        return RefreshIndicator(
          onRefresh: () => provider.refreshData(),
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Week 4: Enhanced Status Cards
                Row(
                  children: [
                    Expanded(child: _buildStatusCard(
                        'Total', '${provider.totalDisasters}', Colors.blue,
                        Icons.public)),
                    SizedBox(width: 8),
                    Expanded(child: _buildStatusCard(
                        'Filtered', '${provider.filteredCount}', Colors.green,
                        Icons.filter_list)),
                    SizedBox(width: 8),
                    Expanded(child: _buildStatusCard(
                        'Critical', '${provider.criticalDisasters}', Colors.red,
                        Icons.warning)),
                  ],
                ),

                SizedBox(height: 8),

                // Week 4: Recent Updates Row
                Row(
                  children: [
                    Expanded(child: _buildStatusCard(
                        'Recent Updates', '${provider.recentUpdatesCount}',
                        Colors.orange, Icons.update)),
                    SizedBox(width: 8),
                    Expanded(child: _buildStatusCard(
                        'Active', '${provider.activeDisasters}', Colors.purple,
                        Icons.radio_button_checked)),
                  ],
                ),

                SizedBox(height: 16),

                // Week 4: LG Sync Status
                Consumer<LiquidGalaxyProvider>(
                  builder: (context, lgProvider, child) {
                    return Card(
                      color: lgProvider.isConnected
                          ? Colors.green.shade900
                          : Colors.red.shade900,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              lgProvider.isConnected ? Icons.monitor : Icons
                                  .monitor_outlined,
                              color: lgProvider.isConnected ? Colors.green
                                  .shade200 : Colors.red.shade200,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lgProvider.isConnected
                                        ? '🟢 Liquid Galaxy Connected'
                                        : '🔴 Liquid Galaxy Disconnected',
                                    style: TextStyle(
                                      color: lgProvider.isConnected ? Colors
                                          .green.shade100 : Colors.red.shade100,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (lgProvider.isConnected) ...[
                                    Text(
                                      'Host: ${lgProvider
                                          .currentHost} | Auto-sync: ${provider
                                          .autoSyncToLG ? "ON" : "OFF"}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green.shade200,
                                      ),
                                    ),
                                    if (provider.lastLGSync != null)
                                      Text(
                                        'Last sync: ${_formatTime(
                                            provider.lastLGSync!)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green.shade300,
                                        ),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                            if (lgProvider.isConnected &&
                                provider.filteredDisasters.isNotEmpty)
                              ElevatedButton.icon(
                                onPressed: lgProvider.isUploadingKML
                                    ? null
                                    : () => _quickSyncToLG(provider),
                                icon: lgProvider.isUploadingKML
                                    ? SizedBox(width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                    : Icon(Icons.sync, size: 16),
                                label: Text('Sync Now'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  minimumSize: Size(0, 32),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: 16),

                // Connection Status
                _buildConnectionStatus(provider),

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
                          Expanded(child: Text(provider.error!,
                              style: TextStyle(color: Colors.red.shade100))),
                        ],
                      ),
                    ),
                  ),

                SizedBox(height: 16),

                // Week 4: Recent Updates Section
                if (provider.recentUpdates.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.update, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('🆕 Recent Updates (${provider.recentUpdates
                                  .length})',
                                  style: Theme
                                      .of(context)
                                      .textTheme
                                      .titleMedium),
                            ],
                          ),
                          SizedBox(height: 12),
                          ...provider.recentUpdates.take(5).map((disaster) =>
                              _buildCompactDisasterTile(
                                  disaster, isUpdate: true)),
                          if (provider.recentUpdates.length > 5)
                            Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Center(
                                child: Text(
                                  'Showing 5 of ${provider.recentUpdates
                                      .length} recent updates',
                                  style: Theme
                                      .of(context)
                                      .textTheme
                                      .bodySmall,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                ],

                // Auto-refresh controls
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('⚙️ Sync Settings', style: Theme
                            .of(context)
                            .textTheme
                            .titleMedium),
                        SizedBox(height: 12),

                        SwitchListTile(
                          title: Text('Auto-Refresh Data'),
                          subtitle: Text(
                              'Fetch new data every ${provider.refreshInterval
                                  .inMinutes} minutes'),
                          value: provider.autoRefreshEnabled,
                          onChanged: (value) => provider.setAutoRefresh(value),
                          secondary: Icon(Icons.refresh),
                        ),

                        Consumer<LiquidGalaxyProvider>(
                          builder: (context, lgProvider, child) {
                            return SwitchListTile(
                              title: Text('Auto-Sync to Liquid Galaxy'),
                              subtitle: Text(lgProvider.isConnected
                                  ? 'Automatically sync filtered data to LG'
                                  : 'Connect to Liquid Galaxy first'),
                              value: provider.autoSyncToLG,
                              onChanged: lgProvider.isConnected
                                  ? (value) => provider.setAutoSyncToLG(value)
                                  : null,
                              secondary: Icon(Icons.monitor),
                            );
                          },
                        ),

                        if (provider.lastUpdate != null)
                          Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Last updated: ${_formatDateTime(
                                  provider.lastUpdate!)}',
                              style: Theme
                                  .of(context)
                                  .textTheme
                                  .bodySmall,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Recent Disasters List
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('🌍 Recent Disasters', style: Theme
                                .of(context)
                                .textTheme
                                .titleLarge),
                            TextButton(
                              onPressed: () => _tabController.animateTo(1),
                              child: Text('Filter'),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        if (provider.filteredDisasters.isEmpty)
                          Center(
                            child: Column(
                              children: [
                                Icon(Icons.search_off, size: 48,
                                    color: Colors.grey),
                                SizedBox(height: 8),
                                Text('No disasters match current filters'),
                                TextButton(
                                  onPressed: () => provider.clearAllFilters(),
                                  child: Text('Clear Filters'),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: math.min(
                                provider.filteredDisasters.length, 10),
                            itemBuilder: (context, index) {
                              final disaster = provider
                                  .filteredDisasters[index];
                              return _buildDisasterListTile(disaster);
                            },
                          ),
                        if (provider.filteredDisasters.length > 10)
                          Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Center(
                              child: Text(
                                'Showing 10 of ${provider.filteredDisasters
                                    .length} disasters',
                                style: Theme
                                    .of(context)
                                    .textTheme
                                    .bodySmall,
                              ),
                            ),
                          ),
                      ],
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

  Widget _buildFiltersTab() {
    return Consumer<UpdatedDisasterProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Actions
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quick Actions', style: Theme
                          .of(context)
                          .textTheme
                          .titleMedium),
                      SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => provider.clearAllFilters(),
                            icon: Icon(Icons.clear_all),
                            label: Text('Clear All'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => provider.setSeverityFilter({
                              SeverityLevel.critical,
                              SeverityLevel.high
                            }),
                            icon: Icon(Icons.warning),
                            label: Text('High Risk Only'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => provider.setDateFilter(
                                DateTime.now().subtract(Duration(days: 1)),
                                null),
                            icon: Icon(Icons.today),
                            label: Text('Last 24h'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Disaster Types Filter
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Disaster Types', style: Theme
                          .of(context)
                          .textTheme
                          .titleMedium),
                      SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: DisasterType.values.map((type) {
                          final isSelected = provider.selectedTypes.contains(
                              type);
                          return FilterChip(
                            label: Text(type.displayName),
                            selected: isSelected,
                            onSelected: (selected) {
                              final newTypes = Set<DisasterType>.from(
                                  provider.selectedTypes);
                              if (selected) {
                                newTypes.add(type);
                              } else {
                                newTypes.remove(type);
                              }
                              provider.setTypeFilter(newTypes);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Severity Filter
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Severity Levels', style: Theme
                          .of(context)
                          .textTheme
                          .titleMedium),
                      SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: SeverityLevel.values.map((severity) {
                          final isSelected = provider.selectedSeverities
                              .contains(severity);
                          return FilterChip(
                            label: Text(severity.displayName),
                            selected: isSelected,
                            backgroundColor: _getSeverityColor(severity)
                                .withOpacity(0.1),
                            selectedColor: _getSeverityColor(severity)
                                .withOpacity(0.3),
                            onSelected: (selected) {
                              final newSeverities = Set<SeverityLevel>.from(
                                  provider.selectedSeverities);
                              if (selected) {
                                newSeverities.add(severity);
                              } else {
                                newSeverities.remove(severity);
                              }
                              provider.setSeverityFilter(newSeverities);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Additional Filters
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Additional Filters', style: Theme
                          .of(context)
                          .textTheme
                          .titleMedium),
                      SizedBox(height: 12),

                      SwitchListTile(
                        title: Text('Active Events Only'),
                        subtitle: Text('Show only currently active disasters'),
                        value: provider.showActiveOnly,
                        onChanged: (value) =>
                            provider.setActiveOnlyFilter(value),
                      ),

                      // Magnitude Filter
                      ListTile(
                        title: Text('Minimum Magnitude: ${provider
                            .minimumMagnitude.toStringAsFixed(1)}'),
                        subtitle: Slider(
                          value: provider.minimumMagnitude,
                          min: 0.0,
                          max: 10.0,
                          divisions: 20,
                          onChanged: (value) =>
                              provider.setMagnitudeFilter(value),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Filter Summary
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Filter Results', style: Theme
                          .of(context)
                          .textTheme
                          .titleMedium),
                      SizedBox(height: 8),
                      Text('${provider.filteredCount} of ${provider
                          .totalDisasters} disasters match your filters'),
                      if (provider.filteredCount != provider.totalDisasters)
                        TextButton(
                          onPressed: () => provider.clearAllFilters(),
                          child: Text('Clear All Filters'),
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

  Widget _buildKMLTab() {
    return Consumer2<UpdatedDisasterProvider, LiquidGalaxyProvider>(
      builder: (context, provider, lgProvider, child) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('KML Generation & Sync', style: Theme
                          .of(context)
                          .textTheme
                          .titleLarge),
                      SizedBox(height: 16),

                      if (lgProvider.isConnected) ...[
                        Text(
                            '✅ Connected to Liquid Galaxy - KML will be sent automatically'),
                        SizedBox(height: 16),
                      ] else
                        ...[
                          Text(
                              '⚠️ Not connected to Liquid Galaxy - KML will be shown for copy/paste'),
                          SizedBox(height: 16),
                        ],

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: provider.filteredDisasters.isEmpty
                                  ? null
                                  : () =>
                                  _generateKML(provider, lgProvider, false),
                              icon: Icon(Icons.map),
                              label: Text('Generate Standard KML'),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: provider.filteredDisasters.isEmpty
                                  ? null
                                  : () =>
                                  _generateKML(provider, lgProvider, true),
                              icon: Icon(Icons.tour),
                              label: Text('Generate Tour KML'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // KML Preview Stats
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('KML Content Preview', style: Theme
                          .of(context)
                          .textTheme
                          .titleMedium),
                      SizedBox(height: 12),

                      if (provider.filteredDisasters.isEmpty)
                        Text('No disasters to include in KML',
                            style: TextStyle(color: Colors.grey))
                      else
                        Column(
                          children: [
                            _buildKMLStatRow('Total Placemarks',
                                '${provider.filteredDisasters.length}'),
                            _buildKMLStatRow('Earthquake Events', '${provider
                                .getDisastersByType(DisasterType.earthquake)
                                .length}'),
                            _buildKMLStatRow('Wildfire Events', '${provider
                                .getDisastersByType(DisasterType.wildfire)
                                .length}'),
                            _buildKMLStatRow('Hurricane Events', '${provider
                                .getDisastersByType(DisasterType.hurricane)
                                .length}'),
                            _buildKMLStatRow('Flood Events', '${provider
                                .getDisastersByType(DisasterType.flood)
                                .length}'),
                            Divider(),
                            _buildKMLStatRow('Critical Severity', '${provider
                                .getDisastersBySeverity(SeverityLevel.critical)
                                .length}'),
                            _buildKMLStatRow('High Severity', '${provider
                                .getDisastersBySeverity(SeverityLevel.high)
                                .length}'),
                            _buildKMLStatRow('Medium Severity', '${provider
                                .getDisastersBySeverity(SeverityLevel.medium)
                                .length}'),
                            _buildKMLStatRow('Low Severity', '${provider
                                .getDisastersBySeverity(SeverityLevel.low)
                                .length}'),
                          ],
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

  Widget _buildStatisticsTab() {
    return Consumer<UpdatedDisasterProvider>(
      builder: (context, provider, child) {
        if (provider.statistics.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No statistics available'),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => provider.refreshData(),
                  child: Text('Load Data'),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Summary stats
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Global Summary', style: Theme
                          .of(context)
                          .textTheme
                          .titleLarge),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildStatCard(
                              'Total', '${provider.totalDisasters}',
                              Icons.public, Colors.blue)),
                          SizedBox(width: 8),
                          Expanded(child: _buildStatCard(
                              'Active', '${provider.activeDisasters}',
                              Icons.warning, Colors.orange)),
                          SizedBox(width: 8),
                          Expanded(child: _buildStatCard(
                              'Critical', '${provider.criticalDisasters}',
                              Icons.crisis_alert, Colors.red)),
                        ],
                      ),

                      SizedBox(height: 16),

                      if (provider.statistics['averageMagnitude'] != null)
                        Text('Average Magnitude: ${(provider
                            .statistics['averageMagnitude'] as double)
                            .toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Recent Trends
              if (provider.statistics['recentTrends'] != null)
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Recent Trends', style: Theme
                            .of(context)
                            .textTheme
                            .titleMedium),
                        SizedBox(height: 12),

                        Builder(
                          builder: (context) {
                            final trends = (provider
                                .statistics['recentTrends'] ??
                                <String, int>{}) as Map<String, int>;
                            return Column(
                              children: [
                                _buildTrendRow('Last 24 Hours',
                                    trends['last24Hours'] ?? 0),
                                _buildTrendRow(
                                    'Last 7 Days', trends['last7Days'] ?? 0),
                                _buildTrendRow(
                                    'Last 30 Days', trends['last30Days'] ?? 0),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

              SizedBox(height: 16),

              // Distribution by Type
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Distribution by Type', style: Theme
                          .of(context)
                          .textTheme
                          .titleMedium),
                      SizedBox(height: 12),

                      ...DisasterType.values.map((type) {
                        final count = provider.disastersByType[type] ?? 0;
                        final percentage = provider.totalDisasters > 0
                            ? (count / provider.totalDisasters * 100)
                            .toStringAsFixed(1)
                            : '0';

                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(_getDisasterIcon(type), size: 20),
                              SizedBox(width: 8),
                              Expanded(child: Text(type.displayName)),
                              Text('$count ($percentage%)'),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Distribution by Severity
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Distribution by Severity', style: Theme
                          .of(context)
                          .textTheme
                          .titleMedium),
                      SizedBox(height: 12),

                      ...SeverityLevel.values.map((severity) {
                        final count = provider.disastersBySeverity[severity] ??
                            0;
                        final percentage = provider.totalDisasters > 0
                            ? (count / provider.totalDisasters * 100)
                            .toStringAsFixed(1)
                            : '0';

                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: _getSeverityColor(severity),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(child: Text(severity.displayName)),
                              Text('$count ($percentage%)'),
                            ],
                          ),
                        );
                      }).toList(),
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

  Widget _buildLiquidGalaxyTab() {
    return Consumer2<LiquidGalaxyProvider, UpdatedDisasterProvider>(
      builder: (context, lgProvider, disasterProvider, child) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Quick Connection Card
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            lgProvider.isConnected ? Icons.monitor : Icons
                                .monitor_outlined,
                            color: lgProvider.isConnected
                                ? Colors.green
                                : Colors.grey,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Liquid Galaxy Connection',
                            style: Theme
                                .of(context)
                                .textTheme
                                .titleMedium,
                          ),
                        ],
                      ),
                      SizedBox(height: 12),

                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: lgProvider.isConnected ? Colors.green
                              .withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: lgProvider.isConnected
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        child: Text(
                          lgProvider.isConnected
                              ? '🟢 Connected to ${lgProvider.currentHost}'
                              : '🔴 Not connected to Liquid Galaxy',
                          style: TextStyle(
                            color: lgProvider.isConnected
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      SizedBox(height: 12),

                      ElevatedButton.icon(
                        onPressed: () =>
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) =>
                                  LiquidGalaxyConnectionScreen()),
                            ),
                        icon: Icon(Icons.settings),
                        label: Text('Open Connection Settings'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 40),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Quick Actions (when connected)
              if (lgProvider.isConnected) ...[
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚡ Quick Actions',
                          style: Theme
                              .of(context)
                              .textTheme
                              .titleMedium,
                        ),
                        SizedBox(height: 12),

                        GridView.count(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 2.5,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          children: [
                            _buildActionButton(
                              'Sync Data',
                              Icons.sync,
                              lgProvider.isUploadingKML ? null : () =>
                                  _syncToLG(disasterProvider),
                              isLoading: lgProvider.isUploadingKML,
                            ),
                            _buildActionButton(
                              'Send Tour',
                              Icons.tour,
                              lgProvider.isUploadingKML ? null : () =>
                                  _sendTour(disasterProvider),
                              isLoading: lgProvider.isUploadingKML,
                            ),
                            _buildActionButton(
                              'Clear Display',
                              Icons.clear_all,
                                  () => _clearLG(lgProvider),
                            ),
                            _buildActionButton(
                              'Restart GE',
                              Icons.restart_alt,
                                  () => _restartGoogleEarth(lgProvider),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Upload Statistics
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📊 Upload Statistics',
                          style: Theme
                              .of(context)
                              .textTheme
                              .titleMedium,
                        ),
                        SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Total',
                                '${lgProvider.totalKMLUploads}',
                                Icons.upload,
                                Colors.blue,
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: _buildStatCard(
                                'Success',
                                '${lgProvider.successfulUploads}',
                                Icons.check_circle,
                                Colors.green,
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: _buildStatCard(
                                'Failed',
                                '${lgProvider.failedUploads}',
                                Icons.error,
                                Colors.red,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 12),

                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Success Rate',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${lgProvider.uploadSuccessRate.toStringAsFixed(
                                    1)}%',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
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

  // Helper Widgets
  Widget _buildActionButton(String label, IconData icon,
      VoidCallback? onPressed, {bool isLoading = false}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: isLoading
          ? SizedBox(width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(icon, size: 16),
      label: Text(label, style: TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Widget _buildCompactDisasterTile(DisasterEvent disaster,
      {bool isUpdate = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUpdate ? Colors.orange.withOpacity(0.1) : Colors.blue
            .withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUpdate ? Colors.orange.withOpacity(0.3) : Colors.blue
              .withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getSeverityColor(disaster.severity),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  disaster.title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${disaster.type.displayName} • ${disaster.severity
                      .displayName} • ${_formatTime(disaster.timestamp)}',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (isUpdate) Icon(Icons.update, size: 16, color: Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, String value, Color color,
      IconData icon) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon,
      Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(value, style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: TextStyle(fontSize: 10),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus(UpdatedDisasterProvider provider) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('API Status', style: Theme
                .of(context)
                .textTheme
                .titleMedium),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  provider.isOnline ? Icons.cloud_done : Icons.cloud_off,
                  color: provider.isOnline ? Colors.green : Colors.red,
                ),
                SizedBox(width: 8),
                Text(provider.isOnline ? 'Online' : 'Offline'),
              ],
            ),
            if (provider.apiStatus.isNotEmpty) ...[
              SizedBox(height: 8),
              ...provider.apiStatus.entries.map((entry) =>
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                          entry.value ? Icons.check_circle : Icons.error,
                          size: 16,
                          color: entry.value ? Colors.green : Colors.red,
                        ),
                        SizedBox(width: 8),
                        Text('${entry.key} API: ${entry.value
                            ? 'Connected'
                            : 'Failed'}'),
                      ],
                    ),
                  )).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDisasterListTile(DisasterEvent disaster) {
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
              'Magnitude: ${disaster.magnitude} • ${disaster.severity
                  .displayName}',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTime(disaster.timestamp),
              style: TextStyle(fontSize: 12),
            ),
            if (!disaster.isActive)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'INACTIVE',
                  style: TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
          ],
        ),
        onTap: () => _showDisasterDetails(disaster),
      ),
    );
  }

  Widget _buildKMLStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTrendRow(String period, int count) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(period),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(count.toString(),
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Action Methods
  Future<void> _quickSyncToLG(UpdatedDisasterProvider provider) async {
    final success = await provider.syncToLiquidGalaxy();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? '✅ Data synced to Liquid Galaxy!'
            : '❌ Failed to sync data'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _syncToLG(UpdatedDisasterProvider provider) async {
    final success = await provider.syncToLiquidGalaxy();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? '✅ ${provider.filteredDisasters
            .length} disasters synced to Liquid Galaxy!'
            : '❌ Failed to sync disasters'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _sendTour(UpdatedDisasterProvider provider) async {
    final success = await provider.syncToLiquidGalaxy(forceTour: true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? '✅ Disaster tour sent to Liquid Galaxy!'
            : '❌ Failed to send tour'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _clearLG(LiquidGalaxyProvider lgProvider) async {
    final success = await lgProvider.clearLiquidGalaxy();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? '✅ Liquid Galaxy display cleared!'
            : '❌ Failed to clear display'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _restartGoogleEarth(LiquidGalaxyProvider lgProvider) async {
    final success = await lgProvider.restartGoogleEarth();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? '✅ Google Earth restarted!'
            : '❌ Failed to restart Google Earth'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  void _generateKML(UpdatedDisasterProvider provider,
      LiquidGalaxyProvider lgProvider, bool isTour) {
    if (lgProvider.isConnected) {
      // If connected to LG, sync directly
      if (isTour) {
        _sendTour(provider);
      } else {
        _syncToLG(provider);
      }
    } else {
      // If not connected, show KML for copy/paste
      final kml = isTour ? provider.generateTourKML() : provider.generateKML();

      showDialog(
        context: context,
        builder: (context) =>
            AlertDialog(
              title: Text(
                  isTour ? 'Generated Tour KML' : 'Generated Standard KML'),
              content: Container(
                width: double.maxFinite,
                height: 400,
                child: SingleChildScrollView(
                  child: SelectableText(
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
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'KML copied to logs - check console for full content'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    print('=== GENERATED ${isTour
                        ? 'TOUR'
                        : 'STANDARD'} KML ===');
                    print(kml);
                    print('=== END KML ===');
                  },
                  child: Text('Copy to Console'),
                ),
              ],
            ),
      );
    }
  }

  void _showDisasterDetails(DisasterEvent disaster) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text(disaster.title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Type', disaster.type.displayName),
                  _buildDetailRow('Location', disaster.location),
                  _buildDetailRow('Magnitude', disaster.magnitude.toString()),
                  _buildDetailRow('Severity', disaster.severity.displayName),
                  _buildDetailRow('Time', _formatDateTime(disaster.timestamp)),
                  _buildDetailRow('Coordinates',
                      '${disaster.latitude.toStringAsFixed(4)}, ${disaster
                          .longitude.toStringAsFixed(4)}'),
                  _buildDetailRow(
                      'Status', disaster.isActive ? 'Active' : 'Inactive'),

                  if (disaster.affectedAreas.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text('Affected Areas:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    ...disaster.affectedAreas.map((area) =>
                        Padding(
                          padding: EdgeInsets.only(left: 16, top: 2),
                          child: Text('• $area'),
                        )).toList(),
                  ],

                  if (disaster.description.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text('Description:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text(disaster.description),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
              Consumer2<UpdatedDisasterProvider, LiquidGalaxyProvider>(
                builder: (context, disasterProvider, lgProvider, child) {
                  return ElevatedButton(
                    onPressed: lgProvider.isConnected
                        ? () {
                      Navigator.pop(context);
                      _syncSingleDisaster(disasterProvider, disaster);
                    }
                        : () {
                      Navigator.pop(context);
                      _generateSingleDisasterKML(disasterProvider, disaster);
                    },
                    child: Text(
                        lgProvider.isConnected ? 'Send to LG' : 'Generate KML'),
                  );
                },
              ),
            ],
          ),
    );
  }

  Future<void> _syncSingleDisaster(UpdatedDisasterProvider provider,
      DisasterEvent disaster) async {
    final success = await provider.syncSingleDisasterToLG(disaster);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? '✅ Disaster sent to Liquid Galaxy and camera positioned!'
            : '❌ Failed to send disaster'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  void _generateSingleDisasterKML(UpdatedDisasterProvider provider,
      DisasterEvent disaster) {
    final kml = provider.generateSingleDisasterKML(disaster);

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text('Single Disaster KML'),
            content: Container(
              width: double.maxFinite,
              height: 300,
              child: SingleChildScrollView(
                child: SelectableText(
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
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Single disaster KML copied to console'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  print('=== SINGLE DISASTER KML ===');
                  print(kml);
                  print('=== END KML ===');
                },
                child: Text('Copy to Console'),
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
            width: 100,
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

  // Helper Methods
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour
        .toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(
        2, '0')}';
  }
}
