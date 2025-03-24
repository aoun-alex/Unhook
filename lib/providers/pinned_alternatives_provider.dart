import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/alternative_model.dart';
import 'alternatives_provider.dart';

/// Provider for pinned alternatives
final pinnedAlternativesProvider = FutureProvider<List<Alternative>>((ref) async {
  final alternativesService = ref.watch(alternativesServiceProvider);
  return await alternativesService.getPinnedAlternatives();
});

/// Notifier for managing the state of pinned alternatives with additional metadata
class PinnedAlternativesNotifier extends StateNotifier<List<PinnedAlternativeState>> {
  final Ref _ref;

  PinnedAlternativesNotifier(this._ref) : super([]) {
    _loadPinnedAlternatives();
  }

  /// Load pinned alternatives from the database
  Future<void> _loadPinnedAlternatives() async {
    final alternativesAsync = await _ref.read(pinnedAlternativesProvider.future);

    // Convert alternatives to state objects with additional metadata
    final pinnedStates = <PinnedAlternativeState>[];

    for (final alternative in alternativesAsync) {
      pinnedStates.add(
        PinnedAlternativeState(
          alternative: alternative,
          isExpanded: false,
        ),
      );
    }

    state = pinnedStates;
  }

  /// Reload pinned alternatives (e.g., after a change)
  Future<void> reloadPinnedAlternatives() async {
    await _loadPinnedAlternatives();
  }

  /// Pin a new alternative
  Future<void> pinAlternative(Alternative alternative, String sourceAppPackage) async {
    final success = await _ref.read(alternativeActionsProvider.notifier)
        .pinAlternative(alternative, sourceAppPackage);

    if (success) {
      await reloadPinnedAlternatives();
    }
  }

  /// Unpin an alternative
  Future<void> unpinAlternative(String title) async {
    final success = await _ref.read(alternativeActionsProvider.notifier)
        .unpinAlternative(title);

    if (success) {
      await reloadPinnedAlternatives();
    }
  }

  /// Toggle expanded state of a pinned alternative
  void toggleExpanded(String title) {
    state = [
      for (final item in state)
        if (item.alternative.title == title)
          item.copyWith(isExpanded: !item.isExpanded)
        else
          item,
    ];
  }

  /// Move an alternative up in the list
  void moveUp(int index) {
    if (index <= 0 || index >= state.length) return;

    final newState = List<PinnedAlternativeState>.from(state);
    final item = newState.removeAt(index);
    newState.insert(index - 1, item);

    state = newState;
  }

  /// Move an alternative down in the list
  void moveDown(int index) {
    if (index < 0 || index >= state.length - 1) return;

    final newState = List<PinnedAlternativeState>.from(state);
    final item = newState.removeAt(index);
    newState.insert(index + 1, item);

    state = newState;
  }
}

/// Provider for pinned alternatives with state management
final pinnedAlternativesNotifierProvider = StateNotifierProvider<PinnedAlternativesNotifier, List<PinnedAlternativeState>>((ref) {
  return PinnedAlternativesNotifier(ref);
});

/// Class representing the state of a pinned alternative with additional metadata
class PinnedAlternativeState {
  final Alternative alternative;
  final bool isExpanded;

  PinnedAlternativeState({
    required this.alternative,
    required this.isExpanded,
  });

  PinnedAlternativeState copyWith({
    Alternative? alternative,
    bool? isExpanded,
  }) {
    return PinnedAlternativeState(
      alternative: alternative ?? this.alternative,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
}

/// Provider to check if an alternative is pinned
final isAlternativePinnedProvider = FutureProvider.family<bool, String>((ref, title) async {
  final alternativesService = ref.watch(alternativesServiceProvider);
  return await alternativesService.isAlternativePinned(title);
});