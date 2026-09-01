import 'package:flinx/core/network/api_business_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('code zero is a business failure and skips typed data parsing', () {
    var parserCalled = false;

    final envelope = ApiEnvelopeDto<Map<String, dynamic>>.fromJson(
      const {
        'code': 0,
        'success': true,
        'data': {'id': 7},
        'msg': 'Legacy success code is no longer accepted',
      },
      (json) {
        parserCalled = true;
        return json as Map<String, dynamic>;
      },
    );

    expect(envelope.isBusinessSuccess, isFalse);
    expect(parserCalled, isFalse);
    expect(envelope.data, isNull);
    expect(envelope.msg, 'Legacy success code is no longer accepted');
  });

  test('code 200 with success false is a business failure', () {
    var parserCalled = false;

    final envelope = ApiEnvelopeDto<Map<String, dynamic>>.fromJson(
      const {
        'code': 200,
        'success': false,
        'data': {'id': 7},
        'message': 'Operation was rejected',
      },
      (json) {
        parserCalled = true;
        return json as Map<String, dynamic>;
      },
    );

    expect(envelope.isBusinessSuccess, isFalse);
    expect(parserCalled, isFalse);
    expect(envelope.data, isNull);
    expect(envelope.msg, 'Operation was rejected');
  });

  test('failed envelope with string data skips typed data parsing', () {
    var parserCalled = false;

    final envelope = ApiEnvelopeDto<Map<String, dynamic>>.fromJson(
      const {
        'code': 100408,
        'success': false,
        'data': '',
        'msg': '设备不存在',
        'messageKey': 'app.door.device_not_exists',
      },
      (json) {
        parserCalled = true;
        return json as Map<String, dynamic>;
      },
    );

    expect(parserCalled, isFalse);
    expect(envelope.code, 100408);
    expect(envelope.success, isFalse);
    expect(envelope.data, isNull);
    expect(envelope.msg, '设备不存在');
    expect(envelope.messageKey, 'app.door.device_not_exists');
  });

  test('successful envelope still parses typed data', () {
    final envelope = ApiEnvelopeDto<Map<String, dynamic>>.fromJson(const {
      'code': 200,
      'success': true,
      'data': {'id': 7},
    }, (json) => json as Map<String, dynamic>);

    expect(envelope.data, {'id': 7});
    expect(envelope.isBusinessSuccess, isTrue);
  });

  test('msg takes precedence over message and blank values fall back', () {
    final preferredMsg = ApiEnvelopeDto<void>.fromJson(
      const {
        'code': 500,
        'success': false,
        'msg': ' Primary message ',
        'message': 'Secondary message',
      },
      (_) {},
    );
    final fallbackMessage = ApiEnvelopeDto<void>.fromJson(
      const {
        'code': 500,
        'success': false,
        'msg': '   ',
        'message': ' Fallback message ',
        'messageKey': '   ',
      },
      (_) {},
    );

    expect(preferredMsg.msg, 'Primary message');
    expect(fallbackMessage.msg, 'Fallback message');
    expect(fallbackMessage.messageKey, isNull);
  });

  test('business failure normalizes server-provided fields', () {
    const envelope = ApiEnvelopeDto<void>(
      code: 100409,
      success: false,
      msg: '  Device is already bound.  ',
      messageKey: '  app.door.already_bound  ',
    );

    final failure = ApiBusinessFailure.fromEnvelope(envelope);

    expect(failure.code, 100409);
    expect(failure.message, 'Device is already bound.');
    expect(failure.messageKey, 'app.door.already_bound');
  });

  test('business failure converts blank messages to null', () {
    final failure = ApiBusinessFailure(
      code: 100500,
      message: '  ',
      messageKey: '\n',
    );

    expect(failure.message, isNull);
    expect(failure.messageKey, isNull);
  });
}
