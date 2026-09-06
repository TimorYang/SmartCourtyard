import 'package:flutter/material.dart';

import '../../app/theme/app_design_tokens.dart';

class FlinxBlockingLoadingOverlay extends StatelessWidget {
  const FlinxBlockingLoadingOverlay({required this.semanticsLabel, super.key});

  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        alignment: Alignment.center,
        children: [
          const ModalBarrier(
            dismissible: false,
            color: AppColors.warningDialogScrim,
          ),
          Semantics(
            label: semanticsLabel,
            child: const CircularProgressIndicator(),
          ),
        ],
      ),
    );
  }
}
