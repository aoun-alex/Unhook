import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/alternative_model.dart';
import '../../providers/pinned_alternatives_provider.dart';
import 'alternative_card.dart';
import '../../providers/alternatives_provider.dart';

/// A section widget that displays a group of alternatives
class AlternativesSection extends StatelessWidget {
  /// The section title
  final String title;

  /// Alternative data with source app information
  final List<Map<String, dynamic>> alternatives;

  /// Whether to show the app that each alternative is for
  final bool showSourceApps;

  /// Callback when an alternative is tapped
  final Function(Map<String, dynamic>)? onAlternativeTap;

  /// Whether this is a pinned alternatives section
  final bool isPinnedSection;

  /// Custom section icon
  final IconData? icon;

  /// Description text for the section
  final String? description;

  const AlternativesSection({
    Key? key,
    required this.title,
    required this.alternatives,
    this.showSourceApps = true,
    this.onAlternativeTap,
    this.isPinnedSection = false,
    this.icon,
    this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sort alternatives if needed
    final sortedAlternatives = List<Map<String, dynamic>>.from(alternatives);

    // Check if there are any alternatives to display
    if (sortedAlternatives.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        _buildSectionHeader(),

        // Optional description
        if (description != null) ...[
          const SizedBox(height: 8),
          Text(
            description!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Alternatives list - Changed from GridView to ListView
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedAlternatives.length,
          itemBuilder: (context, index) {
            final alternativeData = sortedAlternatives[index];
            final alternative = alternativeData['alternative'] as Alternative;
            final appName = alternativeData['appName'] as String;
            final packageName = alternativeData['packageName'] as String;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: AlternativeCard(
                alternative: alternative,
                sourceAppName: appName,
                sourceAppPackage: packageName,
                showSourceApp: showSourceApps,
                isPinnedSection: isPinnedSection,
                onTap: () {
                  if (onAlternativeTap != null) {
                    onAlternativeTap!(alternativeData);
                  }
                },
              ),
            );
          },
        ),
      ],
    );
  }

  /// Builds the section header with title and icon
  Widget _buildSectionHeader() {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            color: Colors.tealAccent,
            size: 20,
          ),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Builds an empty state when there are no alternatives
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[850]!.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon ?? Icons.lightbulb_outline,
            color: Colors.tealAccent.withValues(alpha: 0.5),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'No $title Available',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description ?? 'Start using more apps to get personalized recommendations.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// A widget that displays pinned alternatives
class PinnedAlternativesSection extends ConsumerWidget {
  const PinnedAlternativesSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinnedAlternatives = ref.watch(pinnedAlternativesNotifierProvider);

    // If there are no pinned alternatives, show a message
    if (pinnedAlternatives.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[850]!.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.tealAccent.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.push_pin,
              color: Colors.tealAccent.withValues(alpha: 0.5),
              size: 32,
            ),
            const SizedBox(height: 12),
            const Text(
              'No Pinned Alternatives',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Pin your favorite alternatives for quick access.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Show pinned alternatives
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            const Icon(
              Icons.push_pin,
              color: Colors.tealAccent,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Pinned Alternatives',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(
                Icons.edit,
                size: 16,
                color: Colors.tealAccent,
              ),
              label: const Text(
                'Edit',
                style: TextStyle(
                  color: Colors.tealAccent,
                  fontSize: 14,
                ),
              ),
              onPressed: () {
                _showEditDialog(context, ref);
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // List of pinned alternatives
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: pinnedAlternatives.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final pinnedState = pinnedAlternatives[index];

            return PinnedAlternativeCard(
              alternative: pinnedState.alternative,
              sourceAppName: '', // This would need to be retrieved
              isExpanded: pinnedState.isExpanded,
              onToggleExpanded: () {
                ref.read(pinnedAlternativesNotifierProvider.notifier)
                    .toggleExpanded(pinnedState.alternative.title);
              },
              onUnpin: () {
                ref.read(pinnedAlternativesNotifierProvider.notifier)
                    .unpinAlternative(pinnedState.alternative.title);
              },
            );
          },
        ),
      ],
    );
  }

  /// Shows a dialog to edit the order of pinned alternatives
  void _showEditDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Edit Pinned Alternatives',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: _PinnedAlternativesEditor(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              'Done',
              style: TextStyle(color: Colors.tealAccent),
            ),
          ),
        ],
      ),
    );
  }
}

/// A widget for editing pinned alternatives (reordering, removing)
class _PinnedAlternativesEditor extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinnedAlternatives = ref.watch(pinnedAlternativesNotifierProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Drag to reorder or tap the X to remove',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.4,
          ),
          child: ReorderableListView.builder(
            shrinkWrap: true,
            itemCount: pinnedAlternatives.length,
            onReorder: (oldIndex, newIndex) {
              // Handle the reorder logic
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }

              final notifier = ref.read(pinnedAlternativesNotifierProvider.notifier);

              // Move items one by one to avoid index issues
              if (oldIndex < newIndex) {
                for (int i = oldIndex; i < newIndex; i++) {
                  notifier.moveDown(i);
                }
              } else {
                for (int i = oldIndex; i > newIndex; i--) {
                  notifier.moveUp(i);
                }
              }
            },
            itemBuilder: (context, index) {
              final alternative = pinnedAlternatives[index].alternative;

              return ListTile(
                key: Key('pinned-${alternative.title}'),
                leading: Icon(
                  alternative.icon,
                  color: Colors.tealAccent,
                ),
                title: Text(
                  alternative.title,
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.redAccent),
                      onPressed: () {
                        ref.read(pinnedAlternativesNotifierProvider.notifier)
                            .unpinAlternative(alternative.title);
                      },
                      tooltip: 'Remove',
                    ),
                    const Icon(Icons.drag_handle, color: Colors.white54),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A widget for displaying offline activity alternatives
class OfflineAlternativesSection extends ConsumerWidget {
  final Function(Map<String, dynamic>)? onAlternativeTap;

  const OfflineAlternativesSection({
    Key? key,
    this.onAlternativeTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offlineAlternatives = ref.watch(offlineAlternativesProvider);

    return AlternativesSection(
      title: 'Offline Activities',
      alternatives: offlineAlternatives,
      showSourceApps: true,
      onAlternativeTap: onAlternativeTap,
      icon: Icons.nature_people,
      description: 'Engage in these real-world activities instead of digital scrolling.',
    );
  }
}