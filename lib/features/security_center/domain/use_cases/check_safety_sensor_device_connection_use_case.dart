import '../repositories/safety_sensor_pairing_repository.dart';

class CheckSafetySensorDeviceConnectionUseCase {
  CheckSafetySensorDeviceConnectionUseCase({required this.repository});

  final SafetySensorPairingRepository repository;
  var _requestCounter = 0;

  Future<bool> call({required String deviceId}) {
    final requestId =
        'safety-sensor-connection-check-'
        '${DateTime.now().millisecondsSinceEpoch}-${++_requestCounter}';
    return repository.isDeviceConnected(
      deviceId: deviceId,
      requestId: requestId,
    );
  }
}
