import 'package:flinx/features/account/domain/entities/upgrade_check.dart';
import 'package:flinx/features/account/domain/repositories/upgrade_repository.dart';
import 'package:flinx/features/account/domain/use_cases/submit_firmware_upgrades_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rejects empty, oversized, and duplicate-device submissions', () {
    final useCase = SubmitFirmwareUpgradesUseCase(_FakeUpgradeRepository());
    final target = _target(deviceId: '1', releaseId: '10');

    expect(
      () => useCase(
        schedule: const UpgradeSchedule(mode: UpgradeScheduleMode.immediate),
        targets: const [],
        requestId: 'empty',
      ),
      throwsArgumentError,
    );
    expect(
      () => useCase(
        schedule: const UpgradeSchedule(mode: UpgradeScheduleMode.immediate),
        targets: List.generate(
          11,
          (index) => _target(deviceId: '$index', releaseId: '${100 + index}'),
        ),
        requestId: 'oversized',
      ),
      throwsArgumentError,
    );
    expect(
      () => useCase(
        schedule: const UpgradeSchedule(mode: UpgradeScheduleMode.immediate),
        targets: [
          target,
          _target(deviceId: '1', releaseId: '11'),
        ],
        requestId: 'duplicate-device',
      ),
      throwsArgumentError,
    );
  });

  test('rejects scheduled upgrades that are not in a future minute', () {
    final useCase = SubmitFirmwareUpgradesUseCase(_FakeUpgradeRepository());

    expect(
      () => useCase(
        schedule: UpgradeSchedule(
          mode: UpgradeScheduleMode.postpone,
          scheduledAt: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
        targets: [_target(deviceId: '1', releaseId: '10')],
        requestId: 'past-schedule',
      ),
      throwsArgumentError,
    );
  });
}

FirmwareUpgradeTarget _target({
  required String deviceId,
  required String releaseId,
}) {
  return FirmwareUpgradeTarget(
    deviceId: deviceId,
    firmwareReleaseId: releaseId,
    serialNumber: 'SN-$deviceId',
    currentVersion: '1.0.0',
    deviceType: 'opener',
    deviceTypeLabel: 'Opener',
    packageSizeBytes: 1024,
    availableVersion: '1.1.0',
    lastFirmwareUpgradedAt: null,
    status: FirmwareUpgradeStatus.available,
    scheduledAt: null,
    upgradeExpireAt: null,
  );
}

class _FakeUpgradeRepository implements UpgradeRepository {
  @override
  Future<AppReleaseUpdate> checkAppRelease({required String requestId}) {
    throw UnimplementedError();
  }

  @override
  Future<List<FirmwareUpgradeDoor>> fetchFirmwareUpgrades({
    required String requestId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, int>> readProgresses({required String userId}) {
    throw UnimplementedError();
  }

  @override
  Future<void> replaceProgresses({
    required String userId,
    required Map<String, int> progresses,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<FirmwareUpgradeSubmissionResult>> submitFirmwareUpgrades({
    required UpgradeSchedule schedule,
    required List<FirmwareUpgradeTarget> targets,
    required String requestId,
  }) async {
    return const [];
  }
}
