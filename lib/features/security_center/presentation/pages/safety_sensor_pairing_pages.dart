import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/safety_sensor_pairing_controller.dart';
import '../../application/safety_sensors_evaluation_controller.dart';
import 'safety_sensors_evaluation_page.dart';

class SafetySensorPairingGuidePage extends StatelessWidget {
  const SafetySensorPairingGuidePage({
    required this.doorId,
    required this.deviceId,
    super.key,
  });

  static const routeName = 'safety-sensor-pairing-guide';
  static const routePath = '/safety-sensors/pairing/guide';
  static const guideAsset =
      'assets/icons/security_center/safety_sensor_pairing_bluetooth_guide.png';

  final String doorId;
  final String deviceId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _PairingScaffold(
      title: l10n.safetySensorPairingGuideTitle,
      onBackPressed: () =>
          _returnToEvaluation(context, doorId: doorId, deviceId: deviceId),
      body: _PairingContent(
        illustration: _PairingIllustration(assetPath: guideAsset),
        guideLayout: true,
        status: l10n.safetySensorPairingGuideStatus,
        description: l10n.safetySensorPairingGuideDescription,
      ),
      action: _PairingActionButton(
        key: const ValueKey<String>('safety-sensor-pairing-start'),
        label: l10n.safetySensorPairingGuideAction,
        onPressed: () => context.pushReplacement(
          safetySensorPairingMatchingLocation(
            doorId: doorId,
            deviceId: deviceId,
          ),
        ),
      ),
    );
  }
}

class SafetySensorPairingMatchingPage extends ConsumerStatefulWidget {
  const SafetySensorPairingMatchingPage({
    required this.doorId,
    required this.deviceId,
    super.key,
  });

  static const routeName = 'safety-sensor-pairing-matching';
  static const routePath = '/safety-sensors/pairing/matching';
  static const matchingAsset =
      'assets/icons/security_center/safety_sensor_pairing_hold_button.png';

  final String doorId;
  final String deviceId;

  @override
  ConsumerState<SafetySensorPairingMatchingPage> createState() =>
      _SafetySensorPairingMatchingPageState();
}

class _SafetySensorPairingMatchingPageState
    extends ConsumerState<SafetySensorPairingMatchingPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(safetySensorPairingControllerProvider(widget.deviceId).notifier)
          .start(),
    );
  }

  void _exitPairing() {
    final controller = ref.read(
      safetySensorPairingControllerProvider(widget.deviceId).notifier,
    );
    if (controller.isPairing) {
      unawaited(controller.cancel());
    }
    _returnToEvaluation(
      context,
      doorId: widget.doorId,
      deviceId: widget.deviceId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ref.listen<SafetySensorPairingState>(
      safetySensorPairingControllerProvider(widget.deviceId),
      (previous, next) {
        if (!mounted || previous?.phase == next.phase) {
          return;
        }
        final location = switch (next.phase) {
          SafetySensorPairingPhase.success =>
            safetySensorPairingSuccessLocation(
              doorId: widget.doorId,
              deviceId: widget.deviceId,
            ),
          SafetySensorPairingPhase.failure ||
          SafetySensorPairingPhase.timeout =>
            safetySensorPairingFailureLocation(
              doorId: widget.doorId,
              deviceId: widget.deviceId,
            ),
          _ => null,
        };
        if (location != null) {
          context.pushReplacement(location);
        }
      },
    );
    final state = ref.watch(
      safetySensorPairingControllerProvider(widget.deviceId),
    );
    final isCancelling = state.phase == SafetySensorPairingPhase.cancelling;
    final actionLabel = isCancelling
        ? l10n.safetySensorPairingCancelling
        : l10n.safetySensorPairingCancel;
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _exitPairing();
        }
      },
      child: _PairingScaffold(
        title: l10n.safetySensorPairingGuideTitle,
        onBackPressed: _exitPairing,
        body: _PairingContent(
          illustration: _PairingIllustration(
            assetPath: SafetySensorPairingMatchingPage.matchingAsset,
          ),
          illustrationHeight:
              AppSpacingTokens.safetySensorPairingMatchingIllustrationSize,
          status: l10n.safetySensorPairingInProgress,
          description: l10n.safetySensorPairingMatchingDescription,
        ),
        action: _PairingActionButton(
          key: const ValueKey<String>('safety-sensor-pairing-cancel'),
          label: actionLabel,
          primary: false,
          onPressed: isCancelling ? null : _exitPairing,
        ),
      ),
    );
  }
}

class SafetySensorPairingSuccessPage extends ConsumerWidget {
  const SafetySensorPairingSuccessPage({
    required this.doorId,
    required this.deviceId,
    super.key,
  });

  static const routeName = 'safety-sensor-pairing-success';
  static const routePath = '/safety-sensors/pairing/success';

  final String doorId;
  final String deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SafetySensorPairingResultPage(
      doorId: doorId,
      deviceId: deviceId,
      success: true,
    );
  }
}

class SafetySensorPairingFailurePage extends ConsumerWidget {
  const SafetySensorPairingFailurePage({
    required this.doorId,
    required this.deviceId,
    super.key,
  });

  static const routeName = 'safety-sensor-pairing-failure';
  static const routePath = '/safety-sensors/pairing/failure';

  final String doorId;
  final String deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SafetySensorPairingResultPage(
      doorId: doorId,
      deviceId: deviceId,
      success: false,
    );
  }
}

class _SafetySensorPairingResultPage extends ConsumerWidget {
  const _SafetySensorPairingResultPage({
    required this.doorId,
    required this.deviceId,
    required this.success,
  });

  final String doorId;
  final String deviceId;
  final bool success;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    void complete() {
      if (success) {
        unawaited(
          ref
              .read(safetySensorsEvaluationControllerProvider(doorId).notifier)
              .load(doorId: doorId),
        );
      }
      _returnToEvaluation(context, doorId: doorId, deviceId: deviceId);
    }

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          complete();
        }
      },
      child: _PairingScaffold(
        title: l10n.safetySensorPairingGuideTitle,
        onBackPressed: complete,
        body: _PairingContent(
          illustration: _PairingResultIndicator(success: success),
          status: success
              ? l10n.safetySensorPairingSuccess
              : l10n.safetySensorPairingLearningFailed,
        ),
        action: _PairingActionButton(
          key: const ValueKey<String>('safety-sensor-pairing-complete'),
          label: l10n.safetySensorPairingComplete,
          onPressed: complete,
        ),
      ),
    );
  }
}

class _PairingScaffold extends StatelessWidget {
  const _PairingScaffold({
    required this.title,
    required this.onBackPressed,
    required this.body,
    required this.action,
  });

  final String title;
  final VoidCallback onBackPressed;
  final Widget body;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.safetySensorPairingBackground,
      appBar: FlinxNavigationBar(
        title: '',
        showBottomDivider: false,
        onBackPressed: onBackPressed,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: AppTextTokens.sharedDevicesTitle(textTheme),
                ),
              ),
            ),
            Expanded(child: body),
            Padding(
              padding: const EdgeInsets.only(
                bottom: AppSpacingTokens.safetySensorPairingActionBottom,
              ),
              child: SizedBox(width: double.infinity, child: action),
            ),
          ],
        ),
      ),
    );
  }
}

class _PairingContent extends StatelessWidget {
  const _PairingContent({
    required this.illustration,
    required this.status,
    this.guideLayout = false,
    this.illustrationHeight,
    this.description,
  });

  final Widget illustration;
  final String status;
  final bool guideLayout;
  final double? illustrationHeight;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          top: guideLayout
              ? AppSpacingTokens.safetySensorPairingGuideContentTop
              : AppSpacingTokens.safetySensorPairingContentTop,
        ),
        child: Column(
          children: [
            SizedBox(
              width: guideLayout
                  ? AppSpacingTokens.safetySensorPairingGuideIllustrationSize
                  : null,
              height: guideLayout
                  ? AppSpacingTokens.safetySensorPairingGuideIllustrationSize
                  : illustrationHeight ??
                        AppSpacingTokens.safetySensorPairingIllustrationSize,
              child: Center(child: illustration),
            ),
            SizedBox(
              height: guideLayout
                  ? AppSpacingTokens
                        .safetySensorPairingGuideIllustrationToStatus
                  : AppSpacingTokens.safetySensorPairingIllustrationToStatus,
            ),
            Text(
              status,
              textAlign: TextAlign.center,
              style: AppTextTokens.safetySensorPairingStatus(textTheme),
            ),
            if (description != null) ...[
              SizedBox(
                height: guideLayout
                    ? AppSpacingTokens
                          .safetySensorPairingGuideStatusToDescription
                    : AppSpacingTokens.safetySensorPairingStatusToDescription,
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: guideLayout
                      ? double.infinity
                      : AppSpacingTokens.safetySensorPairingDescriptionMaxWidth,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: guideLayout
                        ? AppSpacingTokens
                              .safetySensorPairingGuideDescriptionHorizontal
                        : 0,
                  ),
                  child: Text(
                    description!,
                    textAlign: TextAlign.left,
                    style: AppTextTokens.safetySensorPairingBody(textTheme),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PairingIllustration extends StatelessWidget {
  const _PairingIllustration({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      key: ValueKey<String>('safety-sensor-pairing-asset-$assetPath'),
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          _PairingAssetPlaceholder(assetPath: assetPath),
    );
  }
}

class _PairingAssetPlaceholder extends StatelessWidget {
  const _PairingAssetPlaceholder({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.safetySensorPairingImagePlaceholder,
      child: Container(
        key: ValueKey<String>('safety-sensor-pairing-placeholder-$assetPath'),
        width: 220,
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.safetySensorPairingPlaceholderSurface,
          borderRadius: BorderRadius.circular(
            AppShapeTokens.safetySensorPairingPlaceholderRadius,
          ),
        ),
        child: Icon(
          Icons.image_outlined,
          color: AppColors.safetySensorPairingPlaceholderForeground,
          size: 56,
        ),
      ),
    );
  }
}

class _PairingResultIndicator extends StatelessWidget {
  const _PairingResultIndicator({required this.success});

  final bool success;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacingTokens.safetySensorPairingResultIndicatorSize,
      height: AppSpacingTokens.safetySensorPairingResultIndicatorSize,
      decoration: BoxDecoration(
        color: success
            ? AppColors.safetySensorPairingSuccess
            : AppColors.safetySensorPairingFailure,
        shape: BoxShape.circle,
      ),
      child: Icon(
        success ? Icons.check_rounded : Icons.close_rounded,
        color: AppColors.safetySensorPairingResultForeground,
        size: AppSpacingTokens.safetySensorPairingResultIconSize,
      ),
    );
  }
}

class _PairingActionButton extends StatelessWidget {
  const _PairingActionButton({
    required this.label,
    required this.onPressed,
    this.primary = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      height: AppSpacingTokens.safetySensorPairingActionHeight,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: primary
              ? AppColors.safetySensorPairingPrimaryAction
              : AppColors.safetySensorPairingSecondaryAction,
          foregroundColor: primary
              ? AppColors.safetySensorPairingPrimaryActionForeground
              : AppColors.safetySensorPairingSecondaryForeground,
          overlayColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppShapeTokens.safetySensorPairingActionRadius,
            ),
          ),
        ),
        child: Text(
          label,
          style: primary
              ? AppTextTokens.safetySensorPairingAction(textTheme)
              : AppTextTokens.safetySensorPairingSecondaryAction(textTheme),
        ),
      ),
    );
  }
}

String safetySensorPairingGuideLocation({
  required String doorId,
  required String deviceId,
}) =>
    _pairingLocation(SafetySensorPairingGuidePage.routePath, doorId, deviceId);

String safetySensorPairingMatchingLocation({
  required String doorId,
  required String deviceId,
}) => _pairingLocation(
  SafetySensorPairingMatchingPage.routePath,
  doorId,
  deviceId,
);

String safetySensorPairingSuccessLocation({
  required String doorId,
  required String deviceId,
}) => _pairingLocation(
  SafetySensorPairingSuccessPage.routePath,
  doorId,
  deviceId,
);

String safetySensorPairingFailureLocation({
  required String doorId,
  required String deviceId,
}) => _pairingLocation(
  SafetySensorPairingFailurePage.routePath,
  doorId,
  deviceId,
);

String _pairingLocation(String routePath, String doorId, String deviceId) =>
    '$routePath?doorId=${Uri.encodeQueryComponent(doorId)}'
    '&deviceId=${Uri.encodeQueryComponent(deviceId)}';

void _returnToEvaluation(
  BuildContext context, {
  required String doorId,
  required String deviceId,
}) {
  if (Navigator.of(context).canPop()) {
    context.pop();
    return;
  }
  context.go(
    _pairingLocation(SafetySensorsEvaluationPage.routePath, doorId, deviceId),
  );
}
