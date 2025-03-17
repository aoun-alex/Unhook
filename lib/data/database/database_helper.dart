import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../data/models/goal_limit.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'unhook_database.db');
    return await openDatabase(
      path,
      version: 2, // Incrementing version for migration
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE goals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        appName TEXT NOT NULL,
        packageName TEXT NOT NULL UNIQUE,
        appIcon BLOB,
        limitInMinutes INTEGER NOT NULL,
        currentUsage INTEGER NOT NULL,
        category TEXT NOT NULL,
        isLimitReached INTEGER NOT NULL,
        lastCheckTime INTEGER NOT NULL,
        notifiedAt80Percent INTEGER NOT NULL DEFAULT 0,
        notifiedAt95Percent INTEGER NOT NULL DEFAULT 0,
        nextCheckTime INTEGER
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns for monitoring
      await db.execute('ALTER TABLE goals ADD COLUMN lastCheckTime INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE goals ADD COLUMN notifiedAt80Percent INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE goals ADD COLUMN notifiedAt95Percent INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE goals ADD COLUMN nextCheckTime INTEGER');

      // Initialize lastCheckTime to current time for existing goals
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      await db.execute('UPDATE goals SET lastCheckTime = $currentTime');
    }
  }

  // CRUD Operations for GoalLimit

  // Create a new goal
  Future<int> insertGoal(GoalLimit goal) async {
    final db = await database;
    return await db.insert(
      'goals',
      {
        'appName': goal.appName,
        'packageName': goal.packageName,
        'appIcon': goal.appIcon,
        'limitInMinutes': goal.limitInMinutes,
        'currentUsage': goal.currentUsage,
        'category': goal.category,
        'isLimitReached': goal.isLimitReached ? 1 : 0,
        'lastCheckTime': goal.lastCheckTime,
        'notifiedAt80Percent': goal.notifiedAt80Percent ? 1 : 0,
        'notifiedAt95Percent': goal.notifiedAt95Percent ? 1 : 0,
        'nextCheckTime': goal.nextCheckTime,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Read all goals
  Future<List<GoalLimit>> getGoals() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('goals');

    return List.generate(maps.length, (i) {
      return GoalLimit(
        appName: maps[i]['appName'],
        packageName: maps[i]['packageName'],
        appIcon: maps[i]['appIcon'],
        limitInMinutes: maps[i]['limitInMinutes'],
        currentUsage: maps[i]['currentUsage'],
        category: maps[i]['category'],
        isLimitReached: maps[i]['isLimitReached'] == 1,
        lastCheckTime: maps[i]['lastCheckTime'] ?? 0,
        notifiedAt80Percent: maps[i]['notifiedAt80Percent'] == 1,
        notifiedAt95Percent: maps[i]['notifiedAt95Percent'] == 1,
        nextCheckTime: maps[i]['nextCheckTime'],
      );
    });
  }

  // Get goals that need checking
  Future<List<GoalLimit>> getGoalsToCheck() async {
    final db = await database;
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    final List<Map<String, dynamic>> maps = await db.query(
      'goals',
      where: 'nextCheckTime IS NULL OR nextCheckTime <= ?',
      whereArgs: [currentTime],
    );

    return List.generate(maps.length, (i) {
      return GoalLimit(
        appName: maps[i]['appName'],
        packageName: maps[i]['packageName'],
        appIcon: maps[i]['appIcon'],
        limitInMinutes: maps[i]['limitInMinutes'],
        currentUsage: maps[i]['currentUsage'],
        category: maps[i]['category'],
        isLimitReached: maps[i]['isLimitReached'] == 1,
        lastCheckTime: maps[i]['lastCheckTime'] ?? 0,
        notifiedAt80Percent: maps[i]['notifiedAt80Percent'] == 1,
        notifiedAt95Percent: maps[i]['notifiedAt95Percent'] == 1,
        nextCheckTime: maps[i]['nextCheckTime'],
      );
    });
  }

  // Update a goal
  Future<int> updateGoal(GoalLimit goal) async {
    final db = await database;
    return await db.update(
      'goals',
      {
        'appName': goal.appName,
        'appIcon': goal.appIcon,
        'limitInMinutes': goal.limitInMinutes,
        'currentUsage': goal.currentUsage,
        'category': goal.category,
        'isLimitReached': goal.isLimitReached ? 1 : 0,
        'lastCheckTime': goal.lastCheckTime,
        'notifiedAt80Percent': goal.notifiedAt80Percent ? 1 : 0,
        'notifiedAt95Percent': goal.notifiedAt95Percent ? 1 : 0,
        'nextCheckTime': goal.nextCheckTime,
      },
      where: 'packageName = ?',
      whereArgs: [goal.packageName],
    );
  }

  // Delete a goal
  Future<int> deleteGoal(String packageName) async {
    final db = await database;
    return await db.delete(
      'goals',
      where: 'packageName = ?',
      whereArgs: [packageName],
    );
  }

  // Update usage for a specific goal
  Future<int> updateUsage(
      String packageName,
      int currentUsage,
      bool isLimitReached,
      int lastCheckTime,
      bool notifiedAt80Percent,
      bool notifiedAt95Percent,
      int? nextCheckTime,
      ) async {
    final db = await database;
    return await db.update(
      'goals',
      {
        'currentUsage': currentUsage,
        'isLimitReached': isLimitReached ? 1 : 0,
        'lastCheckTime': lastCheckTime,
        'notifiedAt80Percent': notifiedAt80Percent ? 1 : 0,
        'notifiedAt95Percent': notifiedAt95Percent ? 1 : 0,
        'nextCheckTime': nextCheckTime,
      },
      where: 'packageName = ?',
      whereArgs: [packageName],
    );
  }

  // Reset notification flags (e.g., for a new day)
  Future<void> resetNotificationFlags() async {
    final db = await database;
    await db.update(
      'goals',
      {
        'notifiedAt80Percent': 0,
        'notifiedAt95Percent': 0,
        'currentUsage': 0,
        'isLimitReached': 0,
      },
    );
  }
}