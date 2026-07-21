import 'package:flinx/core/logging/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the selected tag and redacts credentials', () {
    final output = <String>[];
    final originalDebugPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) output.add(message);
    };
    addTearDown(() => debugPrint = originalDebugPrint);

    const DebugAppLogger().info(
      'authentication_started',
      tag: AppLogTag.binding,
      flowId: 'flow-1',
      requestId: 'flow-1:auth:1',
      context: const {
        'aesKey': '00112233445566778899AABBCCDDEEFF',
        'token': 'secret-token',
        'wifiPassword': 'secret-password',
        'aesKeyVersion': 'v2',
      },
    );

    final line = output.single;
    expect(line, contains('[FLINX_BIND]'));
    expect(line, contains('onboardingFlowId=flow-1'));
    expect(line, contains('aesKeyVersion: v2'));
    expect(line, isNot(contains('00112233445566778899AABBCCDDEEFF')));
    expect(line, isNot(contains('secret-token')));
    expect(line, isNot(contains('secret-password')));
  });
}
