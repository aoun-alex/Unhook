import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/real_time_tracking_service.dart';

/// Provider for the real-time tracking service
final realTimeTrackingServiceProvider = Provider<RealTimeTrackingService>((ref) {
  final service = RealTimeTrackingService();
  // Initialize the service when it's first accessed
  service.initialize();

  // Dispose the service when the provider is disposed
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Stream provider for app launches
final appLaunchStreamProvider = StreamProvider<String>((ref) {
  final trackingService = ref.watch(realTimeTrackingServiceProvider);
  return trackingService.appLaunchStream;
});

/// Provider for the accessibility service status
final accessibilityServiceEnabledProvider = FutureProvider<bool>((ref) async {
  final trackingService = ref.watch(realTimeTrackingServiceProvider);
  return await trackingService.isAccessibilityServiceEnabled();
});