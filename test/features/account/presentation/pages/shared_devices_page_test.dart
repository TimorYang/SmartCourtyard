import 'dart:async';

import 'package:flinx/app/theme/app_theme.dart';
import 'package:flinx/features/account/application/providers.dart';
import 'package:flinx/features/account/domain/entities/shared_door.dart';
import 'package:flinx/features/account/domain/repositories/shared_devices_repository.dart';
import 'package:flinx/features/account/presentation/pages/shared_devices_page.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders loading, then API-backed shared door data', (
    tester,
  ) async {
    final completer = Completer<List<SharedDoor>>();
    await tester.pumpWidget(
      _TestApp(
        repository: _FakeSharedDevicesRepository(
          loader: () => completer.future,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(const [
      SharedDoor(doorId: 3, name: 'Garden gate', sharedUserCount: 0),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Garden gate'), findsOneWidget);
    expect(find.text('Share to 0 people'), findsOneWidget);
    expect(find.byKey(SharedDevicesKeys.deviceCard(0)), findsOneWidget);
    expect(find.byKey(SharedDevicesKeys.addButton), findsOneWidget);
  });

  testWidgets('renders a localized empty state', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        repository: _FakeSharedDevicesRepository(loader: () async => []),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No shared devices yet.'), findsOneWidget);
  });

  testWidgets('uses the door type local image when no cover is returned', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        repository: _FakeSharedDevicesRepository(
          loader: () async => const [
            SharedDoor(
              doorId: 3,
              name: 'Garden gate',
              sharedUserCount: 0,
              doorType: 3,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final image = tester.widget<Image>(find.byType(Image).first);
    expect(
      image.image,
      const AssetImage('assets/icons/add_device/add_new_doors_swing_gate.png'),
    );
  });

  testWidgets('renders a localized retryable error state', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        repository: _FakeSharedDevicesRepository(
          loader: () => Future.error(StateError('offline')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(find.text('Unable to load shared devices.'), findsOneWidget);
    expect(find.byKey(SharedDevicesKeys.retryButton), findsOneWidget);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.repository});

  final SharedDevicesRepository repository;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      key: ValueKey(repository),
      overrides: [
        sharedDevicesRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SharedDevicesPage(),
      ),
    );
  }
}

class _FakeSharedDevicesRepository implements SharedDevicesRepository {
  const _FakeSharedDevicesRepository({required this.loader});

  final Future<List<SharedDoor>> Function() loader;

  @override
  Future<List<SharedDoor>> fetchSharedDoors({required String requestId}) =>
      loader();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
