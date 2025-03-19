import 'dart:async';
import 'package:flutter/services.dart';
import '../models/goal_limit.dart';
import 'usage_broadcast_receiver.dart';
import 'usage_service.dart';
import 'streak_service.dart';
import '../database/database_helper.dart';
import 'dart:developer' as developer;

class UsageMonitoringService {
  static final UsageMonitoringService _instance = UsageMonitoringService._internal();

  factory UsageMonitoringService() {
    return _instance;
  }

  UsageMonitoringService._internal();

  static const MethodChannel _channel = MethodChannel('com.example.unhook/usage_tracking');

  final UsageBroadcastReceiver _receiver = UsageBroadcastReceiver();
  final UsageService _usageService = UsageService();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  StreamSubscription? _eventsSubscription;

  Future<void> initialize() async {
    // Check and request usage stats permission
    bool hasPermission = await checkUsageStatsPermission();
    if (!hasPermission) {
      await requestUsageStatsPermission();
    }

    // Initialize the broadcast receiver
    _receiver.initialize();

    // Listen for events
    _eventsSubscription = _receiver.events.listen(_handleEvent);

    // Start the monitoring
    await startMonitoring();

    developer.log('Usage monitoring service initialized');
  }

  Future<bool> checkUsageStatsPermission() async {
    try {
      return await _channel.invokeMethod('checkUsageStatsPermission');
    } catch (e) {
      developer.log('Error checking usage stats permission: $e');
      return false;
    }
  }

  Future<void> requestUsageStatsPermission() async {
    try {
      await _channel.invokeMethod('requestUsageStatsPermission');
    } catch (e) {
      developer.log('Error requesting usage stats permission: $e');
    }
  }

  Future<void> startMonitoring() async {
    try {
      await _channel.invokeMethod('startUsageMonitoring');
      developer.log('Usage monitoring started');
    } catch (e) {
      developer.log('Error starting usage monitoring: $e');
    }
  }

  Future<void> stopMonitoring() async {
    try {
      await _channel.invokeMethod('stopUsageMonitoring');
      developer.log('Usage monitoring stopped');
    } catch (e) {
      developer.log('Error stopping usage monitoring: $e');
    }
  }

  Future<void> checkSpecificApp(GoalLimit goal) async {
    try {
      await _channel.invokeMethod('checkSpecificAppUsage', {
        'packageName': goal.packageName,
        'limitMinutes': goal.limitInMinutes,
        'appName': goal.appName,
      });
      developer.log('Requested check for ${goal.packageName}');
    } catch (e) {
      developer.log('Error checking specific app: $e');
    }
  }

  Future<void> cancelIntensiveChecks(String packageName) async {
    try {
      await _channel.invokeMethod('cancelIntensiveChecks', {
        'packageName': packageName,
      });
      developer.log('Cancelled intensive checks for $packageName');
    } catch (e) {
      developer.log('Error cancelling intensive checks: $e');
    }
  }

  void _handleEvent(UsageEvent event) async {
    if (event is UsageUpdateEvent) {
      await _handleUsageUpdate(event);
    } else if (event is CheckAllAppsEvent) {
      await _handleCheckAllApps();
    } else if (event is ResetUsageDataEvent) {
      await _handleResetUsageData();
    } else if (event is EvaluateStreakEvent) {
      await _handleEvaluateStreak();
    }
  }

  Future<void> _handleUsageUpdate(UsageUpdateEvent event) async {
    developer.log('Received usage update: $event');

    // Find the goal for this package
    final goals = await _dbHelper.getGoals();
    final goal = goals.firstWhere(
          (g) => g.packageName == event.packageName,
      orElse: () => GoalLimit(
        appName: 'Unknown',
        packageName: event.packageName,
        limitInMinutes: 0,
        currentUsage: 0,
        category: 'Other',
      ),
    );

    if (goal.limitInMinutes > 0) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final usagePercentage = event.usageMinutes / goal.limitInMinutes * 100;

      // Determine notification status based on current usage percentage
      final shouldNotifyAt80 = usagePercentage >= 80 && !goal.notifiedAt80Percent;
      final shouldNotifyAt95 = usagePercentage >= 95 && !goal.notifiedAt95Percent;

      // Calculate next check time based on how close to limit
      int? nextCheckTime;
      if (event.limitReached) {
        // No need to check again today
        nextCheckTime = null;
      } else if (usagePercentage >= 95) {
        // Check again in 2 minutes
        nextCheckTime = now + (2 * 60 * 1000);
      } else if (usagePercentage >= 80) {
        // Check again in 5 minutes
        nextCheckTime = now + (5 * 60 * 1000);
      } else if (usagePercentage >= 50) {
        // Check again in 10 minutes
        nextCheckTime = now + (10 * 60 * 1000);
      } else {
        // Check again in 20 minutes
        nextCheckTime = now + (20 * 60 * 1000);
      }

      // Update the database
      await _dbHelper.updateUsage(
        event.packageName,
        event.usageMinutes,
        event.limitReached,
        now,
        shouldNotifyAt80 || goal.notifiedAt80Percent,
        shouldNotifyAt95 || goal.notifiedAt95Percent,
        nextCheckTime,
      );
    }
  }

  Future<void> _handleCheckAllApps() async {
    developer.log('Checking all apps with limits');

    final goals = await _dbHelper.getGoalsToCheck();
    if (goals.isEmpty) {
      developer.log('No goals to check');
      return;
    }

    for (final goal in goals) {
      if (goal.limitInMinutes > 0) {
        // Update current usage for the goal
        final usageMinutes = await _getCurrentUsage(goal.packageName);
        final now = DateTime.now().millisecondsSinceEpoch;
        final isLimitReached = usageMinutes >= goal.limitInMinutes;
        final usagePercentage = usageMinutes / goal.limitInMinutes * 100;

        // Determine notification status based on current usage percentage
        final shouldNotifyAt80 = usagePercentage >= 80 && !goal.notifiedAt80Percent;
        final shouldNotifyAt95 = usagePercentage >= 95 && !goal.notifiedAt95Percent;

        // Calculate next check time based on how close to limit
        int? nextCheckTime;
        if (isLimitReached) {
          // No need to check again today
          nextCheckTime = null;
        } else if (usagePercentage >= 95) {
          // Check again in 2 minutes
          nextCheckTime = now + (2 * 60 * 1000);
        } else if (usagePercentage >= 80) {
          // Check again in 5 minutes
          nextCheckTime = now + (5 * 60 * 1000);
        } else if (usagePercentage >= 50) {
          // Check again in 10 minutes
          nextCheckTime = now + (10 * 60 * 1000);
        } else {
          // Check again in 20 minutes
          nextCheckTime = now + (20 * 60 * 1000);
        }

        // Update the database
        await _dbHelper.updateUsage(
          goal.packageName,
          usageMinutes,
          isLimitReached,
          now,
          shouldNotifyAt80 || goal.notifiedAt80Percent,
          shouldNotifyAt95 || goal.notifiedAt95Percent,
          nextCheckTime,
        );

        // If approaching or at limit, request more frequent checks from native side
        if (usagePercentage >= 80) {
          await checkSpecificApp(goal);
        }
      }
    }
  }

  Future<int> _getCurrentUsage(String packageName) async {
    try {
      // Use UsageService to get current usage
      return await _usageService.getAppUsageTodayMinutes(packageName);
    } catch (e) {
      developer.log('Error getting current usage: $e');
      return 0;
    }
  }

  Future<void> _handleResetUsageData() async {
    developer.log('Resetting usage data for all goals');

    try {
      await _dbHelper.resetNotificationFlags();
      developer.log('Usage data reset completed');
    } catch (e) {
      developer.log('Error resetting usage data: $e');
    }
  }

  Future<void> _handleEvaluateStreak() async {
    developer.log('Evaluating streak status from broadcast');

    try {
      // Import the streak service provider at the method level to avoid circular dependencies
      final streakServiceProvider = _importStreakServiceProvider();
      if (streakServiceProvider != null) {
        // Manually trigger streak evaluation
        await streakServiceProvider().evaluateDailyStreak();
        developer.log('Streak evaluation completed');
      }
    } catch (e) {
      developer.log('Error evaluating streak: $e');
    }
  }

  // Helper method to import streak service provider to avoid circular dependencies
  dynamic _importStreakServiceProvider() {
    try {
      // This imports the provider at runtime to avoid circular dependencies
      return () => StreakService(DatabaseHelper());
    } catch (e) {
      developer.log('Error importing streak service: $e');
      return null;
    }
  }

  void dispose() {
    _eventsSubscription?.cancel();
    _receiver.dispose();
  }
}