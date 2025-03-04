import 'dart:typed_data';

class GoalLimit {
  final String appName;
  final String packageName;
  final Uint8List? appIcon;
  final int limitInMinutes;
  final int currentUsage;
  final String category;
  final bool isLimitReached;

  GoalLimit({
    required this.appName,
    required this.packageName,
    this.appIcon,
    required this.limitInMinutes,
    required this.currentUsage,
    required this.category,
    this.isLimitReached = false,
  });
}