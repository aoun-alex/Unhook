import 'package:flutter/material.dart';
import '../database/settings_database_helper.dart';

class AppSettings {
  final bool darkMode;
  final Color accentColor;
  final bool notificationsEnabled;
  final int defaultTimeLimit;
  final String trackingSensitivity;
  final String autoResetTime;
  final List<int> customNotificationTimes;

  AppSettings({
    this.darkMode = true,
    this.accentColor = Colors.tealAccent,
    this.notificationsEnabled = true,
    this.defaultTimeLimit = 60,
    this.trackingSensitivity = 'medium',
    this.autoResetTime = '00:00',
    this.customNotificationTimes = const [75, 90, 100],
  });

  // Create a copy with some fields updated
  AppSettings copyWith({
    bool? darkMode,
    Color? accentColor,
    bool? notificationsEnabled,
    int? defaultTimeLimit,
    String? trackingSensitivity,
    String? autoResetTime,
    List<int>? customNotificationTimes,
  }) {
    return AppSettings(
      darkMode: darkMode ?? this.darkMode,
      accentColor: accentColor ?? this.accentColor,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      defaultTimeLimit: defaultTimeLimit ?? this.defaultTimeLimit,
      trackingSensitivity: trackingSensitivity ?? this.trackingSensitivity,
      autoResetTime: autoResetTime ?? this.autoResetTime,
      customNotificationTimes: customNotificationTimes ?? this.customNotificationTimes,
    );
  }

  // Convert from database map
  factory AppSettings.fromMap(Map<String, String> map) {
    // Parse notification times from comma separated string
    List<int> notificationTimes = const [75, 90, 100]; // Default
    if (map.containsKey('custom_notification_times')) {
      try {
        notificationTimes = map['custom_notification_times']!
            .split(',')
            .map((e) => int.parse(e))
            .toList();
      } catch (_) {
        // Use defaults on error
      }
    }

    // Parse color from string
    Color accentColor = Colors.tealAccent; // Default
    if (map.containsKey('accent_color')) {
      accentColor = SettingsDatabaseHelper.getColorFromString(map['accent_color']!);
    }

    return AppSettings(
      darkMode: map['dark_mode'] == 'true',
      accentColor: accentColor,
      notificationsEnabled: map['notifications_enabled'] == 'true',
      defaultTimeLimit: int.tryParse(map['default_time_limit'] ?? '60') ?? 60,
      trackingSensitivity: map['tracking_sensitivity'] ?? 'medium',
      autoResetTime: map['auto_reset_time'] ?? '00:00',
      customNotificationTimes: notificationTimes,
    );
  }

  // Convert to map for database storage
  Map<String, String> toMap() {
    return {
      'dark_mode': darkMode.toString(),
      'accent_color': SettingsDatabaseHelper.getStringFromColor(accentColor),
      'notifications_enabled': notificationsEnabled.toString(),
      'default_time_limit': defaultTimeLimit.toString(),
      'tracking_sensitivity': trackingSensitivity,
      'auto_reset_time': autoResetTime,
      'custom_notification_times': customNotificationTimes.join(','),
    };
  }
}