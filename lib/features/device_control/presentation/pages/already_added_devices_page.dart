import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/already_added_devices_controller.dart';
import '../../domain/entities/door_detail.dart';

class AlreadyAddedDevicesPage extends ConsumerStatefulWidget {
  const AlreadyAddedDevicesPage({
    required this.doorId,
    this.deviceId = '',
    super.key,
  });

  static const routeName = 'already-added-devices';
  static const routePath = '/device-control/already-added-devices';

  final String doorId;
  final String deviceId;

  static const _smartOpenerPlaceholderAsset =
      'assets/icons/device_control/device_command_opener_active.png';

  @override
  ConsumerState<AlreadyAddedDevicesPage> createState() =>
      _AlreadyAddedDevicesPageState();
}

class _AlreadyAddedDevicesPageState
    extends ConsumerState<AlreadyAddedDevicesPage> {
  static const _loadMoreThreshold = 160.0;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    Future<void>.microtask(_loadInitial);
  }

  @override
  void didUpdateWidget(covariant AlreadyAddedDevicesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.doorId != widget.doorId) {
      Future<void>.microtask(_loadInitial);
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _loadInitial() {
    ref
        .read(alreadyAddedDevicesControllerProvider.notifier)
        .loadInitial(doorId: widget.doorId);
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > _loadMoreThreshold) {
      return;
    }
    ref.read(alreadyAddedDevicesControllerProvider.notifier).loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(alreadyAddedDevicesControllerProvider);
    final controller = ref.read(alreadyAddedDevicesControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: FlinxNavigationBar(
        title: '',
        showBottomDivider: false,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            key: const ValueKey<String>('already-added-add-action'),
            tooltip: l10n.smartOpenerAddedAddTooltip,
            onPressed: () {},
            icon: const Icon(Icons.add, size: 26),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () => controller.refresh(doorId: widget.doorId),
          child: CustomScrollView(
            key: const PageStorageKey<String>('already-added-devices-scroll'),
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacingTokens.smartOpenerAddedPageHorizontal,
                  AppSpacingTokens.smartOpenerAddedPageTop,
                  AppSpacingTokens.smartOpenerAddedPageHorizontal,
                  24,
                ),
                sliver: SliverList.list(
                  children: [
                    Text(
                      l10n.smartOpenerAddedDevicesTitle,
                      style: AppTextTokens.smartOpenerAddedTitle(textTheme),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.smartOpenerAddedDevicesDescription,
                      style: AppTextTokens.smartOpenerAddedDescription(
                        textTheme,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              if (state.isInitialLoading)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Semantics(
                      label: l10n.smartOpenerAddedLoading,
                      child: const CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (state.initialLoadFailed)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _LoadFailure(
                    message: l10n.smartOpenerAddedLoadFailed,
                    retryLabel: l10n.smartOpenerAddedRetryAction,
                    onRetry: _loadInitial,
                  ),
                )
              else if (state.devices.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyDevices(
                    title: l10n.smartOpenerAddedEmptyTitle,
                    description: l10n.smartOpenerAddedEmptyDescription,
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacingTokens.smartOpenerAddedPageHorizontal,
                  ),
                  sliver: SliverList.separated(
                    itemCount: state.devices.length,
                    itemBuilder: (context, index) => _AddedDeviceCard(
                      device: state.devices[index],
                      smartOpenerName: l10n.smartOpenerAddedDeviceName,
                      deleteTooltip: l10n.smartOpenerAddedDeleteTooltip,
                    ),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        l10n.smartOpenerAddedNoMore,
                        style: AppTextTokens.smartOpenerAddedDeviceIdentifier(
                          textTheme,
                        ),
                      ),
                    ),
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

class _AddedDeviceCard extends StatelessWidget {
  const _AddedDeviceCard({
    required this.device,
    required this.smartOpenerName,
    required this.deleteTooltip,
  });

  final DoorAssociatedDevice device;
  final String smartOpenerName;
  final String deleteTooltip;

  String get _title {
    final label = device.deviceTypeLabel?.trim();
    if (label != null && label.isNotEmpty) {
      return label;
    }
    return device.deviceType.trim().toLowerCase() == 'opener'
        ? smartOpenerName
        : device.deviceType;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      key: ValueKey<String>('already-added-device-card-${device.bleName}'),
      constraints: const BoxConstraints(minHeight: 100),
      padding: const EdgeInsets.all(
        AppSpacingTokens.smartOpenerAddedCardPadding,
      ),
      decoration: const BoxDecoration(
        color: AppColors.smartOpenerAddedDeviceCardSurface,
        borderRadius: BorderRadius.all(
          Radius.circular(AppShapeTokens.smartOpenerAddedDeviceCardRadius),
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            AlreadyAddedDevicesPage._smartOpenerPlaceholderAsset,
            key: ValueKey<String>(
              'already-added-device-image-placeholder-${device.bleName}',
            ),
          ),
          const SizedBox(width: AppSpacingTokens.smartOpenerAddedCardGap),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextTokens.smartOpenerAddedDeviceTitle(textTheme),
                ),
                Text(
                  device.bleName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextTokens.smartOpenerAddedDeviceIdentifier(
                    textTheme,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: ValueKey<String>(
              'already-added-delete-action-${device.bleName}',
            ),
            tooltip: deleteTooltip,
            onPressed: () {},
            icon: const Icon(Icons.delete, size: 22),
          ),
        ],
      ),
    );
  }
}

class _EmptyDevices extends StatelessWidget {
  const _EmptyDevices({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: AppTextTokens.smartOpenerAddedDeviceTitle(textTheme),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: AppTextTokens.smartOpenerAddedDescription(textTheme),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    );
  }
}
