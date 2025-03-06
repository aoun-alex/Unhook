import 'dart:typed_data';
import '../../data/models/goal_limit.dart';

class GoalService {
  // In-memory storage for goals (for now)
  static final List<GoalLimit> _goals = [];

  // Get all active goals
  List<GoalLimit> getActiveGoals() {
    return List.from(_goals);
  }

  // Add a new goal
  void addGoal({
    required String appName,
    required String packageName,
    required Uint8List? appIcon,
    required int limitInMinutes,
    required String category,
  }) {
    // First check if a goal for this app already exists
    final existingIndex = _goals.indexWhere((goal) => goal.packageName == packageName);

    if (existingIndex != -1) {
      // Update existing goal
      _goals[existingIndex] = GoalLimit(
        appName: appName,
        packageName: packageName,
        appIcon: appIcon,
        limitInMinutes: limitInMinutes,
        currentUsage: _goals[existingIndex].currentUsage,
        category: category,
      );
    } else {
      // Add new goal
      _goals.add(GoalLimit(
        appName: appName,
        packageName: packageName,
        appIcon: appIcon,
        limitInMinutes: limitInMinutes,
        currentUsage: 0, // Start with zero usage
        category: category,
      ));
    }
  }

  // Remove a goal
  void removeGoal(String packageName) {
    _goals.removeWhere((goal) => goal.packageName == packageName);
  }
}