import 'package:flinx/app/flinx_app.dart';
import 'package:flinx/features/auth/application/providers.dart';
import 'package:flinx/features/auth/domain/entities/auth_session.dart';
import 'package:flinx/features/auth/domain/repositories/auth_session_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthSessionRepository implements AuthSessionRepository {
  const _FakeAuthSessionRepository(this.session);

  final AuthSession session;

  @override
  AuthSession readCurrentSession() => session;
}

void main() {
  testWidgets('opens login page from welcome page', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FlinxApp()));

    await tester.pumpAndSettle();

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your email address'), findsOneWidget);
  });

  testWidgets('opens home page from welcome page shortcut', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FlinxApp()));

    await tester.pumpAndSettle();

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(find.text('No doors'), findsOneWidget);
    expect(find.text('0 Door'), findsOneWidget);
  });

  testWidgets('shows home add menu from header add action', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FlinxApp()));

    await tester.pumpAndSettle();

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add door'));
    await tester.pumpAndSettle();

    expect(find.text('Add Scene'), findsOneWidget);
    expect(find.text('Add Door'), findsOneWidget);
    expect(find.text('Smart Device'), findsOneWidget);

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(find.text('Add Scene'), findsNothing);
    expect(find.text('Add Door'), findsNothing);
    expect(find.text('Smart Device'), findsNothing);
  });

  testWidgets('opens scene name dialog from home add scene menu action', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: FlinxApp()));

    await tester.pumpAndSettle();

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add door'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Scene'));
    await tester.pumpAndSettle();

    expect(find.text('Scene Name'), findsOneWidget);
    expect(find.text('Input scene name'), findsOneWidget);
    expect(find.text('SCENE'), findsNothing);
  });

  testWidgets('opens add new doors page from home add door menu action', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: FlinxApp()));

    await tester.pumpAndSettle();

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add door'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Door'));
    await tester.pumpAndSettle();

    expect(find.text('Add new doors'), findsOneWidget);
    expect(find.text('Select the door to be added'), findsOneWidget);
    expect(find.text('Garage door'), findsOneWidget);
    expect(find.text('Roller door'), findsOneWidget);
    expect(find.text('Industrial door'), findsOneWidget);

    await tester.drag(find.byType(Scrollable), const Offset(0, -360));
    await tester.pumpAndSettle();

    expect(find.text('Swing gate'), findsOneWidget);
    expect(find.text('Sliding gate'), findsOneWidget);

    await tester.tap(find.text('Swing gate'));
    await tester.pumpAndSettle();

    expect(find.text('Door name'), findsOneWidget);
    expect(find.text('Input door name'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('Add Device'), findsOneWidget);
    expect(find.text('Select the device to be added'), findsOneWidget);
    expect(find.text('F-box'), findsWidgets);
    expect(find.text('Smart controller'), findsOneWidget);
    expect(find.text('USB WIFI module'), findsOneWidget);
    expect(find.text('Smart Opener'), findsOneWidget);
  });

  testWidgets('redirects authenticated users to the home page', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionRepositoryProvider.overrideWithValue(
            const _FakeAuthSessionRepository(
              AuthSession(isAuthenticated: true, userId: 'user-1'),
            ),
          ),
        ],
        child: const FlinxApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No doors'), findsOneWidget);
    expect(find.text('Login'), findsNothing);
  });
}
