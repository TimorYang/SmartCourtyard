import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../../device_control/presentation/widgets/device_detail_bottom_navigation.dart';
import '../../application/operation_records_controller.dart';
import '../../application/providers.dart';
import '../../domain/entities/operation_record.dart';

class OperationRecordPage extends ConsumerStatefulWidget {
  const OperationRecordPage({required this.onTabSelected, super.key});

  final ValueChanged<DeviceDetailTab> onTabSelected;

  @override
  ConsumerState<OperationRecordPage> createState() =>
      _OperationRecordPageState();
}

class _OperationRecordPageState extends ConsumerState<OperationRecordPage> {
  static const _loadMoreThreshold = 200.0;

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > _loadMoreThreshold) {
      return;
    }
    ref.read(operationRecordsControllerProvider.notifier).loadMore();
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
        child: RefreshIndicator(
          onRefresh: controller.refresh,
          child: CustomScrollView(
            key: const PageStorageKey<String>('operation-record-scroll'),
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
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
                  child: _InitialLoadFailure(onRetry: controller.loadInitial),
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

class _OperationTimelineItem extends StatelessWidget {
  const _OperationTimelineItem({required this.record, required this.isLast});

  static const _avatarPlaceholderAsset =
      'assets/images/records/operation_record_avatar_placeholder.png';

  final OperationRecord record;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
                          record.operationName,
                          style: AppTextTokens.operationRecordAction(textTheme),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        record.operationTimeText,
                        style: AppTextTokens.operationRecordTime(textTheme),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    record.deviceName,
                    style: AppTextTokens.operationRecordMeta(textTheme),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      CircleAvatar(
                        key: const ValueKey<String>('operation-record-avatar'),
                        radius: 10,
                        backgroundColor: AppColors.operationRecordAvatarSurface,
                        backgroundImage: _avatarImage(record.operatorAvatarUrl),
                        onBackgroundImageError: (_, _) {},
                      ),
                      const SizedBox(width: 11.5),
                      Expanded(
                        child: Text(
                          record.operatorEmail,
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

  ImageProvider<Object> _avatarImage(String avatarUrl) {
    if (avatarUrl.isEmpty) return const AssetImage(_avatarPlaceholderAsset);
    return NetworkImage(avatarUrl);
  }
}
