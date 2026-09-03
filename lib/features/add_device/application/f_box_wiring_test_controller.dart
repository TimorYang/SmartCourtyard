import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/logging/providers.dart';
import '../../../platform_bridge/hardware_models.dart';
import '../../device_control/application/device_command_controller.dart';
import '../../device_control/domain/entities/f_box_control_mode.dart';
import '../../device_control/domain/use_cases/update_door_control_mode_use_case.dart';
import '../presentation/navigation/f_box_wiring_test_route.dart';
import 'providers.dart';

final fBoxWiringTestControllerProvider =
    NotifierProvider.autoDispose<FBoxWiringTestController, FBoxWiringTestState>(
      FBoxWiringTestController.new,
    );

enum FBoxWiringTestAction {
  pb(DeviceCommandAction.pb),
  close(DeviceCommandAction.closeDoor),
  stop(DeviceCommandAction.stopDoor),
  open(DeviceCommandAction.openDoor);

  const FBoxWiringTestAction(this.deviceCommandAction);

  final DeviceCommandAction deviceCommandAction;

  DoorCommand get doorCommand => deviceCommandAction.doorCommand;
}

enum FBoxWiringTestStatus {
  idle,
  sending,
  reportingControlMode,
  succeeded,
  rejected,
  failed,
}

enum FBoxWiringTestError {
  noConnectedDevice,
  commandRejected,
  commandFailed,
  controlModeReportFailed,
}

class FBoxWiringTestState {
  const FBoxWiringTestState({
    this.status = FBoxWiringTestStatus.idle,
    this.lastAction,
    this.hasTested = false,
    this.error,
    this.errorMessage,
  });

  final FBoxWiringTestStatus status;
  final FBoxWiringTestAction? lastAction;
  final bool hasTested;
  final FBoxWiringTestError? error;
  final String? errorMessage;

  bool get isSending => status == FBoxWiringTestStatus.sending;
  bool get isReportingControlMode =>
      status == FBoxWiringTestStatus.reportingControlMode;
  bool get isBusy => isSending || isReportingControlMode;

  FBoxWiringTestState copyWith({
    FBoxWiringTestStatus? status,
    FBoxWiringTestAction? lastAction,
    bool? hasTested,
    FBoxWiringTestError? error,
    bool clearError = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return FBoxWiringTestState(
      status: status ?? this.status,
      lastAction: lastAction ?? this.lastAction,
      hasTested: hasTested ?? this.hasTested,
      error: clearError ? null : error ?? this.error,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}

class FBoxWiringTestController extends Notifier<FBoxWiringTestState> {
  late final LocalDoorCommandExecutor _commandExecutor;
  late final UpdateDoorControlModeUseCase _updateDoorControlModeUseCase;
  late final AppLogger _logger;
  int _requestCounter = 0;

  @override
  FBoxWiringTestState build() {
    _commandExecutor = ref.watch(localDoorCommandExecutorProvider);
    _updateDoorControlModeUseCase = ref.watch(
      updateDoorControlModeUseCaseProvider,
    );
    _logger = ref.watch(appLoggerProvider);
    return const FBoxWiringTestState();
  }

  Future<void> send({
    required FBoxWiringTestRouteData routeData,
    required FBoxWiringTestAction action,
  }) async {
    if (state.isBusy) {
      return;
    }

    final target = _resolveTarget(routeData);
    if (target == null) {
      return;
    }

    final requestId = _nextRequestId(routeData, action);
    final flowId = routeData.onboardingFlowId?.trim();
    state = state.copyWith(
      status: FBoxWiringTestStatus.sending,
      lastAction: action,
      clearError: true,
      clearErrorMessage: true,
    );
    _logger.info(
      'fbox_wiring_command_started',
      tag: AppLogTag.ble,
      flowId: flowId?.isEmpty == true ? null : flowId,
      requestId: requestId,
      context: {
        'source': routeData.entryPoint.queryValue,
        'action': action.name,
        'command': action.doorCommand.name,
      },
    );

    try {
      final result = await _commandExecutor.send(
        requestId: requestId,
        deviceId: target.nativeDeviceId,
        command: action.doorCommand,
      );
      if (!ref.mounted) {
        return;
      }
      if (result.accepted) {
        state = state.copyWith(
          status: FBoxWiringTestStatus.succeeded,
          lastAction: action,
          hasTested: true,
          clearError: true,
          clearErrorMessage: true,
        );
        _logger.info(
          'fbox_wiring_command_completed',
          tag: AppLogTag.ble,
          flowId: flowId?.isEmpty == true ? null : flowId,
          requestId: requestId,
          context: {'action': action.name, 'result': 'accepted'},
        );
      } else {
        state = state.copyWith(
          status: FBoxWiringTestStatus.rejected,
          lastAction: action,
          error: FBoxWiringTestError.commandRejected,
          clearErrorMessage: true,
        );
        _logger.warning(
          'fbox_wiring_command_rejected',
          tag: AppLogTag.ble,
          flowId: flowId?.isEmpty == true ? null : flowId,
          requestId: requestId,
          context: {'action': action.name, 'result': 'rejected'},
        );
      }
    } on AppError catch (error, stackTrace) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        status: FBoxWiringTestStatus.failed,
        lastAction: action,
        error: _mapError(error),
        clearErrorMessage: true,
      );
      _logger.error(
        'fbox_wiring_command_failed',
        tag: AppLogTag.ble,
        flowId: flowId?.isEmpty == true ? null : flowId,
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'action': action.name},
      );
    } catch (error, stackTrace) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        status: FBoxWiringTestStatus.failed,
        lastAction: action,
        error: FBoxWiringTestError.commandFailed,
        clearErrorMessage: true,
      );
      _logger.error(
        'fbox_wiring_command_failed',
        tag: AppLogTag.ble,
        flowId: flowId?.isEmpty == true ? null : flowId,
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'action': action.name},
      );
    }
  }

  Future<bool> updateControlMode({
    required FBoxWiringTestRouteData routeData,
    required FBoxControlMode mode,
  }) async {
    if (state.isBusy) {
      return false;
    }

    final requestId = _nextControlModeRequestId(routeData, mode);
    final flowId = routeData.onboardingFlowId?.trim();
    final sn = _resolveControlModeSn(routeData);
    if (sn == null) {
      state = state.copyWith(
        status: FBoxWiringTestStatus.failed,
        error: FBoxWiringTestError.controlModeReportFailed,
        clearErrorMessage: true,
      );
      _logger.warning(
        'fbox_control_mode_update_ignored',
        tag: AppLogTag.general,
        flowId: flowId?.isEmpty == true ? null : flowId,
        requestId: requestId,
        context: {
          'source': routeData.entryPoint.queryValue,
          'controlMode': mode.apiValue,
          'reason': 'missing_serial_number',
        },
      );
      return false;
    }

    state = state.copyWith(
      status: FBoxWiringTestStatus.reportingControlMode,
      clearError: true,
      clearErrorMessage: true,
    );
    _logger.info(
      'fbox_control_mode_update_started',
      tag: AppLogTag.general,
      flowId: flowId?.isEmpty == true ? null : flowId,
      requestId: requestId,
      context: {
        'source': routeData.entryPoint.queryValue,
        'controlMode': mode.apiValue,
      },
    );

    try {
      await _updateDoorControlModeUseCase(
        sn: sn,
        mode: mode,
        requestId: requestId,
      );
      if (!ref.mounted) {
        return false;
      }
      state = state.copyWith(
        status: FBoxWiringTestStatus.succeeded,
        clearError: true,
        clearErrorMessage: true,
      );
      _logger.info(
        'fbox_control_mode_update_completed',
        tag: AppLogTag.general,
        flowId: flowId?.isEmpty == true ? null : flowId,
        requestId: requestId,
        context: {
          'source': routeData.entryPoint.queryValue,
          'controlMode': mode.apiValue,
          'result': 'accepted',
        },
      );
      return true;
    } on AppError catch (error, stackTrace) {
      if (!ref.mounted) {
        return false;
      }
      state = state.copyWith(
        status: FBoxWiringTestStatus.failed,
        error: FBoxWiringTestError.controlModeReportFailed,
        errorMessage: _serverMessage(error),
      );
      _logger.error(
        'fbox_control_mode_update_failed',
        tag: AppLogTag.general,
        flowId: flowId?.isEmpty == true ? null : flowId,
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {
          'source': routeData.entryPoint.queryValue,
          'controlMode': mode.apiValue,
        },
      );
      return false;
    } catch (error, stackTrace) {
      if (!ref.mounted) {
        return false;
      }
      state = state.copyWith(
        status: FBoxWiringTestStatus.failed,
        error: FBoxWiringTestError.controlModeReportFailed,
        clearErrorMessage: true,
      );
      _logger.error(
        'fbox_control_mode_update_failed',
        tag: AppLogTag.general,
        flowId: flowId?.isEmpty == true ? null : flowId,
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {
          'source': routeData.entryPoint.queryValue,
          'controlMode': mode.apiValue,
        },
      );
      return false;
    }
  }

  String? _resolveControlModeSn(FBoxWiringTestRouteData routeData) {
    final sn = routeData.entryPoint == FBoxWiringTestEntryPoint.deviceCommand
        ? _resolveDeviceCommandSn(routeData)
        : _resolveOnboardingSn(routeData);
    final normalized = sn?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  String? _resolveOnboardingSn(FBoxWiringTestRouteData routeData) {
    final addDeviceState = ref.read(addDeviceControllerProvider);
    final routeDeviceId = routeData.deviceId.trim();
    final routeDevice = routeDeviceId.isEmpty
        ? null
        : addDeviceState.devices[routeDeviceId];
    final routeSn = routeDevice?.sn?.trim();
    if (routeSn?.isNotEmpty == true) {
      return routeSn;
    }
    return addDeviceState.selectedDevice?.sn;
  }

  String? _resolveDeviceCommandSn(FBoxWiringTestRouteData routeData) {
    final commandState = ref.read(deviceCommandControllerProvider);
    final routeDeviceId = routeData.deviceId.trim();
    final selectedDeviceId = commandState.selectedDeviceId?.trim() ?? '';
    final targetDeviceId = routeDeviceId.isNotEmpty
        ? routeDeviceId
        : selectedDeviceId;
    if (targetDeviceId.isEmpty) {
      return null;
    }
    return commandState.doorDevices
        .where((device) => device.deviceId == targetDeviceId)
        .firstOrNull
        ?.sn;
  }

  String? _serverMessage(AppError error) {
    final message = error.userMessage?.trim();
    return message == null || message.isEmpty ? null : message;
  }

  _FBoxWiringCommandTarget? _resolveTarget(FBoxWiringTestRouteData routeData) {
    if (routeData.entryPoint == FBoxWiringTestEntryPoint.deviceCommand) {
      final commandState = ref.read(deviceCommandControllerProvider);
      final selectedDeviceId = commandState.selectedDeviceId;
      if (selectedDeviceId == null || selectedDeviceId.trim().isEmpty) {
        state = state.copyWith(
          status: FBoxWiringTestStatus.failed,
          error: FBoxWiringTestError.noConnectedDevice,
        );
        return null;
      }
      if (commandState.bleConnectionStatuses[selectedDeviceId] !=
          DeviceBleConnectionStatus.connected) {
        state = state.copyWith(
          status: FBoxWiringTestStatus.failed,
          error: FBoxWiringTestError.noConnectedDevice,
        );
        return null;
      }
      final nativeDeviceId = commandState.bleDeviceIds[selectedDeviceId];
      if (nativeDeviceId == null || nativeDeviceId.trim().isEmpty) {
        state = state.copyWith(
          status: FBoxWiringTestStatus.failed,
          error: FBoxWiringTestError.noConnectedDevice,
        );
        return null;
      }
      return _FBoxWiringCommandTarget(nativeDeviceId: nativeDeviceId);
    }

    final addDeviceState = ref.read(addDeviceControllerProvider);
    final selectedDevice = addDeviceState.selectedDevice;
    final logicalDeviceId = selectedDevice?.id.trim().isNotEmpty == true
        ? selectedDevice!.id.trim()
        : routeData.deviceId.trim();
    if (logicalDeviceId.isEmpty ||
        addDeviceState.connectionStateFor(logicalDeviceId) !=
            BleConnectionState.connected) {
      state = state.copyWith(
        status: FBoxWiringTestStatus.failed,
        error: FBoxWiringTestError.noConnectedDevice,
      );
      return null;
    }
    return _FBoxWiringCommandTarget(nativeDeviceId: logicalDeviceId);
  }

  FBoxWiringTestError _mapError(AppError error) {
    return switch (error.code) {
      AppErrorCode.bluetoothUnavailable ||
      AppErrorCode.bluetoothDisconnected ||
      AppErrorCode.permissionDenied => FBoxWiringTestError.noConnectedDevice,
      _ => FBoxWiringTestError.commandFailed,
    };
  }

  String _nextRequestId(
    FBoxWiringTestRouteData routeData,
    FBoxWiringTestAction action,
  ) {
    _requestCounter += 1;
    final flowId = routeData.onboardingFlowId?.trim();
    final scope = flowId == null || flowId.isEmpty ? 'fbox-wiring' : flowId;
    return '$scope:${action.name}:${DateTime.now().toUtc().microsecondsSinceEpoch}-$_requestCounter';
  }

  String _nextControlModeRequestId(
    FBoxWiringTestRouteData routeData,
    FBoxControlMode mode,
  ) {
    _requestCounter += 1;
    final flowId = routeData.onboardingFlowId?.trim();
    final scope = flowId == null || flowId.isEmpty ? 'fbox-wiring' : flowId;
    return '$scope:control-mode:${mode.name}:'
        '${DateTime.now().toUtc().microsecondsSinceEpoch}-$_requestCounter';
  }
}

class _FBoxWiringCommandTarget {
  const _FBoxWiringCommandTarget({required this.nativeDeviceId});

  final String nativeDeviceId;
}
