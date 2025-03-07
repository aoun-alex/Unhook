import 'dart:typed_data';

class HiveGoalLimit {
  String appName;
  String packageName;
  Uint8List? appIcon;
  int limitInMinutes;
  int currentUsage;
  String category;
  bool isLimitReached;

  HiveGoalLimit({
    required this.appName,
    required this.packageName,
    this.appIcon,
    required this.limitInMinutes,
    required this.currentUsage,
    required this.category,
    this.isLimitReached = false,
  });
}