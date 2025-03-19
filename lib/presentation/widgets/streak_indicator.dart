import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/streak_provider.dart';

class StreakIndicator extends ConsumerWidget {
  const StreakIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakNotifierProvider);

    return streakAsync.when(
      data: (currentStreak) => _buildStreakCard(context, currentStreak, ref),
      loading: () => _buildLoadingCard(),
      error: (error, stackTrace) => _buildErrorCard(error),
    );
  }

  Widget _buildStreakCard(BuildContext context, int currentStreak, WidgetRef ref) {
    final String message = _getStreakMessage(currentStreak);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.tealAccent.withAlpha(51),
            Colors.teal.withAlpha(26),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.tealAccent.withAlpha(77),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: Colors.tealAccent,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currentStreak == 1
                          ? '$currentStreak Day Streak'
                          : '$currentStreak Day Streak',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Show longest streak if available
                    FutureBuilder<int>(
                        future: ref.read(streakServiceProvider).getLongestStreak(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data! > currentStreak) {
                            return Text(
                              'Best: ${snapshot.data}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
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
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[700],
              shape: BoxShape.circle,
            ),
            child: const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.tealAccent,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Calculating your streak...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(Object error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Error loading streak data',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStreakMessage(int currentStreak) {
    if (currentStreak <= 0) {
      return 'Start your streak by staying within your limits today!';
    } else if (currentStreak == 1) {
      return 'You\'ve stayed within your limits for 1 day. Keep it up!';
    } else if (currentStreak < 3) {
      return 'You\'ve stayed within your limits for $currentStreak days in a row!';
    } else if (currentStreak < 7) {
      return 'Great job! $currentStreak day streak and counting!';
    } else if (currentStreak < 14) {
      return 'Impressive! You\'ve maintained your limits for $currentStreak days straight!';
    } else if (currentStreak < 30) {
      return 'Amazing discipline! $currentStreak day streak - you\'re on fire!';
    } else {
      return 'Incredible! $currentStreak days of digital wellbeing mastery!';
    }
  }
}