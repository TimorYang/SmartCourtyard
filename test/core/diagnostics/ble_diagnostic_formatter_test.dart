import 'dart:typed_data';

import 'package:flinx/core/diagnostics/ble_diagnostic_formatter.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats and correlates TX and RX with one display number', () {
    final formatter = BleDiagnosticFormatter();
    final tx = formatter.format(
      _event(
        direction: BleDiagnosticDirection.tx,
        timestampMillis: 1_753_251_798_352,
      ),
    );
    final rx = formatter.format(
      _event(
        direction: BleDiagnosticDirection.rx,
        timestampMillis: 1_753_251_798_479,
        elapsedMillis: 127,
        result: 'success',
      ),
    );

    expect(tx, contains('📤 BLE TX'));
    expect(tx, contains('#000001'));
    expect(tx, contains('Operation   : Open Door'));
    expect(tx, contains('Type        : 0x03 (Request)'));
    expect(tx, contains('Command     : 0x0005'));
    expect(tx, contains('Control     : 0x1001'));
    expect(tx, contains('Sequence    : 0x0018 (24)'));
    expect(tx, contains('AES-128-ECB-PKCS7'));
    expect(tx, contains('03001800051001'));
    expect(tx, contains('Data\n'));
    expect(tx, contains('1001'));
    expect(tx, contains('5555001801F2A91C76AAAA'));

    expect(rx, contains('📥 BLE RX'));
    expect(rx, contains('#000001'));
    expect(rx, contains('Elapsed     : 127 ms'));
    expect(rx, contains('Type        : 0x04 (Response)'));
    expect(rx, contains('Decrypted Protocol Payload'));
    expect(rx, contains('040018000500'));
    expect(rx, contains('✅ Success'));
  });

  test('marks an RX without a pending TX as unmatched', () {
    final output = BleDiagnosticFormatter().format(
      _event(
        direction: BleDiagnosticDirection.rx,
        timestampMillis: 1_753_251_798_479,
      ),
    );

    expect(output, contains('Elapsed     : unknown'));
    expect(output, contains('⚠️ Unmatched'));
  });

  test('shows an explicit empty Data section', () {
    final output = BleDiagnosticFormatter().format(
      BleDiagnosticEvent(
        direction: BleDiagnosticDirection.rx,
        timestampMillis: 1_753_251_798_479,
        transactionId: 'device:5:25',
        deviceId: 'device',
        operation: 'Unknown Response',
        command: 0x0005,
        sequence: 25,
        encryption: 'None',
        originPayload: Uint8List(0),
        encryptedPayload: Uint8List(0),
        decryptedPayload: Uint8List.fromList([0x04, 0x00, 0x19, 0x00, 0x05]),
        packet: Uint8List.fromList([
          0x55,
          0x55,
          0x00,
          0x0D,
          0x00,
          0x04,
          0x00,
          0x19,
          0x00,
          0x05,
          0xD7,
          0xAA,
          0xAA,
        ]),
      ),
    );

    expect(output, contains('Data\n${'─' * 60}\nnone'));
  });

  test('shows a Wi-Fi provisioning response code as hexadecimal', () {
    final output = BleDiagnosticFormatter().format(
      BleDiagnosticEvent(
        direction: BleDiagnosticDirection.rx,
        timestampMillis: 1_753_251_798_479,
        transactionId: 'device:3586:3',
        deviceId: 'device',
        operation: 'Configure Wi-Fi Ack',
        command: 0x0E02,
        sequence: 3,
        encryption: 'None',
        originPayload: Uint8List(0),
        encryptedPayload: Uint8List(0),
        decryptedPayload: Uint8List.fromList([
          0x04,
          0x00,
          0x03,
          0x0E,
          0x02,
          0x00,
        ]),
        packet: Uint8List(0),
      ),
    );

    expect(output, contains('Data\n${'─' * 60}\n00'));
  });

  test(
    'shows Wi-Fi provisioning payload when diagnostic logging is enabled',
    () {
      final output = BleDiagnosticFormatter().format(
        BleDiagnosticEvent(
          direction: BleDiagnosticDirection.tx,
          timestampMillis: 1_753_251_798_479,
          transactionId: 'device:3586:3',
          deviceId: 'device',
          operation: 'Configure Wi-Fi',
          command: 0x0E02,
          sequence: 3,
          encryption: 'None',
          originPayload: Uint8List.fromList([
            0x03,
            0x00,
            0x03,
            0x0E,
            0x02,
            0x7B,
            0x22,
            0x73,
            0x73,
            0x69,
            0x64,
            0x22,
            0x3A,
            0x22,
            0x6D,
            0x79,
            0x2D,
            0x77,
            0x69,
            0x66,
            0x69,
            0x22,
            0x2C,
            0x22,
            0x70,
            0x77,
            0x64,
            0x22,
            0x3A,
            0x22,
            0x31,
            0x32,
            0x33,
            0x34,
            0x35,
            0x36,
            0x22,
            0x7D,
          ]),
          encryptedPayload: Uint8List(0),
          decryptedPayload: Uint8List(0),
          packet: Uint8List.fromList(List<int>.filled(46, 0)),
        ),
      );

      expect(output, contains('Length      : 46 bytes'));
      expect(
        output,
        contains(
          '7B2273736964223A226D792D77696669222C22707764223A22313233343536227D',
        ),
      );
      expect(output, contains('UTF-8 JSON: {"ssid":"my-wifi","pwd":"123456"}'));
    },
  );
}

BleDiagnosticEvent _event({
  required BleDiagnosticDirection direction,
  required int timestampMillis,
  int? elapsedMillis,
  String? result,
}) {
  return BleDiagnosticEvent(
    direction: direction,
    timestampMillis: timestampMillis,
    transactionId: 'device:5:24',
    requestId: 'door-open-1',
    deviceId: 'device',
    operation: direction == BleDiagnosticDirection.tx
        ? 'Open Door'
        : 'Open Door Ack',
    command: 0x0005,
    control: 0x1001,
    sequence: 24,
    encryption: 'AES-128-ECB-PKCS7',
    originPayload: Uint8List.fromList([
      0x03,
      0x00,
      0x18,
      0x00,
      0x05,
      0x10,
      0x01,
    ]),
    encryptedPayload: Uint8List.fromList([0xF2, 0xA9, 0x1C, 0x76]),
    decryptedPayload: Uint8List.fromList([0x04, 0x00, 0x18, 0x00, 0x05, 0x00]),
    packet: Uint8List.fromList([
      0x55,
      0x55,
      0x00,
      0x18,
      0x01,
      0xF2,
      0xA9,
      0x1C,
      0x76,
      0xAA,
      0xAA,
    ]),
    elapsedMillis: elapsedMillis,
    result: result,
  );
}
