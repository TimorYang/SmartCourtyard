import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/region_selection_controller.dart';
import '../../domain/entities/region_option.dart';

class RegionPage extends ConsumerStatefulWidget {
  const RegionPage({super.key});

  static const routeName = 'region';
  static const routePath = '/account/region';

  @override
  ConsumerState<RegionPage> createState() => _RegionPageState();
}

class _RegionPageState extends ConsumerState<RegionPage> {
  static const _regionRowExtent = 60.0;

  final ScrollController _scrollController = ScrollController();
  bool _hasScheduledInitialScroll = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleInitialScroll(RegionSelectionState state) {
    if (_hasScheduledInitialScroll) {
      return;
    }

    final selectedRegionCode = state.selectedRegionCode;
    if (selectedRegionCode == null ||
        !state.regions.any((region) => region.code == selectedRegionCode)) {
      return;
    }

    _hasScheduledInitialScroll = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      final currentState = ref
          .read(regionSelectionControllerProvider)
          .maybeWhen(data: (value) => value, orElse: () => null);
      final currentSelectedRegionCode = currentState?.selectedRegionCode;
      final selectedIndex =
          currentState == null || currentSelectedRegionCode == null
          ? -1
          : currentState.regions.indexWhere(
              (region) => region.code == currentSelectedRegionCode,
            );
      if (selectedIndex < 0) {
        return;
      }

      final position = _scrollController.position;
      final targetOffset =
          (selectedIndex * _regionRowExtent -
                  (position.viewportDimension - _regionRowExtent) / 2)
              .clamp(0.0, position.maxScrollExtent)
              .toDouble();
      if ((position.pixels - targetOffset).abs() < 0.5) {
        return;
      }

      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final regionState = ref.watch(regionSelectionControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: const FlinxNavigationBar(title: '', showBottomDivider: false),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 26, 32, 0),
                  child: Text(
                    l10n.regionPageTitle,
                    style: AppTextTokens.regionPageTitle(
                      Theme.of(context).textTheme,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: regionState.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => Center(
                      child: FilledButton(
                        onPressed: () =>
                            ref.invalidate(regionSelectionControllerProvider),
                        child: Text(l10n.regionOptionsRetryAction),
                      ),
                    ),
                    data: (state) {
                      _scheduleInitialScroll(state);
                      return Stack(
                        children: [
                          ListView.builder(
                            key: RegionPageKeys.optionsList,
                            controller: _scrollController,
                            itemExtent: _regionRowExtent,
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            itemCount: state.regions.length,
                            itemBuilder: (context, index) {
                              final region = state.regions[index];
                              return _RegionRow(
                                option: region,
                                label: region.displayName,
                                selected:
                                    state.selectedRegionCode == region.code,
                                isEnabled: !state.isSaving,
                                onTap: () async {
                                  final saved = await ref
                                      .read(
                                        regionSelectionControllerProvider
                                            .notifier,
                                      )
                                      .select(region.code);
                                  if (!saved && context.mounted) {
                                    AppToast.error(
                                      context,
                                      l10n.regionOptionsSaveFailed,
                                    );
                                  }
                                },
                              );
                            },
                          ),
                          if (state.isSaving)
                            const Positioned.fill(
                              child: AbsorbPointer(
                                child: Center(
                                  child: CircularProgressIndicator(
                                    key: RegionPageKeys.savingIndicator,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RegionPageKeys {
  const RegionPageKeys._();

  static const optionsList = ValueKey('region-options-list');
  static const savingIndicator = ValueKey('region-saving-indicator');

  static ValueKey<String> option(String id) => ValueKey('region-option-$id');
}

class _RegionRow extends StatelessWidget {
  const _RegionRow({
    required this.option,
    required this.label,
    required this.selected,
    required this.isEnabled,
    required this.onTap,
  });

  final RegionOption option;
  final String label;
  final bool selected;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        key: RegionPageKeys.option(option.code.toLowerCase()),
        onTap: isEnabled ? onTap : null,
        child: Container(
          height: 60,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.borderRegionDivider),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextTokens.regionRowLabel(
                    Theme.of(context).textTheme,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_rounded,
                  color: AppColors.regionSelection,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
