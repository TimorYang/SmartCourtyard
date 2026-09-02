import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_plugin_engagelab/flutter_plugin_engagelab.dart';

import '../../../core/logging/app_logger.dart';
import '../domain/entities/push_configuration.dart';
import '../domain/entities/push_event.dart';
import '../domain/services/push_gateway.dart';

class EngageLabPushGateway implements PushGateway {
  EngageLabPushGateway({required this._logger});

  final AppLogger _logger;
  final StreamController<PushEvent> _eventController =
      StreamController<PushEvent>.broadcast();
  bool _eventHandlerRegistered = false;
  bool _initialized = false;

  @override
  Stream<PushEvent> get events => _eventController.stream;

  @override
  Future<void> initialize(PushConfiguration configuration) async {
    if (_initialized) return;

    if (!_eventHandlerRegistered) {
      FlutterPluginEngagelab.addEventHandler(
        onMTCommonReceiver: _handlePluginEvent,
      );
      _eventHandlerRegistered = true;
    }

    // Keep the vendor SDK's own logging disabled. Its debug output includes
    // registration IDs, device tokens, and complete event payloads.
    FlutterPluginEngagelab.configDebugMode(false);
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      FlutterPluginEngagelab.initIos(
        appKey: configuration.appKey,
        channel: configuration.effectiveChannel,
        isProduction: configuration.iosProduction,
      );
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      FlutterPluginEngagelab.initAndroid();
    } else {
      throw UnsupportedError('EngageLab push is supported on mobile only.');
    }
    _initialized = true;
  }

  @override
  Future<String?> getRegistrationId() async {
    final registrationId = await FlutterPluginEngagelab.getRegistrationId();
    return registrationId.trim().isEmpty ? null : registrationId;
  }

  @override
  Future<void> dispose() async {
    _initialized = false;
    await _eventController.close();
  }

  Future<dynamic> _handlePluginEvent(Map<String, dynamic> message) async {
    final event = _parseEvent(message);
    if (event != null && !_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  PushEvent? _parseEvent(Map<String, dynamic> message) {
    final name = message['event_name'];
    if (name is! String || name.trim().isEmpty) {
      _logIgnoredEvent('missing_event_name');
      return null;
    }

    final payload = _decodePayload(message['event_data']);
    if (payload == null) {
      _logIgnoredEvent('invalid_event_data');
      return null;
    }

    switch (name) {
      case 'onConnectStatus':
      case 'networkDidLogin':
        return PushConnectionChanged(connected: payload['enable'] == true);
      case 'onNotificationArrived':
        return _notificationEvent(payload, clicked: false);
      case 'onNotificationClicked':
        return _notificationEvent(payload, clicked: true);
      case 'onCustomMessage':
        return PushCustomMessageReceived(
          messageId: _stringValue(payload['messageId']),
          title: _stringValue(payload['title']),
          content: _stringValue(payload['content']),
          // Android emits `extras`, while the iOS plugin emits `extra`.
          extras: _extrasValue(payload['extras'] ?? payload['extra']),
        );
      case 'onPlatformToken':
        final token = _stringValue(payload['token']);
        if (token == null) {
          _logIgnoredEvent('missing_platform_token');
          return null;
        }
        return PushPlatformTokenReceived(
          platform: _stringValue(payload['platform']),
          token: token,
        );
      case 'onReceiveDeviceToken':
        final token = _stringValue(payload['deviceToken']);
        if (token == null) {
          _logIgnoredEvent('missing_device_token');
          return null;
        }
        return PushDeviceTokenReceived(token: token);
      default:
        _logIgnoredEvent('unsupported_event');
        return null;
    }
  }

  PushEvent _notificationEvent(
    Map<String, Object?> payload, {
    required bool clicked,
  }) {
    final arguments = <String, Object?>{
      'messageId': _stringValue(payload['messageId']),
      'title': _stringValue(payload['title']),
      'content': _stringValue(payload['content']),
      'extras': _extrasValue(payload['extras']),
    };
    if (clicked) {
      return PushNotificationClicked(
        messageId: arguments['messageId'] as String?,
        title: arguments['title'] as String?,
        content: arguments['content'] as String?,
        extras: arguments['extras']! as Map<String, Object?>,
      );
    }
    return PushNotificationArrived(
      messageId: arguments['messageId'] as String?,
      title: arguments['title'] as String?,
      content: arguments['content'] as String?,
      extras: arguments['extras']! as Map<String, Object?>,
    );
  }

  Map<String, Object?>? _decodePayload(Object? raw) {
    Object? decoded = raw;
    if (raw is String) {
      try {
        decoded = jsonDecode(raw);
      } on FormatException {
        return null;
      }
    }
    if (decoded is! Map) return null;
    return _mapValue(decoded);
  }

  Map<String, Object?> _mapValue(Map<dynamic, dynamic> value) {
    return value.map<String, Object?>((key, item) {
      return MapEntry(key.toString(), _normalizeValue(item));
    });
  }

  Object? _normalizeValue(Object? value) {
    if (value is Map) return _mapValue(value);
    if (value is List) {
      return value.map<Object?>(_normalizeValue).toList(growable: false);
    }
    return value;
  }

  String? _stringValue(Object? value) {
    if (value is! String) return null;
    final result = value.trim();
    return result.isEmpty ? null : result;
  }

  Map<String, Object?> _extrasValue(Object? value) {
    if (value is Map) return Map.unmodifiable(_mapValue(value));
    return const <String, Object?>{};
  }

  void _logIgnoredEvent(String reason) {
    _logger.warning(
      'push_event_ignored',
      tag: AppLogTag.push,
      context: <String, Object?>{'reason': reason},
    );
  }
}
