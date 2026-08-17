import '../../../account/domain/repositories/account_repository.dart';
import '../entities/auth_login_result.dart';
import '../repositories/auth_login_repository.dart';
import '../services/apple_identity_provider.dart';

class AppleLoginUseCase {
  AppleLoginUseCase({
    required this.identityProvider,
    required this.loginRepository,
    required this.accountRepository,
    String Function()? requestIdGenerator,
  }) : _requestIdGenerator = requestIdGenerator ?? _defaultRequestId;

  final AppleIdentityProvider identityProvider;
  final AuthLoginRepository loginRepository;
  final AccountRepository accountRepository;
  final String Function() _requestIdGenerator;

  Future<AuthLoginResult> call() async {
    final credential = await identityProvider.authorize();
    final result = await loginRepository.loginWithApple(
      identityToken: credential.identityToken,
      requestId: _requestIdGenerator(),
    );
    await accountRepository.saveProfile(result.profile);
    await accountRepository.saveTokenSet(result.tokenSet);
    return result;
  }

  static String _defaultRequestId() =>
      'apple-login-${DateTime.now().toUtc().microsecondsSinceEpoch}';
}
