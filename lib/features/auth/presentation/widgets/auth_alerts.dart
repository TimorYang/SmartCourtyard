import 'package:flutter/material.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';

import '../../../../shared/l10n/app_localizations.dart';

Future<void> showAuthEmailInvalidDialog(BuildContext context) async {
  await FlutterPlatformAlert.showCustomAlert(
    windowTitle: '',
    text: AppLocalizations.of(context).loginEmailInvalid,
    positiveButtonTitle: MaterialLocalizations.of(context).okButtonLabel,
  );
}

String registrationErrorMessage(
  BuildContext context,
  String? messageKey, {
  String? userMessage,
}) {
  final normalizedUserMessage = userMessage?.trim();
  if (normalizedUserMessage?.isNotEmpty == true) return normalizedUserMessage!;
  final l10n = AppLocalizations.of(context);
  return switch (messageKey) {
    'networkErrorUnavailable' => l10n.networkErrorUnavailable,
    'networkErrorSessionExpired' => l10n.networkErrorSessionExpired,
    'networkErrorAccessDenied' => l10n.networkErrorAccessDenied,
    'networkErrorRequestTimeout' => l10n.networkErrorRequestTimeout,
    'networkErrorRateLimited' => l10n.networkErrorRateLimited,
    'networkErrorRequestFailed' => l10n.networkErrorRequestFailed,
    'networkErrorServiceUnavailable' => l10n.networkErrorServiceUnavailable,
    'auth.registration.restartRequired' => l10n.registerRestartRequired,
    'auth.registration.networkUnavailable' => l10n.registerNetworkUnavailable,
    'auth.registration.clientAuthorizationFailed' =>
      l10n.registerAuthorizationFailed,
    'auth.password.invalid' => l10n.authPasswordInvalid,
    _ => l10n.registerRequestFailed,
  };
}

String passwordResetErrorMessage(
  BuildContext context,
  String? messageKey, {
  String? userMessage,
}) {
  final normalizedUserMessage = userMessage?.trim();
  if (normalizedUserMessage?.isNotEmpty == true) return normalizedUserMessage!;
  final l10n = AppLocalizations.of(context);
  return switch (messageKey) {
    'networkErrorUnavailable' => l10n.networkErrorUnavailable,
    'networkErrorSessionExpired' => l10n.networkErrorSessionExpired,
    'networkErrorAccessDenied' => l10n.networkErrorAccessDenied,
    'networkErrorRequestTimeout' => l10n.networkErrorRequestTimeout,
    'networkErrorRateLimited' => l10n.networkErrorRateLimited,
    'networkErrorRequestFailed' => l10n.networkErrorRequestFailed,
    'networkErrorServiceUnavailable' => l10n.networkErrorServiceUnavailable,
    'auth.passwordReset.networkUnavailable' =>
      l10n.passwordResetNetworkUnavailable,
    'auth.passwordReset.clientAuthorizationFailed' =>
      l10n.passwordResetAuthorizationFailed,
    'auth.passwordReset.restartRequired' => l10n.passwordResetRestartRequired,
    'auth.password.invalid' => l10n.authPasswordInvalid,
    _ => l10n.passwordResetRequestFailed,
  };
}
