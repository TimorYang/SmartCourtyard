import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../app/theme/app_design_tokens.dart';

enum AppToastType { info, success, error }

class AppToast {
  const AppToast._();

  static var _serverErrorPending = false;
  static String? _activeServerErrorId;

  static void info(BuildContext context, String message) {
    _show(context, message, AppToastType.info);
  }

  static void success(BuildContext context, String message) {
    _show(context, message, AppToastType.success);
  }

  static void error(BuildContext context, String message) {
    if (_hasServerErrorPriority) return;
    _show(context, message, AppToastType.error);
  }

  static void reserveServerError() {
    _serverErrorPending = true;
  }

  static void cancelServerErrorReservation() {
    _serverErrorPending = false;
  }

  static void serverError(BuildContext context, String message) {
    final item = _show(
      context,
      message,
      AppToastType.error,
      callbacks: ToastificationCallbacks(
        onAutoCompleteCompleted: _clearServerError,
        onDismissed: _clearServerError,
      ),
    );
    _activeServerErrorId = item.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _serverErrorPending = false;
    });
  }

  static bool get _hasServerErrorPriority {
    if (_serverErrorPending) return true;
    final activeId = _activeServerErrorId;
    if (activeId == null) return false;
    if (toastification.findToastificationItem(activeId) != null) return true;
    _activeServerErrorId = null;
    return false;
  }

  static void _clearServerError(ToastificationItem item) {
    if (_activeServerErrorId == item.id) _activeServerErrorId = null;
  }

  static ToastificationItem _show(
    BuildContext context,
    String message,
    AppToastType type, {
    ToastificationCallbacks callbacks = const ToastificationCallbacks(),
  }) {
    toastification.dismissAll(delayForAnimation: false);
    return toastification.show(
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
      callbacks: callbacks,
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
