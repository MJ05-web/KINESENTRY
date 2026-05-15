import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/health_data.dart';

class MiniGraph extends StatelessWidget {
  const MiniGraph({
    super.key,
    required this.data,
    required this.color,
    required this.label,
  });

  final List<HealthData> data;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isFallGraph = label == 'Fall Detection';
    final isGestureGraph = label == 'Gesture';
    final isLinkGraph = label == 'ESP32 Link';
    final isStateGraph = isFallGraph || isGestureGraph || isLinkGraph;
    final hasFall = data.any((e) => e.value > 0);

    if (data.isEmpty) {
      return Center(
        child: Text(
          'Waiting for data',
          style: TextStyle(
            color: Colors.white.withValues(alpha: .55),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return LineChart(
      LineChartData(
        minY: _getMinY(),
        maxY: _getMaxY(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: isFallGraph ? 1 : null,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.white10, strokeWidth: 1);
          },
          getDrawingVerticalLine: (value) {
            return FlLine(color: Colors.white10, strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: isStateGraph ? 38 : 30,
              interval: _leftTitleInterval(),
              getTitlesWidget: (value, meta) => _buildLeftTitle(value),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: max(1, (data.length - 1) / 2),
              getTitlesWidget: (value, meta) => _buildBottomTitle(value),
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 8,
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final index = spot.x.toInt();
                if (index < 0 || index >= data.length) {
                  return null;
                }

                final d = data[index];
                final time =
                    '${d.time.hour.toString().padLeft(2, '0')}:${d.time.minute.toString().padLeft(2, '0')}';
                final date = '${d.time.day}/${d.time.month}/${d.time.year}';

                if (isFallGraph) {
                  return LineTooltipItem(
                    d.value > 0
                        ? 'FALL DETECTED\n$date $time'
                        : 'No Fall\n$date $time',
                    const TextStyle(color: Colors.white),
                  );
                }

                return LineTooltipItem(
                  '$label: ${d.value}\n$date $time',
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.value);
            }).toList(),
            isCurved: !isStateGraph,
            color: isFallGraph ? (hasFall ? Colors.red : Colors.green) : color,
            barWidth: 3,
            dotData: FlDotData(
              show: isStateGraph,
              getDotPainter: (spot, percent, bar, index) {
                if (isFallGraph && spot.y > 0) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.red,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                }
                return FlDotCirclePainter(
                  radius: 2.6,
                  color: color,
                  strokeWidth: 0,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color:
                  (isFallGraph ? (hasFall ? Colors.red : Colors.green) : color)
                      .withValues(alpha: .2),
            ),
          ),
        ],
      ),
    );
  }

  double _getMinY() {
    if (data.isEmpty) return 0;
    if (label == 'Heart Rate') return 50;
    if (label == 'Temperature') return 34;
    if (label == 'Gesture') return 0;
    if (label == 'Fall Detection') return 0;
    if (label == 'ESP32 Link') return 0;

    return data.map((e) => e.value).reduce(min) - 1;
  }

  double _getMaxY() {
    if (data.isEmpty) return 1;
    if (label == 'Heart Rate') return 140;
    if (label == 'Temperature') return 40;
    if (label == 'Gesture') return 3;
    if (label == 'Fall Detection') return 1;
    if (label == 'ESP32 Link') return 1;

    return data.map((e) => e.value).reduce(max) + 1;
  }

  double? _leftTitleInterval() {
    if (label == 'Fall Detection') return 1;
    if (label == 'ESP32 Link') return 1;
    if (label == 'Gesture') return 1;
    return null;
  }

  Widget _buildLeftTitle(double value) {
    final style = const TextStyle(color: Colors.white38, fontSize: 9);
    final rounded = value.roundToDouble();

    if ((value - rounded).abs() > 0.05) {
      return const SizedBox();
    }

    if (label == 'Fall Detection') {
      if (rounded == 0) return const Text('No', style: TextStyle(color: Colors.white38, fontSize: 9));
      if (rounded == 1) return const Text('Fall', style: TextStyle(color: Colors.white38, fontSize: 9));
      return const SizedBox();
    }

    if (label == 'ESP32 Link') {
      if (rounded == 0) return const Text('Off', style: TextStyle(color: Colors.white38, fontSize: 9));
      if (rounded == 1) return const Text('On', style: TextStyle(color: Colors.white38, fontSize: 9));
      return const SizedBox();
    }

    if (label == 'Gesture') {
      switch (rounded.toInt()) {
        case 0:
          return const Text('Idle', style: TextStyle(color: Colors.white38, fontSize: 9));
        case 1:
          return const Text('Water', style: TextStyle(color: Colors.white38, fontSize: 9));
        case 2:
          return const Text('Wash', style: TextStyle(color: Colors.white38, fontSize: 9));
        case 3:
          return const Text('Food', style: TextStyle(color: Colors.white38, fontSize: 9));
      }
      return const SizedBox();
    }

    return Text(value.toInt().toString(), style: style);
  }

  Widget _buildBottomTitle(double value) {
    final index = value.toInt();
    if (index < 0 || index >= data.length) {
      return const SizedBox();
    }

    final showIndex = <int>{0, data.length ~/ 2, data.length - 1};
    if (!showIndex.contains(index)) {
      return const SizedBox();
    }

    final time = data[index].time;
    return Text(
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      style: const TextStyle(color: Colors.white38, fontSize: 8),
    );
  }
}
