import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../platform_bridge/hardware_gateway.dart';
import '../../../platform_bridge/hardware_models.dart';
import '../../../platform_bridge/providers.dart';

final deviceCommandHardwareGatewayProvider = Provider<HardwareGateway>((ref) {
  return ref.watch(nativeHardwareGatewayProvider);
});

final deviceCommandControllerProvider =
    NotifierProvider<DeviceCommandController, DeviceCommandState>(
      DeviceCommandController.new,
    );

enum DeviceCommandAction {
  queryAttributes('属性查询上报'),
  openDoor('开门'),
  closeDoor('关门'),
  stopDoor('暂停'),
  partialOpenDoor('半开门'),
  turnLightOn('开灯'),
  turnLightOff('关灯'),
  pb('PB'),
  queryCurrent('电流查询');

  const DeviceCommandAction(this.label);

  final String label;

  DoorCommand? get doorCommand {
    return switch (this) {
      DeviceCommandAction.openDoor => DoorCommand.open,
      DeviceCommandAction.closeDoor => DoorCommand.close,
      DeviceCommandAction.stopDoor => DoorCommand.stop,
      DeviceCommandAction.partialOpenDoor => DoorCommand.partialOpen,
      DeviceCommandAction.turnLightOn => DoorCommand.lightOn,
      DeviceCommandAction.turnLightOff => DoorCommand.lightOff,
      DeviceCommandAction.pb => DoorCommand.pb,
      _ => null,
    };
  }
}

class DeviceCommandState {
  const DeviceCommandState({
    this.pendingAction,
    this.infoMessage,
    this.errorMessage,
  });

  final DeviceCommandAction? pendingAction;
  final String? infoMessage;
  final String? errorMessage;

  DeviceCommandState copyWith({
    DeviceCommandAction? pendingAction,
    bool clearPendingAction = false,
    String? infoMessage,
    bool clearInfoMessage = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return DeviceCommandState(
      pendingAction: clearPendingAction
          ? null
          : pendingAction ?? this.pendingAction,
      infoMessage: clearInfoMessage
          ? null
          : infoMessage ?? this.infoMessage,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}

class DeviceCommandController extends Notifier<DeviceCommandState> {
  late final HardwareGateway _gateway;
  int _requestCounter = 0;

  @override
  DeviceCommandState build() {
    _gateway = ref.watch(deviceCommandHardwareGatewayProvider);
    return const DeviceCommandState();
  }

  Future<void> runAction({
    required String deviceId,
    required DeviceCommandAction action,
  }) async {
    if (deviceId.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: '未找到当前设备，请返回重新连接设备。',
        clearInfoMessage: true,
      );
      return;
    }

    final doorCommand = action.doorCommand;
    if (doorCommand == null) {
      state = state.copyWith(
        infoMessage: '${action.label} 的硬件指令尚未接入。',
        clearErrorMessage: true,
      );
      return;
    }

    state = state.copyWith(
      pendingAction: action,
      infoMessage: '正在发送${action.label}指令...',
      clearErrorMessage: true,
    );

    try {
      final result = await _gateway.sendDoorCommand(
        requestId: _nextRequestId(action),
        deviceId: deviceId,
        command: doorCommand,
      );
      state = state.copyWith(
        clearPendingAction: true,
        infoMessage: result.accepted
            ? '${action.label}指令已接收。'
            : '${action.label}指令未被接收。',
        errorMessage: result.accepted ? null : 'device_command_rejected',
        clearErrorMessage: result.accepted,
      );
    } catch (error) {
      state = state.copyWith(
        clearPendingAction: true,
        errorMessage: error.toString(),
        clearInfoMessage: true,
      );
    }
  }

  String _nextRequestId(DeviceCommandAction action) {
    _requestCounter += 1;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'device-command-${action.name}-$timestamp-$_requestCounter';
  }
}
