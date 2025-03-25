import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/settings_database_helper.dart';
import '../data/models/app_settings.dart';

// Provider for settings database helper
final settingsDatabaseHelperProvider = Provider<SettingsDatabaseHelper>((ref) {
  return SettingsDatabaseHelper();
});

// Provider for loading state
final settingsLoadingProvider = StateProvider<bool>((ref) => false);

// Provider for app settings
final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AsyncValue<AppSettings>>((ref) {
  final settingsDb = ref.watch(settingsDatabaseHelperProvider);
  return AppSettingsNotifier(settingsDb, ref);
});

// Notifier for app settings
class AppSettingsNotifier extends StateNotifier<AsyncValue<AppSettings>> {
  final SettingsDatabaseHelper _settingsDb;
  final Ref _ref;

  AppSettingsNotifier(this._settingsDb, this._ref) : super(const AsyncValue.loading()) {
    // Load settings on initialization
    loadSettings();
  }

  // Load all settings from database
  Future<void> loadSettings() async {
    _setLoading(true);

    try {
      final settings = await _settingsDb.getSettings();
      state = AsyncValue.data(settings);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    } finally {
      _setLoading(false);
    }
  }

  // Update a specific setting
  Future<void> updateSetting({
    bool? darkMode,
    Color? accentColor,
    bool? notificationsEnabled,
    int? defaultTimeLimit,
    String? trackingSensitivity,
    String? autoResetTime,
    List<int>? customNotificationTimes,
  }) async {
    _setLoading(true);

    try {
      // Get current settings
      final currentSettings = state.value!;

      // Create updated settings
      final updatedSettings = currentSettings.copyWith(
        darkMode: darkMode,
        accentColor: accentColor,
        notificationsEnabled: notificationsEnabled,
        defaultTimeLimit: defaultTimeLimit,
        trackingSensitivity: trackingSensitivity,
        autoResetTime: autoResetTime,
        customNotificationTimes: customNotificationTimes,
      );

      // Update settings in database
      final updatedMap = updatedSettings.toMap();
      for (final entry in updatedMap.entries) {
        if (darkMode != null && entry.key == 'dark_mode') {
          await _settingsDb.updateSetting(entry.key, entry.value);
        } else if (accentColor != null && entry.key == 'accent_color') {
          await _settingsDb.updateSetting(entry.key, entry.value);
        } else if (notificationsEnabled != null && entry.key == 'notifications_enabled') {
          await _settingsDb.updateSetting(entry.key, entry.value);
        } else if (defaultTimeLimit != null && entry.key == 'default_time_limit') {
          await _settingsDb.updateSetting(entry.key, entry.value);
        } else if (trackingSensitivity != null && entry.key == 'tracking_sensitivity') {
          await _settingsDb.updateSetting(entry.key, entry.value);
        } else if (autoResetTime != null && entry.key == 'auto_reset_time') {
          await _settingsDb.updateSetting(entry.key, entry.value);
        } else if (customNotificationTimes != null && entry.key == 'custom_notification_times') {
          await _settingsDb.updateSetting(entry.key, entry.value);
        }
      }

      // Update state
      state = AsyncValue.data(updatedSettings);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    } finally {
      _setLoading(false);
    }
  }

  // Toggle dark mode
  Future<void> toggleDarkMode() async {
    if (state.hasValue) {
      final currentDarkMode = state.value!.darkMode;
      await updateSetting(darkMode: !currentDarkMode);
    }
  }

  // Toggle notifications
  Future<void> toggleNotifications() async {
    if (state.hasValue) {
      final currentNotifications = state.value!.notificationsEnabled;
      await updateSetting(notificationsEnabled: !currentNotifications);
    }
  }

  // Set accent color
  Future<void> setAccentColor(Color color) async {
    await updateSetting(accentColor: color);
  }

  // Set default time limit
  Future<void> setDefaultTimeLimit(int minutes) async {
    await updateSetting(defaultTimeLimit: minutes);
  }

  // Set tracking sensitivity
  Future<void> setTrackingSensitivity(String sensitivity) async {
    await updateSetting(trackingSensitivity: sensitivity);
  }

  // Set auto-reset time
  Future<void> setAutoResetTime(String time) async {
    await updateSetting(autoResetTime: time);
  }

  // Set custom notification times
  Future<void> setCustomNotificationTimes(List<int> times) async {
    await updateSetting(customNotificationTimes: times);
  }

  // Clear all data (reset to defaults)
  Future<void> clearAllData() async {
    _setLoading(true);

    try {
      // Re-initialize database with default settings
      final db = await _settingsDb.database;
      await _settingsDb.initializeDefaultSettings(db);

      // Reload settings
      await loadSettings();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    } finally {
      _setLoading(false);
    }
  }

  // Helper method to set loading state
  void _setLoading(bool isLoading) {
    _ref.read(settingsLoadingProvider.notifier).state = isLoading;
  }
}

// Convenience providers for individual settings
final isDarkModeProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(appSettingsProvider);
  return settingsAsync.when(
    data: (settings) => settings.darkMode,
    loading: () => true, // Default to dark mode during loading
    error: (_, __) => true, // Default to dark mode on error
  );
});

final accentColorProvider = Provider<Color>((ref) {
  final settingsAsync = ref.watch(appSettingsProvider);
  return settingsAsync.when(
    data: (settings) => settings.accentColor,
    loading: () => Colors.tealAccent, // Default accent color during loading
    error: (_, __) => Colors.tealAccent, // Default accent color on error
  );
});

final notificationsEnabledProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(appSettingsProvider);
  return settingsAsync.when(
    data: (settings) => settings.notificationsEnabled,
    loading: () => true, // Default to enabled during loading
    error: (_, __) => true, // Default to enabled on error
  );
});

final defaultTimeLimitProvider = Provider<int>((ref) {
  final settingsAsync = ref.watch(appSettingsProvider);
  return settingsAsync.when(
    data: (settings) => settings.defaultTimeLimit,
    loading: () => 60, // Default 60 minutes during loading
    error: (_, __) => 60, // Default 60 minutes on error
  );
});

final trackingSensitivityProvider = Provider<String>((ref) {
  final settingsAsync = ref.watch(appSettingsProvider);
  return settingsAsync.when(
    data: (settings) => settings.trackingSensitivity,
    loading: () => 'medium', // Default medium during loading
    error: (_, __) => 'medium', // Default medium on error
  );
});

final autoResetTimeProvider = Provider<String>((ref) {
  final settingsAsync = ref.watch(appSettingsProvider);
  return settingsAsync.when(
    data: (settings) => settings.autoResetTime,
    loading: () => '00:00', // Default midnight during loading
    error: (_, __) => '00:00', // Default midnight on error
  );
});

final customNotificationTimesProvider = Provider<List<int>>((ref) {
  final settingsAsync = ref.watch(appSettingsProvider);
  return settingsAsync.when(
    data: (settings) => settings.customNotificationTimes,
    loading: () => [75, 90, 100], // Default notification times during loading
    error: (_, __) => [75, 90, 100], // Default notification times on error
  );
});