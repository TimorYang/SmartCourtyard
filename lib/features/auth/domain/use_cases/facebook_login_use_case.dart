import '../../../account/domain/repositories/account_repository.dart';
import '../entities/auth_login_result.dart';
import '../entities/facebook_identity_credential.dart';
import '../entities/facebook_login_nonce.dart';
import '../repositories/auth_login_repository.dart';
import '../services/facebook_identity_provider.dart';
import '../services/login_device_context_provider.dart';

class FacebookLoginUseCase {
  FacebookLoginUseCase({
    required this.identityProvider,
    required this.loginRepository,
    required this.accountRepository,
    required this.deviceContextProvider,
    String Function()? requestIdGenerator,
  }) : _requestIdGenerator = requestIdGenerator ?? _defaultRequestId;

  final FacebookIdentityProvider identityProvider;
  final AuthLoginRepository loginRepository;
  final AccountRepository accountRepository;
  final LoginDeviceContextProvider deviceContextProvider;
  final String Function() _requestIdGenerator;

  Future<AuthLoginResult> call() async {
    if (!await identityProvider.isAvailable()) {
      throw const FacebookIdentityException(
        FacebookIdentityErrorCode.unavailable,
      );
    }

    final requestId = _requestIdGenerator();
    final deviceContext = await deviceContextProvider.read();
    final platform = _platformFor(deviceContext.platform);
    if (platform == null) {
      throw const FacebookIdentityException(
        FacebookIdentityErrorCode.unavailable,
      );
    }

    final nonce = platform == FacebookLoginPlatform.ios
        ? await loginRepository.getFacebookLoginNonce(requestId: requestId)
        : null;
    final credential = await identityProvider.authorize(
      platform: platform,
      nonce: nonce?.nonce,
    );
    _validateCredential(
      platform: platform,
      credential: credential,
      nonce: nonce,
    );

    final result = await loginRepository.loginWithFacebook(
      credential: credential,
      nonceId: nonce?.nonceId,
      deviceId: deviceContext.deviceId,
      deviceModel: deviceContext.deviceModel,
      platform: deviceContext.platform,
      appVersion: deviceContext.appVersion,
      requestId: requestId,
    );
    await accountRepository.saveProfile(result.profile);
    await accountRepository.saveTokenSet(result.tokenSet);
    return result;
  }

  void _validateCredential({
    required FacebookLoginPlatform platform,
    required FacebookIdentityCredential credential,
    required FacebookLoginNonce? nonce,
  }) {
    if (credential.tokenString.trim().isEmpty ||
        (platform == FacebookLoginPlatform.ios &&
            (credential.kind != FacebookTokenKind.authenticationToken ||
                nonce == null)) ||
        (platform == FacebookLoginPlatform.android &&
            credential.kind != FacebookTokenKind.accessToken)) {
      throw const FacebookIdentityException(
        FacebookIdentityErrorCode.invalidCredential,
      );
    }
  }

  FacebookLoginPlatform? _platformFor(String value) {
    return switch (value.trim().toUpperCase()) {
      'IOS' => FacebookLoginPlatform.ios,
      'ANDROID' => FacebookLoginPlatform.android,
      _ => null,
    };
  }

  static String _defaultRequestId() =>
      'facebook-login-${DateTime.now().toUtc().microsecondsSinceEpoch}';
}
