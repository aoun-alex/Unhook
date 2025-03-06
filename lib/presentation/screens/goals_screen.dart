import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/app_limit_card.dart';
import '../widgets/streak_indicator.dart';
import '../widgets/minutes_slider.dart';
import '../../providers/goals_provider.dart';
import '../dialogs/app_selection_dialog.dart';
import '../../data/models/goal_limit.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _limitInMinutes = 60; // Default limit of 60 minutes (1 hour)
  String _selectedCategory = 'Social'; // Default category

  final List<String> _categories = [
    'Social',
    'Entertainment',
    'Communication',
    'Productivity',
    'Gaming',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goals = ref.watch(activeGoalsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show app selection dialog
          _showAppSelectionDialog();
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
                  Tab(text: 'Completed'),
                ],
              ),
              const SizedBox(height: 16),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildActiveLimitsTab(goals),
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

  Widget _buildActiveLimitsTab(List<GoalLimit> goals) {
    if (goals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.app_shortcut_outlined,
              size: 64,
              color: Colors.tealAccent.withAlpha(128),
            ),
            const SizedBox(height: 16),
            const Text(
              'No app limits set yet',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the + button to add one',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: goals.length,
      itemBuilder: (context, index) {
        final goal = goals[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppLimitCard(
            appName: goal.appName,
            appIcon: goal.appIcon,
            packageName: goal.packageName,
            currentUsage: goal.currentUsage,
            limitInMinutes: goal.limitInMinutes,
            category: goal.category,
            isLimitReached: goal.isLimitReached,
          ),
        );
      },
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

  // Show app selection dialog
  void _showAppSelectionDialog() async {
    final selectedApp = await showDialog(
      context: context,
      builder: (context) => const AppSelectionDialog(),
    );

    if (selectedApp != null) {
      // User selected an app, now show the limit setting dialog
      if (mounted) {
        _showTimeLimitDialog(selectedApp);
      }
    }
  }

  // Show time limit dialog after app selection
  void _showTimeLimitDialog(selectedApp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // This allows the sheet to take more space
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 24.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        if (selectedApp.appIcon != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Image.memory(selectedApp.appIcon!, width: 32, height: 32),
                          ),
                        Expanded(
                          child: Text(
                            'Set limit for ${selectedApp.appName}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Daily Time Limit',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.tealAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '$_limitInMinutes min',
                            style: const TextStyle(
                              color: Colors.tealAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180, // Slightly reduced height
                      child: MinutesSlider(
                        initialValue: _limitInMinutes,
                        onChanged: (value) {
                          setState(() {
                            _limitInMinutes = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Category',
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
                          value: _selectedCategory,
                          dropdownColor: const Color(0xFF2A2A2A),
                          style: const TextStyle(color: Colors.white),
                          items: _categories.map((category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value!;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Save the new goal
                          ref.read(activeGoalsProvider.notifier).addGoal(
                            appName: selectedApp.appName,
                            packageName: selectedApp.packageName,
                            appIcon: selectedApp.appIcon,
                            limitInMinutes: _limitInMinutes,
                            category: _selectedCategory,
                          );
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
              ),
            );
          },
        );
      },
    );
  }
}