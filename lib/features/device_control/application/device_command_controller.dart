import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/logging/providers.dart';
import '../../../core/network/providers.dart';
import '../../../platform_bridge/hardware_gateway.dart';
import '../../../platform_bridge/hardware_models.dart';
import '../../../platform_bridge/providers.dart';
import '../data/data_sources/door_detail_api.dart';
import '../data/data_sources/door_detail_remote_data_source.dart';
import '../data/repositories/door_detail_repository_impl.dart';
import '../domain/entities/door_detail.dart';
import '../domain/repositories/door_detail_repository.dart';
import '../domain/use_cases/fetch_door_detail_use_case.dart';

final deviceCommandHardwareGatewayProvider = Provider<HardwareGateway>((ref) {
  return ref.watch(nativeHardwareGatewayProvider);
});

final doorDetailApiProvider = Provider<DoorDetailApi>((ref) {
  return DoorDetailApi(ref.watch(dioProvider));
});

final doorDetailRemoteDataSourceProvider = Provider<DoorDetailRemoteDataSource>(
  (ref) =>
      DoorDetailRemoteDataSourceImpl(api: ref.watch(doorDetailApiProvider)),
);

final doorDetailRepositoryProvider = Provider<DoorDetailRepository>((ref) {
  return DoorDetailRepositoryImpl(
    remoteDataSource: ref.watch(doorDetailRemoteDataSourceProvider),
    logger: ref.watch(appLoggerProvider),
  );
});

final fetchDoorDetailUseCaseProvider = Provider<FetchDoorDetailUseCase>((ref) {
  return FetchDoorDetailUseCase(
    repository: ref.watch(doorDetailRepositoryProvider),
  );
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
    this.doorDetail,
    this.isLoadingDoorDetail = false,
    this.doorDetailErrorMessage,
    this.pendingAction,
    this.pendingRemotePairingAction,
    this.pendingRemoteManagementAction,
    this.remotes = const <RemoteControl>[],
    this.remoteTotalCount = 0,
    this.remoteTotalPages = 0,
    this.remoteCurrentPage = 0,
    this.remoteHasMore = false,
    this.infoMessage,
    this.errorMessage,
  });

  final DoorDetail? doorDetail;
  final bool isLoadingDoorDetail;
  final String? doorDetailErrorMessage;
  final DeviceCommandAction? pendingAction;
  final RemotePairingAction? pendingRemotePairingAction;
  final String? pendingRemoteManagementAction;
  final List<RemoteControl> remotes;
  final int remoteTotalCount;
  final int remoteTotalPages;
  final int remoteCurrentPage;
  final bool remoteHasMore;
  final String? infoMessage;
  final String? errorMessage;

  DeviceCommandState copyWith({
    DoorDetail? doorDetail,
    bool clearDoorDetail = false,
    bool? isLoadingDoorDetail,
    String? doorDetailErrorMessage,
    bool clearDoorDetailErrorMessage = false,
    DeviceCommandAction? pendingAction,
    bool clearPendingAction = false,
    RemotePairingAction? pendingRemotePairingAction,
    bool clearPendingRemotePairingAction = false,
    String? pendingRemoteManagementAction,
    bool clearPendingRemoteManagementAction = false,
    List<RemoteControl>? remotes,
    int? remoteTotalCount,
    int? remoteTotalPages,
    int? remoteCurrentPage,
    bool? remoteHasMore,
    String? infoMessage,
    bool clearInfoMessage = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return DeviceCommandState(
      doorDetail: clearDoorDetail ? null : doorDetail ?? this.doorDetail,
      isLoadingDoorDetail: isLoadingDoorDetail ?? this.isLoadingDoorDetail,
      doorDetailErrorMessage: clearDoorDetailErrorMessage
          ? null
          : doorDetailErrorMessage ?? this.doorDetailErrorMessage,
      pendingAction: clearPendingAction
          ? null
          : pendingAction ?? this.pendingAction,
      pendingRemotePairingAction: clearPendingRemotePairingAction
          ? null
          : pendingRemotePairingAction ?? this.pendingRemotePairingAction,
      pendingRemoteManagementAction: clearPendingRemoteManagementAction
          ? null
          : pendingRemoteManagementAction ?? this.pendingRemoteManagementAction,
      remotes: remotes ?? this.remotes,
      remoteTotalCount: remoteTotalCount ?? this.remoteTotalCount,
      remoteTotalPages: remoteTotalPages ?? this.remoteTotalPages,
      remoteCurrentPage: remoteCurrentPage ?? this.remoteCurrentPage,
      remoteHasMore: remoteHasMore ?? this.remoteHasMore,
      infoMessage: clearInfoMessage ? null : infoMessage ?? this.infoMessage,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}

class DeviceCommandController extends Notifier<DeviceCommandState> {
  late final HardwareGateway _gateway;
  late final FetchDoorDetailUseCase _fetchDoorDetailUseCase;
  int _requestCounter = 0;

  @override
  DeviceCommandState build() {
    _gateway = ref.watch(deviceCommandHardwareGatewayProvider);
    _fetchDoorDetailUseCase = ref.watch(fetchDoorDetailUseCaseProvider);
    return const DeviceCommandState();
  }

  Future<void> loadDoorDetail({required String doorId}) async {
    final trimmedDoorId = doorId.trim();
    if (trimmedDoorId.isEmpty) {
      state = state.copyWith(
        isLoadingDoorDetail: false,
        doorDetailErrorMessage: '未找到当前门，请返回重新进入。',
      );
      return;
    }

    state = state.copyWith(
      isLoadingDoorDetail: true,
      clearDoorDetailErrorMessage: true,
    );

    try {
      final detail = await _fetchDoorDetailUseCase(
        doorId: trimmedDoorId,
        requestId: _nextDoorDetailRequestId(trimmedDoorId),
      );
      state = state.copyWith(
        doorDetail: detail,
        isLoadingDoorDetail: false,
        clearDoorDetailErrorMessage: true,
      );
    } on AppError catch (error) {
      state = state.copyWith(
        isLoadingDoorDetail: false,
        doorDetailErrorMessage: _doorDetailErrorMessage(error),
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingDoorDetail: false,
        doorDetailErrorMessage: error.toString(),
      );
    }
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

  Future<void> runRemotePairingAction({
    required String deviceId,
    required RemotePairingAction action,
  }) async {
    if (deviceId.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: '未找到当前设备，请返回重新连接设备。',
        clearInfoMessage: true,
      );
      return;
    }

    state = state.copyWith(
      pendingRemotePairingAction: action,
      infoMessage: action == RemotePairingAction.start
          ? '正在启动遥控器对码（0x1008）...'
          : '正在取消遥控器对码（0x1009）...',
      clearErrorMessage: true,
    );

    try {
      final result = await _gateway.pairRemote(
        requestId: _nextRemotePairingRequestId(action),
        deviceId: deviceId,
        action: action,
      );
      state = state.copyWith(
        clearPendingRemotePairingAction: true,
        infoMessage: _remotePairingInfoMessage(action, result),
        errorMessage: result.successful
            ? null
            : _remotePairingErrorMessage(result),
        clearErrorMessage: result.successful,
      );
    } catch (error) {
      state = state.copyWith(
        clearPendingRemotePairingAction: true,
        errorMessage: error.toString(),
        clearInfoMessage: true,
      );
    }
  }

  Future<void> queryRemotes({required String deviceId}) async {
    if (_deviceIdMissing(deviceId)) {
      return;
    }

    state = state.copyWith(
      pendingRemoteManagementAction: 'query',
      infoMessage: '正在查询遥控器列表（0x0008）...',
      clearErrorMessage: true,
    );

    try {
      final result = await _gateway.queryRemotes(
        requestId: _nextRemoteManagementRequestId('query'),
        deviceId: deviceId,
      );
      state = state.copyWith(
        clearPendingRemoteManagementAction: true,
        remotes: result.remotes,
        remoteTotalCount: result.totalCount,
        remoteTotalPages: result.totalPages,
        remoteCurrentPage: result.currentPage,
        remoteHasMore: result.hasMore,
        infoMessage: result.remotes.isEmpty
            ? '未查询到已配对的遥控器。'
            : '已查询到 ${result.remotes.length}/${result.totalCount} 个遥控器。',
        clearErrorMessage: true,
      );
    } catch (error) {
      state = state.copyWith(
        clearPendingRemoteManagementAction: true,
        errorMessage: error.toString(),
        clearInfoMessage: true,
      );
    }
  }

  Future<void> deleteRemote({
    required String deviceId,
    int? serialNumber,
  }) async {
    if (_deviceIdMissing(deviceId)) {
      return;
    }

    final isDeleteAll = serialNumber == null;
    state = state.copyWith(
      pendingRemoteManagementAction: isDeleteAll
          ? 'delete-all'
          : 'delete-${serialNumber.toRadixString(16)}',
      infoMessage: isDeleteAll
          ? '正在删除全部遥控器（0x0009）...'
          : '正在删除遥控器 ${_serialNumberLabel(serialNumber)}（0x0009）...',
      clearErrorMessage: true,
    );

    try {
      final result = await _gateway.deleteRemote(
        requestId: _nextRemoteManagementRequestId('delete'),
        deviceId: deviceId,
        serialNumber: serialNumber,
      );
      final nextRemotes = result.successful
          ? isDeleteAll
                ? <RemoteControl>[]
                : state.remotes
                      .where((remote) => remote.serialNumber != serialNumber)
                      .toList()
          : state.remotes;
      state = state.copyWith(
        clearPendingRemoteManagementAction: true,
        remotes: nextRemotes,
        remoteTotalCount: result.successful
            ? nextRemotes.length
            : state.remoteTotalCount,
        infoMessage: _remoteOperationInfoMessage(
          isDeleteAll ? '全部删除' : '删除遥控器',
          result,
        ),
        errorMessage: result.successful
            ? null
            : _remoteOperationErrorMessage('delete', result),
        clearErrorMessage: result.successful,
      );
    } catch (error) {
      state = state.copyWith(
        clearPendingRemoteManagementAction: true,
        errorMessage: error.toString(),
        clearInfoMessage: true,
      );
    }
  }

  Future<void> renameRemote({
    required String deviceId,
    required int serialNumber,
    required String name,
  }) async {
    if (_deviceIdMissing(deviceId)) {
      return;
    }

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      state = state.copyWith(
        errorMessage: '遥控器名称不能为空。',
        clearInfoMessage: true,
      );
      return;
    }

    state = state.copyWith(
      pendingRemoteManagementAction: 'rename-${serialNumber.toRadixString(16)}',
      infoMessage: '正在改名遥控器 ${_serialNumberLabel(serialNumber)}（0x000A）...',
      clearErrorMessage: true,
    );

    try {
      final result = await _gateway.renameRemote(
        requestId: _nextRemoteManagementRequestId('rename'),
        deviceId: deviceId,
        serialNumber: serialNumber,
        name: trimmedName,
      );
      final nextRemotes = result.successful
          ? state.remotes
                .map(
                  (remote) => remote.serialNumber == serialNumber
                      ? RemoteControl(
                          name: trimmedName,
                          serialNumber: remote.serialNumber,
                        )
                      : remote,
                )
                .toList()
          : state.remotes;
      state = state.copyWith(
        clearPendingRemoteManagementAction: true,
        remotes: nextRemotes,
        infoMessage: _remoteOperationInfoMessage('改名遥控器', result),
        errorMessage: result.successful
            ? null
            : _remoteOperationErrorMessage('rename', result),
        clearErrorMessage: result.successful,
      );
    } catch (error) {
      state = state.copyWith(
        clearPendingRemoteManagementAction: true,
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

  String _nextDoorDetailRequestId(String doorId) {
    _requestCounter += 1;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'door-detail-$doorId-$timestamp-$_requestCounter';
  }

  String _nextRemotePairingRequestId(RemotePairingAction action) {
    _requestCounter += 1;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'remote-pairing-${action.name}-$timestamp-$_requestCounter';
  }

  String _nextRemoteManagementRequestId(String operation) {
    _requestCounter += 1;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'remote-$operation-$timestamp-$_requestCounter';
  }

  String _remotePairingInfoMessage(
    RemotePairingAction action,
    RemotePairingResult result,
  ) {
    final actionLabel = action == RemotePairingAction.start ? '开始对码' : '取消对码';
    final reason = result.reasonCode
        .toRadixString(16)
        .padLeft(8, '0')
        .toUpperCase();
    return switch (result.status) {
      RemotePairingStatus.success => '$actionLabel成功，故障码 0x$reason。',
      RemotePairingStatus.failure => '$actionLabel失败，故障码 0x$reason。',
      RemotePairingStatus.timeout => '$actionLabel超时，故障码 0x$reason。',
      RemotePairingStatus.unknown => '$actionLabel返回未知状态，故障码 0x$reason。',
    };
  }

  String _remotePairingErrorMessage(RemotePairingResult result) {
    final reason = result.reasonCode
        .toRadixString(16)
        .padLeft(8, '0')
        .toUpperCase();
    return 'remote_pairing_${result.status.name}_0x$reason';
  }

  bool _deviceIdMissing(String deviceId) {
    if (deviceId.trim().isNotEmpty) {
      return false;
    }
    state = state.copyWith(
      errorMessage: '未找到当前设备，请返回重新连接设备。',
      clearInfoMessage: true,
    );
    return true;
  }

  String _remoteOperationInfoMessage(
    String actionLabel,
    RemoteOperationResult result,
  ) {
    final reason = result.reasonCode
        .toRadixString(16)
        .padLeft(8, '0')
        .toUpperCase();
    return switch (result.status) {
      RemoteOperationStatus.success => '$actionLabel成功，故障码 0x$reason。',
      RemoteOperationStatus.failure => '$actionLabel失败，故障码 0x$reason。',
      RemoteOperationStatus.unknown => '$actionLabel返回未知状态，故障码 0x$reason。',
    };
  }

  String _remoteOperationErrorMessage(
    String operation,
    RemoteOperationResult result,
  ) {
    final reason = result.reasonCode
        .toRadixString(16)
        .padLeft(8, '0')
        .toUpperCase();
    return 'remote_${operation}_${result.status.name}_0x$reason';
  }

  String _serialNumberLabel(int serialNumber) {
    return '0x${serialNumber.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  String _doorDetailErrorMessage(AppError error) {
    return switch (error.code) {
      AppErrorCode.networkUnavailable => '网络不可用，门详情加载失败。',
      AppErrorCode.serverError => '门详情数据异常，请稍后重试。',
      _ => '门详情加载失败。',
    };
  }
}
