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
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: numericData.values.reduce((a, b) => a > b ? a : b) * 1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            numericData.keys.elementAt(value.toInt()),
                            style: TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          isWeekly ? '${value.toInt()}h' : '${value.toInt()}m',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: false),
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
}

