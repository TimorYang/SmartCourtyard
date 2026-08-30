import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_door_command_button.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/f_box_wiring_test_controller.dart';
import '../navigation/f_box_wiring_test_route.dart';
import '../navigation/onboarding_device_navigation.dart';

class FBoxWiringTestAssetPaths {
  const FBoxWiringTestAssetPaths._();

  static const pbControl =
      'assets/icons/add_device/f_box_wiring_test_pb_control.png';
}

class FBoxWiringTestPage extends ConsumerStatefulWidget {
  const FBoxWiringTestPage({
    this.routeData = const FBoxWiringTestRouteData(),
    super.key,
  });

  static const routeName = FBoxWiringTestRoute.routeName;
  static const routePath = FBoxWiringTestRoute.routePath;

  final FBoxWiringTestRouteData routeData;

  @override
  ConsumerState<FBoxWiringTestPage> createState() => _FBoxWiringTestPageState();
}

class _FBoxWiringTestPageState extends ConsumerState<FBoxWiringTestPage> {
  var _wiring = _FBoxWiring.pb;

  void _sendTest(FBoxWiringTestAction action) {
    unawaited(
      ref
          .read(fBoxWiringTestControllerProvider.notifier)
          .send(routeData: widget.routeData, action: action),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final commandState = ref.watch(fBoxWiringTestControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: FlinxNavigationBar(
        title: '',
        showBottomDivider: false,
        automaticallyImplyLeading: Navigator.of(context).canPop(),
        onBackPressed: () => OnboardingDeviceNavigation.handleFBoxBack(
          context,
          routeData: widget.routeData,
        ),
        actions: [
          IconButton(
            key: const Key('fBoxWiringTestAddButton'),
            tooltip: l10n.fBoxWiringTestAddTooltip,
            onPressed: () {},
            icon: const Icon(Icons.add),
          ),
          const SizedBox(
            width:
                AppSpacingTokens.fBoxWiringTestNavigationActionTrailingSpacing,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth =
                (constraints.maxWidth >
                            AppLayoutTokens.fBoxWiringTestLargeScreenMinWidth
                        ? math.min(
                            constraints.maxWidth,
                            AppLayoutTokens.fBoxWiringTestContentMaxWidth,
                          )
                        : constraints.maxWidth)
                    .toDouble();
            final pageHeight = math
                .max(
                  constraints.maxHeight,
                  AppSpacingTokens.fBoxWiringTestMinimumPageHeight,
                )
                .toDouble();

            return SingleChildScrollView(
              child: SizedBox(
                width: constraints.maxWidth,
                height: pageHeight,
                child: Center(
                  child: SizedBox(
                    width: contentWidth,
                    child: Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacingTokens.fBoxWiringTestPageHorizontal,
                              AppSpacingTokens.fBoxWiringTestPageTop,
                              AppSpacingTokens.fBoxWiringTestPageHorizontal,
                              0,
                            ),
                            child: _buildMainContent(
                              l10n: l10n,
                              textTheme: textTheme,
                              contentWidth: contentWidth,
                              commandState: commandState,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacingTokens.fBoxWiringTestPageHorizontal,
                            0,
                            AppSpacingTokens.fBoxWiringTestPageHorizontal,
                            AppSpacingTokens.fBoxWiringTestBottomPadding,
                          ),
                          child: _buildFooter(
                            l10n: l10n,
                            textTheme: textTheme,
                            commandState: commandState,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainContent({
    required AppLocalizations l10n,
    required TextTheme textTheme,
    required double contentWidth,
    required FBoxWiringTestState commandState,
  }) {
    final availableContentWidth = math
        .max(
          0.0,
          contentWidth - (AppSpacingTokens.fBoxWiringTestPageHorizontal * 2),
        )
        .toDouble();
    final segmentWidth = math
        .min(AppSpacingTokens.fBoxWiringTestSegmentWidth, availableContentWidth)
        .toDouble();
    final descriptionWidth = math
        .min(
          AppSpacingTokens.fBoxWiringTestDescriptionMaxWidth,
          availableContentWidth,
        )
        .toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.fBoxWiringTestTitle,
          style: AppTextTokens.fBoxWiringTestTitle(textTheme),
        ),
        const SizedBox(
          height: AppSpacingTokens.fBoxWiringTestTitleToDescription,
        ),
        SizedBox(
          width: descriptionWidth,
          child: Text(
            l10n.fBoxWiringTestDescription,
            style: AppTextTokens.fBoxWiringTestDescription(textTheme),
          ),
        ),
        const SizedBox(
          height: AppSpacingTokens.fBoxWiringTestDescriptionToSegment,
        ),
        SizedBox(
          width: segmentWidth,
          child: _WiringSegmentedControl(
            value: _wiring,
            pbLabel: l10n.fBoxWiringTestPbWiring,
            oscLabel: l10n.fBoxWiringTestOscWiring,
            onChanged: (value) => setState(() => _wiring = value),
          ),
        ),
        Expanded(
          child: Center(
            child: _wiring == _FBoxWiring.pb
                ? _PbWiringTestControl(
                    semanticsLabel: l10n.fBoxWiringTestPbAction,
                    onPressed: commandState.isSending
                        ? null
                        : () => _sendTest(FBoxWiringTestAction.pb),
                    pending:
                        commandState.isSending &&
                        commandState.lastAction == FBoxWiringTestAction.pb,
                  )
                : _OscWiringTestControls(
                    closeLabel: l10n.fBoxWiringTestCloseAction,
                    stopLabel: l10n.fBoxWiringTestStopAction,
                    openLabel: l10n.fBoxWiringTestOpenAction,
                    isSending: commandState.isSending,
                    pendingAction: commandState.lastAction,
                    onPressed: _sendTest,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter({
    required AppLocalizations l10n,
    required TextTheme textTheme,
    required FBoxWiringTestState commandState,
  }) {
    final errorMessage = switch (commandState.error) {
      FBoxWiringTestError.noConnectedDevice =>
        l10n.fBoxWiringTestNoConnectedDevice,
      FBoxWiringTestError.commandRejected => l10n.fBoxWiringTestCommandRejected,
      FBoxWiringTestError.commandFailed => l10n.fBoxWiringTestCommandFailed,
      null => null,
    };

    return Column(
      children: [
        Semantics(
          label: l10n.fBoxWiringTestDoorOperatesNormally,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                key: const Key('fBoxWiringTestStatusIndicator'),
                width: AppSpacingTokens.fBoxWiringTestStatusIndicatorSize,
                height: AppSpacingTokens.fBoxWiringTestStatusIndicatorSize,
                decoration: BoxDecoration(
                  color: commandState.hasTested
                      ? AppColors.brandPrimary
                      : AppColors.fBoxWiringTestStatusPending,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(
                width: AppSpacingTokens.fBoxWiringTestStatusIndicatorGap,
              ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.fBoxWiringTestDoorOperatesNormally,
                    style: AppTextTokens.fBoxWiringTestStatus(textTheme),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(
            height: AppSpacingTokens.fBoxWiringTestErrorTopSpacing,
          ),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: AppTextTokens.fBoxWiringTestError(textTheme),
          ),
        ],
        const SizedBox(height: AppSpacingTokens.fBoxWiringTestStatusToAction),
        SizedBox(
          width: double.infinity,
          height: AppSpacingTokens.fBoxWiringTestActionHeight,
          child: FilledButton(
            key: const Key('fBoxWiringTestNextButton'),
            onPressed: () => OnboardingDeviceNavigation.finishFBoxTest(
              context,
              routeData: widget.routeData,
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.fBoxWiringTestPrimaryAction,
              foregroundColor: AppColors.fBoxWiringTestPrimaryActionForeground,
              shape: const StadiumBorder(),
              textStyle: AppTextTokens.fBoxWiringTestPrimaryButton(textTheme),
            ),
            child: Text(l10n.fBoxConnectionGuideNextAction),
          ),
        ),
      ],
    );
  }
}

enum _FBoxWiring { pb, osc }

class _WiringSegmentedControl extends StatelessWidget {
  const _WiringSegmentedControl({
    required this.value,
    required this.pbLabel,
    required this.oscLabel,
    required this.onChanged,
  });

  final _FBoxWiring value;
  final String pbLabel;
  final String oscLabel;
  final ValueChanged<_FBoxWiring> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('fBoxWiringTestSegmentedControl'),
      height: AppSpacingTokens.fBoxWiringTestSegmentHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.fBoxWiringTestSegmentSurface,
          borderRadius: BorderRadius.circular(
            AppShapeTokens.fBoxWiringTestControlRadius,
          ),
        ),
        child: Row(
          children: [
            _WiringSegment(
              key: const Key('fBoxWiringTestPbSegment'),
              label: pbLabel,
              selected: value == _FBoxWiring.pb,
              onTap: () => onChanged(_FBoxWiring.pb),
            ),
            _WiringSegment(
              key: const Key('fBoxWiringTestOscSegment'),
              label: oscLabel,
              selected: value == _FBoxWiring.osc,
              onTap: () => onChanged(_FBoxWiring.osc),
            ),
          ],
        ),
      ),
    );
  }
}

class _WiringSegment extends StatelessWidget {
  const _WiringSegment({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            AppShapeTokens.fBoxWiringTestControlRadius,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.fBoxWiringTestSegmentSelectedSurface
                  : Colors.transparent,
              border: selected
                  ? Border.all(color: AppColors.fBoxWiringTestSegmentBorder)
                  : null,
              borderRadius: BorderRadius.circular(
                AppShapeTokens.fBoxWiringTestControlRadius,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: AppTextTokens.fBoxWiringTestSegment(
                  Theme.of(context).textTheme,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PbWiringTestControl extends StatelessWidget {
  const _PbWiringTestControl({
    required this.semanticsLabel,
    required this.onPressed,
    required this.pending,
  });

  final String semanticsLabel;
  final VoidCallback? onPressed;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: SizedBox(
        width: AppSpacingTokens.fBoxWiringTestPbControlSize,
        height: AppSpacingTokens.fBoxWiringTestPbControlSize,
        child: FilledButton(
          key: const Key('fBoxWiringTestPbControl'),
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.textHint,
            elevation: 0,
            padding: EdgeInsets.zero,
            shape: const CircleBorder(),
          ),
          child: pending
              ? const CircularProgressIndicator(color: AppColors.textHint)
              : Image.asset(
                  FBoxWiringTestAssetPaths.pbControl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.textHint,
                    size: 96,
                  ),
                ),
        ),
      ),
    );
  }
}

class _OscWiringTestControls extends StatelessWidget {
  const _OscWiringTestControls({
    required this.closeLabel,
    required this.stopLabel,
    required this.openLabel,
    required this.isSending,
    required this.pendingAction,
    required this.onPressed,
  });

  final String closeLabel;
  final String stopLabel;
  final String openLabel;
  final bool isSending;
  final FBoxWiringTestAction? pendingAction;
  final ValueChanged<FBoxWiringTestAction> onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _OscControlButton(
          key: const Key('fBoxWiringTestOpenControl'),
          semanticsLabel: closeLabel,
          icon: Icons.keyboard_arrow_down,
          pending: isSending && pendingAction == FBoxWiringTestAction.close,
          onPressed: isSending
              ? null
              : () => onPressed(FBoxWiringTestAction.close),
        ),
        const SizedBox(width: AppSpacingTokens.fBoxWiringTestControlGap),
        _OscControlButton(
          key: const Key('fBoxWiringTestStopControl'),
          semanticsLabel: stopLabel,
          icon: Icons.pause,
          pending: isSending && pendingAction == FBoxWiringTestAction.stop,
          onPressed: isSending
              ? null
              : () => onPressed(FBoxWiringTestAction.stop),
        ),
        const SizedBox(width: AppSpacingTokens.fBoxWiringTestControlGap),
        _OscControlButton(
          key: const Key('fBoxWiringTestCloseControl'),
          semanticsLabel: openLabel,
          icon: Icons.keyboard_arrow_up,
          pending: isSending && pendingAction == FBoxWiringTestAction.open,
          onPressed: isSending
              ? null
              : () => onPressed(FBoxWiringTestAction.open),
        ),
      ],
    );
  }
}

class _OscControlButton extends StatelessWidget {
  const _OscControlButton({
    super.key,
    required this.semanticsLabel,
    required this.icon,
    required this.onPressed,
    required this.pending,
  });

  final String semanticsLabel;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: FlinxDoorCommandButton(
        tooltip: semanticsLabel,
        icon: icon,
        onPressed: onPressed,
        pending: pending,
        size: AppSpacingTokens.fBoxWiringTestControlSize,
        iconSize: AppSpacingTokens.fBoxWiringTestControlIconSize,
        radius: AppShapeTokens.fBoxWiringTestControlRadius,
      ),
    );
  }
}
