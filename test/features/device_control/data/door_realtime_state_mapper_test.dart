import 'dart:typed_data';

import 'package:flinx/features/device_control/data/mappers/door_realtime_state_mapper.dart';
import 'package:flinx/features/device_control/domain/entities/door_realtime_state.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps door status and percentage from a 0x0202 attribute snapshot', () {
    final result = DoorRealtimeStateMapper.parse(
      _snapshot([_attribute(0x2715, 0x03), _attribute(0x271C, 42)]),
      isDongle: false,
    );

    expect(result.state?.status, DoorRealtimeStatus.opening);
    expect(result.state?.positionPercent, 42);
    expect(result.diagnosticContext, {
      'command': '0x0202',
      'attributeIds': ['0x2715', '0x271C'],
      'relevantRaw': ['0x2715=[0x03]', '0x271C=[0x2A]'],
      'doorStatusRaw': '0x03',
      'doorStatusMappingProfile': 'standard',
      'doorStatusParsed': 'opening',
      'doorPositionRaw': '0x2A',
      'doorPositionParsedPercent': 42.0,
      'uiDoorStatusAfter': 'opening',
      'uiDoorPositionAfterPercent': 42.0,
      'statusAttributeSeen': true,
      'positionAttributeSeen': true,
      'issues': <String>[],
    });
  });

  test('merges partial reports and ignores invalid percentages', () {
    const previous = DoorRealtimeState(
      status: DoorRealtimeStatus.opening,
      positionPercent: 42,
    );

    final result = DoorRealtimeStateMapper.parse(
      _snapshot([_attribute(0x2715, 0x04), _attribute(0x271C, 0xFF)]),
      previous: previous,
      isDongle: false,
    );

    expect(result.state?.status, DoorRealtimeStatus.closing);
    expect(result.state?.positionPercent, 42);
    expect(result.issues, ['0x271C percentage out of range: 255']);
  });

  test('keeps standard stopped and closed values distinct', () {
    final closed = DoorRealtimeStateMapper.parse(
      _snapshot([_attribute(0x2715, 0x01)]),
      isDongle: false,
    );
    final stopped = DoorRealtimeStateMapper.parse(
      _snapshot([_attribute(0x2715, 0x02)]),
      isDongle: false,
    );

    expect(closed.state?.status, DoorRealtimeStatus.closed);
    expect(stopped.state?.status, DoorRealtimeStatus.stopped);
    expect(closed.statusMappingProfile, 'standard');
  });

  test('uses reversed stopped and closed values for dongle', () {
    final stopped = DoorRealtimeStateMapper.parse(
      _snapshot([_attribute(0x2715, 0x01)]),
      isDongle: true,
    );
    final closed = DoorRealtimeStateMapper.parse(
      _snapshot([_attribute(0x2715, 0x02)]),
      isDongle: true,
    );

    expect(stopped.state?.status, DoorRealtimeStatus.stopped);
    expect(closed.state?.status, DoorRealtimeStatus.closed);
    expect(closed.statusMappingProfile, 'dongle');
  });
}

DeviceAttributeSnapshot _snapshot(List<DeviceAttribute> attributes) {
  return DeviceAttributeSnapshot(
    deviceId: 'device-1',
    sequence: 1,
    timestampMillis: 1,
    origin: DeviceAttributeReportOrigin.activeReport,
    attributes: attributes,
  );
}

DeviceAttribute _attribute(int id, int value) {
  return DeviceAttribute(id: id, value: Uint8List.fromList([value]));
}
