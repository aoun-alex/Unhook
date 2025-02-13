import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class UsageChart extends StatelessWidget {
  final Map<String, Duration> usageData;
  final String title;
  final bool isWeekly;

  const UsageChart({
    Key? key,
    required this.usageData,
    required this.title,
    required this.isWeekly,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final numericData = usageData.map((key, value) => MapEntry(
      key,
      isWeekly ? value.inHours.toDouble() : value.inMinutes.toDouble(),
    ));

    // Handle empty data or all zeros
    if (numericData.isEmpty || numericData.values.every((value) => value == 0)) {
      return Card(
        color: Colors.grey[850],
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'No usage data for this period',
                    style: TextStyle(color: Colors.white60, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate nice intervals for the Y-axis
    final maxValue = numericData.values.reduce((a, b) => a > b ? a : b);
    // Ensure we have a minimum value to prevent division by zero
    final interval = _calculateNiceInterval(maxValue > 0 ? maxValue : 10);
    // Set a minimum maxY to show a reasonable scale even with very small values
    final maxY = max(((maxValue / interval).ceil() * interval * 1.2), interval * 2);

    return Card(
      color: Colors.grey[850],
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  minY: 0,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            value.toInt() < numericData.length
                                ? numericData.keys.elementAt(value.toInt())
                                : '',
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: interval,
                        getTitlesWidget: (value, meta) {
                          if (value % interval != 0) return const SizedBox.shrink();
                          return Text(
                            isWeekly ? '${value.toInt()}h' : '${value.toInt()}m',
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: numericData.entries.map((entry) {
                    return BarChartGroupData(
                      x: numericData.keys.toList().indexOf(entry.key),
                      barRods: [
                        BarChartRodData(
                          toY: entry.value,
                          color: Colors.tealAccent,
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateNiceInterval(double maxValue) {
    if (maxValue <= 0) return 1; // Return a default interval if maxValue is 0
    final rough = maxValue / 5; // We want approximately 5 intervals
    final magnitude = pow(10, (log(rough) / ln10).floor()).toDouble();
    final niceIntervals = [1, 2, 5, 10];

    for (final interval in niceIntervals) {
      if (interval * magnitude >= rough) {
        return interval * magnitude;
      }
    }
    return niceIntervals.last * magnitude;
  }
}

