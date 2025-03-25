import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import 'database_helper.dart';

class SettingsDatabaseHelper {
  static final SettingsDatabaseHelper _instance = SettingsDatabaseHelper._internal();

  factory SettingsDatabaseHelper() => _instance;

  SettingsDatabaseHelper._internal();

  // Get database from the main DatabaseHelper
  Future<Database> get database async {
    return await DatabaseHelper().database;
  }

  // Initialize settings table
  Future<void> initSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT NOT NULL UNIQUE,
        value TEXT NOT NULL
      )
    ''');

    // Initialize with default settings if table is empty
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM app_settings'));
    if (count == 0) {
      await initializeDefaultSettings(db);
    }
  }

  // Initialize default settings
  Future<void> initializeDefaultSettings(Database db) async {
    final defaultSettings = [
      {'key': 'dark_mode', 'value': 'true'},
      {'key': 'accent_color', 'value': 'teal'},
      {'key': 'notifications_enabled', 'value': 'true'},
      {'key': 'default_time_limit', 'value': '60'}, // 60 minutes
      {'key': 'tracking_sensitivity', 'value': 'medium'},
      {'key': 'auto_reset_time', 'value': '00:00'}, // Midnight
      {'key': 'custom_notification_times', 'value': '75,90,100'}, // Percentage of limit: 75%, 90%, 100%
    ];

    final batch = db.batch();
    for (final setting in defaultSettings) {
      batch.insert('app_settings', setting, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit();
  }

  // Get all settings
  Future<AppSettings> getSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('app_settings');

    // Convert to key-value map
    final Map<String, String> settingsMap = {};
    for (final map in maps) {
      settingsMap[map['key'] as String] = map['value'] as String;
    }

    // Create AppSettings object from the map
    return AppSettings.fromMap(settingsMap);
  }

  // Update a single setting
  Future<void> updateSetting(String key, String value) async {
    final db = await database;
    await db.update(
      'app_settings',
      {'value': value},
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  // Get a single setting value
  Future<String?> getSetting(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );

    if (result.isNotEmpty) {
      return result.first['value'] as String;
    }
    return null;
  }

  // Toggle boolean setting
  Future<bool> toggleBoolSetting(String key) async {
    final currentValue = await getSetting(key);
    final newValue = (currentValue != 'true').toString();
    await updateSetting(key, newValue);
    return newValue == 'true';
  }

  // Get color from string
  static Color getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'teal':
        return Colors.tealAccent;
      case 'purple':
        return Colors.purpleAccent;
      case 'orange':
        return Colors.orangeAccent;
      default:
        return Colors.tealAccent;
    }
  }

  // Get string from color
  static String getStringFromColor(Color color) {
    if (color == Colors.tealAccent) return 'teal';
    if (color == Colors.purpleAccent) return 'purple';
    if (color == Colors.orangeAccent) return 'orange';
    return 'teal';
  }
}