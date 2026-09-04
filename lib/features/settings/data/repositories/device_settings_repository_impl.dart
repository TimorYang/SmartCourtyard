import 'dart:typed_data';

import '../../../../platform_bridge/hardware_gateway.dart';
import '../../../../platform_bridge/hardware_models.dart';
import '../../domain/entities/device_setting.dart';
import '../../domain/repositories/device_settings_repository.dart';

class DeviceSettingsRepositoryImpl implements DeviceSettingsRepository {
  const DeviceSettingsRepositoryImpl(this._gateway);

  final HardwareGateway _gateway;

  @override
  Stream<Map<DeviceSettingKey, DeviceSettingValue>> watchSettings({
    required String deviceId,
  }) {
    return _gateway.deviceAttributeSnapshots
        .where((snapshot) => snapshot.deviceId == deviceId)
        .map(_mapSnapshot);
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

    final attributeId = value.key.attributeId;
    if (attributeId == null) {
      throw StateError('Setting ${value.key.name} has no attribute protocol.');
    }
    final bytes = Uint8List(value.key.byteWidth);
    // 0x2713 write values remain 0x01-0x09. The tens representation is only
    // normalized when a newer firmware reports it through 0x0202.
    var remaining = value.key.toProtocolValue(value.rawValue);
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
      if (key == DeviceSettingKey.autoCloseTime) {
        final autoCloseValue = _mapAutoCloseValue(byId);
        if (autoCloseValue != null) {
          values[key] = autoCloseValue;
        }
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
    return values;
  }

  DeviceSettingValue? _mapAutoCloseValue(Map<int, DeviceAttribute> attributes) {
    final attribute2712 = attributes[0x2712];
    final attribute2725 = attributes[0x2725];
    final value2712 = attribute2712?.value.length == 1
        ? attribute2712!.unsignedValue
        : null;
    final value2725 = attribute2725?.value.length == 2
        ? attribute2725!.unsignedValue
        : null;
    final preferredValue = value2712 ?? value2725;
    final sourceAttributeId = value2712 != null
        ? DeviceSettingKey.autoCloseTime.attributeId
        : DeviceSettingKey.autoCloseTime.legacyAttributeId;
    if (preferredValue == null) {
      return null;
    }
    final candidateValues = <int>[?value2712, ?value2725];
    return DeviceSettingValue(
      key: DeviceSettingKey.autoCloseTime,
      rawValue: preferredValue,
      candidateValues: List<int>.unmodifiable(candidateValues),
      sourceAttributeId: sourceAttributeId,
    );
  }
}
