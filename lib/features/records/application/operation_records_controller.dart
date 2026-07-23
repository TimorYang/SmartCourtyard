import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/operation_record.dart';
import '../domain/use_cases/fetch_operation_records_use_case.dart';
import 'providers.dart';

class OperationRecordsState {
  const OperationRecordsState({
    this.records = const <OperationRecord>[],
    this.currentPage = 0,
    this.hasMore = true,
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.initialLoadFailed = false,
    this.loadMoreFailed = false,
  });

  final List<OperationRecord> records;
  final int currentPage;
  final bool hasMore;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool initialLoadFailed;
  final bool loadMoreFailed;

  OperationRecordsState copyWith({
    List<OperationRecord>? records,
    int? currentPage,
    bool? hasMore,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? initialLoadFailed,
    bool? loadMoreFailed,
  }) {
    return OperationRecordsState(
      records: records ?? this.records,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      initialLoadFailed: initialLoadFailed ?? this.initialLoadFailed,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    );
  }
}

class OperationRecordsController extends Notifier<OperationRecordsState> {
  static const pageSize = 20;

  late final FetchOperationRecordsUseCase _fetchOperationRecordsUseCase;
  int _requestCounter = 0;
  String? _doorId;

  @override
  OperationRecordsState build() {
    _fetchOperationRecordsUseCase = ref.watch(
      fetchOperationRecordsUseCaseProvider,
    );
    return const OperationRecordsState();
  }

  Future<void> loadInitial({required String doorId}) async {
    if (state.isInitialLoading || state.isRefreshing) return;
    final normalizedDoorId = doorId.trim();
    _doorId = normalizedDoorId;
    state = state.copyWith(isInitialLoading: true, initialLoadFailed: false);
    try {
      final result = await _fetchOperationRecordsUseCase(
        doorId: normalizedDoorId,
        page: 1,
        pageSize: pageSize,
        requestId: _nextRequestId(normalizedDoorId, 'initial'),
      );
      state = state.copyWith(
        records: result.records,
        currentPage: result.currentPage,
        hasMore: result.hasMore,
        isInitialLoading: false,
        initialLoadFailed: false,
      );
    } catch (_) {
      state = state.copyWith(isInitialLoading: false, initialLoadFailed: true);
    }
  }

  Future<void> refresh() async {
    if (state.isInitialLoading || state.isRefreshing) return;
    final doorId = _doorId;
    if (doorId == null) return;
    state = state.copyWith(isRefreshing: true, initialLoadFailed: false);
    try {
      final result = await _fetchOperationRecordsUseCase(
        doorId: doorId,
        page: 1,
        pageSize: pageSize,
        requestId: _nextRequestId(doorId, 'refresh'),
      );
      state = state.copyWith(
        records: result.records,
        currentPage: result.currentPage,
        hasMore: result.hasMore,
        isRefreshing: false,
        initialLoadFailed: false,
        loadMoreFailed: false,
      );
    } catch (_) {
      state = state.copyWith(
        isRefreshing: false,
        initialLoadFailed: state.records.isEmpty,
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isInitialLoading ||
        state.isRefreshing ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }
    final doorId = _doorId;
    if (doorId == null) return;
    state = state.copyWith(isLoadingMore: true, loadMoreFailed: false);
    try {
      final result = await _fetchOperationRecordsUseCase(
        doorId: doorId,
        page: state.currentPage + 1,
        pageSize: pageSize,
        requestId: _nextRequestId(doorId, 'more'),
      );
      state = state.copyWith(
        records: <OperationRecord>[...state.records, ...result.records],
        currentPage: result.currentPage,
        hasMore: result.hasMore,
        isLoadingMore: false,
        loadMoreFailed: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false, loadMoreFailed: true);
    }
  }

  String _nextRequestId(String doorId, String operation) {
    _requestCounter += 1;
    return 'operation-record-$operation-$doorId-'
        '${DateTime.now().toUtc().microsecondsSinceEpoch}-$_requestCounter';
  }
}
