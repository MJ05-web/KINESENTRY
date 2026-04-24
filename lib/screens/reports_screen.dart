import 'package:flutter/material.dart';

import '../models/health_data.dart';
import '../services/data_service.dart';
import '../services/pdf_service.dart';
import '../services/report_storage_service.dart';
import '../widgets/mini_graph.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final dataService = DataService();
  final reportStorage = ReportStorageService();

  bool savingSession = false;
  bool savingHourly = false;
  bool savingDaily = false;
  String? busyReportId;

  Future<void> _saveReport({
    required String title,
    required String type,
    required List<Map<String, dynamic>> data,
    required String insight,
  }) async {
    if (data.isEmpty) {
      _showMessage('No data available to generate this report');
      return;
    }

    setState(() {
      if (type == 'session') {
        savingSession = true;
      } else if (type == 'hourly') {
        savingHourly = true;
      } else {
        savingDaily = true;
      }
    });

    try {
      await reportStorage.saveReport(
        title: title,
        type: type,
        entryCount: data.length,
        insight: insight,
        data: data,
      );

      if (!mounted) return;
      _showMessage('Report saved. You can view or download it below.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Could not save report: $e');
    } finally {
      if (mounted) {
        setState(() {
          if (type == 'session') {
            savingSession = false;
          } else if (type == 'hourly') {
            savingHourly = false;
          } else {
            savingDaily = false;
          }
        });
      }
    }
  }

  Future<void> _viewPreviousReport(StoredReport report) async {
    await _openPreviousReport(report, shouldDownload: false);
  }

  Future<void> _downloadPreviousReport(StoredReport report) async {
    await _openPreviousReport(report, shouldDownload: true);
  }

  Future<void> _confirmDeleteReport(StoredReport report) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF121A2F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: const Text(
            'Delete report?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete "${report.title}"?\n\n'
            'Stored in: Firebase Firestore\n'
            'Path: users/{uid}/reports/${report.id}\n\n'
            'This removes it from this app and Firebase.',
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Delete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE5484D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    setState(() => busyReportId = report.id);

    try {
      await reportStorage.deleteReport(report);

      if (!mounted) return;
      _showMessage('Report deleted from app and Firebase.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Could not delete report: $e');
    } finally {
      if (mounted) {
        setState(() => busyReportId = null);
      }
    }
  }

  Future<void> _openPreviousReport(
    StoredReport report, {
    required bool shouldDownload,
  }) async {
    setState(() => busyReportId = report.id);

    try {
      final bytes = await PdfService.buildReport(
        data: report.samples,
        insight: report.insight,
        reportTitle: report.title,
        reportType: report.type,
      );

      if (shouldDownload) {
        await PdfService.downloadReport(bytes, report.filename);
      } else {
        await PdfService.viewReport(bytes);
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('Could not open report: $e');
    } finally {
      if (mounted) {
        setState(() => busyReportId = null);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = dataService.sessionData;
    final sessionInsight = generateInsights(session);

    final hourly = getHourlyData(dataService.history);
    final hourlyInsight = generateInsights(hourly);

    final daily = getDailyData(dataService.history);
    final dailyInsight = generateInsights(daily);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1C),
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: const Color(0xFF0A0F1C),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Status',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 10),
            buildStatusCard(dataService),
            const SizedBox(height: 20),
            buildReportSection(
              title: 'Session Report',
              subtitle: 'Current monitoring session',
              icon: Icons.timer_outlined,
              accentColor: Colors.cyan,
              data: session,
              insight: sessionInsight,
              isSaving: savingSession,
              onSave: () {
                _saveReport(
                  title: 'Session Health Report',
                  type: 'session',
                  data: session,
                  insight: sessionInsight,
                );
              },
            ),
            const SizedBox(height: 20),
            buildReportSection(
              title: 'Hourly Report',
              subtitle: 'Last 60 minutes',
              icon: Icons.schedule,
              accentColor: Colors.blue,
              data: hourly,
              insight: hourlyInsight,
              isSaving: savingHourly,
              onSave: () {
                _saveReport(
                  title: 'Hourly Health Report',
                  type: 'hourly',
                  data: hourly,
                  insight: hourlyInsight,
                );
              },
            ),
            const SizedBox(height: 20),
            buildReportSection(
              title: 'Daily Report',
              subtitle: 'Today from midnight',
              icon: Icons.today_outlined,
              accentColor: Colors.green,
              data: daily,
              insight: dailyInsight,
              isSaving: savingDaily,
              onSave: () {
                _saveReport(
                  title: 'Daily Health Report',
                  type: 'daily',
                  data: daily,
                  insight: dailyInsight,
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Previous Reports',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 10),
            buildPreviousReports(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget buildStatusCard(DataService dataService) {
    final last = dataService.history.isNotEmpty
        ? dataService.history.last
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF121A2F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: last == null
          ? const Text(
              'Waiting for device data...',
              style: TextStyle(color: Colors.white70),
            )
          : Row(
              children: [
                Expanded(
                  child: _statusMetric(
                    'Heart Rate',
                    '${((last["bpm"] ?? 0) as num).toStringAsFixed(0)} BPM',
                    Icons.favorite,
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _statusMetric(
                    'SpO2',
                    '${((last["spo2"] ?? 0) as num).toStringAsFixed(0)}%',
                    Icons.water_drop,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _statusMetric(
                    'Temp',
                    '${((last["temp"] ?? 0) as num).toStringAsFixed(1)} C',
                    Icons.thermostat,
                    Colors.orange,
                  ),
                ),
              ],
            ),
    );
  }

  Widget buildReportSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required List<Map<String, dynamic>> data,
    required String insight,
    required bool isSaving,
    required VoidCallback onSave,
  }) {
    return Container(
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
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
              _entryChip('${data.length} entries'),
            ],
          ),
          const SizedBox(height: 14),
          buildReportCard(data, insight),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : onSave,
              icon: isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(isSaving ? 'Saving report...' : 'Save to Firebase'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF344054),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPreviousReports() {
    return StreamBuilder<List<StoredReport>>(
      stream: reportStorage.watchReports(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return buildMessageCard('Could not load previous reports');
        }

        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: Colors.blue),
            ),
          );
        }

        final reports = snapshot.data!;

        if (reports.isEmpty) {
          return buildMessageCard('No previous reports generated yet');
        }

        return Column(children: reports.map(buildPreviousReportTile).toList());
      },
    );
  }

  Widget buildPreviousReportTile(StoredReport report) {
    final isBusy = busyReportId == report.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF121A2F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(_reportIcon(report.type), color: _reportColor(report.type)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _reportTypeLabel(report.type),
                  style: TextStyle(
                    color: _reportColor(report.type),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDate(report.createdAt)}  •  ${report.entryCount} entries',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          if (isBusy)
            const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            IconButton(
              tooltip: 'View report',
              onPressed: () => _viewPreviousReport(report),
              icon: const Icon(
                Icons.visibility_outlined,
                color: Colors.white70,
              ),
            ),
            IconButton(
              tooltip: 'Download report',
              onPressed: () => _downloadPreviousReport(report),
              icon: const Icon(Icons.download_outlined, color: Colors.blue),
            ),
            IconButton(
              tooltip: 'Delete report',
              onPressed: () => _confirmDeleteReport(report),
              icon: const Icon(Icons.delete_outline, color: Color(0xFFFF6B6B)),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildMessageCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF121A2F),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(message, style: const TextStyle(color: Colors.white54)),
    );
  }

  Widget buildReportCard(List<Map<String, dynamic>> data, String insight) {
    if (data.isEmpty) {
      return buildMessageCard('No data available');
    }

    List<HealthData> toHealthData(String key) {
      return data.map((e) {
        return HealthData(
          (e[key] ?? 0).toDouble(),
          (e['time'] ?? DateTime.now()) as DateTime,
        );
      }).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryPill(
                'Avg BPM',
                avg(data, 'bpm').toStringAsFixed(0),
                Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _summaryPill(
                'Avg SpO2',
                '${avg(data, 'spo2').toStringAsFixed(0)}%',
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _summaryPill(
                'Avg Temp',
                '${avg(data, 'temp').toStringAsFixed(1)} C',
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text('Heart Rate', style: TextStyle(color: Colors.white54)),
        SizedBox(
          height: 120,
          child: MiniGraph(
            data: toHealthData('bpm'),
            color: Colors.red,
            label: 'BPM',
          ),
        ),
        const SizedBox(height: 10),
        const Text('SpO2', style: TextStyle(color: Colors.white54)),
        SizedBox(
          height: 120,
          child: MiniGraph(
            data: toHealthData('spo2'),
            color: Colors.blue,
            label: 'SpO2',
          ),
        ),
        const SizedBox(height: 10),
        const Text('Temperature', style: TextStyle(color: Colors.white54)),
        SizedBox(
          height: 120,
          child: MiniGraph(
            data: toHealthData('temp'),
            color: Colors.orange,
            label: 'Temp',
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0F1C),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          child: Text(
            'Insights\n$insight',
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
        ),
      ],
    );
  }

  Widget _statusMetric(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _entryChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F1C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }

  Widget _summaryPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F1C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  IconData _reportIcon(String type) {
    if (type == 'session') return Icons.timer_outlined;
    if (type == 'daily') return Icons.today_outlined;
    return Icons.schedule;
  }

  Color _reportColor(String type) {
    if (type == 'session') return Colors.cyan;
    if (type == 'daily') return Colors.green;
    return Colors.blue;
  }

  String _reportTypeLabel(String type) {
    if (type == 'session') return 'Session';
    if (type == 'daily') return 'Daily';
    return 'Hourly';
  }

  String _formatDate(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day}/${date.month}/${date.year} $hour:$minute';
  }
}

List<Map<String, dynamic>> getHourlyData(List data) {
  final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));

  return data
      .where((e) {
        final time = e['time'] as DateTime;
        return time.isAfter(oneHourAgo);
      })
      .toList()
      .cast<Map<String, dynamic>>();
}

List<Map<String, dynamic>> getDailyData(List data) {
  final now = DateTime.now();

  return data
      .where((e) {
        final time = e['time'] as DateTime;
        return now.day == time.day &&
            now.month == time.month &&
            now.year == time.year;
      })
      .toList()
      .cast<Map<String, dynamic>>();
}

double avg(List<Map<String, dynamic>> data, String key) {
  if (data.isEmpty) return 0;

  double sum = 0;
  for (final d in data) {
    sum += d[key] ?? 0;
  }

  return sum / data.length;
}

String generateInsights(List<Map<String, dynamic>> data) {
  if (data.isEmpty) return 'No data available';

  double sumBpm = 0;
  double sumSpo2 = 0;
  double sumTemp = 0;

  double maxBpm = 0;
  double minBpm = double.infinity;
  double maxTemp = 0;
  double minTemp = double.infinity;

  int lowSpo2Count = 0;
  int highBpmCount = 0;
  int highTempCount = 0;

  for (final d in data) {
    final bpm = (d['bpm'] ?? 0).toDouble();
    final spo2 = (d['spo2'] ?? 0).toDouble();
    final temp = (d['temp'] ?? 0).toDouble();

    sumBpm += bpm;
    sumSpo2 += spo2;
    sumTemp += temp;

    if (bpm > maxBpm) maxBpm = bpm;
    if (bpm < minBpm) minBpm = bpm;

    if (temp > maxTemp) maxTemp = temp;
    if (temp < minTemp) minTemp = temp;

    if (spo2 < 92) lowSpo2Count++;
    if (bpm > 110) highBpmCount++;
    if (temp > 38) highTempCount++;
  }

  final n = data.length;

  final avgBpm = sumBpm / n;
  final avgSpo2 = sumSpo2 / n;
  final avgTemp = sumTemp / n;

  var insight = '';

  insight += 'Avg BPM: ${avgBpm.toStringAsFixed(0)}\n';
  insight += 'Avg SpO2: ${avgSpo2.toStringAsFixed(0)}%\n';
  insight += 'Avg Temp: ${avgTemp.toStringAsFixed(1)} C\n\n';
  insight +=
      'Max BPM: ${maxBpm.toStringAsFixed(0)}, Min BPM: ${minBpm.toStringAsFixed(0)}\n';
  insight +=
      'Max Temp: ${maxTemp.toStringAsFixed(1)}, Min Temp: ${minTemp.toStringAsFixed(1)}\n\n';

  if (lowSpo2Count > 0) {
    insight += 'Warning: Low SpO2 detected $lowSpo2Count times\n';
  }

  if (highBpmCount > 0) {
    insight += 'Warning: High heart rate detected $highBpmCount times\n';
  }

  if (highTempCount > 0) {
    insight += 'Warning: High temperature detected $highTempCount times\n';
  }

  if (lowSpo2Count == 0 && highBpmCount == 0 && highTempCount == 0) {
    insight += 'All vitals remained stable during monitoring.';
  }

  return insight;
}
