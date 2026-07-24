import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/logging/providers.dart';
import '../domain/use_cases/refresh_security_balance_use_case.dart';
import 'providers.dart';

final securityBalanceRefreshControllerProvider =
    NotifierProvider<
      SecurityBalanceRefreshController,
      SecurityBalanceRefreshState
    >(SecurityBalanceRefreshController.new);

class SecurityBalanceRefreshController
    extends Notifier<SecurityBalanceRefreshState> {
  late final AppLogger _logger;
  late final RefreshSecurityBalanceUseCase _refreshSecurityBalanceUseCase;
  var _requestCounter = 0;

  @override
  SecurityBalanceRefreshState build() {
    _logger = ref.watch(appLoggerProvider);
    _refreshSecurityBalanceUseCase = ref.watch(
      refreshSecurityBalanceUseCaseProvider,
    );
    return const SecurityBalanceRefreshState();
  }

  Future<void> trigger({required String doorId}) async {
    final normalizedDoorId = doorId.trim();
    if (normalizedDoorId.isEmpty) return;

    final requestId = _nextRequestId(normalizedDoorId);
    state = const SecurityBalanceRefreshState(isLoading: true);
    try {
      final result = await _refreshSecurityBalanceUseCase(
        doorId: normalizedDoorId,
        requestId: requestId,
      );
      state = SecurityBalanceRefreshState(
        serverRequestId: result.requestId,
        status: result.status,
      );
    } on AppError catch (error, stackTrace) {
      state = SecurityBalanceRefreshState(error: error);
      _logger.error(
        'Security balance refresh trigger failed',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'doorId': normalizedDoorId, 'errorCode': error.code.name},
      );
    } catch (error, stackTrace) {
      state = const SecurityBalanceRefreshState(hasUnexpectedError: true);
      _logger.error(
        'Security balance refresh trigger failed',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {
          'doorId': normalizedDoorId,
          'errorKind': error.runtimeType.toString(),
        },
      );
    }
  }

  String _nextRequestId(String doorId) {
    _requestCounter += 1;
    return 'security-balance-refresh-$doorId-'
        '${DateTime.now().millisecondsSinceEpoch}-$_requestCounter';
  }
}

class SecurityBalanceRefreshState {
  const SecurityBalanceRefreshState({
    this.isLoading = false,
    this.serverRequestId,
    this.status,
    this.error,
    this.hasUnexpectedError = false,
  });

  final bool isLoading;
  final String? serverRequestId;
  final String? status;
  final AppError? error;
  final bool hasUnexpectedError;
}
