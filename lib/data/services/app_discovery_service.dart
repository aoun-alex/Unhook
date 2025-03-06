import 'package:flutter/services.dart';
import 'package:android_package_manager/android_package_manager.dart';
import '../../constants.dart';
import 'dart:developer' as developer;

class AppInfo {
  final String packageName;
  final String appName;
  final Uint8List? appIcon;

  AppInfo({
    required this.packageName,
    required this.appName,
    this.appIcon,
  });
}

class AppDiscoveryService {
  final _packageManager = AndroidPackageManager();
  Uint8List? _defaultIcon;

  // Get default icon for fallback
  Future<Uint8List> _getDefaultIcon() async {
    if (_defaultIcon == null) {
      final ByteData data = await rootBundle.load('assets/default-icon.png');
      _defaultIcon = data.buffer.asUint8List();
    }
    return _defaultIcon!;
  }

  // Fetch icon for a package
  Future<Uint8List> fetchIcon(String packageName) async {
    try {
      final icon = await _packageManager.getApplicationIcon(packageName: packageName);
      return icon ?? await _getDefaultIcon();
    } catch (_) {
      return await _getDefaultIcon();
    }
  }

  // Get all monitored apps that are installed on the device
  Future<List<AppInfo>> getMonitoredInstalledApps() async {
    List<AppInfo> monitoredApps = [];

    try {
      // Get all installed apps
      final installedApps = await _packageManager.getInstalledApplications();

      // For each installed app, check if it's in our monitored list
      if (installedApps != null) {
        for (var app in installedApps) {
          final packageName = app.packageName;

          // Check if this app is in our monitored list and package name is not null
          if (packageName != null && appNameMap.containsKey(packageName)) {
            final appName = appNameMap[packageName]!;
            final appIcon = await fetchIcon(packageName);

            monitoredApps.add(AppInfo(
              packageName: packageName,
              appName: appName,
              appIcon: appIcon,
            ));
          }
        }
      }

      // Sort apps by name
      monitoredApps.sort((a, b) => a.appName.compareTo(b.appName));

    } catch (e) {
      developer.log('Error getting installed apps: $e');
    }

    return monitoredApps;
  }
}