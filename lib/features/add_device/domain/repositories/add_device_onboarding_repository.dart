import '../entities/onboarded_force_door.dart';
import '../entities/onboarding_device_key.dart';

abstract interface class AddDeviceOnboardingRepository {
  Future<void> validateBindingStatus({
    required String sn,
    required String requestId,
  });

  Future<OnboardingDeviceKey> fetchDeviceKey({
    required String sn,
    required String requestId,
  });

  Future<OnboardedForceDoor> addForceDoor({
    required String sn,
    String? doorId,
    required int doorType,
    required String requestId,
  });
}
