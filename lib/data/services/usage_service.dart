import 'package:usage_stats/usage_stats.dart';

class UsageService {
  /// Checks and, if needed, requests the usage permission.
  Future<bool> checkAndRequestPermission() async {
    bool hasPermission = await UsageStats.checkUsagePermission() ?? false;
    if (!hasPermission) {
      await UsageStats.grantUsagePermission();
      hasPermission = await UsageStats.checkUsagePermission() ?? false;
    }
    return hasPermission;
  }

  /// Retrieves usage data between [start] and [end] timestamps.
  Future<Map<String, Duration>> getUsageForPeriod(DateTime start, DateTime end) async {
    List<UsageInfo> stats = await UsageStats.queryUsageStats(start, end);
    Map<String, Duration> totalDuration = {
      'instagram': Duration.zero,
      'youtube': Duration.zero,
      'tiktok': Duration.zero,
      'facebook': Duration.zero,
    };

    for (var info in stats) {
      switch (info.packageName) {
        case 'com.instagram.android':
          totalDuration['instagram'] = totalDuration['instagram']! +
              Duration(milliseconds: int.tryParse(info.totalTimeInForeground ?? '0') ?? 0);
          break;
        case 'com.google.android.youtube':
          totalDuration['youtube'] = totalDuration['youtube']! +
              Duration(milliseconds: int.tryParse(info.totalTimeInForeground ?? '0') ?? 0);
          break;
        case 'com.zhiliaoapp.musically':
          totalDuration['tiktok'] = totalDuration['tiktok']! +
              Duration(milliseconds: int.tryParse(info.totalTimeInForeground ?? '0') ?? 0);
          break;
        case 'com.facebook.katana':
          totalDuration['facebook'] = totalDuration['facebook']! +
              Duration(milliseconds: int.tryParse(info.totalTimeInForeground ?? '0') ?? 0);
          break;
      }
    }
    return totalDuration;
  }
}
