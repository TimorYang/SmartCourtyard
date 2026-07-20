import 'package:flinx/features/home/application/providers.dart';
import 'package:flinx/features/home/domain/repositories/home_door_repository.dart';
import 'package:flinx/features/home/domain/use_cases/rename_home_door_use_case.dart';
import 'package:flinx/features/home/presentation/widgets/device_name_dialog.dart';
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
  );

  testWidgets('enables confirm after name input and renames the device', (
    tester,
  ) async {
    final repository = _RenameDoorRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          renameHomeDoorUseCaseProvider.overrideWithValue(
            RenameHomeDoorUseCase(repository: repository),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDeviceNameDialog(context, device: device),
                child: const Text('Open name dialog'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open name dialog'));
    await tester.pumpAndSettle();

    final confirmButton = find.widgetWithText(FilledButton, 'confirm');
    expect(tester.widget<FilledButton>(confirmButton).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Garage Door');
    await tester.pump();

    expect(tester.widget<FilledButton>(confirmButton).onPressed, isNotNull);

    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    expect(repository.doorId, 12);
    expect(repository.name, 'Garage Door');
    expect(repository.requestId, startsWith('home-rename-door-12-'));
    expect(find.text('Device Name'), findsNothing);
  });
}

class _RenameDoorRepository implements HomeDoorRepository {
  int? doorId;
  String? name;
  String? requestId;

  @override
  Future<List<DeviceSummary>> fetchDoors({
    required int sceneId,
    required String requestId,
  }) async => const [];

  @override
  Future<void> renameDoor({
    required int doorId,
    required String name,
    required String requestId,
  }) async {
    this.doorId = doorId;
    this.name = name;
    this.requestId = requestId;
  }

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
  }) async {}
}
