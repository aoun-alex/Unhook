import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/usage_provider.dart';

class DetailedUsageScreen extends ConsumerWidget {
  const DetailedUsageScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String appName = ModalRoute.of(context)?.settings.arguments as String;
    final todayUsageAsync = ref.watch(todayUsageProvider);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text(appName, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today\'s Sessions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: todayUsageAsync.when(
                data: (usage) {
                  final appUsage = usage[appName] ?? Duration.zero;
                  // Mock sessions for demonstration - replace with actual session data
                  final List<Map<String, dynamic>> sessions = [
                    {
                      'startTime': DateTime.now().subtract(const Duration(hours: 2)),
                      'duration': const Duration(minutes: 45),
                    },
                    {
                      'startTime': DateTime.now().subtract(const Duration(hours: 4)),
                      'duration': const Duration(minutes: 30),
                    },
                  ];

                  return Column(
                    children: [
                      Card(
                        color: Colors.grey[850],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Today',
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                              Text(
                                '${appUsage.inMinutes}m',
                                style: const TextStyle(
                                  color: Colors.tealAccent,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: sessions.length,
                          itemBuilder: (context, index) {
                            final session = sessions[index];
                            return Card(
                              color: Colors.grey[850],
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(
                                  _formatTime(session['startTime']),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  'Duration: ${_formatDuration(session['duration'])}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.tealAccent,
                                  size: 16,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Colors.tealAccent),
                ),
                error: (error, stack) => const Center(
                  child: Text(
                    'Error loading sessions',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    return '${duration.inMinutes}m';
  }
}

