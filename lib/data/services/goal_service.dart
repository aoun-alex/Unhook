import 'dart:typed_data';
import '../models/goal_limit.dart';
import '../database/database_helper.dart';

class GoalService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Get all active goals
  Future<List<GoalLimit>> getActiveGoals() async {
    return await _dbHelper.getGoals();
  }

  // Get goals that need checking
  Future<List<GoalLimit>> getGoalsToCheck() async {
    return await _dbHelper.getGoalsToCheck();
  }

  // Add a new goal
  Future<void> addGoal({
    required String appName,
    required String packageName,
    required Uint8List? appIcon,
    required int limitInMinutes,
    required String category,
    int? lastCheckTime,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final goal = GoalLimit(
      appName: appName,
      packageName: packageName,
      appIcon: appIcon,
      limitInMinutes: limitInMinutes,
      currentUsage: 0, // Start with zero usage
      category: category,
      lastCheckTime: lastCheckTime ?? now,
    );

    await _dbHelper.insertGoal(goal);
  }

  // Update an existing goal
  Future<void> updateGoal({
    required String appName,
    required String packageName,
    required Uint8List? appIcon,
    required int limitInMinutes,
    required int currentUsage,
    required String category,
    bool isLimitReached = false,
    int? lastCheckTime,
    bool notifiedAt80Percent = false,
    bool notifiedAt95Percent = false,
    int? nextCheckTime,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final goal = GoalLimit(
      appName: appName,
      packageName: packageName,
      appIcon: appIcon,
      limitInMinutes: limitInMinutes,
      currentUsage: currentUsage,
      category: category,
      isLimitReached: isLimitReached,
      lastCheckTime: lastCheckTime ?? now,
      notifiedAt80Percent: notifiedAt80Percent,
      notifiedAt95Percent: notifiedAt95Percent,
      nextCheckTime: nextCheckTime,
    );

    await _dbHelper.updateGoal(goal);
  }

  // Remove a goal
  Future<void> removeGoal(String packageName) async {
    await _dbHelper.deleteGoal(packageName);
  }

  // Update usage for a goal
  Future<void> updateUsage(
      String packageName,
      int currentUsage,
      bool isLimitReached,
      int lastCheckTime,
      bool notifiedAt80Percent,
      bool notifiedAt95Percent,
      int? nextCheckTime,
      ) async {
    await _dbHelper.updateUsage(
      packageName,
      currentUsage,
      isLimitReached,
      lastCheckTime,
      notifiedAt80Percent,
      notifiedAt95Percent,
      nextCheckTime,
    );
  }

  // Reset notification flags for all goals
  Future<void> resetUsageData() async {
    await _dbHelper.resetNotificationFlags();
  }
}