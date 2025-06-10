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

// Notifier for evaluating daily streak and handling streak updates - SIMPLIFIED FOR DEMO
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
      // For demo purposes, skip database operations and just get the current streak
      // Comment out these lines that might interfere with placeholder data:
      // await _streakService.processMissedDays();
      // await _streakService.evaluateDailyStreak();

      // Just fetch the current streak value (which returns our placeholder 90)
      final currentStreak = await _streakService.getCurrentStreak();
      state = AsyncValue.data(currentStreak);
    } catch (e) {
      // Even on error, return placeholder data
      state = const AsyncValue.data(90);
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

  // Manually trigger a streak evaluation - SIMPLIFIED FOR DEMO
  Future<void> evaluateStreak() async {
    state = const AsyncValue.loading();

    // For demo, just return the placeholder data immediately
    try {
      final currentStreak = await _streakService.getCurrentStreak();
      state = AsyncValue.data(currentStreak);
    } catch (e) {
      state = const AsyncValue.data(90); // Fallback to placeholder
    }
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