import 'dart:async';

import 'package:flinx/features/home/application/providers.dart';
import 'package:flinx/features/home/domain/repositories/home_door_repository.dart';
import 'package:flinx/features/home/domain/use_cases/reset_home_door_cover_use_case.dart';
import 'package:flinx/features/home/presentation/widgets/device_customize_dialog.dart';
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

  testWidgets('resets the default picture once and closes the dialog', (
    tester,
  ) async {
    final repository = _ResetCoverRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          resetHomeDoorCoverUseCaseProvider.overrideWithValue(
            ResetHomeDoorCoverUseCase(repository: repository),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () =>
                    showDeviceCustomizeDialog(context, device: device),
                child: const Text('Open customize'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open customize'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Default picture'));
    await tester.tap(find.text('Default picture'));
    await tester.pump();

    expect(repository.resetCalls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    repository.completeReset();
    await tester.pumpAndSettle();

    expect(repository.doorId, 12);
    expect(repository.requestId, startsWith('home-reset-door-cover-12-'));
    expect(find.text('Default picture'), findsNothing);
  });
}

class _ResetCoverRepository implements HomeDoorRepository {
  final Completer<void> _resetCompleter = Completer<void>();
  var resetCalls = 0;
  int? doorId;
  String? requestId;

  void completeReset() => _resetCompleter.complete();

  @override
  Future<List<DeviceSummary>> fetchDoors({
    required int sceneId,
    required String requestId,
  }) async => const [];

  @override
  Future<void> resetDoorCover({
    required int doorId,
    required String requestId,
  }) {
    resetCalls += 1;
    this.doorId = doorId;
    this.requestId = requestId;
    return _resetCompleter.future;
  }

  @override
  Future<void> renameDoor({
    required int doorId,
    required String name,
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

  @override
  Future<void> moveDoorToScene({
    required int doorId,
    required int sceneId,
    required String requestId,
  }) async {}
}
