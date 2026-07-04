import 'package:flinx/app/flinx_app.dart';
import 'package:flinx/features/auth/application/providers.dart';
import 'package:flinx/features/auth/domain/entities/auth_session.dart';
import 'package:flinx/features/auth/domain/repositories/auth_session_repository.dart';
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
