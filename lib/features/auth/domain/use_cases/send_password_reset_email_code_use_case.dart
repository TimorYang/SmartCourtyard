import '../repositories/auth_password_reset_repository.dart';

class SendPasswordResetEmailCodeUseCase {
  SendPasswordResetEmailCodeUseCase({
    required this.repository,
    String Function()? requestIdGenerator,
  }) : _requestIdGenerator = requestIdGenerator ?? _defaultRequestId;

  final AuthPasswordResetRepository repository;
  final String Function() _requestIdGenerator;

  Future<void> call(String email) => repository.sendEmailCode(
    email: email,
    requestId: _requestIdGenerator(),
  );

  static String _defaultRequestId() =>
      'password-reset-send-code-${DateTime.now().toUtc().microsecondsSinceEpoch}';
}
