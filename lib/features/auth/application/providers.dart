import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../../core/logging/providers.dart';
import '../../../core/network/providers.dart';
import '../../../core/network/session_expired_handler.dart';
import 'forgot_password_code_controller.dart';
import 'apple_login_controller.dart';
import 'facebook_login_controller.dart';
import 'google_login_controller.dart';
import 'forgot_password_controller.dart';
import 'forgot_password_reset_controller.dart';
import 'login_form_controller.dart';
import 'auth_session_controller.dart';
import 'register_code_controller.dart';
import 'register_form_controller.dart';
import 'register_password_controller.dart';
import '../../account/application/providers.dart';
import '../data/data_sources/auth_crypto_remote_data_source.dart';
import '../data/data_sources/auth_login_remote_data_source.dart';
import '../data/data_sources/auth_password_reset_remote_data_source.dart';
import '../data/data_sources/auth_registration_remote_data_source.dart';
import '../data/data_sources/auth_api.dart';
import '../data/repositories/auth_registration_repository_impl.dart';
import '../data/repositories/auth_crypto_repository_impl.dart';
import '../data/repositories/auth_login_repository_impl.dart';
import '../data/repositories/auth_password_reset_repository_impl.dart';
import '../data/services/rsa_oaep_password_ciphertext_encryptor.dart';
import '../data/services/auth_token_refresh_service.dart';
import '../data/services/sign_in_with_apple_identity_provider.dart';
import '../data/services/facebook_sign_in_identity_provider.dart';
import '../data/services/google_sign_in_identity_provider.dart';
import '../domain/entities/auth_session.dart';
import '../domain/entities/registration_device_context.dart';
import '../domain/repositories/auth_crypto_repository.dart';
import '../domain/repositories/auth_login_repository.dart';
import '../domain/repositories/auth_password_reset_repository.dart';
import '../domain/repositories/auth_registration_repository.dart';
import '../domain/services/password_ciphertext_encryptor.dart';
import '../domain/services/apple_identity_provider.dart';
import '../domain/services/facebook_identity_provider.dart';
import '../domain/services/google_identity_provider.dart';
import '../domain/use_cases/complete_registration_use_case.dart';
import '../domain/use_cases/complete_password_reset_use_case.dart';
import '../domain/use_cases/login_use_case.dart';
import '../domain/use_cases/apple_login_use_case.dart';
import '../domain/use_cases/facebook_login_use_case.dart';
import '../domain/use_cases/google_login_use_case.dart';
import '../domain/use_cases/send_registration_email_code_use_case.dart';
import '../domain/use_cases/send_password_reset_email_code_use_case.dart';
import '../domain/use_cases/verify_registration_email_code_use_case.dart';
import '../domain/use_cases/verify_password_reset_email_code_use_case.dart';
import 'registration_flow_store.dart';
import 'password_reset_flow_store.dart';
import 'login_device_context_provider.dart';

export 'login_device_context_provider.dart';

final authSessionProvider = FutureProvider<AuthSession>((ref) async {
  final activeSession = ref.watch(activeAuthSessionProvider);
  if (activeSession.isAuthenticated) {
    return activeSession;
  }
  if (!activeSession.canRestoreFromCache) {
    return activeSession;
  }
  final accountRepository = ref.watch(accountRepositoryProvider);
  final profile = await accountRepository.readCachedProfile();
  final tokenSet = await accountRepository.readTokenSet();
  if (profile == null || tokenSet == null || profile.userId.isEmpty) {
    return const AuthSession.signedOut();
  }

  if (!tokenSet.isUsableAt(DateTime.now())) {
    try {
      final refreshResult = await ref
          .read(authTokenRefreshServiceProvider)
          .refreshExpiredAccessToken();
      if (refreshResult == TokenRefreshResult.sessionExpired) {
        await ref.read(sessionExpiredHandlerProvider)();
        return const AuthSession.signedOutAfterClear();
      }
      final refreshedTokenSet = await accountRepository.readTokenSet();
      if (refreshedTokenSet != null &&
          refreshedTokenSet.isUsableAt(DateTime.now())) {
        return AuthSession(isAuthenticated: true, userId: profile.userId);
      }
    } on Object {
      // A transient refresh failure must not erase a still-valid refresh token.
    }
    return const AuthSession.signedOut();
  }

  return AuthSession(isAuthenticated: true, userId: profile.userId);
});

final activeAuthSessionProvider =
    NotifierProvider<AuthSessionController, AuthSession>(
      AuthSessionController.new,
    );

final authClientAuthorizationProvider = Provider<String>((ref) {
  return const String.fromEnvironment(
    'FLINX_CLIENT_AUTHORIZATION',
    defaultValue: 'c2FiZXI6c2FiZXJfc2VjcmV0',
  );
});

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(dioProvider));
});

final authTokenRefreshServiceProvider = Provider<AuthTokenRefreshService>((
  ref,
) {
  return AuthTokenRefreshService(
    api: ref.watch(authApiProvider),
    accountRepository: ref.watch(accountRepositoryProvider),
    deviceContextProvider: ref.watch(loginDeviceContextProvider),
  );
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

final authLoginRemoteDataSourceProvider = Provider<AuthLoginRemoteDataSource>(
  (ref) => AuthLoginRemoteDataSourceImpl(
    api: ref.watch(authApiProvider),
    clientAuthorization: ref.watch(authClientAuthorizationProvider),
  ),
);

final authLoginRepositoryProvider = Provider<AuthLoginRepository>((ref) {
  return AuthLoginRepositoryImpl(
    remoteDataSource: ref.watch(authLoginRemoteDataSourceProvider),
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

final authPasswordResetRemoteDataSourceProvider =
    Provider<AuthPasswordResetRemoteDataSource>((ref) {
      return AuthPasswordResetRemoteDataSourceImpl(
        api: ref.watch(authApiProvider),
        clientAuthorization: ref.watch(authClientAuthorizationProvider),
      );
    });

final authPasswordResetRepositoryProvider =
    Provider<AuthPasswordResetRepository>((ref) {
      return AuthPasswordResetRepositoryImpl(
        remoteDataSource: ref.watch(authPasswordResetRemoteDataSourceProvider),
        logger: ref.watch(appLoggerProvider),
      );
    });

final passwordCiphertextEncryptorProvider =
    Provider<PasswordCiphertextEncryptor>((ref) {
      return RsaOaepPasswordCiphertextEncryptor();
    });

final registrationFlowStoreProvider = Provider<RegistrationFlowStore>((ref) {
  return RegistrationFlowStore();
});

final passwordResetFlowStoreProvider = Provider<PasswordResetFlowStore>((ref) {
  return PasswordResetFlowStore();
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

final sendPasswordResetEmailCodeUseCaseProvider =
    Provider<SendPasswordResetEmailCodeUseCase>((ref) {
      return SendPasswordResetEmailCodeUseCase(
        repository: ref.watch(authPasswordResetRepositoryProvider),
      );
    });

final verifyPasswordResetEmailCodeUseCaseProvider =
    Provider<VerifyPasswordResetEmailCodeUseCase>((ref) {
      return VerifyPasswordResetEmailCodeUseCase(
        repository: ref.watch(authPasswordResetRepositoryProvider),
      );
    });

final completePasswordResetUseCaseProvider =
    Provider<CompletePasswordResetUseCase>((ref) {
      return CompletePasswordResetUseCase(
        passwordResetRepository: ref.watch(authPasswordResetRepositoryProvider),
        cryptoRepository: ref.watch(authCryptoRepositoryProvider),
        encryptor: ref.watch(passwordCiphertextEncryptorProvider),
      );
    });

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(
    loginRepository: ref.watch(authLoginRepositoryProvider),
    cryptoRepository: ref.watch(authCryptoRepositoryProvider),
    encryptor: ref.watch(passwordCiphertextEncryptorProvider),
    accountRepository: ref.watch(accountRepositoryProvider),
    deviceContextProvider: ref.watch(loginDeviceContextProvider),
  );
});

final appleIdentityProvider = Provider<AppleIdentityProvider>((ref) {
  return SignInWithAppleIdentityProvider();
});

final appleLoginUseCaseProvider = Provider<AppleLoginUseCase>((ref) {
  return AppleLoginUseCase(
    identityProvider: ref.watch(appleIdentityProvider),
    loginRepository: ref.watch(authLoginRepositoryProvider),
    accountRepository: ref.watch(accountRepositoryProvider),
    deviceContextProvider: ref.watch(loginDeviceContextProvider),
  );
});

final appleLoginPlatformSupportedProvider = Provider<bool>((ref) {
  return defaultTargetPlatform == TargetPlatform.iOS;
});

final appleLoginControllerProvider =
    NotifierProvider.autoDispose<AppleLoginController, AppleLoginState>(
      AppleLoginController.new,
    );

final googleIdentityProvider = Provider<GoogleIdentityProvider>((ref) {
  return GoogleSignInIdentityProvider();
});

final googleLoginUseCaseProvider = Provider<GoogleLoginUseCase>((ref) {
  return GoogleLoginUseCase(
    identityProvider: ref.watch(googleIdentityProvider),
    loginRepository: ref.watch(authLoginRepositoryProvider),
    accountRepository: ref.watch(accountRepositoryProvider),
    deviceContextProvider: ref.watch(loginDeviceContextProvider),
  );
});

final googleLoginControllerProvider =
    NotifierProvider.autoDispose<GoogleLoginController, GoogleLoginState>(
      GoogleLoginController.new,
    );

final facebookIdentityProvider = Provider<FacebookIdentityProvider>((ref) {
  return FacebookSignInIdentityProvider();
});

final facebookLoginUseCaseProvider = Provider<FacebookLoginUseCase>((ref) {
  return FacebookLoginUseCase(
    identityProvider: ref.watch(facebookIdentityProvider),
    loginRepository: ref.watch(authLoginRepositoryProvider),
    accountRepository: ref.watch(accountRepositoryProvider),
    deviceContextProvider: ref.watch(loginDeviceContextProvider),
  );
});

final facebookLoginControllerProvider =
    NotifierProvider.autoDispose<FacebookLoginController, FacebookLoginState>(
      FacebookLoginController.new,
    );

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
