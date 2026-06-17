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
  openDoor('开门', 0x1001, DoorCommand.open),
  closeDoor('关门', 0x1002, DoorCommand.close),
  stopDoor('暂停', 0x1003, DoorCommand.stop),
  partialOpenDoor('半开门', 0x1004, DoorCommand.partialOpen),
  turnLightOn('开灯', 0x1005, DoorCommand.lightOn),
  turnLightOff('关灯', 0x1006, DoorCommand.lightOff),
  pb('PB', 0x1007, DoorCommand.pb);

  const DeviceCommandAction(this.label, this.controlCode, this.doorCommand);

  final String label;
  final int controlCode;
  final DoorCommand doorCommand;

  String get controlCodeLabel =>
      '0x${controlCode.toRadixString(16).padLeft(4, '0').toUpperCase()}';
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
      infoMessage: clearInfoMessage ? null : infoMessage ?? this.infoMessage,
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

    state = state.copyWith(
      pendingAction: action,
      infoMessage: '正在发送${action.label}指令（${action.controlCodeLabel}）...',
      clearErrorMessage: true,
    );

    try {
      final result = await _gateway.sendDoorCommand(
        requestId: _nextRequestId(action),
        deviceId: deviceId,
        command: action.doorCommand,
      );
      state = state.copyWith(
        clearPendingAction: true,
        infoMessage: result.accepted
            ? '${action.label}指令已发送（${action.controlCodeLabel}）。'
            : '${action.label}指令未被接收（${action.controlCodeLabel}）。',
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
