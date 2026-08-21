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
    var remaining = value.rawValue;
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
    return <DeviceSettingKey, DeviceSettingValue>{
      for (final key in DeviceSettingKey.values)
        if (key.attributeId case final attributeId?)
          if (byId[attributeId] case final attribute?)
            key: DeviceSettingValue(
              key: key,
              rawValue: attribute.unsignedValue,
            ),
    };
  }
}
