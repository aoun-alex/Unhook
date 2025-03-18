import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/usage_cache_service.dart';
import '../data/services/usage_service.dart';
import '../data/models/usage_snapshot.dart';
import '../data/models/app_usage.dart';
import 'goals_provider.dart';

// Provider to track if usage data is being refreshed
final usageRefreshingProvider = StateProvider<bool>((ref) => false);

// Notifier for managing app usage data
class AppUsageNotifier extends StateNotifier<AsyncValue<List<AppUsageSummary>>> {
  final UsageCacheService _cacheService;
  final UsageService _usageService;
  final Ref _ref;
  Timer? _refreshTimer;
  bool _isRefreshing = false;

  AppUsageNotifier(this._cacheService, this._usageService, this._ref)
      : super(const AsyncValue.loading()) {
    // Initial load
    refreshUsageData();

    // Set up periodic refresh (every 3 minutes)
    _refreshTimer = Timer.periodic(
        const Duration(minutes: 3),
            (_) => refreshUsageData(silent: true)
    );
  }

  // Refresh usage data (can be triggered manually or automatically)
  Future<void> refreshUsageData({bool silent = false}) async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    if (!silent) {
      _ref.read(usageRefreshingProvider.notifier).state = true;
    }

    try {
      // Get the active goals to know which apps to prioritize for refresh
      final activeGoals = _ref.read(activeGoalsProvider);
      final priorityPackages = activeGoals.map((g) => g.packageName).toList();

      // First refresh data for apps with active goals
      if (priorityPackages.isNotEmpty) {
        await _cacheService.refreshAllTrackedApps(priorityPackages);
      }

      // Then fetch the appropriate time period data
      final updatedData = await _getUsageData();

      // Update the state with the new data
      state = AsyncValue.data(updatedData);
    } catch (e) {
      // Only update state with error if it's not a silent refresh
      if (!silent) {
        state = AsyncValue.error(e, StackTrace.current);
      }
    } finally {
      _isRefreshing = false;
      if (!silent) {
        _ref.read(usageRefreshingProvider.notifier).state = false;
      }
    }
  }

  // Get usage data for today or specified period
  Future<List<AppUsageSummary>> _getUsageData() async {
    final DateTime now = DateTime.now();
    final DateTime startOfDay = DateTime(now.year, now.month, now.day, 0, 0);

    return await _usageService.getUsageForPeriod(startOfDay, now);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

// Provider for today's usage data
final todayUsageProvider = StateNotifierProvider<AppUsageNotifier, AsyncValue<List<AppUsageSummary>>>((ref) {
  final cacheService = ref.watch(usageCacheServiceProvider);
  final usageService = ref.watch(usageServiceProvider);
  return AppUsageNotifier(cacheService, usageService, ref);
});

// Provider for weekly usage data
final weeklyUsageProvider = FutureProvider<List<AppUsageSummary>>((ref) async {
  // Listen to the today provider to trigger refreshes when it updates
  ref.watch(todayUsageProvider);

  final usageService = ref.read(usageServiceProvider);
  DateTime now = DateTime.now();

  // Calculate start of week (Monday)
  DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  startOfWeek = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day, 0, 0);

  // Calculate end of week (Sunday)
  DateTime endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

  return await usageService.getUsageForPeriod(startOfWeek, endOfWeek);
});