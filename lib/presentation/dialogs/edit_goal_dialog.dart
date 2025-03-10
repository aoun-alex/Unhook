import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/goals_provider.dart';
import '../widgets/minutes_slider.dart';

class EditGoalDialog extends ConsumerStatefulWidget {
  final String appName;
  final String packageName;
  final dynamic appIcon;
  final int currentLimitInMinutes;
  final int currentUsage;
  final String currentCategory;

  const EditGoalDialog({
    Key? key,
    required this.appName,
    required this.packageName,
    required this.appIcon,
    required this.currentLimitInMinutes,
    required this.currentUsage,
    required this.currentCategory,
  }) : super(key: key);

  @override
  ConsumerState<EditGoalDialog> createState() => _EditGoalDialogState();
}

class _EditGoalDialogState extends ConsumerState<EditGoalDialog> {
  late int _limitInMinutes;
  late String _selectedCategory;

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
    _limitInMinutes = widget.currentLimitInMinutes;
    _selectedCategory = widget.currentCategory;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (widget.appIcon != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Image.memory(widget.appIcon, width: 32, height: 32),
                    ),
                  Expanded(
                    child: Text(
                      'Edit limit for ${widget.appName}',
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
                      color: Colors.tealAccent.withOpacity(0.2),
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
                height: 180,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Update the goal
                      ref.read(activeGoalsProvider.notifier).updateGoal(
                        appName: widget.appName,
                        packageName: widget.packageName,
                        appIcon: widget.appIcon,
                        limitInMinutes: _limitInMinutes,
                        currentUsage: widget.currentUsage,
                        category: _selectedCategory,
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}