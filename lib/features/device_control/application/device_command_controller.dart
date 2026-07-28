import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../add_device/application/ble_auth_token.dart';
import '../../add_device/application/providers.dart';
import '../../add_device/domain/entities/onboarding_device_key.dart';
import '../../add_device/domain/use_cases/fetch_onboarding_device_key_use_case.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/logging/providers.dart';
import '../../../core/network/providers.dart';
import '../../../platform_bridge/hardware_gateway.dart';
import '../../../platform_bridge/hardware_models.dart';
import '../../../platform_bridge/providers.dart';
import '../data/data_sources/door_detail_api.dart';
import '../data/data_sources/door_detail_remote_data_source.dart';
import '../data/mappers/door_realtime_state_mapper.dart';
import '../data/repositories/door_detail_repository_impl.dart';
import '../domain/entities/door_detail.dart';
import '../domain/entities/door_device.dart';
import '../domain/entities/door_realtime_state.dart';
import '../domain/repositories/door_detail_repository.dart';
import '../domain/use_cases/fetch_door_detail_use_case.dart';
import '../domain/use_cases/fetch_door_devices_use_case.dart';
import '../domain/use_cases/unbind_door_device_use_case.dart';

final deviceCommandHardwareGatewayProvider = Provider<HardwareGateway>((ref) {
  return ref.watch(nativeHardwareGatewayProvider);
});

final deviceCommandBleScanDurationProvider = Provider<Duration>((ref) {
  return const Duration(seconds: 10);
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

final fetchDoorDevicesUseCaseProvider = Provider<FetchDoorDevicesUseCase>((
  ref,
) {
  return FetchDoorDevicesUseCase(
    repository: ref.watch(doorDetailRepositoryProvider),
  );
});

final unbindDoorDeviceUseCaseProvider = Provider<UnbindDoorDeviceUseCase>((
  ref,
) {
  return UnbindDoorDeviceUseCase(
    repository: ref.watch(doorDetailRepositoryProvider),
  );
});

final doorDevicesRefreshRequestProvider =
    NotifierProvider<
      DoorDevicesRefreshRequestNotifier,
      DoorDevicesRefreshRequest?
    >(DoorDevicesRefreshRequestNotifier.new);

class DoorDevicesRefreshRequest {
  const DoorDevicesRefreshRequest({
    required this.doorId,
    required this.sequence,
  });

  final String doorId;
  final int sequence;
}

class DoorDevicesRefreshRequestNotifier
    extends Notifier<DoorDevicesRefreshRequest?> {
  @override
  DoorDevicesRefreshRequest? build() => null;

  void notify(DoorDevicesRefreshRequest request) {
    state = request;
  }
}

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

enum DeviceBleConnectionStatus {
  idle,
  scanning,
  connecting,
  authenticating,
  connected,
}

class DeviceCommandState {
  const DeviceCommandState({
    this.doorDetail,
    this.doorDevices = const <DoorDevice>[],
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
    this.bleConnectionStatus = DeviceBleConnectionStatus.idle,
    this.bleDeviceId,
    this.bleTargetName,
    this.bleConnectionStatuses = const <String, DeviceBleConnectionStatus>{},
    this.bleDeviceIds = const <String, String>{},
    this.bleConnectionErrors = const <String>{},
    this.selectedDeviceId,
    this.lastSelectedBleNotification,
    this.lastSelectedAttributeSnapshot,
    this.doorRealtimeState,
  });

  final DoorDetail? doorDetail;
  final List<DoorDevice> doorDevices;
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
  final DeviceBleConnectionStatus bleConnectionStatus;
  final String? bleDeviceId;
  final String? bleTargetName;
  final Map<String, DeviceBleConnectionStatus> bleConnectionStatuses;
  final Map<String, String> bleDeviceIds;
  final Set<String> bleConnectionErrors;
  final String? selectedDeviceId;
  final BleNotification? lastSelectedBleNotification;
  final DeviceAttributeSnapshot? lastSelectedAttributeSnapshot;
  final DoorRealtimeState? doorRealtimeState;

  DeviceCommandState copyWith({
    DoorDetail? doorDetail,
    bool clearDoorDetail = false,
    List<DoorDevice>? doorDevices,
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
    DeviceBleConnectionStatus? bleConnectionStatus,
    String? bleDeviceId,
    bool clearBleDeviceId = false,
    String? bleTargetName,
    bool clearBleTargetName = false,
    Map<String, DeviceBleConnectionStatus>? bleConnectionStatuses,
    Map<String, String>? bleDeviceIds,
    Set<String>? bleConnectionErrors,
    String? selectedDeviceId,
    bool clearSelectedDeviceId = false,
    BleNotification? lastSelectedBleNotification,
    bool clearLastSelectedBleNotification = false,
    DeviceAttributeSnapshot? lastSelectedAttributeSnapshot,
    bool clearLastSelectedAttributeSnapshot = false,
    DoorRealtimeState? doorRealtimeState,
    bool clearDoorRealtimeState = false,
  }) {
    return DeviceCommandState(
      doorDetail: clearDoorDetail ? null : doorDetail ?? this.doorDetail,
      doorDevices: doorDevices ?? this.doorDevices,
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
      bleConnectionStatus: bleConnectionStatus ?? this.bleConnectionStatus,
      bleDeviceId: clearBleDeviceId ? null : bleDeviceId ?? this.bleDeviceId,
      bleTargetName: clearBleTargetName
          ? null
          : bleTargetName ?? this.bleTargetName,
      bleConnectionStatuses:
          bleConnectionStatuses ?? this.bleConnectionStatuses,
      bleDeviceIds: bleDeviceIds ?? this.bleDeviceIds,
      bleConnectionErrors: bleConnectionErrors ?? this.bleConnectionErrors,
      selectedDeviceId: clearSelectedDeviceId
          ? null
          : selectedDeviceId ?? this.selectedDeviceId,
      lastSelectedBleNotification: clearLastSelectedBleNotification
          ? null
          : lastSelectedBleNotification ?? this.lastSelectedBleNotification,
      lastSelectedAttributeSnapshot: clearLastSelectedAttributeSnapshot
          ? null
          : lastSelectedAttributeSnapshot ?? this.lastSelectedAttributeSnapshot,
      doorRealtimeState: clearDoorRealtimeState
          ? null
          : doorRealtimeState ?? this.doorRealtimeState,
    );
  }
}

class DeviceCommandController extends Notifier<DeviceCommandState> {
  late final HardwareGateway _gateway;
  late final FetchDoorDetailUseCase _fetchDoorDetailUseCase;
  late final FetchDoorDevicesUseCase _fetchDoorDevicesUseCase;
  late final FetchOnboardingDeviceKeyUseCase _fetchDeviceKeyUseCase;
  late final AppLogger _logger;
  late final Duration _bleScanDuration;
  final List<StreamSubscription<Object?>> _subscriptions =
      <StreamSubscription<Object?>>[];
  Timer? _bleScanTimer;
  final Map<String, DoorDevice> _pendingBleNames = <String, DoorDevice>{};
  final Map<String, String> _nativeToDoorDeviceId = <String, String>{};
  final Map<String, OnboardingDeviceKey> _deviceKeys =
      <String, OnboardingDeviceKey>{};
  final Set<String> _connectingDoorDeviceIds = <String>{};
  var _bleSessionId = 0;
  int _requestCounter = 0;

  @override
  DeviceCommandState build() {
    _gateway = ref.watch(deviceCommandHardwareGatewayProvider);
    _fetchDoorDetailUseCase = ref.watch(fetchDoorDetailUseCaseProvider);
    _fetchDoorDevicesUseCase = ref.watch(fetchDoorDevicesUseCaseProvider);
    _fetchDeviceKeyUseCase = ref.watch(fetchOnboardingDeviceKeyUseCaseProvider);
    _logger = ref.watch(appLoggerProvider);
    _bleScanDuration = ref.watch(deviceCommandBleScanDurationProvider);
    ref.listen<DoorDevicesRefreshRequest?>(doorDevicesRefreshRequestProvider, (
      _,
      request,
    ) {
      if (request == null || state.doorDetail?.id != request.doorId) {
        return;
      }
      unawaited(refreshDoorDevices(doorId: request.doorId));
    });
    _subscriptions.add(_gateway.bleScanResults.listen(_onBleDeviceFound));
    _subscriptions.add(
      _gateway.bleConnectionEvents.listen(_onBleConnectionChanged),
    );
    _subscriptions.add(_gateway.bleNotifications.listen(_onBleNotification));
    _subscriptions.add(
      _gateway.deviceAttributeSnapshots.listen(_onDeviceAttributeSnapshot),
    );
    ref.onDispose(() {
      unawaited(disposeBleSession());
      for (final subscription in _subscriptions) {
        unawaited(subscription.cancel());
      }
      _subscriptions.clear();
    });
    return const DeviceCommandState();
  }

  Future<void> loadDoorDetail({
    required String doorId,
    String preferredDeviceId = '',
  }) async {
    await _resetBleSessionTracking();
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
      final results = await Future.wait<Object>([
        _fetchDoorDetailUseCase(
          doorId: trimmedDoorId,
          requestId: _nextDoorDetailRequestId(trimmedDoorId),
        ),
        _fetchDoorDevicesUseCase(
          doorId: trimmedDoorId,
          requestId: _nextDoorDevicesRequestId(trimmedDoorId),
        ),
      ]);
      final detail = results[0] as DoorDetail;
      final doorDevices = results[1] as List<DoorDevice>;
      state = state.copyWith(
        doorDetail: detail,
        doorDevices: doorDevices,
        isLoadingDoorDetail: false,
        clearDoorDetailErrorMessage: true,
      );
      _selectInitialDevice(doorDevices, preferredDeviceId);
      unawaited(_startBlePool(doorDevices));
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

  Future<void> refreshDoorDevices({required String doorId}) async {
    final trimmedDoorId = doorId.trim();
    if (trimmedDoorId.isEmpty || state.isLoadingDoorDetail) {
      return;
    }

    try {
      final doorDevices = await _fetchDoorDevicesUseCase(
        doorId: trimmedDoorId,
        requestId: _nextDoorDevicesRequestId(trimmedDoorId),
      );
      await _reconcileBlePool(doorDevices);
    } on AppError {
      // Preserve the currently rendered device cards when a background refresh
      // fails; the originating page already presents the unbind failure state.
    } catch (_) {
      // Preserve the currently rendered device cards when a background refresh
      // fails; the originating page already presents the unbind failure state.
    }
  }

  Future<void> _reconcileBlePool(List<DoorDevice> doorDevices) async {
    final previousSelectedDeviceId = state.selectedDeviceId;
    final retainedDeviceIds = doorDevices
        .map((device) => device.deviceId)
        .toSet();
    final nativeDeviceIdsToDisconnect = <String>{};

    for (final entry in state.bleDeviceIds.entries) {
      final status = state.bleConnectionStatuses[entry.key];
      if (!retainedDeviceIds.contains(entry.key) ||
          status == DeviceBleConnectionStatus.connecting ||
          status == DeviceBleConnectionStatus.authenticating) {
        nativeDeviceIdsToDisconnect.add(entry.value);
      }
    }

    _bleSessionId += 1;
    _pendingBleNames.clear();
    _nativeToDoorDeviceId.clear();
    _deviceKeys.clear();
    _connectingDoorDeviceIds.clear();
    _bleScanTimer?.cancel();
    _bleScanTimer = null;

    try {
      await _gateway.stopBleScan(
        requestId: _nextBleRequestId('refresh-scan-stop'),
      );
    } catch (_) {
      // The page-level scan may already have completed.
    }
    await Future.wait(
      nativeDeviceIdsToDisconnect.map((nativeDeviceId) async {
        try {
          await _gateway.disconnectBleDevice(
            requestId: _nextBleRequestId('refresh-disconnect'),
            deviceId: nativeDeviceId,
          );
        } catch (_) {
          // A removed or in-flight device may already be disconnected.
        }
      }),
    );

    final retainedStatuses = <String, DeviceBleConnectionStatus>{};
    final retainedNativeDeviceIds = <String, String>{};
    for (final deviceId in retainedDeviceIds) {
      if (state.bleConnectionStatuses[deviceId] ==
          DeviceBleConnectionStatus.connected) {
        final nativeDeviceId = state.bleDeviceIds[deviceId];
        if (nativeDeviceId != null &&
            !nativeDeviceIdsToDisconnect.contains(nativeDeviceId)) {
          retainedStatuses[deviceId] = DeviceBleConnectionStatus.connected;
          retainedNativeDeviceIds[deviceId] = nativeDeviceId;
          _nativeToDoorDeviceId[nativeDeviceId] = deviceId;
        }
      }
    }

    final selectedDeviceId =
        previousSelectedDeviceId != null &&
            retainedDeviceIds.contains(previousSelectedDeviceId)
        ? previousSelectedDeviceId
        : doorDevices.firstOrNull?.deviceId;
    state = state.copyWith(
      doorDevices: doorDevices,
      bleConnectionStatuses: retainedStatuses,
      bleDeviceIds: retainedNativeDeviceIds,
      bleConnectionErrors: state.bleConnectionErrors
          .where(retainedDeviceIds.contains)
          .toSet(),
      selectedDeviceId: selectedDeviceId,
      clearSelectedDeviceId: selectedDeviceId == null,
      bleConnectionStatus: DeviceBleConnectionStatus.idle,
      clearBleDeviceId: true,
      clearBleTargetName: true,
    );
    if (selectedDeviceId != null) {
      selectDevice(selectedDeviceId);
    }
    await _startBlePool(doorDevices);
  }

  String _nextDoorDevicesRequestId(String doorId) {
    _requestCounter += 1;
    return 'door-devices-$doorId-'
        '${DateTime.now().toUtc().microsecondsSinceEpoch}-$_requestCounter';
  }

  Future<void> disposeBleSession() async {
    _bleSessionId += 1;
    _pendingBleNames.clear();
    _nativeToDoorDeviceId.clear();
    _deviceKeys.clear();
    _connectingDoorDeviceIds.clear();
    _bleScanTimer?.cancel();
    _bleScanTimer = null;
    try {
      await _gateway.stopBleScan(requestId: _nextBleRequestId('scan-stop'));
    } catch (_) {
      // Scanning may already be stopped by native code.
    }
    try {
      await _gateway.disconnectAllManagedBleDevices(
        requestId: _nextBleRequestId('disconnect-all'),
      );
    } catch (_) {
      // Cleanup is best effort while the page/provider is leaving.
    }
    if (ref.mounted) {
      state = state.copyWith(
        bleConnectionStatus: DeviceBleConnectionStatus.idle,
        clearBleDeviceId: true,
        clearBleTargetName: true,
        bleConnectionStatuses: const <String, DeviceBleConnectionStatus>{},
        bleDeviceIds: const <String, String>{},
        bleConnectionErrors: const <String>{},
      );
    }
  }

  Future<void> _resetBleSessionTracking() async {
    _bleSessionId += 1;
    _pendingBleNames.clear();
    _nativeToDoorDeviceId.clear();
    _deviceKeys.clear();
    _connectingDoorDeviceIds.clear();
    _bleScanTimer?.cancel();
    _bleScanTimer = null;
    try {
      await _gateway.stopBleScan(requestId: _nextBleRequestId('scan-stop'));
    } catch (_) {
      // A previous page scan may already have stopped.
    }
    state = state.copyWith(
      bleConnectionStatus: DeviceBleConnectionStatus.idle,
      clearBleDeviceId: true,
      clearBleTargetName: true,
      bleConnectionStatuses: const <String, DeviceBleConnectionStatus>{},
      bleDeviceIds: const <String, String>{},
      bleConnectionErrors: const <String>{},
      clearLastSelectedBleNotification: true,
      clearLastSelectedAttributeSnapshot: true,
      clearDoorRealtimeState: true,
    );
  }

  void _selectInitialDevice(
    List<DoorDevice> devices,
    String preferredDeviceId,
  ) {
    final preferred = preferredDeviceId.trim();
    DoorDevice? selected;
    for (final device in devices) {
      if (preferred.isNotEmpty &&
          (device.deviceId == preferred ||
              device.sn == preferred ||
              device.bleUuid == preferred ||
              device.bleMac == preferred)) {
        selected = device;
        break;
      }
    }
    selected ??= devices.firstOrNull;
    if (selected != null) {
      selectDevice(selected.deviceId);
    }
  }

  void selectDevice(String deviceId) {
    final selected = state.doorDevices
        .where((device) => device.deviceId == deviceId)
        .firstOrNull;
    if (selected == null) {
      return;
    }
    final status =
        state.bleConnectionStatuses[deviceId] ?? DeviceBleConnectionStatus.idle;
    final deviceChanged = state.selectedDeviceId != deviceId;
    state = state.copyWith(
      selectedDeviceId: deviceId,
      bleConnectionStatus: status,
      bleDeviceId: state.bleDeviceIds[deviceId],
      clearBleDeviceId: !state.bleDeviceIds.containsKey(deviceId),
      bleTargetName: selected.bleName,
      clearBleTargetName: (selected.bleName?.trim().isEmpty ?? true),
      clearLastSelectedBleNotification: deviceChanged,
      clearLastSelectedAttributeSnapshot: deviceChanged,
      clearDoorRealtimeState: deviceChanged,
    );
  }

  Future<void> connectDoorDevice({required String bleName}) async {
    final normalizedBleName = bleName.trim();
    final device = state.doorDevices
        .where((item) => item.bleName?.trim() == normalizedBleName)
        .firstOrNull;
    if (device != null) {
      selectDevice(device.deviceId);
    }
  }

  String? get selectedHardwareDeviceId {
    final selectedDeviceId = state.selectedDeviceId;
    if (selectedDeviceId == null ||
        state.bleConnectionStatuses[selectedDeviceId] !=
            DeviceBleConnectionStatus.connected) {
      return null;
    }
    return state.bleDeviceIds[selectedDeviceId];
  }

  Future<void> _startBlePool(List<DoorDevice> devices) async {
    final sessionId = _bleSessionId;
    final eligibleDevices = devices
        .where((device) => _targetBleName(device).isNotEmpty)
        .toList(growable: false);
    await _prefetchDeviceKeys(eligibleDevices, sessionId);
    if (!_isCurrentBleSession(sessionId)) {
      return;
    }
    List<ConnectedBleDevice> connectedDevices;
    try {
      connectedDevices = await _gateway.getConnectedBleDevices(
        requestId: _nextBleRequestId('connected-snapshot'),
      );
    } catch (_) {
      connectedDevices = const <ConnectedBleDevice>[];
    }
    if (!_isCurrentBleSession(sessionId)) {
      return;
    }
    final statuses = Map<String, DeviceBleConnectionStatus>.from(
      state.bleConnectionStatuses,
    );
    final deviceIds = Map<String, String>.from(state.bleDeviceIds);
    for (final device in eligibleDevices) {
      final bleName = _targetBleName(device);
      final existing = connectedDevices
          .where((connected) => _matchesConnectedDevice(device, connected))
          .firstOrNull;
      if (existing != null && existing.state == BleConnectionState.connected) {
        statuses[device.deviceId] = DeviceBleConnectionStatus.connected;
        deviceIds[device.deviceId] = existing.deviceId;
        _nativeToDoorDeviceId[existing.deviceId] = device.deviceId;
      } else if (_deviceKeys.containsKey(device.deviceId)) {
        _pendingBleNames[bleName] = device;
        statuses[device.deviceId] = DeviceBleConnectionStatus.scanning;
      } else {
        statuses[device.deviceId] = DeviceBleConnectionStatus.idle;
      }
    }
    state = state.copyWith(
      bleConnectionStatuses: statuses,
      bleDeviceIds: deviceIds,
    );
    _refreshSelectedBleView();
    if (_pendingBleNames.isEmpty) {
      return;
    }
    try {
      await _gateway.startBleScan(
        requestId: _nextBleRequestId('scan'),
        filter: const BleScanFilter(),
      );
      if (!_isCurrentBleSession(sessionId)) {
        return;
      }
      _bleScanTimer = Timer(_bleScanDuration, () {
        unawaited(_stopBleScanAfterTimeout(sessionId));
      });
    } catch (_) {
      if (_isCurrentBleSession(sessionId)) {
        state = state.copyWith(
          bleConnectionStatus: DeviceBleConnectionStatus.idle,
          clearBleTargetName: true,
        );
      }
    }
  }

  Future<void> _prefetchDeviceKeys(
    List<DoorDevice> devices,
    int sessionId,
  ) async {
    final failedDeviceIds = <String>{};
    await Future.wait(
      devices.map((device) async {
        final sn = device.sn.trim();
        if (sn.isEmpty) {
          failedDeviceIds.add(device.deviceId);
          return;
        }
        try {
          final key = await _fetchDeviceKeyUseCase(
            sn: sn,
            requestId: _nextBleRequestId('device-key'),
          );
          if (_isCurrentBleSession(sessionId)) {
            _deviceKeys[device.deviceId] = key;
          }
        } catch (_) {
          failedDeviceIds.add(device.deviceId);
        }
      }),
    );
    if (_isCurrentBleSession(sessionId) && failedDeviceIds.isNotEmpty) {
      state = state.copyWith(
        bleConnectionErrors: <String>{
          ...state.bleConnectionErrors,
          ...failedDeviceIds,
        },
      );
    }
  }

  void _onBleDeviceFound(Object? event) {
    if (event is! BleDevice) {
      return;
    }
    final name = event.name?.trim();
    final sn = event.sn?.trim();
    final target =
        (name == null ? null : _pendingBleNames[name]) ??
        (sn == null ? null : _pendingBleNames[sn]);
    if (target == null || _connectingDoorDeviceIds.contains(target.deviceId)) {
      return;
    }
    final sessionId = _bleSessionId;
    _pendingBleNames.remove(_targetBleName(target));
    _connectingDoorDeviceIds.add(target.deviceId);
    _nativeToDoorDeviceId[event.id] = target.deviceId;
    unawaited(_connectAndAuthenticate(event, target, sessionId));
  }

  Future<void> _stopBleScanAfterTimeout(int sessionId) async {
    if (!_isCurrentBleSession(sessionId) || _pendingBleNames.isEmpty) {
      return;
    }
    try {
      await _gateway.stopBleScan(requestId: _nextBleRequestId('scan-timeout'));
    } catch (_) {
      // Timeout is intentionally silent.
    }
    if (_isCurrentBleSession(sessionId)) {
      final statuses = Map<String, DeviceBleConnectionStatus>.from(
        state.bleConnectionStatuses,
      );
      for (final target in _pendingBleNames.values) {
        statuses[target.deviceId] = DeviceBleConnectionStatus.idle;
      }
      _pendingBleNames.clear();
      state = state.copyWith(bleConnectionStatuses: statuses);
      _refreshSelectedBleView();
    }
  }

  Future<void> _connectAndAuthenticate(
    BleDevice device,
    DoorDevice target,
    int sessionId,
  ) async {
    try {
      _setDeviceBleStatus(
        target.deviceId,
        DeviceBleConnectionStatus.connecting,
        nativeDeviceId: device.id,
      );
      final connection = await _gateway.connectBleDevice(
        requestId: _nextBleRequestId('connect'),
        deviceId: device.id,
      );
      if (!_isCurrentBleSession(sessionId) ||
          connection.state != BleConnectionState.connected) {
        await _failBleDevice(target.deviceId, device.id, sessionId);
        return;
      }
      _setDeviceBleStatus(
        target.deviceId,
        DeviceBleConnectionStatus.authenticating,
      );
      final deviceKey = _deviceKeys[target.deviceId];
      if (deviceKey == null) {
        await _failBleDevice(target.deviceId, device.id, sessionId);
        return;
      }
      if (!_isCurrentBleSession(sessionId)) {
        return;
      }
      final authenticated = await _gateway.authenticateBleDevice(
        requestId: _nextBleRequestId('authenticate'),
        deviceId: device.id,
        token: buildBleAuthenticationToken(deviceKey.aesKey),
        aesKey: deviceKey.aesKey,
        aesKeyVersion: deviceKey.aesKeyVersion,
      );
      if (!_isCurrentBleSession(sessionId) || !authenticated.authenticated) {
        await _failBleDevice(target.deviceId, device.id, sessionId);
        return;
      }
      _setDeviceBleStatus(
        target.deviceId,
        DeviceBleConnectionStatus.connected,
        nativeDeviceId: device.id,
      );
    } catch (_) {
      await _failBleDevice(target.deviceId, device.id, sessionId);
    } finally {
      _connectingDoorDeviceIds.remove(target.deviceId);
      if (_pendingBleNames.isEmpty && _connectingDoorDeviceIds.isEmpty) {
        _bleScanTimer?.cancel();
        _bleScanTimer = null;
        try {
          await _gateway.stopBleScan(
            requestId: _nextBleRequestId('scan-complete'),
          );
        } catch (_) {
          // The scan may have already stopped.
        }
      }
    }
  }

  Future<void> _failBleDevice(
    String doorDeviceId,
    String nativeDeviceId,
    int sessionId,
  ) async {
    if (!_isCurrentBleSession(sessionId)) {
      return;
    }
    try {
      await _gateway.disconnectBleDevice(
        requestId: _nextBleRequestId('disconnect'),
        deviceId: nativeDeviceId,
      );
    } catch (_) {
      // A failed connection may already be disconnected.
    }
    if (_isCurrentBleSession(sessionId)) {
      final errors = Set<String>.from(state.bleConnectionErrors)
        ..add(doorDeviceId);
      _setDeviceBleStatus(
        doorDeviceId,
        DeviceBleConnectionStatus.idle,
        clearNativeDeviceId: true,
        errors: errors,
      );
    }
  }

  void _onBleConnectionChanged(BleConnectionEvent event) {
    final doorDeviceId = _nativeToDoorDeviceId[event.deviceId];
    if (doorDeviceId == null) {
      return;
    }
    final selectedDeviceDisconnected =
        event.state == BleConnectionState.disconnected &&
        doorDeviceId == state.selectedDeviceId;
    final doorId = state.doorDetail?.id.trim() ?? '';
    final status = switch (event.state) {
      BleConnectionState.disconnected => DeviceBleConnectionStatus.idle,
      BleConnectionState.connecting => DeviceBleConnectionStatus.connecting,
      BleConnectionState.connected => DeviceBleConnectionStatus.connected,
    };
    _setDeviceBleStatus(
      doorDeviceId,
      status,
      nativeDeviceId: event.deviceId,
      clearNativeDeviceId: event.state == BleConnectionState.disconnected,
    );
    if (event.state == BleConnectionState.disconnected) {
      _nativeToDoorDeviceId.remove(event.deviceId);
    }
    if (selectedDeviceDisconnected) {
      state = state.copyWith(
        clearLastSelectedBleNotification: true,
        clearLastSelectedAttributeSnapshot: true,
        clearDoorRealtimeState: true,
      );
      if (doorId.isNotEmpty) {
        unawaited(_refreshDoorDetailAfterDisconnect(doorId));
      }
    }
  }

  Future<void> _refreshDoorDetailAfterDisconnect(String doorId) async {
    final requestId = _nextDoorDetailRequestId(doorId);
    try {
      final detail = await _fetchDoorDetailUseCase(
        doorId: doorId,
        requestId: requestId,
      );
      if (!ref.mounted || state.doorDetail?.id != doorId) {
        return;
      }
      state = state.copyWith(doorDetail: detail);
      _logger.info(
        'door_detail_refreshed_after_ble_disconnect',
        tag: AppLogTag.ble,
        requestId: requestId,
        context: {'doorId': doorId},
      );
    } catch (error, stackTrace) {
      _logger.error(
        'door_detail_refresh_after_ble_disconnect_failed',
        tag: AppLogTag.ble,
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'doorId': doorId, 'errorType': error.runtimeType.toString()},
      );
    }
  }

  void _onBleNotification(BleNotification notification) {
    if (notification.deviceId != selectedHardwareDeviceId) {
      return;
    }
    state = state.copyWith(lastSelectedBleNotification: notification);
  }

  void _onDeviceAttributeSnapshot(DeviceAttributeSnapshot snapshot) {
    final activeHardwareDeviceId = selectedHardwareDeviceId;
    _logger.info(
      'device_attribute_snapshot_received',
      tag: AppLogTag.ble,
      requestId: snapshot.requestId,
      context: {
        'command': '0x0202',
        'sourceDeviceId': snapshot.deviceId,
        'selectedHardwareDeviceId': activeHardwareDeviceId,
        'selectedDoorDeviceId': state.selectedDeviceId,
        'origin': snapshot.origin.name,
        'sequence': snapshot.sequence,
        'attributeCount': snapshot.attributes.length,
        'attributeIds': snapshot.attributes
            .map(
              (attribute) =>
                  '0x${attribute.id.toRadixString(16).padLeft(4, '0').toUpperCase()}',
            )
            .toList(growable: false),
      },
    );
    if (snapshot.deviceId != activeHardwareDeviceId) {
      _logger.info(
        'device_attribute_snapshot_ignored',
        tag: AppLogTag.ble,
        requestId: snapshot.requestId,
        context: {
          'command': '0x0202',
          'reason': activeHardwareDeviceId == null
              ? 'no_selected_connected_hardware_device'
              : 'source_device_does_not_match_selected_device',
          'sourceDeviceId': snapshot.deviceId,
          'selectedHardwareDeviceId': activeHardwareDeviceId,
          'selectedDoorDeviceId': state.selectedDeviceId,
        },
      );
      return;
    }
    final selectedDevice = state.doorDevices
        .where((device) => device.deviceId == state.selectedDeviceId)
        .firstOrNull;
    final parseResult = DoorRealtimeStateMapper.parse(
      snapshot,
      previous: state.doorRealtimeState,
      isDongle: selectedDevice?.deviceType.trim().toLowerCase() == 'dongle',
    );
    final logContext = <String, Object?>{
      ...parseResult.diagnosticContext,
      'sourceDeviceId': snapshot.deviceId,
      'selectedDoorDeviceId': state.selectedDeviceId,
      'selectedDeviceType': selectedDevice?.deviceType,
      'uiUpdate': parseResult.hasValidUpdate
          ? 'applied'
          : parseResult.hasDoorAttributes
          ? 'rejected'
          : 'no_door_attributes_in_report',
    };
    if (parseResult.issues.isEmpty) {
      _logger.info(
        'device_attribute_report_parsed',
        tag: AppLogTag.ble,
        requestId: snapshot.requestId,
        context: logContext,
      );
    } else {
      _logger.warning(
        'device_attribute_report_parsed_with_issues',
        tag: AppLogTag.ble,
        requestId: snapshot.requestId,
        context: logContext,
      );
    }
    state = state.copyWith(
      lastSelectedAttributeSnapshot: snapshot,
      doorRealtimeState: parseResult.state,
    );
  }

  void _setDeviceBleStatus(
    String doorDeviceId,
    DeviceBleConnectionStatus status, {
    String? nativeDeviceId,
    bool clearNativeDeviceId = false,
    Set<String>? errors,
  }) {
    final statuses = Map<String, DeviceBleConnectionStatus>.from(
      state.bleConnectionStatuses,
    )..[doorDeviceId] = status;
    final deviceIds = Map<String, String>.from(state.bleDeviceIds);
    if (clearNativeDeviceId) {
      deviceIds.remove(doorDeviceId);
    } else if (nativeDeviceId != null) {
      deviceIds[doorDeviceId] = nativeDeviceId;
    }
    state = state.copyWith(
      bleConnectionStatuses: statuses,
      bleDeviceIds: deviceIds,
      bleConnectionErrors: errors,
    );
    _refreshSelectedBleView();
  }

  void _refreshSelectedBleView() {
    final selectedDeviceId = state.selectedDeviceId;
    if (selectedDeviceId == null) {
      return;
    }
    final selected = state.doorDevices
        .where((device) => device.deviceId == selectedDeviceId)
        .firstOrNull;
    final nativeId = state.bleDeviceIds[selectedDeviceId];
    state = state.copyWith(
      bleConnectionStatus:
          state.bleConnectionStatuses[selectedDeviceId] ??
          DeviceBleConnectionStatus.idle,
      bleDeviceId: nativeId,
      clearBleDeviceId: nativeId == null,
      bleTargetName: selected?.bleName,
      clearBleTargetName: (selected?.bleName?.trim().isEmpty ?? true),
    );
  }

  bool _matchesConnectedDevice(
    DoorDevice device,
    ConnectedBleDevice connected,
  ) {
    final connectedId = connected.deviceId.trim().toLowerCase();
    final ids = <String>{
      device.bleUuid?.trim().toLowerCase() ?? '',
      device.bleMac?.trim().toLowerCase() ?? '',
    }..remove('');
    return ids.contains(connectedId) ||
        (connected.name?.trim().isNotEmpty == true &&
            connected.name!.trim() == _targetBleName(device));
  }

  String _targetBleName(DoorDevice device) {
    return device.bleName?.trim() ?? '';
  }

  bool _isCurrentBleSession(int sessionId) =>
      ref.mounted && sessionId == _bleSessionId;

  Future<void> runAction({
    required String deviceId,
    required DeviceCommandAction action,
  }) async {
    final targetDeviceId = _resolveSelectedHardwareDeviceId(deviceId);
    if (_deviceIdMissing(targetDeviceId)) {
      state = state.copyWith(
        errorMessage: '当前设备蓝牙未连接，无法发送控制指令。',
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
        deviceId: targetDeviceId,
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
    final targetDeviceId = _resolveSelectedHardwareDeviceId(deviceId);
    if (_deviceIdMissing(targetDeviceId)) {
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
        deviceId: targetDeviceId,
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
    final targetDeviceId = _resolveSelectedHardwareDeviceId(deviceId);
    if (_deviceIdMissing(targetDeviceId)) {
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
        deviceId: targetDeviceId,
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
    final targetDeviceId = _resolveSelectedHardwareDeviceId(deviceId);
    if (_deviceIdMissing(targetDeviceId)) {
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
        deviceId: targetDeviceId,
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
    final targetDeviceId = _resolveSelectedHardwareDeviceId(deviceId);
    if (_deviceIdMissing(targetDeviceId)) {
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
        deviceId: targetDeviceId,
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

  String _nextBleRequestId(String operation) {
    _requestCounter += 1;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'device-detail-ble-$operation-$timestamp-$_requestCounter';
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

  String _resolveSelectedHardwareDeviceId(String fallbackDeviceId) {
    final selectedDeviceId = state.selectedDeviceId;
    if (selectedDeviceId == null) {
      return fallbackDeviceId.trim();
    }
    if (state.bleConnectionStatuses[selectedDeviceId] !=
        DeviceBleConnectionStatus.connected) {
      return '';
    }
    return state.bleDeviceIds[selectedDeviceId]?.trim() ?? '';
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
