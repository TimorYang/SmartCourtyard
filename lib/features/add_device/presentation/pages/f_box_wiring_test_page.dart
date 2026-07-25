import 'package:flutter/material.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';

class FBoxWiringTestAssetPaths {
  const FBoxWiringTestAssetPaths._();

  static const pbTestPlaceholder =
      'assets/icons/add_device/f_box_wiring_pb_test_placeholder.png';
}

class FBoxWiringTestPage extends StatefulWidget {
  const FBoxWiringTestPage({super.key});

  static const routeName = 'f-box-wiring-test';
  static const routePath = '/add-device/f-box/wiring-test';

  @override
  State<FBoxWiringTestPage> createState() => _FBoxWiringTestPageState();
}

class _FBoxWiringTestPageState extends State<FBoxWiringTestPage> {
  var _wiring = _FBoxWiring.pb;
  var _hasTested = false;

  void _markTested() => setState(() => _hasTested = true);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: FlinxNavigationBar(
        title: '',
        showBottomDivider: false,
        automaticallyImplyLeading: Navigator.of(context).canPop(),
      ),
      body: SafeArea(
        top: false,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.fBoxWiringTestTitle,
                      style: AppTextTokens.fBoxWiringTestTitle(textTheme),
                    ),
                    const SizedBox(
                      height: AppSpacingTokens.fBoxWiringTestTitleToDescription,
                    ),
                    Text(
                      l10n.fBoxWiringTestDescription,
                      style: AppTextTokens.fBoxWiringTestDescription(textTheme),
                    ),
                    const SizedBox(
                      height: AppSpacingTokens.fBoxWiringTestDescriptionToSegment,
                    ),
                    _WiringSegmentedControl(
                      value: _wiring,
                      pbLabel: l10n.fBoxWiringTestPbWiring,
                      oscLabel: l10n.fBoxWiringTestOscWiring,
                      onChanged: (value) => setState(() => _wiring = value),
                    ),
                    Expanded(
                      child: Center(
                        child: _wiring == _FBoxWiring.pb
                            ? _PbWiringTestControl(
                                semanticsLabel: l10n.fBoxWiringTestPbAction,
                                onPressed: _markTested,
                              )
                            : _OscWiringTestControls(
                                openLabel: l10n.fBoxWiringTestOpenAction,
                                stopLabel: l10n.fBoxWiringTestStopAction,
                                closeLabel: l10n.fBoxWiringTestCloseAction,
                                onPressed: _markTested,
                              ),
                      ),
                    ),
                  ],
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
              child: Column(
                children: [
                  Semantics(
                    label: l10n.fBoxWiringTestDoorOperatesNormally,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          key: const Key('fBoxWiringTestStatusIndicator'),
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _hasTested
                                ? AppColors.brandPrimary
                                : AppColors.fBoxWiringTestStatusPending,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          l10n.fBoxWiringTestDoorOperatesNormally,
                          style: AppTextTokens.fBoxWiringTestStatus(textTheme),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: AppSpacingTokens.fBoxWiringTestStatusToAction,
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: AppSpacingTokens.fBoxWiringTestActionHeight,
                    child: FilledButton(
                      key: const Key('fBoxWiringTestNextButton'),
                      onPressed: () {},
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        textStyle: AppTextTokens.smartOpenerPrimaryButton(
                          textTheme,
                        ),
                      ),
                      child: Text(l10n.fBoxConnectionGuideNextAction),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
  });

  final String semanticsLabel;
  final VoidCallback onPressed;

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
          child: Image.asset(
            FBoxWiringTestAssetPaths.pbTestPlaceholder,
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
    required this.openLabel,
    required this.stopLabel,
    required this.closeLabel,
    required this.onPressed,
  });

  final String openLabel;
  final String stopLabel;
  final String closeLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _OscControlButton(
          key: const Key('fBoxWiringTestOpenControl'),
          semanticsLabel: openLabel,
          icon: Icons.keyboard_arrow_down_rounded,
          onPressed: onPressed,
        ),
        const SizedBox(width: AppSpacingTokens.fBoxWiringTestControlGap),
        _OscControlButton(
          key: const Key('fBoxWiringTestStopControl'),
          semanticsLabel: stopLabel,
          icon: Icons.pause_rounded,
          onPressed: onPressed,
        ),
        const SizedBox(width: AppSpacingTokens.fBoxWiringTestControlGap),
        _OscControlButton(
          key: const Key('fBoxWiringTestCloseControl'),
          semanticsLabel: closeLabel,
          icon: Icons.keyboard_arrow_up_rounded,
          onPressed: onPressed,
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
  });

  final String semanticsLabel;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: SizedBox(
        width: AppSpacingTokens.fBoxWiringTestControlSize,
        height: AppSpacingTokens.fBoxWiringTestControlSize,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.fBoxWiringTestControlSurface,
            foregroundColor: AppColors.fBoxWiringTestControlForeground,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppShapeTokens.fBoxWiringTestControlRadius,
              ),
            ),
          ),
          child: Icon(icon, size: 42),
        ),
      ),
    );
  }
}
