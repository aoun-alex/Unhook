import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/app_discovery_service.dart';

final appDiscoveryServiceProvider = Provider<AppDiscoveryService>((ref) {
  return AppDiscoveryService();
});

final monitoredAppsProvider = FutureProvider<List<AppInfo>>((ref) async {
  final discoveryService = ref.read(appDiscoveryServiceProvider);
  return await discoveryService.getMonitoredInstalledApps();
});