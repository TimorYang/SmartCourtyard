import '../entities/onboarding_device_key.dart';
import '../repositories/add_device_onboarding_repository.dart';

class FetchOnboardingDeviceKeyUseCase {
  const FetchOnboardingDeviceKeyUseCase({required this.repository});

  final AddDeviceOnboardingRepository repository;

  Future<OnboardingDeviceKey> call({
    required String sn,
    required String requestId,
  }) {
    return repository.fetchDeviceKey(sn: sn, requestId: requestId);
  }
}
