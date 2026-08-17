import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../domain/entities/apple_identity_credential.dart';
import '../../domain/services/apple_identity_provider.dart';

class SignInWithAppleIdentityProvider implements AppleIdentityProvider {
  const SignInWithAppleIdentityProvider();

  @override
  Future<bool> isAvailable() => SignInWithApple.isAvailable();

  @override
  Future<AppleIdentityCredential> authorize() async {
    try {
      if (!await isAvailable()) {
        throw const AppleIdentityException(AppleIdentityErrorCode.unavailable);
      }
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [AppleIDAuthorizationScopes.email],
      );
      final identityToken = credential.identityToken?.trim();
      if (identityToken == null || identityToken.isEmpty) {
        throw const AppleIdentityException(
          AppleIdentityErrorCode.invalidCredential,
        );
      }
      return AppleIdentityCredential(identityToken: identityToken);
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
}
