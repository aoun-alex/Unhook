import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;

class UsageBroadcastReceiver {
  static final UsageBroadcastReceiver _instance = UsageBroadcastReceiver._internal();

  factory UsageBroadcastReceiver() {
    return _instance;
  }

  UsageBroadcastReceiver._internal();

  static const EventChannel _eventChannel = EventChannel('com.example.unhook/usage_events');

  final StreamController<UsageEvent> _eventController = StreamController<UsageEvent>.broadcast();
  Stream<UsageEvent> get events => _eventController.stream;

  StreamSubscription? _eventSubscription;

  void initialize() {
    _eventSubscription = _eventChannel
        .receiveBroadcastStream()
        .listen(_onEvent, onError: _onError);

    developer.log('Usage broadcast receiver initialized');
  }

  void _onEvent(dynamic event) {
    if (event is! Map) {
      developer.log('Received non-map event: $event');
      return;
    }

    final Map<dynamic, dynamic> eventMap = event;
    final String type = eventMap['type'];

    switch (type) {
      case 'usage_update':
        _eventController.add(UsageUpdateEvent(
          packageName: eventMap['packageName'],
          usageMinutes: eventMap['usageMinutes'],
          limitReached: eventMap['limitReached'],
        ));
        break;

      case 'check_all_apps':
        _eventController.add(CheckAllAppsEvent());
        break;

      case 'reset_usage_data':
        _eventController.add(ResetUsageDataEvent());
        break;

      default:
        developer.log('Unknown event type: $type');
    }
  }

  void _onError(Object error) {
    developer.log('Error from event channel: $error');
  }

  void dispose() {
    _eventSubscription?.cancel();
    _eventController.close();
  }
}

// Event classes
abstract class UsageEvent {}

class UsageUpdateEvent extends UsageEvent {
  final String packageName;
  final int usageMinutes;
  final bool limitReached;

  UsageUpdateEvent({
    required this.packageName,
    required this.usageMinutes,
    required this.limitReached,
  });

  @override
  String toString() => 'UsageUpdateEvent{packageName: $packageName, usageMinutes: $usageMinutes, limitReached: $limitReached}';
}

class CheckAllAppsEvent extends UsageEvent {}

class ResetUsageDataEvent extends UsageEvent {}