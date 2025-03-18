import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/goal_limit.dart';
import '../data/services/goal_service.dart';
import '../data/services/usage_service.dart';
import '../data/database/database_helper.dart';
import '../data/services/usage_monitoring_service.dart';
import '../data/services/usage_cache_service.dart';
import '../data/services/usage_sync_service.dart';

final goalServiceProvider = Provider<GoalService>((ref) {
  return GoalService();
});

final usageServiceProvider = Provider<UsageService>((ref) {
  return UsageService();
});

final usageCacheServiceProvider = Provider<UsageCacheService>((ref) {
  return UsageCacheService();
});

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

final usageSyncServiceProvider = Provider<UsageSyncService>((ref) {
  final usageService = ref.read(usageServiceProvider);
  final dbHelper = ref.read(databaseHelperProvider);
  return UsageSyncService(usageService, dbHelper);
});

final usageMonitoringServiceProvider = Provider<UsageMonitoringService>((ref) {
  final service = UsageMonitoringService();
  // Initialize the service when it's first accessed
  service.initialize();

  // Dispose the service when the provider is disposed
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

// Provider for goals data loading state
final goalsLoadingProvider = StateProvider<bool>((ref) => false);

// Provider for active goals
final activeGoalsProvider = StateNotifierProvider<GoalsNotifier, List<GoalLimit>>((ref) {
  final goalService = ref.read(goalServiceProvider);
  final monitoringService = ref.read(usageMonitoringServiceProvider);
  final syncService = ref.read(usageSyncServiceProvider);
  final cacheService = ref.read(usageCacheServiceProvider);
  return GoalsNotifier(goalService, monitoringService, syncService, cacheService, ref);
});

class GoalsNotifier extends StateNotifier<List<GoalLimit>> {
  final GoalService _goalService;
  final UsageMonitoringService _monitoringService;
  final UsageSyncService _syncService;
  final UsageCacheService _cacheService;
  final Ref _ref;

  // For debouncing UI updates
  Timer? _loadDebounceTimer;
  bool _isUpdating = false;
  List<GoalLimit> _pendingState = [];

  // Last successful data to fall back on in case of error
  List<GoalLimit>? _lastValidState;

  GoalsNotifier(
      this._goalService,
      this._monitoringService,
      this._syncService,
      this._cacheService,
      this._ref
      ) : super([]) {
    // Load goals on initialization
    loadGoals();
  }

  Future<void> loadGoals() async {
    if (_isUpdating) {
      return; // Don't allow concurrent updates
    }

    _setLoading(true);
    _isUpdating = true;

    try {
      final goals = await _goalService.getActiveGoals();

      // Validate data - basic sanity check
      if (_isValidGoalsList(goals)) {
        // Update each goal with latest cached usage data
        List<GoalLimit> updatedGoals = [];
        for (final goal in goals) {
          final usageMinutes = await _cacheService.getAppUsage(goal.packageName);

          final isLimitReached = usageMinutes >= goal.limitInMinutes;

          // Create updated goal with latest usage data
          final updatedGoal = goal.copyWith(
            currentUsage: usageMinutes,
            isLimitReached: isLimitReached,
          );

          updatedGoals.add(updatedGoal);
        }

        _lastValidState = updatedGoals;
        _updateStateWithDebounce(updatedGoals);
      } else if (_lastValidState != null) {
        // If new data is invalid but we have valid data from before, use that
        _updateStateWithDebounce(_lastValidState!);
      } else {
        // No valid state to fall back on, use the fetched goals anyway
        _updateStateWithDebounce(goals);
      }
    } catch (e) {
      // On error, use last valid state if available
      if (_lastValidState != null) {
        _updateStateWithDebounce(_lastValidState!);
      }
    } finally {
      _isUpdating = false;
      _setLoading(false);
    }
  }

  // Check if a goal list seems valid
  bool _isValidGoalsList(List<GoalLimit> goals) {
    if (goals.isEmpty) return true; // Empty list is valid

    // Check for obviously wrong values
    for (final goal in goals) {
      // Reject negative usage
      if (goal.currentUsage < 0) return false;

      // Reject unreasonably high usage values (e.g., more than 24 hours)
      if (goal.currentUsage > 24 * 60) return false;
    }

    return true;
  }

  // Update state with debouncing to prevent UI flickering
  void _updateStateWithDebounce(List<GoalLimit> newState) {
    _pendingState = newState;

    _loadDebounceTimer?.cancel();
    _loadDebounceTimer = Timer(const Duration(milliseconds: 150), () {
      state = _pendingState;
    });
  }

  void _setLoading(bool loading) {
    _ref.read(goalsLoadingProvider.notifier).state = loading;
  }

  Future<void> addGoal({
    required String appName,
    required String packageName,
    required Uint8List? appIcon,
    required int limitInMinutes,
    required String category,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await _goalService.addGoal(
      appName: appName,
      packageName: packageName,
      appIcon: appIcon,
      limitInMinutes: limitInMinutes,
      category: category,
      lastCheckTime: now,
    );

    await loadGoals();

    // Request a check for the new goal
    final goal = state.firstWhere(
            (g) => g.packageName == packageName,
        orElse: () => GoalLimit(
          appName: appName,
          packageName: packageName,
          limitInMinutes: limitInMinutes,
          currentUsage: 0,
          category: category,
          lastCheckTime: now,
        )
    );
    await _monitoringService.checkSpecificApp(goal);

    // Force refresh usage data for this app
    await _cacheService.forceRefreshUsage(packageName);
  }

  Future<void> updateGoal({
    required String appName,
    required String packageName,
    required Uint8List? appIcon,
    required int limitInMinutes,
    required int currentUsage,
    required String category,
    bool isLimitReached = false,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Cancel any existing intensive checks for this app
    await _monitoringService.cancelIntensiveChecks(packageName);

    final goal = state.firstWhere(
          (g) => g.packageName == packageName,
      orElse: () => GoalLimit(
        appName: appName,
        packageName: packageName,
        limitInMinutes: limitInMinutes,
        currentUsage: currentUsage,
        category: category,
        lastCheckTime: now,
      ),
    );

    await _goalService.updateGoal(
      appName: appName,
      packageName: packageName,
      appIcon: appIcon,
      limitInMinutes: limitInMinutes,
      currentUsage: currentUsage,
      category: category,
      isLimitReached: isLimitReached,
      lastCheckTime: goal.lastCheckTime,
      notifiedAt80Percent: goal.notifiedAt80Percent,
      notifiedAt95Percent: goal.notifiedAt95Percent,
      nextCheckTime: goal.nextCheckTime,
    );

    await loadGoals();

    // Request a check for the updated goal to reflect new limits
    final updatedGoal = state.firstWhere(
          (g) => g.packageName == packageName,
      orElse: () => GoalLimit(
        appName: appName,
        packageName: packageName,
        limitInMinutes: limitInMinutes,
        currentUsage: currentUsage,
        category: category,
        lastCheckTime: now,
      ),
    );
    await _monitoringService.checkSpecificApp(updatedGoal);
  }

  Future<void> removeGoal(String packageName) async {
    await _goalService.removeGoal(packageName);
    await loadGoals();
  }

  // Method to manually trigger a check for a specific app
  Future<void> checkGoalUsage(String packageName) async {
    final goal = state.firstWhere(
          (g) => g.packageName == packageName,
      orElse: () => throw Exception('Goal not found'),
    );

    // Get fresh usage data from cache service
    final usageMinutes = await _cacheService.forceRefreshUsage(packageName);

    // Update the UI optimistically
    final goalIndex = state.indexWhere((g) => g.packageName == packageName);
    if (goalIndex >= 0) {
      // Create a new list to trigger state update
      final newState = List<GoalLimit>.from(state);
      newState[goalIndex] = newState[goalIndex].copyWith(
        currentUsage: usageMinutes,
        isLimitReached: usageMinutes >= newState[goalIndex].limitInMinutes,
      );

      _updateStateWithDebounce(newState);
    }

    // Still request a check from the monitoring service for notifications
    await _monitoringService.checkSpecificApp(goal);
  }

  // Method to check all goals
  Future<void> checkAllGoals() async {
    _setLoading(true);

    try {
      // Create list of package names to refresh
      final packageNames = state.map((g) => g.packageName).toList();

      // Refresh cached usage data for all apps
      await _cacheService.refreshAllTrackedApps(packageNames);

      // Reload goals to reflect updated usage
      await loadGoals();

      // Also check with monitoring service for notifications
      for (final goal in state) {
        await _monitoringService.checkSpecificApp(goal);
      }
    } finally {
      _setLoading(false);
    }
  }

  // Method to manually sync usage data
  Future<void> syncUsage() async {
    _setLoading(true);

    try {
      // First sync usage data using the sync service
      await _syncService.syncUsageWithGoals();

      // Force refresh cache for all tracked apps
      final packageNames = state.map((g) => g.packageName).toList();
      await _cacheService.refreshAllTrackedApps(packageNames);

      // Then check all goals for more frequent monitoring if needed
      await checkAllGoals();

      // Finally, reload goals to reflect any updates
      await loadGoals();
    } finally {
      _setLoading(false);
    }
  }
}