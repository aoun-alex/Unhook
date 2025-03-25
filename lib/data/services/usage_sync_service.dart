import '../database/database_helper.dart';
import 'usage_service.dart';
import '../models/goal_limit.dart';
import 'dart:developer' as developer;

class UsageSyncService {
  final UsageService _usageService;
  final DatabaseHelper _dbHelper;

  UsageSyncService(this._usageService, this._dbHelper);

  // Synchronize usage data with goals
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

        // Use current time as the last check time
        final now = DateTime.now().millisecondsSinceEpoch;

        // Calculate the percentage of limit used
        double percentageUsed = 0;
        if (goal.limitInMinutes > 0) {
          percentageUsed = (usageMinutes / goal.limitInMinutes) * 100;
        }

        // Determine notification flags based on current usage
        bool notifiedAt80Percent = goal.notifiedAt80Percent;
        bool notifiedAt95Percent = goal.notifiedAt95Percent;

        if (percentageUsed >= 95) {
          notifiedAt95Percent = true;
          notifiedAt80Percent = true;
        } else if (percentageUsed >= 80) {
          notifiedAt80Percent = true;
        }

        // Calculate next check time based on how close to limit
        int? nextCheckTime;
        if (isLimitReached) {
          // No need to check again today
          nextCheckTime = null;
        } else if (percentageUsed >= 95) {
          // Check again in 2 minutes
          nextCheckTime = now + (2 * 60 * 1000);
        } else if (percentageUsed >= 80) {
          // Check again in 5 minutes
          nextCheckTime = now + (5 * 60 * 1000);
        } else if (percentageUsed >= 50) {
          // Check again in 10 minutes
          nextCheckTime = now + (10 * 60 * 1000);
        } else {
          // Check again in 20 minutes
          nextCheckTime = now + (20 * 60 * 1000);
        }

        // Update the goal in database with all required parameters
        await _dbHelper.updateUsage(
            goal.packageName,
            usageMinutes,
            isLimitReached,
            now,
            notifiedAt80Percent,
            notifiedAt95Percent,
            nextCheckTime
        );

        developer.log('Updated usage for ${goal.appName}: $usageMinutes min (limit: ${goal.limitInMinutes} min)');
      }
    } catch (e) {
      developer.log('Error syncing usage: $e');
    }
  }
}