import 'dart:typed_data';

import 'package:flinx/features/device_control/data/mappers/door_realtime_state_mapper.dart';
import 'package:flinx/features/device_control/domain/entities/door_realtime_state.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps door status and percentage from a 0x0202 attribute snapshot', () {
    final result = DoorRealtimeStateMapper.parse(
      _snapshot([_attribute(0x2715, 0x03), _attribute(0x271C, 42)]),
    );

    expect(result.state?.status, DoorRealtimeStatus.opening);
    expect(result.state?.positionPercent, 42);
    expect(result.diagnosticContext, {
      'command': '0x0202',
      'attributeIds': ['0x2715', '0x271C'],
      'relevantRaw': ['0x2715=[0x03]', '0x271C=[0x2A]'],
      'doorStatusRaw': '0x03',
      'doorStatusMappingProfile': 'unified',
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
    );

    expect(result.state?.status, DoorRealtimeStatus.closing);
    expect(result.state?.positionPercent, 42);
    expect(result.issues, ['0x271C percentage out of range: 255']);
  });

  test('uses the unified open, stopped, and closed values', () {
    final open = DoorRealtimeStateMapper.parse(
      _snapshot([_attribute(0x2715, 0x00)]),
    );
    final stopped = DoorRealtimeStateMapper.parse(
      _snapshot([_attribute(0x2715, 0x01)]),
    );
    final closed = DoorRealtimeStateMapper.parse(
      _snapshot([_attribute(0x2715, 0x02)]),
    );

    expect(open.state?.status, DoorRealtimeStatus.open);
    expect(stopped.state?.status, DoorRealtimeStatus.stopped);
    expect(closed.state?.status, DoorRealtimeStatus.closed);
    expect(closed.statusMappingProfile, 'unified');
  });

  test('treats open and closed as moving between position endpoints', () {
    final opening = DoorRealtimeStateMapper.parse(
      _snapshot([_attribute(0x2715, 0x00), _attribute(0x271C, 42)]),
    );
    final closing = DoorRealtimeStateMapper.parse(
      _snapshot([_attribute(0x2715, 0x02), _attribute(0x271C, 42)]),
    );

    expect(opening.parsedStatus, DoorRealtimeStatus.open);
    expect(opening.state?.status, DoorRealtimeStatus.opening);
    expect(closing.parsedStatus, DoorRealtimeStatus.closed);
    expect(closing.state?.status, DoorRealtimeStatus.closing);
  });

  test('keeps open and closed at position endpoints', () {
    final open = DoorRealtimeStateMapper.parse(
      _snapshot([_attribute(0x2715, 0x00), _attribute(0x271C, 100)]),
    );
    final closed = DoorRealtimeStateMapper.parse(
      _snapshot([_attribute(0x2715, 0x02), _attribute(0x271C, 0)]),
    );

    expect(open.state?.status, DoorRealtimeStatus.open);
    expect(closed.state?.status, DoorRealtimeStatus.closed);
  });

  test('adjusts state when status and position arrive separately', () {
    const previous = DoorRealtimeState(
      status: DoorRealtimeStatus.open,
      positionPercent: 100,
    );

    final result = DoorRealtimeStateMapper.parse(
      _snapshot([_attribute(0x271C, 42)]),
      previous: previous,
    );

    expect(result.state?.status, DoorRealtimeStatus.opening);
    expect(result.state?.positionPercent, 42);
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
