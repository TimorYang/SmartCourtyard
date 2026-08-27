import '../entities/upgrade_check.dart';

abstract interface class UpgradeRepository {
  Future<AppReleaseUpdate> checkAppRelease({required String requestId});

  Future<List<FirmwareUpgradeDoor>> fetchFirmwareUpgrades({
    required String requestId,
  });

  Future<List<FirmwareUpgradeSubmissionResult>> submitFirmwareUpgrades({
    required UpgradeSchedule schedule,
    required List<FirmwareUpgradeTarget> targets,
    required String requestId,
  });

  Future<Map<String, int>> readProgresses({required String userId});

  Future<void> replaceProgresses({
    required String userId,
    required Map<String, int> progresses,
  });
}
