import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/alternatives_section.dart';
import '../../providers/alternatives_provider.dart';
import '../../providers/pinned_alternatives_provider.dart';
import '../../providers/goals_provider.dart';
import '../../data/models/alternative_model.dart';
import 'alternative_detail_screen.dart';

/// Mindful screen with tabs for alternatives and mindfulness learning
class MindfulScreen extends ConsumerStatefulWidget {
  const MindfulScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MindfulScreen> createState() => _MindfulScreenState();
}

class _MindfulScreenState extends ConsumerState<MindfulScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initial data load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
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
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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

              const SizedBox(height: 24),

              // Tab bar
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.tealAccent,
                labelColor: Colors.tealAccent,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'Alternatives'),
                  Tab(text: 'Mindfulness'),
                ],
              ),

              const SizedBox(height: 16),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAlternativesTab(),
                    _buildMindfulnessTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the alternatives tab with personalized suggestions and pinned alternatives
  Widget _buildAlternativesTab() {
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
            // Description
            Text(
              'Find healthier alternatives to apps you use frequently. These suggestions are personalized based on your usage patterns.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

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

  /// Empty state when no personalized alternatives are available
  Widget _buildEmptyPersonalizedState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[850]!.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.favorite_outline,
            color: Colors.tealAccent.withOpacity(0.5),
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
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Navigate to goals tab
              // We can't use named routes, so we'll use the bottom navigation
              DefaultTabController.of(context).animateTo(1); // Tab index for Goals
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

  /// Placeholder for the mindfulness tab (will be implemented in future)
  Widget _buildMindfulnessTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.self_improvement,
            size: 80,
            color: Colors.tealAccent.withOpacity(0.6),
          ),
          const SizedBox(height: 24),
          const Text(
            'Mindfulness Learning',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Coming soon...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(12),
            ),
            width: MediaQuery.of(context).size.width * 0.8,
            child: Text(
              'We\'re working on mindfulness exercises and digital wellbeing lessons to help you develop healthier technology habits.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Navigate to the alternative detail screen
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