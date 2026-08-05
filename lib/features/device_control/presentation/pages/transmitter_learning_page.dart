import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/device_command_controller.dart';

enum _TransmitterLearningState { ready, learning, failed, succeeded }

class TransmitterLearningPage extends ConsumerStatefulWidget {
  const TransmitterLearningPage({required this.deviceId, super.key});

  static const routeName = 'transmitter-learning';
  static const routePath = '/device-settings/transmitters/learning';
  final String deviceId;

  @override
  ConsumerState<TransmitterLearningPage> createState() =>
      _TransmitterLearningPageState();
}

class _TransmitterLearningPageState
    extends ConsumerState<TransmitterLearningPage> {
  late final DeviceCommandController _controller;
  var _state = _TransmitterLearningState.ready;
  var _pairingGeneration = 0;
  var _pairingActive = false;
  var _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(deviceCommandControllerProvider.notifier);
  }

  Future<void> _startPairing() async {
    if (_pairingActive || _isCancelling) {
      return;
    }
    final generation = ++_pairingGeneration;
    setState(() {
      _pairingActive = true;
      _state = _TransmitterLearningState.learning;
    });

    final succeeded = await _controller.startRemotePairing(
      deviceId: widget.deviceId,
    );
    if (!mounted || generation != _pairingGeneration) {
      return;
    }
    setState(() {
      _pairingActive = false;
      _state = succeeded
          ? _TransmitterLearningState.succeeded
          : _TransmitterLearningState.failed;
    });
  }

  void _cancelAndPop() {
    if (_isCancelling) {
      return;
    }
    final shouldCancelPairing = _pairingActive;
    _pairingGeneration += 1;
    setState(() {
      _pairingActive = false;
      _isCancelling = true;
    });
    if (shouldCancelPairing) {
      unawaited(_controller.cancelRemotePairing(deviceId: widget.deviceId));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.pop();
      }
    });
  }

  void _handleBack() {
    if (_pairingActive) {
      _cancelAndPop();
      return;
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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

    return PopScope(
      canPop: !_pairingActive,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _cancelAndPop();
        }
      },
      child: Scaffold(
        appBar: FlinxNavigationBar(
          title: '',
          showBottomDivider: false,
          onBackPressed: _handleBack,
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
                const Spacer(),
                Expanded(
                  flex: 8,
                  child: Image.asset(
                    illustrationPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Image.asset(
                      _TransmitterLearningAssetPaths.readyIllustration,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  statusTitle,
                  textAlign: TextAlign.center,
                  style: (textTheme.headlineSmall ?? const TextStyle())
                      .copyWith(
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
                const Spacer(),
                if (!isLearning && !isSucceeded)
                  FilledButton(
                    style: primaryButtonStyle,
                    onPressed: _startPairing,
                    child: Text(
                      isReady
                          ? l10n.transmitterLearningStartAction
                          : l10n.transmitterLearningRestartAction,
                    ),
                  ),
                if (isSucceeded)
                  FilledButton(
                    style: primaryButtonStyle,
                    onPressed: _handleBack,
                    child: Text(l10n.transmitterLearningCompleteAction),
                  ),
                if (isLearning || isFailed) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    style: cancelButtonStyle,
                    onPressed: _cancelAndPop,
                    child: Text(l10n.deviceSettingsCancelAction),
                  ),
                ],
              ],
            ),
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
