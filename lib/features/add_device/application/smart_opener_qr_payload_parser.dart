const String smartOpenerQrPayloadSeparator = '#SPT#';
const List<String> smartOpenerBleNamePrefixes = <String>[
  'Noru_',
  'opener_',
  'Evo_',
  'Fbox_',
];

bool isSupportedSmartOpenerBleName(String name) {
  return smartOpenerBleNamePrefixes.any(name.startsWith);
}

String? parseSmartOpenerSerialNumber(String payload) {
  final separatorIndex = payload.indexOf(smartOpenerQrPayloadSeparator);
  if (separatorIndex <= 0) {
    return null;
  }

  final serialNumber = payload.substring(0, separatorIndex).trim();
  if (!isSupportedSmartOpenerBleName(serialNumber)) {
    return null;
  }

  return serialNumber;
}
