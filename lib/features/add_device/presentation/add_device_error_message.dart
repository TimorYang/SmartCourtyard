import 'package:flutter/widgets.dart';

import '../../../shared/l10n/app_localizations.dart';
import '../application/add_device_controller.dart';

String localizedAddDeviceErrorMessage(
  BuildContext context,
  AddDeviceState state, {
  required String fallback,
}) {
  final l10n = AppLocalizations.of(context);
  return switch (state.errorMessageKey) {
    'addDevice.deviceAlreadyBoundToCurrentUser' =>
      l10n.smartOpenerAlreadyBoundToCurrentUser,
    'addDevice.deviceAlreadyBoundToAnotherUser' =>
      l10n.smartOpenerAlreadyBoundToAnotherUser,
    _ => state.errorMessage ?? fallback,
  };
}
