import 'package:flinx/app/theme/app_theme.dart';
import 'package:flinx/features/account/presentation/pages/account_details_page.dart';
import 'package:flinx/features/account/presentation/pages/account_profile_page.dart';
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
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AccountProfilePage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('739059568@qq.com'), findsOneWidget);
    expect(find.text('2023-05-04 14:34:48'), findsOneWidget);
    expect(find.text('Shared devices'), findsOneWidget);
    expect(find.text('Receiving devices'), findsOneWidget);
    expect(find.text('manage devices'), findsOneWidget);
    expect(find.text('message'), findsOneWidget);
    expect(find.text('Region'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('System permissions'), findsOneWidget);
    expect(find.text('Check for updates'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('2'), findsNWidgets(3));
    expect(find.text('England'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
  });

  testWidgets('shows a placeholder snackbar from account menu rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AccountProfilePage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Region'));
    await tester.pump();

    expect(find.text('Region is coming soon'), findsOneWidget);
  });

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
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('ACCOUNT'), findsNothing);
  });
}
