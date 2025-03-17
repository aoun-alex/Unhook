import 'dart:typed_data';

class GoalLimit {
  final String appName;
  final String packageName;
  final Uint8List? appIcon;
  final int limitInMinutes;
  final int currentUsage;
  final String category;
  final bool isLimitReached;
  final int lastCheckTime;
  final bool notifiedAt80Percent;
  final bool notifiedAt95Percent;
  final int? nextCheckTime;

  GoalLimit({
    required this.appName,
    required this.packageName,
    this.appIcon,
    required this.limitInMinutes,
    required this.currentUsage,
    required this.category,
    this.isLimitReached = false,
    this.lastCheckTime = 0,
    this.notifiedAt80Percent = false,
    this.notifiedAt95Percent = false,
    this.nextCheckTime,
  });

  double get usagePercentage =>
      limitInMinutes > 0 ? (currentUsage / limitInMinutes) * 100 : 0;

  bool get isApproachingLimit =>
      usagePercentage >= 80 && usagePercentage < 95;

  bool get isNearLimit =>
      usagePercentage >= 95 && !isLimitReached;

  // Create a copy with updated values
  GoalLimit copyWith({
    String? appName,
    String? packageName,
    Uint8List? appIcon,
    int? limitInMinutes,
    int? currentUsage,
    String? category,
    bool? isLimitReached,
    int? lastCheckTime,
    bool? notifiedAt80Percent,
    bool? notifiedAt95Percent,
    int? nextCheckTime,
  }) {
    return GoalLimit(
      appName: appName ?? this.appName,
      packageName: packageName ?? this.packageName,
      appIcon: appIcon ?? this.appIcon,
      limitInMinutes: limitInMinutes ?? this.limitInMinutes,
      currentUsage: currentUsage ?? this.currentUsage,
      category: category ?? this.category,
      isLimitReached: isLimitReached ?? this.isLimitReached,
      lastCheckTime: lastCheckTime ?? this.lastCheckTime,
      notifiedAt80Percent: notifiedAt80Percent ?? this.notifiedAt80Percent,
      notifiedAt95Percent: notifiedAt95Percent ?? this.notifiedAt95Percent,
      nextCheckTime: nextCheckTime ?? this.nextCheckTime,
    );
  }
}