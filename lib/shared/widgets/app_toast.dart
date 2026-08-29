import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../app/theme/app_design_tokens.dart';

enum AppToastType { info, success, error }

class AppToast {
  const AppToast._();

  static void info(BuildContext context, String message) {
    _show(context, message, AppToastType.info);
  }

  static void success(BuildContext context, String message) {
    _show(context, message, AppToastType.success);
  }

  static void error(BuildContext context, String message) {
    _show(context, message, AppToastType.error);
  }

  static void _show(BuildContext context, String message, AppToastType type) {
    toastification.dismissAll(delayForAnimation: false);
    toastification.show(
      context: context,
      title: Text(message),
      type: _toastificationType(type),
      style: ToastificationStyle.fillColored,
      autoCloseDuration: const Duration(seconds: 2),
      alignment: Alignment.topCenter,
      animationDuration: const Duration(milliseconds: 220),
      primaryColor: _primaryColor(type),
      foregroundColor: AppColors.toastForeground,
      showProgressBar: false,
      closeOnClick: true,
      dragToClose: true,
    );
  }

  static ToastificationType _toastificationType(AppToastType type) {
    return switch (type) {
      AppToastType.info => ToastificationType.info,
      AppToastType.success => ToastificationType.success,
      AppToastType.error => ToastificationType.error,
    };
  }

  static Color _primaryColor(AppToastType type) {
    return switch (type) {
      AppToastType.info => AppColors.toastInfo,
      AppToastType.success => AppColors.toastSuccess,
      AppToastType.error => AppColors.toastError,
    };
  }
}
