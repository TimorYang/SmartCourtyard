import 'package:flinx/features/add_device/application/smart_opener_qr_payload_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('extracts the Smart Opener serial number before the separator', () {
    expect(
      parseSmartOpenerSerialNumber(
        'opener_B8F86211A9DC#SPT#opener_B8F86211A9DC',
      ),
      'opener_B8F86211A9DC',
    );

    for (final prefix in <String>['Noru_', 'evo_', 'Fbox_']) {
      final serialNumber = '${prefix}B8F86211A9DC';
      expect(
        parseSmartOpenerSerialNumber('$serialNumber#SPT#$serialNumber'),
        serialNumber,
      );
    }
  });

  test('rejects missing separator, empty serial number, and other devices', () {
    expect(parseSmartOpenerSerialNumber('opener_B8F86211A9DC'), isNull);
    expect(parseSmartOpenerSerialNumber('#SPT#opener_B8F86211A9DC'), isNull);
    expect(parseSmartOpenerSerialNumber('device_001#SPT#device_001'), isNull);
  });
}
