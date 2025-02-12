import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/usage_provider.dart';
import '../widgets/usage_chart.dart';
import 'detailed_usage_screen.dart';

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
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Unhook', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isDaily ? 'Today\'s Focus' : 'This Week\'s Progress',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(value: true, label: Text('Today')),
                ButtonSegment<bool>(value: false, label: Text('This Week')),
              ],
              selected: {_isDaily},
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() {
                  _isDaily = newSelection.first;
                });
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color>(
                      (Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.tealAccent;
                    }
                    return Colors.grey[800]!;
                  },
                ),
                foregroundColor: WidgetStateProperty.resolveWith<Color>(
                      (Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.black;
                    }
                    return Colors.white;
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _isDaily
                  ? todayUsageAsync.when(
                data: (todayUsage) => _buildUsageContent(
                  usage: todayUsage,
                  chartTitle: "Today's Usage",
                  isWeekly: false,
                ),
                loading: () => const Center(child: CircularProgressIndicator(color: Colors.tealAccent)),
                error: (error, stack) => const Center(child: Text('Error loading data', style: TextStyle(color: Colors.white))),
              )
                  : weeklyUsageAsync.when(
                data: (weeklyUsage) => _buildUsageContent(
                  usage: weeklyUsage,
                  chartTitle: "This Week's Usage",
                  isWeekly: true,
                ),
                loading: () => const Center(child: CircularProgressIndicator(color: Colors.tealAccent)),
                error: (error, stack) => const Center(child: Text('Error loading data', style: TextStyle(color: Colors.white))),
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
    final sortedApps = usage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: UsageChart(
            usageData: {for (var entry in sortedApps.take(3)) entry.key: entry.value},
            title: chartTitle,
            isWeekly: isWeekly,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'App Breakdown',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: sortedApps.length,
            itemBuilder: (context, index) {
              final entry = sortedApps[index];
              final appName = entry.key;
              final duration = entry.value;
              return ListTile(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DetailedUsageScreen(),
                    settings: RouteSettings(arguments: appName),
                  ),
                ),
                title: Text(appName, style: const TextStyle(color: Colors.white)),
                trailing: Text(
                  _formatDuration(duration, isWeekly),
                  style: const TextStyle(color: Colors.tealAccent),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration, bool isWeekly) {
    if (isWeekly) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}

