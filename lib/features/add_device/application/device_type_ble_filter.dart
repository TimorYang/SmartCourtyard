const String defaultDoorDeviceType = 'opener';

const Map<String, String> doorDeviceTypeBleNamePrefixes = <String, String>{
  'dongle': 'Noru_',
  'opener': 'opener_',
  'evolution': 'Evo_',
  'fbox': 'Fbox_',
};

String normalizeDoorDeviceType(String? deviceType) {
  final normalized = deviceType?.trim().toLowerCase();
  return doorDeviceTypeBleNamePrefixes.containsKey(normalized)
      ? normalized!
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
