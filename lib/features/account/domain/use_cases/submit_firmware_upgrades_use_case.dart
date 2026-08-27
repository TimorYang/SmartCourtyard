import '../entities/upgrade_check.dart';
import '../repositories/upgrade_repository.dart';

class SubmitFirmwareUpgradesUseCase {
  const SubmitFirmwareUpgradesUseCase(this._repository);

  final UpgradeRepository _repository;

  Future<List<FirmwareUpgradeSubmissionResult>> call({
    required UpgradeSchedule schedule,
    required List<FirmwareUpgradeTarget> targets,
    required String requestId,
  }) {
    if (targets.isEmpty || targets.length > 10) {
      throw ArgumentError.value(
        targets.length,
        'targets',
        'A firmware upgrade request must contain 1 to 10 targets.',
      );
    }
    if (targets.map((target) => target.deviceId).toSet().length !=
        targets.length) {
      throw ArgumentError.value(
        targets,
        'targets',
        'A device can appear only once in an upgrade request.',
      );
    }
    if (schedule.mode == UpgradeScheduleMode.postpone) {
      final scheduledAt = schedule.normalizedScheduledAt;
      if (scheduledAt == null || !scheduledAt.isAfter(DateTime.now())) {
        throw ArgumentError.value(
          schedule.scheduledAt,
          'scheduledAt',
          'A scheduled firmware upgrade must use a future minute.',
        );
      }
    }
    return _repository.submitFirmwareUpgrades(
      schedule: schedule,
      targets: targets,
      requestId: requestId,
    );
  }
}
