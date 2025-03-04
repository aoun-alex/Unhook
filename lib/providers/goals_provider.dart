import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:android_package_manager/android_package_manager.dart';
import 'package:flutter/services.dart';
import '../data/models/goal_limit.dart';

final goalsServiceProvider = Provider<GoalsService>((ref) => GoalsService());

class GoalsService {
  final _packageManager = AndroidPackageManager();
  Uint8List? _defaultIcon;

  // Method to get default icon
  Future<Uint8List> _getDefaultIcon() async {
    if (_defaultIcon == null) {
      final ByteData data = await rootBundle.load('assets/default-icon.png');
      _defaultIcon = data.buffer.asUint8List();
    }
    return _defaultIcon!;
  }

  // Fetch app icon
  Future<Uint8List> fetchIcon(String packageName) async {
    try {
      final icon = await _packageManager.getApplicationIcon(packageName: packageName);
      return icon ?? await _getDefaultIcon();
    } catch (_) {
      return await _getDefaultIcon();
    }
  }

  // Mock data for now, in a real app this would come from a database
  Future<List<GoalLimit>> getActiveGoals() async {
    // Get app icons from the package manager
    final iconMap = await _fetchAppIcons();

    // Return mock data with real icons
    return [
      GoalLimit(
        appName: 'Instagram',
        packageName: 'com.instagram.android',
        appIcon: iconMap['com.instagram.android'],
        currentUsage: 45,
        limitInMinutes: 60,
        category: 'Social',
      ),
      GoalLimit(
        appName: 'YouTube',
        packageName: 'com.google.android.youtube',
        appIcon: iconMap['com.google.android.youtube'],
        currentUsage: 85,
        limitInMinutes: 90,
        category: 'Entertainment',
      ),
      GoalLimit(
        appName: 'X',
        packageName: 'com.twitter.android',
        appIcon: iconMap['com.twitter.android'],
        currentUsage: 30,
        limitInMinutes: 30,
        category: 'Social',
        isLimitReached: true,
      ),
      GoalLimit(
        appName: 'TikTok',
        packageName: 'com.zhiliaoapp.musically',
        appIcon: iconMap['com.zhiliaoapp.musically'],
        currentUsage: 15,
        limitInMinutes: 45,
        category: 'Entertainment',
      ),
    ];
  }

  Future<Map<String, Uint8List?>> _fetchAppIcons() async {
    Map<String, Uint8List?> iconMap = {};

    // List of package names to fetch icons for
    List<String> packageNames = [
      'com.instagram.android',
      'com.google.android.youtube',
      'com.twitter.android',
      'com.zhiliaoapp.musically',
    ];

    // Fetch icons for each package
    for (String packageName in packageNames) {
      try {
        iconMap[packageName] = await fetchIcon(packageName);
      } catch (e) {
        // Handle the error, maybe set a default icon
        iconMap[packageName] = null;
      }
    }

    return iconMap;
  }
}

final activeGoalsProvider = FutureProvider<List<GoalLimit>>((ref) async {
  final goalsService = ref.read(goalsServiceProvider);
  return await goalsService.getActiveGoals();
});