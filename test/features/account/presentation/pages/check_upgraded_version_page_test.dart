import 'package:flinx/app/theme/app_theme.dart';
import 'package:flinx/features/account/presentation/pages/account_profile_page.dart';
import 'package:flinx/features/account/presentation/pages/check_upgraded_version_page.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('opens the upgrade check page from account profile', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = GoRouter(
      initialLocation: AccountProfilePage.routePath,
      routes: [
        GoRoute(
          path: AccountProfilePage.routePath,
          name: AccountProfilePage.routeName,
          builder: (context, state) => const AccountProfilePage(),
        ),
        GoRoute(
          path: CheckUpgradedVersionPage.routePath,
          name: CheckUpgradedVersionPage.routeName,
          builder: (context, state) => const CheckUpgradedVersionPage(),
        ),
      ],
    );

    await tester.pumpWidget(_TestApp(router: router));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AccountProfileKeys.checkForUpdatesMenuItem));
    await tester.pumpAndSettle();

    expect(find.text('Check the upgraded version'), findsOneWidget);
  });

  testWidgets(
    'selects updates, opens the schedule dialog and completes progress',
    (tester) async {
      await tester.pumpWidget(_TestApp(home: const CheckUpgradedVersionPage()));
      await tester.pumpAndSettle();

      final start = tester.widget<FilledButton>(
        find.byKey(CheckUpgradedVersionKeys.startButton),
      );
      expect(start.onPressed, isNull);

      await tester.tap(
        find.byKey(CheckUpgradedVersionKeys.packageCheckbox('gdo-1', 'motor')),
      );
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(CheckUpgradedVersionKeys.startButton),
            )
            .onPressed,
        isNotNull,
      );

      await tester.tap(find.byKey(CheckUpgradedVersionKeys.startButton));
      await tester.pumpAndSettle();
      expect(
        find.byKey(CheckUpgradedVersionKeys.scheduleDialog),
        findsOneWidget,
      );
      expect(find.text('Select upgrade time'), findsOneWidget);

      await tester.tap(find.byKey(CheckUpgradedVersionKeys.scheduleConfirm));
      await tester.pump();
      expect(
        find.byKey(CheckUpgradedVersionKeys.progressCard('gdo-1')),
        findsOneWidget,
      );
      expect(find.text('Upgrading'), findsOneWidget);

      await tester.pump(const Duration(seconds: 6));
      expect(find.text('Completed'), findsOneWidget);
    },
  );

  testWidgets('synchronizes parent selection and collapses device details', (
    tester,
  ) async {
    await tester.pumpWidget(_TestApp(home: const CheckUpgradedVersionPage()));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(CheckUpgradedVersionKeys.deviceCheckbox('rdo-1')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.byKey(CheckUpgradedVersionKeys.deviceCheckbox('rdo-1')),
    );
    await tester.pump();
    expect(find.byIcon(Icons.check_rounded), findsAtLeastNWidgets(3));

    await tester.tap(
      find.byKey(CheckUpgradedVersionKeys.deviceExpansion('rdo-1')),
    );
    await tester.pump();
    expect(
      find.byKey(CheckUpgradedVersionKeys.packageCheckbox('rdo-1', 'motor')),
      findsNothing,
    );
  });

  testWidgets('switches scheduling modes and dismisses the dialog', (
    tester,
  ) async {
    await tester.pumpWidget(_TestApp(home: const CheckUpgradedVersionPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CheckUpgradedVersionKeys.applicationCheckbox));
    await tester.pump();
    await tester.tap(find.byKey(CheckUpgradedVersionKeys.startButton));
    await tester.pumpAndSettle();
    expect(find.byKey(CheckUpgradedVersionKeys.scheduleDialog), findsOneWidget);

    await tester.tap(find.text('postpone'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('immediate').last);
    await tester.pumpAndSettle();
    expect(find.text('immediate'), findsOneWidget);

    await tester.tap(find.byKey(CheckUpgradedVersionKeys.scheduleCancel));
    await tester.pumpAndSettle();
    expect(find.byKey(CheckUpgradedVersionKeys.scheduleDialog), findsNothing);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({this.home, this.router});

  final Widget? home;
  final GoRouter? router;

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );
    return ProviderScope(
      child: router == null
          ? app
          : MaterialApp.router(
              theme: AppTheme.light(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: router,
            ),
    );
  }
}
