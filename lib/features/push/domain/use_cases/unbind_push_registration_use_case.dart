import '../repositories/push_registration_repository.dart';

class UnbindPushRegistrationUseCase {
  const UnbindPushRegistrationUseCase({required this.repository});

  final PushRegistrationRepository repository;

  Future<void> call({required String requestId}) {
    return repository.unbind(requestId: requestId);
  }
}
