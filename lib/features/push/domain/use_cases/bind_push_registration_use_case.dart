import '../entities/push_registration.dart';
import '../repositories/push_registration_repository.dart';

class BindPushRegistrationUseCase {
  const BindPushRegistrationUseCase({required this.repository});

  final PushRegistrationRepository repository;

  Future<void> call({
    required PushRegistration registration,
    required String requestId,
  }) {
    return repository.bind(registration: registration, requestId: requestId);
  }
}
