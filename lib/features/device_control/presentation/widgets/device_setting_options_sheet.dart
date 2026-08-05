import 'package:flutter/material.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../settings/domain/entities/device_capability.dart';

String formatDeviceCapabilityOption(
  DeviceCapabilityOption option,
  String? unit,
) {
  final normalizedUnit = unit?.trim();
  return normalizedUnit == null || normalizedUnit.isEmpty
      ? option.label
      : '${option.label} $normalizedUnit';
}

class DeviceCapabilityOptionsSheet extends StatefulWidget {
  const DeviceCapabilityOptionsSheet({
    required this.title,
    required this.options,
    required this.unit,
    required this.initialValue,
    super.key,
  });

  final String title;
  final List<DeviceCapabilityOption> options;
  final String? unit;
  final int initialValue;

  @override
  State<DeviceCapabilityOptionsSheet> createState() =>
      _DeviceCapabilityOptionsSheetState();
}

class _DeviceCapabilityOptionsSheetState
    extends State<DeviceCapabilityOptionsSheet> {
  late int _selectedValue = widget.initialValue;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DeviceSettingsSheetFrame(
      heightFactor: 0.50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: AppTextTokens.deviceSettingsSheetTitle(textTheme),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: DeviceSettingsFixedSelectionList<DeviceCapabilityOption>(
              values: widget.options,
              initialValue: widget.options.firstWhere(
                (option) => option.value == _selectedValue,
                orElse: () => widget.options.first,
              ),
              labelBuilder: (option) =>
                  formatDeviceCapabilityOption(option, widget.unit),
              onSelected: (option) =>
                  setState(() => _selectedValue = option.value),
            ),
          ),
          const SizedBox(height: 20),
          DeviceSettingsSheetActionRow(
            onConfirm: () => Navigator.pop(context, _selectedValue),
          ),
        ],
      ),
    );
  }
}

class DeviceSettingsSheetFrame extends StatelessWidget {
  const DeviceSettingsSheetFrame({
    required this.heightFactor,
    required this.child,
    super.key,
  });

  final double heightFactor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: heightFactor,
      alignment: Alignment.bottomCenter,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.backgroundPrimary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: child,
          ),
        ),
      ),
    );
  }
}

class DeviceSettingsFixedSelectionList<T> extends StatefulWidget {
  const DeviceSettingsFixedSelectionList({
    required this.values,
    required this.initialValue,
    required this.labelBuilder,
    required this.onSelected,
    super.key,
  });

  static const itemExtent = 46.0;

  final List<T> values;
  final T initialValue;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onSelected;

  @override
  State<DeviceSettingsFixedSelectionList<T>> createState() =>
      _DeviceSettingsFixedSelectionListState<T>();
}

class _DeviceSettingsFixedSelectionListState<T>
    extends State<DeviceSettingsFixedSelectionList<T>> {
  late int _selectedIndex = _initialIndex;
  late final FixedExtentScrollController _controller =
      FixedExtentScrollController(initialItem: _selectedIndex);

  int get _initialIndex {
    final index = widget.values.indexOf(widget.initialValue);
    return index < 0 ? 0 : index;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final selectionTop =
            (constraints.maxHeight -
                DeviceSettingsFixedSelectionList.itemExtent) /
            2;

        return Stack(
          children: [
            ListWheelScrollView.useDelegate(
              controller: _controller,
              physics: const FixedExtentScrollPhysics(),
              itemExtent: DeviceSettingsFixedSelectionList.itemExtent,
              onSelectedItemChanged: (index) {
                setState(() => _selectedIndex = index);
                widget.onSelected(widget.values[index]);
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: widget.values.length,
                builder: (context, index) {
                  final selected = index == _selectedIndex;
                  return Center(
                    child: Text(
                      widget.labelBuilder(widget.values[index]),
                      style: selected
                          ? AppTextTokens.deviceSettingsSheetSelectedOption(
                              textTheme,
                            )
                          : AppTextTokens.deviceSettingsSheetOption(textTheme),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: selectionTop,
              left: 0,
              right: 0,
              height: DeviceSettingsFixedSelectionList.itemExtent,
              child: IgnorePointer(
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                      horizontal: BorderSide(
                        color: AppColors.deviceSettingsDivider,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class DeviceSettingsSheetActionRow extends StatelessWidget {
  const DeviceSettingsSheetActionRow({required this.onConfirm, super.key});

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 45,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.deviceSettingsSheetCancel,
                foregroundColor: AppColors.textMuted,
                shape: const StadiumBorder(),
              ),
              child: Text(
                l10n.deviceSettingsCancelAction,
                style: AppTextTokens.deviceSettingsSheetButton(
                  textTheme,
                ).copyWith(color: AppColors.textMuted),
              ),
            ),
          ),
        ),
        const SizedBox(width: 40),
        Expanded(
          child: SizedBox(
            height: 45,
            child: FilledButton(
              onPressed: onConfirm,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: AppColors.backgroundPrimary,
                shape: const StadiumBorder(),
              ),
              child: Text(
                l10n.deviceSettingsConfirmAction,
                style: AppTextTokens.deviceSettingsSheetButton(
                  textTheme,
                ).copyWith(color: AppColors.backgroundPrimary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
