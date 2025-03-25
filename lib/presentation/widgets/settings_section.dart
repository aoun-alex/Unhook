import 'package:flutter/material.dart';

class SettingsSection extends StatelessWidget {
  final String title;

  const SettingsSection({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: Colors.tealAccent.withAlpha(180),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Divider(
            color: Colors.tealAccent.withAlpha(100),
            thickness: 1,
          ),
        ],
      ),
    );
  }
}