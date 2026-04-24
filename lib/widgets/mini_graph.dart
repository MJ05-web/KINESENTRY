import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/health_data.dart';
import 'dart:math';

class MiniGraph extends StatelessWidget {
  final List<HealthData> data;
  final Color color;
  final String label;

  MiniGraph({
    required this.data,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    bool isFallGraph = label == "Fall Detection";
    bool hasFall = data.any((e) => e.value > 4);

    return LineChart(
      LineChartData(
        minY: _getMinY(),
        maxY: _getMaxY(),

        // ✅ GRID
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.white10, strokeWidth: 1);
          },
          getDrawingVerticalLine: (value) {
            return FlLine(color: Colors.white10, strokeWidth: 1);
          },
        ),

        // ✅ AXIS LABELS
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                );
              },
            ),
          ),

          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: max(1, data.length / 4),
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= data.length) return SizedBox();

                final time = data[index].time;

                return Text(
                  "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}",
                  style: TextStyle(color: Colors.white38, fontSize: 8),
                );
              },
            ),
          ),

          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),

        borderData: FlBorderData(show: false),

        // ✅ TOOLTIP
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 8,
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final d = data[spot.x.toInt()];

                String time =
                    "${d.time.hour.toString().padLeft(2, '0')}:${d.time.minute.toString().padLeft(2, '0')}";

                String date =
                    "${d.time.day}/${d.time.month}/${d.time.year}";

                if (isFallGraph) {
                  return LineTooltipItem(
                    d.value > 4
                        ? "FALL DETECTED ⚠\n$date $time"
                        : "No Fall\n$date $time",
                    TextStyle(color: Colors.white),
                  );
                }

                return LineTooltipItem(
                  "$label: ${d.value}\n$date $time",
                  TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),

        // ✅ GRAPH LINE
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.value);
            }).toList(),
            isCurved: true,
            color: isFallGraph
                ? (hasFall ? Colors.red : Colors.green)
                : color,
            barWidth: 3,

            // ✅ FALL DOT LOGIC
            dotData: FlDotData(
              show: isFallGraph,
              getDotPainter: (spot, percent, bar, index) {
                if (isFallGraph && spot.y > 4) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.red,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                }
                return FlDotCirclePainter(radius: 0);
              },
            ),

            belowBarData: BarAreaData(
              show: true,
              color: (isFallGraph
                      ? (hasFall ? Colors.red : Colors.green)
                      : color)
                  .withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ RANGE LOGIC
  double _getMinY() {
    if (label == "Heart Rate") return 50;
    if (label == "Temperature") return 34;
    if (label == "Gesture") return 0;
    if (label == "Fall Detection") return 0;

    return data.map((e) => e.value).reduce(min) - 1;
  }

  double _getMaxY() {
    if (label == "Heart Rate") return 140;
    if (label == "Temperature") return 40;
    if (label == "Gesture") return 6;
    if (label == "Fall Detection") return 6;

    return data.map((e) => e.value).reduce(max) + 1;
  }
}