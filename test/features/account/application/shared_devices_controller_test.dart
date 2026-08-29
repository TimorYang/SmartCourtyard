import 'package:flinx/core/errors/app_error.dart';
import 'package:flinx/features/account/application/providers.dart';
import 'package:flinx/features/account/domain/entities/shared_door.dart';
import 'package:flinx/features/account/domain/repositories/shared_devices_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads shared doors and refreshes them with a request ID', () async {
    final repository = _FakeSharedDevicesRepository();
    final container = ProviderContainer(
      overrides: [
        sharedDevicesRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    expect(await container.read(sharedDevicesControllerProvider.future), const [
      SharedDoor(doorId: 1, name: 'Main gate', sharedUserCount: 2),
    ]);

    await container.read(sharedDevicesControllerProvider.notifier).refresh();

    expect(repository.requestIds, hasLength(2));
    expect(
      repository.requestIds.every((id) => id.startsWith('shared-devices-')),
      isTrue,
    );
  });

  test('exposes a refresh failure as an error state', () async {
    final container = ProviderContainer(
      overrides: [
        sharedDevicesRepositoryProvider.overrideWithValue(
          _FakeSharedDevicesRepository(
            errorAfterFirstRequest: const AppError(
              code: AppErrorCode.networkUnavailable,
              messageKey: 'sharedDevices.networkUnavailable',
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(sharedDevicesControllerProvider.future);
    await container.read(sharedDevicesControllerProvider.notifier).refresh();
    expect(container.read(sharedDevicesControllerProvider).hasError, isTrue);
  });
}

class _FakeSharedDevicesRepository implements SharedDevicesRepository {
  _FakeSharedDevicesRepository({this.errorAfterFirstRequest});

  final Object? errorAfterFirstRequest;
  final requestIds = <String>[];

  @override
  Future<List<SharedDoor>> fetchSharedDoors({required String requestId}) async {
    requestIds.add(requestId);
    if (requestIds.length > 1 && errorAfterFirstRequest != null) {
      throw errorAfterFirstRequest!;
    }
    return const [SharedDoor(doorId: 1, name: 'Main gate', sharedUserCount: 2)];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
