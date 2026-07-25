import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/device_setting.dart';
import '../domain/repositories/device_settings_repository.dart';
import '../domain/use_cases/query_device_settings_use_case.dart';
import '../domain/use_cases/set_device_setting_use_case.dart';
import 'providers.dart';

final deviceSettingsControllerProvider =
    NotifierProvider.family<
      DeviceSettingsController,
      DeviceSettingsState,
      String
    >((deviceId) => DeviceSettingsController(deviceId));

class DeviceSettingsState {
  const DeviceSettingsState({
    this.values = const <DeviceSettingKey, DeviceSettingValue>{},
    this.loading = true,
    this.pendingKey,
    this.errorMessage,
  });

  final Map<DeviceSettingKey, DeviceSettingValue> values;
  final bool loading;
  final DeviceSettingKey? pendingKey;
  final String? errorMessage;

  DeviceSettingsState copyWith({
    Map<DeviceSettingKey, DeviceSettingValue>? values,
    bool? loading,
    DeviceSettingKey? pendingKey,
    bool clearPendingKey = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DeviceSettingsState(
      values: values ?? this.values,
      loading: loading ?? this.loading,
      pendingKey: clearPendingKey ? null : pendingKey ?? this.pendingKey,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class DeviceSettingsController extends Notifier<DeviceSettingsState> {
  DeviceSettingsController(this.deviceId);

  final String deviceId;
  late final QueryDeviceSettingsUseCase _query;
  late final SetDeviceSettingUseCase _set;
  late final DeviceSettingsRepository _repository;
  StreamSubscription<Map<DeviceSettingKey, DeviceSettingValue>>? _subscription;
  int _requestCounter = 0;

  @override
  DeviceSettingsState build() {
    _query = ref.watch(queryDeviceSettingsUseCaseProvider);
    _set = ref.watch(setDeviceSettingUseCaseProvider);
    _repository = ref.watch(deviceSettingsRepositoryProvider);
    _subscription = _repository
        .watchSettings(deviceId: deviceId)
        .listen(_applyValues, onError: _applyStreamError);
    ref.onDispose(() => unawaited(_subscription?.cancel()));
    Future.microtask(load);
    return const DeviceSettingsState();
  }

  Future<void> load() async {
    if (!ref.mounted) {
      return;
    }
    if (deviceId.trim().isEmpty) {
      state = state.copyWith(loading: false, clearError: true);
      return;
    }
    state = state.copyWith(loading: true, clearError: true);
    try {
      final values = await _query(
        requestId: _nextRequestId('query'),
        deviceId: deviceId,
      );
      if (!ref.mounted) {
        return;
      }
      _applyValues(values);
    } catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(loading: false, errorMessage: error.toString());
    }
  }

  Future<bool> setRawValue(DeviceSettingKey key, int rawValue) async {
    if (deviceId.trim().isEmpty || state.pendingKey != null) {
      return false;
    }
    state = state.copyWith(pendingKey: key, clearError: true);
    try {
      await _set(
        requestId: _nextRequestId('set-${key.name}'),
        deviceId: deviceId,
        key: key,
        rawValue: rawValue,
      );
      if (!ref.mounted) {
        return false;
      }
      final values = await _query(
        requestId: _nextRequestId('refresh'),
        deviceId: deviceId,
      );
      if (!ref.mounted) {
        return false;
      }
      _applyValues(values);
      return true;
    } catch (error) {
      if (!ref.mounted) {
        return false;
      }
      state = state.copyWith(
        errorMessage: error.toString(),
        clearPendingKey: true,
      );
      return false;
    }
  }

  void _applyValues(Map<DeviceSettingKey, DeviceSettingValue> values) {
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(
      values: Map<DeviceSettingKey, DeviceSettingValue>.unmodifiable(values),
      loading: false,
      clearPendingKey: true,
      clearError: true,
    );
  }

  void _applyStreamError(Object error, StackTrace stackTrace) {
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(loading: false, errorMessage: error.toString());
  }

  String _nextRequestId(String operation) {
    _requestCounter++;
    return 'device-settings-$operation-${DateTime.now().microsecondsSinceEpoch}-$_requestCounter';
  }
}
