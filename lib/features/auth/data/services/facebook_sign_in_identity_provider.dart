import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import '../../domain/entities/facebook_identity_credential.dart';
import '../../domain/services/facebook_identity_provider.dart';
import 'facebook_login_configuration.dart';

typedef FacebookLoginRequester =
    Future<LoginResult> Function({
      required List<String> permissions,
      required LoginBehavior loginBehavior,
      required LoginTracking loginTracking,
      String? nonce,
    });
typedef FacebookPlatformSupportChecker = bool Function();

class FacebookSignInIdentityProvider implements FacebookIdentityProvider {
  FacebookSignInIdentityProvider({
    FacebookLoginConfiguration? configuration,
    FacebookLoginRequester? loginRequester,
    FacebookPlatformSupportChecker? platformSupportChecker,
  }) : _configuration =
           configuration ?? FacebookLoginConfiguration.fromEnvironment(),
       _loginRequester = loginRequester ?? _requestLogin,
       _platformSupportChecker =
           platformSupportChecker ??
           (() => _isSupportedPlatform(
             configuration ?? FacebookLoginConfiguration.fromEnvironment(),
           ));

  static const _permissions = <String>['public_profile', 'email'];

  final FacebookLoginConfiguration _configuration;
  final FacebookLoginRequester _loginRequester;
  final FacebookPlatformSupportChecker _platformSupportChecker;

  @override
  Future<bool> isAvailable() async {
    return _platformSupportChecker() &&
        _configuration.hasRequiredClientConfiguration;
  }

  @override
  Future<FacebookIdentityCredential> authorize({
    required FacebookLoginPlatform platform,
    String? nonce,
  }) async {
    if (!await isAvailable()) {
      throw const FacebookIdentityException(
        FacebookIdentityErrorCode.unavailable,
      );
    }
    if (platform == FacebookLoginPlatform.ios &&
        (nonce == null || nonce.trim().isEmpty)) {
      throw const FacebookIdentityException(
        FacebookIdentityErrorCode.invalidCredential,
      );
    }

    try {
      final result = await _loginRequester(
        permissions: _permissions,
        loginBehavior: LoginBehavior.nativeWithFallback,
        loginTracking: platform == FacebookLoginPlatform.ios
            ? LoginTracking.limited
            : LoginTracking.enabled,
        nonce: platform == FacebookLoginPlatform.ios ? nonce : null,
      );
      if (result.status == LoginStatus.cancelled) {
        throw const FacebookIdentityException(
          FacebookIdentityErrorCode.canceled,
        );
      }
      if (result.status != LoginStatus.success || result.accessToken == null) {
        throw const FacebookIdentityException(FacebookIdentityErrorCode.failed);
      }

      final accessToken = result.accessToken!;
      if (platform == FacebookLoginPlatform.ios) {
        if (accessToken is! LimitedToken ||
            accessToken.tokenString.trim().isEmpty ||
            accessToken.nonce.trim().isEmpty) {
          throw const FacebookIdentityException(
            FacebookIdentityErrorCode.invalidCredential,
          );
        }
        return FacebookIdentityCredential(
          kind: FacebookTokenKind.authenticationToken,
          tokenString: accessToken.tokenString.trim(),
        );
      }

      if (accessToken is! ClassicToken ||
          accessToken.tokenString.trim().isEmpty) {
        throw const FacebookIdentityException(
          FacebookIdentityErrorCode.invalidCredential,
        );
      }
      return FacebookIdentityCredential(
        kind: FacebookTokenKind.accessToken,
        tokenString: accessToken.tokenString.trim(),
      );
    } on FacebookIdentityException {
      rethrow;
    } on PlatformException catch (error) {
      final code = error.code.toUpperCase();
      if (code.contains('CANCEL')) {
        throw const FacebookIdentityException(
          FacebookIdentityErrorCode.canceled,
        );
      }
      throw const FacebookIdentityException(FacebookIdentityErrorCode.failed);
    } on Object {
      throw const FacebookIdentityException(FacebookIdentityErrorCode.failed);
    }
  }

  static Future<LoginResult> _requestLogin({
    required List<String> permissions,
    required LoginBehavior loginBehavior,
    required LoginTracking loginTracking,
    String? nonce,
  }) {
    return FacebookAuth.instance.login(
      permissions: permissions,
      loginBehavior: loginBehavior,
      loginTracking: loginTracking,
      nonce: nonce,
    );
  }

  static bool _isSupportedPlatform(FacebookLoginConfiguration configuration) {
    return configuration.isSupportedPlatform;
  }
}
