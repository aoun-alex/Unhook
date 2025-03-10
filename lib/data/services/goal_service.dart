import 'dart:typed_data';
import '../models/goal_limit.dart';
import '../database/database_helper.dart';

class GoalService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Get all active goals
  Future<List<GoalLimit>> getActiveGoals() async {
    return await _dbHelper.getGoals();
  }

  // Add a new goal
  Future<void> addGoal({
    required String appName,
    required String packageName,
    required Uint8List? appIcon,
    required int limitInMinutes,
    required String category,
  }) async {
    final goal = GoalLimit(
      appName: appName,
      packageName: packageName,
      appIcon: appIcon,
      limitInMinutes: limitInMinutes,
      currentUsage: 0, // Start with zero usage
      category: category,
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
  }) async {
    final goal = GoalLimit(
      appName: appName,
      packageName: packageName,
      appIcon: appIcon,
      limitInMinutes: limitInMinutes,
      currentUsage: currentUsage,
      category: category,
      isLimitReached: isLimitReached,
    );

    await _dbHelper.updateGoal(goal);
  }

  // Remove a goal
  Future<void> removeGoal(String packageName) async {
    await _dbHelper.deleteGoal(packageName);
  }

  // Update usage for a goal
  Future<void> updateUsage(String packageName, int currentUsage, bool isLimitReached) async {
    await _dbHelper.updateUsage(packageName, currentUsage, isLimitReached);
  }
}