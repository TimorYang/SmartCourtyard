import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/logging/providers.dart';
import '../../device_control/application/device_command_controller.dart';
import '../../../platform_bridge/hardware_models.dart';
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

enum FBoxWiringTestStatus { idle, sending, succeeded, rejected, failed }

enum FBoxWiringTestError { noConnectedDevice, commandRejected, commandFailed }

class FBoxWiringTestState {
  const FBoxWiringTestState({
    this.status = FBoxWiringTestStatus.idle,
    this.lastAction,
    this.hasTested = false,
    this.error,
  });

  final FBoxWiringTestStatus status;
  final FBoxWiringTestAction? lastAction;
  final bool hasTested;
  final FBoxWiringTestError? error;

  bool get isSending => status == FBoxWiringTestStatus.sending;

  FBoxWiringTestState copyWith({
    FBoxWiringTestStatus? status,
    FBoxWiringTestAction? lastAction,
    bool? hasTested,
    FBoxWiringTestError? error,
    bool clearError = false,
  }) {
    return FBoxWiringTestState(
      status: status ?? this.status,
      lastAction: lastAction ?? this.lastAction,
      hasTested: hasTested ?? this.hasTested,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class FBoxWiringTestController extends Notifier<FBoxWiringTestState> {
  late final LocalDoorCommandExecutor _commandExecutor;
  late final AppLogger _logger;
  int _requestCounter = 0;

  @override
  FBoxWiringTestState build() {
    _commandExecutor = ref.watch(localDoorCommandExecutorProvider);
    _logger = ref.watch(appLoggerProvider);
    return const FBoxWiringTestState();
  }

  Future<void> send({
    required FBoxWiringTestRouteData routeData,
    required FBoxWiringTestAction action,
  }) async {
    if (state.isSending) {
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
}

class _FBoxWiringCommandTarget {
  const _FBoxWiringCommandTarget({required this.nativeDeviceId});

  final String nativeDeviceId;
}
