import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../platform_bridge/hardware_models.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/providers.dart';
import 'smart_opener_connecting_page.dart';

class SmartOpenerChooseWifiPage extends ConsumerStatefulWidget {
  const SmartOpenerChooseWifiPage({super.key});

  static const routeName = 'smart-opener-choose-wifi';
  static const routePath = '/add-device/smart-opener/choose-wifi';

  @override
  ConsumerState<SmartOpenerChooseWifiPage> createState() =>
      _SmartOpenerChooseWifiPageState();
}

class _SmartOpenerChooseWifiPageState
    extends ConsumerState<SmartOpenerChooseWifiPage> {
  final TextEditingController _passwordController = TextEditingController();
  var _wifiSheetShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_scanWifi());
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _scanWifi() async {
    final controller = ref.read(addDeviceControllerProvider.notifier);
    final networks = await controller.scanWifiNetworks();
    if (!mounted || networks.isEmpty || _wifiSheetShown) {
      return;
    }
    _wifiSheetShown = true;
    await _showWifiSheet(networks);
  }

  Future<void> _showWifiSheet(List<WifiNetwork> networks) async {
    final selectedSsid = ref.read(addDeviceControllerProvider).wifiSsid;
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.overlaySoft,
      builder: (context) =>
          _WifiNetworkSheet(networks: networks, selectedSsid: selectedSsid),
    );
    if (!mounted || selected == null) {
      return;
    }
    ref.read(addDeviceControllerProvider.notifier).selectWifiNetwork(selected);
  }

  void _goConnecting({required bool skipWifi}) {
    ref
        .read(addDeviceControllerProvider.notifier)
        .updateWifiPassword(_passwordController.text);
    context.push(
      '${SmartOpenerConnectingPage.routePath}?skipWifi=${skipWifi ? 'true' : 'false'}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(addDeviceControllerProvider);
    final networks = state.wifiNetworks;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: const FlinxNavigationBar(title: '', showBottomDivider: false),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final afterHintGap = constraints.maxHeight < 760 ? 72.0 : 170.0;

              return SafeArea(
                top: false,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(43, 42, 43, 36),
                  children: [
                    Text(
                      l10n.smartOpenerChooseWifiTitle,
                      style: AppTextTokens.smartOpenerFlowTitle(textTheme),
                    ),
                    const SizedBox(height: 17),
                    Text(
                      l10n.smartOpenerChooseWifiDescription,
                      style: AppTextTokens.smartOpenerFlowSubtitle(textTheme),
                    ),
                    const SizedBox(height: 79),
                    _WifiFormRow(
                      icon: Icons.wifi,
                      text: state.wifiSsid.isEmpty
                          ? l10n.smartOpenerSelectWifiPlaceholder
                          : state.wifiSsid,
                      trailing: Icons.chevron_right,
                      onTap: () => _showWifiSheet(networks),
                    ),
                    _PasswordRow(controller: _passwordController),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.only(left: 20, right: 10),
                      child: Text(
                        l10n.smartOpenerWifiPasswordHint,
                        style: AppTextTokens.smartOpenerFormHint(textTheme),
                      ),
                    ),
                    SizedBox(height: afterHintGap),
                    Text(
                      l10n.smartOpenerEnableBluetoothTip,
                      textAlign: TextAlign.center,
                      style: AppTextTokens.smartOpenerBodyCenter(textTheme),
                    ),
                    const SizedBox(height: 22),
                    _WideActionButton(
                      label: l10n.smartOpenerNextAction,
                      onPressed: () => _goConnecting(skipWifi: false),
                    ),
                    const SizedBox(height: 23),
                    _WideActionButton(
                      label: l10n.smartOpenerSkipAction,
                      isPrimary: false,
                      onPressed: () => _goConnecting(skipWifi: true),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      l10n.smartOpenerSkipTip,
                      textAlign: TextAlign.center,
                      style: AppTextTokens.smartOpenerBodyCenter(textTheme),
                    ),
                  ],
                ),
              );
            },
          ),
          if (state.isScanningWifi)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x33FFFFFF),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class _WifiFormRow extends StatelessWidget {
  const _WifiFormRow({
    required this.icon,
    required this.text,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final IconData trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 72,
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.smartOpenerDivider),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 30, color: AppColors.textIcon),
            const SizedBox(width: 21),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextTokens.smartOpenerFormText(textTheme),
              ),
            ),
            Icon(trailing, size: 34, color: AppColors.textPrimary),
          ],
        ),
      ),
    );
  }
}

class _PasswordRow extends StatelessWidget {
  const _PasswordRow({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: 72,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.smartOpenerDivider)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 30, color: AppColors.textIcon),
          const SizedBox(width: 21),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: l10n.smartOpenerWifiPasswordPlaceholder,
                hintStyle: AppTextTokens.smartOpenerFormText(textTheme),
              ),
              style: AppTextTokens.smartOpenerFormText(textTheme),
            ),
          ),
          const Icon(
            Icons.visibility_off_outlined,
            size: 30,
            color: AppColors.textIcon,
          ),
        ],
      ),
    );
  }
}

class _WifiNetworkSheet extends StatelessWidget {
  const _WifiNetworkSheet({required this.networks, required this.selectedSsid});

  final List<WifiNetwork> networks;
  final String selectedSsid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(38, 29, 38, 28),
        decoration: const BoxDecoration(
          color: AppColors.backgroundPrimary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.smartOpenerSelectWifiTitle,
              style: AppTextTokens.smartOpenerSheetTitle(textTheme),
            ),
            const SizedBox(height: 21),
            for (final network in networks)
              _WifiNetworkTile(
                network: network,
                isSelected: network.ssid == selectedSsid,
              ),
          ],
        ),
      ),
    );
  }
}

class _WifiNetworkTile extends StatelessWidget {
  const _WifiNetworkTile({required this.network, required this.isSelected});

  final WifiNetwork network;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(network.ssid),
      child: Container(
        height: 69,
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.smartOpenerDivider),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.wifi,
              size: 29,
              color: isSelected ? AppColors.brandPrimary : AppColors.textIcon,
            ),
            const SizedBox(width: 22),
            Expanded(
              child: Text(
                network.ssid,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextTokens.smartOpenerFormText(textTheme).copyWith(
                  color: isSelected
                      ? AppColors.brandPrimary
                      : AppColors.textMuted,
                  fontSize: 19,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 34,
              color: AppColors.textPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

class _WideActionButton extends StatelessWidget {
  const _WideActionButton({
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 68,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: isPrimary
              ? AppColors.brandPrimary
              : AppColors.smartOpenerSecondaryButton,
          foregroundColor: isPrimary ? Colors.white : AppColors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(34),
          ),
        ),
        child: Text(
          label,
          style: isPrimary
              ? AppTextTokens.smartOpenerActionButton(textTheme)
              : AppTextTokens.smartOpenerSecondaryActionButton(textTheme),
        ),
      ),
    );
  }
}
