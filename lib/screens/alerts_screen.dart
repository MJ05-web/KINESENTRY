import 'package:flutter/material.dart';

import '../services/data_service.dart';
import '../services/health_rules.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataService = DataService();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1C),
      appBar: AppBar(
        title: const Text('Alerts'),
        backgroundColor: const Color(0xFF0A0F1C),
        centerTitle: true,
      ),
      body: StreamBuilder<Map<String, double>>(
        stream: dataService.stream,
        builder: (context, snapshot) {
          final latest = dataService.latestData;
          final alerts = HealthRules.evaluate(latest);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statusOverview(latest),
                const SizedBox(height: 16),
                _categorySection(
                  title: 'Critical Alerts',
                  icon: Icons.priority_high_rounded,
                  color: Colors.red,
                  alerts: _byCategory(alerts, HealthRules.categoryCritical),
                  emptyText: 'No critical vitals or fall alerts',
                ),
                const SizedBox(height: 14),
                _categorySection(
                  title: 'Warnings',
                  icon: Icons.warning_amber_rounded,
                  color: Colors.orange,
                  alerts: _byCategory(alerts, HealthRules.categoryWarning),
                  emptyText: 'No warning-level vitals right now',
                ),
                const SizedBox(height: 14),
                _categorySection(
                  title: 'Gesture Requests',
                  icon: Icons.pan_tool_outlined,
                  color: Colors.cyan,
                  alerts: _byCategory(alerts, HealthRules.categoryGesture),
                  emptyText: 'No active gesture request',
                ),
                const SizedBox(height: 14),
                _categorySection(
                  title: 'Battery',
                  icon: Icons.battery_alert_outlined,
                  color: Colors.green,
                  alerts: _byCategory(alerts, HealthRules.categoryBattery),
                  emptyText: _batteryText(latest),
                ),
                const SizedBox(height: 18),
                _historySection(dataService.alertHistory),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statusOverview(Map<String, dynamic>? latest) {
    final status = HealthRules.overallStatus(latest);
    final color = status == 'Critical'
        ? Colors.red
        : status == 'Warning'
        ? Colors.orange
        : Colors.green;
    final time = latest?['time'] is DateTime
        ? latest!['time'] as DateTime
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF121A2F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.health_and_safety_outlined, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  time == null
                      ? 'Waiting for readings'
                      : 'Updated ${_formatTime(time)}',
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categorySection({
    required String title,
    required IconData icon,
    required Color color,
    required List<HealthAlert> alerts,
    required String emptyText,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _countBadge(alerts.length, color),
            ],
          ),
          const SizedBox(height: 12),
          if (alerts.isEmpty)
            _emptyState(emptyText)
          else
            Column(
              children: alerts
                  .map(
                    (alert) => _alertTile(
                      title: alert.title,
                      detail: alert.detail,
                      color: _severityColor(alert.severity, fallback: color),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _historySection(List<Map<String, dynamic>> history) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF121A2F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alert History',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (history.isEmpty)
            _emptyState('No alerts recorded yet')
          else
            Column(
              children: history.map((alert) {
                final color = _severityColor(
                  alert['severity'] ?? 'warning',
                  fallback: _categoryColor(alert['type'] ?? ''),
                );
                final time = alert['time'] is DateTime
                    ? alert['time'] as DateTime
                    : DateTime.now();

                return _alertTile(
                  title: alert['message'] ?? 'Alert',
                  detail: '${alert['detail'] ?? ''}\n${_formatTime(time)}',
                  color: color,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _alertTile({
    required String title,
    required String detail,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: .75)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, color: color, size: 10),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
                if (detail.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: const TextStyle(color: Colors.white70, height: 1.3),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F1C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white54)),
    );
  }

  Widget _countBadge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        count.toString(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  List<HealthAlert> _byCategory(List<HealthAlert> alerts, String category) {
    return alerts.where((alert) => alert.category == category).toList();
  }

  Color _severityColor(String severity, {required Color fallback}) {
    if (severity == 'critical') return Colors.red;
    if (severity == 'warning') return Colors.orange;
    if (severity == 'gesture') return Colors.cyan;
    return fallback;
  }

  Color _categoryColor(String category) {
    if (category == HealthRules.categoryCritical) return Colors.red;
    if (category == HealthRules.categoryGesture) return Colors.cyan;
    if (category == HealthRules.categoryBattery) return Colors.green;
    return Colors.orange;
  }

  String _batteryText(Map<String, dynamic>? latest) {
    final battery = latest == null ? 100 : (latest['battery'] as num).toInt();
    return 'Battery healthy at $battery%';
  }

  String _formatTime(DateTime time) {
    return '${time.day}/${time.month}/${time.year} '
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}
