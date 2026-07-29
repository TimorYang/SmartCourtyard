import 'package:flinx/features/home/application/providers.dart';
import 'package:flinx/features/home/domain/repositories/home_door_repository.dart';
import 'package:flinx/features/home/domain/use_cases/unbind_home_door_use_case.dart';
import 'package:flinx/features/home/presentation/widgets/device_delete_dialog.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const device = DeviceSummary(
    id: '12',
    name: 'Garage door',
    onlineState: DeviceOnlineState.online,
    bleState: BleConnectionState.connected,
    doorState: DoorState.closed,
    cycleCount: 0,
    remainingLifePercent: 100,
    sceneId: 7,
  );

  testWidgets('refreshes the current scene doors after unbinding a device', (
    tester,
  ) async {
    final repository = _UnbindDoorRepository();
    var doorListRequestCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          unbindHomeDoorUseCaseProvider.overrideWithValue(
            UnbindHomeDoorUseCase(repository: repository),
          ),
          homeDoorsBySceneProvider(device.sceneId!).overrideWith((ref) async {
            doorListRequestCount += 1;
            return const <DeviceSummary>[];
          }),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Consumer(
            builder: (context, ref, child) {
              ref.watch(homeDoorsBySceneProvider(device.sceneId!));
              return Scaffold(
                body: TextButton(
                  onPressed: () =>
                      showDeviceDeleteDialog(context, device: device),
                  child: const Text('Open delete dialog'),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(doorListRequestCount, 1);

    await tester.tap(find.text('Open delete dialog'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();

    expect(repository.doorId, 12);
    expect(repository.requestId, startsWith('home-unbind-door-12-'));
    expect(doorListRequestCount, 2);
  });
}

class _UnbindDoorRepository implements HomeDoorRepository {
  int? doorId;
  String? requestId;

  @override
  Future<List<DeviceSummary>> fetchDoors({
    required int sceneId,
    required String requestId,
  }) async => const [];

  @override
  Future<void> moveDoorToScene({
    required int doorId,
    required int sceneId,
    required String requestId,
  }) async {}

  @override
  Future<void> renameDoor({
    required int doorId,
    required String name,
    required String requestId,
  }) async {}

  @override
  Future<void> resetDoorCover({
    required int doorId,
    required String requestId,
  }) async {}

  @override
  Future<void> topDoor({
    required int doorId,
    required String requestId,
  }) async {}

  @override
  Future<void> unbindDoor({
    required int doorId,
    required String requestId,
  }) async {
    this.doorId = doorId;
    this.requestId = requestId;
  }
}
