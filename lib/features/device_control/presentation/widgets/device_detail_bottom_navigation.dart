import 'package:flutter/material.dart';

import '../../../../app/theme/app_design_tokens.dart';

enum DeviceDetailTab { operationRecords, command, securityCenter }

class DeviceDetailBottomNavigation extends StatelessWidget {
  const DeviceDetailBottomNavigation({required this.selectedTab, required this.onSelected, super.key});

  final DeviceDetailTab selectedTab;
  final ValueChanged<DeviceDetailTab> onSelected;

  static const _operationRecordsSelectedIconAsset = 'assets/icons/device_control/device_detail_operation_records_tab_selected.png';
  static const _operationRecordsUnselectedIconAsset = 'assets/icons/device_control/device_detail_operation_records_tab_unselected.png';
  static const _commandSelectedIconAsset = 'assets/icons/device_control/device_detail_command_tab_selected.png';
  static const _commandUnselectedIconAsset = 'assets/icons/device_control/device_detail_command_tab_unselected.png';
  static const _securityCenterSelectedIconAsset = 'assets/icons/device_control/device_detail_security_center_tab_selected.png';
  static const _securityCenterUnselectedIconAsset = 'assets/icons/device_control/device_detail_security_center_tab_unselected.png';

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.deviceDetailNavigationBackground,
        border: Border(top: BorderSide(color: AppColors.deviceDetailNavigationDivider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 65,
          child: Row(
            children: [
              _NavigationItem(
                tooltip: 'Operation records',
                selectedIconAsset: _operationRecordsSelectedIconAsset,
                unselectedIconAsset: _operationRecordsUnselectedIconAsset,
                selected: selectedTab == DeviceDetailTab.operationRecords,
                onTap: () => onSelected(DeviceDetailTab.operationRecords),
              ),
              _NavigationItem(
                tooltip: 'Device command',
                selectedIconAsset: _commandSelectedIconAsset,
                unselectedIconAsset: _commandUnselectedIconAsset,
                selected: selectedTab == DeviceDetailTab.command,
                onTap: () => onSelected(DeviceDetailTab.command),
              ),
              _NavigationItem(
                tooltip: 'Security center',
                selectedIconAsset: _securityCenterSelectedIconAsset,
                unselectedIconAsset: _securityCenterUnselectedIconAsset,
                selected: selectedTab == DeviceDetailTab.securityCenter,
                onTap: () => onSelected(DeviceDetailTab.securityCenter),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.tooltip,
    required this.selectedIconAsset,
    required this.unselectedIconAsset,
    required this.selected,
    required this.onTap,
  });

  final String tooltip;
  final String selectedIconAsset;
  final String unselectedIconAsset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: Tooltip(
          message: tooltip,
          child: InkWell(
            onTap: onTap,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  selected ? selectedIconAsset : unselectedIconAsset,
                  width: 50,
                  height: 50,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.square(dimension: 50),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
