import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../../account/presentation/widgets/account_avatar_code_assets.dart';
import '../../../device_control/presentation/widgets/device_detail_bottom_navigation.dart';
import '../../../home/application/providers.dart';
import '../../application/operation_records_controller.dart';
import '../../application/providers.dart';
import '../../domain/entities/operation_record.dart';

class OperationRecordPage extends ConsumerStatefulWidget {
  const OperationRecordPage({
    required this.doorId,
    required this.onTabSelected,
    this.isActive = true,
    super.key,
  });

  final String doorId;
  final ValueChanged<DeviceDetailTab> onTabSelected;
  final bool isActive;

  @override
  ConsumerState<OperationRecordPage> createState() =>
      _OperationRecordPageState();
}

class _OperationRecordPageState extends ConsumerState<OperationRecordPage> {
  @override
  void initState() {
    super.initState();
    if (widget.isActive) _loadInitial();
  }

  @override
  void didUpdateWidget(covariant OperationRecordPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.doorId != widget.doorId && widget.isActive) ||
        (!oldWidget.isActive && widget.isActive)) {
      _loadInitial();
    }
  }

  void _loadInitial() {
    Future<void>.microtask(
      () => ref
          .read(operationRecordsControllerProvider.notifier)
          .loadInitial(doorId: widget.doorId),
    );
  }

  Future<IndicatorResult> _loadMore() async {
    final controller = ref.read(operationRecordsControllerProvider.notifier);
    await controller.loadMore();
    final state = ref.read(operationRecordsControllerProvider);
    if (state.loadMoreFailed) return IndicatorResult.fail;
    return state.hasMore ? IndicatorResult.success : IndicatorResult.noMore;
  }

  ClassicHeader _classicHeader(AppLocalizations l10n) {
    return ClassicHeader(
      dragText: l10n.refreshControlPullToRefresh,
      armedText: l10n.refreshControlReleaseToRefresh,
      readyText: l10n.refreshControlRefreshing,
      processingText: l10n.refreshControlRefreshing,
      processedText: l10n.refreshControlRefreshSucceeded,
      failedText: l10n.refreshControlRefreshFailed,
      showMessage: false,
    );
  }

  ClassicFooter _classicFooter(AppLocalizations l10n) {
    return ClassicFooter(
      dragText: l10n.refreshControlPullToLoad,
      armedText: l10n.refreshControlReleaseToLoad,
      readyText: l10n.refreshControlLoading,
      processingText: l10n.refreshControlLoading,
      processedText: l10n.refreshControlLoadSucceeded,
      failedText: l10n.refreshControlLoadFailed,
      noMoreText: l10n.refreshControlNoMoreData,
      showMessage: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final recordsState = ref.watch(operationRecordsControllerProvider);
    final controller = ref.read(operationRecordsControllerProvider.notifier);

    return Scaffold(
      appBar: const FlinxNavigationBar(title: '', showBottomDivider: false),
      bottomNavigationBar: DeviceDetailBottomNavigation(
        selectedTab: DeviceDetailTab.operationRecords,
        onSelected: widget.onTabSelected,
      ),
      body: SafeArea(
        top: false,
        child: EasyRefresh.builder(
          header: _classicHeader(l10n),
          footer: _classicFooter(l10n),
          onRefresh: controller.refresh,
          onLoad: _loadMore,
          childBuilder: (context, physics) => CustomScrollView(
            key: const PageStorageKey<String>('operation-record-scroll'),
            physics: physics,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                sliver: SliverList.list(
                  children: [
                    Text(
                      l10n.operationRecordTitle,
                      style: AppTextTokens.operationRecordTitle(textTheme),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.operationRecordLast14DaysDescription,
                      style: AppTextTokens.operationRecordSubtitle(textTheme),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
              if (recordsState.isInitialLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (recordsState.initialLoadFailed)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _InitialLoadFailure(
                    onRetry: () =>
                        controller.loadInitial(doorId: widget.doorId),
                  ),
                )
              else if (recordsState.records.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      l10n.operationRecordEmpty,
                      style: AppTextTokens.operationRecordMeta(textTheme),
                    ),
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.builder(
                    itemCount: recordsState.records.length,
                    itemBuilder: (context, index) {
                      return _OperationTimelineItem(
                        record: recordsState.records[index],
                        isLast:
                            index == recordsState.records.length - 1 &&
                            !recordsState.hasMore &&
                            !recordsState.isLoadingMore &&
                            !recordsState.loadMoreFailed,
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: _LoadMoreFooter(
                    state: recordsState,
                    onRetry: controller.loadMore,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InitialLoadFailure extends StatelessWidget {
  const _InitialLoadFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: TextButton(
        onPressed: onRetry,
        child: Text(l10n.operationRecordLoadFailed),
      ),
    );
  }
}

class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({required this.state, required this.onRetry});

  final OperationRecordsState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (state.records.isEmpty) return const SizedBox(height: 20);
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.loadMoreFailed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: TextButton(
            onPressed: onRetry,
            child: Text(l10n.operationRecordLoadMoreFailed),
          ),
        ),
      );
    }
    if (!state.hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            l10n.operationRecordNoMore,
            style: AppTextTokens.operationRecordMeta(
              Theme.of(context).textTheme,
            ),
          ),
        ),
      );
    }
    return const SizedBox(height: 20);
  }
}

class _OperationTimelineItem extends ConsumerWidget {
  const _OperationTimelineItem({required this.record, required this.isLast});

  static const _avatarPlaceholderAsset =
      'assets/images/records/operation_record_avatar_placeholder.png';

  final OperationRecord record;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              const SizedBox(height: 5),
              const DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.operationRecordTimeline,
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(dimension: 12),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1,
                    color: AppColors.operationRecordTimelineLine,
                  ),
                ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          record.action.label(l10n),
                          style: AppTextTokens.operationRecordAction(textTheme),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatOccurredAt(record.occurredAt, l10n),
                        style: AppTextTokens.operationRecordTime(textTheme),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _displayDoorName(
                      record.doorName,
                      record.operationMethodLabel,
                      l10n,
                    ),
                    style: AppTextTokens.operationRecordMeta(textTheme),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      CircleAvatar(
                        key: const ValueKey<String>('operation-record-avatar'),
                        radius: 10,
                        backgroundColor: AppColors.operationRecordAvatarSurface,
                        backgroundImage: _avatarImage(ref),
                        onBackgroundImageError: (_, _) {},
                      ),
                      const SizedBox(width: 11.5),
                      Expanded(
                        child: Text(
                          record.operatorDisplayName ??
                              l10n.operationRecordUnknownOperator,
                          style: AppTextTokens.operationRecordMeta(textTheme),
                        ),
                      ),
                    ],
                  ),
                  if (!isLast) ...[
                    const SizedBox(height: 16),
                    const Divider(
                      key: ValueKey<String>('operation-record-divider'),
                      height: 1,
                      thickness: 1,
                      color: AppColors.operationRecordDivider,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider<Object> _avatarImage(WidgetRef ref) {
    final avatarCode = record.operatorAvatarCode;
    if (avatarCode != null) {
      return AssetImage(avatarCode.assetPath);
    }
    final avatarImage = ref.watch(
      homeDoorCoverImageSourceProvider(record.operatorAvatarFileId),
    );
    if (avatarImage != null) {
      return NetworkImage(avatarImage.url, headers: avatarImage.headers);
    }
    return const AssetImage(_avatarPlaceholderAsset);
  }
}

String _formatOccurredAt(DateTime? occurredAt, AppLocalizations l10n) {
  if (occurredAt == null) return l10n.operationRecordUnknownTime;
  return DateFormat('yyyy-MM-dd HH:mm:ss').format(occurredAt);
}

String _displayDoorName(
  String? doorName,
  String? operationMethodLabel,
  AppLocalizations l10n,
) {
  final parts = <String>[
    if (doorName?.trim().isNotEmpty ?? false) doorName!.trim(),
    if (operationMethodLabel?.trim().isNotEmpty ?? false)
      operationMethodLabel!.trim(),
  ];
  return parts.isEmpty ? l10n.operationRecordUnknownDoor : parts.join(' / ');
}

extension on OperationRecordAction {
  String label(AppLocalizations l10n) => switch (this) {
    OperationRecordAction.open => l10n.operationRecordActionOpen,
    OperationRecordAction.close => l10n.operationRecordActionClose,
    OperationRecordAction.stop => l10n.operationRecordActionStop,
    OperationRecordAction.ledOn => l10n.operationRecordActionLedOn,
    OperationRecordAction.ledOff => l10n.operationRecordActionLedOff,
    OperationRecordAction.unknown => l10n.operationRecordActionUnknown,
  };
}
