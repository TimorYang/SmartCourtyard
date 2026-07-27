import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/logging/providers.dart';
import '../domain/entities/safety_sensors_evaluation.dart';
import '../domain/use_cases/fetch_safety_sensors_evaluation_use_case.dart';
import 'providers.dart';

final safetySensorsEvaluationControllerProvider =
    NotifierProvider.family<
      SafetySensorsEvaluationController,
      AsyncValue<SafetySensorsEvaluation>,
      String
    >((doorId) => SafetySensorsEvaluationController());

class SafetySensorsEvaluationController
    extends Notifier<AsyncValue<SafetySensorsEvaluation>> {
  late final AppLogger _logger;
  late final FetchSafetySensorsEvaluationUseCase _fetchEvaluation;
  var _requestCounter = 0;

  @override
  AsyncValue<SafetySensorsEvaluation> build() {
    _logger = ref.watch(appLoggerProvider);
    _fetchEvaluation = ref.watch(fetchSafetySensorsEvaluationUseCaseProvider);
    return const AsyncLoading();
  }

  Future<void> load({required String doorId}) async {
    final requestId =
        'safety-sensors-$doorId-'
        '${DateTime.now().millisecondsSinceEpoch}-${++_requestCounter}';
    state = const AsyncLoading();
    try {
      state = AsyncData(
        await _fetchEvaluation(doorId: doorId, requestId: requestId),
      );
    } catch (error, stackTrace) {
      _logger.error(
        'Safety sensors evaluation load failed',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'doorId': doorId},
      );
      state = AsyncError(error, stackTrace);
    }
  }
}
