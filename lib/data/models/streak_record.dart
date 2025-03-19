class StreakRecord {
  final String date;
  final int streakDay;
  final bool allLimitsRespected;
  final int timestamp;

  StreakRecord({
    required this.date,
    required this.streakDay,
    required this.allLimitsRespected,
    required this.timestamp,
  });

  // Create a copy with updated values
  StreakRecord copyWith({
    String? date,
    int? streakDay,
    bool? allLimitsRespected,
    int? timestamp,
  }) {
    return StreakRecord(
      date: date ?? this.date,
      streakDay: streakDay ?? this.streakDay,
      allLimitsRespected: allLimitsRespected ?? this.allLimitsRespected,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  // Parse date string into DateTime object
  DateTime get dateTime {
    final parts = date.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  // Format date for display: e.g., "Jan 15, 2025"
  String get formattedDate {
    final dt = dateTime;
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  String toString() {
    return 'StreakRecord(date: $date, streakDay: $streakDay, allLimitsRespected: $allLimitsRespected)';
  }
}