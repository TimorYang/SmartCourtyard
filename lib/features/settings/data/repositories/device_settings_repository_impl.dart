import 'dart:typed_data';

import '../../../../platform_bridge/hardware_gateway.dart';
import '../../../../platform_bridge/hardware_models.dart';
import '../../domain/entities/device_setting.dart';
import '../../domain/entities/device_settings_snapshot.dart';
import '../../domain/repositories/device_settings_repository.dart';

class DeviceSettingsRepositoryImpl implements DeviceSettingsRepository {
  const DeviceSettingsRepositoryImpl(this._gateway);

  final HardwareGateway _gateway;

  @override
  Stream<DeviceSettingsSnapshot> watchSettings({required String deviceId}) {
    return _gateway.deviceAttributeSnapshots
        .where((snapshot) => snapshot.deviceId == deviceId)
        .map(
          (snapshot) => DeviceSettingsSnapshot(
            values: _mapSnapshot(snapshot),
            origin: switch (snapshot.origin) {
              DeviceAttributeReportOrigin.activeReport =>
                DeviceSettingsSnapshotOrigin.activeReport,
              DeviceAttributeReportOrigin.queryResult =>
                DeviceSettingsSnapshotOrigin.queryResult,
            },
            sequence: snapshot.sequence,
            timestampMillis: snapshot.timestampMillis,
          ),
        );
  }

  @override
  Stream<void> watchDisconnections({required String deviceId}) {
    return _gateway.bleConnectionEvents
        .where(
          (event) =>
              event.deviceId == deviceId &&
              event.state == BleConnectionState.disconnected,
        )
        .map((_) {});
  }

  @override
  Future<Map<DeviceSettingKey, DeviceSettingValue>> querySettings({
    required String requestId,
    required String deviceId,
  }) async {
    final snapshot = await _gateway.queryDeviceAttributes(
      requestId: requestId,
      deviceId: deviceId,
    );
    return _mapSnapshot(snapshot);
  }

  @override
  Future<void> setSetting({
    required String requestId,
    required String deviceId,
    required DeviceSettingValue value,
  }) async {
    if (value.key == DeviceSettingKey.doorOpenReminder) {
      final result = await _gateway.setDoorOpenReminder(
        requestId: requestId,
        deviceId: deviceId,
        value: value.rawValue,
      );
      if (!result.accepted) {
        throw StateError(
          'Device rejected door open reminder command'
          '${result.domainCode == null ? '' : ' code=${result.domainCode}'}',
        );
      }
      return;
    }

    if (!value.key.writable) {
      throw StateError('Setting ${value.key.name} is read-only.');
    }

    final attributeId = value.key.attributeId;
    if (attributeId == null) {
      throw StateError('Setting ${value.key.name} has no attribute protocol.');
    }
    final protocolValue = value.key == DeviceSettingKey.autoCloseTime
        ? value.wireValue
        : value.key.toProtocolValue(value.rawValue);
    if (protocolValue == null) {
      throw StateError(
        'Auto-close writes require a complete 0x2712 wire value.',
      );
    }
    final bytes = Uint8List(value.key.protocolByteWidth);
    // 0x2713 write values remain 0x01-0x09. The tens representation is only
    // normalized when a newer firmware reports it through 0x0202.
    var remaining = protocolValue;
    for (var index = bytes.length - 1; index >= 0; index--) {
      bytes[index] = remaining & 0xFF;
      remaining >>= 8;
    }
    final result = await _gateway.setDeviceAttributes(
      requestId: requestId,
      deviceId: deviceId,
      attributes: <DeviceAttribute>[
        DeviceAttribute(id: attributeId, value: bytes),
      ],
    );
    if (!result.success) {
      throw StateError(
        'Device rejected attribute write'
        '${result.reasonCode == null ? '' : ' reason=${result.reasonCode}'}',
      );
    }
  }

  Map<DeviceSettingKey, DeviceSettingValue> _mapSnapshot(
    DeviceAttributeSnapshot snapshot,
  ) {
    final byId = <int, DeviceAttribute>{
      for (final attribute in snapshot.attributes) attribute.id: attribute,
    };
    final values = <DeviceSettingKey, DeviceSettingValue>{};
    for (final key in DeviceSettingKey.values) {
      if (key == DeviceSettingKey.autoCloseCondition ||
          key == DeviceSettingKey.autoCloseTime) {
        continue;
      }
      final attributeId = key.attributeId;
      if (attributeId == null) {
        continue;
      }
      final attribute = byId[attributeId];
      if (attribute == null) {
        continue;
      }
      // Keep the report's raw value for diagnostics; presentation normalizes
      // upgraded 0x2713 values through DeviceSettingKey.fromProtocolValue.
      values[key] = DeviceSettingValue(
        key: key,
        rawValue: attribute.unsignedValue,
        sourceAttributeId: attributeId,
      );
    }
    values.addAll(_mapAutoCloseValues(byId));
    return values;
  }

  Map<DeviceSettingKey, DeviceSettingValue> _mapAutoCloseValues(
    Map<int, DeviceAttribute> attributes,
  ) {
    final attribute2712 = attributes[0x2712];
    final attribute2725 = attributes[0x2725];
    final rawValue2712 = attribute2712?.value.length == 1
        ? attribute2712!.unsignedValue
        : null;
    // 0x2712 uses a composite value when written, but in a settings snapshot
    // it is a time source only. Position is always read independently from
    // 0x2714.
    final value2712 = AutoClosePosition.fromWireValue(rawValue2712) == null
        ? rawValue2712
        : rawValue2712! & 0x0F;
    final value2725 = attribute2725?.value.length == 2
        ? attribute2725!.unsignedValue
        : null;
    final preferredValue = value2712 ?? value2725;
    final sourceAttributeId = value2712 != null
        ? DeviceSettingKey.autoCloseTime.attributeId
        : DeviceSettingKey.autoCloseTime.legacyAttributeId;
    final autoCloseTime = preferredValue == null
        ? null
        : DeviceSettingValue(
            key: DeviceSettingKey.autoCloseTime,
            rawValue: preferredValue,
            candidateValues: List<int>.unmodifiable(
              <int?>[value2712, value2725].whereType<int>(),
            ),
            sourceAttributeId: sourceAttributeId,
          );

    final conditionAttribute = attributes[0x2714];
    final conditionValue = conditionAttribute?.value.length == 1
        ? DeviceSettingValue(
            key: DeviceSettingKey.autoCloseCondition,
            rawValue: conditionAttribute!.unsignedValue,
            sourceAttributeId: DeviceSettingKey.autoCloseCondition.attributeId,
          )
        : null;

    final values = <DeviceSettingKey, DeviceSettingValue>{};
    if (conditionValue != null) {
      values[DeviceSettingKey.autoCloseCondition] = conditionValue;
    }
    if (autoCloseTime != null) {
      values[DeviceSettingKey.autoCloseTime] = autoCloseTime;
    }
    return values;
  }
}
