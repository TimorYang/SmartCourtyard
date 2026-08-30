import '../entities/google_identity_credential.dart';

abstract interface class GoogleIdentityProvider {
  Future<bool> isAvailable();

  Future<GoogleIdentityCredential> authorize({required String nonce});
}

enum GoogleIdentityErrorCode {
  canceled,
  unavailable,
  invalidCredential,
  failed,
}

class GoogleIdentityException implements Exception {
  const GoogleIdentityException(this.code);

  final GoogleIdentityErrorCode code;
}
