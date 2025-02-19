import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/usage_service.dart';

final usageServiceProvider = Provider<UsageService>((ref) => UsageService());

final todayUsageSummaryProvider = FutureProvider<List<AppUsageSummary>>((ref) async {
  final usageService = ref.read(usageServiceProvider);
  DateTime now = DateTime.now();
  DateTime startOfDay = DateTime(now.year, now.month, now.day, 0, 0);
  DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
  return await usageService.getUsageForPeriod(startOfDay, endOfDay);
});

final weeklyUsageSummaryProvider = FutureProvider<List<AppUsageSummary>>((ref) async {
  final usageService = ref.read(usageServiceProvider);
  DateTime now = DateTime.now();

  // Calculate start of week (Monday)
  DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  startOfWeek = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day, 0, 0);

  // Calculate end of week (Sunday)
  DateTime endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

  return await usageService.getUsageForPeriod(startOfWeek, endOfWeek);
});

// Helper provider to convert AppUsageSummary to the format expected by the chart
final usageChartDataProvider = Provider.family<Map<String, Duration>, List<AppUsageSummary>>((ref, summaries) {
  Map<String, Duration> chartData = {};
  for (var summary in summaries) {
    chartData[summary.appName] = Duration(seconds: summary.totalDurationSeconds);
  }
  return chartData;
});