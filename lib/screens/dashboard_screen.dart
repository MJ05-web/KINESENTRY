import 'dart:async';

import 'package:flutter/material.dart';

import '../models/health_data.dart';
import '../services/audio_device_service.dart';
import '../services/bluetooth_service.dart';
import '../services/data_service.dart';
import '../services/health_rules.dart';
import '../services/ml_insight_service.dart';
import '../services/session_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
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
  final audioDevices = AudioDeviceService();
  final bluetooth = MyBluetoothService();
  final settings = SettingsService();
  StreamSubscription<Map<String, double>>? _subscription;
  VoidCallback? _bluetoothListener;

  final bpmData = <HealthData>[];
  final spo2Data = <HealthData>[];
  final tempData = <HealthData>[];
  final gestureData = <HealthData>[];
  final fallData = <HealthData>[];
  final batteryData = <HealthData>[];
  final esp32Data = <HealthData>[];

  @override
  void initState() {
    super.initState();
    dataService = DataService();

    if (settings.dummyDataEnabled && !bluetooth.isEsp32Connected) {
      dataService.startDummyData();
    }

    audioDevices.refresh();
    _seedGraphsFromHistory();
    _subscription = dataService.stream.listen((_) {
      final entry = dataService.latestData;
      if (!mounted) return;
      setState(() {
        if (entry == null) {
          bpmData.clear();
          spo2Data.clear();
          tempData.clear();
          gestureData.clear();
          fallData.clear();
          batteryData.clear();
          esp32Data.clear();
          return;
        }
        _appendEntry(entry);
      });
    });

    _bluetoothListener = () {
      if (!mounted) return;
      setState(() {
        _pushPoint(
          esp32Data,
          bluetooth.isEsp32Connected ? 1 : 0,
          DateTime.now(),
        );
      });
    };
    bluetooth.addListener(_bluetoothListener!);
    _pushPoint(
      esp32Data,
      bluetooth.isEsp32Connected ? 1 : 0,
      DateTime.now(),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    if (_bluetoothListener != null) {
      bluetooth.removeListener(_bluetoothListener!);
    }
    super.dispose();
  }

  void _seedGraphsFromHistory() {
    final recent = dataService.history.length > 24
        ? dataService.history.sublist(dataService.history.length - 24)
        : dataService.history;

    for (final entry in recent) {
      _appendEntry(entry);
    }
  }

  void _appendEntry(Map<String, dynamic> entry) {
    final time = entry['time'] is DateTime
        ? entry['time'] as DateTime
        : DateTime.now();
    _pushPoint(bpmData, (entry['bpm'] as num).toDouble(), time);
    _pushPoint(spo2Data, (entry['spo2'] as num).toDouble(), time);
    _pushPoint(tempData, (entry['temp'] as num).toDouble(), time);
    _pushPoint(gestureData, (entry['gesture'] as num).toDouble(), time);
    _pushPoint(fallData, (entry['fall'] as num).toDouble(), time);
    _pushPoint(batteryData, (entry['battery'] as num).toDouble(), time);
    _pushPoint(esp32Data, bluetooth.isEsp32Connected ? 1 : 0, time);
  }

  void _pushPoint(List<HealthData> list, double value, DateTime time) {
    list.add(HealthData(value, time));
    if (list.length > 24) list.removeAt(0);
  }

  @override
  Widget build(BuildContext context) {
    final latest = dataService.latestData;
    final status = HealthRules.overallStatus(latest);
    final statusColor = _statusColor(status);
    final bleConnected = bluetooth.isEsp32Connected;
    final gesture = _latestValue(gestureData).toInt();
    final fallDetected = _latestValue(fallData) > 0;
    final ml = MlInsightService.analyze(dataService.recordedVitalHistory);
    final dashboardLogo = AppThemeColors.isDark(context)
        ? 'assets/images/logo_dark.jpg'
        : 'assets/images/logo.png';

    return AnimatedBuilder(
      animation: Listenable.merge([audioDevices, bluetooth, settings, dataService]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          bottomNavigationBar: BottomNavigationBar(
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
          body: AppChrome(
            padding: const EdgeInsets.fromLTRB(15, 8, 15, 18),
            safeBottom: true,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        dashboardLogo,
                        height: 52,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: const AccentHeadline(
                          title: 'Live Monitoring',
                          subtitle:
                              'Vitals, alerts, and predictions aligned in one flowing care view.',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: PopupMenuButton<String>(
                          color: AppThemeColors.panel(context),
                          icon: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppThemeColors.accent(context).withValues(alpha: .18),
                                  AppThemeColors.accentSecondary(context)
                                      .withValues(alpha: .18),
                                ],
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: AppThemeColors.panel(context),
                              child: Icon(
                                Icons.person_outline,
                                color: AppThemeColors.textPrimary(context),
                              ),
                            ),
                          ),
                          onSelected: (value) async {
                            if (value == 'settings') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SettingsScreen(),
                                ),
                              );
                            } else if (value == 'logout') {
                              await SessionService.logout(context);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'settings',
                              child: Text(
                                'Settings',
                                style: TextStyle(
                                  color: AppThemeColors.textPrimary(context),
                                ),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'logout',
                              child: Text(
                                'Logout',
                                style: TextStyle(
                                  color: AppThemeColors.danger(context),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _statusHero(status, statusColor, bleConnected),
                  const SizedBox(height: 16),
                  _statusIcons(),
                  const SizedBox(height: 16),
                  _syncBanner(latest),
                  const SizedBox(height: 12),
                  _powerModeBanner(),
                  const SizedBox(height: 12),
                  _mlInsightBanner(ml),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: .98,
                    children: [
                      _metricCard(
                        value:
                            '${_latestValue(bpmData).toStringAsFixed(0)} BPM',
                        label: 'Heart Rate',
                        icon: Icons.favorite,
                        color: _vitalColor('bpm', _latestValue(bpmData)),
                        graphData: bpmData,
                      ),
                      _metricCard(
                        value: '${_latestValue(spo2Data).toStringAsFixed(0)}%',
                        label: 'SpO2',
                        icon: Icons.water_drop,
                        color: _vitalColor('spo2', _latestValue(spo2Data)),
                        graphData: spo2Data,
                      ),
                      _metricCard(
                        value: '${_latestValue(tempData).toStringAsFixed(1)} C',
                        label: 'Temperature',
                        icon: Icons.thermostat,
                        color: _vitalColor('temp', _latestValue(tempData)),
                        graphData: tempData,
                      ),
                      _metricCard(
                        value: HealthRules.gestureText(gesture),
                        label: 'Gesture',
                        icon: Icons.pan_tool,
                        color: gesture > 0 ? Colors.cyan : Colors.green,
                        graphData: gestureData,
                      ),
                      _metricCard(
                        value: fallDetected ? 'Fall Detected' : 'No Fall',
                        label: 'Fall Detection',
                        icon: Icons.warning_amber_rounded,
                        color: fallDetected ? Colors.red : Colors.green,
                        graphData: fallData,
                      ),
                      _metricCard(
                        value: bleConnected ? 'Transmitting' : 'Disconnected',
                        label: 'ESP32 Link',
                        icon: bleConnected
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth_disabled,
                        color: bleConnected ? Colors.blue : Colors.red,
                        graphData: esp32Data,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _statusIcons() {
    final battery = _latestValue(batteryData);
    final chargingColor = battery < 30
        ? AppThemeColors.danger(context)
        : AppThemeColors.success(context);

    return GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _statusIconTile(
              icon: Icons.battery_charging_full_rounded,
              color: chargingColor,
              title: 'Glove Battery',
              subtitle: '${battery.toStringAsFixed(0)}%',
              active: true,
            ),
          ),
          Expanded(
            child: _statusIconTile(
              icon: Icons.speaker_group,
              color: audioDevices.isSpeakerConnected
                  ? AppThemeColors.success(context)
                  : Colors.grey,
              title: 'Speaker',
              subtitle: audioDevices.isSpeakerConnected
                  ? audioDevices.speakerName
                  : 'Not connected',
              active: audioDevices.isSpeakerConnected,
            ),
          ),
          Expanded(
            child: _statusIconTile(
              icon: Icons.memory,
              color: bluetooth.isEsp32Connected ? Colors.blue : Colors.grey,
              title: 'ESP32',
              subtitle: bluetooth.isEsp32Connected
                  ? bluetooth.connectedDeviceName
                  : 'Disconnected',
              active: bluetooth.isEsp32Connected,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusIconTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool active,
  }) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: active
                ? color.withValues(alpha: .14)
                : AppThemeColors.panelAlt(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? color : AppThemeColors.border(context),
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: .18),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            color: AppThemeColors.textPrimary(context),
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppThemeColors.textTertiary(context),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _syncBanner(Map<String, dynamic>? latest) {
    final time = latest?['time'] is DateTime
        ? latest!['time'] as DateTime
        : null;
    final text = time == null
        ? 'Waiting for first hub reading'
        : 'Synced ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} | ${dataService.history.length} readings';

    return GlassPanel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(Icons.sync, color: AppThemeColors.accent(context)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppThemeColors.textSecondary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _powerModeBanner() {
    final enabled = settings.deepSleepEnabled;
    final color = enabled
        ? const Color(0xFF8B5CF6)
        : AppThemeColors.textTertiary(context);

    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderColor: enabled
          ? color.withValues(alpha: .6)
          : AppThemeColors.border(context),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: enabled ? color.withValues(alpha: .14) : Colors.white10,
              borderRadius: BorderRadius.circular(8),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: .22),
                        blurRadius: 14,
                      ),
                    ]
                  : null,
            ),
            child: Icon(Icons.bedtime_rounded, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              enabled ? 'Deep Sleep Mode armed for hardware power saving' : 'Deep Sleep Mode off',
              style: TextStyle(
                color: enabled
                    ? AppThemeColors.textPrimary(context)
                    : AppThemeColors.textSecondary(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mlInsightBanner(MlInsightResult ml) {
    final riskColor = ml.riskScore >= 70
        ? AppThemeColors.danger(context)
        : ml.riskScore >= 35
        ? AppThemeColors.warning(context)
        : AppThemeColors.success(context);

    return GlassPanel(
      padding: const EdgeInsets.all(14),
      glowColor: riskColor.withValues(alpha: .12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.insights_outlined, color: riskColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ML Insight  |  ${ml.riskLabel} (${ml.riskScore.toStringAsFixed(0)}%)',
                  style: TextStyle(
                    color: riskColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ml.summary,
                  style: TextStyle(
                    color: AppThemeColors.textSecondary(context),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    required List<HealthData> graphData,
  }) {
    return GlassPanel(
      padding: const EdgeInsets.all(14),
      glowColor: color.withValues(alpha: .10),
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
            style: TextStyle(
              color: AppThemeColors.textPrimary(context),
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: AppThemeColors.textTertiary(context)),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: MiniGraph(data: graphData, color: color, label: label),
          ),
        ],
      ),
    );
  }

  Widget _statusHero(String status, Color statusColor, bool connected) {
    return GlassPanel(
      padding: const EdgeInsets.all(18),
      glowColor: statusColor.withValues(alpha: .12),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            height: 62,
            width: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  statusColor.withValues(alpha: .30),
                  statusColor.withValues(alpha: .10),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: .22),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              connected ? Icons.wifi_tethering_rounded : Icons.sensors_off_outlined,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  connected
                      ? 'Hub and monitoring visuals are active and updating in real time.'
                      : 'Reconnect the hub to restore live monitoring and trigger flow.',
                  style: TextStyle(
                    color: AppThemeColors.textSecondary(context),
                    height: 1.3,
                  ),
                ),
              ],
            ),
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

  double _latestValue(List<HealthData> list) {
    return list.isEmpty ? 0 : list.last.value;
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
