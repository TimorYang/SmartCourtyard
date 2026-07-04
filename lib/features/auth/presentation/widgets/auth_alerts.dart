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
