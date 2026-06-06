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

  group('bleDebugHexString', () {
    test('shows none for empty bytes', () {
      expect(bleDebugHexString(const <int>[]), 'none');
    });

    test('renders full uppercase hex payloads', () {
      expect(bleDebugHexString(const <int>[0x12, 0xab, 0x00]), '12 AB 00');
      expect(
        bleDebugHexString(const <int>[0, 1, 2, 3, 4, 5, 6, 7, 8]),
        '00 01 02 03 04 05 06 07 08',
      );
    });
  });
}
