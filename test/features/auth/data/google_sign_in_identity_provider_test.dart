import 'package:flinx/features/auth/data/services/google_sign_in_configuration.dart';
import 'package:flinx/features/auth/data/services/google_sign_in_identity_provider.dart';
import 'package:flinx/features/auth/domain/services/google_identity_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

void main() {
  test(
    'passes the backend nonce and returns both Google credentials',
    () async {
      InitParameters? capturedParameters;
      final provider = GoogleSignInIdentityProvider(
        configuration: const GoogleSignInConfiguration(
          iosClientId: 'ios-client-id',
          serverClientId: 'server-client-id',
        ),
        platformSupportChecker: () => true,
        initializer: (parameters) async {
          capturedParameters = parameters;
        },
        authenticator: (_) async => const AuthenticationResults(
          user: GoogleSignInUserData(
            email: 'alice@example.com',
            id: 'google-user-id',
            displayName: 'Alice',
          ),
          authenticationTokens: AuthenticationTokenData(idToken: ' id-token '),
        ),
        serverAuthorizer: (_) async => const ServerAuthorizationTokenData(
          serverAuthCode: ' authorization-code ',
        ),
      );

      final credential = await provider.authorize(nonce: 'raw-nonce');

      expect(capturedParameters?.nonce, 'raw-nonce');
      expect(capturedParameters?.serverClientId, 'server-client-id');
      expect(capturedParameters?.clientId, 'ios-client-id');
      expect(credential.idToken, 'id-token');
      expect(credential.authorizationCode, 'authorization-code');
    },
  );

  test('maps a user cancellation to the domain error', () async {
    final provider = GoogleSignInIdentityProvider(
      configuration: const GoogleSignInConfiguration(
        serverClientId: 'server-client-id',
      ),
      platformSupportChecker: () => true,
      initializer: (_) async {},
      authenticator: (_) => throw const GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
      ),
      serverAuthorizer: (_) async => null,
    );

    expect(
      () => provider.authorize(nonce: 'raw-nonce'),
      throwsA(
        isA<GoogleIdentityException>().having(
          (error) => error.code,
          'code',
          GoogleIdentityErrorCode.canceled,
        ),
      ),
    );
  });

  test(
    'reports the provider as unavailable before Google configuration exists',
    () async {
      var initialized = false;
      final provider = GoogleSignInIdentityProvider(
        configuration: const GoogleSignInConfiguration(),
        platformSupportChecker: () => true,
        initializer: (_) async {
          initialized = true;
        },
      );

      expect(await provider.isAvailable(), isFalse);
      expect(
        () => provider.authorize(nonce: 'raw-nonce'),
        throwsA(
          isA<GoogleIdentityException>().having(
            (error) => error.code,
            'code',
            GoogleIdentityErrorCode.unavailable,
          ),
        ),
      );
      expect(initialized, isFalse);
    },
  );

  test('rejects a missing server authorization code', () async {
    final provider = GoogleSignInIdentityProvider(
      configuration: const GoogleSignInConfiguration(
        serverClientId: 'server-client-id',
      ),
      platformSupportChecker: () => true,
      initializer: (_) async {},
      authenticator: (_) async => const AuthenticationResults(
        user: GoogleSignInUserData(
          email: 'alice@example.com',
          id: 'google-user-id',
        ),
        authenticationTokens: AuthenticationTokenData(idToken: 'id-token'),
      ),
      serverAuthorizer: (_) async => null,
    );

    expect(
      () => provider.authorize(nonce: 'raw-nonce'),
      throwsA(
        isA<GoogleIdentityException>().having(
          (error) => error.code,
          'code',
          GoogleIdentityErrorCode.invalidCredential,
        ),
      ),
    );
  });
}
