import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'goals_screen.dart';
import 'placeholder_screens.dart';  // This contains MindfulScreen and SettingsScreen

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const GoalsScreen(),
    const MindfulScreen(),    // From placeholder_screens.dart
    const SettingsScreen(),    // From placeholder_screens.dart
  ];

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
              label: 'Mindful',
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