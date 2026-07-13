import '../entities/onboarded_force_door.dart';
import '../repositories/add_device_onboarding_repository.dart';

class AddForceDoorUseCase {
  const AddForceDoorUseCase({required this.repository});

  final AddDeviceOnboardingRepository repository;

  Future<OnboardedForceDoor> call({
    required String sn,
    required String requestId,
  }) {
    return repository.addForceDoor(sn: sn, requestId: requestId);
  }
}
