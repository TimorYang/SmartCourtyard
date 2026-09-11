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
          ModalBarrier(
            dismissible: false,
            color: context.colors.warningDialogScrim,
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
