import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../domain/entities/door_device.dart';
import '../domain/use_cases/fetch_door_devices_use_case.dart';
import '../domain/use_cases/unbind_door_device_use_case.dart';
import 'device_command_controller.dart';

final alreadyAddedDevicesControllerProvider =
    NotifierProvider<AlreadyAddedDevicesController, AlreadyAddedDevicesState>(
      AlreadyAddedDevicesController.new,
    );

class AlreadyAddedDevicesState {
  const AlreadyAddedDevicesState({
    this.devices = const <DoorDevice>[],
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.initialLoadFailed = false,
    this.hasMore = true,
    this.pendingUnbindDeviceId,
    this.unbindFailedDeviceId,
  });

  final List<DoorDevice> devices;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool initialLoadFailed;
  final bool hasMore;
  final String? pendingUnbindDeviceId;
  final String? unbindFailedDeviceId;

  AlreadyAddedDevicesState copyWith({
    List<DoorDevice>? devices,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? initialLoadFailed,
    bool? hasMore,
    String? pendingUnbindDeviceId,
    bool clearPendingUnbindDeviceId = false,
    String? unbindFailedDeviceId,
    bool clearUnbindFailedDeviceId = false,
  }) {
    return AlreadyAddedDevicesState(
      devices: devices ?? this.devices,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      initialLoadFailed: initialLoadFailed ?? this.initialLoadFailed,
      hasMore: hasMore ?? this.hasMore,
      pendingUnbindDeviceId: clearPendingUnbindDeviceId
          ? null
          : pendingUnbindDeviceId ?? this.pendingUnbindDeviceId,
      unbindFailedDeviceId: clearUnbindFailedDeviceId
          ? null
          : unbindFailedDeviceId ?? this.unbindFailedDeviceId,
    );
  }
}

class AlreadyAddedDevicesController extends Notifier<AlreadyAddedDevicesState> {
  late final FetchDoorDevicesUseCase _fetchDoorDevicesUseCase;
  late final UnbindDoorDeviceUseCase _unbindDoorDeviceUseCase;
  var _requestCounter = 0;

  @override
  AlreadyAddedDevicesState build() {
    _fetchDoorDevicesUseCase = ref.watch(fetchDoorDevicesUseCaseProvider);
    _unbindDoorDeviceUseCase = ref.watch(unbindDoorDeviceUseCaseProvider);
    return const AlreadyAddedDevicesState();
  }

  Future<void> loadInitial({required String doorId}) async {
    if (state.isInitialLoading || state.isRefreshing) {
      return;
    }
    await _fetchDevices(doorId: doorId, isRefresh: false);
  }

  Future<void> refresh({required String doorId}) async {
    if (state.isInitialLoading || state.isRefreshing) {
      return;
    }
    await _fetchDevices(doorId: doorId, isRefresh: true);
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isInitialLoading || state.isRefreshing) {
      return;
    }
    state = state.copyWith(hasMore: false);
  }

  Future<void> unbindDevice({
    required String doorId,
    required String deviceId,
  }) async {
    if (state.pendingUnbindDeviceId != null) {
      return;
    }

    final normalizedDoorId = doorId.trim();
    final normalizedDeviceId = deviceId.trim();
    state = state.copyWith(
      pendingUnbindDeviceId: normalizedDeviceId,
      clearUnbindFailedDeviceId: true,
    );
    try {
      await _unbindDoorDeviceUseCase(
        doorId: normalizedDoorId,
        deviceId: normalizedDeviceId,
        requestId: _nextUnbindRequestId(normalizedDoorId, normalizedDeviceId),
      );
      await refresh(doorId: normalizedDoorId);
      _notifyDeviceCommandDeviceListRefresh(normalizedDoorId);
    } on AppError {
      state = state.copyWith(unbindFailedDeviceId: normalizedDeviceId);
    } catch (_) {
      state = state.copyWith(unbindFailedDeviceId: normalizedDeviceId);
    } finally {
      state = state.copyWith(clearPendingUnbindDeviceId: true);
    }
  }

  Future<void> _fetchDevices({
    required String doorId,
    required bool isRefresh,
  }) async {
    final normalizedDoorId = doorId.trim();
    if (normalizedDoorId.isEmpty) {
      state = state.copyWith(
        isInitialLoading: false,
        isRefreshing: false,
        initialLoadFailed: true,
      );
      return;
    }

    state = state.copyWith(
      isInitialLoading: !isRefresh,
      isRefreshing: isRefresh,
      initialLoadFailed: false,
    );
    try {
      final devices = await _fetchDoorDevicesUseCase(
        doorId: normalizedDoorId,
        requestId: _nextRequestId(normalizedDoorId),
      );
      state = state.copyWith(
        devices: devices,
        isInitialLoading: false,
        isRefreshing: false,
        initialLoadFailed: false,
        hasMore: false,
      );
    } on AppError {
      state = state.copyWith(
        isInitialLoading: false,
        isRefreshing: false,
        initialLoadFailed: state.devices.isEmpty,
      );
    } catch (_) {
      state = state.copyWith(
        isInitialLoading: false,
        isRefreshing: false,
        initialLoadFailed: state.devices.isEmpty,
      );
    }
  }

  String _nextRequestId(String doorId) {
    _requestCounter += 1;
    return 'already-added-devices-$doorId-'
        '${DateTime.now().toUtc().microsecondsSinceEpoch}-$_requestCounter';
  }

  String _nextUnbindRequestId(String doorId, String deviceId) {
    _requestCounter += 1;
    return 'unbind-door-device-$doorId-$deviceId-'
        '${DateTime.now().toUtc().microsecondsSinceEpoch}-$_requestCounter';
  }

  void _notifyDeviceCommandDeviceListRefresh(String doorId) {
    ref
        .read(doorDevicesRefreshRequestProvider.notifier)
        .notify(
          DoorDevicesRefreshRequest(doorId: doorId, sequence: _requestCounter),
        );
  }
}
