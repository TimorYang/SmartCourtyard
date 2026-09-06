import 'device_setting.dart';

enum DeviceSettingsSnapshotOrigin { activeReport, queryResult }

class DeviceSettingsSnapshot {
  const DeviceSettingsSnapshot({
    required this.values,
    required this.origin,
    required this.sequence,
    required this.timestampMillis,
  });

  final Map<DeviceSettingKey, DeviceSettingValue> values;
  final DeviceSettingsSnapshotOrigin origin;
  final int sequence;
  final int timestampMillis;
}
