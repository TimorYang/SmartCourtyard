import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/providers.dart';
import '../../../device_control/presentation/pages/already_added_devices_page.dart';
import '../../../device_control/presentation/pages/device_command_page.dart';
import 'add_new_doors_page.dart';

class SmartOpenerConnectionSuccessPage extends ConsumerStatefulWidget {
  const SmartOpenerConnectionSuccessPage({super.key});

  static const routeName = 'smart-opener-connection-success';
  static const routePath = '/add-device/smart-opener/success';

  @override
  ConsumerState<SmartOpenerConnectionSuccessPage> createState() =>
      _SmartOpenerConnectionSuccessPageState();
}

class _SmartOpenerConnectionSuccessPageState
    extends ConsumerState<SmartOpenerConnectionSuccessPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(addDeviceControllerProvider.notifier).logSuccessPageEntered();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final addDeviceState = ref.watch(addDeviceControllerProvider);
    final onboardedDoor = addDeviceState.onboardedDoor;
    final deviceId = addDeviceState.selectedDevice?.id ?? '';

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: const FlinxNavigationBar(title: '', showBottomDivider: false),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final topGap = constraints.maxHeight < 760 ? 34.0 : 70.0;

          return SafeArea(
            top: false,
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, topGap, 20, 34),
              children: [
                const Center(child: _SuccessCheck()),
                const SizedBox(height: 20),
                Text(
                  l10n.smartOpenerConnectionSuccessTitle,
                  textAlign: TextAlign.center,
                  style: AppTextTokens.smartOpenerConnectingTitle(textTheme),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.smartOpenerConnectionSuccessDescription,
                  textAlign: TextAlign.center,
                  style: AppTextTokens.smartOpenerBodyCenter(textTheme),
                ),
                SizedBox(height: 80),
                Padding(
                  padding: EdgeInsetsGeometry.only(left: 10, right: 10),
                  child: _SuccessFormRow(
                    icon: Icons.door_front_door_outlined,
                    label: l10n.smartOpenerDeviceNamePlaceholder,
                  ),
                ),
                Padding(
                  padding: EdgeInsetsGeometry.only(left: 10, right: 10),
                  child: _SuccessFormRow(
                    icon: Icons.view_in_ar_outlined,
                    label: l10n.smartOpenerSelectScenePlaceholder,
                    trailing: Icons.chevron_right,
                  ),
                ),
                SizedBox(height: 80),
                Text(
                  l10n.smartOpenerInviteFamilyTip,
                  textAlign: TextAlign.center,
                  style: AppTextTokens.smartOpenerBodyCenter(textTheme),
                ),
                const SizedBox(height: 13),
                Padding(
                  padding: EdgeInsetsGeometry.only(left: 10, right: 10),
                  child: _SuccessActionButton(
                    label: l10n.smartOpenerShareAction,
                    isPrimary: false,
                    onPressed: () => _showShareDialog(context),
                  ),
                ),
                const SizedBox(height: 19),
                Padding(
                  padding: EdgeInsetsGeometry.only(left: 10, right: 10),
                  child: _SuccessActionButton(
                    label: l10n.smartOpenerTryAction,
                    onPressed: onboardedDoor == null
                        ? null
                        : () => _openDeviceCommand(
                            context,
                            doorId: onboardedDoor.id.toString(),
                            deviceId: deviceId,
                            onboardingFlowId:
                                addDeviceState.onboardingFlowId ?? '',
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openDeviceCommand(
    BuildContext context, {
    required String doorId,
    required String deviceId,
    required String onboardingFlowId,
  }) {
    ref.read(addDeviceControllerProvider.notifier).logDeviceDetailNavigation();

    final router = GoRouter.of(context);
    final navigator = Navigator.of(context);
    String? flowBoundaryRouteName;
    final location =
        '${DeviceCommandPage.routePath}'
        '?doorId=${Uri.encodeQueryComponent(doorId)}'
        '&deviceId=${Uri.encodeQueryComponent(deviceId)}'
        '&onboardingFlowId=${Uri.encodeQueryComponent(onboardingFlowId)}';

    navigator.popUntil((route) {
      final routeName = route.settings.name;
      if (routeName == AddNewDoorsPage.routeName ||
          routeName == AlreadyAddedDevicesPage.routeName) {
        flowBoundaryRouteName = routeName;
        return true;
      }
      return route.isFirst;
    });

    if (flowBoundaryRouteName == AlreadyAddedDevicesPage.routeName &&
        navigator.canPop()) {
      navigator.pop(deviceId);
      return;
    }

    router.pushReplacement(location);
  }

  Future<void> _showShareDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierColor: AppColors.overlayStrong,
      builder: (context) => const _ShareDeviceDialog(),
    );
  }
}

class _SuccessCheck extends StatelessWidget {
  const _SuccessCheck();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        color: AppColors.smartOpenerSuccess,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check, color: Colors.white, size: 40),
    );
  }
}

class _SuccessFormRow extends StatelessWidget {
  const _SuccessFormRow({
    required this.icon,
    required this.label,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: 66,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.smartOpenerDivider)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: AppColors.textIcon),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextTokens.smartOpenerFormText(textTheme),
            ),
          ),
          if (trailing != null)
            Icon(trailing, size: 24, color: AppColors.textPrimary),
        ],
      ),
    );
  }
}

class _SuccessActionButton extends StatelessWidget {
  const _SuccessActionButton({
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 50,
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

class _ShareDeviceDialog extends StatelessWidget {
  const _ShareDeviceDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: AppColors.backgroundPrimary,
      insetPadding: const EdgeInsets.symmetric(horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.smartOpenerShareDialogTitle,
                style: AppTextTokens.smartOpenerShareDialogTitle(textTheme),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.smartOpenerShareDialogDescription,
                style: AppTextTokens.smartOpenerShareDialogDescription(
                  textTheme,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 38,
                child: TextField(
                  keyboardType: TextInputType.emailAddress,
                  style: AppTextTokens.smartOpenerShareDialogAccountHint(
                    textTheme,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.smartOpenerShareDialogAccountHint,
                    hintStyle: AppTextTokens.smartOpenerShareDialogAccountHint(
                      textTheme,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(
                        color: AppColors.deviceShareFieldBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _ShareDialogActionButton(
                      label: l10n.smartOpenerCancelAction,
                      backgroundColor: AppColors.deviceShareCancelButton,
                      foregroundColor: AppColors.textPrimary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 30),
                  Expanded(
                    child: _ShareDialogActionButton(
                      label: l10n.smartOpenerConfirmAction,
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: Colors.white,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareDialogActionButton extends StatelessWidget {
  const _ShareDialogActionButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: const StadiumBorder(),
          textStyle: AppTextTokens.smartOpenerShareDialogAccountHint2(
            Theme.of(context).textTheme,
          ).copyWith(fontWeight: FontWeight.w500),
        ),
        child: Text(label),
      ),
    );
  }
}
