import '../../../../platform_bridge/hardware_models.dart';
import '../../domain/entities/door_realtime_state.dart';

class DoorRealtimeStateMapper {
  const DoorRealtimeStateMapper._();

  static const _doorStatusAttributeId = 0x2715;
  static const _doorPositionAttributeId = 0x271C;

  static DoorRealtimeStateParseResult parse(
    DeviceAttributeSnapshot snapshot, {
    DoorRealtimeState? previous,
  }) {
    var motorState = previous?.motorState;
    var positionPercent = previous?.positionPercent;
    var hasValidUpdate = false;
    var statusAttributeSeen = false;
    var positionAttributeSeen = false;
    int? rawStatus;
    int? rawPositionPercent;
    DoorMotorState? parsedMotorState;
    double? parsedPositionPercent;
    final issues = <String>[];

    for (final attribute in snapshot.attributes) {
      switch (attribute.id) {
        case _doorStatusAttributeId:
          statusAttributeSeen = true;
          if (attribute.value.length != 1) {
            issues.add(
              '0x2715 expected 1 byte, received ${attribute.value.length}',
            );
            continue;
          }
          rawStatus = attribute.unsignedValue;
          parsedMotorState = _motorStateFromRawValue(rawStatus);
          motorState = parsedMotorState;
          hasValidUpdate = true;
        case _doorPositionAttributeId:
          positionAttributeSeen = true;
          if (attribute.value.length != 1) {
            issues.add(
              '0x271C expected 1 byte, received ${attribute.value.length}',
            );
            continue;
          }
          rawPositionPercent = attribute.unsignedValue;
          if (rawPositionPercent <= 100) {
            parsedPositionPercent = rawPositionPercent.toDouble();
            positionPercent = parsedPositionPercent;
            hasValidUpdate = true;
          } else {
            issues.add('0x271C percentage out of range: $rawPositionPercent');
          }
      }
    }

    final status = _doorStatusFrom(
      motorState: motorState,
      positionPercent: positionPercent,
    );

    return DoorRealtimeStateParseResult(
      state: hasValidUpdate
          ? DoorRealtimeState(
              status: status,
              motorState: motorState,
              positionPercent: positionPercent,
            )
          : previous,
      statusAttributeSeen: statusAttributeSeen,
      positionAttributeSeen: positionAttributeSeen,
      rawStatus: rawStatus,
      rawPositionPercent: rawPositionPercent,
      parsedMotorState: parsedMotorState,
      parsedPositionPercent: parsedPositionPercent,
      hasValidUpdate: hasValidUpdate,
      statusMappingProfile: 'motor_and_position',
      issues: issues,
      attributeIds: snapshot.attributes
          .map((attribute) => _hex(attribute.id, width: 4))
          .toList(growable: false),
      relevantRawAttributes: snapshot.attributes
          .where(
            (attribute) =>
                attribute.id == _doorStatusAttributeId ||
                attribute.id == _doorPositionAttributeId,
          )
          .map(_formatAttribute)
          .toList(growable: false),
    );
  }

  static DoorMotorState _motorStateFromRawValue(int value) {
    return switch (value) {
      0x00 => DoorMotorState.opening,
      0x01 => DoorMotorState.stopped,
      0x02 => DoorMotorState.closing,
      _ => DoorMotorState.unknown,
    };
  }

  static DoorRealtimeStatus? _doorStatusFrom({
    required DoorMotorState? motorState,
    required double? positionPercent,
  }) {
    if (positionPercent == 0) {
      return DoorRealtimeStatus.closed;
    }
    if (positionPercent == 100) {
      return DoorRealtimeStatus.open;
    }
    return switch (motorState) {
      DoorMotorState.opening => DoorRealtimeStatus.opening,
      DoorMotorState.stopped => DoorRealtimeStatus.stopped,
      DoorMotorState.closing => DoorRealtimeStatus.closing,
      DoorMotorState.unknown => DoorRealtimeStatus.unknown,
      null => positionPercent == null ? null : DoorRealtimeStatus.unknown,
    };
  }

  static String _formatAttribute(DeviceAttribute attribute) {
    final value = attribute.value.map((byte) => _hex(byte, width: 2)).join(' ');
    return '${_hex(attribute.id, width: 4)}=[$value]';
  }

  static String _hex(int value, {required int width}) {
    return '0x${value.toRadixString(16).padLeft(width, '0').toUpperCase()}';
  }
}

class DoorRealtimeStateParseResult {
  DoorRealtimeStateParseResult({
    required this.state,
    required this.statusAttributeSeen,
    required this.positionAttributeSeen,
    required this.rawStatus,
    required this.rawPositionPercent,
    required this.parsedMotorState,
    required this.parsedPositionPercent,
    required this.hasValidUpdate,
    required this.statusMappingProfile,
    required List<String> issues,
    required List<String> attributeIds,
    required List<String> relevantRawAttributes,
  }) : issues = List.unmodifiable(issues),
       attributeIds = List.unmodifiable(attributeIds),
       relevantRawAttributes = List.unmodifiable(relevantRawAttributes);

  final DoorRealtimeState? state;
  final bool statusAttributeSeen;
  final bool positionAttributeSeen;
  final int? rawStatus;
  final int? rawPositionPercent;
  final DoorMotorState? parsedMotorState;
  final double? parsedPositionPercent;
  final bool hasValidUpdate;
  final String statusMappingProfile;
  final List<String> issues;
  final List<String> attributeIds;
  final List<String> relevantRawAttributes;

  bool get hasDoorAttributes => statusAttributeSeen || positionAttributeSeen;

  Map<String, Object?> get diagnosticContext => {
    'command': '0x0202',
    'attributeIds': attributeIds,
    'relevantRaw': relevantRawAttributes,
    'doorMotorRaw': rawStatus == null
        ? null
        : DoorRealtimeStateMapper._hex(rawStatus!, width: 2),
    'doorStatusMappingProfile': statusMappingProfile,
    'doorMotorParsed': parsedMotorState?.name,
    'doorPositionRaw': rawPositionPercent == null
        ? null
        : DoorRealtimeStateMapper._hex(rawPositionPercent!, width: 2),
    'doorPositionParsedPercent': parsedPositionPercent,
    'uiDoorStatusAfter': state?.status?.name,
    'uiDoorPositionAfterPercent': state?.positionPercent,
    'statusAttributeSeen': statusAttributeSeen,
    'positionAttributeSeen': positionAttributeSeen,
    'issues': issues,
  };
}
