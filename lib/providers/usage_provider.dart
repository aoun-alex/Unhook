import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/usage_service.dart';

final usageServiceProvider = Provider<UsageService>((ref) => UsageService());

final todayUsageProvider = FutureProvider<Map<String, Duration>>((ref) async {
  final usageService = ref.read(usageServiceProvider);
  DateTime now = DateTime.now();
  DateTime startOfDay = DateTime(now.year, now.month, now.day, 0, 0);
  DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
  return await usageService.getUsageForPeriod(startOfDay, endOfDay);
});

final weeklyUsageProvider = FutureProvider<Map<String, Duration>>((ref) async {
  final usageService = ref.read(usageServiceProvider);
  DateTime now = DateTime.now();
  Map<String, Duration> weeklyUsage = {
    'instagram': Duration.zero,
    'youtube': Duration.zero,
    'tiktok': Duration.zero,
    'facebook': Duration.zero,
  };

  // Loop through the past 7 days.
  for (int i = 0; i < 7; i++) {
    DateTime day = now.subtract(Duration(days: i));
    DateTime startOfDay = DateTime(day.year, day.month, day.day, 0, 0);
    DateTime endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59);
    Map<String, Duration> dayUsage = await usageService.getUsageForPeriod(startOfDay, endOfDay);
    weeklyUsage['instagram'] = weeklyUsage['instagram']! + (dayUsage['instagram'] ?? Duration.zero);
    weeklyUsage['youtube'] = weeklyUsage['youtube']! + (dayUsage['youtube'] ?? Duration.zero);
    weeklyUsage['tiktok'] = weeklyUsage['tiktok']! + (dayUsage['tiktok'] ?? Duration.zero);
    weeklyUsage['facebook'] = weeklyUsage['facebook']! + (dayUsage['facebook'] ?? Duration.zero);
  }
  return weeklyUsage;
});
