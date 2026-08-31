import 'package:flinx/app/theme/app_theme.dart';
import 'package:flinx/core/diagnostics/diagnostic_logging.dart';
import 'package:flinx/core/network/network_proxy_controller.dart';
import 'package:flinx/core/network/network_proxy_preferences.dart';
import 'package:flinx/features/account/presentation/pages/hardware_diagnostics_page.dart';
import 'package:flinx/features/hardware_debug/presentation/pages/http_proxy_settings_page.dart';
import 'package:flinx/platform_bridge/mock_hardware_gateway.dart';
import 'package:flinx/platform_bridge/providers.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('opens HTTP Proxy from hardware diagnostics', (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      initialLocation: HardwareDiagnosticsPage.routePath,
      routes: [
        GoRoute(
          path: HardwareDiagnosticsPage.routePath,
          name: HardwareDiagnosticsPage.routeName,
          builder: (context, state) => const HardwareDiagnosticsPage(),
        ),
        GoRoute(
          path: HttpProxySettingsPage.routePath,
          name: HttpProxySettingsPage.routeName,
          builder: (context, state) => const HttpProxySettingsPage(),
        ),
      ],
    );
    final gateway = MockHardwareGateway();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          diagnosticLoggingPreferencesProvider.overrideWithValue(
            _InMemoryDiagnosticLoggingPreferences(),
          ),
          nativeHardwareGatewayProvider.overrideWithValue(gateway),
          networkProxyPreferencesProvider.overrideWithValue(
            InMemoryNetworkProxyPreferences(),
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

    expect(find.text('HTTP Proxy'), findsOneWidget);
    expect(find.text('Disabled'), findsOneWidget);
    await tester.tap(find.byKey(HardwareDiagnosticsPage.httpProxyRowKey));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(HttpProxySettingsPageKeys.saveButton),
    );

    expect(find.text('HTTP Proxy'), findsOneWidget);
    expect(find.byKey(HttpProxySettingsPageKeys.saveButton), findsOneWidget);
  });
}

class _InMemoryDiagnosticLoggingPreferences
    implements DiagnosticLoggingPreferences {
  DiagnosticLoggingSettings settings =
      const DiagnosticLoggingSettings.defaults();

  @override
  Future<DiagnosticLoggingSettings> read() async => settings;

  @override
  Future<void> write(DiagnosticLoggingSettings value) async {
    settings = value;
  }
}
