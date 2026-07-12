import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui' as ui;

import 'package:flutter_timezone/flutter_timezone.dart';

import '../../../core/logging/providers.dart';
import '../../../core/network/providers.dart';
import 'forgot_password_code_controller.dart';
import 'forgot_password_controller.dart';
import 'forgot_password_reset_controller.dart';
import 'login_form_controller.dart';
import 'register_code_controller.dart';
import 'register_form_controller.dart';
import 'register_password_controller.dart';
import 'simulated_login_use_case.dart';
import '../../account/application/providers.dart';
import '../data/data_sources/auth_crypto_remote_data_source.dart';
import '../data/data_sources/auth_registration_remote_data_source.dart';
import '../data/data_sources/auth_api.dart';
import '../data/repositories/auth_registration_repository_impl.dart';
import '../data/repositories/auth_crypto_repository_impl.dart';
import '../data/services/rsa_oaep_password_ciphertext_encryptor.dart';
import '../domain/entities/auth_session.dart';
import '../domain/entities/registration_device_context.dart';
import '../domain/repositories/auth_crypto_repository.dart';
import '../domain/repositories/auth_registration_repository.dart';
import '../domain/services/password_ciphertext_encryptor.dart';
import '../domain/use_cases/complete_registration_use_case.dart';
import '../domain/use_cases/send_registration_email_code_use_case.dart';
import '../domain/use_cases/verify_registration_email_code_use_case.dart';
import 'registration_flow_store.dart';

final authSessionProvider = FutureProvider<AuthSession>((ref) async {
  final accountRepository = ref.watch(accountRepositoryProvider);
  final profile = await accountRepository.readCachedProfile();
  final tokenSet = await accountRepository.readTokenSet();
  if (profile == null || tokenSet == null) {
    return const AuthSession.signedOut();
  }

  if (profile.userId.isEmpty || !tokenSet.isUsableAt(DateTime.now())) {
    return const AuthSession.signedOut();
  }

  return AuthSession(isAuthenticated: true, userId: profile.userId);
});

final simulatedLoginUseCaseProvider = Provider<SimulatedLoginUseCase>((ref) {
  return SimulatedLoginUseCase(
    accountRepository: ref.watch(accountRepositoryProvider),
  );
});

final authClientAuthorizationProvider = Provider<String>((ref) {
  return const String.fromEnvironment(
    'FLINX_CLIENT_AUTHORIZATION',
    defaultValue: 'c2FiZXI6c2FiZXJfc2VjcmV0',
  );
});

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(dioProvider));
});

final authCryptoRemoteDataSourceProvider = Provider<AuthCryptoRemoteDataSource>(
  (ref) {
    return AuthCryptoRemoteDataSourceImpl(
      api: ref.watch(authApiProvider),
      clientAuthorization: ref.watch(authClientAuthorizationProvider),
    );
  },
);

final authCryptoRepositoryProvider = Provider<AuthCryptoRepository>((ref) {
  return AuthCryptoRepositoryImpl(
    remoteDataSource: ref.watch(authCryptoRemoteDataSourceProvider),
    logger: ref.watch(appLoggerProvider),
  );
});

final authRegistrationRemoteDataSourceProvider =
    Provider<AuthRegistrationRemoteDataSource>((ref) {
      return AuthRegistrationRemoteDataSourceImpl(
        api: ref.watch(authApiProvider),
        clientAuthorization: ref.watch(authClientAuthorizationProvider),
      );
    });

final authRegistrationRepositoryProvider = Provider<AuthRegistrationRepository>(
  (ref) {
    return AuthRegistrationRepositoryImpl(
      remoteDataSource: ref.watch(authRegistrationRemoteDataSourceProvider),
      logger: ref.watch(appLoggerProvider),
    );
  },
);

final passwordCiphertextEncryptorProvider =
    Provider<PasswordCiphertextEncryptor>((ref) {
      return RsaOaepPasswordCiphertextEncryptor();
    });

final registrationFlowStoreProvider = Provider<RegistrationFlowStore>((ref) {
  return RegistrationFlowStore();
});

final registrationDeviceContextProvider =
    FutureProvider<RegistrationDeviceContext>((ref) async {
      final locale = ui.PlatformDispatcher.instance.locale;
      final localeValue = locale.toLanguageTag();
      final timezone = await FlutterTimezone.getLocalTimezone();
      return RegistrationDeviceContext(
        locale: localeValue.isEmpty ? 'en-US' : localeValue,
        regionCode: locale.countryCode?.isEmpty ?? true
            ? null
            : locale.countryCode,
        timezone: timezone,
      );
    });

final sendRegistrationEmailCodeUseCaseProvider =
    Provider<SendRegistrationEmailCodeUseCase>((ref) {
      return SendRegistrationEmailCodeUseCase(
        repository: ref.watch(authRegistrationRepositoryProvider),
      );
    });

final verifyRegistrationEmailCodeUseCaseProvider =
    Provider<VerifyRegistrationEmailCodeUseCase>((ref) {
      return VerifyRegistrationEmailCodeUseCase(
        repository: ref.watch(authRegistrationRepositoryProvider),
      );
    });

final completeRegistrationUseCaseProvider =
    Provider<CompleteRegistrationUseCase>((ref) {
      return CompleteRegistrationUseCase(
        registrationRepository: ref.watch(authRegistrationRepositoryProvider),
        cryptoRepository: ref.watch(authCryptoRepositoryProvider),
        encryptor: ref.watch(passwordCiphertextEncryptorProvider),
      );
    });

final loginFormControllerProvider =
    NotifierProvider.autoDispose<LoginFormController, LoginFormState>(() {
      return LoginFormController();
    });

final forgotPasswordControllerProvider =
    NotifierProvider.autoDispose<ForgotPasswordController, ForgotPasswordState>(
      () {
        return ForgotPasswordController();
      },
    );

final forgotPasswordCodeControllerProvider =
    NotifierProvider.autoDispose<
      ForgotPasswordCodeController,
      ForgotPasswordCodeState
    >(() {
      return ForgotPasswordCodeController();
    });

final forgotPasswordResetControllerProvider =
    NotifierProvider.autoDispose<
      ForgotPasswordResetController,
      ForgotPasswordResetState
    >(() {
      return ForgotPasswordResetController();
    });

final registerFormControllerProvider =
    NotifierProvider.autoDispose<RegisterFormController, RegisterFormState>(() {
      return RegisterFormController();
    });

final registerCodeControllerProvider =
    NotifierProvider.autoDispose<RegisterCodeController, RegisterCodeState>(() {
      return RegisterCodeController();
    });

final registerPasswordControllerProvider =
    NotifierProvider.autoDispose<
      RegisterPasswordController,
      RegisterPasswordState
    >(() {
      return RegisterPasswordController();
    });
