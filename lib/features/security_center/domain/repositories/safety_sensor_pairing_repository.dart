import '../entities/safety_sensor_pairing.dart';

abstract interface class SafetySensorPairingRepository {
  Future<bool> isDeviceConnected({
    required String deviceId,
    required String requestId,
  });

  Future<SafetySensorPairingResult> pair(SafetySensorPairingRequest request);
}
