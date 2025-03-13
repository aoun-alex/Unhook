import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/real_time_tracking_provider.dart';
import 'accessibility_permission_screen.dart';

class TrackingTestScreen extends ConsumerStatefulWidget {
  const TrackingTestScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TrackingTestScreen> createState() => _TrackingTestScreenState();
}

class _TrackingTestScreenState extends ConsumerState<TrackingTestScreen> {
  final List<AppLaunchEvent> _events = [];
  final int _maxEvents = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAccessibilityPermission();
    });
  }

  void _checkAccessibilityPermission() async {
    final isEnabled = await ref.read(realTimeTrackingServiceProvider).isAccessibilityServiceEnabled();
    if (!isEnabled && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AccessibilityPermissionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to app launch events
    ref.listen<AsyncValue<String>>(
      appLaunchStreamProvider,
          (previous, next) {
        next.whenData((packageName) {
          if (packageName.isNotEmpty) {
            setState(() {
              _events.insert(
                0,
                AppLaunchEvent(
                  packageName: packageName,
                  timestamp: DateTime.now(),
                ),
              );

              // Limit the number of events
              if (_events.length > _maxEvents) {
                _events.removeLast();
              }
            });
          }
        });
      },
    );

    // Get the current status of the accessibility service
    final accessibilityEnabled = ref.watch(accessibilityServiceEnabledProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Real-Time Tracking Test'),
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_accessibility),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AccessibilityPermissionScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: accessibilityEnabled.when(
              data: (enabled) {
                return Card(
                  color: enabled ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          enabled ? Icons.check_circle : Icons.error,
                          color: enabled ? Colors.greenAccent : Colors.redAccent,
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                enabled
                                    ? 'Real-time tracking active'
                                    : 'Real-time tracking not available',
                                style: TextStyle(
                                  color: enabled ? Colors.greenAccent : Colors.redAccent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                enabled
                                    ? 'Accessibility service is enabled and tracking app launches.'
                                    : 'Enable the accessibility service for real-time tracking.',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.tealAccent),
                  ),
                ),
              ),
              error: (_, __) => const Card(
                color: Colors.redAccent,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Error checking accessibility status',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),

          // Events List Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Icon(Icons.history, color: Colors.tealAccent),
                SizedBox(width: 8),
                Text(
                  'Recent App Launches',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Events List
          Expanded(
            child: _events.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.hourglass_empty,
                    size: 64,
                    color: Colors.tealAccent.withAlpha(100),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No app launches detected yet',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Switch to different apps to see events',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _events.length,
              itemBuilder: (context, index) {
                final event = _events[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.withOpacity(0.2),
                    child: const Icon(Icons.apps, color: Colors.tealAccent),
                  ),
                  title: Text(
                    _formatPackageName(event.packageName),
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    DateFormat('HH:mm:ss').format(event.timestamp),
                    style: const TextStyle(color: Colors.white60),
                  ),
                  trailing: Text(
                    _getTimeDifference(event.timestamp),
                    style: const TextStyle(color: Colors.tealAccent),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Format package name to be more readable
  String _formatPackageName(String packageName) {
    // Extract the app name from the package name
    final parts = packageName.split('.');
    if (parts.length > 1) {
      return parts.last.replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
            (match) => '${match.group(1)} ${match.group(2)}',
      ).capitalize();
    }
    return packageName;
  }

  // Get relative time string
  String _getTimeDifference(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
}

// Extension to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

// Simple class to store app launch events
class AppLaunchEvent {
  final String packageName;
  final DateTime timestamp;

  AppLaunchEvent({
    required this.packageName,
    required this.timestamp,
  });
}