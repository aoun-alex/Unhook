import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'presentation/screens/main_screen.dart';
import 'data/services/usage_service.dart';

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

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unhook',
      theme: AppTheme.darkTheme,
      home: const MainScreen(),
    );
  }
}