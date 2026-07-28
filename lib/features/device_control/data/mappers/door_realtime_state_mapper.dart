import '../../../../platform_bridge/hardware_models.dart';
import '../../domain/entities/door_realtime_state.dart';

class DoorRealtimeStateMapper {
  const DoorRealtimeStateMapper._();

  static const _doorStatusAttributeId = 0x2715;
  static const _doorPositionAttributeId = 0x271C;

  static DoorRealtimeStateParseResult parse(
    DeviceAttributeSnapshot snapshot, {
    DoorRealtimeState? previous,
    required bool isDongle,
  }) {
    var status = previous?.status;
    var positionPercent = previous?.positionPercent;
    var hasValidUpdate = false;
    var statusAttributeSeen = false;
    var positionAttributeSeen = false;
    int? rawStatus;
    int? rawPositionPercent;
    DoorRealtimeStatus? parsedStatus;
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
          parsedStatus = _statusFromRawValue(rawStatus, isDongle: isDongle);
          status = parsedStatus;
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

    return DoorRealtimeStateParseResult(
      state: hasValidUpdate
          ? DoorRealtimeState(status: status, positionPercent: positionPercent)
          : previous,
      statusAttributeSeen: statusAttributeSeen,
      positionAttributeSeen: positionAttributeSeen,
      rawStatus: rawStatus,
      rawPositionPercent: rawPositionPercent,
      parsedStatus: parsedStatus,
      parsedPositionPercent: parsedPositionPercent,
      hasValidUpdate: hasValidUpdate,
      statusMappingProfile: isDongle ? 'dongle' : 'standard',
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

  static DoorRealtimeStatus _statusFromRawValue(
    int value, {
    required bool isDongle,
  }) {
    if (isDongle) {
      return switch (value) {
        0x00 => DoorRealtimeStatus.open,
        0x02 => DoorRealtimeStatus.closed,
        0x01 => DoorRealtimeStatus.stopped,
        _ => DoorRealtimeStatus.unknown,
      };
    }
    return switch (value) {
      0x00 => DoorRealtimeStatus.open,
      0x01 => DoorRealtimeStatus.closed,
      0x02 => DoorRealtimeStatus.stopped,
      0x03 => DoorRealtimeStatus.opening,
      0x04 => DoorRealtimeStatus.closing,
      0x05 => DoorRealtimeStatus.running,
      _ => DoorRealtimeStatus.unknown,
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
    required this.parsedStatus,
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
  final DoorRealtimeStatus? parsedStatus;
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
    'doorStatusRaw': rawStatus == null
        ? null
        : DoorRealtimeStateMapper._hex(rawStatus!, width: 2),
    'doorStatusMappingProfile': statusMappingProfile,
    'doorStatusParsed': parsedStatus?.name,
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
