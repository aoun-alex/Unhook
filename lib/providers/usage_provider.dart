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

  // Calculate the start of the week (Monday)
  DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  startOfWeek = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day, 0, 0);

  // Calculate the end of the week (Sunday)
  DateTime endOfWeek = startOfWeek.add(Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

  Map<String, Duration> weeklyUsage = {
    'instagram': Duration.zero,
    'youtube': Duration.zero,
    'tiktok': Duration.zero,
    'facebook': Duration.zero,
  };

  // Get usage for the entire week at once
  Map<String, Duration> weekUsage = await usageService.getUsageForPeriod(startOfWeek, endOfWeek);

  // Combine the usage data
  weeklyUsage.forEach((app, _) {
    weeklyUsage[app] = weekUsage[app] ?? Duration.zero;
  });

  return weeklyUsage;
});

