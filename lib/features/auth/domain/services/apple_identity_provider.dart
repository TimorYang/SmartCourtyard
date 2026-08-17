import '../entities/apple_identity_credential.dart';

abstract interface class AppleIdentityProvider {
  Future<bool> isAvailable();

  Future<AppleIdentityCredential> authorize();
}

enum AppleIdentityErrorCode { canceled, unavailable, invalidCredential, failed }

class AppleIdentityException implements Exception {
  const AppleIdentityException(this.code);

  final AppleIdentityErrorCode code;
}
