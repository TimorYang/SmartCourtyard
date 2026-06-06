import 'package:flutter_test/flutter_test.dart';
import 'package:flinx/features/hardware_debug/presentation/pages/ble_debug_page.dart';

void main() {
  group('matchesBleDebugTargetName', () {
    test('matches exact target name case-insensitively', () {
      expect(matchesBleDebugTargetName('HEMS_Controller'), isTrue);
      expect(matchesBleDebugTargetName('hems_controller'), isTrue);
      expect(matchesBleDebugTargetName(' HEMS_Controller '), isTrue);
    });

    test('matches target name prefix with suffixes', () {
      expect(matchesBleDebugTargetName('HEMS_Controller_01'), isTrue);
      expect(matchesBleDebugTargetName('hems_controller test'), isTrue);
    });

    test('rejects null, empty, and non-matching names', () {
      expect(matchesBleDebugTargetName(null), isFalse);
      expect(matchesBleDebugTargetName(''), isFalse);
      expect(matchesBleDebugTargetName('FLINX_Device'), isFalse);
    });
  });

  group('bleDebugHexPreview', () {
    test('shows none for empty bytes', () {
      expect(bleDebugHexPreview(const <int>[]), 'none');
    });

    test('renders uppercase hex and truncates long payloads', () {
      expect(bleDebugHexPreview(const <int>[0x12, 0xab, 0x00]), '12 AB 00');
      expect(
        bleDebugHexPreview(const <int>[0, 1, 2, 3, 4, 5, 6, 7, 8], maxBytes: 4),
        '00 01 02 03 ...',
      );
    });
  });
}
