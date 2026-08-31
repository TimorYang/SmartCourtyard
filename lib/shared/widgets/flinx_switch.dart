import 'package:flutter/material.dart';

import '../../app/theme/app_design_tokens.dart';

class FlinxSwitch extends StatelessWidget {
  const FlinxSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.onDisabled,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onDisabled;

  @override
  Widget build(BuildContext context) {
    final trackColor = value
        ? AppColors.toggleSelected
        : AppColors.deviceControlInactive.withValues(alpha: 0.58);

    return Semantics(
      button: true,
      toggled: value,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged(!value) : onDisabled,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          opacity: enabled ? 1 : 0.55,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: 50,
            height: 26,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: trackColor,
              borderRadius: BorderRadius.circular(13),
            ),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: AppColors.backgroundPrimary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
