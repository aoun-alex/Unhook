import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/alternative_model.dart';
import '../../providers/alternatives_provider.dart';
import '../../providers/pinned_alternatives_provider.dart';

/// A card widget that displays an alternative activity or app
class AlternativeCard extends ConsumerStatefulWidget {
  /// The alternative to display
  final Alternative alternative;

  /// The name of the source app this is an alternative for
  final String sourceAppName;

  /// The package name of the source app
  final String sourceAppPackage;

  /// Whether to show which app this is an alternative for
  final bool showSourceApp;

  /// Callback when the card is tapped
  final Function()? onTap;

  /// Callback when the pin button is tapped
  final Function(bool isPinned)? onPinToggled;

  /// Whether this card is in a pinned alternatives section
  final bool isPinnedSection;

  const AlternativeCard({
    Key? key,
    required this.alternative,
    required this.sourceAppName,
    required this.sourceAppPackage,
    this.showSourceApp = true,
    this.onTap,
    this.onPinToggled,
    this.isPinnedSection = false,
  }) : super(key: key);

  @override
  ConsumerState<AlternativeCard> createState() => _AlternativeCardState();
}

class _AlternativeCardState extends ConsumerState<AlternativeCard> {
  bool _isPinned = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Check if this alternative is pinned
    _checkIfPinned();
  }

  Future<void> _checkIfPinned() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final isPinned = await ref
          .read(alternativeActionsProvider.notifier)
          .isAlternativePinned(widget.alternative.title);

      if (mounted) {
        setState(() {
          _isPinned = isPinned;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _togglePin() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      bool success;
      if (_isPinned) {
        success = await ref
            .read(alternativeActionsProvider.notifier)
            .unpinAlternative(widget.alternative.title);
      } else {
        success = await ref
            .read(alternativeActionsProvider.notifier)
            .pinAlternative(widget.alternative, widget.sourceAppPackage);
      }

      if (success && mounted) {
        setState(() {
          _isPinned = !_isPinned;
        });

        if (widget.onPinToggled != null) {
          widget.onPinToggled!(_isPinned);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if this is an offline or app alternative
    final isOffline = widget.alternative.isOfflineActivity;
    final categoryText = widget.alternative.category ?? (isOffline ? 'Offline Activity' : 'App Alternative');

    // Determine colors based on alternative type
    final Color cardColor = isOffline
        ? Colors.teal.withOpacity(0.2)
        : Colors.blue.withOpacity(0.2);

    final Color iconColor = isOffline
        ? Colors.tealAccent
        : Colors.blueAccent;

    return Card(
      elevation: 2,
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _isPinned ? Colors.tealAccent.withOpacity(0.7) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon in a colored circle
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cardColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.alternative.icon,
                      color: iconColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title and category
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.alternative.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          categoryText,
                          style: TextStyle(
                            color: iconColor.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Pin button
                  if (!widget.isPinnedSection)
                    IconButton(
                      icon: _isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.tealAccent,
                        ),
                      )
                          : Icon(
                        _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                        color: _isPinned ? Colors.tealAccent : Colors.white70,
                      ),
                      onPressed: _togglePin,
                      tooltip: _isPinned ? 'Unpin' : 'Pin',
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                widget.alternative.description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),

              // Show which app this is an alternative for
              if (widget.showSourceApp) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.swap_horiz,
                      color: Colors.white.withOpacity(0.5),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Alternative for ${widget.sourceAppName}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A smaller, simplified alternative card for the pinned section
class PinnedAlternativeCard extends ConsumerWidget {
  final Alternative alternative;
  final String sourceAppName;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onUnpin;

  const PinnedAlternativeCard({
    Key? key,
    required this.alternative,
    required this.sourceAppName,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onUnpin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine if this is an offline or app alternative
    final isOffline = alternative.isOfflineActivity;
    final Color iconColor = isOffline
        ? Colors.tealAccent
        : Colors.blueAccent;

    return Card(
      elevation: 1,
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Colors.tealAccent.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onToggleExpanded,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Icon(
                    alternative.icon,
                    color: iconColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),

                  // Title
                  Expanded(
                    child: Text(
                      alternative.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Unpin button
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: 16,
                    ),
                    onPressed: onUnpin,
                    tooltip: 'Unpin',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              // Description and source app (only if expanded)
              if (isExpanded) ...[
                const SizedBox(height: 8),
                Text(
                  alternative.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Alternative for $sourceAppName',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}