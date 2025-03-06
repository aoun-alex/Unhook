import 'package:flutter/material.dart';

class MinutesSlider extends StatefulWidget {
  final int initialValue;
  final Function(int) onChanged;
  final int minValue;
  final int maxValue;
  final int step;

  const MinutesSlider({
    Key? key,
    required this.initialValue,
    required this.onChanged,
    this.minValue = 10,
    this.maxValue = 120,
    this.step = 10,
  }) : super(key: key);

  @override
  State<MinutesSlider> createState() => _MinutesSliderState();
}

class _MinutesSliderState extends State<MinutesSlider> {
  late FixedExtentScrollController _scrollController;
  late int _currentValue;
  late List<int> _values;

  @override
  void initState() {
    super.initState();
    _values = List.generate(
      ((widget.maxValue - widget.minValue) ~/ widget.step) + 1,
          (index) => widget.minValue + (index * widget.step),
    );

    _currentValue = _ensureValidValue(widget.initialValue);
    int initialIndex = _values.indexOf(_currentValue);
    _scrollController = FixedExtentScrollController(initialItem: initialIndex);
  }

  int _ensureValidValue(int value) {
    // Round to nearest step
    int roundedValue = ((value / widget.step).round() * widget.step);

    // Clamp between min and max
    return roundedValue.clamp(widget.minValue, widget.maxValue);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Center selection indicator
          Center(
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                  color: Colors.tealAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          // List wheel scroll view for minutes
          ListWheelScrollView.useDelegate(
            controller: _scrollController,
            itemExtent: 45,
            perspective: 0.005,
            diameterRatio: 1.8,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) {
              setState(() {
                _currentValue = _values[index];
                widget.onChanged(_currentValue);
              });
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: _values.length,
              builder: (context, index) {
                final isSelected = _values[index] == _currentValue;

                return Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${_values[index]}',
                          style: TextStyle(
                            color: isSelected ? Colors.tealAccent : Colors.white,
                            fontSize: isSelected ? 22 : 18,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'minutes',
                          style: TextStyle(
                            color: isSelected ? Colors.tealAccent : Colors.white70,
                            fontSize: isSelected ? 15 : 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Show hour equivalent on top
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _currentValue >= 60
                      ? '${(_currentValue / 60).toStringAsFixed(1)} hours'
                      : '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}