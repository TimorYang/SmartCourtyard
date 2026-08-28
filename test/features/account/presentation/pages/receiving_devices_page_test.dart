import 'dart:async';

import 'package:flinx/app/theme/app_theme.dart';
import 'package:flinx/core/errors/app_error.dart';
import 'package:flinx/features/account/application/providers.dart';
import 'package:flinx/features/account/domain/entities/receiving_door.dart';
import 'package:flinx/features/account/domain/entities/shared_door.dart';
import 'package:flinx/features/account/domain/entities/shared_door_members.dart';
import 'package:flinx/features/account/domain/repositories/receiving_devices_repository.dart';
import 'package:flinx/features/account/domain/repositories/shared_devices_repository.dart';
import 'package:flinx/features/account/presentation/pages/receiving_devices_page.dart';
import 'package:flinx/features/home/application/providers.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toastification/toastification.dart';

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

  testWidgets(
    'toggles editing and deletes a receiving device by its share ID',
    (tester) async {
      var devices = const [
        ReceivingDoor(
          shareId: 9,
          doorId: 3,
          name: 'Garden gate',
          ownerEmail: 'owner@example.com',
          expiresAt: null,
        ),
      ];
      var homeRefreshCount = 0;
      final sharedDevicesRepository = _FakeSharedDevicesRepository(
        onDelete: (shareId) async {
          devices = const [];
        },
      );

      await tester.pumpWidget(
        _TestApp(
          repository: _FakeReceivingDevicesRepository(
            loader: () async => devices,
          ),
          sharedDevicesRepository: sharedDevicesRepository,
          onHomeInvalidated: () {
            homeRefreshCount += 1;
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('RECEIVING DEVICES'), findsOneWidget);
      expect(find.byKey(ReceivingDevicesKeys.deleteButton(9)), findsNothing);

      await tester.tap(find.byKey(ReceivingDevicesKeys.editButton));
      await tester.pump();

      expect(find.text('RECEIVING DEVICES EDITING'), findsOneWidget);
      expect(find.byKey(ReceivingDevicesKeys.deleteButton(9)), findsOneWidget);

      await tester.tap(find.byKey(ReceivingDevicesKeys.deleteButton(9)));
      await tester.pumpAndSettle();

      expect(sharedDevicesRepository.deletedShareIds, [9]);
      expect(
        sharedDevicesRepository.requestIds.single,
        startsWith('receiving-device-delete-9-'),
      );
      expect(homeRefreshCount, 1);
      expect(find.text('No receiving devices yet.'), findsOneWidget);
      expect(find.text('RECEIVING DEVICES EDITING'), findsOneWidget);

      await tester.tap(find.byKey(ReceivingDevicesKeys.editButton));
      await tester.pump();
      expect(find.text('RECEIVING DEVICES'), findsOneWidget);
    },
  );

  testWidgets('keeps the device when deletion fails', (tester) async {
    final deletion = Completer<void>();
    final sharedDevicesRepository = _FakeSharedDevicesRepository(
      onDelete: (_) => deletion.future,
    );

    await tester.pumpWidget(
      _TestApp(
        repository: _FakeReceivingDevicesRepository(
          loader: () async => const [
            ReceivingDoor(
              shareId: 9,
              doorId: 3,
              name: 'Garden gate',
              ownerEmail: 'owner@example.com',
              expiresAt: null,
            ),
          ],
        ),
        sharedDevicesRepository: sharedDevicesRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ReceivingDevicesKeys.editButton));
    await tester.pump();
    await tester.tap(find.byKey(ReceivingDevicesKeys.deleteButton(9)));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byKey(ReceivingDevicesKeys.deleteButton(9)));
    await tester.pump();
    expect(sharedDevicesRepository.deletedShareIds, [9]);

    deletion.completeError(
      const AppError(
        code: AppErrorCode.networkUnavailable,
        messageKey: 'sharedDevices.networkUnavailable',
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Garden gate'), findsOneWidget);
    expect(find.text('RECEIVING DEVICES EDITING'), findsOneWidget);
    expect(
      find.text('Failed to delete the receiving device. Please try again.'),
      findsOneWidget,
    );

    toastification.dismissAll(delayForAnimation: false);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({
    super.key,
    required this.repository,
    this.sharedDevicesRepository,
    this.onHomeInvalidated,
  });

  final ReceivingDevicesRepository repository;
  final SharedDevicesRepository? sharedDevicesRepository;
  final VoidCallback? onHomeInvalidated;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      key: key,
      overrides: [
        receivingDevicesRepositoryProvider.overrideWithValue(repository),
        if (sharedDevicesRepository != null)
          sharedDevicesRepositoryProvider.overrideWithValue(
            sharedDevicesRepository!,
          ),
        if (onHomeInvalidated != null)
          homeDeviceListsInvalidatorProvider.overrideWithValue(
            onHomeInvalidated!,
          ),
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

class _FakeSharedDevicesRepository implements SharedDevicesRepository {
  _FakeSharedDevicesRepository({this.onDelete});

  final Future<void> Function(int shareId)? onDelete;
  final deletedShareIds = <int>[];
  final requestIds = <String>[];

  @override
  Future<void> deleteDoorMember({
    required int shareId,
    required String requestId,
  }) async {
    deletedShareIds.add(shareId);
    requestIds.add(requestId);
    await onDelete?.call(shareId);
  }

  @override
  Future<SharedDoorMembers> fetchDoorMembers({
    required int doorId,
    required String requestId,
  }) => throw UnimplementedError();

  @override
  Future<List<SharedDoor>> fetchSharedDoors({required String requestId}) =>
      throw UnimplementedError();
}
