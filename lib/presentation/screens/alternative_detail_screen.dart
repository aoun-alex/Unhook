import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_apps/device_apps.dart';
import '../../data/models/alternative_model.dart';
import '../../providers/alternatives_provider.dart';
import '../../providers/pinned_alternatives_provider.dart';
import 'dart:developer' as developer;

// Screen showing detailed information about an alternative
class AlternativeDetailScreen extends ConsumerStatefulWidget {
  // The alternative to display
  final Alternative alternative;

  // The name of the source app this is an alternative for
  final String sourceAppName;

  // The package name of the source app
  final String sourcePackageName;

  const AlternativeDetailScreen({
    Key? key,
    required this.alternative,
    required this.sourceAppName,
    required this.sourcePackageName,
  }) : super(key: key);

  @override
  ConsumerState<AlternativeDetailScreen> createState() => _AlternativeDetailScreenState();
}

class _AlternativeDetailScreenState extends ConsumerState<AlternativeDetailScreen> {
  bool _isPinned = false;
  bool _isCheckingPin = true;
  bool _isLoading = false;
  bool _isAppInstalled = false;

  @override
  void initState() {
    super.initState();
    // Check if this alternative is pinned and if app is installed
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    setState(() {
      _isCheckingPin = true;
    });

    try {
      // Check if this alternative is pinned
      final isPinned = await ref
          .read(alternativeActionsProvider.notifier)
          .isAlternativePinned(widget.alternative.title);

      // If it's an app alternative, check if it's installed
      bool isInstalled = false;
      if (widget.alternative.packageName != null) {
        isInstalled = await DeviceApps.isAppInstalled(widget.alternative.packageName!);
      }

      if (mounted) {
        setState(() {
          _isPinned = isPinned;
          _isAppInstalled = isInstalled;
          _isCheckingPin = false;
        });
      }
    } catch (e) {
      developer.log('Error checking alternative state: $e');
      if (mounted) {
        setState(() {
          _isCheckingPin = false;
        });
      }
    }
  }

  Future<void> _togglePin() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      bool success;
      if (_isPinned) {
        success = await ref
            .read(alternativeActionsProvider.notifier)
            .unpinAlternative(widget.alternative.title);
      } else {
        success = await ref
            .read(alternativeActionsProvider.notifier)
            .pinAlternative(widget.alternative, widget.sourcePackageName);
      }

      if (success && mounted) {
        setState(() {
          _isPinned = !_isPinned;
        });

        // Refresh pinned alternatives
        ref.read(pinnedAlternativesNotifierProvider.notifier).reloadPinnedAlternatives();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openOrInstallApp() async {
    if (widget.alternative.packageName == null) return;

    try {
      if (_isAppInstalled) {
        // Open the app if installed
        await DeviceApps.openApp(widget.alternative.packageName!);
      } else {
        // Show dialog to install the app
        _showInstallPrompt();
      }
    } catch (e) {
      developer.log('Error opening app: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the app'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showInstallPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Install App',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Would you like to install ${widget.alternative.title}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // This would ideally open the Play Store page for the app
              // For now, just show a message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Feature coming soon: Open Play Store'),
                  backgroundColor: Colors.tealAccent,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent,
              foregroundColor: Colors.black,
            ),
            child: const Text('Open Play Store'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine if this is an offline or app alternative
    final isOffline = widget.alternative.isOfflineActivity;
    final categoryText = widget.alternative.category ?? (isOffline ? 'Offline Activity' : 'App Alternative');

    // Determine colors based on alternative type
    final Color primaryColor = isOffline
        ? Colors.tealAccent
        : Colors.blueAccent;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          widget.alternative.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.grey[900],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Pin button in app bar
          _isCheckingPin
              ? const Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.tealAccent,
              ),
            ),
          )
              : IconButton(
            icon: Icon(
              _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: _isPinned ? Colors.tealAccent : Colors.white70,
            ),
            onPressed: _togglePin,
            tooltip: _isPinned ? 'Unpin' : 'Pin',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero section with icon and category
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon in a colored circle
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.alternative.icon,
                      color: primaryColor,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      categoryText,
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Source app info
                  Text(
                    'Alternative for ${widget.sourceAppName}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description section
                  const Text(
                    'Why Try This',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.alternative.description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Benefits section
                  const Text(
                    'Benefits',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildBenefitsList(isOffline),
                  const SizedBox(height: 32),

                  // Getting started section
                  const Text(
                    'Getting Started',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isOffline
                        ? 'Ready to take a break from screens? Here\'s how to get started with this activity:'
                        : 'Ready to try a healthier app alternative? Here\'s how to get started:',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildGettingStartedSteps(isOffline),
                  const SizedBox(height: 32),

                  // Action buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isOffline ? null : _openOrInstallApp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOffline ? Colors.grey[700] : primaryColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey[700],
                        disabledForegroundColor: Colors.white54,
                      ),
                      child: Text(
                        isOffline
                            ? 'Offline Activity'
                            : (_isAppInstalled ? 'Open App' : 'Get App'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _togglePin,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: _isPinned ? Colors.redAccent : primaryColor,
                          width: 1.5,
                        ),
                        foregroundColor: _isPinned ? Colors.redAccent : primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _isPinned ? Colors.redAccent : primaryColor,
                        ),
                      )
                          : Text(
                        _isPinned ? 'Unpin' : 'Pin to Favorites',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds the benefits list based on the type of alternative
  Widget _buildBenefitsList(bool isOffline) {
    final benefits = isOffline
        ? [
      'Reduces screen time and digital dependency',
      'Engages your body and mind in the real world',
      'Improves focus and mindfulness',
      'Creates more meaningful experiences',
    ]
        : [
      'Provides a more mindful digital experience',
      'Reduces addictive scrolling patterns',
      'Helps you use technology more intentionally',
      'Still allows digital engagement but in a healthier way',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: benefits.map((benefit) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.tealAccent,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  benefit,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Builds the getting started steps based on the type of alternative
  Widget _buildGettingStartedSteps(bool isOffline) {
    final steps = isOffline
        ? [
      'Set aside specific time for this activity',
      'Put your phone in Do Not Disturb mode',
      'Start with a small time commitment (15-30 minutes)',
      'Reflect on how you feel afterward compared to scrolling',
    ]
        : [
      'Download the app from your app store',
      'Set up your profile and preferences',
      'Configure notifications to minimize distractions',
      'Try using it as a replacement when you feel the urge to use ${widget.sourceAppName}',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.tealAccent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.tealAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}