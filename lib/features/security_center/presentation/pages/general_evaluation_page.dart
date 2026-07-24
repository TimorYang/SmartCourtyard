import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';
import '../../application/general_evaluation_controller.dart';
import '../widgets/security_report_widgets.dart';

class GeneralEvaluationPage extends ConsumerStatefulWidget {
  const GeneralEvaluationPage({this.doorId = '', this.deviceId = '', super.key});

  static const routeName = 'general-evaluation';
  static const routePath = '/general-evaluation';

  final String doorId;
  final String deviceId;

  @override
  ConsumerState<GeneralEvaluationPage> createState() => _GeneralEvaluationPageState();
}

class _GeneralEvaluationPageState extends ConsumerState<GeneralEvaluationPage> {
  BalanceEvaluation _balance = BalanceEvaluation.open;
  RecordRange _recordRange = RecordRange.last7Days;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(generalEvaluationControllerProvider.notifier).load(doorId: widget.doorId));
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(generalEvaluationControllerProvider);
    return reportState.when(
      loading: () => _stateScaffold(const Center(child: CircularProgressIndicator())),
      error: (_, _) => _stateScaffold(
        Center(
          child: TextButton(
            onPressed: () => ref.read(generalEvaluationControllerProvider.notifier).load(doorId: widget.doorId),
            child: Text(AppLocalizations.of(context).generalEvaluationLoadFailed),
          ),
        ),
      ),
      data: (report) => _buildReport(context, report),
    );
  }

  Widget _buildReport(BuildContext context, dynamic report) {
    final balanceEvaluation = _balance == BalanceEvaluation.open ? report.openBalanceEvaluation : report.closeBalanceEvaluation;
    final operationRecord = _recordRange == RecordRange.last24Hours ? report.last24HoursRecord : report.last7DaysRecord;

    return Scaffold(
      backgroundColor: AppColors.securityCenterBackground,
      appBar: FlinxNavigationBar(title: AppLocalizations.of(context).securityCenterGeneralEvaluation, showBottomDivider: false),
      body: SingleChildScrollView(
        key: const ValueKey<String>('general-evaluation-scroll'),
        child: Stack(
          children: [
            const Positioned(top: 150, left: 0, right: 0, child: SecurityReportBlueBackdrop()),
            Column(
              children: [
                SecurityReportHero(motorName: report.motorName, serialNumber: '', needsMaintenance: report.cycleSummary.needsMaintenance),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      CycleSummaryCard(summary: report.cycleSummary),
                      const SizedBox(height: 16),
                      BalanceEvaluationCard(
                        selection: _balance,
                        evaluation: report.balancePending ? null : balanceEvaluation,
                        onChanged: (value) => setState(() => _balance = value),
                      ),
                      const SizedBox(height: 22),
                      OperationChartCard(range: _recordRange, record: operationRecord, onChanged: (value) => setState(() => _recordRange = value)),
                      const SizedBox(height: 16),
                      MotorFunctionStatusCard(status: report.motorFunctionStatus),
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

  Widget _stateScaffold(Widget body) => Scaffold(
    backgroundColor: AppColors.securityCenterBackground,
    appBar: FlinxNavigationBar(title: AppLocalizations.of(context).securityCenterGeneralEvaluation, showBottomDivider: false),
    body: body,
  );
}
