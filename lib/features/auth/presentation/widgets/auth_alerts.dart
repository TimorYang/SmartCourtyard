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

String registrationErrorMessage(BuildContext context, String? messageKey) {
  final l10n = AppLocalizations.of(context);
  return switch (messageKey) {
    'auth.registration.restartRequired' => l10n.registerRestartRequired,
    'auth.registration.networkUnavailable' => l10n.registerNetworkUnavailable,
    'auth.registration.clientAuthorizationFailed' =>
      l10n.registerAuthorizationFailed,
    _ => l10n.registerRequestFailed,
  };
}

String passwordResetErrorMessage(BuildContext context, String? messageKey) {
  final l10n = AppLocalizations.of(context);
  return switch (messageKey) {
    'auth.passwordReset.networkUnavailable' =>
      l10n.passwordResetNetworkUnavailable,
    'auth.passwordReset.clientAuthorizationFailed' =>
      l10n.passwordResetAuthorizationFailed,
    'auth.passwordReset.restartRequired' => l10n.passwordResetRestartRequired,
    _ => l10n.passwordResetRequestFailed,
  };
}
