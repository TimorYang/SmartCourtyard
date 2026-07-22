import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/providers.dart';
import '../widgets/security_report_widgets.dart';

class GeneralEvaluationPage extends ConsumerStatefulWidget {
  const GeneralEvaluationPage({required this.deviceId, super.key});

  static const routeName = 'general-evaluation';
  static const routePath = '/general-evaluation';

  final String deviceId;

  @override
  ConsumerState<GeneralEvaluationPage> createState() =>
      _GeneralEvaluationPageState();
}

class _GeneralEvaluationPageState extends ConsumerState<GeneralEvaluationPage> {
  BalanceEvaluation _balance = BalanceEvaluation.open;
  RecordRange _recordRange = RecordRange.last24Hours;

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(fullReportProvider(widget.deviceId));
    final balanceEvaluation = _balance == BalanceEvaluation.open
        ? report.openBalanceEvaluation
        : report.closeBalanceEvaluation;
    final operationRecord = _recordRange == RecordRange.last24Hours
        ? report.last24HoursRecord
        : report.last7DaysRecord;

    return Scaffold(
      backgroundColor: AppColors.securityCenterBackground,
      appBar: FlinxNavigationBar(
        title: AppLocalizations.of(context).securityCenterGeneralEvaluation,
        showBottomDivider: false,
      ),
      body: SingleChildScrollView(
        key: const ValueKey<String>('general-evaluation-scroll'),
        child: Stack(
          children: [
            const Positioned(
              top: 150,
              left: 0,
              right: 0,
              child: SecurityReportBlueBackdrop(),
            ),
            Column(
              children: [
                SecurityReportHero(
                  motorName: report.motorName,
                  serialNumber: report.serialNumber,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      CycleSummaryCard(summary: report.cycleSummary),
                      const SizedBox(height: 16),
                      BalanceEvaluationCard(
                        selection: _balance,
                        evaluation: balanceEvaluation,
                        onChanged: (value) => setState(() => _balance = value),
                      ),
                      const SizedBox(height: 22),
                      OperationChartCard(
                        range: _recordRange,
                        record: operationRecord,
                        onChanged: (value) =>
                            setState(() => _recordRange = value),
                      ),
                      const SizedBox(height: 16),
                      MotorFunctionStatusCard(
                        status: report.motorFunctionStatus,
                      ),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
