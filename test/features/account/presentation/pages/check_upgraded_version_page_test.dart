import 'package:flinx/app/theme/app_theme.dart';
import 'package:flinx/features/account/application/providers.dart';
import 'package:flinx/features/account/domain/entities/account_profile.dart';
import 'package:flinx/features/account/domain/entities/upgrade_check.dart';
import 'package:flinx/features/account/domain/repositories/upgrade_repository.dart';
import 'package:flinx/features/account/data/services/app_update_url_launcher.dart';
import 'package:flinx/features/account/presentation/pages/check_upgraded_version_page.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders API-backed app and door-grouped firmware data', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeUpgradeRepository(
      application: AppReleaseUpdate(
        action: AppReleaseAction.optional,
        targetVersion: '1.2.5',
        targetBuildNumber: '125',
        publishedAt: null,
        updateUrl: Uri.parse(
          'https://play.google.com/store/apps/details?id=flinx',
        ),
      ),
      doors: [
        _door([_target()]),
      ],
    );

    await tester.pumpWidget(_TestApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('App version update'), findsOneWidget);
    expect(
      find.byKey(CheckUpgradedVersionKeys.applicationCard),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    expect(find.text('1.2.5'), findsOneWidget);
    expect(find.text('Available Version : 1.2.5'), findsOneWidget);
    expect(find.text('South Gate'), findsOneWidget);
    expect(find.text('Opener'), findsOneWidget);
    expect(find.text('serial number : SN-101'), findsOneWidget);
    expect(find.text('Current Version : --'), findsOneWidget);
    expect(find.text('18.3 MB'), findsOneWidget);
  });

  testWidgets('opens the app update URL without enabling firmware submission', (
    tester,
  ) async {
    final updateUrl = Uri.parse(
      'https://play.google.com/store/search?q=F-linX&c=apps',
    );
    final launcher = _FakeAppUpdateUrlLauncher();
    final repository = _FakeUpgradeRepository(
      application: AppReleaseUpdate(
        action: AppReleaseAction.force,
        targetVersion: '1.2.5',
        targetBuildNumber: '125',
        publishedAt: null,
        updateUrl: updateUrl,
      ),
    );

    await tester.pumpWidget(
      _TestApp(repository: repository, launcher: launcher),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<FilledButton>(
            find.byKey(CheckUpgradedVersionKeys.startButton),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(CheckUpgradedVersionKeys.applicationCard));
    await tester.pump();

    expect(launcher.openedUrls, [updateUrl]);
    expect(repository.submitCount, 0);
  });

  testWidgets('submits only firmware and advances accepted fake progress', (
    tester,
  ) async {
    final target = _target();
    final repository = _FakeUpgradeRepository(
      application: const AppReleaseUpdate(
        action: AppReleaseAction.optional,
        targetVersion: '1.2.5',
        targetBuildNumber: '125',
        publishedAt: null,
        updateUrl: null,
      ),
      doors: [
        _door([target]),
      ],
      submitResults: [_submission(target)],
    );

    await tester.pumpWidget(_TestApp(repository: repository));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        CheckUpgradedVersionKeys.packageCheckbox('door-1', target.key),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(CheckUpgradedVersionKeys.startButton));
    await tester.pumpAndSettle();

    expect(find.text('South Gate · Opener'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(CheckUpgradedVersionKeys.scheduleDialog),
        matching: find.text('serial number : SN-101'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('postpone'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('immediate').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CheckUpgradedVersionKeys.scheduleConfirm));
    await tester.pumpAndSettle();

    expect(repository.submittedTargetKeys, [target.key]);
    expect(
      find.byKey(CheckUpgradedVersionKeys.progressCard(target.key)),
      findsOneWidget,
    );
    expect(find.text('1%'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));

    expect(find.text('2%'), findsOneWidget);
    expect(find.text('Completed'), findsNothing);

    await tester.pump(const Duration(minutes: 10));

    expect(find.text('99%'), findsOneWidget);
    expect(find.text('100%'), findsNothing);
    expect(repository.progresses, {target.key: 99});
  });

  testWidgets('keeps the middle area blank when neither API has content', (
    tester,
  ) async {
    final repository = _FakeUpgradeRepository();

    await tester.pumpWidget(_TestApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Check the upgraded version'), findsOneWidget);
    expect(find.text('APP'), findsNothing);
    expect(find.text('firmware'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(CheckUpgradedVersionKeys.startButton),
          )
          .onPressed,
      isNull,
    );
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.repository, this.launcher});

  final UpgradeRepository repository;
  final AppUpdateUrlLauncher? launcher;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        upgradeRepositoryProvider.overrideWithValue(repository),
        if (launcher case final launcher?)
          appUpdateUrlLauncherProvider.overrideWithValue(launcher),
        cachedAccountProfileProvider.overrideWith(
          (ref) async => AccountProfile(
            userId: 'user-7',
            email: 'user@example.com',
            nickname: 'User',
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CheckUpgradedVersionPage(),
      ),
    );
  }
}

FirmwareUpgradeDoor _door(List<FirmwareUpgradeTarget> targets) {
  return FirmwareUpgradeDoor(
    doorId: 'door-1',
    doorName: 'South Gate',
    upgrades: targets,
  );
}

FirmwareUpgradeTarget _target() {
  return const FirmwareUpgradeTarget(
    deviceId: '101',
    firmwareReleaseId: '1001',
    serialNumber: 'SN-101',
    currentVersion: null,
    deviceType: 'opener',
    deviceTypeLabel: 'Opener',
    packageSizeBytes: 19188941,
    availableVersion: '1.2.5',
    lastFirmwareUpgradedAt: null,
    status: FirmwareUpgradeStatus.available,
    scheduledAt: null,
    upgradeExpireAt: null,
  );
}

FirmwareUpgradeSubmissionResult _submission(FirmwareUpgradeTarget target) {
  return FirmwareUpgradeSubmissionResult(
    deviceId: target.deviceId,
    firmwareReleaseId: target.firmwareReleaseId,
    accepted: true,
    scheduledAt: null,
    upgradeExpireAt: null,
    failureMessage: null,
  );
}

class _FakeUpgradeRepository implements UpgradeRepository {
  _FakeUpgradeRepository({
    this.application = const AppReleaseUpdate(
      action: AppReleaseAction.none,
      targetVersion: null,
      targetBuildNumber: null,
      publishedAt: null,
      updateUrl: null,
    ),
    this.doors = const [],
    this.submitResults = const [],
  });

  final AppReleaseUpdate application;
  final List<FirmwareUpgradeDoor> doors;
  final List<FirmwareUpgradeSubmissionResult> submitResults;
  var submitCount = 0;
  List<String> submittedTargetKeys = const [];
  Map<String, int> progresses = const {};

  @override
  Future<AppReleaseUpdate> checkAppRelease({required String requestId}) async {
    return application;
  }

  @override
  Future<List<FirmwareUpgradeDoor>> fetchFirmwareUpgrades({
    required String requestId,
  }) async {
    return doors;
  }

  @override
  Future<Map<String, int>> readProgresses({required String userId}) async {
    return progresses;
  }

  @override
  Future<void> replaceProgresses({
    required String userId,
    required Map<String, int> progresses,
  }) async {
    this.progresses = Map<String, int>.from(progresses);
  }

  @override
  Future<List<FirmwareUpgradeSubmissionResult>> submitFirmwareUpgrades({
    required UpgradeSchedule schedule,
    required List<FirmwareUpgradeTarget> targets,
    required String requestId,
  }) async {
    submitCount += 1;
    submittedTargetKeys = targets.map((target) => target.key).toList();
    return submitResults;
  }
}

class _FakeAppUpdateUrlLauncher implements AppUpdateUrlLauncher {
  final List<Uri> openedUrls = [];

  @override
  Future<bool> open(Uri url) async {
    openedUrls.add(url);
    return true;
  }
}
