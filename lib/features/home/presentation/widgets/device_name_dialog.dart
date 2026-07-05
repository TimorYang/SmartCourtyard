import 'package:flutter/material.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';

class DeviceNameDialogAssetPaths {
  const DeviceNameDialogAssetPaths._();

  static const nameInputPlaceholder =
      'assets/icons/home/device_name_input_placeholder.png';
}

Future<void> showDeviceNameDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: AppColors.overlaySoft,
    builder: (context) => const DeviceNameDialog(),
  );
}

class DeviceNameDialog extends StatefulWidget {
  const DeviceNameDialog({super.key});

  @override
  State<DeviceNameDialog> createState() => _DeviceNameDialogState();
}

class _DeviceNameDialogState extends State<DeviceNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: viewInsets + const EdgeInsets.symmetric(horizontal: 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Material(
            color: AppColors.backgroundPrimary,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 30, 28, 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.deviceNameDialogTitle,
                    style: AppTextTokens.sceneDialogTitle(textTheme),
                  ),
                  const SizedBox(height: 16),
                  _DeviceNameTextField(controller: _controller),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: () => Navigator.pop(context),
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  AppColors.sceneDialogCancelButton,
                              foregroundColor: AppColors.textPrimary,
                              shape: const StadiumBorder(),
                              textStyle: AppTextTokens.sceneDialogButton(
                                textTheme,
                              ),
                            ),
                            child: Text(l10n.sceneNameCancelAction),
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: () => Navigator.pop(context),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.brandPrimary,
                              foregroundColor: AppColors.backgroundPrimary,
                              shape: const StadiumBorder(),
                              textStyle: AppTextTokens.sceneDialogButton(
                                textTheme,
                              ),
                            ),
                            child: Text(l10n.sceneNameConfirmAction),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeviceNameTextField extends StatelessWidget {
  const _DeviceNameTextField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.sceneDialogInputBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const _DeviceNameInputIcon(),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              style: AppTextTokens.sceneDialogInput(textTheme),
              decoration: InputDecoration.collapsed(
                hintText: l10n.deviceNameInputPlaceholder,
                hintStyle: AppTextTokens.sceneDialogInputHint(textTheme),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceNameInputIcon extends StatelessWidget {
  const _DeviceNameInputIcon();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      DeviceNameDialogAssetPaths.nameInputPlaceholder,
      width: 15,
      height: 15,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(
          Icons.dns_outlined,
          color: AppColors.textHint,
          size: 15,
        );
      },
    );
  }
}
