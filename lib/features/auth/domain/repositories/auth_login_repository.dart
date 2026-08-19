import '../entities/apple_login_nonce.dart';
import '../entities/auth_login_result.dart';

abstract interface class AuthLoginRepository {
  Future<AuthLoginResult> login({
    required String email,
    required String passwordCiphertext,
    required String keyId,
    required String nonce,
    required String deviceId,
    required String deviceModel,
    required String platform,
    required String appVersion,
    required String requestId,
  });

  Future<AuthLoginResult> loginWithApple({
    required String nonceId,
    required String identityToken,
    required String authorizationCode,
    required String? givenName,
    required String? familyName,
    required String deviceId,
    required String deviceModel,
    required String platform,
    required String appVersion,
    required String requestId,
  });

  Future<AppleLoginNonce> getAppleLoginNonce({required String requestId});
}
