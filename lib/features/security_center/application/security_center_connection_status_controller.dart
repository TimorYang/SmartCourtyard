import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/logging/providers.dart';
import '../domain/use_cases/fetch_security_center_connection_status_use_case.dart';
import 'providers.dart';

final securityCenterConnectionStatusControllerProvider =
    NotifierProvider<
      SecurityCenterConnectionStatusController,
      SecurityCenterConnectionStatusState
    >(SecurityCenterConnectionStatusController.new);

class SecurityCenterConnectionStatusController
    extends Notifier<SecurityCenterConnectionStatusState> {
  late final AppLogger _logger;
  late final FetchSecurityCenterConnectionStatusUseCase _fetchConnectionStatus;
  var _requestCounter = 0;

  @override
  SecurityCenterConnectionStatusState build() {
    _logger = ref.watch(appLoggerProvider);
    _fetchConnectionStatus = ref.watch(
      fetchSecurityCenterConnectionStatusUseCaseProvider,
    );
    return const SecurityCenterConnectionStatusState();
  }

  Future<bool> check({required String doorId}) async {
    final normalizedDoorId = doorId.trim();
    if (normalizedDoorId.isEmpty) return false;

    final requestId = _nextRequestId(normalizedDoorId);
    state = const SecurityCenterConnectionStatusState(isLoading: true);
    try {
      final connectionStatus = await _fetchConnectionStatus(
        doorId: normalizedDoorId,
        requestId: requestId,
      );
      final isBlocked = connectionStatus.isWifiDisconnected;
      state = SecurityCenterConnectionStatusState(isBlocked: isBlocked);
      return isBlocked;
    } on AppError catch (error, stackTrace) {
      state = SecurityCenterConnectionStatusState(error: error);
      _logger.error(
        'Security center connection status check failed',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'doorId': normalizedDoorId, 'errorCode': error.code.name},
      );
      return false;
    } catch (error, stackTrace) {
      state = const SecurityCenterConnectionStatusState(
        hasUnexpectedError: true,
      );
      _logger.error(
        'Security center connection status check failed',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {
          'doorId': normalizedDoorId,
          'errorKind': error.runtimeType.toString(),
        },
      );
      return false;
    }
  }

  String _nextRequestId(String doorId) {
    _requestCounter += 1;
    return 'security-center-connection-status-$doorId-'
        '${DateTime.now().millisecondsSinceEpoch}-$_requestCounter';
  }
}

class SecurityCenterConnectionStatusState {
  const SecurityCenterConnectionStatusState({
    this.isLoading = false,
    this.isBlocked = false,
    this.error,
    this.hasUnexpectedError = false,
  });

  final bool isLoading;
  final bool isBlocked;
  final AppError? error;
  final bool hasUnexpectedError;
}
