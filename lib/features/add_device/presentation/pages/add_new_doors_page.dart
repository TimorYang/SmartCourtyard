import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/design_system/door_type_option.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import 'add_device_page.dart';

class AddNewDoorsPage extends ConsumerWidget {
  const AddNewDoorsPage({super.key});

  static const routeName = 'add-new-doors';
  static const routePath = '/add-new-doors';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final doorTypes = DoorTypeOption.values;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: FlinxNavigationBar(
        title: '',
        showBottomDivider: false,
        automaticallyImplyLeading: context.canPop(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 36, 18, 46),
        children: [
          Text(
            l10n.addNewDoorsTitle,
            style: AppTextTokens.addNewDoorsTitle(textTheme),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.addNewDoorsSubtitle,
            style: AppTextTokens.addNewDoorsSubtitle(textTheme),
          ),
          const SizedBox(height: 46),
          for (final option in doorTypes) ...[
            _DoorTypeCard(
              option: option,
              onPressed: () => context.pushNamed(
                AddDevicePage.routeName,
                queryParameters: {
                  AddDevicePage.doorTypeQueryParameter: option
                      .doorType
                      .wireValue
                      .toString(),
                },
              ),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _DoorTypeCard extends StatelessWidget {
  const _DoorTypeCard({required this.option, required this.onPressed});

  final DoorTypeOption option;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceItemSceneCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: SizedBox(
          height: 96,
          child: Row(
            children: [
              const SizedBox(width: 30),
              _DoorTypeIcon(
                assetPath: option.assetPath,
                fallbackIcon: option.fallbackIcon,
              ),
              const SizedBox(width: 34),
              Expanded(
                child: Text(
                  option.localizedName(AppLocalizations.of(context)),
                  style: AppTextTokens.addNewDoorsCardTitle(
                    Theme.of(context).textTheme,
                  ),
                ),
              ),
              const SizedBox(width: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoorTypeIcon extends StatelessWidget {
  const _DoorTypeIcon({required this.assetPath, required this.fallbackIcon});

  final String assetPath;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: 72,
      height: 72,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(fallbackIcon, color: AppColors.iconHomeAction, size: 64);
      },
    );
  }
}
