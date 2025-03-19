import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/streak_record.dart';
import '../data/services/streak_service.dart';
import '../data/database/database_helper.dart';
import 'dart:async';

// Provider for DatabaseHelper
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

// Provider for StreakService
final streakServiceProvider = Provider<StreakService>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return StreakService(dbHelper);
});

// Provider for current streak count
final currentStreakProvider = FutureProvider<int>((ref) async {
  final streakService = ref.watch(streakServiceProvider);
  return await streakService.getCurrentStreak();
});

// Provider for longest streak count
final longestStreakProvider = FutureProvider<int>((ref) async {
  final streakService = ref.watch(streakServiceProvider);
  return await streakService.getLongestStreak();
});

// Provider for monthly streak records
final monthlyStreakRecordsProvider = FutureProvider.family<List<StreakRecord>, MonthYear>((ref, monthYear) async {
  final streakService = ref.watch(streakServiceProvider);
  return await streakService.getMonthRecords(monthYear.year, monthYear.month);
});

// Provider for monthly streak summary
final monthlyStreakSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final streakService = ref.watch(streakServiceProvider);
  return await streakService.getCurrentMonthSummary();
});

// Notifier for evaluating daily streak and handling streak updates
class StreakNotifier extends StateNotifier<AsyncValue<int>> {
  final StreakService _streakService;
  Timer? _dailyEvaluationTimer;

  StreakNotifier(this._streakService) : super(const AsyncValue.loading()) {
    // Immediately fetch current streak
    _fetchCurrentStreak();

    // Schedule next evaluation to occur at midnight
    _scheduleDailyEvaluation();
  }

  Future<void> _fetchCurrentStreak() async {
    try {
      // First process any missed days
      await _streakService.processMissedDays();

      // Then evaluate yesterday's streak (if not already done)
      await _streakService.evaluateDailyStreak();

      // Finally, fetch the current streak value
      final currentStreak = await _streakService.getCurrentStreak();
      state = AsyncValue.data(currentStreak);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void _scheduleDailyEvaluation() {
    // Cancel any existing timer
    _dailyEvaluationTimer?.cancel();

    // Calculate time until midnight
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final timeUntilMidnight = midnight.difference(now);

    // Schedule the evaluation
    _dailyEvaluationTimer = Timer(timeUntilMidnight, () {
      // Run the streak evaluation
      _fetchCurrentStreak();

      // Schedule the next evaluation
      _scheduleDailyEvaluation();
    });
  }

  // Manually trigger a streak evaluation
  Future<void> evaluateStreak() async {
    state = const AsyncValue.loading();
    await _fetchCurrentStreak();
  }

  @override
  void dispose() {
    _dailyEvaluationTimer?.cancel();
    super.dispose();
  }
}

// Provider for streak notifier
final streakNotifierProvider = StateNotifierProvider<StreakNotifier, AsyncValue<int>>((ref) {
  final streakService = ref.watch(streakServiceProvider);
  return StreakNotifier(streakService);
});

// Simple class to represent a month and year
class MonthYear {
  final int year;
  final int month;

  MonthYear(this.year, this.month);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is MonthYear &&
              runtimeType == other.runtimeType &&
              year == other.year &&
              month == other.month;

  @override
  int get hashCode => year.hashCode ^ month.hashCode;
}