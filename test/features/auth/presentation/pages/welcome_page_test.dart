import 'package:flinx/app/flinx_app.dart';
import 'package:flinx/features/account/application/providers.dart';
import 'package:flinx/features/account/data/data_sources/account_local_data_source.dart';
import 'package:flinx/features/account/data/data_sources/account_profile_remote_data_source.dart';
import 'package:flinx/features/account/data/data_sources/account_secure_data_source.dart';
import 'package:flinx/features/account/data/dto/account_profile_dto.dart';
import 'package:flinx/features/account/data/dto/account_profile_remote_dto.dart';
import 'package:flinx/features/account/data/dto/app_language_option_dto.dart';
import 'package:flinx/features/account/data/dto/app_region_option_dto.dart';
import 'package:flinx/features/account/domain/entities/account_avatar_code.dart';
import 'package:flinx/features/account/domain/entities/account_token_set.dart';
import 'package:flinx/features/auth/application/providers.dart';
import 'package:flinx/features/auth/domain/entities/auth_session.dart';
import 'package:flinx/features/add_device/domain/entities/add_door_draft.dart';
import 'package:flinx/features/add_device/presentation/widgets/add_door_name_dialog.dart';
import 'package:flinx/features/home/application/providers.dart';
import 'package:flinx/features/device_control/application/device_command_controller.dart';
import 'package:flinx/features/device_control/domain/entities/about_device_info.dart';
import 'package:flinx/features/device_control/domain/entities/door_detail.dart';
import 'package:flinx/features/device_control/domain/entities/door_device.dart';
import 'package:flinx/features/device_control/domain/repositories/door_detail_repository.dart';
import 'package:flinx/features/home/domain/entities/home_scene.dart';
import 'package:flinx/features/notification/application/providers.dart'
    as notification;
import 'package:flinx/features/settings/application/providers.dart' as settings;
import 'package:flinx/features/settings/domain/entities/device_capability.dart';
import 'package:flinx/features/settings/domain/entities/door_setting_snapshot.dart';
import 'package:flinx/features/settings/domain/repositories/device_capability_repository.dart';
import 'package:flinx/features/settings/domain/repositories/door_settings_repository.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flinx/platform_bridge/mock_hardware_gateway.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const homeSceneFixtures = [
    HomeScene(id: 1, name: 'Home', doorCount: 2, isDefault: true),
  ];

  const homeDeviceFixtures = [
    DeviceSummary(
      id: 'door-1',
      name: 'Garage door',
      onlineState: DeviceOnlineState.online,
      bleState: BleConnectionState.connected,
      doorState: DoorState.closing,
      cycleCount: 8,
      remainingLifePercent: 96,
      sceneId: 1,
    ),
    DeviceSummary(
      id: 'door-2',
      name: 'Roller door',
      onlineState: DeviceOnlineState.offline,
      bleState: BleConnectionState.disconnected,
      doorState: DoorState.open,
      cycleCount: 12,
      remainingLifePercent: 89,
      sceneId: 1,
    ),
  ];

  Future<void> pumpSignedInApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(
            (ref) async =>
                const AuthSession(isAuthenticated: true, userId: 'test-user'),
          ),
          homeScenesProvider.overrideWith((ref) async => homeSceneFixtures),
          homeDevicesProvider.overrideWith((ref) async => homeDeviceFixtures),
          notification.notificationUnreadStateProvider.overrideWith(
            (ref) async => false,
          ),
          accountProfileRemoteDataSourceProvider.overrideWithValue(
            _FakeAccountProfileRemoteDataSource(),
          ),
          doorDetailRepositoryProvider.overrideWithValue(
            const _FakeDoorDetailRepository(),
          ),
          deviceCommandHardwareGatewayProvider.overrideWithValue(
            MockHardwareGateway(),
          ),
          settings.deviceCapabilityRepositoryProvider.overrideWithValue(
            const _FakeDeviceCapabilityRepository(),
          ),
          settings.doorSettingsRepositoryProvider.overrideWithValue(
            const _FakeDoorSettingsRepository(),
          ),
        ],
        child: const FlinxApp(),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('opens login page from welcome page', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notification.notificationUnreadStateProvider.overrideWith(
            (ref) async => false,
          ),
        ],
        child: const FlinxApp(),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your email address'), findsOneWidget);
  });

  testWidgets('keeps home shortcut protected while signed out', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notification.notificationUnreadStateProvider.overrideWith(
            (ref) async => false,
          ),
        ],
        child: const FlinxApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Start your\nsmart life'), findsOneWidget);
    expect(find.text('2 Doors'), findsNothing);
  });

  testWidgets('opens device command page from home shortcut device card', (
    tester,
  ) async {
    await pumpSignedInApp(tester);

    await tester.tap(find.text('Garage door').first);
    for (var attempt = 0; attempt < 5; attempt += 1) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Operated cycles'), findsOneWidget);
    expect(find.byTooltip('More'), findsOneWidget);
    expect(find.text('Login'), findsNothing);
  });

  testWidgets('opens account profile page from the home avatar', (
    tester,
  ) async {
    await pumpSignedInApp(tester);

    await tester.tap(find.byTooltip('Account profile'));
    await tester.pumpAndSettle();

    expect(find.text('739059568@qq.com'), findsOneWidget);
    expect(find.text('Shared devices'), findsOneWidget);
    expect(find.text('Region'), findsOneWidget);
  });

  testWidgets('shows home device cards when doors are loaded', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(
            (ref) async =>
                const AuthSession(isAuthenticated: true, userId: 'test-user'),
          ),
          homeScenesProvider.overrideWith((ref) async => homeSceneFixtures),
          homeDevicesProvider.overrideWith((ref) async => homeDeviceFixtures),
          notification.notificationUnreadStateProvider.overrideWith(
            (ref) async => false,
          ),
        ],
        child: const FlinxApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('2 Doors'), findsOneWidget);
    expect(find.text('Garage door'), findsOneWidget);
    expect(find.text('Closing'), findsOneWidget);
    expect(find.text('Roller door'), findsOneWidget);
    expect(find.text('Opened'), findsOneWidget);
    expect(find.text('No doors'), findsNothing);
  });

  testWidgets('opens device editing sheet from home device long press', (
    tester,
  ) async {
    await pumpSignedInApp(tester);

    await tester.longPress(find.text('Roller door'));
    await tester.pumpAndSettle();

    expect(find.text('Device editing'), findsOneWidget);
    expect(find.text('Top'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Move Scene'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Delete Device'), findsOneWidget);
    expect(find.text('Customize'), findsOneWidget);
  });

  testWidgets('opens choose scene page from device editing move scene action', (
    tester,
  ) async {
    await pumpSignedInApp(tester);

    await tester.longPress(find.text('Roller door'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Move Scene'));
    await tester.pumpAndSettle();

    expect(find.text('CHOOSE A SCENE'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('333/TestFoor'), findsNothing);
    expect(find.text('2222'), findsNothing);
    expect(find.text('Device editing'), findsNothing);
  });

  testWidgets('closes choose scene page after selecting a scene', (
    tester,
  ) async {
    await pumpSignedInApp(tester);

    await tester.longPress(find.text('Roller door'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Move Scene'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();

    expect(find.text('CHOOSE A SCENE'), findsNothing);
    expect(find.text('Welcome'), findsOneWidget);
  });

  testWidgets('opens device name dialog from device editing name action', (
    tester,
  ) async {
    await pumpSignedInApp(tester);

    await tester.longPress(find.text('Roller door'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Name'));
    await tester.pumpAndSettle();

    expect(find.text('Device Name'), findsOneWidget);
    expect(find.text('Input Device Name'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('confirm'), findsOneWidget);
    expect(find.text('Device editing'), findsNothing);
  });

  testWidgets('opens device delete dialog from device editing delete action', (
    tester,
  ) async {
    await pumpSignedInApp(tester);

    await tester.longPress(find.text('Roller door'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete Device'));
    await tester.pumpAndSettle();

    expect(find.text('Are you sure to delete the device ?'), findsOneWidget);
    expect(find.text('No'), findsOneWidget);
    expect(find.text('Yes'), findsOneWidget);
    expect(find.text('Device editing'), findsNothing);
  });

  testWidgets('opens customize dialog from device editing customize action', (
    tester,
  ) async {
    await pumpSignedInApp(tester);

    await tester.longPress(find.text('Roller door'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Customize'));
    await tester.pumpAndSettle();

    expect(find.text('Customize'), findsOneWidget);
    expect(find.text('Change picture'), findsOneWidget);
    expect(find.text('Default picture'), findsOneWidget);
    expect(find.text('Device editing'), findsNothing);
  });

  testWidgets('shows home add menu from header add action', (tester) async {
    await pumpSignedInApp(tester);

    await tester.tap(find.byTooltip('Add door'));
    await tester.pumpAndSettle();

    expect(find.text('Add Scene'), findsOneWidget);
    expect(find.text('Add Door'), findsOneWidget);

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(find.text('Add Scene'), findsNothing);
    expect(find.text('Add Door'), findsNothing);
  });

  testWidgets('opens scene name dialog from home add scene menu action', (
    tester,
  ) async {
    await pumpSignedInApp(tester);

    await tester.tap(find.byTooltip('Add door'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Scene'));
    await tester.pumpAndSettle();

    expect(find.text('Scene Name'), findsOneWidget);
    expect(find.text('Input scene name'), findsOneWidget);
    expect(find.text('SCENE'), findsNothing);
  });

  testWidgets('opens add new doors page from home add door menu action', (
    tester,
  ) async {
    await pumpSignedInApp(tester);

    await tester.tap(find.byTooltip('Add door'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Door'));
    await tester.pumpAndSettle();

    expect(find.text('Add new doors'), findsOneWidget);
    expect(find.text('Select the door to be added'), findsOneWidget);
    expect(find.text('Garage door'), findsOneWidget);
    expect(find.text('Roller door'), findsOneWidget);
    expect(find.text('Industrial door'), findsOneWidget);

    await tester.drag(find.byType(Scrollable), const Offset(0, -360));
    await tester.pumpAndSettle();

    expect(find.text('Swing gate'), findsOneWidget);
    expect(find.text('Sliding gate'), findsOneWidget);

    await tester.tap(find.text('Swing gate'));
    await tester.pumpAndSettle();

    expect(find.text('Add New Device'), findsOneWidget);
    expect(find.text('Select the device to be added'), findsOneWidget);
    expect(find.text('F-box'), findsWidgets);
    expect(find.text('Smart controller'), findsOneWidget);
    expect(find.text('USB WIFI module'), findsOneWidget);
    expect(find.text('Smart Opener (Built-in Wi-Fi)'), findsOneWidget);
  });

  testWidgets('add door dialog selects a scene and returns its draft', (
    tester,
  ) async {
    const scenes = [
      HomeScene(id: 1, name: 'Home', doorCount: 2, isDefault: true),
      HomeScene(id: 2, name: 'Warehouse', doorCount: 1, isDefault: false),
    ];
    AddDoorDraft? confirmedDraft;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [homeScenesProvider.overrideWith((ref) async => scenes)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AddDoorNameDialog(
            onConfirmed: (draft) => confirmedDraft = draft,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Warehouse'), findsOneWidget);

    await tester.tap(find.text('Warehouse'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Garage door');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
    await tester.pumpAndSettle();

    expect(confirmedDraft?.name, 'Garage door');
    expect(confirmedDraft?.sceneId, 2);
    expect(confirmedDraft?.sceneName, 'Warehouse');
  });

  testWidgets('redirects authenticated users to the home page', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(
            (ref) async =>
                const AuthSession(isAuthenticated: true, userId: 'user-1'),
          ),
          homeScenesProvider.overrideWith((ref) async => homeSceneFixtures),
          homeDevicesProvider.overrideWith((ref) async => homeDeviceFixtures),
          notification.notificationUnreadStateProvider.overrideWith(
            (ref) async => false,
          ),
        ],
        child: const FlinxApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('2 Doors'), findsOneWidget);
    expect(find.text('Login'), findsNothing);
  });

  testWidgets('redirects a restored cold-start session to the home page', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountLocalDataSourceProvider.overrideWithValue(
            InMemoryAccountLocalDataSource(
              initialProfile: const AccountProfileDto(
                schemaVersion: 1,
                userId: 'user-1',
                email: 'user@example.com',
                nickname: 'User',
                registeredAtIso8601: '2026-01-02T03:04:05Z',
              ),
            ),
          ),
          accountSecureDataSourceProvider.overrideWithValue(
            _InitialTokenDataSource(
              AccountTokenSet(
                accessToken: 'valid-access',
                expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
              ),
            ),
          ),
          homeScenesProvider.overrideWith((ref) async => homeSceneFixtures),
          homeDevicesProvider.overrideWith((ref) async => homeDeviceFixtures),
          notification.notificationUnreadStateProvider.overrideWith(
            (ref) async => false,
          ),
        ],
        child: const FlinxApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('2 Doors'), findsOneWidget);
    expect(find.text('Login'), findsNothing);
  });
}

class _FakeDeviceCapabilityRepository implements DeviceCapabilityRepository {
  const _FakeDeviceCapabilityRepository();

  @override
  Future<List<DeviceCapability>> fetchCapabilities({
    required String deviceId,
    required String requestId,
  }) async => const [];
}

class _FakeDoorSettingsRepository implements DoorSettingsRepository {
  const _FakeDoorSettingsRepository();

  @override
  Future<List<DoorSettingSnapshot>> fetchSettings({
    required String doorId,
    required String requestId,
  }) async => const [];
}

class _FakeDoorDetailRepository implements DoorDetailRepository {
  const _FakeDoorDetailRepository();

  @override
  Future<DoorDetail> fetchDoorDetail({
    required String doorId,
    required String requestId,
  }) async => const DoorDetail(
    id: 'door-1',
    name: 'Garage door',
    doorState: DoorState.closed,
    doorStateLabel: 'Closed',
    operatedCycles: 8,
    remainingCycles: 92,
    positionPercent: 50,
  );

  @override
  Future<List<DoorDevice>> fetchDoorDevices({
    required String doorId,
    required String requestId,
  }) async => const [];

  @override
  Future<AboutDeviceInfo> fetchAboutDeviceInfo({
    required String doorId,
    required String deviceId,
    required String requestId,
  }) async => const AboutDeviceInfo(
    deviceId: 'device-1',
    sn: 'test-sn',
    deviceType: 'opener',
    deviceTypeLabel: 'Opener',
    bluetoothName: 'Test opener',
    hardwareVersion: '1.0.0',
    firmwareVersion: '1.0.0',
    updateAvailable: false,
    availableVersion: '',
  );

  @override
  Future<void> unbindDoorDevice({
    required String doorId,
    required String deviceId,
    required String requestId,
  }) async {}
}

class _InitialTokenDataSource extends InMemoryAccountSecureDataSource {
  _InitialTokenDataSource(this.initialTokenSet);

  final AccountTokenSet initialTokenSet;

  @override
  Future<AccountTokenSet?> readTokenSet() async => initialTokenSet;
}

class _FakeAccountProfileRemoteDataSource
    implements AccountProfileRemoteDataSource {
  @override
  Future<AccountProfileRemoteDto> fetchProfile({
    required String requestId,
  }) async => const AccountProfileRemoteDto(
    userId: 'test-user',
    email: '739059568@qq.com',
    emailVerified: true,
    nickname: '',
  );

  @override
  Future<List<AppRegionOptionDto>> fetchRegionOptions({
    required String requestId,
  }) async => const [
    AppRegionOptionDto(regionCode: 'GB', displayName: 'England'),
  ];

  @override
  Future<List<AppLanguageOptionDto>> fetchLanguageOptions({
    required String requestId,
  }) async => const [];

  @override
  Future<int> uploadImage({
    required List<int> bytes,
    required String fileName,
    required String requestId,
  }) => throw UnimplementedError();

  @override
  Future<void> updateProfile({
    String? nickname,
    AccountAvatarCode? avatarCode,
    int? avatarFileId,
    String? regionCode,
    String? locale,
    required String requestId,
  }) async {}

  @override
  Future<void> updateAvatar({
    AccountAvatarCode? avatarCode,
    int? avatarFileId,
    required String requestId,
  }) async {}

  @override
  Future<void> updateNickname({
    required String nickname,
    required String requestId,
  }) async {}

  @override
  Future<void> updateRegion({
    required String regionCode,
    required String requestId,
  }) async {}

  @override
  Future<void> updateLanguage({
    required String locale,
    required String requestId,
  }) async {}

  @override
  Future<void> confirmAccountDeletion({required String requestId}) async {}
}
