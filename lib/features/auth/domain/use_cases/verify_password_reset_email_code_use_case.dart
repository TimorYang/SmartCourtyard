import '../repositories/auth_password_reset_repository.dart';
import '../entities/password_reset_verification.dart';

class VerifyPasswordResetEmailCodeUseCase {
  VerifyPasswordResetEmailCodeUseCase({
    required this.repository,
    String Function()? requestIdGenerator,
  }) : _requestIdGenerator = requestIdGenerator ?? _defaultRequestId;

  final AuthPasswordResetRepository repository;
  final String Function() _requestIdGenerator;

  Future<PasswordResetVerification> call({
    required String email,
    required String code,
  }) => repository.verifyEmailCode(
    email: email,
    code: code,
    requestId: _requestIdGenerator(),
  );

  static String _defaultRequestId() =>
      'password-reset-verify-code-${DateTime.now().toUtc().microsecondsSinceEpoch}';
}
