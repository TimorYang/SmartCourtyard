import '../entities/safety_sensor_pairing.dart';
import '../repositories/safety_sensor_pairing_repository.dart';

class PairSafetySensorUseCase {
  const PairSafetySensorUseCase({required this.repository});

  final SafetySensorPairingRepository repository;

  Future<SafetySensorPairingResult> call(SafetySensorPairingRequest request) =>
      repository.pair(request);
}
