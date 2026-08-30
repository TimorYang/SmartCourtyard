import '../../../account/domain/repositories/account_repository.dart';
import '../entities/auth_login_result.dart';
import '../repositories/auth_login_repository.dart';
import '../services/google_identity_provider.dart';
import '../services/login_device_context_provider.dart';

class GoogleLoginUseCase {
  GoogleLoginUseCase({
    required this.identityProvider,
    required this.loginRepository,
    required this.accountRepository,
    required this.deviceContextProvider,
    String Function()? requestIdGenerator,
  }) : _requestIdGenerator = requestIdGenerator ?? _defaultRequestId;

  final GoogleIdentityProvider identityProvider;
  final AuthLoginRepository loginRepository;
  final AccountRepository accountRepository;
  final LoginDeviceContextProvider deviceContextProvider;
  final String Function() _requestIdGenerator;

  Future<AuthLoginResult> call() async {
    final requestId = _requestIdGenerator();
    final deviceContext = await deviceContextProvider.read();
    final nonce = await loginRepository.getGoogleLoginNonce(
      requestId: requestId,
    );
    final credential = await identityProvider.authorize(nonce: nonce.nonce);
    final idToken = credential.idToken.trim();
    final authorizationCode = credential.authorizationCode.trim();
    if (idToken.isEmpty || authorizationCode.isEmpty) {
      throw const GoogleIdentityException(
        GoogleIdentityErrorCode.invalidCredential,
      );
    }

    final result = await loginRepository.loginWithGoogle(
      nonceId: nonce.nonceId,
      idToken: idToken,
      authorizationCode: authorizationCode,
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

  static String _defaultRequestId() =>
      'google-login-${DateTime.now().toUtc().microsecondsSinceEpoch}';
}
