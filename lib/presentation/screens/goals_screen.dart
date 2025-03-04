import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/app_limit_card.dart';
import '../widgets/streak_indicator.dart';
import '../../providers/goals_provider.dart';

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
    _tabController = TabController(length: 2, vsync: this);
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
    final activeGoalsAsync = ref.watch(activeGoalsProvider);

    return activeGoalsAsync.when(
      data: (goals) {
        if (goals.isEmpty) {
          return const Center(
            child: Text(
              'No active app limits set',
              style: TextStyle(color: Colors.white70),
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
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Colors.tealAccent),
      ),
      error: (error, stackTrace) => Center(
        child: Text(
          'Error loading goals: $error',
          style: const TextStyle(color: Colors.white70),
        ),
      ),
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