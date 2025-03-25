import 'dart:async';
import '../database/database_helper.dart';
import '../models/usage_snapshot.dart';
import 'usage_service.dart';
import 'dart:developer' as developer;

class _CachedUsage {
  final int usageMinutes;
  final int timestamp;

  _CachedUsage({
    required this.usageMinutes,
    required this.timestamp,
  });
}

class UsageCacheService {
  static final UsageCacheService _instance = UsageCacheService._internal();

  factory UsageCacheService() => _instance;

  UsageCacheService._internal();

  final DatabaseHelper _db = DatabaseHelper();
  final UsageService _usageService = UsageService();

  // In-memory cache for very frequent access
  final Map<String, _CachedUsage> _memoryCache = {};

  // Minimum time between usage stats queries for the same app
  static const int _minQueryInterval = 30000;

  // Get app usage with caching strategy
  Future<int> getAppUsage(String packageName) async {
    final now = DateTime.now();
    final todayFormatted = _formatDate(now);

    // Check memory cache first
    if (_memoryCache.containsKey(packageName)) {
      final cached = _memoryCache[packageName]!;

      // Return from memory if recent enough
      if (now.millisecondsSinceEpoch - cached.timestamp < _minQueryInterval) {
        developer.log('Usage for $packageName returned from memory cache');
        return cached.usageMinutes;
      }
    }

    // Check database cache next
    final dbSnapshot = await _db.getLatestUsageSnapshot(packageName, todayFormatted);
    if (dbSnapshot != null) {
      final age = now.millisecondsSinceEpoch - dbSnapshot.timestamp;

      // If database data is fresh enough, use it and update memory cache
      if (age < _minQueryInterval) {
        _updateMemoryCache(packageName, dbSnapshot.usageMinutes);
        developer.log('Usage for $packageName returned from database cache');
        return dbSnapshot.usageMinutes;
      }
    }

    // If we get here, need fresh data from UsageStats
    try {
      if (!_isQueryInProgress(packageName)) {
        _setQueryInProgress(packageName, true);

        // Get fresh data from the usage stats service
        final usageMinutes = await _usageService.getAppUsageTodayMinutes(packageName);

        // Update both caches
        _updateMemoryCache(packageName, usageMinutes);
        await _db.storeUsageSnapshot(packageName, usageMinutes);

        _setQueryInProgress(packageName, false);
        developer.log('Fresh usage data fetched for $packageName: $usageMinutes min');
        return usageMinutes;
      } else {
        // Query in progress, return last known value or 0
        developer.log('Query in progress for $packageName, returning cached value');
        return _memoryCache[packageName]?.usageMinutes ??
            dbSnapshot?.usageMinutes ??
            0;
      }
    } catch (e) {
      developer.log('Error getting usage for $packageName: $e');
      _setQueryInProgress(packageName, false);

      // Return last known value in case of error
      return _memoryCache[packageName]?.usageMinutes ??
          dbSnapshot?.usageMinutes ??
          0;
    }
  }

  // Get usage data for the week
  Future<List<UsageSnapshot>> getWeeklyUsage(String packageName) async {
    return await _db.getWeeklyUsageSnapshots(packageName, 7);
  }

  // Force refresh usage for a package
  Future<int> forceRefreshUsage(String packageName) async {
    try {
      // Get fresh data from the usage stats service
      final usageMinutes = await _usageService.getAppUsageTodayMinutes(packageName);

      // Update both caches
      _updateMemoryCache(packageName, usageMinutes);
      await _db.storeUsageSnapshot(packageName, usageMinutes);

      developer.log('Usage forcefully refreshed for $packageName: $usageMinutes min');
      return usageMinutes;
    } catch (e) {
      developer.log('Error refreshing usage for $packageName: $e');

      // Return last known value in case of error
      final cached = _memoryCache[packageName];
      if (cached != null) {
        return cached.usageMinutes;
      }

      final todayFormatted = _formatDate(DateTime.now());
      final dbSnapshot = await _db.getLatestUsageSnapshot(packageName, todayFormatted);
      return dbSnapshot?.usageMinutes ?? 0;
    }
  }

  // Refresh usage for all tracked apps
  Future<void> refreshAllTrackedApps(List<String> packageNames) async {
    for (final packageName in packageNames) {
      // Use a slight delay between apps to prevent overwhelming the UsageStats API
      await Future.delayed(const Duration(milliseconds: 100));
      await getAppUsage(packageName);
    }
  }

  // Update memory cache with new usage data
  void _updateMemoryCache(String packageName, int usageMinutes) {
    _memoryCache[packageName] = _CachedUsage(
      usageMinutes: usageMinutes,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  // Query progress tracking
  final Map<String, bool> _queryInProgress = {};

  bool _isQueryInProgress(String packageName) {
    return _queryInProgress[packageName] ?? false;
  }

  void _setQueryInProgress(String packageName, bool inProgress) {
    _queryInProgress[packageName] = inProgress;
  }

  // Format a date as yyyy-MM-dd for database storage
  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Clear memory cache (e.g., for testing or after long inactivity)
  void clearMemoryCache() {
    _memoryCache.clear();
    developer.log('Memory cache cleared');
  }
}