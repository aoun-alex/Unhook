class UsageSnapshot {
  final String packageName;
  final int usageMinutes;
  final int timestamp;
  final String date;

  UsageSnapshot({
    required this.packageName,
    required this.usageMinutes,
    required this.timestamp,
    required this.date,
  });

  // Helper method to format date from yyyy-MM-dd to readable format
  String get formattedDate {
    final parts = date.split('-');
    if (parts.length != 3) return date;

    final year = int.tryParse(parts[0]) ?? 0;
    final month = int.tryParse(parts[1]) ?? 0;
    final day = int.tryParse(parts[2]) ?? 0;

    final dateObj = DateTime(year, month, day);
    return '${dateObj.day}/${dateObj.month}/${dateObj.year}';
  }

  // Helper method to get readable timestamp
  String get formattedTime {
    final dateObj = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dateObj.hour.toString().padLeft(2, '0')}:${dateObj.minute.toString().padLeft(2, '0')}';
  }

  // For creating a copy with updated values
  UsageSnapshot copyWith({
    String? packageName,
    int? usageMinutes,
    int? timestamp,
    String? date,
  }) {
    return UsageSnapshot(
      packageName: packageName ?? this.packageName,
      usageMinutes: usageMinutes ?? this.usageMinutes,
      timestamp: timestamp ?? this.timestamp,
      date: date ?? this.date,
    );
  }
}