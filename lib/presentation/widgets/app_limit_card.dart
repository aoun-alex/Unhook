import 'dart:typed_data';
import 'package:flutter/material.dart';

class AppLimitCard extends StatelessWidget {
  final String appName;
  final Uint8List? appIcon;
  final String packageName;
  final int currentUsage;
  final int limitInMinutes;
  final String category;
  final bool isLimitReached;

  const AppLimitCard({
    super.key,
    required this.appName,
    required this.appIcon,
    required this.packageName,
    required this.currentUsage,
    required this.limitInMinutes,
    required this.category,
    this.isLimitReached = false,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = currentUsage / limitInMinutes;
    final Color progressColor = isLimitReached
        ? Colors.redAccent
        : (progress > 0.8 ? Colors.orangeAccent : Colors.tealAccent);

    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: appIcon != null
                      ? Image.memory(appIcon!, width: 24, height: 24)
                      : const Icon(
                    Icons.app_shortcut,
                    color: Colors.white70,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category,
                        style: TextStyle(
                          color: Colors.white.withAlpha(153),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white70),
                  onPressed: () {
                    // Handle more options
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${currentUsage}m / ${limitInMinutes}m',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      isLimitReached ? 'Limit Reached' : '${((1 - progress) * 100).toInt()}% remaining',
                      style: TextStyle(
                        color: progressColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[800],
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}