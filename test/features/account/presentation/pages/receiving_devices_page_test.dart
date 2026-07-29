import 'dart:async';

import 'package:flinx/app/theme/app_theme.dart';
import 'package:flinx/features/account/application/providers.dart';
import 'package:flinx/features/account/domain/entities/receiving_door.dart';
import 'package:flinx/features/account/domain/repositories/receiving_devices_repository.dart';
import 'package:flinx/features/account/presentation/pages/receiving_devices_page.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders loading, then API-backed receiving door data', (
    tester,
  ) async {
    final completer = Completer<List<ReceivingDoor>>();
    await tester.pumpWidget(
      _TestApp(
        repository: _FakeReceivingDevicesRepository(
          loader: () => completer.future,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(const [
      ReceivingDoor(
        shareId: 1,
        doorId: 3,
        name: 'Garden gate',
        ownerEmail: 'owner@example.com',
        expiresAt: null,
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Garden gate'), findsOneWidget);
    expect(find.text('Shared by: owner@example.com'), findsOneWidget);
    expect(find.byKey(ReceivingDevicesKeys.deviceCard(0)), findsOneWidget);
  });

  testWidgets('renders localized empty and retryable error states', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        key: const ValueKey('empty-state'),
        repository: _FakeReceivingDevicesRepository(loader: () async => []),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No receiving devices yet.'), findsOneWidget);

    await tester.pumpWidget(
      _TestApp(
        key: const ValueKey('error-state'),
        repository: _FakeReceivingDevicesRepository(
          loader: () => Future.error(StateError('offline')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Unable to load receiving devices.'), findsOneWidget);
    expect(find.byKey(ReceivingDevicesKeys.retryButton), findsOneWidget);
  });

  testWidgets('uses the door type local image when no cover is returned', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        repository: _FakeReceivingDevicesRepository(
          loader: () async => const [
            ReceivingDoor(
              shareId: 1,
              doorId: 3,
              name: 'Garden gate',
              ownerEmail: 'owner@example.com',
              expiresAt: null,
              doorType: 4,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final image = tester.widget<Image>(find.byType(Image).first);
    expect(
      image.image,
      const AssetImage(
        'assets/icons/add_device/add_new_doors_sliding_gate.png',
      ),
    );
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({super.key, required this.repository});

  final ReceivingDevicesRepository repository;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      key: key,
      overrides: [
        receivingDevicesRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ReceivingDevicesPage(),
      ),
    );
  }
}

class _FakeReceivingDevicesRepository implements ReceivingDevicesRepository {
  const _FakeReceivingDevicesRepository({required this.loader});

  final Future<List<ReceivingDoor>> Function() loader;

  @override
  Future<List<ReceivingDoor>> fetchReceivingDoors({
    required String requestId,
  }) => loader();
}
