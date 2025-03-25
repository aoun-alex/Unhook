import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_screen.dart';
import 'goals_screen.dart';
import 'mindful_screen.dart';
import 'settings_screen.dart';
import '../../providers/goals_provider.dart';
import '../../providers/settings_provider.dart';
import 'dart:async';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  Timer? _syncTimer;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const GoalsScreen(),
    const MindfulScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Set up periodic sync every 5 minutes
    _syncTimer = Timer.periodic(
        const Duration(minutes: 5),
            (_) => _syncUsage()
    );

    // Initial sync
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncUsage();

      // Also load settings
      ref.read(appSettingsProvider.notifier).loadSettings();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Sync when app is resumed
    if (state == AppLifecycleState.resumed) {
      _syncUsage();
    }
  }

  void _syncUsage() {
    ref.read(activeGoalsProvider.notifier).syncUsage();
  }

  @override
  Widget build(BuildContext context) {
    // Get the accent color from settings
    final accentColor = ref.watch(accentColorProvider);

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.grey[900]!.withAlpha(242),
          indicatorColor: accentColor.withAlpha(76), // Use accent color from settings
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _selectedIndex = index;
            });

            // Sync when switching to goals tab
            if (index == 1) {
              _syncUsage();
            }
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.insights, color: Colors.white70),
              selectedIcon: Icon(Icons.insights, color: accentColor), // Use accent color
              label: 'Insights',
            ),
            NavigationDestination(
              icon: const Icon(Icons.track_changes, color: Colors.white70),
              selectedIcon: Icon(Icons.track_changes, color: accentColor), // Use accent color
              label: 'Goals',
            ),
            NavigationDestination(
              icon: const Icon(Icons.self_improvement, color: Colors.white70),
              selectedIcon: Icon(Icons.self_improvement, color: accentColor), // Use accent color
              label: 'Mindful',
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings, color: Colors.white70),
              selectedIcon: Icon(Icons.settings, color: accentColor), // Use accent color
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}