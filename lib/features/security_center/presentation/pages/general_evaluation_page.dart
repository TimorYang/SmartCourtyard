import 'package:flutter/material.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../widgets/security_report_widgets.dart';

class GeneralEvaluationPage extends StatefulWidget {
  const GeneralEvaluationPage({required this.deviceId, super.key});

  static const routeName = 'general-evaluation';
  static const routePath = '/general-evaluation';

  final String deviceId;

  @override
  State<GeneralEvaluationPage> createState() => _GeneralEvaluationPageState();
}

class _GeneralEvaluationPageState extends State<GeneralEvaluationPage> {
  BalanceEvaluation _balance = BalanceEvaluation.open;
  RecordRange _recordRange = RecordRange.last7Days;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.securityCenterBackground,
      appBar: const FlinxNavigationBar(
        title: 'General Evaluation',
        showBottomDivider: false,
      ),
      body: ListView(
        key: const ValueKey<String>('general-evaluation-scroll'),
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          const SecurityReportHero(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const CycleSummaryCard(showWarning: true),
                const SizedBox(height: 20),
                BalanceEvaluationCard(
                  selection: _balance,
                  onChanged: (value) => setState(() => _balance = value),
                ),
                const SizedBox(height: 20),
                OperationChartCard(
                  range: _recordRange,
                  onChanged: (value) => setState(() => _recordRange = value),
                ),
                const SizedBox(height: 20),
                const MotorFunctionStatusCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
