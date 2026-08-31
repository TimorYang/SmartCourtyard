import 'package:flutter/foundation.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

import '../../domain/entities/google_identity_credential.dart';
import '../../domain/services/google_identity_provider.dart';
import 'google_sign_in_configuration.dart';

typedef GooglePlatformInitializer =
    Future<void> Function(InitParameters parameters);
typedef GooglePlatformAuthenticator =
    Future<AuthenticationResults> Function(AuthenticateParameters parameters);
typedef GooglePlatformServerAuthorizer =
    Future<ServerAuthorizationTokenData?> Function(
      ServerAuthorizationTokensForScopesParameters parameters,
    );
typedef GooglePlatformSupportChecker = bool Function();
typedef GoogleTargetPlatformProvider = TargetPlatform Function();

class GoogleSignInIdentityProvider implements GoogleIdentityProvider {
  GoogleSignInIdentityProvider({
    GoogleSignInConfiguration? configuration,
    GooglePlatformInitializer? initializer,
    GooglePlatformAuthenticator? authenticator,
    GooglePlatformServerAuthorizer? serverAuthorizer,
    GooglePlatformSupportChecker? platformSupportChecker,
    GoogleTargetPlatformProvider? targetPlatformProvider,
  }) : _configuration =
           configuration ?? GoogleSignInConfiguration.fromEnvironment(),
       _initializer = initializer ?? _initializePlatform,
       _authenticator = authenticator ?? _authenticatePlatform,
       _serverAuthorizer = serverAuthorizer ?? _authorizeServerPlatform,
       _platformSupportChecker =
           platformSupportChecker ??
           (() => _isSupportedPlatform(
             configuration ?? GoogleSignInConfiguration.fromEnvironment(),
           )),
       _targetPlatformProvider =
           targetPlatformProvider ?? (() => defaultTargetPlatform);

  static const _scopes = <String>['openid', 'email', 'profile'];

  final GoogleSignInConfiguration _configuration;
  final GooglePlatformInitializer _initializer;
  final GooglePlatformAuthenticator _authenticator;
  final GooglePlatformServerAuthorizer _serverAuthorizer;
  final GooglePlatformSupportChecker _platformSupportChecker;
  final GoogleTargetPlatformProvider _targetPlatformProvider;

  @override
  Future<bool> isAvailable() async {
    return _platformSupportChecker() && _configuration.hasRequiredClientIds;
  }

  @override
  Future<GoogleIdentityCredential> authorize({required String nonce}) async {
    if (!await isAvailable()) {
      throw const GoogleIdentityException(GoogleIdentityErrorCode.unavailable);
    }

    try {
      // The app-facing GoogleSignIn singleton accepts a nonce only during its
      // one-time initialization. The backend issues a fresh nonce per login,
      // so this adapter initializes the endorsed platform implementation for
      // each request and forwards the raw nonce to the native SDK.
      await _initializer(
        InitParameters(
          clientId: _configuration.optionalIosClientId,
          serverClientId: _configuration.serverClientId.trim(),
          hostedDomain: _configuration.optionalHostedDomain,
          nonce: nonce,
        ),
      );
      // Ask for the basic OpenID scopes during the user-initiated sign-in.
      // The iOS implementation caches the server authorization code returned
      // by this combined flow, so the follow-up server-token lookup can stay
      // silent instead of presenting a second authorization sheet.
      final authentication = await _authenticator(
        const AuthenticateParameters(scopeHint: _scopes),
      );
      final idToken = authentication.authenticationTokens.idToken?.trim();
      final serverAuthorization = await _serverAuthorizer(
        ServerAuthorizationTokensForScopesParameters(
          request: AuthorizationRequestDetails(
            scopes: _scopes,
            userId: authentication.user.id,
            email: authentication.user.email,
            // iOS returns and caches the server auth code from the combined
            // authenticate(scopeHint: ...) call, so this lookup must remain
            // silent. Android's Credential Manager ignores scopeHint and
            // needs this explicit authorization request on first sign-in.
            promptIfUnauthorized:
                _targetPlatformProvider() == TargetPlatform.android,
          ),
        ),
      );
      final authorizationCode = serverAuthorization?.serverAuthCode.trim();
      if (idToken == null ||
          idToken.isEmpty ||
          authorizationCode == null ||
          authorizationCode.isEmpty) {
        throw const GoogleIdentityException(
          GoogleIdentityErrorCode.invalidCredential,
        );
      }
      return GoogleIdentityCredential(
        idToken: idToken,
        authorizationCode: authorizationCode,
      );
    } on GoogleIdentityException {
      rethrow;
    } on GoogleSignInException catch (error) {
      throw _mapException(error);
    } on Object {
      throw const GoogleIdentityException(GoogleIdentityErrorCode.failed);
    }
  }

  GoogleIdentityException _mapException(GoogleSignInException error) {
    return switch (error.code) {
      GoogleSignInExceptionCode.canceled => const GoogleIdentityException(
        GoogleIdentityErrorCode.canceled,
      ),
      GoogleSignInExceptionCode.clientConfigurationError ||
      GoogleSignInExceptionCode.providerConfigurationError ||
      GoogleSignInExceptionCode.uiUnavailable => const GoogleIdentityException(
        GoogleIdentityErrorCode.unavailable,
      ),
      _ => const GoogleIdentityException(GoogleIdentityErrorCode.failed),
    };
  }

  static Future<void> _initializePlatform(InitParameters parameters) {
    return GoogleSignInPlatform.instance.init(parameters);
  }

  static Future<AuthenticationResults> _authenticatePlatform(
    AuthenticateParameters parameters,
  ) {
    return GoogleSignInPlatform.instance.authenticate(parameters);
  }

  static Future<ServerAuthorizationTokenData?> _authorizeServerPlatform(
    ServerAuthorizationTokensForScopesParameters parameters,
  ) {
    return GoogleSignInPlatform.instance.serverAuthorizationTokensForScopes(
      parameters,
    );
  }

  static bool _supportsPlatform() {
    try {
      return GoogleSignInPlatform.instance.supportsAuthenticate();
    } on Object {
      return false;
    }
  }

  static bool _isSupportedPlatform(GoogleSignInConfiguration configuration) {
    return configuration.isSupportedPlatform && _supportsPlatform();
  }
}
