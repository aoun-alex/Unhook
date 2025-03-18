import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../data/models/goal_limit.dart';
import '../../data/models/usage_snapshot.dart';

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
      version: 3, // Incrementing version for migration
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

    await db.execute('''
      CREATE TABLE usage_snapshots(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        packageName TEXT NOT NULL,
        usageMinutes INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_usage_snapshots_package_date 
      ON usage_snapshots(packageName, date)
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

    if (oldVersion < 3) {
      // Create usage snapshots table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS usage_snapshots(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          packageName TEXT NOT NULL,
          usageMinutes INTEGER NOT NULL,
          timestamp INTEGER NOT NULL,
          date TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_usage_snapshots_package_date 
        ON usage_snapshots(packageName, date)
      ''');
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

    // Also store a usage snapshot
    storeUsageSnapshot(packageName, currentUsage);

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

  // Store a usage snapshot
  Future<void> storeUsageSnapshot(String packageName, int usageMinutes) async {
    final db = await database;
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    final date = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    await db.insert(
      'usage_snapshots',
      {
        'packageName': packageName,
        'usageMinutes': usageMinutes,
        'timestamp': timestamp,
        'date': date,
      },
    );

    // Cleanup old snapshots - keep only last 7 days
    final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
    final cutoffDateStr = "${cutoffDate.year}-${cutoffDate.month.toString().padLeft(2, '0')}-${cutoffDate.day.toString().padLeft(2, '0')}";

    await db.delete(
      'usage_snapshots',
      where: 'date < ?',
      whereArgs: [cutoffDateStr],
    );
  }

  // Get the latest usage snapshot for a package on a specific date
  Future<UsageSnapshot?> getLatestUsageSnapshot(String packageName, String date) async {
    final db = await database;

    final List<Map<String, dynamic>> result = await db.query(
      'usage_snapshots',
      where: 'packageName = ? AND date = ?',
      whereArgs: [packageName, date],
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return UsageSnapshot(
      packageName: result[0]['packageName'],
      usageMinutes: result[0]['usageMinutes'],
      timestamp: result[0]['timestamp'],
      date: result[0]['date'],
    );
  }

  // Get all usage snapshots for a package on a specific date
  Future<List<UsageSnapshot>> getDailyUsageSnapshots(String packageName, String date) async {
    final db = await database;

    final List<Map<String, dynamic>> result = await db.query(
      'usage_snapshots',
      where: 'packageName = ? AND date = ?',
      whereArgs: [packageName, date],
      orderBy: 'timestamp ASC',
    );

    return result.map((map) => UsageSnapshot(
      packageName: map['packageName'],
      usageMinutes: map['usageMinutes'],
      timestamp: map['timestamp'],
      date: map['date'],
    )).toList();
  }

  // Get usage snapshots for a package for the last n days
  Future<List<UsageSnapshot>> getWeeklyUsageSnapshots(String packageName, int days) async {
    final db = await database;

    // Calculate dates for the last n days
    final dates = List.generate(days, (index) {
      final date = DateTime.now().subtract(Duration(days: index));
      return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    });

    // Query for each date and get the latest snapshot
    List<UsageSnapshot> snapshots = [];

    for (String date in dates) {
      final snapshot = await getLatestUsageSnapshot(packageName, date);
      if (snapshot != null) {
        snapshots.add(snapshot);
      }
    }

    return snapshots;
  }
}