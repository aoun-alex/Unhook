import 'dart:developer' as developer;

import '../models/alternative_model.dart';
import '../constants/app_metadata.dart';
import '../database/database_helper.dart';
import '../database/mindful_database_extension.dart';
import '../models/goal_limit.dart';
import '../../constants.dart';

/// Service for managing and providing mindful alternatives
class AlternativesService {
  final DatabaseHelper _dbHelper;

  AlternativesService(this._dbHelper) {
    // Initialize tables
    _initDatabase();
  }

  /// Initialize the database tables for alternatives
  Future<void> _initDatabase() async {
    try {
      await _dbHelper.initMindfulTables();
    } catch (e) {
      developer.log('Error initializing mindful tables: $e');
    }
  }

  /// Get alternatives for a specific app
  List<Alternative> getAlternativesForApp(String packageName) {
    if (appMetadataMap.containsKey(packageName)) {
      return appMetadataMap[packageName]!.alternatives;
    }

    // If we don't have metadata for this specific app, try to match by display name
    final appName = appNameMap[packageName];
    if (appName != null) {
      // Look for apps with the same display name
      for (final entry in appMetadataMap.entries) {
        if (entry.value.displayName == appName) {
          return entry.value.alternatives;
        }
      }
    }

    return [];
  }

  /// Get all alternatives grouped by app category
  Map<String, List<Map<String, dynamic>>> getAllAlternativesByCategory() {
    final Map<String, List<Map<String, dynamic>>> result = {};

    for (final entry in appMetadataMap.entries) {
      final category = entry.value.category;
      final appName = entry.value.displayName;
      final packageName = entry.key;

      if (!result.containsKey(category)) {
        result[category] = [];
      }

      for (final alternative in entry.value.alternatives) {
        result[category]!.add({
          'alternative': alternative,
          'appName': appName,
          'packageName': packageName,
        });
      }
    }

    return result;
  }

  /// Get personalized alternatives based on the user's most used apps
  /// and apps that have set goals/limits
  Future<List<Map<String, dynamic>>> getPersonalizedAlternatives(List<GoalLimit> goals) async {
    final List<Map<String, dynamic>> results = [];

    // First, prioritize apps that have goals set
    for (final goal in goals) {
      final alternatives = getAlternativesForApp(goal.packageName);
      if (alternatives.isNotEmpty) {
        for (final alternative in alternatives) {
          results.add({
            'alternative': alternative,
            'appName': goal.appName,
            'packageName': goal.packageName,
            'isGoal': true,
            'usagePercentage': goal.usagePercentage,
          });
        }
      }
    }

    // Sort alternatives, prioritizing those for apps closer to their limits
    results.sort((a, b) {
      final aPercentage = a['usagePercentage'] as double? ?? 0.0;
      final bPercentage = b['usagePercentage'] as double? ?? 0.0;
      return bPercentage.compareTo(aPercentage);
    });

    return results;
  }

  /// Pin an alternative for quick access
  Future<bool> pinAlternative(Alternative alternative, String sourceAppPackage) async {
    try {
      await _dbHelper.pinAlternative(alternative, sourceAppPackage);
      return true;
    } catch (e) {
      developer.log('Error pinning alternative: $e');
      return false;
    }
  }

  /// Unpin an alternative
  Future<bool> unpinAlternative(String title) async {
    try {
      await _dbHelper.unpinAlternative(title);
      return true;
    } catch (e) {
      developer.log('Error unpinning alternative: $e');
      return false;
    }
  }

  /// Check if an alternative is pinned
  Future<bool> isAlternativePinned(String title) async {
    try {
      return await _dbHelper.isAlternativePinned(title);
    } catch (e) {
      developer.log('Error checking if alternative is pinned: $e');
      return false;
    }
  }

  /// Get all pinned alternatives
  Future<List<Alternative>> getPinnedAlternatives() async {
    try {
      return await _dbHelper.getPinnedAlternatives();
    } catch (e) {
      developer.log('Error getting pinned alternatives: $e');
      return [];
    }
  }

  /// Get recommendations based on a specific category
  List<Map<String, dynamic>> getRecommendationsByCategory(String category) {
    final List<Map<String, dynamic>> results = [];

    for (final entry in appMetadataMap.entries) {
      if (entry.value.category == category) {
        final appName = entry.value.displayName;
        final packageName = entry.key;

        for (final alternative in entry.value.alternatives) {
          results.add({
            'alternative': alternative,
            'appName': appName,
            'packageName': packageName,
          });
        }
      }
    }

    return results;
  }

  /// Get offline activity alternatives only
  List<Map<String, dynamic>> getOfflineAlternatives() {
    final List<Map<String, dynamic>> results = [];

    for (final entry in appMetadataMap.entries) {
      final appName = entry.value.displayName;
      final packageName = entry.key;

      for (final alternative in entry.value.alternatives) {
        if (alternative.isOfflineActivity) {
          results.add({
            'alternative': alternative,
            'appName': appName,
            'packageName': packageName,
          });
        }
      }
    }

    return results;
  }
}