import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error_message.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/logging/providers.dart';

import '../domain/entities/device_capability.dart';
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

class AutoCloseConfigurationResult {
  const AutoCloseConfigurationResult({
    required this.saved,
    required this.positionChanged,
    required this.timeChanged,
  });

  final bool saved;
  final bool positionChanged;
  final bool timeChanged;
}

class DeviceSettingsController extends Notifier<DeviceSettingsState> {
  DeviceSettingsController(this.deviceId);

  final String deviceId;
  late final QueryDeviceSettingsUseCase _query;
  late final SetDeviceSettingUseCase _set;
  late final DeviceSettingsRepository _repository;
  late final AppLogger _logger;
  StreamSubscription<Map<DeviceSettingKey, DeviceSettingValue>>? _subscription;
  int _requestCounter = 0;

  @override
  DeviceSettingsState build() {
    _query = ref.watch(queryDeviceSettingsUseCaseProvider);
    _set = ref.watch(setDeviceSettingUseCaseProvider);
    _repository = ref.watch(deviceSettingsRepositoryProvider);
    _logger = ref.watch(appLoggerProvider);
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
    Set<int>? autoCloseAllowedValues;
    if (key == DeviceSettingKey.autoCloseTime) {
      final capabilityValues = allowedValues?.toSet() ?? const <int>{};
      if (rawValue < 0 ||
          rawValue > 9 ||
          capabilityValues.isEmpty ||
          (rawValue != 0 && !capabilityValues.contains(rawValue))) {
        return false;
      }
      autoCloseAllowedValues = <int>{0, ...capabilityValues};
    }
    final value = key == DeviceSettingKey.autoCloseTime
        ? DeviceSettingValue(
            key: key,
            rawValue: rawValue,
            wireValue: encodeAutoCloseProtocolValue(
              position: _currentAutoClosePosition(),
              level: rawValue,
            ),
          )
        : DeviceSettingValue(key: key, rawValue: key.toProtocolValue(rawValue));
    state = state.copyWith(pendingKey: key, clearError: true);
    final writeRequestId = _nextRequestId('set-${key.name}');
    try {
      await _set(requestId: writeRequestId, deviceId: deviceId, value: value);
    } catch (error) {
      if (!ref.mounted) {
        return false;
      }
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
      final values = key == DeviceSettingKey.autoCloseTime
          ? _resolveAutoCloseValues(
              reportedValues,
              allowedValues: autoCloseAllowedValues!,
              fallbackValue: value,
              requestId: readRequestId,
              logMismatch: true,
            )
          : reportedValues;
      _applyValues(values);
      return true;
    } catch (error) {
      if (!ref.mounted) {
        return false;
      }
      if (key == DeviceSettingKey.autoCloseTime) {
        _logger.warning(
          'auto_close_attribute_readback_failed',
          tag: AppLogTag.ble,
          requestId: readRequestId,
          context: {'deviceId': deviceId, 'errorType': error.runtimeType},
        );
        state = state.copyWith(
          values: Map<DeviceSettingKey, DeviceSettingValue>.unmodifiable({
            ...state.values,
            key: value,
          }),
          clearPendingKey: true,
          clearError: true,
        );
        return true;
      }
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
    const failed = AutoCloseConfigurationResult(
      saved: false,
      positionChanged: false,
      timeChanged: false,
    );
    if (deviceId.trim().isEmpty || state.pendingKey != null) {
      return failed;
    }

    final allowedValues = allowedTimeValues.toSet();
    if (allowedValues.isEmpty || (time != 0 && !allowedValues.contains(time))) {
      return failed;
    }

    final currentPosition = _currentAutoClosePosition();
    final currentTimeSetting = state.values[DeviceSettingKey.autoCloseTime];
    final currentTime =
        matchingDeviceSettingCandidate(currentTimeSetting, allowedValues) ??
        currentTimeSetting?.rawValue;
    final positionChanged = currentPosition != position;
    final timeChanged = currentTime != time;
    if (!positionChanged && !timeChanged) {
      return const AutoCloseConfigurationResult(
        saved: true,
        positionChanged: false,
        timeChanged: false,
      );
    }

    final timeValue = DeviceSettingValue(
      key: DeviceSettingKey.autoCloseTime,
      rawValue: time,
      sourceAttributeId: DeviceSettingKey.autoCloseTime.attributeId,
      wireValue: encodeAutoCloseProtocolValue(position: position, level: time),
    );
    final operationRequestId = _nextRequestId('set-auto-close');

    state = state.copyWith(
      pendingKey: DeviceSettingKey.autoCloseTime,
      clearError: true,
    );
    try {
      await _set(
        requestId: operationRequestId,
        deviceId: deviceId,
        value: timeValue,
      );

      if (!ref.mounted) {
        return failed;
      }

      final readRequestId = '$operationRequestId-refresh';
      try {
        final reportedValues = await _query(
          requestId: readRequestId,
          deviceId: deviceId,
        );
        if (!ref.mounted) {
          return failed;
        }
        final values = _resolveAutoCloseValues(
          reportedValues,
          allowedValues: <int>{0, ...allowedValues},
          fallbackValue: timeValue,
          requestId: readRequestId,
          logMismatch: true,
        );
        final valuesWithCondition =
            values.containsKey(DeviceSettingKey.autoCloseCondition)
            ? values
            : <DeviceSettingKey, DeviceSettingValue>{
                ...values,
                DeviceSettingKey.autoCloseCondition: DeviceSettingValue(
                  key: DeviceSettingKey.autoCloseCondition,
                  rawValue: position.protocolValue,
                  sourceAttributeId: DeviceSettingKey.autoCloseTime.attributeId,
                ),
              };
        _applyValues(valuesWithCondition);
        return AutoCloseConfigurationResult(
          saved: true,
          positionChanged: positionChanged,
          timeChanged: timeChanged,
        );
      } catch (error) {
        if (!ref.mounted) {
          return failed;
        }
        _logger.warning(
          'auto_close_configuration_readback_failed',
          tag: AppLogTag.ble,
          requestId: readRequestId,
          context: {'deviceId': deviceId, 'errorType': error.runtimeType},
        );
        state = state.copyWith(
          values: Map<DeviceSettingKey, DeviceSettingValue>.unmodifiable({
            ...state.values,
            DeviceSettingKey.autoCloseTime: timeValue,
            DeviceSettingKey.autoCloseCondition: DeviceSettingValue(
              key: DeviceSettingKey.autoCloseCondition,
              rawValue: position.protocolValue,
              sourceAttributeId: DeviceSettingKey.autoCloseTime.attributeId,
            ),
          }),
          clearPendingKey: true,
          clearError: true,
        );
        return AutoCloseConfigurationResult(
          saved: true,
          positionChanged: positionChanged,
          timeChanged: timeChanged,
        );
      }
    } catch (error) {
      if (!ref.mounted) {
        return failed;
      }
      state = state.copyWith(
        errorMessage: appErrorMessage(error, ''),
        clearPendingKey: true,
      );
      return AutoCloseConfigurationResult(
        saved: false,
        positionChanged: positionChanged,
        timeChanged: timeChanged,
      );
    }
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
      return setRawValue(
        key,
        enabled ? enabledValue! : 0,
        allowedValues: allowedValues,
      );
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
      values: Map<DeviceSettingKey, DeviceSettingValue>.unmodifiable(values),
      loading: false,
      clearPendingKey: true,
      clearError: true,
    );
  }

  Map<DeviceSettingKey, DeviceSettingValue> _resolveAutoCloseValues(
    Map<DeviceSettingKey, DeviceSettingValue> values, {
    required Set<int> allowedValues,
    DeviceSettingValue? fallbackValue,
    String? requestId,
    bool logMismatch = false,
  }) {
    if (allowedValues.isEmpty) {
      return values;
    }
    final reportedValue = values[DeviceSettingKey.autoCloseTime];
    if (reportedValue?.sourceAttributeId ==
        DeviceSettingKey.autoCloseTime.legacyAttributeId) {
      return values;
    }
    final resolvedRawValue = matchingDeviceSettingCandidate(
      reportedValue,
      allowedValues,
    );
    if (reportedValue != null && resolvedRawValue != null) {
      return <DeviceSettingKey, DeviceSettingValue>{
        ...values,
        DeviceSettingKey.autoCloseTime: DeviceSettingValue(
          key: reportedValue.key,
          rawValue: resolvedRawValue,
          candidateValues: reportedValue.candidateValues,
          sourceAttributeId: reportedValue.sourceAttributeId,
          wireValue: reportedValue.wireValue,
        ),
      };
    }
    if (logMismatch) {
      _logger.warning(
        'auto_close_attribute_value_unmatched',
        tag: AppLogTag.ble,
        requestId: requestId,
        context: {
          'deviceId': deviceId,
          'reportedValues': reportedValue?.candidateValues,
          'allowedValues': allowedValues.toList(growable: false),
        },
      );
    }
    if (fallbackValue == null) {
      return values;
    }
    return <DeviceSettingKey, DeviceSettingValue>{
      ...values,
      DeviceSettingKey.autoCloseTime: fallbackValue,
    };
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
