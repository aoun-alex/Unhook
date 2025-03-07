import 'dart:typed_data';
import '../../data/models/goal_limit.dart';
import '../../data/models/hive_goal_limit.dart';
import 'hive_service.dart';

class GoalService {
  // Get all active goals
  List<GoalLimit> getActiveGoals() {
    final goalsBox = HiveService.getGoalsBox();
    return goalsBox.values.map((hiveGoal) => _convertToGoalLimit(hiveGoal)).toList();
  }

  // Add a new goal
  void addGoal({
    required String appName,
    required String packageName,
    required Uint8List? appIcon,
    required int limitInMinutes,
    required String category,
  }) {
    final goalsBox = HiveService.getGoalsBox();
    // First check if a goal for this app already exists
    final existingGoalKey = _getKeyByPackageName(packageName);

    if (existingGoalKey != null) {
      // Update existing goal
      goalsBox.put(existingGoalKey, HiveGoalLimit(
        appName: appName,
        packageName: packageName,
        appIcon: appIcon,
        limitInMinutes: limitInMinutes,
        currentUsage: goalsBox.get(existingGoalKey)?.currentUsage ?? 0,
        category: category,
        isLimitReached: false,
      ));
    } else {
      // Add new goal
      goalsBox.add(HiveGoalLimit(
        appName: appName,
        packageName: packageName,
        appIcon: appIcon,
        limitInMinutes: limitInMinutes,
        currentUsage: 0, // Start with zero usage
        category: category,
        isLimitReached: false,
      ));
    }
  }

  // Remove a goal
  void removeGoal(String packageName) {
    final goalsBox = HiveService.getGoalsBox();
    final keyToRemove = _getKeyByPackageName(packageName);
    if (keyToRemove != null) {
      goalsBox.delete(keyToRemove);
    }
  }

  // Update a goal's usage
  void updateGoalUsage(String packageName, int newUsage) {
    final goalsBox = HiveService.getGoalsBox();
    final key = _getKeyByPackageName(packageName);
    if (key != null) {
      final goal = goalsBox.get(key);
      if (goal != null) {
        goal.currentUsage = newUsage;
        goal.isLimitReached = newUsage >= goal.limitInMinutes;
        goalsBox.put(key, goal);
      }
    }
  }

  // Helper method to get a goal's key by package name
  dynamic _getKeyByPackageName(String packageName) {
    final goalsBox = HiveService.getGoalsBox();
    for (var entry in goalsBox.toMap().entries) {
      if (entry.value.packageName == packageName) {
        return entry.key;
      }
    }
    return null;
  }

  // Helper method to convert HiveGoalLimit to GoalLimit
  GoalLimit _convertToGoalLimit(HiveGoalLimit hiveGoal) {
    return GoalLimit(
      appName: hiveGoal.appName,
      packageName: hiveGoal.packageName,
      appIcon: hiveGoal.appIcon,
      limitInMinutes: hiveGoal.limitInMinutes,
      currentUsage: hiveGoal.currentUsage,
      category: hiveGoal.category,
      isLimitReached: hiveGoal.isLimitReached,
    );
  }
}