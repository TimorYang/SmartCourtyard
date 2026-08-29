import 'package:flinx/core/errors/app_error.dart';
import 'package:flinx/features/account/application/providers.dart';
import 'package:flinx/features/account/domain/entities/receiving_door.dart';
import 'package:flinx/features/account/domain/repositories/receiving_devices_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads receiving doors and refreshes them with a request ID', () async {
    final repository = _FakeReceivingDevicesRepository();
    final container = ProviderContainer(
      overrides: [
        receivingDevicesRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    expect(
      await container.read(receivingDevicesControllerProvider.future),
      const [
        ReceivingDoor(
          shareId: 1,
          doorId: 2,
          name: 'Main gate',
          ownerEmail: 'owner@example.com',
          expiresAt: null,
        ),
      ],
    );

    await container.read(receivingDevicesControllerProvider.notifier).refresh();

    expect(repository.requestIds, hasLength(2));
    expect(
      repository.requestIds.every((id) => id.startsWith('receiving-devices-')),
      isTrue,
    );
  });

  test('exposes failures as an error state', () async {
    final container = ProviderContainer(
      overrides: [
        receivingDevicesRepositoryProvider.overrideWithValue(
          _FakeReceivingDevicesRepository(
            error: const AppError(
              code: AppErrorCode.networkUnavailable,
              messageKey: 'receivingDevices.networkUnavailable',
            ),
          ),
        ),
      ],
    );
    final subscription = container.listen(
      receivingDevicesControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    addTearDown(container.dispose);

    container.read(receivingDevicesControllerProvider);
    await Future<void>.delayed(Duration.zero);

    final state = container.read(receivingDevicesControllerProvider);
    expect(state.hasError, isTrue);
    expect(state.error, isA<AppError>());
  });
}

class _FakeReceivingDevicesRepository implements ReceivingDevicesRepository {
  _FakeReceivingDevicesRepository({this.error});

  final Object? error;
  final requestIds = <String>[];

  @override
  Future<List<ReceivingDoor>> fetchReceivingDoors({
    required String requestId,
  }) async {
    requestIds.add(requestId);
    if (error != null) throw error!;
    return const [
      ReceivingDoor(
        shareId: 1,
        doorId: 2,
        name: 'Main gate',
        ownerEmail: 'owner@example.com',
        expiresAt: null,
      ),
    ];
  }
}
