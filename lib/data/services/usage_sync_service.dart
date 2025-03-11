import '../database/database_helper.dart';
import 'usage_service.dart';
import '../models/goal_limit.dart';
import 'dart:developer' as developer;

class UsageSyncService {
  final UsageService _usageService;
  final DatabaseHelper _dbHelper;

  UsageSyncService(this._usageService, this._dbHelper);

  /// Synchronize usage data with goals
  Future<void> syncUsageWithGoals() async {
    try {
      // Get all active goals
      List<GoalLimit> goals = await _dbHelper.getGoals();

      // For each goal, get current usage and update
      for (var goal in goals) {
        // Get actual usage in seconds
        int usageSeconds = await _usageService.getAppUsageToday(goal.packageName);

        // Convert to minutes (rounded up)
        int usageMinutes = (usageSeconds / 60).ceil();

        // Check if limit is reached
        bool isLimitReached = usageMinutes >= goal.limitInMinutes;

        // Update the goal in database
        await _dbHelper.updateUsage(
            goal.packageName,
            usageMinutes,
            isLimitReached
        );

        developer.log('Updated usage for ${goal.appName}: $usageMinutes min (limit: ${goal.limitInMinutes} min)');
      }
    } catch (e) {
      developer.log('Error syncing usage: $e');
    }
  }
}