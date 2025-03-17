import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/goal_limit.dart';
import '../data/services/goal_service.dart';
import '../data/services/usage_service.dart';
import '../data/database/database_helper.dart';
import '../data/services/usage_monitoring_service.dart';
import '../data/services/usage_sync_service.dart';

final goalServiceProvider = Provider<GoalService>((ref) {
  return GoalService();
});

final usageServiceProvider = Provider<UsageService>((ref) {
  return UsageService();
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

// Provider for active goals
final activeGoalsProvider = StateNotifierProvider<GoalsNotifier, List<GoalLimit>>((ref) {
  final goalService = ref.read(goalServiceProvider);
  final monitoringService = ref.read(usageMonitoringServiceProvider);
  final syncService = ref.read(usageSyncServiceProvider);
  return GoalsNotifier(goalService, monitoringService, syncService);
});

class GoalsNotifier extends StateNotifier<List<GoalLimit>> {
  final GoalService _goalService;
  final UsageMonitoringService _monitoringService;
  final UsageSyncService _syncService;

  GoalsNotifier(this._goalService, this._monitoringService, this._syncService) : super([]) {
    // Load goals on initialization
    loadGoals();
  }

  Future<void> loadGoals() async {
    final goals = await _goalService.getActiveGoals();
    state = goals;
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

  // Method to manually trigger a check
  Future<void> checkGoalUsage(String packageName) async {
    final goal = state.firstWhere(
          (g) => g.packageName == packageName,
      orElse: () => throw Exception('Goal not found'),
    );

    await _monitoringService.checkSpecificApp(goal);
  }

  // Method to check all goals
  Future<void> checkAllGoals() async {
    for (final goal in state) {
      await _monitoringService.checkSpecificApp(goal);
    }
  }

  // Method to manually sync usage data
  Future<void> syncUsage() async {
    // First sync usage data using the sync service
    await _syncService.syncUsageWithGoals();

    // Then check all goals for more frequent monitoring if needed
    await checkAllGoals();

    // Finally, reload goals to reflect any updates
    await loadGoals();
  }
}