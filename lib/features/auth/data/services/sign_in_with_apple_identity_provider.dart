import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../domain/entities/apple_identity_credential.dart';
import '../../domain/services/apple_identity_provider.dart';

typedef AppleAvailabilityChecker = Future<bool> Function();
typedef AppleCredentialRequester =
    Future<AuthorizationCredentialAppleID> Function({
      required List<AppleIDAuthorizationScopes> scopes,
      required String nonce,
    });

class SignInWithAppleIdentityProvider implements AppleIdentityProvider {
  SignInWithAppleIdentityProvider({
    AppleAvailabilityChecker? availabilityChecker,
    AppleCredentialRequester? credentialRequester,
  }) : _availabilityChecker =
           availabilityChecker ?? SignInWithApple.isAvailable,
       _credentialRequester = credentialRequester ?? _requestCredential;

  final AppleAvailabilityChecker _availabilityChecker;
  final AppleCredentialRequester _credentialRequester;

  @override
  Future<bool> isAvailable() => _availabilityChecker();

  @override
  Future<AppleIdentityCredential> authorize({
    required String hashedNonce,
  }) async {
    try {
      if (!await isAvailable()) {
        throw const AppleIdentityException(AppleIdentityErrorCode.unavailable);
      }
      final credential = await _credentialRequester(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
      final identityToken = credential.identityToken?.trim();
      final authorizationCode = credential.authorizationCode.trim();
      if (identityToken == null ||
          identityToken.isEmpty ||
          authorizationCode.isEmpty) {
        throw const AppleIdentityException(
          AppleIdentityErrorCode.invalidCredential,
        );
      }
      return AppleIdentityCredential(
        identityToken: identityToken,
        authorizationCode: authorizationCode,
        givenName: _nonEmpty(credential.givenName),
        familyName: _nonEmpty(credential.familyName),
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        throw const AppleIdentityException(AppleIdentityErrorCode.canceled);
      }
      throw const AppleIdentityException(AppleIdentityErrorCode.failed);
    } on SignInWithAppleNotSupportedException {
      throw const AppleIdentityException(AppleIdentityErrorCode.unavailable);
    } on AppleIdentityException {
      rethrow;
    } on Object {
      throw const AppleIdentityException(AppleIdentityErrorCode.failed);
    }
  }

  String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static Future<AuthorizationCredentialAppleID> _requestCredential({
    required List<AppleIDAuthorizationScopes> scopes,
    required String nonce,
  }) => SignInWithApple.getAppleIDCredential(scopes: scopes, nonce: nonce);
}
