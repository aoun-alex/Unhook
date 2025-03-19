import 'package:flutter/services.dart';
import 'package:device_apps/device_apps.dart';
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
      final app = await DeviceApps.getApp(packageName, true);
      if (app != null && app is ApplicationWithIcon) {
        return Uint8List.fromList(app.icon);
      }
      return await _getDefaultIcon();
    } catch (_) {
      return await _getDefaultIcon();
    }
  }

  // Get all monitored apps that are installed on the device
  Future<List<AppInfo>> getMonitoredInstalledApps() async {
    List<AppInfo> monitoredApps = [];

    try {
      // Get all installed apps
      final installedApps = await DeviceApps.getInstalledApplications(
        includeSystemApps: true, // Include system apps because of YouTube
        includeAppIcons: true,
      );

      // For each installed app, check if it's in our monitored list
      for (var app in installedApps) {
        final packageName = app.packageName;

        // Check if this app is in our monitored list
        if (appNameMap.containsKey(packageName)) {
          final appName = appNameMap[packageName]!;
          Uint8List appIcon;

          if (app is ApplicationWithIcon) {
            appIcon = Uint8List.fromList(app.icon);
          } else {
            appIcon = await _getDefaultIcon();
          }

          monitoredApps.add(AppInfo(
            packageName: packageName,
            appName: appName,
            appIcon: appIcon,
          ));
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