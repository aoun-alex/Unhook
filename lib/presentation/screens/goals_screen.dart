import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/app_limit_card.dart';
import '../widgets/goal_template_card.dart';
import '../widgets/streak_indicator.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show dialog to add new app limit
          _showAddLimitDialog();
        },
        backgroundColor: Colors.tealAccent,
        child: const Icon(Icons.add, color: Color(0xFF121212)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Goals',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Streak indicator
              const StreakIndicator(currentStreak: 5),
              const SizedBox(height: 24),

              // Tab bar for different categories
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.tealAccent,
                labelColor: Colors.tealAccent,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'Active'),
                  Tab(text: 'Templates'),
                  Tab(text: 'Completed'),
                ],
              ),
              const SizedBox(height: 16),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildActiveLimitsTab(),

                    _buildTemplatesTab(),

                    _buildCompletedTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveLimitsTab() {
    return ListView(
      children: const [
        AppLimitCard(
          appName: 'Instagram',
          appIcon: Icons.camera_alt,
          iconColor: Colors.pink,
          currentUsage: 45,
          limitInMinutes: 60,
          category: 'Social',
        ),
        SizedBox(height: 12),
        AppLimitCard(
          appName: 'YouTube',
          appIcon: Icons.play_arrow,
          iconColor: Colors.red,
          currentUsage: 85,
          limitInMinutes: 90,
          category: 'Entertainment',
        ),
        SizedBox(height: 12),
        AppLimitCard(
          appName: 'Twitter',
          appIcon: Icons.chat,
          iconColor: Colors.lightBlue,
          currentUsage: 30,
          limitInMinutes: 30,
          category: 'Social',
          isLimitReached: true,
        ),
        SizedBox(height: 12),
        AppLimitCard(
          appName: 'TikTok',
          appIcon: Icons.music_note,
          iconColor: Colors.purpleAccent,
          currentUsage: 15,
          limitInMinutes: 45,
          category: 'Entertainment',
        ),
      ],
    );
  }

  Widget _buildTemplatesTab() {
    return ListView(
      children: const [
        GoalTemplateCard(
          title: 'Digital Detox',
          description: 'Limit social media apps to 30 minutes per day',
          icon: Icons.spa,
          apps: ['Instagram', 'Twitter', 'Facebook', 'TikTok'],
        ),
        SizedBox(height: 12),
        GoalTemplateCard(
          title: 'Focus Mode',
          description: 'Block distracting apps during work hours',
          icon: Icons.work,
          apps: ['YouTube', 'Netflix', 'Games'],
        ),
        SizedBox(height: 12),
        GoalTemplateCard(
          title: 'Sleep Better',
          description: 'No screen time 1 hour before bed',
          icon: Icons.nightlight_round,
          apps: ['All apps'],
        ),
      ],
    );
  }

  Widget _buildCompletedTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events,
            size: 64,
            color: Colors.tealAccent.withAlpha(128),
          ),
          const SizedBox(height: 16),
          const Text(
            'Completed goals will appear here',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddLimitDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add New App Limit',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Select App',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text('Choose an app', style: TextStyle(color: Colors.white70)),
                    dropdownColor: const Color(0xFF2A2A2A),
                    items: const [], //TODO: Add app list
                    onChanged: null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Daily Time Limit',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const TextField(
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Minutes',
                          hintStyle: TextStyle(color: Colors.white38),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Set Limit'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}