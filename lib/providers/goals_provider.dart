import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/goal_limit.dart';
import '../data/services/goal_service.dart';
import '../data/services/usage_service.dart';
import '../data/services/usage_sync_service.dart';
import '../data/database/database_helper.dart';

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

// Provider for active goals
final activeGoalsProvider = StateNotifierProvider<GoalsNotifier, List<GoalLimit>>((ref) {
  final goalService = ref.read(goalServiceProvider);
  final syncService = ref.read(usageSyncServiceProvider);
  return GoalsNotifier(goalService, syncService);
});

class GoalsNotifier extends StateNotifier<List<GoalLimit>> {
  final GoalService _goalService;
  final UsageSyncService _syncService;

  GoalsNotifier(this._goalService, this._syncService) : super([]) {
    // Load goals on initialization
    loadGoals();
  }

  Future<void> loadGoals() async {
    // First sync usage data
    await _syncService.syncUsageWithGoals();

    // Then load updated goals
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
    await _goalService.addGoal(
      appName: appName,
      packageName: packageName,
      appIcon: appIcon,
      limitInMinutes: limitInMinutes,
      category: category,
    );
    await loadGoals();
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
    await _goalService.updateGoal(
      appName: appName,
      packageName: packageName,
      appIcon: appIcon,
      limitInMinutes: limitInMinutes,
      currentUsage: currentUsage,
      category: category,
      isLimitReached: isLimitReached,
    );
    await loadGoals();
  }

  Future<void> removeGoal(String packageName) async {
    await _goalService.removeGoal(packageName);
    await loadGoals();
  }

  Future<void> updateUsage(String packageName, int currentUsage, bool isLimitReached) async {
    await _goalService.updateUsage(packageName, currentUsage, isLimitReached);
    await loadGoals();
  }

  // Method to manually trigger sync
  Future<void> syncUsage() async {
    await _syncService.syncUsageWithGoals();
    await loadGoals();
  }
}