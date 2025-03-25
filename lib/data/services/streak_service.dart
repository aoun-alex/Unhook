import '../database/database_helper.dart';
import '../models/streak_record.dart';
import 'dart:developer' as developer;

class StreakService {
  final DatabaseHelper _dbHelper;

  StreakService(this._dbHelper);

  // Format date as YYYY-MM-DD
  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Get the current streak count
  Future<int> getCurrentStreak() async {
    try {
      final streakData = await _dbHelper.getStreakData();
      return streakData['currentStreak'] ?? 0;
    } catch (e) {
      developer.log('Error getting current streak: $e');
      return 0;
    }
  }

  // Get the longest streak achieved
  Future<int> getLongestStreak() async {
    try {
      final streakData = await _dbHelper.getStreakData();
      return streakData['longestStreak'] ?? 0;
    } catch (e) {
      developer.log('Error getting longest streak: $e');
      return 0;
    }
  }

  // Check and update the streak at the end of the day
  Future<void> evaluateDailyStreak() async {
    try {
      final today = DateTime.now();
      final todayFormatted = _formatDate(today);
      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdayFormatted = _formatDate(yesterday);

      // Get current streak data
      final streakData = await _dbHelper.getStreakData();
      int currentStreak = streakData['currentStreak'] ?? 0;
      int longestStreak = streakData['longestStreak'] ?? 0;
      String? lastStreakDate = streakData['lastStreakDate'];
      String? lastCheckDate = streakData['lastCheckDate'];

      // Avoid processing the same day twice
      if (lastCheckDate == todayFormatted) {
        developer.log('Already processed streak for today: $todayFormatted');
        return;
      }

      // Check if any limits were exceeded yesterday
      final anyLimitExceeded = await _dbHelper.wasAnyLimitExceededOnDate(yesterdayFormatted);

      // Update streak based on yesterday's performance
      if (!anyLimitExceeded) {
        // All limits respected - streak continues or starts
        currentStreak += 1;

        // Check if we have a new longest streak
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }

        // Record the streak day
        await _dbHelper.recordDailyStreak(
            yesterdayFormatted,
            true, // allLimitsRespected
            currentStreak
        );

        developer.log('Streak increased to $currentStreak days');
      } else {
        // A limit was exceeded - reset streak
        currentStreak = 0;

        // Record the broken streak
        await _dbHelper.recordDailyStreak(
            yesterdayFormatted,
            false, // some limit was exceeded
            0 // reset streak day counter
        );

        developer.log('Streak reset to 0 due to exceeded limits');
      }

      // Update the streak data in the database
      await _dbHelper.updateStreakData(
        currentStreak,
        longestStreak,
        yesterdayFormatted, // last streak date
        todayFormatted, // last check date
      );

    } catch (e) {
      developer.log('Error evaluating daily streak: $e');
    }
  }

  // Process streak for any missed days
  Future<void> processMissedDays() async {
    try {
      final streakData = await _dbHelper.getStreakData();
      final lastCheckDate = streakData['lastCheckDate'];

      if (lastCheckDate == null) {
        // First time using the app, start tracking from today
        final today = _formatDate(DateTime.now());
        await _dbHelper.updateStreakData(0, 0, null, today);
        return;
      }

      // Parse the last check date
      final lastCheck = DateTime.parse(lastCheckDate);
      final today = DateTime.now();

      // Calculate days since last check
      final difference = today.difference(lastCheck).inDays;

      if (difference <= 1) {
        // No missed days or just yesterday which will be handled by evaluateDailyStreak
        return;
      }

      // Process each missed day
      for (int i = difference - 1; i >= 1; i--) {
        final missedDate = today.subtract(Duration(days: i));
        final missedDateFormatted = _formatDate(missedDate);

        // Check if we already have a record for this date
        final record = await _dbHelper.getDailyRecord(missedDateFormatted);
        if (record == null) {
          // No record exists, check if any goals were set for that day
          final goalsExisted = await _goalsExistedOnDate(missedDateFormatted);

          if (goalsExisted) {
            // If goals existed but we don't have a record, we'll assume the streak was broken
            // since the user didn't open the app to track usage
            await _dbHelper.recordDailyStreak(missedDateFormatted, false, 0);

            // Reset streak if it was ongoing
            if (streakData['currentStreak'] > 0) {
              await _dbHelper.updateStreakData(
                0, // reset current streak
                streakData['longestStreak'],
                null, // clear last streak date
                missedDateFormatted, // update last check date
              );
            }
          }
        }
      }

    } catch (e) {
      developer.log('Error processing missed days: $e');
    }
  }

  // Helper method to check if any goals existed on a specific date
  Future<bool> _goalsExistedOnDate(String date) async {
    final goals = await _dbHelper.getGoals();
    return goals.isNotEmpty;
  }

  // Get records for a specific month
  Future<List<StreakRecord>> getMonthRecords(int year, int month) async {
    try {
      // Calculate the start and end dates for the month
      final startDate = DateTime(year, month, 1);
      final endDate = month < 12
          ? DateTime(year, month + 1, 0)
          : DateTime(year + 1, 1, 0);

      // Get all records for the month
      return await _dbHelper.getDailyRecords(startDate, endDate);
    } catch (e) {
      developer.log('Error getting month records: $e');
      return [];
    }
  }

  // Get a summary of the current month's streak status
  Future<Map<String, dynamic>> getCurrentMonthSummary() async {
    try {
      final now = DateTime.now();
      final records = await getMonthRecords(now.year, now.month);

      // Count days with respected limits
      final daysWithRespectedLimits = records.where((r) => r.allLimitsRespected).length;

      // Get the current streak
      final currentStreak = await getCurrentStreak();

      // Get the longest streak this month
      int longestStreakThisMonth = 0;
      int currentMonthStreak = 0;

      for (final record in records) {
        if (record.allLimitsRespected) {
          currentMonthStreak++;
          if (currentMonthStreak > longestStreakThisMonth) {
            longestStreakThisMonth = currentMonthStreak;
          }
        } else {
          currentMonthStreak = 0;
        }
      }

      return {
        'daysInMonth': DateTime(now.year, now.month + 1, 0).day,
        'daysWithRespectedLimits': daysWithRespectedLimits,
        'currentStreak': currentStreak,
        'longestStreakThisMonth': longestStreakThisMonth,
      };
    } catch (e) {
      developer.log('Error getting month summary: $e');
      return {
        'daysInMonth': 30,
        'daysWithRespectedLimits': 0,
        'currentStreak': 0,
        'longestStreakThisMonth': 0,
      };
    }
  }
}