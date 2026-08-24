import 'package:flinx/app/theme/app_theme.dart';
import 'package:flinx/features/account/application/providers.dart';
import 'package:flinx/features/account/data/data_sources/account_local_data_source.dart';
import 'package:flinx/features/account/data/data_sources/account_profile_remote_data_source.dart';
import 'package:flinx/features/account/data/data_sources/app_locale_local_data_source.dart';
import 'package:flinx/features/account/data/dto/account_profile_dto.dart';
import 'package:flinx/features/account/data/dto/app_language_option_dto.dart';
import 'package:flinx/features/account/data/dto/app_region_option_dto.dart';
import 'package:flinx/features/account/data/dto/account_profile_remote_dto.dart';
import 'package:flinx/features/account/domain/entities/receiving_door.dart';
import 'package:flinx/features/account/domain/entities/account_avatar_code.dart';
import 'package:flinx/features/account/domain/entities/app_language_option.dart';
import 'package:flinx/features/account/domain/entities/system_permission.dart';
import 'package:flinx/features/account/domain/entities/shared_door.dart';
import 'package:flinx/features/account/domain/entities/shared_door_members.dart';
import 'package:flinx/features/account/domain/repositories/receiving_devices_repository.dart';
import 'package:flinx/features/account/domain/repositories/shared_devices_repository.dart';
import 'package:flinx/features/account/presentation/pages/account_details_page.dart';
import 'package:flinx/features/account/presentation/pages/account_profile_page.dart';
import 'package:flinx/features/account/presentation/pages/manage_devices_page.dart';
import 'package:flinx/features/account/presentation/pages/receiving_devices_page.dart';
import 'package:flinx/features/account/presentation/pages/region_page.dart';
import 'package:flinx/features/account/presentation/pages/shared_devices_page.dart';
import 'package:flinx/features/account/presentation/pages/shared_device_member_management_page.dart';
import 'package:flinx/features/account/presentation/pages/system_permissions_page.dart';
import 'package:flinx/features/auth/application/providers.dart';
import 'package:flinx/features/auth/presentation/pages/login_page.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flinx/platform_bridge/mock_hardware_gateway.dart';
import 'package:flinx/platform_bridge/providers.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('shows fallback profile header and account menu rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLocaleLocalDataSourceProvider.overrideWithValue(
            InMemoryAppLocaleLocalDataSource(initialLanguageCode: 'en'),
          ),
        ],
        child: const _LocaleTestHarness(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('739059568@qq.com'), findsOneWidget);
    expect(find.text('Refresh time unavailable'), findsOneWidget);
    expect(find.text('Shared devices'), findsOneWidget);
    expect(find.text('Receiving devices'), findsOneWidget);
    expect(find.text('manage devices'), findsOneWidget);
    expect(find.text('after-sales service'), findsOneWidget);
    expect(find.text('Region'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('System permissions'), findsOneWidget);
    expect(find.text('Manual & guide'), findsOneWidget);
    expect(find.text('Check for updates'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('message'), findsNothing);
    expect(find.text('2'), findsNothing);
    expect(find.text('England'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.byKey(AccountProfileKeys.themeIcon), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(AccountProfileKeys.logoutButton),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Log out'), findsOneWidget);
  });

  testWidgets('opens the region page from the account profile', (tester) async {
    final semantics = tester.ensureSemantics();
    final router = GoRouter(
      initialLocation: AccountProfilePage.routePath,
      routes: [
        GoRoute(
          path: AccountProfilePage.routePath,
          name: AccountProfilePage.routeName,
          builder: (context, state) => const AccountProfilePage(),
        ),
        GoRoute(
          path: RegionPage.routePath,
          name: RegionPage.routeName,
          builder: (context, state) => const RegionPage(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountProfileRemoteDataSourceProvider.overrideWithValue(
            _AvatarProfileRemoteDataSource(),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AccountProfileKeys.regionMenuItem));
    await tester.pumpAndSettle();

    expect(find.text('REGION'), findsOneWidget);
    expect(find.text('China'), findsOneWidget);
    expect(find.text('America'), findsOneWidget);
    expect(find.text('England'), findsOneWidget);
    expect(find.text('La Republique francaise'), findsOneWidget);
    expect(find.text('Canada'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    await tester.tap(find.byKey(RegionPageKeys.option('ca')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();
    expect(find.text('Alex'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('opens system permissions from the account profile', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AccountProfilePage.routePath,
      routes: [
        GoRoute(
          path: AccountProfilePage.routePath,
          name: AccountProfilePage.routeName,
          builder: (context, state) => const AccountProfilePage(),
        ),
        GoRoute(
          path: SystemPermissionsPage.routePath,
          name: SystemPermissionsPage.routeName,
          builder: (context, state) => const SystemPermissionsPage(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AccountProfileKeys.systemPermissionsMenuItem));
    await tester.pumpAndSettle();

    expect(find.text('SYSTEM PERMISSIONS'), findsOneWidget);
    expect(find.text('Access Geographic Location'), findsOneWidget);
    expect(find.text('Access Camera Permissions'), findsOneWidget);
    expect(find.text('Access recording permission'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Access phone storage'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Access phone storage'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Access mobile Bluetooth'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Access mobile Bluetooth'), findsOneWidget);
    expect(
      find.byKey(SystemPermissionsPageKeys.card(SystemPermission.microphone)),
      findsOneWidget,
    );
    expect(
      find.byIcon(Icons.close_rounded, skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byIcon(Icons.check_rounded, skipOffstage: false),
      findsNWidgets(4),
    );
  });

  testWidgets(
    'selects the language centered in the picker when scrolling stops',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appLocaleLocalDataSourceProvider.overrideWithValue(
              InMemoryAppLocaleLocalDataSource(initialLanguageCode: 'en'),
            ),
            appLanguageOptionsProvider.overrideWith(
              (ref) async => const [
                AppLanguageOption(locale: 'en-US', nativeName: 'English'),
                AppLanguageOption(locale: 'zh-CN', nativeName: '中文(简体)'),
              ],
            ),
            accountLocalDataSourceProvider.overrideWithValue(
              InMemoryAccountLocalDataSource(
                initialProfile: const AccountProfileDto(
                  schemaVersion: AccountProfileDto.currentSchemaVersion,
                  userId: 'user-1',
                  email: '739059568@qq.com',
                  nickname: 'Alex',
                  registeredAtIso8601: '',
                ),
              ),
            ),
            accountProfileRemoteDataSourceProvider.overrideWithValue(
              _AvatarProfileRemoteDataSource(),
            ),
          ],
          child: const _LocaleTestHarness(),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AccountProfileKeys.languageMenuItem));
      await tester.pumpAndSettle();

      expect(find.byKey(AccountProfileKeys.languageDialog), findsOneWidget);
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byKey(AccountProfileKeys.languagePicker), findsOneWidget);
      expect(find.text('France'), findsNothing);
      expect(find.text('中文(简体)'), findsOneWidget);
      expect(find.text('Das ist Deutsch'), findsNothing);
      expect(
        find.byKey(AccountProfileKeys.languageCancelButton),
        findsOneWidget,
      );
      expect(
        find.byKey(AccountProfileKeys.languageConfirmButton),
        findsOneWidget,
      );

      final dialog = find.byKey(AccountProfileKeys.languageDialog);
      final english = find.descendant(
        of: dialog,
        matching: find.text('English'),
      );
      final selectedOptionStyle = tester.widget<Text>(english).style;

      await tester.drag(
        find.byKey(AccountProfileKeys.languagePicker),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();
      final simplifiedChinese = find.descendant(
        of: dialog,
        matching: find.text('中文(简体)'),
      );
      expect(
        tester.widget<Text>(simplifiedChinese).style?.color,
        selectedOptionStyle?.color,
      );
      expect(
        tester.widget<Text>(simplifiedChinese).style?.fontSize,
        selectedOptionStyle?.fontSize,
      );
      expect(
        tester.widget<Text>(simplifiedChinese).style?.fontWeight,
        selectedOptionStyle?.fontWeight,
      );

      await tester.tap(find.byKey(AccountProfileKeys.languageConfirmButton));
      await tester.pumpAndSettle();

      expect(find.byKey(AccountProfileKeys.languageDialog), findsNothing);
      expect(find.text('语言'), findsOneWidget);
      expect(find.text('中文(简体)'), findsOneWidget);

      await tester.tap(find.byKey(AccountProfileKeys.languageMenuItem));
      await tester.pumpAndSettle();
      final reopenedDialog = find.byKey(AccountProfileKeys.languageDialog);
      final reopenedSimplifiedChinese = find.descendant(
        of: reopenedDialog,
        matching: find.text('中文(简体)'),
      );
      expect(
        tester.widget<Text>(reopenedSimplifiedChinese).style?.color,
        selectedOptionStyle?.color,
      );
      expect(
        tester.widget<Text>(reopenedSimplifiedChinese).style?.fontSize,
        selectedOptionStyle?.fontSize,
      );
      expect(
        tester.widget<Text>(reopenedSimplifiedChinese).style?.fontWeight,
        selectedOptionStyle?.fontWeight,
      );
      await tester.drag(
        find.byKey(AccountProfileKeys.languagePicker),
        const Offset(0, 100),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AccountProfileKeys.languageCancelButton));
      await tester.pumpAndSettle();

      expect(find.text('语言'), findsOneWidget);
      expect(find.text('中文(简体)'), findsOneWidget);
    },
  );

  testWidgets('opens account details page when tapping the avatar', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AccountProfilePage.routePath,
      routes: [
        GoRoute(
          path: AccountProfilePage.routePath,
          name: AccountProfilePage.routeName,
          builder: (context, state) => const AccountProfilePage(),
        ),
        GoRoute(
          path: AccountDetailsPage.routePath,
          name: AccountDetailsPage.routeName,
          builder: (context, state) => const AccountDetailsPage(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AccountProfileKeys.avatarButton));
    await tester.pumpAndSettle();

    expect(find.text('ACCOUNT'), findsOneWidget);
    expect(find.text('Account number'), findsOneWidget);
    expect(find.text('34345435@qq.com'), findsOneWidget);
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('James'), findsOneWidget);
    expect(find.text('Mailbox'), findsOneWidget);
    expect(find.text('123456@qq.com'), findsOneWidget);
    expect(find.text('Change Password'), findsOneWidget);
    expect(find.text('Forgot password'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
  });

  testWidgets('opens member management when tapping a shared device', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: SharedDevicesPage.routePath,
      routes: [
        GoRoute(
          path: SharedDevicesPage.routePath,
          name: SharedDevicesPage.routeName,
          builder: (context, state) => const SharedDevicesPage(),
        ),
        GoRoute(
          path: SharedDeviceMemberManagementPage.routePath,
          name: SharedDeviceMemberManagementPage.routeName,
          builder: (context, state) => SharedDeviceMemberManagementPage(
            device: state.extra as SharedDoor?,
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedDevicesRepositoryProvider.overrideWithValue(
            _FakeSharedDevicesRepository(),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(SharedDevicesKeys.deviceCard(0)));
    await tester.pumpAndSettle();

    expect(find.byType(SharedDeviceMemberManagementPage), findsOneWidget);
  });

  testWidgets('opens shared devices and returns to the account profile', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AccountProfilePage.routePath,
      routes: [
        GoRoute(
          path: AccountProfilePage.routePath,
          name: AccountProfilePage.routeName,
          builder: (context, state) => const AccountProfilePage(),
        ),
        GoRoute(
          path: SharedDevicesPage.routePath,
          name: SharedDevicesPage.routeName,
          builder: (context, state) => const SharedDevicesPage(),
        ),
        GoRoute(
          path: SharedDeviceMemberManagementPage.routePath,
          name: SharedDeviceMemberManagementPage.routeName,
          builder: (context, state) => const SharedDeviceMemberManagementPage(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedDevicesRepositoryProvider.overrideWithValue(
            _FakeSharedDevicesRepository(),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AccountProfileKeys.sharedDevicesMenuItem));
    await tester.pumpAndSettle();

    expect(find.text('Shared devices'), findsOneWidget);
    expect(find.text('Garage door'), findsOneWidget);
    expect(find.text('Industrial door'), findsOneWidget);
    expect(find.text('Share to 3 people'), findsNWidgets(2));
    expect(find.byKey(SharedDevicesKeys.addButton), findsOneWidget);

    await tester.tap(find.byKey(SharedDevicesKeys.deviceCard(0)));
    await tester.pumpAndSettle();

    expect(find.text('Garage door'), findsOneWidget);
    expect(find.text('Administrator'), findsOneWidget);
    expect(find.text('Guest'), findsOneWidget);
    expect(find.text('Andy@forcedoor.cn'), findsNWidgets(4));
    expect(find.text('2025-10-16 17:54:28'), findsNWidgets(4));
    expect(find.text('Accepted'), findsNWidgets(4));
    expect(
      find.byKey(
        SharedDeviceMemberManagementKeys.editButton('member-admin-001'),
      ),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.byKey(
        SharedDeviceMemberManagementKeys.memberCard('member-guest-002'),
      ),
      200,
    );

    expect(find.text('Andy@forcedoor.cn'), findsNWidgets(4));
    expect(find.text('2025-10-16 17:54:28'), findsNWidgets(4));
    expect(find.text('Accepted'), findsNWidgets(4));
    expect(
      find.byKey(
        SharedDeviceMemberManagementKeys.deleteButton('member-guest-002'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();

    expect(find.text('Shared devices'), findsOneWidget);

    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();

    expect(find.text('739059568@qq.com'), findsOneWidget);
  });

  testWidgets('opens receiving devices and returns to the account profile', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AccountProfilePage.routePath,
      routes: [
        GoRoute(
          path: AccountProfilePage.routePath,
          name: AccountProfilePage.routeName,
          builder: (context, state) => const AccountProfilePage(),
        ),
        GoRoute(
          path: ReceivingDevicesPage.routePath,
          name: ReceivingDevicesPage.routeName,
          builder: (context, state) => const ReceivingDevicesPage(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          receivingDevicesRepositoryProvider.overrideWithValue(
            _StaticReceivingDevicesRepository(),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AccountProfileKeys.receivingDevicesMenuItem));
    await tester.pumpAndSettle();

    expect(find.text('RECEIVING DEVICES'), findsOneWidget);
    expect(find.text('Main gate'), findsOneWidget);
    expect(find.text('Shared by: owner@example.com'), findsOneWidget);
    expect(find.byKey(ReceivingDevicesKeys.editButton), findsOneWidget);
    expect(find.byKey(ReceivingDevicesKeys.deviceCard(0)), findsOneWidget);
    expect(find.byKey(ReceivingDevicesKeys.deviceCard(1)), findsNothing);

    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();

    expect(find.text('739059568@qq.com'), findsOneWidget);
  });

  testWidgets('opens manage devices from the account profile', (tester) async {
    final router = GoRouter(
      initialLocation: AccountProfilePage.routePath,
      routes: [
        GoRoute(
          path: AccountProfilePage.routePath,
          name: AccountProfilePage.routeName,
          builder: (context, state) => const AccountProfilePage(),
        ),
        GoRoute(
          path: ManageDevicesPage.routePath,
          name: ManageDevicesPage.routeName,
          builder: (context, state) => const ManageDevicesPage(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AccountProfileKeys.manageDevicesMenuItem));
    await tester.pumpAndSettle();

    expect(find.text('Manage devices'), findsOneWidget);
    expect(find.text('Devices logged in'), findsOneWidget);
    expect(find.text('Iphone 16 pro max'), findsOneWidget);
    expect(find.text('Ipad air'), findsOneWidget);
    expect(find.text('2025-08-02 11:02'), findsNWidgets(2));
  });

  testWidgets('opens and dismisses account details avatar sheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AccountDetailsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Head portrait'));
    await tester.pumpAndSettle();

    expect(find.text('Photo album'), findsOneWidget);
    expect(find.text('Photograph'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    for (final label in ['Photo album', 'Photograph']) {
      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(FilledButton),
        ),
      );
      final style = button.style!;
      expect(
        style.backgroundColor!.resolve(const {WidgetState.disabled}),
        style.backgroundColor!.resolve(const {}),
      );
      expect(
        style.foregroundColor!.resolve(const {WidgetState.disabled}),
        style.foregroundColor!.resolve(const {}),
      );
      expect(
        style.overlayColor!.resolve(const {WidgetState.pressed}),
        Colors.transparent,
      );
    }

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('Photo album'), findsNothing);
  });

  testWidgets(
    'shows camera permission guidance and preserves the avatar sheet',
    (tester) async {
      final gateway = _CameraPermissionBlockedGateway();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [hardwareGatewayProvider.overrideWithValue(gateway)],
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AccountDetailsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Head portrait'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Photograph'));
      await tester.pumpAndSettle();

      expect(find.text('Camera permission required'), findsOneWidget);
      expect(find.text('Photo album'), findsOneWidget);
      expect(find.text('Go to Settings'), findsOneWidget);

      await tester.tap(find.text('Go to Settings'));
      await tester.pumpAndSettle();

      expect(gateway.openAppSettingsCalls, 1);
      expect(find.text('Camera permission required'), findsNothing);
      expect(find.text('Photo album'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Photo album'), findsNothing);
    },
  );

  testWidgets('updates a built-in avatar and closes the sheet on success', (
    tester,
  ) async {
    final remoteDataSource = _AvatarProfileRemoteDataSource();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountLocalDataSourceProvider.overrideWithValue(
            InMemoryAccountLocalDataSource(
              initialProfile: const AccountProfileDto(
                schemaVersion: AccountProfileDto.currentSchemaVersion,
                userId: 'user-1',
                email: 'alex@example.com',
                nickname: 'Alex',
                registeredAtIso8601: '',
              ),
            ),
          ),
          accountProfileRemoteDataSourceProvider.overrideWithValue(
            remoteDataSource,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AccountDetailsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Head portrait'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Avatar option 4'));
    await tester.pumpAndSettle();

    expect(remoteDataSource.avatarCode, AccountAvatarCode.avatar04);
    expect(remoteDataSource.avatarFileId, isNull);
    expect(find.text('Photo album'), findsNothing);
  });

  testWidgets('localizes account details when the app language is Chinese', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('zh'),
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AccountDetailsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('账户'), findsOneWidget);
    expect(find.text('头像'), findsOneWidget);
    expect(find.text('修改密码'), findsOneWidget);
    expect(find.text('注销账号'), findsOneWidget);
    expect(find.text('退出登录'), findsOneWidget);
    expect(find.text('ACCOUNT'), findsNothing);
  });

  testWidgets('confirms account deletion and returns to login', (tester) async {
    final remoteDataSource = _AvatarProfileRemoteDataSource();
    final router = GoRouter(
      initialLocation: AccountDetailsPage.routePath,
      routes: [
        GoRoute(
          path: LoginPage.routePath,
          builder: (context, state) => const Scaffold(body: Text('Login')),
        ),
        GoRoute(
          path: AccountDetailsPage.routePath,
          name: AccountDetailsPage.routeName,
          builder: (context, state) => const AccountDetailsPage(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountProfileRemoteDataSourceProvider.overrideWithValue(
            remoteDataSource,
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(AccountDetailsPage)),
    );
    container
        .read(activeAuthSessionProvider.notifier)
        .markAuthenticated(userId: 'test-user');

    await tester.ensureVisible(find.text('Cancel account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel account'));
    await tester.pumpAndSettle();
    expect(find.text('Are you sure to cancel the account?'), findsOneWidget);

    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
    expect(find.text('Are you sure to cancel the account?'), findsNothing);

    await tester.tap(find.text('Cancel account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
    expect(
      remoteDataSource.confirmedDeletionRequestId,
      startsWith('account-deletion-'),
    );
    expect(container.read(activeAuthSessionProvider).isAuthenticated, isFalse);
  });

  testWidgets('shows cached account details', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountLocalDataSourceProvider.overrideWithValue(
            InMemoryAccountLocalDataSource(
              initialProfile: const AccountProfileDto(
                schemaVersion: AccountProfileDto.currentSchemaVersion,
                userId: 'user-1',
                email: 'alex@example.com',
                nickname: 'Alex',
                avatarUrl: ' ',
                registeredAtIso8601: '',
                country: 'CN',
              ),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AccountDetailsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('alex@example.com'), findsNWidgets(2));
  });

  testWidgets('opens rename and password sheets from account details rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AccountDetailsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Full name'));
    await tester.pumpAndSettle();

    expect(find.text('Rename'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('Rename'), findsNothing);

    await tester.tap(find.text('Change Password'));
    await tester.pumpAndSettle();

    expect(find.text('Change Password'), findsNWidgets(2));
    expect(find.text('Enter New Password'), findsNWidgets(2));

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('Enter New Password'), findsNothing);
  });

  testWidgets('clears account data and returns to welcome on logout', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AccountDetailsPage.routePath,
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Welcome')),
        ),
        GoRoute(
          path: AccountDetailsPage.routePath,
          name: AccountDetailsPage.routeName,
          builder: (context, state) => const AccountDetailsPage(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(AccountDetailsPage)),
    );
    container
        .read(activeAuthSessionProvider.notifier)
        .markAuthenticated(userId: 'test-user');
    expect(container.read(activeAuthSessionProvider).isAuthenticated, isTrue);

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('ACCOUNT'), findsNothing);
    expect(container.read(activeAuthSessionProvider).isAuthenticated, isFalse);
  });

  testWidgets('clears account data from the profile logout button', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AccountProfilePage.routePath,
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Welcome')),
        ),
        GoRoute(
          path: AccountProfilePage.routePath,
          name: AccountProfilePage.routeName,
          builder: (context, state) => const AccountProfilePage(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(AccountProfilePage)),
    );
    container
        .read(activeAuthSessionProvider.notifier)
        .markAuthenticated(userId: 'test-user');

    await tester.scrollUntilVisible(
      find.byKey(AccountProfileKeys.logoutButton),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(AccountProfileKeys.logoutButton));
    await tester.pumpAndSettle();

    expect(find.text('Welcome'), findsOneWidget);
    expect(container.read(activeAuthSessionProvider).isAuthenticated, isFalse);
  });
}

class _CameraPermissionBlockedGateway extends MockHardwareGateway {
  var openAppSettingsCalls = 0;

  @override
  Future<PermissionSnapshot> getPermissionSnapshot({
    required String requestId,
  }) async => const PermissionSnapshot(
    bluetoothStatus: PermissionStatus.granted,
    cameraStatus: PermissionStatus.blocked,
    locationStatus: PermissionStatus.granted,
    microphoneStatus: PermissionStatus.denied,
    storageStatus: PermissionStatus.granted,
    localNetworkGranted: true,
    notificationGranted: true,
  );

  @override
  Future<void> openAppSettings({required String requestId}) async {
    openAppSettingsCalls += 1;
  }
}

class _AvatarProfileRemoteDataSource implements AccountProfileRemoteDataSource {
  AccountAvatarCode? avatarCode;
  int? avatarFileId;
  String? confirmedDeletionRequestId;

  @override
  Future<AccountProfileRemoteDto> fetchProfile({
    required String requestId,
  }) async => AccountProfileRemoteDto(
    userId: 'user-1',
    email: '739059568@qq.com',
    emailVerified: true,
    nickname: 'Alex',
    avatarCode: avatarCode?.wireValue,
    avatarFileId: avatarFileId,
  );

  @override
  Future<List<AppRegionOptionDto>> fetchRegionOptions({
    required String requestId,
  }) async => const [
    AppRegionOptionDto(regionCode: 'CN', displayName: 'China'),
    AppRegionOptionDto(regionCode: 'US', displayName: 'America'),
    AppRegionOptionDto(regionCode: 'GB', displayName: 'England'),
    AppRegionOptionDto(
      regionCode: 'FR',
      displayName: 'La Republique francaise',
    ),
    AppRegionOptionDto(regionCode: 'CA', displayName: 'Canada'),
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
  }) async {
    this.avatarCode = avatarCode;
    this.avatarFileId = avatarFileId;
  }

  @override
  Future<void> updateAvatar({
    AccountAvatarCode? avatarCode,
    int? avatarFileId,
    required String requestId,
  }) async {
    this.avatarCode = avatarCode;
    this.avatarFileId = avatarFileId;
  }

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
  Future<void> confirmAccountDeletion({required String requestId}) async {
    confirmedDeletionRequestId = requestId;
  }
}

class _FakeSharedDevicesRepository implements SharedDevicesRepository {
  @override
  Future<List<SharedDoor>> fetchSharedDoors({required String requestId}) async {
    return const [
      SharedDoor(doorId: 1, name: 'Garage door', sharedUserCount: 3),
      SharedDoor(doorId: 2, name: 'Industrial door', sharedUserCount: 3),
    ];
  }

  @override
  Future<SharedDoorMembers> fetchDoorMembers({
    required int doorId,
    required String requestId,
  }) async => SharedDoorMembers(
    doorId: doorId,
    doorName: 'Door $doorId',
    administrators: const [],
    guests: const [],
  );

  @override
  Future<void> deleteDoorMember({
    required int shareId,
    required String requestId,
  }) async {}
}

class _StaticReceivingDevicesRepository implements ReceivingDevicesRepository {
  @override
  Future<List<ReceivingDoor>> fetchReceivingDoors({
    required String requestId,
  }) async => const [
    ReceivingDoor(
      shareId: 1,
      doorId: 2,
      name: 'Main gate',
      ownerEmail: 'owner@example.com',
      expiresAt: null,
    ),
  ];
}

class _LocaleTestHarness extends ConsumerWidget {
  const _LocaleTestHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = ref
        .watch(appLocaleControllerProvider)
        .maybeWhen(data: (value) => value.languageCode, orElse: () => null);

    return MaterialApp(
      locale: Locale(languageCode ?? 'en'),
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AccountProfilePage(),
    );
  }
}
