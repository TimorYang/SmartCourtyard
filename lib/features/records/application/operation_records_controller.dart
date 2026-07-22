import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/operation_record.dart';
import '../domain/repositories/operation_record_repository.dart';
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

  late final OperationRecordRepository _repository;

  @override
  OperationRecordsState build() {
    _repository = ref.watch(operationRecordRepositoryProvider);
    Future<void>.microtask(loadInitial);
    return const OperationRecordsState();
  }

  Future<void> loadInitial() async {
    if (state.isInitialLoading || state.isRefreshing) return;
    state = state.copyWith(isInitialLoading: true, initialLoadFailed: false);
    try {
      final result = await _repository.fetchOperationRecords(
        page: 1,
        pageSize: pageSize,
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
    state = state.copyWith(isRefreshing: true, initialLoadFailed: false);
    try {
      final result = await _repository.fetchOperationRecords(
        page: 1,
        pageSize: pageSize,
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
    state = state.copyWith(isLoadingMore: true, loadMoreFailed: false);
    try {
      final result = await _repository.fetchOperationRecords(
        page: state.currentPage + 1,
        pageSize: pageSize,
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
}
