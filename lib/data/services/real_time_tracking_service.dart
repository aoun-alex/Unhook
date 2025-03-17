import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;

class RealTimeTrackingService {
  static final RealTimeTrackingService _instance = RealTimeTrackingService._internal();

  factory RealTimeTrackingService() {
    return _instance;
  }

  RealTimeTrackingService._internal();

  static const MethodChannel _channel = MethodChannel('com.example.unhook/usage_tracking');

  final StreamController<String> _appLaunchStreamController = StreamController<String>.broadcast();
  Stream<String> get appLaunchStream => _appLaunchStreamController.stream;

  Timer? _pollingTimer;
  String _lastApp = '';

  /// Initialize the service and event handling
  Future<void> initialize() async {
    try {
      // Start the tracker service
      await startTrackingService();

      // Set up polling for current app
      _startPolling();
    } catch (e) {
      developer.log('Error initializing real-time tracking: $e');
    }
  }

  /// Start polling for the current app
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        final currentApp = await getCurrentApp();
        if (currentApp.isNotEmpty && currentApp != _lastApp) {
          _lastApp = currentApp;
          _appLaunchStreamController.add(currentApp);
          developer.log('App launched: $currentApp');
        }
      } catch (e) {
        developer.log('Error polling current app: $e');
      }
    });
  }

  /// Check if the accessibility service is enabled
  Future<bool> isAccessibilityServiceEnabled() async {
    try {
      return await _channel.invokeMethod('checkAccessibilityPermission');
    } catch (e) {
      developer.log('Error checking accessibility permission: $e');
      return false;
    }
  }

  /// Request the user to enable the accessibility service
  Future<void> requestAccessibilityPermission() async {
    try {
      await _channel.invokeMethod('requestAccessibilityPermission');
    } catch (e) {
      developer.log('Error requesting accessibility permission: $e');
    }
  }

  /// Start the tracker service
  Future<void> startTrackingService() async {
    try {
      await _channel.invokeMethod('startTrackingService');
    } catch (e) {
      developer.log('Error starting tracking service: $e');
    }
  }

  /// Stop the tracker service
  Future<void> stopTrackingService() async {
    try {
      await _channel.invokeMethod('stopTrackingService');
    } catch (e) {
      developer.log('Error stopping tracking service: $e');
    }
  }

  /// Get the currently active app
  Future<String> getCurrentApp() async {
    try {
      return await _channel.invokeMethod('getCurrentApp');
    } catch (e) {
      developer.log('Error getting current app: $e');
      return '';
    }
  }

  /// Dispose of the service
  void dispose() {
    _pollingTimer?.cancel();
    _appLaunchStreamController.close();
  }
}