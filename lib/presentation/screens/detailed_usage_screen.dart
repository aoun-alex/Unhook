import 'package:flutter/material.dart';
import '../../data/services/usage_service.dart';
import '../../data/models/app_usage.dart';
import 'package:intl/intl.dart';

class DetailedUsageScreen extends StatelessWidget {
  final AppUsageSummary summary;

  const DetailedUsageScreen({
    Key? key,
    required this.summary,
  }) : super(key: key);

  Map<String, List<AppUsage>> _groupSessionsByDay() {
    Map<String, List<AppUsage>> groupedSessions = {};

    for (var session in summary.sessions) {
      // Create a key in format "Monday, Jan 15"
      String dayKey = DateFormat('EEEE, MMM d').format(session.time);

      if (!groupedSessions.containsKey(dayKey)) {
        groupedSessions[dayKey] = [];
      }
      groupedSessions[dayKey]!.add(session);
    }

    // Sort sessions within each day
    groupedSessions.forEach((day, sessions) {
      sessions.sort((a, b) => b.time.compareTo(a.time));
    });

    return groupedSessions;
  }

  int _calculateDayTotal(List<AppUsage> sessions) {
    return sessions.fold<int>(0, (sum, session) => sum + session.durationInSeconds);
  }

  @override
  Widget build(BuildContext context) {
    final groupedSessions = _groupSessionsByDay();
    final sortedDays = groupedSessions.keys.toList()
      ..sort((a, b) => DateFormat('EEEE, MMM d')
          .parse(b)
          .compareTo(DateFormat('EEEE, MMM d').parse(a)));

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Row(
          children: [
            if (summary.appIcon != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Image.memory(summary.appIcon!, width: 30, height: 30),
              ),
            Text(
              summary.appName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.grey[900]!.withValues(alpha: 0.95),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.grey[850],
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Usage',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        summary.totalDurationText,
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
              const SizedBox(height: 24),
              const Text(
                'Sessions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: sortedDays.length,
                  itemBuilder: (context, index) {
                    final day = sortedDays[index];
                    final sessions = groupedSessions[day]!;
                    final dayTotal = _calculateDayTotal(sessions);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                day,
                                style: const TextStyle(
                                  color: Colors.tealAccent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _formatDuration(Duration(seconds: dayTotal)),
                                style: const TextStyle(
                                  color: Colors.tealAccent,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(color: Colors.tealAccent, height: 1),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: sessions.length,
                          itemBuilder: (context, sessionIndex) {
                            final session = sessions[sessionIndex];
                            return Card(
                              color: Colors.grey[850],
                              elevation: 0,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                title: Text(
                                  _formatTime(session.time),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  session.durationInText ?? '',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.access_time,
                                  color: Colors.tealAccent,
                                  size: 20,
                                ),
                              ),
                            );
                          },
                        ),
                        if (index < sortedDays.length - 1)
                          const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }
}