import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/logging/providers.dart';
import '../domain/entities/safety_sensor_management.dart';
import '../domain/use_cases/safety_sensor_management_delete_use_case.dart';
import '../domain/use_cases/safety_sensor_management_query_use_case.dart';
import 'safety_sensor_management_providers.dart';

final safetySensorManagementControllerProvider =
    NotifierProvider.family<
      SafetySensorManagementController,
      SafetySensorManagementState,
      String
    >((deviceId) => SafetySensorManagementController(deviceId));

class SafetySensorManagementController
    extends Notifier<SafetySensorManagementState> {
  SafetySensorManagementController(this._deviceId);

  final String _deviceId;
  late final SafetySensorManagementQueryUseCase _query;
  late final SafetySensorManagementDeleteUseCase _delete;
  late final AppLogger _logger;
  var _requestCounter = 0;
  var _generation = 0;

  @override
  SafetySensorManagementState build() {
    _query = ref.watch(safetySensorManagementQueryUseCaseProvider);
    _delete = ref.watch(safetySensorManagementDeleteUseCaseProvider);
    _logger = ref.watch(appLoggerProvider);
    ref.onDispose(() => _generation += 1);
    return const SafetySensorManagementState();
  }

  Future<void> load() async {
    if (state.loading) return;
    final generation = ++_generation;
    final requestId = _nextRequestId('query');
    state = state.copyWith(loading: true, clearError: true);
    try {
      final management = await _query(
        requestId: requestId,
        deviceId: _deviceId,
      );
      if (!_isCurrent(generation)) return;
      state = state.copyWith(
        loading: false,
        sensors: management.sensors,
        clearError: true,
      );
    } catch (error, stackTrace) {
      if (!_isCurrent(generation)) return;
      _logger.error(
        'Safety sensor management query failed',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'deviceId': _deviceId},
      );
      state = state.copyWith(loading: false, error: error);
    }
  }

  Future<bool> deleteSensor(SafetySensorManagementItem sensor) async {
    if (state.deletingSerialNumber != null) return false;
    final requestId = _nextRequestId('delete');
    state = state.copyWith(
      deletingSerialNumber: sensor.serialNumber,
      clearError: true,
    );
    try {
      await _delete(
        requestId: requestId,
        deviceId: _deviceId,
        serialNumber: sensor.serialNumber,
      );
      if (!ref.mounted) return false;
      state = state.copyWith(
        sensors: state.sensors
            .where((item) => item.serialNumber != sensor.serialNumber)
            .toList(growable: false),
        clearDeleting: true,
      );
      await load();
      return true;
    } catch (error, stackTrace) {
      if (!ref.mounted) return false;
      _logger.error(
        'Safety sensor management deletion failed',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {
          'deviceId': _deviceId,
          'serialNumber': sensor.id,
          'type': sensor.type.name,
        },
      );
      state = state.copyWith(error: error, clearDeleting: true);
      return false;
    }
  }

  bool _isCurrent(int generation) => ref.mounted && generation == _generation;

  String _nextRequestId(String action) =>
      'safety-sensor-management-$action-'
      '${DateTime.now().millisecondsSinceEpoch}-${++_requestCounter}';
}

class SafetySensorManagementState {
  const SafetySensorManagementState({
    this.loading = false,
    this.sensors = const <SafetySensorManagementItem>[],
    this.deletingSerialNumber,
    this.error,
  });

  final bool loading;
  final List<SafetySensorManagementItem> sensors;
  final int? deletingSerialNumber;
  final Object? error;

  SafetySensorManagementState copyWith({
    bool? loading,
    List<SafetySensorManagementItem>? sensors,
    int? deletingSerialNumber,
    Object? error,
    bool clearDeleting = false,
    bool clearError = false,
  }) => SafetySensorManagementState(
    loading: loading ?? this.loading,
    sensors: sensors ?? this.sensors,
    deletingSerialNumber: clearDeleting
        ? null
        : deletingSerialNumber ?? this.deletingSerialNumber,
    error: clearError ? null : error ?? this.error,
  );
}
