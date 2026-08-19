import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import '../../../account/domain/repositories/account_repository.dart';
import '../entities/auth_login_result.dart';
import '../repositories/auth_login_repository.dart';
import '../services/apple_identity_provider.dart';
import '../services/login_device_context_provider.dart';

class AppleLoginUseCase {
  AppleLoginUseCase({
    required this.identityProvider,
    required this.loginRepository,
    required this.accountRepository,
    required this.deviceContextProvider,
    String Function()? requestIdGenerator,
  }) : _requestIdGenerator = requestIdGenerator ?? _defaultRequestId;

  final AppleIdentityProvider identityProvider;
  final AuthLoginRepository loginRepository;
  final AccountRepository accountRepository;
  final LoginDeviceContextProvider deviceContextProvider;
  final String Function() _requestIdGenerator;

  Future<AuthLoginResult> call() async {
    final requestId = _requestIdGenerator();
    final deviceContext = await deviceContextProvider.read();
    final nonce = await loginRepository.getAppleLoginNonce(
      requestId: requestId,
    );
    final credential = await identityProvider.authorize(
      hashedNonce: _sha256(nonce.nonce),
    );
    final result = await loginRepository.loginWithApple(
      nonceId: nonce.nonceId,
      identityToken: credential.identityToken,
      authorizationCode: credential.authorizationCode,
      givenName: credential.givenName,
      familyName: credential.familyName,
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
      'apple-login-${DateTime.now().toUtc().microsecondsSinceEpoch}';

  static String _sha256(String value) {
    final digest = SHA256Digest().process(
      Uint8List.fromList(utf8.encode(value)),
    );
    return digest.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }
}
