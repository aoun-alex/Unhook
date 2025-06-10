import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/streak_provider.dart';
import '../../data/models/streak_record.dart';

class StreakCalendar extends ConsumerStatefulWidget {
  const StreakCalendar({Key? key}) : super(key: key);

  @override
  ConsumerState<StreakCalendar> createState() => _StreakCalendarState();
}

class _StreakCalendarState extends ConsumerState<StreakCalendar> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final monthYear = MonthYear(_selectedMonth.year, _selectedMonth.month);
    final monthRecordsAsync = ref.watch(monthlyStreakRecordsProvider(monthYear));

    return Column(
      children: [
        _buildCalendarHeader(),
        const SizedBox(height: 16),
        Expanded(
          child: monthRecordsAsync.when(
            data: (records) => _buildCalendarGrid(records),
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent),
            ),
            error: (error, stack) => const Center(
              child: Text(
                'Error loading streak data',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildCalendarLegend(),
      ],
    );
  }

  Widget _buildCalendarHeader() {
    final monthFormatter = DateFormat('MMMM yyyy');
    final monthText = monthFormatter.format(_selectedMonth);

    // Determine if next month is in the future
    final now = DateTime.now();
    final isNextMonthFuture = _selectedMonth.year > now.year ||
        (_selectedMonth.year == now.year && _selectedMonth.month >= now.month);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white),
          onPressed: _previousMonth,
        ),
        Text(
          monthText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: Colors.white),
          onPressed: isNextMonthFuture ? null : _nextMonth,
          disabledColor: Colors.white.withValues(alpha: 0.3),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(List<StreakRecord> records) {
    // Get the first day of the month
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);

    // Get the day of week for the first day (0 = Monday, 6 = Sunday in DateTime)
    final firstWeekday = firstDayOfMonth.weekday;

    // Calculate the number of days in the month
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;

    // Convert records to a map for easier lookup
    final recordMap = {
      for (var record in records) record.date: record
    };

    // Build the calendar grid
    return Column(
      children: [
        // Days of week header
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            CalendarDayHeader(day: 'Mon'),
            CalendarDayHeader(day: 'Tue'),
            CalendarDayHeader(day: 'Wed'),
            CalendarDayHeader(day: 'Thu'),
            CalendarDayHeader(day: 'Fri'),
            CalendarDayHeader(day: 'Sat'),
            CalendarDayHeader(day: 'Sun'),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0), // Add padding to prevent overflow
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
                crossAxisSpacing: 2, // Reduce spacing to prevent overflow
                mainAxisSpacing: 2,
              ),
              itemCount: (firstWeekday - 1) + daysInMonth, // Adjusted for Monday start
              itemBuilder: (context, index) {
                // Empty cells for days before the first of the month
                if (index < (firstWeekday - 1)) {
                  return const SizedBox();
                }

                // Calculate the day number
                final day = index - (firstWeekday - 1) + 1;

                // Format the date string for lookup in the record map
                final dateStr = _formatDate(_selectedMonth.year, _selectedMonth.month, day);

                // Get the streak record for this day if it exists
                final record = recordMap[dateStr];

                // Check if this day is today
                final isToday = _isToday(_selectedMonth.year, _selectedMonth.month, day);

                // Check if this day is in the future
                final isFuture = _isFuture(_selectedMonth.year, _selectedMonth.month, day);

                // Get the streak status for this day
                final streakStatus = _getStreakStatus(record, isFuture);

                // Get the streak day number (to show consecutive days)
                final streakDay = record?.streakDay ?? 0;

                return CalendarDayCell(
                  day: day,
                  streakStatus: streakStatus,
                  streakDay: streakDay,
                  isToday: isToday,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildLegendItem(Colors.grey.withValues(alpha: 0.3), 'No data'),
          _buildLegendItem(Colors.tealAccent.withValues(alpha: 0.5), 'Within limits'),
          _buildLegendItem(Colors.tealAccent, 'Streak day'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatDate(int year, int month, int day) {
    return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  bool _isToday(int year, int month, int day) {
    final now = DateTime.now();
    return now.year == year && now.month == month && now.day == day;
  }

  bool _isFuture(int year, int month, int day) {
    final now = DateTime.now();
    final date = DateTime(year, month, day);
    return date.isAfter(now);
  }

  StreakStatus _getStreakStatus(StreakRecord? record, bool isFuture) {
    if (isFuture) {
      return StreakStatus.future;
    } else if (record == null) {
      return StreakStatus.noData;
    } else if (record.streakDay > 0) {
      // If streakDay > 0, it's definitely a streak day (green)
      return StreakStatus.streak;
    } else if (record.allLimitsRespected) {
      // If limits were respected but not part of streak
      return StreakStatus.respected;
    } else {
      // Only show as no data if both conditions fail
      return StreakStatus.noData;
    }
  }
}

enum StreakStatus {
  noData,
  respected,
  streak,
  future,
}

class CalendarDayHeader extends StatelessWidget {
  final String day;

  const CalendarDayHeader({Key? key, required this.day}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Text(
        day,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class CalendarDayCell extends StatelessWidget {
  final int day;
  final StreakStatus streakStatus;
  final int streakDay;
  final bool isToday;

  const CalendarDayCell({
    Key? key,
    required this.day,
    required this.streakStatus,
    required this.streakDay,
    required this.isToday,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor = Colors.white;
    BoxBorder? border;

    switch (streakStatus) {
      case StreakStatus.noData:
        backgroundColor = Colors.grey.withValues(alpha: 0.3);
        break;
      case StreakStatus.respected:
        backgroundColor = Colors.tealAccent.withValues(alpha: 0.5);
        break;
      case StreakStatus.streak:
        backgroundColor = Colors.tealAccent.withValues(alpha: 0.8);
        textColor = Colors.black;
        break;
      case StreakStatus.future:
        backgroundColor = Colors.transparent;
        textColor = Colors.white.withValues(alpha: 0.3);
        break;
    }

    // Add today indicator
    if (isToday) {
      border = Border.all(
        color: Colors.white,
        width: 2.0,
      );
    }

    // If this is part of a streak and not the first day, add streak indicator
    String? streakDayText;
    if (streakStatus == StreakStatus.streak && streakDay > 1) {
      streakDayText = '$streakDay';
    }

    return Container(
      margin: const EdgeInsets.all(1), // Reduced margin to prevent overflow
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6), // Slightly smaller radius
        border: border,
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              day.toString(),
              style: TextStyle(
                color: textColor,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                fontSize: 14, // Slightly smaller font
              ),
            ),
          ),
          if (streakDayText != null)
            Positioned(
              top: 1,
              right: 2,
              child: Container(
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  streakDayText,
                  style: const TextStyle(
                    color: Colors.tealAccent,
                    fontSize: 8, // Smaller font for streak number
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}