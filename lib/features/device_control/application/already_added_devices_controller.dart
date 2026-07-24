import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../domain/entities/door_detail.dart';
import '../domain/use_cases/fetch_door_detail_use_case.dart';
import 'device_command_controller.dart';

final alreadyAddedDevicesControllerProvider =
    NotifierProvider<AlreadyAddedDevicesController, AlreadyAddedDevicesState>(
      AlreadyAddedDevicesController.new,
    );

class AlreadyAddedDevicesState {
  const AlreadyAddedDevicesState({
    this.devices = const <DoorAssociatedDevice>[],
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.initialLoadFailed = false,
    this.hasMore = true,
  });

  final List<DoorAssociatedDevice> devices;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool initialLoadFailed;
  final bool hasMore;

  AlreadyAddedDevicesState copyWith({
    List<DoorAssociatedDevice>? devices,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? initialLoadFailed,
    bool? hasMore,
  }) {
    return AlreadyAddedDevicesState(
      devices: devices ?? this.devices,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      initialLoadFailed: initialLoadFailed ?? this.initialLoadFailed,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class AlreadyAddedDevicesController extends Notifier<AlreadyAddedDevicesState> {
  late final FetchDoorDetailUseCase _fetchDoorDetailUseCase;
  var _requestCounter = 0;

  @override
  AlreadyAddedDevicesState build() {
    _fetchDoorDetailUseCase = ref.watch(fetchDoorDetailUseCaseProvider);
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
    // Door detail returns the complete associated-device collection.
    if (!state.hasMore || state.isInitialLoading || state.isRefreshing) {
      return;
    }
    state = state.copyWith(hasMore: false);
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
      await _fetchDoorDetailUseCase(
        doorId: normalizedDoorId,
        requestId: _nextRequestId(normalizedDoorId),
      );
      state = state.copyWith(
        // The door-detail endpoint no longer includes associated devices.
        devices: const <DoorAssociatedDevice>[],
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
}
