import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/goal_limit.dart';
import '../data/services/goal_service.dart';

final goalServiceProvider = Provider<GoalService>((ref) {
  return GoalService();
});

// Provider for active goals
final activeGoalsProvider = StateNotifierProvider<GoalsNotifier, List<GoalLimit>>((ref) {
  final goalService = ref.read(goalServiceProvider);
  return GoalsNotifier(goalService);
});

class GoalsNotifier extends StateNotifier<List<GoalLimit>> {
  final GoalService _goalService;

  GoalsNotifier(this._goalService) : super(_goalService.getActiveGoals());

  void refreshGoals() {
    state = _goalService.getActiveGoals();
  }

  void addGoal({
    required String appName,
    required String packageName,
    required Uint8List? appIcon,
    required int limitInMinutes,
    required String category,
  }) {
    _goalService.addGoal(
      appName: appName,
      packageName: packageName,
      appIcon: appIcon,
      limitInMinutes: limitInMinutes,
      category: category,
    );
    refreshGoals();
  }

  void updateGoal({
    required String packageName,
    required int limitInMinutes,
    required String category,
  }) {
    // Find the existing goal to preserve other properties
    final existingGoal = state.firstWhere(
          (goal) => goal.packageName == packageName,
      orElse: () => GoalLimit(
          appName: '',
          packageName: packageName,
          limitInMinutes: 0,
          currentUsage: 0,
          category: ''
      ),
    );

    // Use the addGoal method to update
    _goalService.addGoal(
      appName: existingGoal.appName,
      packageName: packageName,
      appIcon: existingGoal.appIcon,
      limitInMinutes: limitInMinutes,
      category: category,
    );

    refreshGoals();
  }

  void removeGoal(String packageName) {
    _goalService.removeGoal(packageName);
    refreshGoals();
  }

  void updateUsage(String packageName, int newUsage) {
    _goalService.updateGoalUsage(packageName, newUsage);
    refreshGoals();
  }
}