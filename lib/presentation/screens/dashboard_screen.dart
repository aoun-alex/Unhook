import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/usage_provider.dart';
import '../widgets/usage_chart.dart';

/// Simple helper to format durations below the chart. For daily, we show hours+minutes; for weekly, just hours.
String formatDuration(Duration duration, bool isWeekly) {
  if (isWeekly) {
    // e.g. 1024 minutes => 17h
    return '${duration.inHours}h';
  } else {
    // daily => e.g. "1h 20m" or "45m"
    final totalMinutes = duration.inMinutes;
    if (totalMinutes < 60) {
      return '${totalMinutes}m';
    }
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (minutes == 0) {
      return '${hours}h';
    } else {
      return '${hours}h ${minutes}m';
    }
  }
}

/// Return an icon with brand color for known apps
Widget getColoredAppIcon(String appName) {
  final lower = appName.toLowerCase();
  if (lower.contains('instagram')) {
    return const Icon(Icons.camera_alt, color: Color(0xFFC13584));
  } else if (lower.contains('youtube')) {
    return const Icon(Icons.play_circle_fill, color: Color(0xFFFF0000));
  } else if (lower.contains('facebook')) {
    return const Icon(Icons.facebook, color: Color(0xFF4267B2));
  } else if (lower.contains('tiktok')) {
    return const Icon(Icons.music_note, color: Color(0xFF69C9D0));
  }
  // Default fallback
  return const Icon(Icons.android, color: Colors.lightGreenAccent);
}

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isDaily = true;

  @override
  Widget build(BuildContext context) {
    final todayUsageAsync = ref.watch(todayUsageProvider);
    final weeklyUsageAsync = ref.watch(weeklyUsageProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('App Usage Stats')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Toggle between Daily and Weekly
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Daily'),
                  selected: _isDaily,
                  onSelected: (selected) {
                    setState(() {
                      _isDaily = true;
                    });
                  },
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('Weekly'),
                  selected: !_isDaily,
                  onSelected: (selected) {
                    setState(() {
                      _isDaily = false;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // The chart + list area
            Expanded(
              child: _isDaily
                  ? todayUsageAsync.when(
                data: (todayUsage) {
                  return _buildUsageContent(
                    usage: todayUsage,
                    chartTitle: "Today's Usage",
                    isWeekly: false,
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Text('Error loading today usage: $error'),
                ),
              )
                  : weeklyUsageAsync.when(
                data: (weeklyUsage) {
                  return _buildUsageContent(
                    usage: weeklyUsage,
                    chartTitle: "Past 7 Days",
                    isWeekly: true,
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Text('Error loading weekly usage: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageContent({
    required Map<String, Duration> usage,
    required String chartTitle,
    required bool isWeekly,
  }) {
    // Sort apps by usage descending
    final sortedApps = usage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Only show top 3 in the chart
    final topThree = sortedApps.take(3).toList();
    final chartData = {
      for (final entry in topThree) entry.key: entry.value,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The bar chart (top 3 apps)
        UsageChart(
          usageData: chartData,
          title: chartTitle,
          isWeekly: isWeekly,
          onBarTap: (appName) {
            Navigator.pushNamed(context, '/details', arguments: appName);
          },
        ),
        const SizedBox(height: 16),

        // Full list below the chart (including the apps not in the top 3)
        Expanded(
          child: ListView.builder(
            itemCount: sortedApps.length,
            itemBuilder: (context, index) {
              final entry = sortedApps[index];
              final appName = entry.key;
              final duration = entry.value;
              return ListTile(
                leading: getColoredAppIcon(appName),
                title: Text(appName),
                subtitle: Text(
                  formatDuration(duration, isWeekly),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(context, '/details',
                      arguments: appName);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
