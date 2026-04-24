import 'dart:async';

import 'package:flutter/material.dart';

import '../models/health_data.dart';
import '../services/data_service.dart';
import '../services/health_rules.dart';
import '../services/settings_service.dart';
import '../services/voice_service.dart';
import '../widgets/mini_graph.dart';
import 'alerts_screen.dart';
import 'bluetooth_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DataService dataService;
  StreamSubscription<Map<String, double>>? _subscription;

  final bpmData = <HealthData>[];
  final spo2Data = <HealthData>[];
  final tempData = <HealthData>[];
  final gestureData = <HealthData>[];
  final fallData = <HealthData>[];
  final batteryData = <HealthData>[];

  int lastSpokenGesture = 0;
  bool useDummy = true;

  @override
  void initState() {
    super.initState();
    dataService = DataService();

    if (useDummy) {
      dataService.startDummyData(context);
    }

    _seedGraphsFromHistory();
    _subscription = dataService.stream.listen(_handleReading);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _seedGraphsFromHistory() {
    final recent = dataService.history.length > 24
        ? dataService.history.sublist(dataService.history.length - 24)
        : dataService.history;

    for (final entry in recent) {
      _appendEntry(entry, notify: false);
    }
  }

  void _handleReading(Map<String, double> data) {
    final entry = dataService.latestData;
    if (entry == null || !mounted) return;

    setState(() => _appendEntry(entry));
    _handleGestureVoice((entry['gesture'] as num).toInt());
  }

  void _appendEntry(Map<String, dynamic> entry, {bool notify = true}) {
    final time = entry['time'] is DateTime
        ? entry['time'] as DateTime
        : DateTime.now();
    _updateData(bpmData, (entry['bpm'] as num).toDouble(), time);
    _updateData(spo2Data, (entry['spo2'] as num).toDouble(), time);
    _updateData(tempData, (entry['temp'] as num).toDouble(), time);
    _updateData(gestureData, (entry['gesture'] as num).toDouble(), time);
    _updateData(fallData, (entry['fall'] as num).toDouble(), time);
    _updateData(batteryData, (entry['battery'] as num).toDouble(), time);
  }

  void _updateData(List<HealthData> list, double value, DateTime time) {
    list.add(HealthData(value, time));
    if (list.length > 24) list.removeAt(0);
  }

  void _handleGestureVoice(int gesture) {
    if (gesture == 0) {
      lastSpokenGesture = 0;
      return;
    }

    if (gesture == lastSpokenGesture) return;
    lastSpokenGesture = gesture;

    if (SettingsService().soundEnabled) {
      VoiceService.speak(HealthRules.gestureText(gesture));
    }
  }

  @override
  Widget build(BuildContext context) {
    final latest = dataService.latestData;
    final status = HealthRules.overallStatus(latest);
    final statusColor = _statusColor(status);
    final battery = _latestValue(batteryData, fallback: 0);
    final hasFall = _latestValue(fallData, fallback: 0) >= 5;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1C),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0A0F1C),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _openTab,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bluetooth),
            label: 'Bluetooth',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              _header(status, statusColor, battery),
              const SizedBox(height: 16),
              _statusStrip(latest),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: .98,
                children: [
                  buildCard(
                    value: '${_latestValue(bpmData).toStringAsFixed(0)} BPM',
                    label: 'Heart Rate',
                    icon: Icons.favorite,
                    color: _vitalColor('bpm', _latestValue(bpmData)),
                    graphData: bpmData,
                  ),
                  buildCard(
                    value: '${_latestValue(spo2Data).toStringAsFixed(0)}%',
                    label: 'SpO2',
                    icon: Icons.water_drop,
                    color: _vitalColor('spo2', _latestValue(spo2Data)),
                    graphData: spo2Data,
                  ),
                  buildCard(
                    value: '${_latestValue(tempData).toStringAsFixed(1)} C',
                    label: 'Temperature',
                    icon: Icons.thermostat,
                    color: _vitalColor('temp', _latestValue(tempData)),
                    graphData: tempData,
                  ),
                  buildCard(
                    value: HealthRules.gestureText(
                      _latestValue(gestureData).toInt(),
                    ),
                    label: 'Gesture',
                    icon: Icons.pan_tool,
                    color: _latestValue(gestureData) > 0
                        ? Colors.cyan
                        : Colors.green,
                    graphData: gestureData,
                  ),
                  buildCard(
                    value: hasFall ? 'Fall Detected' : 'No Fall',
                    label: 'Fall Detection',
                    icon: Icons.warning_amber_rounded,
                    color: hasFall ? Colors.red : Colors.green,
                    graphData: fallData,
                  ),
                  buildCard(
                    value: '${battery.toStringAsFixed(0)}%',
                    label: 'Battery',
                    icon: Icons.battery_5_bar,
                    color: battery < 20
                        ? Colors.red
                        : battery < 50
                        ? Colors.orange
                        : Colors.green,
                    graphData: batteryData,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(String status, Color statusColor, double battery) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'KineSentry Hub',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Icon(Icons.circle, color: statusColor, size: 10),
                const SizedBox(width: 6),
                Text(status, style: TextStyle(color: statusColor)),
              ],
            ),
          ],
        ),
        Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 62,
                  width: 62,
                  child: CircularProgressIndicator(
                    value: (battery / 100).clamp(0, 1),
                    strokeWidth: 6,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation(
                      battery < 20
                          ? Colors.red
                          : battery < 50
                          ? Colors.orange
                          : Colors.green,
                    ),
                  ),
                ),
                Text(
                  '${battery.toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 5),
            const Text(
              'Battery',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statusStrip(Map<String, dynamic>? latest) {
    final time = latest?['time'] is DateTime
        ? latest!['time'] as DateTime
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF121A2F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.sync, color: Colors.blue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              time == null
                  ? 'Waiting for first hub reading'
                  : 'Synced ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} | ${dataService.history.length} readings',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    required List<HealthData> graphData,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF121A2F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Container(
                height: 8,
                width: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label, style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 8),
          Expanded(
            child: MiniGraph(data: graphData, color: color, label: label),
          ),
        ],
      ),
    );
  }

  void _openTab(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ReportsScreen()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AlertsScreen()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BluetoothScreen()),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
    }
  }

  double _latestValue(List<HealthData> list, {double fallback = 0}) {
    return list.isEmpty ? fallback : list.last.value;
  }

  Color _statusColor(String status) {
    if (status == 'Critical') return Colors.red;
    if (status == 'Warning') return Colors.orange;
    return Colors.green;
  }

  Color _vitalColor(String key, double value) {
    if (key == 'spo2') {
      if (value < 92) return Colors.red;
      if (value < 95) return Colors.orange;
      return Colors.blue;
    }

    if (key == 'bpm') {
      if (value > 110 || value < 50) return Colors.red;
      if (value > 100 || value < 55) return Colors.orange;
      return Colors.redAccent;
    }

    if (key == 'temp') {
      if (value > 38 || value < 35) return Colors.red;
      if (value > 37.5) return Colors.orange;
      return Colors.orangeAccent;
    }

    return Colors.blue;
  }
}
