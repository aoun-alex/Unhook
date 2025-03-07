import 'package:hive_flutter/hive_flutter.dart';
import '../models/hive_goal_limit.dart';
import '../adapters/uint8list_adapter.dart';
import '../adapters/hive_goal_limit_adapter.dart';

class HiveService {
  static const String goalsBoxName = 'goals';

  // Initialize Hive
  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(Uint8ListAdapter());
    }

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(HiveGoalLimitAdapter());
    }

    // Open boxes
    await Hive.openBox<HiveGoalLimit>(goalsBoxName);
  }

  // Get the goals box
  static Box<HiveGoalLimit> getGoalsBox() {
    return Hive.box<HiveGoalLimit>(goalsBoxName);
  }

  // Close Hive when app is closed
  static Future<void> close() async {
    await Hive.close();
  }
}