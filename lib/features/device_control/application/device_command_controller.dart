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
import '../data/data_sources/door_detail_api.dart';
import '../data/data_sources/door_detail_remote_data_source.dart';
import '../data/data_sources/remote_door_command_api.dart';
import '../data/data_sources/remote_door_command_remote_data_source.dart';
import '../data/mappers/door_realtime_state_mapper.dart';
import '../data/repositories/door_detail_repository_impl.dart';
import '../data/repositories/remote_door_command_repository_impl.dart';
import '../domain/entities/door_detail.dart';
import '../domain/entities/door_device.dart';
import '../domain/entities/door_realtime_state.dart';
import '../domain/entities/remote_door_command.dart';
import '../domain/repositories/door_detail_repository.dart';
import '../domain/repositories/remote_door_command_repository.dart';
import '../domain/use_cases/fetch_door_detail_use_case.dart';
import '../domain/use_cases/fetch_door_devices_use_case.dart';
import '../domain/use_cases/fetch_about_device_info_use_case.dart';
import '../domain/use_cases/submit_remote_door_command_use_case.dart';
import '../domain/use_cases/unbind_door_device_use_case.dart';
import 'local_door_command_executor.dart';

export 'local_door_command_executor.dart';

final deviceCommandBleScanDurationProvider = Provider<Duration>((ref) {
  return const Duration(seconds: 10);
});

final deviceCommandRemotePollIntervalProvider = Provider<Duration>((ref) {
  return const Duration(milliseconds: 500);
});

final deviceCommandRemotePollMaxAttemptsProvider = Provider<int>((ref) {
  return 6;
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

final fetchAboutDeviceInfoUseCaseProvider =
    Provider<FetchAboutDeviceInfoUseCase>((ref) {
      return FetchAboutDeviceInfoUseCase(
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

final remoteDoorCommandApiProvider = Provider<RemoteDoorCommandApi>((ref) {
  return RemoteDoorCommandApi(ref.watch(dioProvider));
});

final remoteDoorCommandRemoteDataSourceProvider =
    Provider<RemoteDoorCommandRemoteDataSource>((ref) {
      return RemoteDoorCommandRemoteDataSourceImpl(
        api: ref.watch(remoteDoorCommandApiProvider),
      );
    });

final remoteDoorCommandRepositoryProvider =
    Provider<RemoteDoorCommandRepository>((ref) {
      return RemoteDoorCommandRepositoryImpl(
        remoteDataSource: ref.watch(remoteDoorCommandRemoteDataSourceProvider),
        logger: ref.watch(appLoggerProvider),
      );
    });

final submitRemoteDoorCommandUseCaseProvider =
    Provider<SubmitRemoteDoorCommandUseCase>((ref) {
      return SubmitRemoteDoorCommandUseCase(
        repository: ref.watch(remoteDoorCommandRepositoryProvider),
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
  openDoor(0x1001, DoorCommand.open),
  closeDoor(0x1002, DoorCommand.close),
  stopDoor(0x1003, DoorCommand.stop),
  partialOpenDoor(0x1004, DoorCommand.partialOpen),
  turnLightOn(0x1005, DoorCommand.lightOn),
  turnLightOff(0x1006, DoorCommand.lightOff),
  pb(0x1007, DoorCommand.pb);

  const DeviceCommandAction(this.controlCode, this.doorCommand);

  final int controlCode;
  final DoorCommand doorCommand;

  String get controlCodeLabel =>
      '0x${controlCode.toRadixString(16).padLeft(4, '0').toUpperCase()}';
}

enum DeviceCommandTransport { bluetooth, app }

class DeviceCommandExecutionResult {
  const DeviceCommandExecutionResult({required this.succeeded, this.transport});

  final bool succeeded;
  final DeviceCommandTransport? transport;
}

enum DeviceCommandFeedbackKind {
  sending,
  succeeded,
  rejected,
  requiresBluetooth,
  remoteFailed,
  remoteUnconfirmed,
  remoteTimeout,
  networkFailure,
}

class DeviceCommandFeedback {
  const DeviceCommandFeedback({
    required this.kind,
    required this.action,
    this.failureCategory,
  });

  final DeviceCommandFeedbackKind kind;
  final DeviceCommandAction action;
  final String? failureCategory;

  bool get isError =>
      kind == DeviceCommandFeedbackKind.rejected ||
      kind == DeviceCommandFeedbackKind.requiresBluetooth ||
      kind == DeviceCommandFeedbackKind.remoteFailed ||
      kind == DeviceCommandFeedbackKind.remoteUnconfirmed ||
      kind == DeviceCommandFeedbackKind.remoteTimeout ||
      kind == DeviceCommandFeedbackKind.networkFailure;
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
    this.commandFeedback,
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
  final DeviceCommandFeedback? commandFeedback;

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
    DeviceCommandFeedback? commandFeedback,
    bool clearCommandFeedback = false,
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
      commandFeedback: clearCommandFeedback
          ? null
          : commandFeedback ?? this.commandFeedback,
    );
  }
}

class DeviceCommandController extends Notifier<DeviceCommandState> {
  static const _defaultDeviceTypePriority = <String>[
    'opener',
    'evolution',
    'dongle',
    'fbox',
  ];

  late final HardwareGateway _gateway;
  late final LocalDoorCommandExecutor _localDoorCommandExecutor;
  late final FetchDoorDetailUseCase _fetchDoorDetailUseCase;
  late final FetchDoorDevicesUseCase _fetchDoorDevicesUseCase;
  late final FetchOnboardingDeviceKeyUseCase _fetchDeviceKeyUseCase;
  late final SubmitRemoteDoorCommandUseCase _submitRemoteDoorCommandUseCase;
  late final AppLogger _logger;
  late final Duration _bleScanDuration;
  late final Duration _remotePollInterval;
  late final int _remotePollMaxAttempts;
  final List<StreamSubscription<Object?>> _subscriptions =
      <StreamSubscription<Object?>>[];
  Timer? _bleScanTimer;
  final Map<String, DoorDevice> _pendingBleNames = <String, DoorDevice>{};
  final Map<String, String> _nativeToDoorDeviceId = <String, String>{};
  final Map<String, OnboardingDeviceKey> _deviceKeys =
      <String, OnboardingDeviceKey>{};
  final Set<String> _connectingDoorDeviceIds = <String>{};
  var _bleSessionId = 0;
  var _remoteCommandGeneration = 0;
  var _doorDetailPollGeneration = 0;
  var _doorDetailLoadGeneration = 0;
  var _remotePairingGeneration = 0;
  int _requestCounter = 0;

  @override
  DeviceCommandState build() {
    _gateway = ref.watch(deviceCommandHardwareGatewayProvider);
    _localDoorCommandExecutor = ref.watch(localDoorCommandExecutorProvider);
    _fetchDoorDetailUseCase = ref.watch(fetchDoorDetailUseCaseProvider);
    _fetchDoorDevicesUseCase = ref.watch(fetchDoorDevicesUseCaseProvider);
    _fetchDeviceKeyUseCase = ref.watch(fetchOnboardingDeviceKeyUseCaseProvider);
    _submitRemoteDoorCommandUseCase = ref.watch(
      submitRemoteDoorCommandUseCaseProvider,
    );
    _logger = ref.watch(appLoggerProvider);
    _bleScanDuration = ref.watch(deviceCommandBleScanDurationProvider);
    _remotePollInterval = ref.watch(deviceCommandRemotePollIntervalProvider);
    _remotePollMaxAttempts = ref.watch(
      deviceCommandRemotePollMaxAttemptsProvider,
    );
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
      _cancelRemoteWork();
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
    final loadGeneration = ++_doorDetailLoadGeneration;
    _cancelRemoteWork();
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
      clearCommandFeedback: true,
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
      if (loadGeneration != _doorDetailLoadGeneration) {
        return;
      }
      state = state.copyWith(
        doorDetail: detail,
        doorDevices: doorDevices,
        isLoadingDoorDetail: false,
        clearDoorDetailErrorMessage: true,
      );
      _selectInitialDevice(doorDevices, preferredDeviceId);
      _restartDoorDetailPollingIfNeeded();
      unawaited(_startBlePool(doorDevices));
    } on AppError catch (error) {
      if (loadGeneration != _doorDetailLoadGeneration) {
        return;
      }
      state = state.copyWith(
        isLoadingDoorDetail: false,
        doorDetailErrorMessage: _doorDetailErrorMessage(error),
      );
    } catch (error) {
      if (loadGeneration != _doorDetailLoadGeneration) {
        return;
      }
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
        : _defaultDevice(doorDevices)?.deviceId;
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
    _cancelRemoteWork();
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
          (device.deviceId.trim() == preferred ||
              device.sn.trim() == preferred ||
              device.bleUuid?.trim() == preferred ||
              device.bleMac?.trim() == preferred)) {
        selected = device;
        break;
      }
    }
    selected ??= _defaultDevice(devices);
    if (selected != null) {
      selectDevice(selected.deviceId);
    } else {
      state = state.copyWith(clearSelectedDeviceId: true);
    }
  }

  DoorDevice? _defaultDevice(List<DoorDevice> devices) {
    for (final deviceType in _defaultDeviceTypePriority) {
      for (final device in devices) {
        if (device.deviceType.trim().toLowerCase() == deviceType) {
          return device;
        }
      }
    }
    return devices.firstOrNull;
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
    _restartDoorDetailPollingIfNeeded();
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
      _restartDoorDetailPollingIfNeeded(requestId: requestId);
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
    if (doorDeviceId == state.selectedDeviceId) {
      _restartDoorDetailPollingIfNeeded();
    }
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

  Future<DeviceCommandExecutionResult?> runAction({
    required String deviceId,
    required DeviceCommandAction action,
  }) async {
    if (state.pendingAction != null) {
      return null;
    }
    final selectedDeviceId = state.selectedDeviceId;
    final isBleConnected =
        selectedDeviceId != null &&
        state.bleConnectionStatuses[selectedDeviceId] ==
            DeviceBleConnectionStatus.connected;
    if (!isBleConnected) {
      final remoteAction = _remoteActionFor(action);
      if (remoteAction == null) {
        state = state.copyWith(
          commandFeedback: DeviceCommandFeedback(
            kind: DeviceCommandFeedbackKind.requiresBluetooth,
            action: action,
          ),
          clearInfoMessage: true,
          clearErrorMessage: true,
        );
        return const DeviceCommandExecutionResult(succeeded: false);
      }
      return _runRemoteAction(action: action, remoteAction: remoteAction);
    }

    final targetDeviceId = _resolveSelectedHardwareDeviceId(deviceId);
    if (_deviceIdMissing(targetDeviceId)) {
      state = state.copyWith(
        commandFeedback: DeviceCommandFeedback(
          kind: DeviceCommandFeedbackKind.requiresBluetooth,
          action: action,
        ),
        clearInfoMessage: true,
        clearErrorMessage: true,
      );
      return const DeviceCommandExecutionResult(succeeded: false);
    }

    state = state.copyWith(
      pendingAction: action,
      commandFeedback: DeviceCommandFeedback(
        kind: DeviceCommandFeedbackKind.sending,
        action: action,
      ),
      clearInfoMessage: true,
      clearErrorMessage: true,
    );

    try {
      final result = await _localDoorCommandExecutor.send(
        requestId: _nextRequestId(action),
        deviceId: targetDeviceId,
        command: action.doorCommand,
      );
      state = state.copyWith(
        clearPendingAction: true,
        commandFeedback: DeviceCommandFeedback(
          kind: result.accepted
              ? DeviceCommandFeedbackKind.succeeded
              : DeviceCommandFeedbackKind.rejected,
          action: action,
        ),
        clearInfoMessage: true,
        clearErrorMessage: result.accepted,
      );
      return DeviceCommandExecutionResult(
        succeeded: result.accepted,
        transport: DeviceCommandTransport.bluetooth,
      );
    } catch (error) {
      state = state.copyWith(
        clearPendingAction: true,
        commandFeedback: DeviceCommandFeedback(
          kind: DeviceCommandFeedbackKind.networkFailure,
          action: action,
        ),
        clearErrorMessage: true,
        clearInfoMessage: true,
      );
      return const DeviceCommandExecutionResult(
        succeeded: false,
        transport: DeviceCommandTransport.bluetooth,
      );
    }
  }

  Future<DeviceCommandExecutionResult?> _runRemoteAction({
    required DeviceCommandAction action,
    required RemoteDoorCommandAction remoteAction,
  }) async {
    final doorId = state.doorDetail?.id.trim() ?? '';
    final initialDoorState = state.doorDetail?.doorState;
    final initialLedStatus = state.doorDetail?.ledStatus;
    if (doorId.isEmpty) {
      state = state.copyWith(
        commandFeedback: DeviceCommandFeedback(
          kind: DeviceCommandFeedbackKind.networkFailure,
          action: action,
        ),
        clearInfoMessage: true,
        clearErrorMessage: true,
      );
      return const DeviceCommandExecutionResult(
        succeeded: false,
        transport: DeviceCommandTransport.app,
      );
    }

    _remoteCommandGeneration += 1;
    _doorDetailPollGeneration += 1;
    final generation = _remoteCommandGeneration;
    final requestId = _nextRemoteDoorCommandRequestId(doorId, action);
    state = state.copyWith(
      pendingAction: action,
      commandFeedback: DeviceCommandFeedback(
        kind: DeviceCommandFeedbackKind.sending,
        action: action,
      ),
      clearInfoMessage: true,
      clearErrorMessage: true,
    );

    try {
      final command = await _submitRemoteDoorCommandUseCase(
        doorId: doorId,
        action: remoteAction,
        requestId: requestId,
      );
      var stateConfirmed = false;
      var pollAttempts = 0;
      DoorDetail? latestDetail;

      while (_isCurrentRemoteCommand(generation) &&
          pollAttempts < _remotePollMaxAttempts) {
        await Future<void>.delayed(_remotePollInterval);
        if (!_isCurrentRemoteCommand(generation)) {
          return null;
        }

        final detail = await _fetchDoorDetailUseCase(
          doorId: doorId,
          requestId: requestId,
        );
        if (!_isCurrentRemoteCommand(generation)) {
          return null;
        }

        pollAttempts += 1;
        if (state.doorDetail?.id == doorId && detail.id == doorId) {
          state = state.copyWith(
            doorDetail: detail,
            clearDoorRealtimeState: true,
          );
        }
        latestDetail = detail;
        stateConfirmed = _isRemoteStateConfirmed(
          action: action,
          detail: detail,
          initialDoorState: initialDoorState,
        );
        if (stateConfirmed) {
          break;
        }
      }
      if (!_isCurrentRemoteCommand(generation)) {
        return null;
      }

      if (!stateConfirmed) {
        final detail = await _fetchDoorDetailUseCase(
          doorId: doorId,
          requestId: requestId,
        );
        if (!_isCurrentRemoteCommand(generation)) {
          return null;
        }
        if (state.doorDetail?.id == doorId && detail.id == doorId) {
          state = state.copyWith(
            doorDetail: detail,
            clearDoorRealtimeState: true,
          );
        }
        latestDetail = detail;
        stateConfirmed = _isRemoteStateConfirmed(
          action: action,
          detail: detail,
          initialDoorState: initialDoorState,
        );
      }

      if (latestDetail != null) {
        _restartDoorDetailPollingIfNeeded(requestId: requestId);
      }
      state = state.copyWith(
        clearPendingAction: true,
        commandFeedback: stateConfirmed
            ? DeviceCommandFeedback(
                kind: DeviceCommandFeedbackKind.succeeded,
                action: action,
                failureCategory: command.failureCategory,
              )
            : _isLightAction(action)
            ? DeviceCommandFeedback(
                kind: DeviceCommandFeedbackKind.remoteTimeout,
                action: action,
                failureCategory: command.failureCategory,
              )
            : null,
        clearCommandFeedback: !stateConfirmed && !_isLightAction(action),
        clearInfoMessage: true,
        clearErrorMessage: true,
      );
      _logger.info(
        'Remote door command completed',
        requestId: requestId,
        context: {
          'doorId': doorId,
          'commandId': command.commandId,
          'action': command.action.wireValue,
          'status': command.status.name,
          'initialDoorState': initialDoorState?.name,
          'finalDoorState': latestDetail?.doorState.name,
          'initialLedStatus': initialLedStatus,
          'targetLedStatus': _targetLedStatus(action),
          'finalLedStatus': latestDetail?.ledStatus,
          'pollAttempts': pollAttempts,
          'stateConfirmed': stateConfirmed,
          'failureCategory': command.failureCategory,
          'deviceResultCode': command.deviceResultCode,
        },
      );
      return DeviceCommandExecutionResult(
        succeeded: stateConfirmed,
        transport: DeviceCommandTransport.app,
      );
    } catch (error, stackTrace) {
      if (!_isCurrentRemoteCommand(generation)) {
        return null;
      }
      state = state.copyWith(
        clearPendingAction: true,
        commandFeedback: DeviceCommandFeedback(
          kind: DeviceCommandFeedbackKind.networkFailure,
          action: action,
        ),
        clearInfoMessage: true,
        clearErrorMessage: true,
      );
      _logger.error(
        'Remote door command failed',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'doorId': doorId, 'action': remoteAction.wireValue},
      );
      return const DeviceCommandExecutionResult(
        succeeded: false,
        transport: DeviceCommandTransport.app,
      );
    }
  }

  bool _isRemoteStateConfirmed({
    required DeviceCommandAction action,
    required DoorDetail detail,
    required DoorState? initialDoorState,
  }) {
    final targetLedStatus = _targetLedStatus(action);
    if (targetLedStatus != null) {
      return detail.ledStatus == targetLedStatus;
    }
    return initialDoorState != null && detail.doorState != initialDoorState;
  }

  bool _isLightAction(DeviceCommandAction action) =>
      _targetLedStatus(action) != null;

  int? _targetLedStatus(DeviceCommandAction action) {
    return switch (action) {
      DeviceCommandAction.turnLightOn => 2,
      DeviceCommandAction.turnLightOff => 1,
      DeviceCommandAction.openDoor ||
      DeviceCommandAction.closeDoor ||
      DeviceCommandAction.stopDoor ||
      DeviceCommandAction.partialOpenDoor ||
      DeviceCommandAction.pb => null,
    };
  }

  RemoteDoorCommandAction? _remoteActionFor(DeviceCommandAction action) {
    return switch (action) {
      DeviceCommandAction.openDoor => RemoteDoorCommandAction.open,
      DeviceCommandAction.closeDoor => RemoteDoorCommandAction.close,
      DeviceCommandAction.stopDoor => RemoteDoorCommandAction.stop,
      DeviceCommandAction.turnLightOn => RemoteDoorCommandAction.ledOn,
      DeviceCommandAction.turnLightOff => RemoteDoorCommandAction.ledOff,
      DeviceCommandAction.partialOpenDoor || DeviceCommandAction.pb => null,
    };
  }

  void _restartDoorDetailPollingIfNeeded({String? requestId}) {
    _doorDetailPollGeneration += 1;
    final detail = state.doorDetail;
    if (detail == null || !_isDoorMoving(detail) || _isSelectedBleConnected()) {
      return;
    }
    final generation = _doorDetailPollGeneration;
    final pollRequestId =
        requestId ?? _nextDoorDetailRequestId(detail.id.trim());
    unawaited(
      _pollDoorDetail(
        doorId: detail.id.trim(),
        requestId: pollRequestId,
        generation: generation,
      ),
    );
  }

  Future<void> _pollDoorDetail({
    required String doorId,
    required String requestId,
    required int generation,
  }) async {
    while (_isCurrentDoorDetailPoll(generation)) {
      await Future<void>.delayed(_remotePollInterval);
      if (!_isCurrentDoorDetailPoll(generation) || _isSelectedBleConnected()) {
        return;
      }
      try {
        final detail = await _fetchDoorDetailUseCase(
          doorId: doorId,
          requestId: requestId,
        );
        if (!_isCurrentDoorDetailPoll(generation) ||
            state.doorDetail?.id != doorId) {
          return;
        }
        state = state.copyWith(
          doorDetail: detail,
          clearDoorRealtimeState: true,
        );
        if (!_isDoorMoving(detail)) {
          return;
        }
      } catch (error, stackTrace) {
        if (_isCurrentDoorDetailPoll(generation)) {
          _logger.error(
            'Door detail movement polling failed',
            requestId: requestId,
            error: error,
            stackTrace: stackTrace,
            context: {'doorId': doorId},
          );
        }
        return;
      }
    }
  }

  bool _isDoorMoving(DoorDetail detail) =>
      detail.doorState == DoorState.opening ||
      detail.doorState == DoorState.closing;

  bool _isSelectedBleConnected() {
    final selectedDeviceId = state.selectedDeviceId;
    return selectedDeviceId != null &&
        state.bleConnectionStatuses[selectedDeviceId] ==
            DeviceBleConnectionStatus.connected;
  }

  bool _isCurrentRemoteCommand(int generation) =>
      ref.mounted && generation == _remoteCommandGeneration;

  bool _isCurrentDoorDetailPoll(int generation) =>
      ref.mounted && generation == _doorDetailPollGeneration;

  void _cancelRemoteWork() {
    _remoteCommandGeneration += 1;
    _doorDetailPollGeneration += 1;
  }

  Future<bool> startRemotePairing({required String deviceId}) {
    return _runRemotePairingAction(
      deviceId: deviceId,
      action: RemotePairingAction.start,
    );
  }

  Future<bool> cancelRemotePairing({required String deviceId}) {
    return _runRemotePairingAction(
      deviceId: deviceId,
      action: RemotePairingAction.cancel,
    );
  }

  Future<bool> _runRemotePairingAction({
    required String deviceId,
    required RemotePairingAction action,
  }) async {
    final generation = ++_remotePairingGeneration;
    final targetDeviceId = _resolveSelectedHardwareDeviceId(deviceId);
    if (_deviceIdMissing(targetDeviceId)) {
      return false;
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
      if (!ref.mounted || generation != _remotePairingGeneration) {
        return false;
      }
      state = state.copyWith(
        clearPendingRemotePairingAction: true,
        infoMessage: _remotePairingInfoMessage(action, result),
        errorMessage: result.successful
            ? null
            : _remotePairingErrorMessage(result),
        clearErrorMessage: result.successful,
      );
      return result.successful;
    } catch (error) {
      if (!ref.mounted || generation != _remotePairingGeneration) {
        return false;
      }
      state = state.copyWith(
        clearPendingRemotePairingAction: true,
        errorMessage: error.toString(),
        clearInfoMessage: true,
      );
      return false;
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

  String _nextRemoteDoorCommandRequestId(
    String doorId,
    DeviceCommandAction action,
  ) {
    _requestCounter += 1;
    final timestamp = DateTime.now().toUtc().microsecondsSinceEpoch;
    return 'remote-door-command-$doorId-${action.name}-$timestamp-'
        '$_requestCounter';
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
