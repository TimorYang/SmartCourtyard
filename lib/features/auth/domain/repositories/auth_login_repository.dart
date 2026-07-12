import '../entities/auth_login_result.dart';

abstract interface class AuthLoginRepository {
  Future<AuthLoginResult> login({
    required String email,
    required String passwordCiphertext,
    required String keyId,
    required String nonce,
    required String requestId,
  });
}
