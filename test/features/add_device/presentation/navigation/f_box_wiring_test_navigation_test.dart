import 'package:flinx/features/add_device/presentation/navigation/f_box_wiring_test_route.dart';
import 'package:flinx/features/add_device/presentation/pages/f_box_wiring_test_page.dart';
import 'package:flinx/features/device_control/application/device_command_controller.dart';
import 'package:flinx/platform_bridge/mock_hardware_gateway.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flinx/shared/widgets/flinx_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('encodes and parses F-box route context', () {
    const data = FBoxWiringTestRouteData(
      doorId: 'door/42',
      deviceId: 'Fbox device',
      onboardingFlowId: 'flow 1',
      entryPoint: FBoxWiringTestEntryPoint.deviceCommand,
    );

    final parsed = FBoxWiringTestRoute.fromQueryParameters(
      Uri.parse(data.location).queryParameters,
    );

    expect(parsed, data);
  });

  testWidgets('Try it back returns home from the top-level onboarding flow', (
    tester,
  ) async {
    await _pumpNavigationApp(tester, initialLocation: '/home');

    await tester.tap(find.byKey(const Key('open-add-page')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-success-page')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-fbox-page')));
    await tester.pumpAndSettle();

    expect(find.byType(FBoxWiringTestPage), findsOneWidget);
    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.byType(FBoxWiringTestPage), findsNothing);
    expect(find.text('Add new'), findsNothing);
    expect(find.text('Success'), findsNothing);
  });

  testWidgets('Try it NEXT opens device command from the top-level flow', (
    tester,
  ) async {
    await _pumpNavigationApp(tester, initialLocation: '/home');

    await tester.tap(find.byKey(const Key('open-add-page')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-success-page')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-fbox-page')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('fBoxWiringTestNextButton')),
    );
    await tester.tap(find.byKey(const Key('fBoxWiringTestNextButton')));
    await tester.pumpAndSettle();

    expect(
      find.text('Device command door=42 device=fbox-device'),
      findsOneWidget,
    );
    expect(find.text('Add new'), findsNothing);
    expect(find.text('Success'), findsNothing);
  });

  testWidgets('child Try it back and NEXT return to the parent command page', (
    tester,
  ) async {
    await _pumpNavigationApp(tester, initialLocation: '/home');

    await tester.tap(find.byKey(const Key('open-command-page')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-already-added-page')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-child-success-page')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-fbox-page')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();

    expect(
      find.text('Device command door=42 device=parent-device'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('open-already-added-page')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-child-success-page')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-fbox-page')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('fBoxWiringTestNextButton')),
    );
    await tester.tap(find.byKey(const Key('fBoxWiringTestNextButton')));
    await tester.pumpAndSettle();

    expect(
      find.text('Device command door=42 device=parent-device'),
      findsOneWidget,
    );
    expect(find.byType(FBoxWiringTestPage), findsNothing);
  });

  testWidgets('device command entry point pops back to the original page', (
    tester,
  ) async {
    await _pumpNavigationApp(tester, initialLocation: '/home');

    await tester.tap(find.byKey(const Key('open-command-page')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-device-command-fbox-page')));
    await tester.pumpAndSettle();
    expect(find.byType(FBoxWiringTestPage), findsOneWidget);

    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();
    expect(
      find.text('Device command door=42 device=parent-device'),
      findsOneWidget,
    );
  });
}

Future<void> _pumpNavigationApp(
  WidgetTester tester, {
  required String initialLocation,
}) async {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => _TestPage(
          title: 'Home',
          actions: [
            _TestAction(
              key: const Key('open-add-page'),
              label: 'Open add',
              onPressed: () => context.push('/add'),
            ),
            _TestAction(
              key: const Key('open-command-page'),
              label: 'Open command',
              onPressed: () => context.push('/command'),
            ),
          ],
        ),
      ),
      GoRoute(
        path: '/add',
        name: 'add-new-doors',
        builder: (context, state) => _TestPage(
          title: 'Add new',
          actions: [
            _TestAction(
              key: const Key('open-success-page'),
              label: 'Open success',
              onPressed: () => context.push('/success'),
            ),
          ],
        ),
      ),
      GoRoute(
        path: '/success',
        name: 'success',
        builder: (context, state) => _TestPage(
          title: 'Success',
          actions: [
            _TestAction(
              key: const Key('open-fbox-page'),
              label: 'Open F-box',
              onPressed: () => context.push(
                FBoxWiringTestRoute.location(
                  doorId: '42',
                  deviceId: 'fbox-device',
                ),
              ),
            ),
          ],
        ),
      ),
      GoRoute(
        path: '/command',
        name: 'device-command',
        builder: (context, state) => _TestPage(
          title:
              'Device command door=${state.uri.queryParameters['doorId'] ?? '42'} '
              'device=${state.uri.queryParameters['deviceId'] ?? 'parent-device'}',
          actions: [
            _TestAction(
              key: const Key('open-already-added-page'),
              label: 'Open already added',
              onPressed: () => context.push('/already-added'),
            ),
            _TestAction(
              key: const Key('open-device-command-fbox-page'),
              label: 'Open F-box from command',
              onPressed: () => context.push(
                FBoxWiringTestRoute.location(
                  doorId: '42',
                  deviceId: 'parent-device',
                  entryPoint: FBoxWiringTestEntryPoint.deviceCommand,
                ),
              ),
            ),
          ],
        ),
      ),
      GoRoute(
        path: '/already-added',
        name: 'already-added-devices',
        builder: (context, state) => _TestPage(
          title: 'Already added',
          actions: [
            _TestAction(
              key: const Key('open-child-success-page'),
              label: 'Open child success',
              onPressed: () => context.push('/child-success'),
            ),
          ],
        ),
      ),
      GoRoute(
        path: '/child-success',
        name: 'child-success',
        builder: (context, state) => _TestPage(
          title: 'Child success',
          actions: [
            _TestAction(
              key: const Key('open-fbox-page'),
              label: 'Open F-box',
              onPressed: () => context.push(
                FBoxWiringTestRoute.location(
                  doorId: '42',
                  deviceId: 'child-device',
                ),
              ),
            ),
          ],
        ),
      ),
      GoRoute(
        path: FBoxWiringTestRoute.routePath,
        name: FBoxWiringTestRoute.routeName,
        builder: (context, state) => FBoxWiringTestPage(
          routeData: FBoxWiringTestRoute.fromQueryParameters(
            state.uri.queryParameters,
          ),
        ),
      ),
      GoRoute(
        path: '/device-command',
        name: 'device-command-result',
        builder: (context, state) => _TestPage(
          title:
              'Device command door=${state.uri.queryParameters['doorId']} '
              'device=${state.uri.queryParameters['deviceId']}',
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        deviceCommandHardwareGatewayProvider.overrideWithValue(
          MockHardwareGateway(),
        ),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _TestPage extends StatelessWidget {
  const _TestPage({required this.title, this.actions = const []});

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FlinxNavigationBar(title: title),
      body: Column(children: actions),
    );
  }
}

class _TestAction extends StatelessWidget {
  const _TestAction({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(onPressed: onPressed, child: Text(label));
  }
}
