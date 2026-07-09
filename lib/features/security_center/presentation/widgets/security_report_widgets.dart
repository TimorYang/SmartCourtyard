import 'package:flutter/material.dart';

import '../../../../app/theme/app_design_tokens.dart';

const securityReportHeroAsset =
    'assets/icons/security_center/security_center_protecting_hero.png';

class SecurityReportHero extends StatelessWidget {
  const SecurityReportHero({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 330,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned.fill(
            top: 120,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.securityReportHeroBlue,
                    AppColors.securityReportHeroFade,
                    AppColors.securityCenterBackground,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 22,
            child: Image.asset(
              securityReportHeroAsset,
              width: 265,
              height: 205,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.garage_outlined,
                size: 180,
                color: AppColors.securityCenterSensorIcon,
              ),
            ),
          ),
          Positioned(
            top: 205,
            child: Text(
              'TestFoor',
              style: AppTextTokens.securityReportDeviceName(
                Theme.of(context).textTheme,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SecurityReportCard extends StatelessWidget {
  const SecurityReportCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.securityCenterCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class CycleSummaryCard extends StatelessWidget {
  const CycleSummaryCard({this.showWarning = false, super.key});

  final bool showWarning;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SecurityReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'TestFoor',
                  style: AppTextTokens.securityCenterCardTitle(textTheme),
                ),
              ),
              Icon(
                showWarning ? Icons.error : Icons.check_circle,
                size: 18,
                color: showWarning
                    ? AppColors.securityReportWarning
                    : AppColors.securityCenterSuccess,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Metric(value: '3', label: 'Operated cycles'),
              ),
              const SizedBox(
                height: 45,
                child: VerticalDivider(color: AppColors.securityReportDivider),
              ),
              const Expanded(
                child: _Metric(
                  value: '--',
                  label: 'Remaining cycles',
                  alignEnd: true,
                ),
              ),
            ],
          ),
          if (showWarning) ...[
            const SizedBox(height: 12),
            Text(
              'Operation cycle alerts are disabled. We recommend enabling them.',
              style: AppTextTokens.securityReportWarning(textTheme),
            ),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.value,
    required this.label,
    this.alignEnd = false,
  });

  final String value;
  final String label;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTextTokens.securityReportMetric(
            Theme.of(context).textTheme,
          ),
        ),
        Text(
          label,
          style: AppTextTokens.securityReportLabel(Theme.of(context).textTheme),
        ),
      ],
    );
  }
}

enum BalanceEvaluation { open, close }

class BalanceEvaluationCard extends StatelessWidget {
  const BalanceEvaluationCard({
    required this.selection,
    this.onChanged,
    super.key,
  });

  final BalanceEvaluation selection;
  final ValueChanged<BalanceEvaluation>? onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SecurityReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(title: 'Door balance evaluation'),
          const SizedBox(height: 4),
          Text(
            "Mark: Evaluation is limited to the door's latest open/close operation.",
            style: AppTextTokens.securityReportValue(
              textTheme,
            ).copyWith(fontSize: 11),
          ),
          const SizedBox(height: 14),
          ReportSegmentedControl<BalanceEvaluation>(
            selected: selection,
            options: const {
              BalanceEvaluation.open: 'Open evaluation',
              BalanceEvaluation.close: 'Close evaluation',
            },
            onChanged: onChanged,
          ),
          const SizedBox(height: 16),
          _BalanceTable(
            key: ValueKey<BalanceEvaluation>(selection),
            selection: selection,
          ),
        ],
      ),
    );
  }
}

class _BalanceTable extends StatelessWidget {
  const _BalanceTable({required this.selection, super.key});

  final BalanceEvaluation selection;

  @override
  Widget build(BuildContext context) {
    const ranges = [
      '80% - 100%',
      '60% - 80%',
      '40% - 60%',
      '20% - 40%',
      '0 - 20%',
    ];
    final selectedRow = selection == BalanceEvaluation.open ? 2 : 3;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 32,
          child: Padding(
            padding: EdgeInsets.only(top: 18.0 + selectedRow * 35),
            child: Icon(
              selection == BalanceEvaluation.open
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              color: AppColors.securityCenterLink,
              size: 25,
            ),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              for (final range in ranges)
                SizedBox(
                  height: 35,
                  child: Row(
                    children: [
                      Expanded(child: Center(child: Text(range))),
                      const VerticalDivider(
                        width: 1,
                        color: AppColors.securityReportDivider,
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            '--',
                            style: TextStyle(color: AppColors.textHint),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

enum RecordRange { last24Hours, last7Days }

class OperationChartCard extends StatelessWidget {
  const OperationChartCard({required this.range, this.onChanged, super.key});

  final RecordRange range;
  final ValueChanged<RecordRange>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SecurityReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(title: 'Door operation record'),
          const SizedBox(height: 14),
          ReportSegmentedControl<RecordRange>(
            selected: range,
            options: const {
              RecordRange.last24Hours: 'Last 24 hours',
              RecordRange.last7Days: 'Last 7 days',
            },
            onChanged: onChanged,
          ),
          const SizedBox(height: 16),
          Text(
            range == RecordRange.last24Hours
                ? 'X: Time Y: Operation cycles'
                : 'X: Date Y: Operation cycles',
            style: AppTextTokens.securityReportLabel(
              Theme.of(context).textTheme,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            key: ValueKey<RecordRange>(range),
            height: 190,
            width: double.infinity,
            child: CustomPaint(painter: _OperationChartPainter(range)),
          ),
        ],
      ),
    );
  }
}

class _OperationChartPainter extends CustomPainter {
  const _OperationChartPainter(this.range);

  final RecordRange range;

  @override
  void paint(Canvas canvas, Size size) {
    final axis = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final grid = Paint()
      ..color = AppColors.securityReportChartGrid
      ..strokeWidth = 0.8;
    final chart = Rect.fromLTWH(28, 5, size.width - 34, size.height - 30);
    canvas.drawRect(chart, axis);
    for (final value in [0.38, 0.69]) {
      final y = chart.bottom - chart.height * value;
      for (double x = chart.left; x < chart.right; x += 12) {
        canvas.drawLine(
          Offset(x, y),
          Offset((x + 6).clamp(x, chart.right), y),
          grid,
        );
      }
    }
    final bar = Paint()..color = AppColors.securityReportChartBar;
    final x = range == RecordRange.last24Hours
        ? chart.left + chart.width * 0.34
        : chart.left + chart.width * 0.92;
    final height = range == RecordRange.last24Hours
        ? chart.height * 0.45
        : chart.height * 0.62;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, chart.bottom - height, 8, height),
        const Radius.circular(2),
      ),
      bar,
    );
    final labels = range == RecordRange.last24Hours
        ? List.generate(8, (index) => '${index * 3}')
        : const ['07-03', '07-04', '07-05', '07-06', '07-07', '07-08', '07-09'];
    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    for (var index = 0; index < labels.length; index++) {
      painter.text = TextSpan(
        text: labels[index],
        style: const TextStyle(fontSize: 7, color: AppColors.textMuted),
      );
      painter.layout();
      final dx =
          chart.left +
          chart.width * index / (labels.length - 1) -
          painter.width / 2;
      painter.paint(canvas, Offset(dx, chart.bottom + 5));
    }
  }

  @override
  bool shouldRepaint(covariant _OperationChartPainter oldDelegate) {
    return oldDelegate.range != range;
  }
}

class ReportSegmentedControl<T> extends StatelessWidget {
  const ReportSegmentedControl({
    required this.selected,
    required this.options,
    this.onChanged,
    super.key,
  });

  final T selected;
  final Map<T, String> options;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.securityReportSegmentTrack,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          for (final option in options.entries)
            Expanded(
              child: Semantics(
                button: true,
                selected: option.key == selected,
                child: InkWell(
                  key: ValueKey<String>('segment-${option.value}'),
                  onTap: onChanged == null
                      ? null
                      : () => onChanged!(option.key),
                  splashFactory: NoSplash.splashFactory,
                  highlightColor: Colors.transparent,
                  borderRadius: BorderRadius.circular(28),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: option.key == selected
                          ? AppColors.securityReportSegmentSelected
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Text(
                      option.value,
                      textAlign: TextAlign.center,
                      style:
                          AppTextTokens.securityReportBody(
                            Theme.of(context).textTheme,
                          ).copyWith(
                            color: option.key == selected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: option.key == selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MotorFunctionStatusCard extends StatelessWidget {
  const MotorFunctionStatusCard({super.key});

  static const values = <String, String>{
    'Door opening force': 'Level 5',
    'Door closing force': 'Level 3',
    'Auto close time': 'Off',
    'Auto close condition': 'Top position',
    'LED off delay': '3min',
    'Partial open': '0cm',
    'Ignore obstruction height': '1cm',
    'Photo beam function': 'Off',
    'Community mode': 'Off',
    'Wired E-lock': 'Off',
  };

  @override
  Widget build(BuildContext context) {
    return SecurityReportCard(
      child: Column(
        children: [
          const _CardHeading(
            title: 'Motor function status',
            trailing: Icon(Icons.keyboard_arrow_down),
          ),
          const SizedBox(height: 14),
          for (final entry in values.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: AppTextTokens.securityReportBody(
                        Theme.of(context).textTheme,
                      ),
                    ),
                  ),
                  Text(
                    entry.value,
                    style: AppTextTokens.securityReportValue(
                      Theme.of(context).textTheme,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class SensorStatusCard extends StatelessWidget {
  const SensorStatusCard({
    required this.title,
    required this.sensors,
    super.key,
  });

  final String title;
  final List<String> sensors;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SecurityReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextTokens.securityCenterCardTitle(textTheme)),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SensorCount(
                icon: Icons.link,
                label: 'Normal',
                count: '0',
                color: AppColors.securityReportNormal,
              ),
              _SensorCount(
                icon: Icons.link_off,
                label: 'Disconnect',
                count: '2',
                color: AppColors.securityReportDisconnected,
              ),
              _SensorCount(
                icon: Icons.error,
                label: 'Abnormal',
                count: '0',
                color: AppColors.securityReportAbnormal,
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final sensor in sensors)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.securityCenterBackground,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.sensors,
                    size: 19,
                    color: AppColors.securityCenterSensorIcon,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sensor,
                          style: AppTextTokens.securityReportBody(textTheme),
                        ),
                        Text(
                          'Disconnect',
                          style: AppTextTokens.securityReportLabel(textTheme),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class SafetySuggestionCard extends StatelessWidget {
  const SafetySuggestionCard({this.onSave, this.onShare, super.key});

  final VoidCallback? onSave;
  final VoidCallback? onShare;

  static const suggestions = <String>[
    'Operated cycles has reached the maintenance warning;',
    'Battery power of safety edge is low, replace it in time;',
    'Contact your installer for a necessary maintenance to ensure the safety of the door.',
    'The opening current of your opener exceeds the maximum value we set.',
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SecurityReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Safety suggestion:',
            style: AppTextTokens.securityCenterCardTitle(textTheme),
          ),
          const SizedBox(height: 6),
          for (var index = 0; index < suggestions.length; index++)
            Text(
              '${index + 1}. ${suggestions[index]}',
              style: AppTextTokens.securityReportSuggestion(textTheme),
            ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SuggestionAction(
                icon: Icons.save_outlined,
                label: 'Save',
                onTap: onSave,
              ),
              const SizedBox(width: 18),
              _SuggestionAction(
                icon: Icons.open_in_new,
                label: 'Share',
                onTap: onShare,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuggestionAction extends StatelessWidget {
  const _SuggestionAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: AppColors.securityReportActionSurface,
        borderRadius: BorderRadius.circular(5),
        child: InkWell(
          onTap: onTap,
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: AppColors.textPrimary),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: AppTextTokens.securityReportAction(
                    Theme.of(context).textTheme,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SensorCount extends StatelessWidget {
  const _SensorCount({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        Text(
          label,
          style: AppTextTokens.securityReportLabel(Theme.of(context).textTheme),
        ),
        const SizedBox(height: 4),
        Text(
          count,
          style: AppTextTokens.securityReportBody(Theme.of(context).textTheme),
        ),
      ],
    );
  }
}

class _CardHeading extends StatelessWidget {
  const _CardHeading({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextTokens.securityCenterCardTitle(
              Theme.of(context).textTheme,
            ),
          ),
        ),
        trailing ??
            const Icon(
              Icons.check_circle,
              color: AppColors.securityCenterSuccess,
              size: 18,
            ),
      ],
    );
  }
}
