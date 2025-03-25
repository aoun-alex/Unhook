import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../data/models/goal_limit.dart';
import '../../data/models/usage_snapshot.dart';
import '../../data/models/streak_record.dart';
import 'settings_database_helper.dart';

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
      version: 5,
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

    // Create streak_data table
    await db.execute('''
      CREATE TABLE streak_data(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        currentStreak INTEGER NOT NULL DEFAULT 0,
        longestStreak INTEGER NOT NULL DEFAULT 0,
        lastStreakDate TEXT,
        lastCheckDate TEXT
      )
    ''');

    // Create daily_records table to track streak history
    await db.execute('''
      CREATE TABLE daily_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        streakDay INTEGER NOT NULL DEFAULT 0,
        allLimitsRespected INTEGER NOT NULL DEFAULT 1,
        timestamp INTEGER NOT NULL
      )
    ''');

    // Initialize streak data with a single row
    await db.insert('streak_data', {
      'currentStreak': 0,
      'longestStreak': 0,
      'lastStreakDate': null,
      'lastCheckDate': null,
    });

    await SettingsDatabaseHelper().initSettingsTable(db);
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

    if (oldVersion < 4) {
      // Add streak-related tables
      await db.execute('''
        CREATE TABLE IF NOT EXISTS streak_data(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          currentStreak INTEGER NOT NULL DEFAULT 0,
          longestStreak INTEGER NOT NULL DEFAULT 0,
          lastStreakDate TEXT,
          lastCheckDate TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS daily_records(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL UNIQUE,
          streakDay INTEGER NOT NULL DEFAULT 0,
          allLimitsRespected INTEGER NOT NULL DEFAULT 1,
          timestamp INTEGER NOT NULL
        )
      ''');

      // Initialize streak data with a single row
      final existingData = await db.query('streak_data');
      if (existingData.isEmpty) {
        await db.insert('streak_data', {
          'currentStreak': 0,
          'longestStreak': 0,
          'lastStreakDate': null,
          'lastCheckDate': null,
        });
      }
    }

    if (oldVersion < 5) {
      // Add settings table
      await SettingsDatabaseHelper().initSettingsTable(db);
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

  // Streak-related methods

  // Get current streak data
  Future<Map<String, dynamic>> getStreakData() async {
    final db = await database;
    final result = await db.query('streak_data');

    if (result.isEmpty) {
      // Initialize if not exists
      final id = await db.insert('streak_data', {
        'currentStreak': 0,
        'longestStreak': 0,
        'lastStreakDate': null,
        'lastCheckDate': null,
      });
      return {
        'id': id,
        'currentStreak': 0,
        'longestStreak': 0,
        'lastStreakDate': null,
        'lastCheckDate': null,
      };
    }

    return result.first;
  }

  // Update streak data
  Future<void> updateStreakData(int currentStreak, int longestStreak, String? lastStreakDate, String lastCheckDate) async {
    final db = await database;
    await db.update(
      'streak_data',
      {
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastStreakDate': lastStreakDate,
        'lastCheckDate': lastCheckDate,
      },
      where: 'id = 1',
    );
  }

  // Record a daily streak status
  Future<void> recordDailyStreak(String date, bool allLimitsRespected, int streakDay) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Use INSERT OR REPLACE to handle the UNIQUE constraint on date
    await db.insert(
      'daily_records',
      {
        'date': date,
        'streakDay': streakDay,
        'allLimitsRespected': allLimitsRespected ? 1 : 0,
        'timestamp': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all daily records for a date range
  Future<List<StreakRecord>> getDailyRecords(DateTime startDate, DateTime endDate) async {
    final db = await database;

    final startDateStr = "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
    final endDateStr = "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";

    final result = await db.query(
      'daily_records',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDateStr, endDateStr],
      orderBy: 'date ASC',
    );

    return result.map((record) => StreakRecord(
      date: record['date'] as String,
      streakDay: record['streakDay'] as int,
      allLimitsRespected: record['allLimitsRespected'] == 1,
      timestamp: record['timestamp'] as int,
    )).toList();
  }

  // Get a specific daily record
  Future<StreakRecord?> getDailyRecord(String date) async {
    final db = await database;

    final result = await db.query(
      'daily_records',
      where: 'date = ?',
      whereArgs: [date],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return StreakRecord(
      date: result[0]['date'] as String,
      streakDay: result[0]['streakDay'] as int,
      allLimitsRespected: result[0]['allLimitsRespected'] == 1,
      timestamp: result[0]['timestamp'] as int,
    );
  }

  // Check if any limit was exceeded for a specific date
  Future<bool> wasAnyLimitExceededOnDate(String date) async {
    final db = await database;

    // Check if there's a record for this date
    final record = await getDailyRecord(date);
    if (record != null) {
      // Return the stored value
      return !record.allLimitsRespected;
    }

    // If no record exists, use the usage snapshots to determine
    final goals = await getGoals();

    for (final goal in goals) {
      final snapshot = await getLatestUsageSnapshot(goal.packageName, date);
      if (snapshot != null && snapshot.usageMinutes > goal.limitInMinutes) {
        return true; // At least one limit was exceeded
      }
    }

    return false; // No limits were exceeded
  }
}