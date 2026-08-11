import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/logging/providers.dart';
import '../../../platform_bridge/hardware_models.dart';
import '../domain/entities/safety_sensor_pairing.dart';
import '../domain/use_cases/pair_safety_sensor_use_case.dart';
import 'providers.dart';

final safetySensorPairingControllerProvider =
    NotifierProvider.family<
      SafetySensorPairingController,
      SafetySensorPairingState,
      String
    >((deviceId) => SafetySensorPairingController(deviceId));

class SafetySensorPairingController extends Notifier<SafetySensorPairingState> {
  SafetySensorPairingController(this._deviceId);

  final String _deviceId;
  late final PairSafetySensorUseCase _pairSafetySensor;
  late final AppLogger _logger;
  var _generation = 0;
  var _requestCounter = 0;

  @override
  SafetySensorPairingState build() {
    _pairSafetySensor = ref.watch(pairSafetySensorUseCaseProvider);
    _logger = ref.watch(appLoggerProvider);
    ref.onDispose(() => _generation += 1);
    return const SafetySensorPairingState();
  }

  bool get isPairing =>
      state.phase == SafetySensorPairingPhase.starting ||
      state.phase == SafetySensorPairingPhase.pairing;

  Future<void> start() async {
    if (isPairing || state.phase == SafetySensorPairingPhase.cancelling) {
      return;
    }
    final generation = ++_generation;
    final requestId = _nextRequestId('start');
    state = state.copyWith(
      phase: SafetySensorPairingPhase.starting,
      requestId: requestId,
      clearError: true,
      clearResult: true,
    );
    try {
      final result = await _pairSafetySensor(
        SafetySensorPairingRequest(
          requestId: requestId,
          deviceId: _deviceId,
          action: SafetyAccessoryPairingAction.start,
        ),
      );
      if (!_isCurrent(generation)) return;
      state = state.copyWith(
        phase: switch (result.status) {
          SafetyAccessoryPairingStatus.success =>
            SafetySensorPairingPhase.success,
          SafetyAccessoryPairingStatus.timeout =>
            SafetySensorPairingPhase.timeout,
          SafetyAccessoryPairingStatus.failure ||
          SafetyAccessoryPairingStatus.unknown =>
            SafetySensorPairingPhase.failure,
        },
        result: result,
      );
    } catch (error, stackTrace) {
      if (!_isCurrent(generation)) return;
      _logger.error(
        'Safety sensor pairing failed',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'deviceId': _deviceId},
      );
      state = state.copyWith(
        phase: error is AppError && error.code == AppErrorCode.commandTimeout
            ? SafetySensorPairingPhase.timeout
            : SafetySensorPairingPhase.failure,
        error: error,
      );
    }
  }

  Future<void> cancel() async {
    if (!isPairing || state.phase == SafetySensorPairingPhase.cancelling) {
      return;
    }
    final generation = ++_generation;
    final requestId = _nextRequestId('cancel');
    state = state.copyWith(
      phase: SafetySensorPairingPhase.cancelling,
      requestId: requestId,
      clearError: true,
    );
    try {
      await _pairSafetySensor(
        SafetySensorPairingRequest(
          requestId: requestId,
          deviceId: _deviceId,
          action: SafetyAccessoryPairingAction.cancel,
        ),
      );
    } catch (error) {
      if (!_isCurrent(generation)) return;
      _logger.warning(
        'Safety sensor pairing cancellation failed',
        requestId: requestId,
        context: {'deviceId': _deviceId, 'errorType': error.runtimeType},
      );
    }
  }

  bool _isCurrent(int generation) => ref.mounted && generation == _generation;

  String _nextRequestId(String action) {
    _requestCounter += 1;
    return 'safety-sensor-pairing-$action-'
        '${DateTime.now().millisecondsSinceEpoch}-$_requestCounter';
  }
}

enum SafetySensorPairingPhase {
  idle,
  starting,
  pairing,
  success,
  failure,
  timeout,
  cancelling,
}

class SafetySensorPairingState {
  const SafetySensorPairingState({
    this.phase = SafetySensorPairingPhase.idle,
    this.requestId,
    this.result,
    this.error,
  });

  final SafetySensorPairingPhase phase;
  final String? requestId;
  final SafetySensorPairingResult? result;
  final Object? error;

  int? get reasonCode => result?.reasonCode;

  SafetySensorPairingState copyWith({
    SafetySensorPairingPhase? phase,
    String? requestId,
    SafetySensorPairingResult? result,
    Object? error,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return SafetySensorPairingState(
      phase: phase ?? this.phase,
      requestId: requestId ?? this.requestId,
      result: clearResult ? null : result ?? this.result,
      error: clearError ? null : error ?? this.error,
    );
  }
}
