import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class UsageChart extends StatelessWidget {
  final Map<String, Duration> usageData;
  final String title;
  final bool isWeekly;
  final void Function(String app)? onBarTap;

  const UsageChart({
    Key? key,
    required this.usageData,
    required this.title,
    required this.isWeekly,
    this.onBarTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final numericData = <String, double>{};
    usageData.forEach((app, duration) {
      numericData[app] = isWeekly
          ? duration.inHours.toDouble()
          : duration.inMinutes.toDouble();
    });

    double maxVal = numericData.values.isEmpty ? 1 : numericData.values.reduce((a, b) => a > b ? a : b);
    double niceMax = isWeekly ? ((maxVal / 5).ceil() * 5).toDouble() : ((maxVal / 10).ceil() * 10).toDouble();
    double interval = niceMax / 5;

    int index = 0;
    final barGroups = numericData.entries.map((e) {
      return BarChartGroupData(
        x: index++,
        barRods: [
          BarChartRodData(
            toY: e.value,
            color: Colors.lightBlueAccent,
            width: 22,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    return Card(
      color: Theme.of(context).cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1.7,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceEvenly,
                  maxY: niceMax,
                  minY: 0,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Colors.blueGrey.withAlpha((0.8 * 255).toInt()),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final appName = numericData.keys.elementAt(group.x.toInt());
                        final rawValue = rod.toY;
                        final label = isWeekly
                            ? '${rawValue.toInt()}h'
                            : rawValue >= 60
                            ? '${(rawValue ~/ 60).toInt()}h ${(rawValue % 60).toInt()}m'
                            : '${rawValue.toInt()}m';
                        return BarTooltipItem(
                          '$appName\n$label',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                    touchCallback: (event, response) {
                      if (onBarTap != null && event is FlTapUpEvent && response?.spot != null) {
                        final tappedApp = numericData.keys.elementAt(response!.spot!.touchedBarGroupIndex);
                        onBarTap!(tappedApp);
                      }
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final appName = numericData.keys.elementAt(value.toInt());
                          return SideTitleWidget(
                            meta: meta,
                            space: 6,
                            child: Text(
                              appName,
                              style: const TextStyle(
                                fontSize: 12,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        // Increase the size only if this is the daily chart
                        reservedSize: isWeekly ? 40 : 60,
                        interval: interval,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final int val = value.toInt();
                          if (val % interval == 0) {
                            final label = isWeekly
                                ? '${val}h'
                                : val >= 60
                                ? '${(val ~/ 60)}h ${(val % 60)}m'
                                : '${val}m';
                            return SideTitleWidget(
                              meta: meta,
                              space: 6,
                              child: Text(label),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),

                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: barGroups,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
