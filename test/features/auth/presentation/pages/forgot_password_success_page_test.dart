import 'package:flinx/app/theme/app_theme.dart';
import 'package:flinx/features/account/application/providers.dart';
import 'package:flinx/features/account/domain/entities/account_profile.dart';
import 'package:flinx/features/auth/application/providers.dart';
import 'package:flinx/features/auth/domain/entities/auth_session.dart';
import 'package:flinx/features/auth/presentation/pages/forgot_password_success_page.dart';
import 'package:flinx/features/auth/presentation/pages/login_page.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flinx/shared/widgets/flinx_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('returns to login when the button is tapped', (tester) async {
    final harness = await _pumpSuccessPage(tester);

    await tester.tap(find.text('Back to Login'));
    await tester.pumpAndSettle();

    _expectSignedOutAtLogin(harness);
  });

  testWidgets('returns to login when the navigation back button is tapped', (
    tester,
  ) async {
    final harness = await _pumpSuccessPage(tester);

    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();

    _expectSignedOutAtLogin(harness);
  });

  testWidgets('returns to login when the system back action is invoked', (
    tester,
  ) async {
    final harness = await _pumpSuccessPage(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    _expectSignedOutAtLogin(harness);
  });

  testWidgets('uses default pop behavior without a back callback', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(
                        appBar: FlinxNavigationBar(title: 'Details'),
                        body: SizedBox.shrink(),
                      ),
                    ),
                  );
                },
                child: const Text('Open details'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();

    expect(find.text('Open details'), findsOneWidget);
  });
}

Future<_SuccessPageHarness> _pumpSuccessPage(WidgetTester tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await container.read(accountControllerProvider.future);
  container.read(accountControllerProvider.notifier).setSessionProfile(
    AccountProfile(
      userId: 'user-1',
      email: 'user@example.com',
      nickname: 'User',
      registeredAt: DateTime.utc(2026, 7, 29),
    ),
  );
  container
      .read(activeAuthSessionProvider.notifier)
      .markAuthenticated(userId: 'user-1');

  final router = GoRouter(
    initialLocation: '/password-reset',
    routes: [
      GoRoute(
        path: '/password-reset',
        builder: (context, state) => Scaffold(
          body: Center(
            child: FilledButton(
              key: const ValueKey('open-password-reset-success'),
              onPressed: () => context.push(ForgotPasswordSuccessPage.routePath),
              child: const Text('Open success'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: ForgotPasswordSuccessPage.routePath,
        builder: (context, state) => const ForgotPasswordSuccessPage(),
      ),
      GoRoute(
        path: LoginPage.routePath,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Login destination')),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('open-password-reset-success')));
  await tester.pumpAndSettle();

  return _SuccessPageHarness(container: container, router: router);
}

void _expectSignedOutAtLogin(_SuccessPageHarness harness) {
  expect(harness.router.state.matchedLocation, LoginPage.routePath);
  expect(
    harness.container.read(accountControllerProvider).requireValue,
    isNull,
  );
  expect(
    harness.container.read(activeAuthSessionProvider),
    const AuthSession.signedOutAfterClear(),
  );
}

class _SuccessPageHarness {
  const _SuccessPageHarness({required this.container, required this.router});

  final ProviderContainer container;
  final GoRouter router;
}
