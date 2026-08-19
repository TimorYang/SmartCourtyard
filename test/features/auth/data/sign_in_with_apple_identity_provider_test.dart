import 'package:flinx/features/auth/data/services/sign_in_with_apple_identity_provider.dart';
import 'package:flinx/features/auth/domain/services/apple_identity_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

void main() {
  test('passes the hashed nonce and required scopes to Apple', () async {
    List<AppleIDAuthorizationScopes>? capturedScopes;
    String? capturedNonce;
    final provider = SignInWithAppleIdentityProvider(
      availabilityChecker: () async => true,
      credentialRequester: ({required scopes, required nonce}) async {
        capturedScopes = scopes;
        capturedNonce = nonce;
        return const AuthorizationCredentialAppleID(
          userIdentifier: 'apple-user',
          givenName: ' Alice ',
          familyName: ' Smith ',
          authorizationCode: ' authorization-code ',
          email: 'alice@example.com',
          identityToken: ' identity-token ',
          state: null,
        );
      },
    );

    final credential = await provider.authorize(hashedNonce: 'hashed-nonce');

    expect(capturedNonce, 'hashed-nonce');
    expect(capturedScopes, contains(AppleIDAuthorizationScopes.email));
    expect(capturedScopes, contains(AppleIDAuthorizationScopes.fullName));
    expect(credential.identityToken, 'identity-token');
    expect(credential.authorizationCode, 'authorization-code');
    expect(credential.givenName, 'Alice');
    expect(credential.familyName, 'Smith');
  });

  test('rejects a missing authorization code', () async {
    final provider = SignInWithAppleIdentityProvider(
      availabilityChecker: () async => true,
      credentialRequester: ({required scopes, required nonce}) async =>
          const AuthorizationCredentialAppleID(
            userIdentifier: 'apple-user',
            givenName: null,
            familyName: null,
            authorizationCode: ' ',
            email: null,
            identityToken: 'identity-token',
            state: null,
          ),
    );

    expect(
      () => provider.authorize(hashedNonce: 'hashed-nonce'),
      throwsA(
        isA<AppleIdentityException>().having(
          (error) => error.code,
          'code',
          AppleIdentityErrorCode.invalidCredential,
        ),
      ),
    );
  });
}
