import 'dart:typed_data';

import 'package:flinx/features/device_control/data/mappers/door_realtime_state_mapper.dart';
import 'package:flinx/features/device_control/domain/entities/door_realtime_state.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps door status and percentage from a 0x0202 attribute snapshot', () {
    final result = DoorRealtimeStateMapper.parse(
      _snapshot([_attribute(0x2715, 0x00), _attribute(0x271C, 42)]),
    );

    expect(result.state?.status, DoorRealtimeStatus.opening);
    expect(result.state?.motorState, DoorMotorState.opening);
    expect(result.state?.positionPercent, 42);
    expect(result.diagnosticContext, {
      'command': '0x0202',
      'attributeIds': ['0x2715', '0x271C'],
      'relevantRaw': ['0x2715=[0x00]', '0x271C=[0x2A]'],
      'doorMotorRaw': '0x00',
      'doorStatusMappingProfile': 'motor_and_position',
      'doorMotorParsed': 'opening',
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
      motorState: DoorMotorState.opening,
      positionPercent: 42,
    );

    final result = DoorRealtimeStateMapper.parse(
      _snapshot([_attribute(0x2715, 0x02), _attribute(0x271C, 0xFF)]),
      previous: previous,
    );

    expect(result.state?.status, DoorRealtimeStatus.closing);
    expect(result.state?.motorState, DoorMotorState.closing);
    expect(result.state?.positionPercent, 42);
    expect(result.issues, ['0x271C percentage out of range: 255']);
  });

  test('uses 0x2715 as motor state between position endpoints', () {
    final opening = DoorRealtimeStateMapper.parse(
      _snapshot([_attribute(0x2715, 0x00), _attribute(0x271C, 50)]),
    );
    final stopped = DoorRealtimeStateMapper.parse(
      _snapshot([_attribute(0x2715, 0x01), _attribute(0x271C, 50)]),
    );
    final closing = DoorRealtimeStateMapper.parse(
      _snapshot([_attribute(0x2715, 0x02), _attribute(0x271C, 50)]),
    );

    expect(opening.state?.status, DoorRealtimeStatus.opening);
    expect(stopped.state?.status, DoorRealtimeStatus.stopped);
    expect(closing.state?.status, DoorRealtimeStatus.closing);
    expect(closing.statusMappingProfile, 'motor_and_position');
  });

  test('position endpoints override the reported motor state', () {
    final open = DoorRealtimeStateMapper.parse(
      _snapshot([_attribute(0x2715, 0x02), _attribute(0x271C, 0)]),
    );
    final closed = DoorRealtimeStateMapper.parse(
      _snapshot([_attribute(0x2715, 0x00), _attribute(0x271C, 100)]),
    );

    expect(open.state?.status, DoorRealtimeStatus.open);
    expect(open.state?.motorState, DoorMotorState.closing);
    expect(closed.state?.status, DoorRealtimeStatus.closed);
    expect(closed.state?.motorState, DoorMotorState.opening);
  });

  test('combines 0x2715 and 0x271C when they arrive separately', () {
    final motorOnly = DoorRealtimeStateMapper.parse(
      _snapshot([_attribute(0x2715, 0x02)]),
    );
    final atOpenEndpoint = DoorRealtimeStateMapper.parse(
      _snapshot([_attribute(0x271C, 0)]),
      previous: motorOnly.state,
    );
    final changedMotor = DoorRealtimeStateMapper.parse(
      _snapshot([_attribute(0x2715, 0x00)]),
      previous: atOpenEndpoint.state,
    );
    final moving = DoorRealtimeStateMapper.parse(
      _snapshot([_attribute(0x271C, 42)]),
      previous: changedMotor.state,
    );

    expect(motorOnly.state?.status, DoorRealtimeStatus.closing);
    expect(atOpenEndpoint.state?.status, DoorRealtimeStatus.open);
    expect(changedMotor.state?.status, DoorRealtimeStatus.open);
    expect(moving.state?.status, DoorRealtimeStatus.opening);
    expect(moving.state?.motorState, DoorMotorState.opening);
    expect(moving.state?.positionPercent, 42);
  });

  test('maps an unknown motor value to unknown away from endpoints', () {
    final result = DoorRealtimeStateMapper.parse(
      _snapshot([_attribute(0x2715, 0x03), _attribute(0x271C, 42)]),
    );

    expect(result.state?.status, DoorRealtimeStatus.unknown);
    expect(result.state?.motorState, DoorMotorState.unknown);
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
