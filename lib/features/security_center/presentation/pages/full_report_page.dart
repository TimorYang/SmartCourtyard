import 'package:flutter/material.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../widgets/security_report_widgets.dart';

class FullReportPage extends StatelessWidget {
  const FullReportPage({required this.deviceId, super.key});

  static const routeName = 'full-report';
  static const routePath = '/full-report';

  final String deviceId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.securityCenterBackground,
      appBar: const FlinxNavigationBar(
        title: 'Full Report',
        showBottomDivider: false,
      ),
      body: ListView(
        key: const ValueKey<String>('full-report-scroll'),
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          const SecurityReportHero(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const CycleSummaryCard(),
                const SizedBox(height: 20),
                const BalanceEvaluationCard(selection: BalanceEvaluation.open),
                const SizedBox(height: 20),
                const BalanceEvaluationCard(selection: BalanceEvaluation.close),
                const SizedBox(height: 20),
                const OperationChartCard(range: RecordRange.last24Hours),
                const SizedBox(height: 20),
                const OperationChartCard(range: RecordRange.last7Days),
                const SizedBox(height: 20),
                const MotorFunctionStatusCard(),
                const SizedBox(height: 20),
                const SensorStatusCard(
                  title: 'Wired sensor status',
                  sensors: ['Wired photo beam', 'Wired E-lock'],
                ),
                const SizedBox(height: 20),
                const SensorStatusCard(
                  title: 'Wireless Sensors Status',
                  sensors: [
                    'Wireless Photo Beam',
                    'Wireless wicket door',
                    'Wireless safety edge',
                    'Wireless E-lock',
                    'Wireless rope sensor',
                  ],
                ),
                const SizedBox(height: 20),
                const SafetySuggestionCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
