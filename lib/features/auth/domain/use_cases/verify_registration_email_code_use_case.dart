import '../entities/registration_verification.dart';
import '../repositories/auth_registration_repository.dart';

class VerifyRegistrationEmailCodeUseCase {
  VerifyRegistrationEmailCodeUseCase({
    required this.repository,
    String Function()? requestIdGenerator,
  }) : _requestIdGenerator = requestIdGenerator ?? _defaultRequestId;

  final AuthRegistrationRepository repository;
  final String Function() _requestIdGenerator;

  Future<RegistrationVerification> call({
    required String email,
    required String code,
  }) => repository.verifyEmailCode(
    email: email,
    code: code,
    requestId: _requestIdGenerator(),
  );

  static String _defaultRequestId() =>
      'register-verify-code-${DateTime.now().toUtc().microsecondsSinceEpoch}';
}
