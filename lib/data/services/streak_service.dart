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

  // Get the current streak count - PLACEHOLDER DATA
  Future<int> getCurrentStreak() async {
    try {
      // Return placeholder 90-day streak
      return 90;
    } catch (e) {
      developer.log('Error getting current streak: $e');
      return 90; // Still return placeholder on error
    }
  }

  // Get the longest streak achieved - PLACEHOLDER DATA
  Future<int> getLongestStreak() async {
    try {
      // Return placeholder longest streak (could be same or higher)
      return 95; // Slightly higher than current for demo
    } catch (e) {
      developer.log('Error getting longest streak: $e');
      return 95; // Still return placeholder on error
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

  // Get records for a specific month - PLACEHOLDER DATA
  Future<List<StreakRecord>> getMonthRecords(int year, int month) async {
    try {
      // Generate placeholder streak records
      List<StreakRecord> records = [];

      // Define our 90-day streak period: March 12, 2025 to June 10, 2025
      final streakStart = DateTime(2025, 3, 12);
      final streakEnd = DateTime(2025, 6, 10);

      // Get the first and last day of the requested month
      final monthStart = DateTime(year, month, 1);
      final monthEnd = DateTime(year, month + 1, 0); // Last day of month

      // Generate records for each day in the month
      for (int day = 1; day <= monthEnd.day; day++) {
        final currentDate = DateTime(year, month, day);
        final dateStr = _formatDate(currentDate);

        // Check if this date falls within our streak period
        bool isInStreak = currentDate.isAfter(streakStart.subtract(const Duration(days: 1))) &&
            currentDate.isBefore(streakEnd.add(const Duration(days: 1)));

        if (isInStreak) {
          // Calculate the streak day number
          final daysSinceStart = currentDate.difference(streakStart).inDays + 1;

          records.add(StreakRecord(
            date: dateStr,
            streakDay: daysSinceStart,
            allLimitsRespected: true, // Always true for streak days
            timestamp: currentDate.millisecondsSinceEpoch,
          ));
        }
        // Don't create records for days outside the streak - they'll show as "no data" (gray)
      }

      return records;
    } catch (e) {
      developer.log('Error getting month records: $e');
      return [];
    }
  }

  // Get a summary of the current month's streak status - PLACEHOLDER DATA
  Future<Map<String, dynamic>> getCurrentMonthSummary() async {
    try {
      final now = DateTime.now();
      final records = await getMonthRecords(now.year, now.month);

      // Count days with respected limits in current month
      final daysWithRespectedLimits = records.where((r) => r.allLimitsRespected).length;

      // For June 2025, we have 10 days in streak (June 1-10)
      final currentStreak = now.month == 6 && now.year == 2025 ? 90 : await getCurrentStreak();

      // Longest streak this month would be the current streak if we're in June
      final longestStreakThisMonth = now.month == 6 && now.year == 2025 ? 10 : daysWithRespectedLimits;

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
        'currentStreak': 90, // Placeholder
        'longestStreakThisMonth': 0,
      };
    }
  }
}