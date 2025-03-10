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
      version: 1,
      onCreate: _onCreate,
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
        isLimitReached INTEGER NOT NULL
      )
    ''');
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
  Future<int> updateUsage(String packageName, int currentUsage, bool isLimitReached) async {
    final db = await database;
    return await db.update(
      'goals',
      {
        'currentUsage': currentUsage,
        'isLimitReached': isLimitReached ? 1 : 0,
      },
      where: 'packageName = ?',
      whereArgs: [packageName],
    );
  }
}