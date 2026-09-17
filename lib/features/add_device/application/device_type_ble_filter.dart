import '../../../core/utils/device_type.dart';

const String defaultDoorDeviceType = DeviceTypeValues.opener;

const Map<String, String> doorDeviceTypeBleNamePrefixes = <String, String>{
  DeviceTypeValues.dongle: 'Noru_',
  DeviceTypeValues.opener: 'opener_',
  DeviceTypeValues.evolution: 'Evo_',
  DeviceTypeValues.fBox: 'Fbox_',
};

String normalizeDoorDeviceType(String? deviceType) {
  final normalized = canonicalDoorDeviceType(deviceType);
  return doorDeviceTypeBleNamePrefixes.containsKey(normalized)
      ? normalized
      : defaultDoorDeviceType;
}

String bleNamePrefixForDoorDeviceType(String? deviceType) {
  return doorDeviceTypeBleNamePrefixes[normalizeDoorDeviceType(deviceType)]!;
}

bool bleNameMatchesDoorDeviceType(String? bleName, String? deviceType) {
  final normalizedName = bleName?.trim();
  return normalizedName != null &&
      normalizedName.startsWith(bleNamePrefixForDoorDeviceType(deviceType));
}
