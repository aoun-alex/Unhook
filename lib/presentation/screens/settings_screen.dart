import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_switch_tile.dart';
import '../widgets/settings_navigation_tile.dart';
import '../dialogs/confirm_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Settings state (will be implemented with providers later)
    const isDarkMode = true; // Default to dark mode for now
    const accentColor = Colors.tealAccent; // Default accent color
    const notificationsEnabled = true;
    const defaultTimeLimit = 60; // 60 minutes
    const trackingSensitivity = 'Medium';
    const isLoading = false; // For loading states

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Colors.grey[900],
                  title: const Text(
                    'Settings(not fully implemented',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  automaticallyImplyLeading: false,
                ),

                // Settings content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Notifications Section
                        const SettingsSection(title: 'Notifications'),
                        SettingsSwitchTile(
                          title: 'Enable Notifications',
                          subtitle: 'Get alerts when app time limits are approaching',
                          value: notificationsEnabled,
                          onChanged: (value) {
                            // Will implement with provider
                          },
                        ),
                        SettingsNavigationTile(
                          title: 'Custom Notification Times',
                          subtitle: 'Set when you want to be notified',
                          enabled: notificationsEnabled,
                          onTap: () {
                            // Will navigate to notification settings
                          },
                        ),
                        const SizedBox(height: 16),

                        // Appearance Section
                        const SettingsSection(title: 'Appearance'),
                        SettingsSwitchTile(
                          title: 'Dark Mode',
                          subtitle: 'Use dark theme throughout the app',
                          value: isDarkMode,
                          onChanged: (value) {
                            // Will implement theme switching
                          },
                        ),
                        SettingsNavigationTile(
                          title: 'Accent Color',
                          subtitle: 'Change the app accent color',
                          trailing: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          onTap: () {
                            // Will show color picker
                            _showColorPicker(context);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Data Section
                        const SettingsSection(title: 'Data'),
                        SettingsNavigationTile(
                          title: 'Export Data',
                          subtitle: 'Export your usage data as CSV',
                          icon: Icons.download,
                          onTap: () {
                            // Will implement export functionality
                          },
                        ),
                        SettingsNavigationTile(
                          title: 'Clear All Data',
                          subtitle: 'Reset all app data and preferences',
                          icon: Icons.delete_outline,
                          iconColor: Colors.redAccent,
                          onTap: () {
                            // Show confirmation dialog
                            showDialog(
                              context: context,
                              builder: (context) => ConfirmDialog(
                                title: 'Clear All Data',
                                content: 'This will reset all your data including goals, limits, and preferences. This action cannot be undone.',
                                confirmText: 'Clear Data',
                                confirmColor: Colors.redAccent,
                                onConfirm: () {
                                  // Will implement data clearing
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Time Tracking Preferences Section
                        const SettingsSection(title: 'Time Tracking Preferences'),
                        SettingsNavigationTile(
                          title: 'Default Time Limit',
                          subtitle: '$defaultTimeLimit minutes',
                          onTap: () {
                            // Will show time limit selection
                            _showDefaultTimeLimitDialog(context);
                          },
                        ),
                        SettingsNavigationTile(
                          title: 'Tracking Sensitivity',
                          subtitle: trackingSensitivity,
                          onTap: () {
                            // Will show sensitivity selection
                            _showTrackingSensitivityDialog(context);
                          },
                        ),
                        SettingsNavigationTile(
                          title: 'Auto-Reset Time',
                          subtitle: 'Midnight (00:00)',
                          onTap: () {
                            // Will show time picker
                          },
                        ),
                        const SizedBox(height: 32),

                        // App Info
                        Center(
                          child: Column(
                            children: [
                              const Text(
                                'Unhook',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Version 0.1.0',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(153),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Loading overlay
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.tealAccent),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    // Accent color options
    final colors = [
      Colors.tealAccent,
      Colors.purpleAccent,
      Colors.orangeAccent,
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Choose Accent Color',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: colors.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    // Will implement color change
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors[index],
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDefaultTimeLimitDialog(BuildContext context) {
    // Time limit presets
    final presets = [
      {'label': 'Low (30 minutes)', 'value': 30},
      {'label': 'Medium (60 minutes)', 'value': 60},
      {'label': 'High (90 minutes)', 'value': 90},
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Default Time Limit',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: presets.map((preset) {
              return ListTile(
                title: Text(
                  preset['label'] as String,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  // Will implement time limit change
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showTrackingSensitivityDialog(BuildContext context) {
    // Sensitivity options
    final sensitivities = ['Low', 'Medium', 'High'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Tracking Sensitivity',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: sensitivities.map((sensitivity) {
              return ListTile(
                title: Text(
                  sensitivity,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  _getSensitivityDescription(sensitivity),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  // Will implement sensitivity change
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _getSensitivityDescription(String sensitivity) {
    switch (sensitivity) {
      case 'Low':
        return 'Only count longer app sessions (5+ minutes)';
      case 'Medium':
        return 'Default - Balanced tracking';
      case 'High':
        return 'Track all app usage, even brief sessions';
      default:
        return '';
    }
  }
}