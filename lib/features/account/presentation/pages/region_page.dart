import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/region_selection_controller.dart';
import '../../domain/entities/region_option.dart';

class RegionPage extends ConsumerWidget {
  const RegionPage({super.key});

  static const routeName = 'region';
  static const routePath = '/account/region';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(regionSelectionControllerProvider);

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
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacingTokens.regionPageHorizontal,
                    AppSpacingTokens.regionPageTitleTop,
                    AppSpacingTokens.regionPageHorizontal,
                    0,
                  ),
                  child: Text(
                    l10n.regionPageTitle,
                    style: AppTextTokens.regionPageTitle(
                      Theme.of(context).textTheme,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacingTokens.regionPageTitleToList),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacingTokens.regionPageHorizontal,
                    ),
                    itemCount: state.regions.length,
                    itemBuilder: (context, index) {
                      final region = state.regions[index];
                      return _RegionRow(
                        option: region,
                        label: _localizedRegionName(l10n, region.code),
                        selected: state.selectedRegionCode == region.code,
                        onTap: () => ref
                            .read(regionSelectionControllerProvider.notifier)
                            .select(region.code),
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

  static ValueKey<String> option(String id) => ValueKey('region-option-$id');
}

String _localizedRegionName(AppLocalizations l10n, String regionCode) {
  return switch (regionCode) {
    'CN' => l10n.regionChina,
    'US' => l10n.regionAmerica,
    'GB' => l10n.regionEngland,
    'FR' => l10n.regionFrance,
    'CA' => l10n.regionCanada,
    _ => regionCode,
  };
}

class _RegionRow extends StatelessWidget {
  const _RegionRow({
    required this.option,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final RegionOption option;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        key: RegionPageKeys.option(option.code.toLowerCase()),
        onTap: onTap,
        child: Container(
          height: AppSpacingTokens.regionRowHeight,
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
