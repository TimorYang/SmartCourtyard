import 'dart:convert';

import 'package:flinx/core/logging/app_logger.dart';
import 'package:flinx/features/push/data/engage_lab_push_gateway.dart';
import 'package:flinx/features/push/domain/entities/push_configuration.dart';
import 'package:flinx/features/push/domain/entities/push_event.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter_plugin_engagelab');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    messenger.setMockMethodCallHandler(channel, (_) async => null);
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('preserves custom-message extras from Android and iOS', () async {
    final gateway = EngageLabPushGateway(logger: const _TestLogger());
    addTearDown(gateway.dispose);
    await gateway.initialize(
      const PushConfiguration(
        appKey: 'test-app-key',
        channel: 'test',
        iosProduction: false,
      ),
    );

    final events = <PushCustomMessageReceived>[];
    final subscription = gateway.events.listen((event) {
      if (event is PushCustomMessageReceived) events.add(event);
    });
    addTearDown(subscription.cancel);

    await _emitCustomMessage(messenger, extrasKey: 'extras');
    await _emitCustomMessage(messenger, extrasKey: 'extra');
    await Future<void>.delayed(Duration.zero);

    expect(events, hasLength(2));
    expect(events[0].extras, <String, Object?>{'route': 'android-route'});
    expect(events[1].extras, <String, Object?>{'route': 'ios-route'});
  });
}

Future<void> _emitCustomMessage(
  TestDefaultBinaryMessenger messenger, {
  required String extrasKey,
}) {
  final platform = extrasKey == 'extras' ? 'android' : 'ios';
  return messenger.handlePlatformMessage(
    'flutter_plugin_engagelab',
    const StandardMethodCodec().encodeMethodCall(
      MethodCall('onMTCommonReceiver', <String, Object?>{
        'event_name': 'onCustomMessage',
        'event_data': jsonEncode(<String, Object?>{
          'messageId': '$platform-message',
          'title': '$platform-title',
          'content': '$platform-content',
          extrasKey: <String, Object?>{'route': '$platform-route'},
        }),
      }),
    ),
    null,
  );
}

class _TestLogger implements AppLogger {
  const _TestLogger();

  @override
  void info(
    String message, {
    AppLogTag tag = AppLogTag.general,
    String? flowId,
    String? requestId,
    Map<String, Object?> context = const {},
  }) {}

  @override
  void warning(
    String message, {
    AppLogTag tag = AppLogTag.general,
    String? flowId,
    String? requestId,
    Map<String, Object?> context = const {},
  }) {}

  @override
  void error(
    String message, {
    AppLogTag tag = AppLogTag.general,
    String? flowId,
    String? requestId,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {}
}
