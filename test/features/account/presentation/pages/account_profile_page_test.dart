import 'package:flinx/app/theme/app_theme.dart';
import 'package:flinx/features/account/application/providers.dart';
import 'package:flinx/features/account/data/data_sources/account_local_data_source.dart';
import 'package:flinx/features/account/data/data_sources/app_locale_local_data_source.dart';
import 'package:flinx/features/account/data/dto/account_profile_dto.dart';
import 'package:flinx/features/account/domain/entities/system_permission.dart';
import 'package:flinx/features/account/presentation/pages/account_details_page.dart';
import 'package:flinx/features/account/presentation/pages/account_profile_page.dart';
import 'package:flinx/features/account/presentation/pages/manage_devices_page.dart';
import 'package:flinx/features/account/presentation/pages/receiving_devices_page.dart';
import 'package:flinx/features/account/presentation/pages/region_page.dart';
import 'package:flinx/features/account/presentation/pages/shared_devices_page.dart';
import 'package:flinx/features/account/presentation/pages/shared_device_member_management_page.dart';
import 'package:flinx/features/account/presentation/pages/system_permissions_page.dart';
import 'package:flinx/features/auth/application/providers.dart';
import 'package:flinx/features/home/presentation/pages/device_share_page.dart';
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
    expect(find.text('2023-05-04 14:34:48'), findsOneWidget);
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
    expect(find.text('12'), findsOneWidget);
    expect(find.text('2'), findsNWidgets(3));
    expect(find.text('England'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(AccountProfileKeys.logoutButton),
      250,
      scrollable: find.byType(Scrollable).first,
    );
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
    expect(find.text('739059568@qq.com'), findsOneWidget);
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

  testWidgets('opens device share page when tapping a shared device', (
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
          path: DeviceSharePage.routePath,
          name: DeviceSharePage.routeName,
          builder: (context, state) => const DeviceSharePage(),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(SharedDevicesKeys.deviceCard(0)));
    await tester.pumpAndSettle();

    expect(find.byType(DeviceSharePage), findsOneWidget);
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

    await tester.tap(find.byKey(SharedDevicesKeys.addButton));
    await tester.pumpAndSettle();

    expect(find.text('Garage door'), findsOneWidget);
    expect(find.text('Administrator'), findsOneWidget);
    expect(find.text('Guest'), findsOneWidget);
    expect(find.text('Andy@forcedoor.cn'), findsNWidgets(3));
    expect(find.text('2025-10-16 17:54:28'), findsNWidgets(3));
    expect(find.text('Accepted'), findsNWidgets(3));
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
    expect(find.text('Smart door A'), findsOneWidget);
    expect(find.text('Smart door B'), findsNWidgets(2));
    expect(find.text('Share to 2 people'), findsOneWidget);
    expect(find.text('Not shared'), findsNWidgets(2));
    expect(find.byKey(ReceivingDevicesKeys.editButton), findsOneWidget);
    expect(find.byKey(ReceivingDevicesKeys.deviceCard(0)), findsOneWidget);
    expect(find.byKey(ReceivingDevicesKeys.deviceCard(1)), findsOneWidget);
    expect(find.byKey(ReceivingDevicesKeys.deviceCard(2)), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(3));

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
    expect(find.byKey(ManageDevicesKeys.phoneCard), findsOneWidget);
    expect(find.byKey(ManageDevicesKeys.tabletCard), findsOneWidget);
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

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('Photo album'), findsNothing);
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
