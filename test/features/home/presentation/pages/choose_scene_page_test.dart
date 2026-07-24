import 'package:flinx/features/home/application/providers.dart';
import 'package:flinx/features/home/domain/entities/home_scene.dart';
import 'package:flinx/features/home/presentation/pages/choose_scene_page.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _scenes = [
  HomeScene(id: 1, name: 'Home', doorCount: 2, isDefault: true),
  HomeScene(id: 2, name: 'Warehouse', doorCount: 5, isDefault: false),
];

const _door = DeviceSummary(
  id: '12',
  name: 'Main Gate',
  onlineState: DeviceOnlineState.online,
  bleState: BleConnectionState.connected,
  doorState: DoorState.closed,
  cycleCount: 0,
  remainingLifePercent: 100,
  sceneId: 1,
);

void main() {
  Future<void> pumpPage(
    WidgetTester tester, {
    required Future<List<HomeScene>> Function(Ref ref) loadScenes,
  }) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [homeScenesProvider.overrideWith(loadScenes)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChooseScenePage(door: _door),
        ),
      ),
    );
  }

  testWidgets('renders scenes from the home scenes provider', (tester) async {
    await pumpPage(tester, loadScenes: (_) async => _scenes);
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Warehouse'), findsOneWidget);
    expect(find.text('2 Devices'), findsOneWidget);
    expect(find.text('5 Devices'), findsOneWidget);
    expect(find.text('2222'), findsNothing);
  });

  testWidgets('shows an empty state when the response contains no scenes', (
    tester,
  ) async {
    await pumpPage(tester, loadScenes: (_) async => const []);
    await tester.pumpAndSettle();

    expect(find.text('No scenes available'), findsOneWidget);
  });

  testWidgets('shows a retry state when loading scenes fails', (tester) async {
    await pumpPage(
      tester,
      loadScenes: (_) async => throw StateError('offline'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to load scenes. Tap to retry.'), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
  });
}
