import '../entities/facebook_identity_credential.dart';

enum FacebookLoginPlatform { android, ios }

abstract interface class FacebookIdentityProvider {
  Future<bool> isAvailable();

  Future<FacebookIdentityCredential> authorize({
    required FacebookLoginPlatform platform,
    String? nonce,
  });
}

enum FacebookIdentityErrorCode {
  canceled,
  unavailable,
  invalidCredential,
  failed,
}

class FacebookIdentityException implements Exception {
  const FacebookIdentityException(this.code);

  final FacebookIdentityErrorCode code;
}
