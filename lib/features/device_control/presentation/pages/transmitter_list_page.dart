import 'package:flutter/material.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';

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
  final _names = [
    'Warehouse-01-Daniel',
    'Warehouse-02-Danyl',
    'Warehouse-03-Turk',
    'Workshop-03-Airly',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                      itemCount: _names.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        color: AppColors.deviceSettingsDivider,
                      ),
                      itemBuilder: (context, index) => _TransmitterListRow(
                        name: _names[index],
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
                      onPressed: () => _edit(null),
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

  Future<void> _edit(int? index) async {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    await showDialog<void>(
      context: context,
      barrierColor: AppColors.deviceSettingsSheetScrim,
      builder: (dialogContext) => MediaQuery.removeViewInsets(
        context: dialogContext,
        removeBottom: true,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: _TransmitterNameSheet(
                initialName: index == null ? '' : _names[index],
                title: l10n.transmitterManagementInfoTitle,
                nameHint: l10n.transmitterManagementNameHint,
                cancelLabel: l10n.deviceSettingsCancelAction,
                confirmLabel: l10n.deviceSettingsConfirmAction,
                textTheme: textTheme,
                onConfirm: (name) {
                  setState(() {
                    if (index == null) {
                      _names.add(name);
                    } else {
                      _names[index] = name;
                    }
                  });
                  Navigator.of(dialogContext, rootNavigator: true).pop();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(int index) async {
    final l10n = AppLocalizations.of(context)!;
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
          setState(() => _names.removeAt(index));
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }
}

class _TransmitterListRow extends StatelessWidget {
  const _TransmitterListRow({
    required this.name,
    required this.editSemanticLabel,
    required this.deleteSemanticLabel,
    required this.onEdit,
    required this.onDelete,
  });

  final String name;
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
            name,
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
  const _TransmitterSheetSurface({
    required this.child,
    this.borderRadius = const BorderRadius.vertical(top: Radius.circular(16)),
  });

  final Widget child;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Material(
      color: AppColors.backgroundPrimary,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: child,
    ),
  );
}

class _TransmitterNameSheet extends StatefulWidget {
  const _TransmitterNameSheet({
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
  State<_TransmitterNameSheet> createState() => _TransmitterNameSheetState();
}

class _TransmitterNameSheetState extends State<_TransmitterNameSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _TransmitterSheetSurface(
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title,
            style: AppTextTokens.transmitterManagementSheetTitle(
              widget.textTheme,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 40,
            child: TextField(
              controller: _controller,
              autofocus: true,
              textAlignVertical: TextAlignVertical.center,
              style: AppTextTokens.transmitterManagementSheetInput(
                widget.textTheme,
              ),
              decoration: InputDecoration(
                hintText: widget.nameHint,
                hintStyle: AppTextTokens.transmitterManagementSheetInput(
                  widget.textTheme,
                ).copyWith(color: AppColors.textHint),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 52,
                  minHeight: 24,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 18, right: 12),
                  child: Image.asset(
                    TransmitterListAssetPaths.editActionPlaceholder,
                    width: 18,
                    height: 18,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                enabledBorder: _transmitterInputBorder,
                focusedBorder: _transmitterInputBorder,
              ),
            ),
          ),
          const SizedBox(height: 42),
          _TransmitterSheetActionRow(
            cancelLabel: widget.cancelLabel,
            confirmLabel: widget.confirmLabel,
            textTheme: widget.textTheme,
            onConfirm: () => widget.onConfirm(_controller.text),
          ),
        ],
      ),
    ),
  );
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

final _transmitterInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(30),
  borderSide: const BorderSide(
    color: AppColors.transmitterManagementSheetInputBorder,
  ),
);
