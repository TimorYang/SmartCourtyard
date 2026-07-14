import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import 'add_device_page.dart';
import '../widgets/add_door_name_dialog.dart';

class AddNewDoorsAssetPaths {
  const AddNewDoorsAssetPaths._();

  static const garageDoor = 'assets/icons/add_device/add_new_doors_garage_door.png';
  static const rollerDoor = 'assets/icons/add_device/add_new_doors_roller_door.png';
  static const industrialDoor = 'assets/icons/add_device/add_new_doors_industrial_door.png';
  static const swingGate = 'assets/icons/add_device/add_new_doors_swing_gate.png';
  static const slidingGate = 'assets/icons/add_device/add_new_doors_sliding_gate.png';
}

class AddNewDoorsPage extends StatelessWidget {
  const AddNewDoorsPage({super.key});

  static const routeName = 'add-new-doors';
  static const routePath = '/add-new-doors';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final doorTypes = [
      _DoorTypeOption(label: l10n.addNewDoorsGarageDoor, assetPath: AddNewDoorsAssetPaths.garageDoor, fallbackIcon: Icons.garage_outlined),
      _DoorTypeOption(label: l10n.addNewDoorsRollerDoor, assetPath: AddNewDoorsAssetPaths.industrialDoor, fallbackIcon: Icons.window_outlined),
      _DoorTypeOption(label: l10n.addNewDoorsIndustrialDoor, assetPath: AddNewDoorsAssetPaths.rollerDoor, fallbackIcon: Icons.warehouse_outlined),
      _DoorTypeOption(label: l10n.addNewDoorsSwingGate, assetPath: AddNewDoorsAssetPaths.slidingGate, fallbackIcon: Icons.door_front_door_outlined),
      _DoorTypeOption(label: l10n.addNewDoorsSlidingGate, assetPath: AddNewDoorsAssetPaths.swingGate, fallbackIcon: Icons.door_sliding_outlined),
    ];

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
              // onPressed: () => showAddDoorNameDialog(context, onConfirmed: () => context.push(AddDevicePage.routePath)),
              onPressed: () => context.push(AddDevicePage.routePath),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _DoorTypeOption {
  const _DoorTypeOption({required this.label, required this.assetPath, required this.fallbackIcon});

  final String label;
  final String assetPath;
  final IconData fallbackIcon;
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
              _DoorTypeIcon(assetPath: option.assetPath, fallbackIcon: option.fallbackIcon),
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
