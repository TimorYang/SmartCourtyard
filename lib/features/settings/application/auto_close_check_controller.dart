import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error_message.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/logging/providers.dart';
import '../domain/use_cases/check_auto_close_allowed_use_case.dart';
import 'providers.dart';

typedef AutoCloseCheckRequest = ({String doorId, String deviceId});

final autoCloseCheckControllerProvider = NotifierProvider.autoDispose
    .family<
      AutoCloseCheckController,
      AutoCloseCheckState,
      AutoCloseCheckRequest
    >((request) => AutoCloseCheckController(request));

class AutoCloseCheckState {
  const AutoCloseCheckState({
    this.checking = false,
    this.autoCloseAllowed,
    this.errorMessage,
  });

  final bool checking;
  final bool? autoCloseAllowed;
  final String? errorMessage;

  bool get hasError => errorMessage != null;
}

class AutoCloseCheckController extends Notifier<AutoCloseCheckState> {
  AutoCloseCheckController(this.request);

  final AutoCloseCheckRequest request;
  late final CheckAutoCloseAllowedUseCase _checkAutoClose;
  late final AppLogger _logger;
  var _requestCounter = 0;

  @override
  AutoCloseCheckState build() {
    _checkAutoClose = ref.watch(checkAutoCloseAllowedUseCaseProvider);
    _logger = ref.watch(appLoggerProvider);
    return const AutoCloseCheckState();
  }

  Future<bool> checkAllowed() async {
    if (!ref.mounted || state.checking) {
      return false;
    }

    final requestId = _nextRequestId();
    state = AutoCloseCheckState(
      checking: true,
      autoCloseAllowed: state.autoCloseAllowed,
    );
    try {
      final result = await _checkAutoClose(
        doorId: request.doorId,
        deviceId: request.deviceId,
        requestId: requestId,
      );
      if (!ref.mounted) {
        return false;
      }
      state = AutoCloseCheckState(autoCloseAllowed: result.autoCloseAllowed);
      return result.autoCloseAllowed;
    } catch (error, stackTrace) {
      if (!ref.mounted) {
        return false;
      }
      _logger.error(
        'Auto-close availability check failed',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'doorId': request.doorId, 'deviceId': request.deviceId},
      );
      state = AutoCloseCheckState(errorMessage: appErrorMessage(error, ''));
      return false;
    }
  }

  String _nextRequestId() {
    _requestCounter++;
    return 'auto-close-check-${request.doorId}-${request.deviceId}-'
        '${DateTime.now().microsecondsSinceEpoch}-$_requestCounter';
  }
}
