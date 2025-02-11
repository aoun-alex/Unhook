import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DetailedUsageScreen extends ConsumerWidget {
  const DetailedUsageScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Retrieve the app name
    final String app = ModalRoute.of(context)?.settings.arguments as String;

    // Placeholder or real data from a provider
    final List<Map<String, dynamic>> mockSessions = [
      {
        'title': 'Session 1',
        'timeRange': 'From 2:35 PM to 4:20 PM (1h 45min)',
      },
      {
        'title': 'Session 2',
        'timeRange': 'From 6:00 PM to 6:30 PM (30min)',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: Text('$app Usage Details')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: mockSessions.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detailed usage for $app',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
              ],
            );
          }

          final session = mockSessions[index - 1];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(session['title'] ?? ''),
            subtitle: Text(session['timeRange'] ?? ''),
          );
        },
      ),
    );
  }
}
