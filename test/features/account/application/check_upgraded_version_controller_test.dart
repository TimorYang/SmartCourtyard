import 'package:flinx/features/account/application/check_upgraded_version_controller.dart';
import 'package:flinx/features/account/application/providers.dart';
import 'package:flinx/features/account/domain/entities/account_profile.dart';
import 'package:flinx/features/account/domain/entities/upgrade_check.dart';
import 'package:flinx/features/account/domain/repositories/upgrade_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'restores only active upgrading progress for the current user',
    () async {
      final target = _target(
        deviceId: '101',
        releaseId: '1001',
        status: FirmwareUpgradeStatus.upgrading,
      );
      final repository = _FakeUpgradeRepository(
        doors: [
          _door([target]),
        ],
        progresses: {target.key: 42, 'stale:release': 88},
      );
      final container = _container(repository);
      addTearDown(container.dispose);
      final subscription = container.listen(
        checkUpgradedVersionControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);

      final state = await container.read(
        checkUpgradedVersionControllerProvider.future,
      );

      expect(state.progressByTarget, {target.key: 42});
      expect(repository.lastUserId, 'user-7');
      expect(repository.savedProgresses, {target.key: 42});
    },
  );

  test('enforces the ten-target selection limit', () async {
    final targets = List.generate(
      11,
      (index) =>
          _target(deviceId: '${100 + index}', releaseId: '${1000 + index}'),
    );
    final repository = _FakeUpgradeRepository(doors: [_door(targets)]);
    final container = _container(repository);
    addTearDown(container.dispose);
    final subscription = container.listen(
      checkUpgradedVersionControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    await container.read(checkUpgradedVersionControllerProvider.future);
    final controller = container.read(
      checkUpgradedVersionControllerProvider.notifier,
    );

    for (final target in targets.take(10)) {
      expect(
        controller.toggleTarget(target.key),
        UpgradeSelectionResult.changed,
      );
    }

    expect(
      controller.toggleTarget(targets.last.key),
      UpgradeSelectionResult.limitReached,
    );
    expect(
      container
          .read(checkUpgradedVersionControllerProvider)
          .requireValue
          .selectedTargetKeys,
      hasLength(10),
    );
  });

  test('starts progress only for accepted immediate upgrades', () async {
    final accepted = _target(deviceId: '101', releaseId: '1001');
    final rejected = _target(deviceId: '102', releaseId: '1002');
    final repository = _FakeUpgradeRepository(
      doors: [
        _door([accepted, rejected]),
      ],
      submitResults: [
        _submission(accepted, accepted: true),
        _submission(rejected, accepted: false),
      ],
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    final subscription = container.listen(
      checkUpgradedVersionControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    await container.read(checkUpgradedVersionControllerProvider.future);
    final controller = container.read(
      checkUpgradedVersionControllerProvider.notifier,
    );
    controller.toggleTarget(accepted.key);
    controller.toggleTarget(rejected.key);

    final result = await controller.submitFirmwareUpgrades(
      const UpgradeSchedule(mode: UpgradeScheduleMode.immediate),
    );
    final state = container
        .read(checkUpgradedVersionControllerProvider)
        .requireValue;

    expect(result, UpgradeSubmitUiResult.partial);
    expect(state.upgradingEntries.single.target.key, accepted.key);
    expect(state.selectedTargetKeys, {rejected.key});
    expect(state.progressByTarget[accepted.key], 1);
    expect(repository.submittedTargets, [accepted.key, rejected.key]);
  });

  test(
    'does not clear persisted progress when the firmware request fails',
    () async {
      final repository = _FakeUpgradeRepository(
        doors: const [],
        progresses: const {'101:1001': 47},
        fetchError: StateError('offline'),
      );
      final container = _container(repository);
      addTearDown(container.dispose);
      final subscription = container.listen(
        checkUpgradedVersionControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);

      final state = await container.read(
        checkUpgradedVersionControllerProvider.future,
      );

      expect(state.firmwareLoadFailed, isTrue);
      expect(repository.lastUserId, isNull);
      expect(repository.savedProgresses, isNull);
    },
  );
}

ProviderContainer _container(_FakeUpgradeRepository repository) {
  return ProviderContainer(
    overrides: [
      upgradeRepositoryProvider.overrideWithValue(repository),
      cachedAccountProfileProvider.overrideWith(
        (ref) async => AccountProfile(
          userId: 'user-7',
          email: 'user@example.com',
          nickname: 'User',
        ),
      ),
    ],
  );
}

FirmwareUpgradeDoor _door(List<FirmwareUpgradeTarget> targets) {
  return FirmwareUpgradeDoor(
    doorId: 'door-1',
    doorName: 'South Gate',
    upgrades: targets,
  );
}

FirmwareUpgradeTarget _target({
  required String deviceId,
  required String releaseId,
  FirmwareUpgradeStatus status = FirmwareUpgradeStatus.available,
}) {
  return FirmwareUpgradeTarget(
    deviceId: deviceId,
    firmwareReleaseId: releaseId,
    serialNumber: 'SN-$deviceId',
    currentVersion: null,
    deviceType: 'opener',
    deviceTypeLabel: 'Opener',
    packageSizeBytes: 19188941,
    availableVersion: '1.2.5',
    lastFirmwareUpgradedAt: null,
    status: status,
    scheduledAt: null,
    upgradeExpireAt: null,
  );
}

FirmwareUpgradeSubmissionResult _submission(
  FirmwareUpgradeTarget target, {
  required bool accepted,
}) {
  return FirmwareUpgradeSubmissionResult(
    deviceId: target.deviceId,
    firmwareReleaseId: target.firmwareReleaseId,
    accepted: accepted,
    scheduledAt: null,
    upgradeExpireAt: null,
    failureMessage: accepted ? null : 'rejected',
  );
}

class _FakeUpgradeRepository implements UpgradeRepository {
  _FakeUpgradeRepository({
    required this.doors,
    this.progresses = const {},
    this.submitResults = const [],
    this.fetchError,
  });

  final List<FirmwareUpgradeDoor> doors;
  final Map<String, int> progresses;
  final List<FirmwareUpgradeSubmissionResult> submitResults;
  final Object? fetchError;
  String? lastUserId;
  Map<String, int>? savedProgresses;
  List<String> submittedTargets = [];

  @override
  Future<AppReleaseUpdate> checkAppRelease({required String requestId}) async {
    return const AppReleaseUpdate(
      action: AppReleaseAction.none,
      targetVersion: null,
      targetBuildNumber: null,
      publishedAt: null,
      updateUrl: null,
    );
  }

  @override
  Future<List<FirmwareUpgradeDoor>> fetchFirmwareUpgrades({
    required String requestId,
  }) async {
    final error = fetchError;
    if (error != null) throw error;
    return doors;
  }

  @override
  Future<Map<String, int>> readProgresses({required String userId}) async {
    lastUserId = userId;
    return progresses;
  }

  @override
  Future<void> replaceProgresses({
    required String userId,
    required Map<String, int> progresses,
  }) async {
    lastUserId = userId;
    savedProgresses = Map<String, int>.from(progresses);
  }

  @override
  Future<List<FirmwareUpgradeSubmissionResult>> submitFirmwareUpgrades({
    required UpgradeSchedule schedule,
    required List<FirmwareUpgradeTarget> targets,
    required String requestId,
  }) async {
    submittedTargets = targets.map((target) => target.key).toList();
    return submitResults;
  }
}
