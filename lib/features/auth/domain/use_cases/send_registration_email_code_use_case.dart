import '../repositories/auth_registration_repository.dart';

class SendRegistrationEmailCodeUseCase {
  SendRegistrationEmailCodeUseCase({
    required this.repository,
    String Function()? requestIdGenerator,
  }) : _requestIdGenerator = requestIdGenerator ?? _defaultRequestId;

  final AuthRegistrationRepository repository;
  final String Function() _requestIdGenerator;

  Future<void> call(String email) =>
      repository.sendEmailCode(email: email, requestId: _requestIdGenerator());

  static String _defaultRequestId() =>
      'register-email-code-${DateTime.now().toUtc().microsecondsSinceEpoch}';
}
