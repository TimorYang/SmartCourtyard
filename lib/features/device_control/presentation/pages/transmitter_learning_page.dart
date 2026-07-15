import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';

enum _TransmitterLearningState { ready, learning, failed, succeeded }

class TransmitterLearningPage extends StatefulWidget {
  const TransmitterLearningPage({required this.deviceId, super.key});

  static const routeName = 'transmitter-learning';
  static const routePath = '/device-settings/transmitters/learning';
  final String deviceId;

  @override
  State<TransmitterLearningPage> createState() =>
      _TransmitterLearningPageState();
}

class _TransmitterLearningPageState extends State<TransmitterLearningPage> {
  var _state = _TransmitterLearningState.ready;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final isReady = _state == _TransmitterLearningState.ready;
    final isLearning = _state == _TransmitterLearningState.learning;
    final isFailed = _state == _TransmitterLearningState.failed;
    final isSucceeded = _state == _TransmitterLearningState.succeeded;
    final primaryButtonStyle = FilledButton.styleFrom(
      backgroundColor: AppColors.deviceSettingsForceMarginConfirm,
      minimumSize: const Size.fromHeight(50),
    );
    final cancelButtonStyle = TextButton.styleFrom(
      backgroundColor: AppColors.deviceSettingsCancelAction,
      minimumSize: const Size.fromHeight(50),
    );
    final statusTitle = switch (_state) {
      _TransmitterLearningState.ready =>
        l10n.transmitterLearningKeepBluetoothOn,
      _TransmitterLearningState.learning => l10n.transmitterLearningInProgress,
      _TransmitterLearningState.failed => l10n.transmitterLearningFailed,
      _TransmitterLearningState.succeeded => l10n.transmitterLearningSucceeded,
    };
    final statusDescription = switch (_state) {
      _TransmitterLearningState.ready =>
        l10n.transmitterLearningReadyDescription,
      _TransmitterLearningState.learning =>
        l10n.transmitterLearningInProgressDescription,
      _TransmitterLearningState.failed || _TransmitterLearningState.succeeded =>
        l10n.transmitterLearningRemoteInstruction,
    };
    final illustrationPath = switch (_state) {
      _TransmitterLearningState.ready =>
        _TransmitterLearningAssetPaths.readyIllustration,
      _TransmitterLearningState.learning =>
        _TransmitterLearningAssetPaths.learningIllustration,
      _TransmitterLearningState.failed =>
        _TransmitterLearningAssetPaths.failedIllustration,
      _TransmitterLearningState.succeeded =>
        _TransmitterLearningAssetPaths.succeededIllustration,
    };

    return Scaffold(
      appBar: FlinxNavigationBar(
        title: '',
        showBottomDivider: false,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.qr_code_scanner_outlined),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 20, 32, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.transmitterLearningTitle,
                style: AppTextTokens.deviceSettingsTitle(textTheme),
              ),
              const SizedBox(height: 5),
              Text(
                l10n.transmitterLearningOnSiteTip,
                style: (textTheme.bodyLarge ?? const TextStyle()).copyWith(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              const Spacer(flex: 2),
              Image.asset(
                illustrationPath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Image.asset(
                  _TransmitterLearningAssetPaths.readyIllustration,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                statusTitle,
                textAlign: TextAlign.center,
                style: (textTheme.headlineSmall ?? const TextStyle()).copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 11),
              Text(
                statusDescription,
                textAlign: isReady ? TextAlign.start : TextAlign.center,
                style: (textTheme.bodyLarge ?? const TextStyle()).copyWith(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const Spacer(flex: 2),
              if (!isLearning && !isSucceeded)
                FilledButton(
                  style: primaryButtonStyle,
                  onPressed: () {
                    if (isReady) {
                      setState(
                        () => _state = _TransmitterLearningState.learning,
                      );
                    } else {
                      setState(() => _state = _TransmitterLearningState.ready);
                    }
                  },
                  child: Text(
                    isReady
                        ? l10n.transmitterLearningStartAction
                        : l10n.transmitterLearningRestartAction,
                  ),
                ),
              if (isSucceeded)
                FilledButton(
                  style: primaryButtonStyle,
                  onPressed: context.pop,
                  child: Text(l10n.transmitterLearningCompleteAction),
                ),
              if (isLearning || isFailed) ...[
                const SizedBox(height: 16),
                TextButton(
                  style: cancelButtonStyle,
                  onPressed: context.pop,
                  child: Text(l10n.deviceSettingsCancelAction),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TransmitterLearningAssetPaths {
  const _TransmitterLearningAssetPaths._();

  static const readyIllustration =
      'assets/icons/device_settings/transmitter_learning_placeholder.png';
  static const learningIllustration =
      'assets/icons/device_settings/transmitter_learning_progress_placeholder.png';
  static const failedIllustration =
      'assets/icons/device_settings/transmitter_learning_failed_placeholder.png';
  static const succeededIllustration =
      'assets/icons/device_settings/transmitter_learning_succeeded_placeholder.png';
}
