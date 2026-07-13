import 'package:flinx/app/flinx_app.dart';
import 'package:flinx/features/auth/application/providers.dart';
import 'package:flinx/features/auth/domain/entities/auth_session.dart';
import 'package:flinx/features/home/application/providers.dart';
import 'package:flinx/features/home/domain/entities/home_scene.dart';
import 'package:flinx/features/home/domain/use_cases/create_home_scene_use_case.dart';
import 'package:flinx/features/home/domain/repositories/home_scene_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpSignedInApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(
            (ref) async =>
                const AuthSession(isAuthenticated: true, userId: 'test-user'),
          ),
          homeScenesProvider.overrideWith(
            (ref) async => const [
              HomeScene(id: 1, name: 'Home', doorCount: 2, isDefault: true),
            ],
          ),
          createHomeSceneUseCaseProvider.overrideWith(
            (ref) => CreateHomeSceneUseCase(repository: _FakeSceneRepository()),
          ),
        ],
        child: const FlinxApp(),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('opens scene page from the second home action', (tester) async {
    await pumpSignedInApp(tester);

    await tester.tap(find.byTooltip('Scene'));
    await tester.pumpAndSettle();

    expect(find.text('SCENE'), findsOneWidget);
    expect(find.byTooltip('Edit scene'), findsOneWidget);
    expect(find.text('5 Scenes'), findsOneWidget);
    expect(find.text('Warehouse A'), findsOneWidget);
    expect(find.text('5 Devices'), findsOneWidget);
    expect(find.text('Home Garage A'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.text('New scene'), findsOneWidget);
  });

  testWidgets('opens scene name dialog from new scene card', (tester) async {
    await pumpSignedInApp(tester);

    await tester.tap(find.byTooltip('Scene'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New scene'));
    await tester.pumpAndSettle();

    expect(find.text('Scene Name'), findsOneWidget);
    expect(find.text('Input scene name'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('confirm'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Scene Name'), findsNothing);

    await tester.tap(find.text('New scene'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Demo scene');
    await tester.tap(find.text('confirm'));
    await tester.pumpAndSettle();

    expect(find.text('Scene Name'), findsNothing);
  });

  testWidgets('keeps scene name dialog open when name is empty', (
    tester,
  ) async {
    await pumpSignedInApp(tester);

    await tester.tap(find.byTooltip('Scene'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New scene'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('confirm'));
    await tester.pump();

    expect(find.text('Scene Name'), findsOneWidget);
    expect(find.text('input scene name'), findsOneWidget);
  });

  testWidgets('toggles scene editing mode from the top-right action', (
    tester,
  ) async {
    await pumpSignedInApp(tester);

    await tester.tap(find.byTooltip('Scene'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit scene'));
    await tester.pumpAndSettle();

    expect(find.text('SCENE EDITING'), findsOneWidget);
    expect(find.byTooltip('Done editing'), findsOneWidget);
    expect(find.byIcon(Icons.remove_rounded), findsNWidgets(3));
    expect(find.text('New scene'), findsNothing);

    await tester.tap(find.byTooltip('Done editing'));
    await tester.pumpAndSettle();

    expect(find.text('SCENE'), findsOneWidget);
    expect(find.byTooltip('Edit scene'), findsOneWidget);
  });
}

class _FakeSceneRepository implements HomeSceneRepository {
  @override
  Future<List<HomeScene>> fetchScenes({required String requestId}) async {
    return const [
      HomeScene(id: 1, name: 'Home', doorCount: 2, isDefault: true),
    ];
  }

  @override
  Future<HomeScene> createScene({
    required String name,
    required String requestId,
  }) async {
    return HomeScene(id: 2, name: name, doorCount: 0, isDefault: false);
  }
}
