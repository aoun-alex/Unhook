import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../models/alternative_model.dart';
import 'database_helper.dart';

// Extension on Database class to add methods for the mindful feature
extension MindfulDatabaseExtension on Database {
  // Creates the pinned_alternatives table if it doesn't exist
  Future<void> createPinnedAlternativesTable() async {
    await execute('''
      CREATE TABLE IF NOT EXISTS pinned_alternatives(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        package_name TEXT,
        is_offline_activity INTEGER NOT NULL,
        icon_code_point INTEGER NOT NULL,
        icon_font_family TEXT,
        icon_font_package TEXT,
        category TEXT,
        source_app_package TEXT NOT NULL,
        pinned_at INTEGER NOT NULL
      )
    ''');
  }

  // Pins an alternative to save it for quick access
  Future<int> pinAlternative({
    required String title,
    required String description,
    String? packageName,
    required bool isOfflineActivity,
    required int iconCodePoint,
    String? iconFontFamily,
    String? iconFontPackage,
    String? category,
    required String sourceAppPackage,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    return await insert(
      'pinned_alternatives',
      {
        'title': title,
        'description': description,
        'package_name': packageName,
        'is_offline_activity': isOfflineActivity ? 1 : 0,
        'icon_code_point': iconCodePoint,
        'icon_font_family': iconFontFamily,
        'icon_font_package': iconFontPackage,
        'category': category,
        'source_app_package': sourceAppPackage,
        'pinned_at': now,
      },
    );
  }

  // Unpins an alternative by title
  Future<int> unpinAlternative(String title) async {
    return await delete(
      'pinned_alternatives',
      where: 'title = ?',
      whereArgs: [title],
    );
  }

  // Checks if an alternative is pinned
  Future<bool> isAlternativePinned(String title) async {
    final result = await query(
      'pinned_alternatives',
      where: 'title = ?',
      whereArgs: [title],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  // Gets all pinned alternatives
  Future<List<Map<String, dynamic>>> getPinnedAlternatives() async {
    return await query(
      'pinned_alternatives',
      orderBy: 'pinned_at DESC',
    );
  }

  // Converts raw database map to Alternative object
  Alternative mapToAlternative(Map<String, dynamic> map) {
    return Alternative(
      title: map['title'],
      description: map['description'],
      packageName: map['package_name'],
      isOfflineActivity: map['is_offline_activity'] == 1,
      icon: IconData(
        map['icon_code_point'],
        fontFamily: map['icon_font_family'],
        fontPackage: map['icon_font_package'],
      ),
      category: map['category'],
    );
  }
}

// Extension to DatabaseHelper to add mindful-specific methods
extension MindfulDatabaseHelperExtension on DatabaseHelper {
  Future<void> initMindfulTables() async {
    final db = await database;
    await db.createPinnedAlternativesTable();
  }

  // Pin an alternative
  Future<int> pinAlternative(Alternative alternative, String sourceAppPackage) async {
    final db = await database;
    return await db.pinAlternative(
      title: alternative.title,
      description: alternative.description,
      packageName: alternative.packageName,
      isOfflineActivity: alternative.isOfflineActivity,
      iconCodePoint: alternative.icon.codePoint,
      iconFontFamily: alternative.icon.fontFamily,
      iconFontPackage: alternative.icon.fontPackage,
      category: alternative.category,
      sourceAppPackage: sourceAppPackage,
    );
  }

  // Unpin an alternative
  Future<int> unpinAlternative(String title) async {
    final db = await database;
    return await db.unpinAlternative(title);
  }

  // Check if an alternative is pinned
  Future<bool> isAlternativePinned(String title) async {
    final db = await database;
    return await db.isAlternativePinned(title);
  }

  // Get all pinned alternatives
  Future<List<Alternative>> getPinnedAlternatives() async {
    final db = await database;
    final maps = await db.getPinnedAlternatives();

    return maps.map((map) => db.mapToAlternative(map)).toList();
  }
}
