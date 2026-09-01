import 'package:flinx/features/auth/data/services/facebook_login_configuration.dart';
import 'package:flinx/features/auth/data/services/facebook_sign_in_identity_provider.dart';
import 'package:flinx/features/auth/domain/entities/facebook_identity_credential.dart';
import 'package:flinx/features/auth/domain/services/facebook_identity_provider.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses Limited Login and forwards the iOS nonce', () async {
    List<String>? capturedPermissions;
    LoginBehavior? capturedBehavior;
    LoginTracking? capturedTracking;
    String? capturedNonce;
    final provider = FacebookSignInIdentityProvider(
      configuration: const FacebookLoginConfiguration(
        appId: '1732924337995646',
        clientToken: 'client-token',
        displayName: 'force-test',
      ),
      platformSupportChecker: () => true,
      loginRequester:
          ({
            required loginBehavior,
            required loginTracking,
            required permissions,
            nonce,
          }) async {
            capturedPermissions = permissions;
            capturedBehavior = loginBehavior;
            capturedTracking = loginTracking;
            capturedNonce = nonce;
            return LoginResult(
              status: LoginStatus.success,
              accessToken: LimitedToken(
                userId: 'facebook-user-id',
                userName: 'Alice',
                userEmail: 'alice@example.com',
                nonce: 'facebook-raw-nonce',
                tokenString: 'authentication-token',
              ),
            );
          },
    );

    final credential = await provider.authorize(
      platform: FacebookLoginPlatform.ios,
      nonce: 'facebook-raw-nonce',
    );

    expect(capturedPermissions, ['public_profile', 'email']);
    expect(capturedBehavior, LoginBehavior.nativeWithFallback);
    expect(capturedTracking, LoginTracking.limited);
    expect(capturedNonce, 'facebook-raw-nonce');
    expect(credential.kind, FacebookTokenKind.authenticationToken);
    expect(credential.tokenString, 'authentication-token');
  });

  test('uses ClassicToken on Android without forwarding a nonce', () async {
    String? capturedNonce = 'unexpected';
    final provider = FacebookSignInIdentityProvider(
      configuration: const FacebookLoginConfiguration(
        appId: '1732924337995646',
        clientToken: 'client-token',
        displayName: 'force-test',
      ),
      platformSupportChecker: () => true,
      loginRequester:
          ({
            required loginBehavior,
            required loginTracking,
            required permissions,
            nonce,
          }) async {
            capturedNonce = nonce;
            return LoginResult(
              status: LoginStatus.success,
              accessToken: ClassicToken(
                declinedPermissions: const [],
                grantedPermissions: const ['public_profile', 'email'],
                userId: 'facebook-user-id',
                expires: DateTime.utc(2030),
                tokenString: 'access-token',
                applicationId: 'app-id',
              ),
            );
          },
    );

    final credential = await provider.authorize(
      platform: FacebookLoginPlatform.android,
      nonce: 'must-not-be-forwarded',
    );

    expect(capturedNonce, isNull);
    expect(credential.kind, FacebookTokenKind.accessToken);
    expect(credential.tokenString, 'access-token');
  });

  test('maps a cancelled SDK result to the domain error', () async {
    final provider = FacebookSignInIdentityProvider(
      configuration: const FacebookLoginConfiguration(
        appId: '1732924337995646',
        clientToken: 'client-token',
        displayName: 'force-test',
      ),
      platformSupportChecker: () => true,
      loginRequester:
          ({
            required loginBehavior,
            required loginTracking,
            required permissions,
            nonce,
          }) async => LoginResult(status: LoginStatus.cancelled),
    );

    expect(
      () => provider.authorize(
        platform: FacebookLoginPlatform.ios,
        nonce: 'facebook-raw-nonce',
      ),
      throwsA(
        isA<FacebookIdentityException>().having(
          (error) => error.code,
          'code',
          FacebookIdentityErrorCode.canceled,
        ),
      ),
    );
  });

  test(
    'does not call the SDK when Facebook configuration is missing',
    () async {
      var loginCalls = 0;
      final provider = FacebookSignInIdentityProvider(
        configuration: const FacebookLoginConfiguration(),
        platformSupportChecker: () => true,
        loginRequester:
            ({
              required loginBehavior,
              required loginTracking,
              required permissions,
              nonce,
            }) async {
              loginCalls += 1;
              return LoginResult(status: LoginStatus.failed);
            },
      );

      expect(await provider.isAvailable(), isFalse);
      expect(
        () => provider.authorize(platform: FacebookLoginPlatform.android),
        throwsA(
          isA<FacebookIdentityException>().having(
            (error) => error.code,
            'code',
            FacebookIdentityErrorCode.unavailable,
          ),
        ),
      );
      expect(loginCalls, 0);
    },
  );

  test('rejects an iOS success without a LimitedToken credential', () async {
    final provider = FacebookSignInIdentityProvider(
      configuration: const FacebookLoginConfiguration(
        appId: '1732924337995646',
        clientToken: 'client-token',
        displayName: 'force-test',
      ),
      platformSupportChecker: () => true,
      loginRequester:
          ({
            required loginBehavior,
            required loginTracking,
            required permissions,
            nonce,
          }) async => LoginResult(
            status: LoginStatus.success,
            accessToken: ClassicToken(
              declinedPermissions: const [],
              grantedPermissions: const [],
              userId: 'facebook-user-id',
              expires: DateTime.utc(2030),
              tokenString: 'access-token',
              applicationId: 'app-id',
            ),
          ),
    );

    expect(
      () => provider.authorize(
        platform: FacebookLoginPlatform.ios,
        nonce: 'facebook-raw-nonce',
      ),
      throwsA(
        isA<FacebookIdentityException>().having(
          (error) => error.code,
          'code',
          FacebookIdentityErrorCode.invalidCredential,
        ),
      ),
    );
  });
}
