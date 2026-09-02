import '../entities/push_registration.dart';

abstract interface class PushRegistrationRepository {
  Future<void> bind({
    required PushRegistration registration,
    required String requestId,
  });

  Future<void> unbind({required String requestId});
}
