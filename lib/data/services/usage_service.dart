import 'package:usage_stats/usage_stats.dart';
import 'package:device_apps/device_apps.dart';
import '../../constants.dart';
import '../models/app_event.dart';
import '../models/app_usage.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;

class AppUsageSummary {
  final String appName;
  final String packageName;
  final Uint8List? appIcon;
  final int totalDurationSeconds;
  final List<AppUsage> sessions;

  AppUsageSummary({
    required this.appName,
    required this.packageName,
    required this.appIcon,
    required this.totalDurationSeconds,
    required this.sessions,
  });

  String get totalDurationText {
    int hours = totalDurationSeconds ~/ 3600;
    int minutes = (totalDurationSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

class UsageService {
  Uint8List? _defaultIcon;

  /// Checks and requests usage permission
  Future<bool> checkAndRequestPermission() async {
    bool hasPermission = await UsageStats.checkUsagePermission() ?? false;
    if (!hasPermission) {
      await UsageStats.grantUsagePermission();
      hasPermission = await UsageStats.checkUsagePermission() ?? false;
    }
    return hasPermission;
  }

  Future<Uint8List> _getDefaultIcon() async {
    if (_defaultIcon == null) {
      final ByteData data = await rootBundle.load('assets/default-icon.png');
      _defaultIcon = data.buffer.asUint8List();
    }
    return _defaultIcon!;
  }

  Future<Uint8List> fetchIcon(String packageName) async {
    try {
      final app = await DeviceApps.getApp(packageName, true);
      if (app != null && app is ApplicationWithIcon) {
        return Uint8List.fromList(app.icon);
      }
      return await _getDefaultIcon();
    } catch (_) {
      return await _getDefaultIcon();
    }
  }

  bool _isResumed(AppEvent event) => event.eventType == "Activity Resumed";
  bool _isPausedOrStopped(AppEvent event) =>
      event.eventType == "Activity Paused" || event.eventType == "Activity Stopped";

  /// Retrieves usage data for a specific time period
  Future<List<AppUsageSummary>> getUsageForPeriod(DateTime startDate, DateTime endDate) async {
    // Ensure we have permission
    bool hasPermission = await checkAndRequestPermission();
    if (!hasPermission) {
      throw Exception('Usage permission not granted');
    }

    List<EventUsageInfo> rawEvents = await UsageStats.queryEvents(startDate, endDate);

    Map<String, Uint8List> iconCache = {};

    Map<String, int> eventCountByPackage = {};
    for (var e in rawEvents) {
      if (e.packageName != null) {
        eventCountByPackage[e.packageName!] = (eventCountByPackage[e.packageName!] ?? 0) + 1;
      }
    }

    eventCountByPackage.entries
        .toList()
        .sort((a, b) => b.value.compareTo(a.value));
    for (var entry in eventCountByPackage.entries.take(10)) {
      developer.log('${entry.key}: ${entry.value} events (tracked: ${appNameMap.containsKey(entry.key)})');
    }

    Set<String> packageNames = rawEvents
        .where((e) => e.packageName != null && appNameMap.containsKey(e.packageName!))
        .map((e) => e.packageName!)
        .toSet();
    await Future.wait(
        packageNames.map((pkg) async {
          iconCache[pkg] = await fetchIcon(pkg);
        })
    );

    Map<String, List<AppEvent>> eventsByApp = {};

    for (var raw in rawEvents) {
      if (raw.packageName == null || !appNameMap.containsKey(raw.packageName!)) continue;

      String? eventType;
      try {
        eventType = eventTypeMap[int.parse(raw.eventType!)];
      } catch (e) {
        continue;
      }

      if (eventType == null) continue;

      if (!eventTypeForDurationList.contains(eventType)) {
        if (raw.packageName == 'com.twitter.android' || raw.packageName == 'com.pinterest') {
          developer.log('Skipped event for ${raw.packageName}: $eventType');
        }
        continue;
      }

      DateTime eventTime = DateTime.fromMillisecondsSinceEpoch(int.parse(raw.timeStamp!));
      String packageName = raw.packageName!;

      AppEvent event = AppEvent(
        eventType: eventType,
        time: eventTime,
        appName: appNameMap[packageName]!,
        appIconByte: iconCache[packageName],
      );

      eventsByApp.putIfAbsent(packageName, () => []).add(event);
    }

    // Log which apps have events
    developer.log('Apps with processed events:');
    for (var entry in eventsByApp.entries) {
      developer.log('${entry.key} (${appNameMap[entry.key]}): ${entry.value.length} events');
    }

    // Process events into sessions
    List<AppUsageSummary> summaries = [];

    eventsByApp.forEach((packageName, events) {
      events.sort((a, b) => a.time.compareTo(b.time));
      List<AppUsage> sessions = [];

      for (int i = 0; i < events.length; i++) {
        var event = events[i];
        if (_isResumed(event)) {
          int j = i + 1;
          DateTime startTime = event.time;

          while (j < events.length) {
            if (_isPausedOrStopped(events[j])) {
              var endEvent = events[j];
              int durationSeconds = endEvent.time.difference(startTime).inSeconds;
              if (durationSeconds >= minSessionDurationSeconds) {
                sessions.add(AppUsage(
                  appName: event.appName,
                  appIconByte: event.appIconByte,
                  time: startTime,
                  durationInSeconds: durationSeconds,
                ));
              }
              i = j;
              break;
            }
            j++;
          }
        }
      }

      // Merge close sessions
      if (sessions.isNotEmpty) {
        sessions.sort((a, b) => a.time.compareTo(b.time));
        List<AppUsage> mergedSessions = [];
        AppUsage currentSession = sessions[0];

        for (int i = 1; i < sessions.length; i++) {
          AppUsage nextSession = sessions[i];
          DateTime currentEnd = currentSession.time.add(
              Duration(seconds: currentSession.durationInSeconds)
          );

          if (nextSession.time.difference(currentEnd).inMinutes <= sessionMergeThresholdMinutes) {
            int totalDuration = currentSession.durationInSeconds +
                nextSession.durationInSeconds +
                nextSession.time.difference(currentEnd).inSeconds;

            currentSession = AppUsage(
              appName: currentSession.appName,
              appIconByte: currentSession.appIconByte,
              time: currentSession.time,
              durationInSeconds: totalDuration,
            );
          } else {
            mergedSessions.add(currentSession);
            currentSession = nextSession;
          }
        }
        mergedSessions.add(currentSession);

        // Calculate total duration
        int totalDuration = mergedSessions.fold(0, (sum, session) => sum + session.durationInSeconds);

        if (totalDuration >= minSessionDurationSeconds) {
          summaries.add(AppUsageSummary(
            appName: appNameMap[packageName]!,
            packageName: packageName,
            appIcon: iconCache[packageName],
            totalDurationSeconds: totalDuration,
            sessions: mergedSessions,
          ));
        }
      }
    });

    developer.log('Final app summaries: ${summaries.length}');
    for (var summary in summaries) {
      developer.log('${summary.appName}: ${summary.totalDurationText} (${summary.sessions.length} sessions)');
    }

    summaries.sort((a, b) => b.totalDurationSeconds.compareTo(a.totalDurationSeconds));

    return summaries;
  }

  /// Get usage for a specific app by package name for today in seconds
  Future<int> getAppUsageToday(String packageName) async {
    try {
      DateTime now = DateTime.now();
      DateTime startOfDay = DateTime(now.year, now.month, now.day, 0, 0);

      List<AppUsageSummary> summaries = await getUsageForPeriod(startOfDay, now);

      // Find the app in the summaries
      for (var summary in summaries) {
        if (summary.packageName == packageName) {
          return summary.totalDurationSeconds;
        }
      }

      // App not found in summaries, return 0
      return 0;
    } catch (e) {
      developer.log('Error getting app usage: $e');
      return 0;
    }
  }

  /// Get usage for a specific app by package name for today in minutes
  Future<int> getAppUsageTodayMinutes(String packageName) async {
    try {
      int seconds = await getAppUsageToday(packageName);
      return (seconds / 60).ceil(); // Convert to minutes and round up
    } catch (e) {
      developer.log('Error getting app usage in minutes: $e');
      return 0;
    }
  }
}