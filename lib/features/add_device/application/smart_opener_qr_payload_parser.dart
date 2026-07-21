const String smartOpenerQrPayloadSeparator = '#SPT#';
const String smartOpenerBleNamePrefix = 'opener_';

String? parseSmartOpenerSerialNumber(String payload) {
  final separatorIndex = payload.indexOf(smartOpenerQrPayloadSeparator);
  if (separatorIndex <= 0) {
    return null;
  }

  final serialNumber = payload.substring(0, separatorIndex).trim();
  if (!serialNumber.startsWith(smartOpenerBleNamePrefix)) {
    return null;
  }

  return serialNumber;
}
