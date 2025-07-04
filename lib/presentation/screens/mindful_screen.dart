import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/alternatives_section.dart';
import '../../providers/alternatives_provider.dart';
import '../../providers/pinned_alternatives_provider.dart';
import '../../providers/goals_provider.dart';
import '../../data/models/alternative_model.dart';
import 'alternative_detail_screen.dart';

// Mindful screen showing only alternatives (no mindfulness tab)
class MindfulScreen extends ConsumerStatefulWidget {
  const MindfulScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MindfulScreen> createState() => _MindfulScreenState();
}

class _MindfulScreenState extends ConsumerState<MindfulScreen> {
  bool _isLoading = false;
  bool _isInitialized = false;

  Future<void> _refreshData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Refresh goals to ensure we have the latest usage data
      await ref.read(activeGoalsProvider.notifier).syncUsage();

      // Refresh pinned alternatives
      await ref.read(pinnedAlternativesNotifierProvider.notifier).reloadPinnedAlternatives();

      // Refresh personalized alternatives
      ref.refresh(personalizedAlternativesProvider).value;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Load data only once when the screen is first built
    if (!_isInitialized && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshData();
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mindful Alternatives',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.tealAccent,
                      ),
                    )
                        : const Icon(Icons.refresh, color: Colors.tealAccent),
                    onPressed: _isLoading ? null : _refreshData,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Description
              Text(
                'Find healthier alternatives to apps you use frequently. These suggestions are personalized based on your usage patterns.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 24),

              // Content - Direct alternatives without tabs
              Expanded(
                child: _buildAlternativesContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Builds the alternatives content directly (no tabs)
  Widget _buildAlternativesContent() {
    final personalizedAlternativesAsync = ref.watch(personalizedAlternativesProvider);
    final offlineAlternatives = ref.watch(offlineAlternativesProvider);

    return RefreshIndicator(
      color: Colors.tealAccent,
      backgroundColor: Colors.grey[850],
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pinned alternatives section
            const PinnedAlternativesSection(),
            const SizedBox(height: 32),

            // For You section - personalized alternatives
            personalizedAlternativesAsync.when(
              data: (alternatives) {
                if (alternatives.isEmpty) {
                  return _buildEmptyPersonalizedState();
                }

                return AlternativesSection(
                  title: 'For You',
                  alternatives: alternatives,
                  showSourceApps: true,
                  icon: Icons.favorite,
                  description: 'Personalized recommendations based on your usage patterns.',
                  onAlternativeTap: (alternativeData) {
                    _navigateToDetailScreen(alternativeData);
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: Colors.tealAccent),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error loading alternatives: $error',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Offline activities section
            AlternativesSection(
              title: 'Offline Activities',
              alternatives: offlineAlternatives,
              showSourceApps: true,
              icon: Icons.nature_people,
              description: 'Try these real-world activities instead of digital scrolling.',
              onAlternativeTap: (alternativeData) {
                _navigateToDetailScreen(alternativeData);
              },
            ),

            const SizedBox(height: 100), // Bottom padding for scrolling
          ],
        ),
      ),
    );
  }

  // Empty state when no personalized alternatives are available
  Widget _buildEmptyPersonalizedState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[850]!.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.favorite_outline,
            color: Colors.tealAccent.withValues(alpha: 0.5),
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Personalized Alternatives Yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Set up goals for apps you want to spend less time on to get personalized alternatives.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Navigate to goals tab
              // We're using a more reliable method to navigate to the Goals tab
              final scaffoldContext = ScaffoldMessenger.of(context).context;
              Navigator.popUntil(scaffoldContext, (route) => route.isFirst);

              // This will use navigateToTabIndex from parent if it exists
              // or simply show a message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Go to the Goals tab to set up app limits'),
                  backgroundColor: Colors.tealAccent,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Set Up App Goals'),
          ),
        ],
      ),
    );
  }

  // Navigate to the alternative detail screen
  void _navigateToDetailScreen(Map<String, dynamic> alternativeData) {
    final alternative = alternativeData['alternative'] as Alternative;
    final sourceAppName = alternativeData['appName'] as String;
    final sourcePackageName = alternativeData['packageName'] as String;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlternativeDetailScreen(
          alternative: alternative,
          sourceAppName: sourceAppName,
          sourcePackageName: sourcePackageName,
        ),
      ),
    );
  }
}