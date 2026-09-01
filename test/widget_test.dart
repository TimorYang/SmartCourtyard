import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flinx/app/flinx_app.dart';
import 'package:flinx/app/router/app_router.dart';
import 'package:flinx/core/localization/providers.dart';
import 'package:flinx/features/account/application/providers.dart';
import 'package:flinx/features/account/domain/entities/app_locale_preference.dart';
import 'package:flinx/features/account/domain/repositories/app_locale_repository.dart';

void main() {
  testWidgets('shows the unauthenticated welcome page', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FlinxApp()));

    await tester.pumpAndSettle();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );
    expect(find.text('Start your\nsmart life'), findsOneWidget);
    expect(find.text('Make your life comfortable'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
  });

  testWidgets('waits for the saved locale before starting the router', (
    tester,
  ) async {
    final localeCompleter = Completer<AppLocalePreference?>();
    final repository = _DelayedAppLocaleRepository(localeCompleter.future);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Ready')),
        ),
      ],
    );
    addTearDown(router.dispose);
    var routerBuildCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLocaleRepositoryProvider.overrideWithValue(repository),
          appRouterProvider.overrideWith((ref) {
            routerBuildCount += 1;
            return router;
          }),
        ],
        child: const FlinxApp(),
      ),
    );
    await tester.pump();

    expect(routerBuildCount, 0);
    expect(find.text('Ready'), findsNothing);

    localeCompleter.complete(AppLocalePreference.simplifiedChinese);
    await tester.pumpAndSettle();

    expect(routerBuildCount, 1);
    expect(find.text('Ready'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.text('Ready')),
    );
    expect(container.read(currentAppLocaleStoreProvider).value, 'zh-CN');
  });
}

class _DelayedAppLocaleRepository implements AppLocaleRepository {
  const _DelayedAppLocaleRepository(this.locale);

  final Future<AppLocalePreference?> locale;

  @override
  Future<AppLocalePreference?> readPreferredLocale() => locale;

  @override
  Future<void> savePreferredLocale(AppLocalePreference locale) async {}
}
