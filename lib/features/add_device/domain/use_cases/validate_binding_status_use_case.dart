import '../repositories/add_device_onboarding_repository.dart';

class ValidateBindingStatusUseCase {
  const ValidateBindingStatusUseCase({required this.repository});

  final AddDeviceOnboardingRepository repository;

  Future<void> call({required String sn, required String requestId}) {
    return repository.validateBindingStatus(sn: sn, requestId: requestId);
  }
}
