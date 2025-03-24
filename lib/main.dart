import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'presentation/screens/main_screen.dart';
import 'data/services/usage_service.dart';
import 'data/services/usage_cache_service.dart';
import 'data/database/database_helper.dart';
import 'data/database/mindful_database_extension.dart'; // Import the extension
import 'providers/goals_provider.dart';
import 'providers/alternatives_provider.dart'; // Import the alternatives provider

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  final dbHelper = DatabaseHelper();
  await dbHelper.database; // This ensures the database is created and migrations run

  // Initialize mindful tables
  await dbHelper.initMindfulTables(); // Initialize the mindful-specific tables

  // Request usage stats permission at start
  final usageService = UsageService();
  await usageService.checkAndRequestPermission();

  // Pre-initialize the cache service (it's a singleton)
  UsageCacheService();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Access the monitoring service to ensure it's initialized
    ref.watch(usageMonitoringServiceProvider);

    // Access the cache service to ensure it's initialized
    ref.watch(usageCacheServiceProvider);

    // Initialize the alternatives service
    ref.watch(alternativesServiceProvider);

    return MaterialApp(
      title: 'Unhook',
      theme: AppTheme.darkTheme,
      home: const MainScreen(),
    );
  }
}