import 'device_type_ble_filter.dart';

const String smartOpenerQrPayloadSeparator = '#SPT#';
bool isSupportedSmartOpenerBleName(String name) {
  return doorDeviceTypeBleNamePrefixes.values.any(name.startsWith);
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
