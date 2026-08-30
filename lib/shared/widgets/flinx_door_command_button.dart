import 'package:flutter/material.dart';

import '../../app/theme/app_design_tokens.dart';

class FlinxDoorCommandButton extends StatelessWidget {
  const FlinxDoorCommandButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.pending = false,
    this.size = AppSpacingTokens.deviceControlCommandButtonSize,
    this.iconSize = AppSpacingTokens.deviceControlCommandButtonIconSize,
    this.radius = AppShapeTokens.deviceControlCommandButtonRadius,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool pending;
  final double size;
  final double iconSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        fixedSize: Size.square(size),
        padding: EdgeInsets.zero,
        backgroundColor: AppColors.deviceControlPrimaryAction,
        disabledBackgroundColor: AppColors.deviceControlPrimaryAction
            .withValues(
              alpha: AppOpacityTokens.deviceControlCommandButtonDisabled,
            ),
        foregroundColor: AppColors.deviceControlPrimaryActionForeground,
        disabledForegroundColor: AppColors.deviceControlPrimaryActionForeground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      icon: pending
          ? SizedBox.square(
              dimension:
                  AppSpacingTokens.deviceControlCommandButtonProgressSize,
              child: CircularProgressIndicator(
                strokeWidth: AppSpacingTokens
                    .deviceControlCommandButtonProgressStrokeWidth,
                color: AppColors.deviceControlPrimaryActionForeground,
              ),
            )
          : Icon(icon, size: iconSize),
    );
  }
}
