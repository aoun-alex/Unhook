import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/alternatives_service.dart';
import '../data/models/alternative_model.dart';
import 'goals_provider.dart';
import 'pinned_alternatives_provider.dart';

/// Provider for the alternatives service
final alternativesServiceProvider = Provider<AlternativesService>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return AlternativesService(dbHelper);
});

/// Provider for all alternatives grouped by category
final alternativesByCategoryProvider = Provider<Map<String, List<Map<String, dynamic>>>>((ref) {
  final alternativesService = ref.watch(alternativesServiceProvider);
  return alternativesService.getAllAlternativesByCategory();
});

/// Provider for alternatives related to a specific app
final appAlternativesProvider = Provider.family<List<Alternative>, String>((ref, packageName) {
  final alternativesService = ref.watch(alternativesServiceProvider);
  return alternativesService.getAlternativesForApp(packageName);
});

/// Provider for personalized alternatives based on user's goals and usage
final personalizedAlternativesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final alternativesService = ref.watch(alternativesServiceProvider);
  final goals = ref.watch(activeGoalsProvider);
  return await alternativesService.getPersonalizedAlternatives(goals);
});

/// Provider for offline activity alternatives only
final offlineAlternativesProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final alternativesService = ref.watch(alternativesServiceProvider);
  return alternativesService.getOfflineAlternatives();
});

/// Provider for category-specific recommendations
final categoryRecommendationsProvider = Provider.family<List<Map<String, dynamic>>, String>((ref, category) {
  final alternativesService = ref.watch(alternativesServiceProvider);
  return alternativesService.getRecommendationsByCategory(category);
});

/// Loading state provider for alternatives operations
final alternativesLoadingProvider = StateProvider<bool>((ref) => false);

/// Notifier for managing alternative pinning/unpinning operations
class AlternativeActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final AlternativesService _alternativesService;
  final Ref _ref;

  AlternativeActionsNotifier(this._alternativesService, this._ref) : super(const AsyncValue.data(null));

  /// Pin an alternative
  Future<bool> pinAlternative(Alternative alternative, String sourceAppPackage) async {
    _ref.read(alternativesLoadingProvider.notifier).state = true;

    try {
      final result = await _alternativesService.pinAlternative(alternative, sourceAppPackage);

      // Refresh pinned alternatives
      await _ref.refresh(pinnedAlternativesNotifierProvider.notifier).reloadPinnedAlternatives();

      return result;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    } finally {
      _ref.read(alternativesLoadingProvider.notifier).state = false;
    }
  }

  /// Unpin an alternative
  Future<bool> unpinAlternative(String title) async {
    _ref.read(alternativesLoadingProvider.notifier).state = true;

    try {
      final result = await _alternativesService.unpinAlternative(title);

      // Refresh pinned alternatives
      await _ref.refresh(pinnedAlternativesNotifierProvider.notifier).reloadPinnedAlternatives();

      return result;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    } finally {
      _ref.read(alternativesLoadingProvider.notifier).state = false;
    }
  }

  /// Check if an alternative is pinned
  Future<bool> isAlternativePinned(String title) async {
    try {
      return await _alternativesService.isAlternativePinned(title);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }
}

/// Provider for alternative actions notifier
final alternativeActionsProvider = StateNotifierProvider<AlternativeActionsNotifier, AsyncValue<void>>((ref) {
  final alternativesService = ref.watch(alternativesServiceProvider);
  return AlternativeActionsNotifier(alternativesService, ref);
});