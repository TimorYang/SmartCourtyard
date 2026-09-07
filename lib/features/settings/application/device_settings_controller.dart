import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error_message.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/logging/providers.dart';

import '../domain/entities/device_capability.dart';
import '../domain/entities/device_setting.dart';
import '../domain/entities/device_settings_snapshot.dart';
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

int? matchingDeviceSettingCandidate(
  DeviceSettingValue? value,
  Iterable<int> allowedValues,
) {
  if (value == null) {
    return null;
  }
  final allowed = allowedValues.toSet();
  final candidates = value.candidateValues.isEmpty
      ? <int>[value.rawValue]
      : value.candidateValues;
  for (final candidate in candidates) {
    if (allowed.contains(candidate)) {
      return candidate;
    }
  }
  return null;
}

DeviceCapabilityOption? matchingDeviceSettingCapabilityOption({
  required DeviceCapability? capability,
  required DeviceSettingKey key,
  required int? reportedValue,
}) {
  if (capability == null || reportedValue == null) {
    return null;
  }
  // 0x2713 may be reported in the upgraded tens representation. Normalize
  // that report before matching the capability's original 0x01-0x09 values.
  final normalizedValue = key.fromProtocolValue(reportedValue);
  for (final option in capability.options) {
    if (option.value == normalizedValue) {
      return option;
    }
  }
  return null;
}

Set<int> autoCloseReportedTimeCandidates({
  required DeviceCapability? capability,
  required int value,
}) {
  final candidates = <int>{value};
  final option = capability?.options
      .where((option) => option.value == value)
      .firstOrNull;
  if (option == null) {
    return candidates;
  }
  final numericLabel = RegExp(r'\d+').firstMatch(option.label)?.group(0);
  final parsedLabel = numericLabel == null ? null : int.tryParse(numericLabel);
  if (parsedLabel != null) {
    candidates.add(parsedLabel);
  }
  return candidates;
}

DeviceCapabilityOption? matchingAutoCloseReportedOption({
  required DeviceCapability? capability,
  required Iterable<int> reportedValues,
}) {
  if (capability == null) {
    return null;
  }
  final reported = reportedValues.toSet();
  for (final option in capability.options) {
    if (autoCloseReportedTimeCandidates(
      capability: capability,
      value: option.value,
    ).any(reported.contains)) {
      return option;
    }
  }
  return null;
}

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

enum AutoCloseSaveStatus { confirmed, unchanged, writeFailed, invalid, busy }

class AutoCloseConfigurationResult {
  const AutoCloseConfigurationResult({
    required this.status,
    required this.positionChanged,
    required this.timeChanged,
  });

  final AutoCloseSaveStatus status;
  final bool positionChanged;
  final bool timeChanged;

  bool get saved =>
      status == AutoCloseSaveStatus.confirmed ||
      status == AutoCloseSaveStatus.unchanged;
}

class DeviceSettingsController extends Notifier<DeviceSettingsState> {
  DeviceSettingsController(this.deviceId);

  final String deviceId;
  late final QueryDeviceSettingsUseCase _query;
  late final SetDeviceSettingUseCase _set;
  late final DeviceSettingsRepository _repository;
  late final AppLogger _logger;
  StreamSubscription<DeviceSettingsSnapshot>? _subscription;
  int _requestCounter = 0;
  // Reports remain authoritative, but cannot move a setting while its write
  // is awaiting a reply. Keep the latest report for reconciliation afterward.
  final Map<DeviceSettingKey, DeviceSettingValue?> _lockedValues = {};
  final Map<DeviceSettingKey, DeviceSettingValue?> _deferredValues = {};

  @override
  DeviceSettingsState build() {
    _query = ref.watch(queryDeviceSettingsUseCaseProvider);
    _set = ref.watch(setDeviceSettingUseCaseProvider);
    _repository = ref.watch(deviceSettingsRepositoryProvider);
    _logger = ref.watch(appLoggerProvider);
    _subscription = _repository
        .watchSettings(deviceId: deviceId)
        .listen(_applySnapshot, onError: _applyStreamError);
    ref.onDispose(() {
      unawaited(_subscription?.cancel());
    });
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
      state = state.copyWith(
        loading: false,
        errorMessage: appErrorMessage(error, ''),
      );
    }
  }

  Future<bool> setRawValue(
    DeviceSettingKey key,
    int rawValue, {
    Iterable<int>? allowedValues,
  }) async {
    if (deviceId.trim().isEmpty || state.pendingKey != null) {
      return false;
    }
    if (key == DeviceSettingKey.autoCloseTime) {
      final capabilityValues = allowedValues?.toSet() ?? const <int>{};
      if (rawValue < 0 ||
          rawValue > 9 ||
          capabilityValues.isEmpty ||
          (rawValue != 0 && !capabilityValues.contains(rawValue))) {
        return false;
      }
      final result = await _setAutoCloseValue(
        position: _currentAutoClosePosition(),
        time: rawValue,
        allowedTimeValues: capabilityValues,
      );
      return result.saved;
    }
    final value = DeviceSettingValue(
      key: key,
      rawValue: key.toProtocolValue(rawValue),
    );
    _lockValues({key});
    state = state.copyWith(pendingKey: key, clearError: true);
    final writeRequestId = _nextRequestId('set-${key.name}');
    try {
      await _set(requestId: writeRequestId, deviceId: deviceId, value: value);
      _unlockValues();
    } catch (error) {
      if (!ref.mounted) {
        return false;
      }
      _unlockValues();
      state = state.copyWith(
        errorMessage: appErrorMessage(error, ''),
        clearPendingKey: true,
      );
      return false;
    }
    if (!ref.mounted) {
      return false;
    }

    final readRequestId = _nextRequestId('refresh');
    try {
      final reportedValues = await _query(
        requestId: readRequestId,
        deviceId: deviceId,
      );
      if (!ref.mounted) {
        return false;
      }
      _applyValues(reportedValues);
      state = state.copyWith(clearPendingKey: true);
      return true;
    } catch (error) {
      if (!ref.mounted) {
        return false;
      }
      _unlockValues();
      state = state.copyWith(
        errorMessage: appErrorMessage(error, ''),
        clearPendingKey: true,
      );
      return false;
    }
  }

  Future<AutoCloseConfigurationResult> setAutoCloseConfiguration({
    required AutoClosePosition position,
    required int time,
    required Iterable<int> allowedTimeValues,
  }) async {
    return _setAutoCloseValue(
      position: position,
      time: time,
      allowedTimeValues: allowedTimeValues,
    );
  }

  Future<AutoCloseConfigurationResult> setAutoCloseEnabled({
    required bool enabled,
    required int? enabledValue,
    required Iterable<int> allowedValues,
  }) {
    if (enabled && (enabledValue == null || enabledValue == 0)) {
      return Future<AutoCloseConfigurationResult>.value(
        const AutoCloseConfigurationResult(
          status: AutoCloseSaveStatus.invalid,
          positionChanged: false,
          timeChanged: false,
        ),
      );
    }
    return _setAutoCloseValue(
      position: _currentAutoClosePosition(),
      time: enabled ? enabledValue! : 0,
      allowedTimeValues: allowedValues,
    );
  }

  Future<bool> setEnabled(
    DeviceSettingKey key, {
    required bool enabled,
    int? enabledValue,
    Iterable<int>? allowedValues,
  }) {
    if (!key.supportsEnabledToggle) {
      return Future<bool>.value(false);
    }
    if (key == DeviceSettingKey.autoCloseTime) {
      if (enabled && (enabledValue == null || enabledValue == 0)) {
        return Future<bool>.value(false);
      }
      return setAutoCloseEnabled(
        enabled: enabled,
        enabledValue: enabledValue,
        allowedValues: allowedValues ?? const <int>[],
      ).then((result) => result.saved);
    }
    final currentValue = state.values[key]?.rawValue;
    final rawValue = enabled
        ? currentValue != null && currentValue != 0
              ? currentValue
              : key.defaultEnabledValue
        : 0;
    return setRawValue(key, rawValue);
  }

  void _applyValues(Map<DeviceSettingKey, DeviceSettingValue> values) {
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(
      values: _protectValues(values),
      loading: false,
      clearError: true,
    );
  }

  Future<AutoCloseConfigurationResult> _setAutoCloseValue({
    required AutoClosePosition position,
    required int time,
    required Iterable<int> allowedTimeValues,
  }) async {
    final allowedValues = allowedTimeValues.toSet();
    final currentPosition = _currentAutoClosePosition();
    final currentTimeSetting = state.values[DeviceSettingKey.autoCloseTime];
    final currentTime =
        matchingDeviceSettingCandidate(currentTimeSetting, allowedValues) ??
        currentTimeSetting?.rawValue;
    final positionChanged = currentPosition != position;
    final timeChanged = currentTime != time;

    AutoCloseConfigurationResult result(AutoCloseSaveStatus status) {
      return AutoCloseConfigurationResult(
        status: status,
        positionChanged: positionChanged,
        timeChanged: timeChanged,
      );
    }

    if (deviceId.trim().isEmpty || state.pendingKey != null) {
      return result(AutoCloseSaveStatus.busy);
    }
    if (allowedValues.isEmpty || (time != 0 && !allowedValues.contains(time))) {
      return result(AutoCloseSaveStatus.invalid);
    }
    if (!positionChanged && !timeChanged) {
      return result(AutoCloseSaveStatus.unchanged);
    }

    final wireValue = encodeAutoCloseProtocolValue(
      position: position,
      level: time,
    );
    final requestId = _nextRequestId('set-auto-close');
    final value = DeviceSettingValue(
      key: DeviceSettingKey.autoCloseTime,
      rawValue: time,
      sourceAttributeId: DeviceSettingKey.autoCloseTime.attributeId,
      wireValue: wireValue,
    );
    _lockValues({
      DeviceSettingKey.autoCloseTime,
      DeviceSettingKey.autoCloseCondition,
    });
    state = state.copyWith(
      pendingKey: DeviceSettingKey.autoCloseTime,
      clearError: true,
    );

    try {
      await _set(requestId: requestId, deviceId: deviceId, value: value);
      _unlockValues();
    } catch (error, stackTrace) {
      _logger.error(
        'auto_close_write_failed',
        tag: AppLogTag.ble,
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'deviceId': deviceId, 'requestedWireValue': wireValue},
      );
      if (ref.mounted) {
        _unlockValues();
        state = state.copyWith(clearPendingKey: true, clearError: true);
      }
      return result(AutoCloseSaveStatus.writeFailed);
    }
    _logger.info(
      'auto_close_write_acknowledged',
      tag: AppLogTag.ble,
      requestId: requestId,
      context: {
        'deviceId': deviceId,
        'requestedWireValue': wireValue,
        'positionChanged': positionChanged,
        'timeChanged': timeChanged,
      },
    );
    if (ref.mounted) {
      state = state.copyWith(clearPendingKey: true, clearError: true);
    }
    return result(AutoCloseSaveStatus.confirmed);
  }

  void _lockValues(Set<DeviceSettingKey> keys) {
    _deferredValues.clear();
    for (final key in keys) {
      _lockedValues[key] = state.values[key];
    }
  }

  Map<DeviceSettingKey, DeviceSettingValue> _protectValues(
    Map<DeviceSettingKey, DeviceSettingValue> values,
  ) {
    final visible = {...values};
    for (final entry in _lockedValues.entries) {
      _deferredValues[entry.key] = values[entry.key];
      final frozen = entry.value;
      if (frozen == null) {
        visible.remove(entry.key);
      } else {
        visible[entry.key] = frozen;
      }
    }
    return Map.unmodifiable(visible);
  }

  void _unlockValues() {
    if (!ref.mounted) {
      return;
    }
    final values = {...state.values};
    for (final entry in _deferredValues.entries) {
      final reported = entry.value;
      if (reported == null) {
        values.remove(entry.key);
      } else {
        values[entry.key] = reported;
      }
    }
    _lockedValues.clear();
    _deferredValues.clear();
    state = state.copyWith(values: Map.unmodifiable(values));
  }

  void _applySnapshot(DeviceSettingsSnapshot snapshot) {
    if (!ref.mounted) {
      return;
    }
    final values = snapshot.origin == DeviceSettingsSnapshotOrigin.activeReport
        ? <DeviceSettingKey, DeviceSettingValue>{
            for (final entry in state.values.entries)
              if (!_deferredValues.containsKey(entry.key))
                entry.key: entry.value,
            for (final entry in _deferredValues.entries)
              if (entry.value != null) entry.key: entry.value!,
            ...snapshot.values,
          }
        : snapshot.values;
    state = state.copyWith(
      values: _protectValues(values),
      loading: false,
      clearError: true,
    );
  }

  void _applyStreamError(Object error, StackTrace stackTrace) {
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(
      loading: false,
      errorMessage: appErrorMessage(error, ''),
    );
  }

  String _nextRequestId(String operation) {
    _requestCounter++;
    return 'device-settings-$operation-${DateTime.now().microsecondsSinceEpoch}-$_requestCounter';
  }

  AutoClosePosition _currentAutoClosePosition() {
    return AutoClosePosition.fromProtocolValue(
          state.values[DeviceSettingKey.autoCloseCondition]?.rawValue,
        ) ??
        AutoClosePosition.upLimit;
  }
}
