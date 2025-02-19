import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/usage_service.dart';
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
    final todayUsageAsync = ref.watch(todayUsageSummaryProvider);
    final weeklyUsageAsync = ref.watch(weeklyUsageSummaryProvider);

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
                data: (summaries) => _buildUsageContent(
                  summaries: summaries,
                  chartTitle: "Today's Usage",
                  isWeekly: false,
                ),
                loading: () => const Center(
                    child:
                    CircularProgressIndicator(color: Colors.tealAccent)),
                error: (error, stack) => Center(
                    child: Text('Error: $error',
                        style: const TextStyle(color: Colors.white))),
              )
                  : weeklyUsageAsync.when(
                data: (summaries) => _buildUsageContent(
                  summaries: summaries,
                  chartTitle: "This Week's Usage",
                  isWeekly: true,
                ),
                loading: () => const Center(
                    child:
                    CircularProgressIndicator(color: Colors.tealAccent)),
                error: (error, stack) => Center(
                    child: Text('Error: $error',
                        style: const TextStyle(color: Colors.white))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageContent({
    required List<AppUsageSummary> summaries,
    required String chartTitle,
    required bool isWeekly,
  }) {
    if (summaries.isEmpty) {
      return const Center(
          child: Text('No usage data available',
              style: TextStyle(color: Colors.white)));
    }

    final chartData = ref.read(usageChartDataProvider(summaries));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: UsageChart(
            usageData: chartData,
            title: chartTitle,
            isWeekly: isWeekly,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'App Breakdown',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: summaries.length,
            itemBuilder: (context, index) {
              final summary = summaries[index];
              return ListTile(
                leading: summary.appIcon != null
                    ? Image.memory(summary.appIcon!, width: 40, height: 40)
                    : const SizedBox(width: 40, height: 40),
                title: Text(summary.appName,
                    style: const TextStyle(color: Colors.white)),
                trailing: Text(
                  summary.totalDurationText,
                  style: const TextStyle(color: Colors.tealAccent),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailedUsageScreen(summary: summary),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}