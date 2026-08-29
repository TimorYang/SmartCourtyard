import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../domain/entities/transmitter.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import 'transmitter_learning_page.dart';

class TransmitterListAssetPaths {
  const TransmitterListAssetPaths._();

  static const editActionPlaceholder =
      'assets/icons/device_settings/transmitter_edit_action_placeholder.png';
  static const deleteActionPlaceholder =
      'assets/icons/device_settings/transmitter_delete_action_placeholder.png';
  static const addActionPlaceholder =
      'assets/icons/device_settings/transmitter_add_action_placeholder.png';
}

class TransmitterListPage extends StatefulWidget {
  const TransmitterListPage({required this.deviceId, super.key});

  static const routeName = 'transmitter-list';
  static const routePath = '/device-settings/transmitters/list';

  final String deviceId;

  @override
  State<TransmitterListPage> createState() => _TransmitterListPageState();
}

class _TransmitterListPageState extends State<TransmitterListPage> {
  final _transmitters = [
    const Transmitter(id: 'mock-transmitter-1', name: 'Warehouse-01-Daniel'),
    const Transmitter(id: 'mock-transmitter-2', name: 'Warehouse-02-Danyl'),
    const Transmitter(id: 'mock-transmitter-3', name: 'Warehouse-03-Turk'),
    const Transmitter(id: 'mock-transmitter-4', name: 'Workshop-03-Airly'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const FlinxNavigationBar(title: '', showBottomDivider: false),
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.deviceSettingsManagement,
                    style: AppTextTokens.transmitterManagementTitle(textTheme),
                  ),
                  const SizedBox(height: 48),
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: _transmitters.length,
                      separatorBuilder: (_, _) => const Divider(
                        height: 1,
                        color: AppColors.deviceSettingsDivider,
                      ),
                      itemBuilder: (context, index) => _TransmitterListRow(
                        transmitter: _transmitters[index],
                        editSemanticLabel: l10n.transmitterManagementEditAction,
                        deleteSemanticLabel:
                            l10n.transmitterManagementDeleteAction,
                        onEdit: () => _edit(index),
                        onDelete: () => _delete(index),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.transmitterManagementTipsTitle,
                    style: AppTextTokens.transmitterManagementTipsTitle(
                      textTheme,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${l10n.transmitterManagementSafetyTip}\n'
                    '${l10n.transmitterManagementHowToTip}',
                    style: AppTextTokens.transmitterManagementTipsBody(
                      textTheme,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: _TransmitterAddButton(
                      semanticLabel: l10n.transmitterManagementAddAction,
                      onPressed: _startLearning,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _startLearning() {
    context.push(
      '${TransmitterLearningPage.routePath}?deviceId=${Uri.encodeComponent(widget.deviceId)}',
    );
  }

  Future<void> _edit(int? index) async {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    await showDialog<void>(
      context: context,
      barrierColor: AppColors.overlaySoft,
      builder: (dialogContext) => _TransmitterNameDialog(
        initialName: index == null ? '' : _transmitters[index].name,
        title: l10n.transmitterManagementInfoTitle,
        nameHint: l10n.transmitterManagementNameHint,
        cancelLabel: l10n.deviceSettingsCancelAction,
        confirmLabel: l10n.deviceSettingsConfirmAction,
        textTheme: textTheme,
        onConfirm: (name) {
          setState(() {
            if (index == null) {
              _transmitters.add(
                Transmitter(
                  id: 'mock-transmitter-${_transmitters.length + 1}',
                  name: name,
                ),
              );
            } else {
              _transmitters[index] = Transmitter(
                id: _transmitters[index].id,
                name: name,
              );
            }
          });
          Navigator.of(dialogContext, rootNavigator: true).pop();
        },
      ),
    );
  }

  Future<void> _delete(int index) async {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.deviceSettingsSheetScrim,
      builder: (sheetContext) => _TransmitterDeleteSheet(
        title: l10n.transmitterManagementDeletePromptTitle,
        message: l10n.transmitterManagementDeletePromptMessage,
        cancelLabel: l10n.deviceSettingsCancelAction,
        confirmLabel: l10n.deviceSettingsConfirmAction,
        textTheme: textTheme,
        onConfirm: () {
          setState(() => _transmitters.removeAt(index));
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }
}

class _TransmitterListRow extends StatelessWidget {
  const _TransmitterListRow({
    required this.transmitter,
    required this.editSemanticLabel,
    required this.deleteSemanticLabel,
    required this.onEdit,
    required this.onDelete,
  });

  final Transmitter transmitter;
  final String editSemanticLabel;
  final String deleteSemanticLabel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 66,
    child: Row(
      children: [
        Expanded(
          child: Text(
            transmitter.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextTokens.transmitterManagementRowTitle(
              Theme.of(context).textTheme,
            ),
          ),
        ),
        const SizedBox(width: 16),
        _TransmitterActionButton(
          semanticLabel: editSemanticLabel,
          assetPath: TransmitterListAssetPaths.editActionPlaceholder,
          onPressed: onEdit,
        ),
        const SizedBox(width: 15),
        _TransmitterActionButton(
          semanticLabel: deleteSemanticLabel,
          assetPath: TransmitterListAssetPaths.deleteActionPlaceholder,
          onPressed: onDelete,
        ),
      ],
    ),
  );
}

class _TransmitterActionButton extends StatelessWidget {
  const _TransmitterActionButton({
    required this.semanticLabel,
    required this.assetPath,
    required this.onPressed,
  });

  final String semanticLabel;
  final String assetPath;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semanticLabel,
    child: SizedBox(
      child: Center(
        child: Material(
          color: AppColors.transmitterManagementActionSurface,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Image.asset(assetPath, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _TransmitterAddButton extends StatelessWidget {
  const _TransmitterAddButton({
    required this.semanticLabel,
    required this.onPressed,
  });

  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semanticLabel,
    child: SizedBox(
      child: Center(
        child: Material(
          color: AppColors.transmitterManagementPrimaryAction,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: 53,
              height: 53,
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Image.asset(
                  TransmitterListAssetPaths.addActionPlaceholder,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _TransmitterSheetSurface extends StatelessWidget {
  const _TransmitterSheetSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.backgroundPrimary,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
    clipBehavior: Clip.antiAlias,
    child: SafeArea(top: false, child: child),
  );
}

class _TransmitterNameDialog extends StatefulWidget {
  const _TransmitterNameDialog({
    required this.initialName,
    required this.title,
    required this.nameHint,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.textTheme,
    required this.onConfirm,
  });

  final String initialName;
  final String title;
  final String nameHint;
  final String cancelLabel;
  final String confirmLabel;
  final TextTheme textTheme;
  final ValueChanged<String> onConfirm;

  @override
  State<_TransmitterNameDialog> createState() => _TransmitterNameDialogState();
}

class _TransmitterNameDialogState extends State<_TransmitterNameDialog> {
  late final TextEditingController _controller;
  var _hasName = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _hasName = widget.initialName.trim().isNotEmpty;
    _controller.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onNameChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    final hasName = _controller.text.trim().isNotEmpty;
    if (_hasName != hasName) {
      setState(() => _hasName = hasName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: viewInsets,
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
                    widget.title,
                    style: AppTextTokens.transmitterManagementSheetTitle(
                      widget.textTheme,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: AppColors.transmitterManagementSheetInputBorder,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Image.asset(
                          TransmitterListAssetPaths.editActionPlaceholder,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            style:
                                AppTextTokens.transmitterManagementSheetInput(
                                  widget.textTheme,
                                ),
                            decoration: InputDecoration.collapsed(
                              hintText: widget.nameHint,
                              hintStyle:
                                  AppTextTokens.transmitterManagementSheetInput(
                                    widget.textTheme,
                                  ).copyWith(color: AppColors.textHint),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  AppColors.deviceSettingsCancelAction,
                              foregroundColor: AppColors.textPrimary,
                              shape: const StadiumBorder(),
                            ),
                            child: Text(
                              widget.cancelLabel,
                              style:
                                  AppTextTokens.transmitterManagementSheetButton(
                                    widget.textTheme,
                                  ).copyWith(color: AppColors.textPrimary),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: _hasName
                                ? () =>
                                      widget.onConfirm(_controller.text.trim())
                                : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.brandPrimary,
                              disabledBackgroundColor:
                                  AppColors.brandPrimaryDisabled,
                              foregroundColor: AppColors.backgroundPrimary,
                              disabledForegroundColor:
                                  AppColors.authPrimaryButtonDisabledForeground,
                              shape: const StadiumBorder(),
                            ),
                            child: Text(
                              widget.confirmLabel,
                              style:
                                  AppTextTokens.transmitterManagementSheetButton(
                                    widget.textTheme,
                                  ),
                            ),
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

class _TransmitterDeleteSheet extends StatelessWidget {
  const _TransmitterDeleteSheet({
    required this.title,
    required this.message,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.textTheme,
    required this.onConfirm,
  });

  final String title;
  final String message;
  final String cancelLabel;
  final String confirmLabel;
  final TextTheme textTheme;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) => _TransmitterSheetSurface(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: AppTextTokens.transmitterManagementSheetTitle(textTheme),
          ),
          const SizedBox(height: 11),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextTokens.transmitterManagementSheetBody(textTheme),
          ),
          const SizedBox(height: 33),
          _TransmitterSheetActionRow(
            cancelLabel: cancelLabel,
            confirmLabel: confirmLabel,
            textTheme: textTheme,
            onConfirm: onConfirm,
          ),
        ],
      ),
    ),
  );
}

class _TransmitterSheetActionRow extends StatelessWidget {
  const _TransmitterSheetActionRow({
    required this.cancelLabel,
    required this.confirmLabel,
    required this.textTheme,
    required this.onConfirm,
  });

  final String cancelLabel;
  final String confirmLabel;
  final TextTheme textTheme;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.deviceSettingsCancelAction,
              foregroundColor: AppColors.textPrimary,
              shape: const StadiumBorder(),
            ),
            child: Text(
              cancelLabel,
              style: AppTextTokens.transmitterManagementSheetButton(
                textTheme,
              ).copyWith(color: AppColors.textPrimary),
            ),
          ),
        ),
      ),
      const SizedBox(width: 48),
      Expanded(
        child: SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: onConfirm,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: AppColors.backgroundPrimary,
              shape: const StadiumBorder(),
            ),
            child: Text(
              confirmLabel,
              style: AppTextTokens.transmitterManagementSheetButton(textTheme),
            ),
          ),
        ),
      ),
    ],
  );
}
