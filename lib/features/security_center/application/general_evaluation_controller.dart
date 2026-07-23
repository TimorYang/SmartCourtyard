import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/logging/providers.dart';
import '../domain/entities/general_evaluation_report.dart';
import 'providers.dart';
import 'security_balance_refresh_controller.dart';

final generalEvaluationControllerProvider =
    NotifierProvider<
      GeneralEvaluationController,
      AsyncValue<GeneralEvaluationReport>
    >(GeneralEvaluationController.new);

class GeneralEvaluationController
    extends Notifier<AsyncValue<GeneralEvaluationReport>> {
  late final AppLogger _logger;

  @override
  AsyncValue<GeneralEvaluationReport> build() {
    _logger = ref.watch(appLoggerProvider);
    return const AsyncLoading();
  }

  Future<void> load({required String doorId}) async {
    final assessmentRequestId = ref
        .read(securityBalanceRefreshControllerProvider)
        .serverRequestId;
    final requestId =
        'general-evaluation-$doorId-${DateTime.now().millisecondsSinceEpoch}';
    state = const AsyncLoading();
    try {
      state = AsyncData(
        await ref.read(fetchGeneralEvaluationUseCaseProvider)(
          doorId: doorId,
          assessmentRequestId: assessmentRequestId,
          requestId: requestId,
        ),
      );
    } catch (error, stackTrace) {
      _logger.error(
        'General evaluation load failed after successful request dispatch',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {
          'doorId': doorId,
          'hasAssessmentRequestId':
              assessmentRequestId != null && assessmentRequestId.isNotEmpty,
          'errorType': error.runtimeType.toString(),
          // This is intentionally limited to Dart conversion/format failures.
          // It identifies the offending field without logging response bodies.
          'conversionError': switch (error) {
            TypeError() || FormatException() => error.toString(),
            _ => null,
          },
        },
      );
      state = AsyncError(error, stackTrace);
    }
  }
}
