import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../platform_bridge/hardware_models.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/design_system/door_type_visuals.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/providers.dart';
import '../widgets/add_door_name_dialog.dart';
import 'add_device_page.dart';

class AddNewDoorsPage extends ConsumerWidget {
  const AddNewDoorsPage({super.key});

  static const routeName = 'add-new-doors';
  static const routePath = '/add-new-doors';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final doorTypes = DoorType.values
        .map((type) => _DoorTypeOption(label: _labelForType(l10n, type), visual: DoorTypeVisuals.forType(type)))
        .toList(growable: false);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: FlinxNavigationBar(title: '', showBottomDivider: false, automaticallyImplyLeading: context.canPop()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 36, 18, 46),
        children: [
          Text(l10n.addNewDoorsTitle, style: AppTextTokens.addNewDoorsTitle(textTheme)),
          const SizedBox(height: 2),
          Text(l10n.addNewDoorsSubtitle, style: AppTextTokens.addNewDoorsSubtitle(textTheme)),
          const SizedBox(height: 46),
          for (final option in doorTypes) ...[
            _DoorTypeCard(
              option: option,
              // onPressed: () => showAddDoorNameDialog(
              //   context,
              //   onConfirmed: (draft) {
              //     ref
              //         .read(addDeviceControllerProvider.notifier)
              //         .setPendingDoorDraft(draft);
              //     context.push(AddDevicePage.routePath);
              //   },
              // ),
              onPressed: () => context.push(AddDevicePage.routePath),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  String _labelForType(AppLocalizations l10n, DoorType type) {
    return switch (type) {
      DoorType.garage => l10n.addNewDoorsGarageDoor,
      DoorType.roller => l10n.addNewDoorsRollerDoor,
      DoorType.industrial => l10n.addNewDoorsIndustrialDoor,
      DoorType.swing => l10n.addNewDoorsSwingGate,
      DoorType.sliding => l10n.addNewDoorsSlidingGate,
    };
  }
}

class _DoorTypeOption {
  const _DoorTypeOption({required this.label, required this.visual});

  final String label;
  final DoorTypeVisual visual;
}

class _DoorTypeCard extends StatelessWidget {
  const _DoorTypeCard({required this.option, required this.onPressed});

  final _DoorTypeOption option;
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
              _DoorTypeIcon(assetPath: option.visual.assetPath, fallbackIcon: option.visual.fallbackIcon),
              const SizedBox(width: 34),
              Expanded(child: Text(option.label, style: AppTextTokens.addNewDoorsCardTitle(Theme.of(context).textTheme))),
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
