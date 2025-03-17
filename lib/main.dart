import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'presentation/screens/main_screen.dart';
import 'data/services/usage_service.dart';
import 'providers/goals_provider.dart'; // This will initialize the monitoring service

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request usage stats permission at start
  final usageService = UsageService();
  await usageService.checkAndRequestPermission();

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

    return MaterialApp(
      title: 'Unhook',
      theme: AppTheme.darkTheme,
      home: const MainScreen(),
    );
  }
}