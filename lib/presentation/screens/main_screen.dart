import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_screen.dart';
import 'goals_screen.dart';
import 'placeholder_screens.dart';
import 'tracking_test_screen.dart';
import '../../providers/goals_provider.dart';
import '../../providers/real_time_tracking_provider.dart';
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
    const TrackingTestScreen(), // New tracking test screen
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize real-time tracking
    ref.read(realTimeTrackingServiceProvider);

    // Set up periodic sync every 5 minutes
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _syncUsage();
    });

    // Initial sync
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncUsage();
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
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.grey[900]!.withAlpha(242),
          indicatorColor: Colors.tealAccent.withAlpha(76),
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
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.insights, color: Colors.white70),
              selectedIcon: Icon(Icons.insights, color: Colors.tealAccent),
              label: 'Insights',
            ),
            NavigationDestination(
              icon: Icon(Icons.track_changes, color: Colors.white70),
              selectedIcon: Icon(Icons.track_changes, color: Colors.tealAccent),
              label: 'Goals',
            ),
            NavigationDestination(
              icon: Icon(Icons.psychology, color: Colors.white70),
              selectedIcon: Icon(Icons.psychology, color: Colors.tealAccent),
              label: 'Real-time',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings, color: Colors.white70),
              selectedIcon: Icon(Icons.settings, color: Colors.tealAccent),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}