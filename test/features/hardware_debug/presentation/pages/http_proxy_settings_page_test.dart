import 'dart:async';

import 'package:flinx/app/theme/app_theme.dart';
import 'package:flinx/core/network/network_proxy_controller.dart';
import 'package:flinx/core/network/network_proxy_preferences.dart';
import 'package:flinx/core/network/network_proxy_settings.dart';
import 'package:flinx/features/hardware_debug/presentation/pages/http_proxy_settings_page.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';

void main() {
  testWidgets('starts disabled and validates host and port when enabled', (
    tester,
  ) async {
    _useTallMobileViewport(tester);
    final router = _router();
    await tester.pumpWidget(_app(router, InMemoryNetworkProxyPreferences()));
    await tester.pumpAndSettle();
    unawaited(router.pushNamed(HttpProxySettingsPage.routeName));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextFormField>(
            find.byKey(HttpProxySettingsPageKeys.hostField),
          )
          .enabled,
      isTrue,
    );
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(HttpProxySettingsPageKeys.portField),
          )
          .enabled,
      isTrue,
    );

    await tester.tap(find.byKey(HttpProxySettingsPageKeys.enabledSwitch));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(HttpProxySettingsPageKeys.saveButton),
    );
    await tester.tap(find.byKey(HttpProxySettingsPageKeys.saveButton));
    await tester.pump();

    expect(find.text('Enter a proxy host or IP.'), findsOneWidget);
    expect(find.text('Enter a proxy port.'), findsOneWidget);
  });

  testWidgets('saves valid settings and shows local feedback', (tester) async {
    _useTallMobileViewport(tester);
    final preferences = InMemoryNetworkProxyPreferences();
    final router = _router();
    await tester.pumpWidget(_app(router, preferences));
    await tester.pumpAndSettle();
    unawaited(router.pushNamed(HttpProxySettingsPage.routeName));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(HttpProxySettingsPageKeys.enabledSwitch));
    await tester.pump();
    await tester.enterText(
      find.byKey(HttpProxySettingsPageKeys.hostField),
      'proxy.example.test',
    );
    await tester.enterText(
      find.byKey(HttpProxySettingsPageKeys.portField),
      '9090',
    );
    await tester.ensureVisible(
      find.byKey(HttpProxySettingsPageKeys.saveButton),
    );
    await tester.tap(find.byKey(HttpProxySettingsPageKeys.saveButton));
    await tester.pumpAndSettle();

    expect(
      await preferences.read(),
      const NetworkProxySettings(
        enabled: true,
        host: 'proxy.example.test',
        port: 9090,
      ),
    );
    expect(find.text('Previous page'), findsOneWidget);
    expect(find.text('HTTP proxy settings saved.'), findsOneWidget);
    toastification.dismissAll(delayForAnimation: false);
    await tester.pumpAndSettle();
  });

  testWidgets('keeps save pending and ignores duplicate submissions', (
    tester,
  ) async {
    _useTallMobileViewport(tester);
    final writeStarted = Completer<void>();
    final writeRelease = Completer<void>();
    final preferences = _BlockingNetworkProxyPreferences(
      writeStarted: writeStarted,
      writeRelease: writeRelease,
    );
    final router = _router();
    await tester.pumpWidget(_app(router, preferences));
    await tester.pumpAndSettle();
    unawaited(router.pushNamed(HttpProxySettingsPage.routeName));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(HttpProxySettingsPageKeys.enabledSwitch));
    await tester.pump();
    await tester.enterText(
      find.byKey(HttpProxySettingsPageKeys.hostField),
      'proxy.example.test',
    );
    await tester.enterText(
      find.byKey(HttpProxySettingsPageKeys.portField),
      '9090',
    );
    await tester.ensureVisible(
      find.byKey(HttpProxySettingsPageKeys.saveButton),
    );
    await tester.tap(find.byKey(HttpProxySettingsPageKeys.saveButton));
    await tester.pump();
    await writeStarted.future;

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(preferences.writeCount, 1);
    await tester.tap(
      find.byKey(HttpProxySettingsPageKeys.saveButton),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(preferences.writeCount, 1);

    writeRelease.complete();
    await tester.pumpAndSettle();
    expect(find.text('Previous page'), findsOneWidget);
    toastification.dismissAll(delayForAnimation: false);
    await tester.pumpAndSettle();
  });
}

void _useTallMobileViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app(GoRouter router, NetworkProxyPreferences preferences) {
  return ProviderScope(
    overrides: [networkProxyPreferencesProvider.overrideWithValue(preferences)],
    child: ToastificationWrapper(
      child: MaterialApp.router(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
        builder: (context, child) => ToastificationConfigProvider(
          config: const ToastificationConfig(
            alignment: Alignment.topCenter,
            animationDuration: Duration(milliseconds: 220),
          ),
          child: child!,
        ),
      ),
    ),
  );
}

GoRouter _router() {
  return GoRouter(
    initialLocation: '/previous',
    routes: [
      GoRoute(
        path: '/previous',
        name: 'previous',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Previous page'))),
      ),
      GoRoute(
        path: HttpProxySettingsPage.routePath,
        name: HttpProxySettingsPage.routeName,
        builder: (context, state) => const HttpProxySettingsPage(),
      ),
    ],
  );
}

class _BlockingNetworkProxyPreferences implements NetworkProxyPreferences {
  _BlockingNetworkProxyPreferences({
    required this.writeStarted,
    required this.writeRelease,
  });

  final Completer<void> writeStarted;
  final Completer<void> writeRelease;
  int writeCount = 0;

  @override
  Future<NetworkProxySettings> read() async {
    return const NetworkProxySettings.disabled();
  }

  @override
  Future<void> write(NetworkProxySettings settings) async {
    writeCount++;
    writeStarted.complete();
    await writeRelease.future;
  }
}
