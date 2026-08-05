import 'dart:async';

import 'package:flinx/features/device_control/application/device_command_controller.dart';
import 'package:flinx/features/device_control/presentation/pages/transmitter_learning_page.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flinx/platform_bridge/mock_hardware_gateway.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('shows the real pairing success returned by the controller', (
    tester,
  ) async {
    final gateway = _PairingGateway();
    final router = await _pumpPage(tester, gateway);
    addTearDown(router.dispose);

    await tester.tap(find.text('Start Learning'));
    await tester.pumpAndSettle();

    expect(gateway.actions, [RemotePairingAction.start]);
    expect(find.text('Transmitter Learning Succeed'), findsOneWidget);
    expect(find.text('Complete'), findsOneWidget);
  });

  testWidgets('shows failure and restarts the pairing request', (tester) async {
    final gateway = _PairingGateway(
      startStatuses: [RemotePairingStatus.failure, RemotePairingStatus.success],
    );
    final router = await _pumpPage(tester, gateway);
    addTearDown(router.dispose);

    await tester.tap(find.text('Start Learning'));
    await tester.pumpAndSettle();

    expect(find.text('Transmitter Learning Failed'), findsOneWidget);
    expect(find.text('Restart'), findsOneWidget);

    await tester.tap(find.text('Restart'));
    await tester.pumpAndSettle();

    expect(gateway.actions, [
      RemotePairingAction.start,
      RemotePairingAction.start,
    ]);
    expect(find.text('Transmitter Learning Succeed'), findsOneWidget);
  });

  testWidgets('keeps one start request pending and sends cancel before pop', (
    tester,
  ) async {
    final gateway = _PairingGateway(holdStartRequest: true);
    final router = await _pumpPage(tester, gateway);
    addTearDown(router.dispose);

    await tester.tap(find.text('Start Learning'));
    await tester.pump();

    expect(find.text('Learning...'), findsOneWidget);
    expect(find.text('Start Learning'), findsNothing);
    expect(gateway.actions, [RemotePairingAction.start]);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(gateway.actions, [
      RemotePairingAction.start,
      RemotePairingAction.cancel,
    ]);
    expect(find.text('Previous page'), findsOneWidget);
  });

  testWidgets('system back cancels an active pairing request', (tester) async {
    final gateway = _PairingGateway(holdStartRequest: true);
    final router = await _pumpPage(tester, gateway);
    addTearDown(router.dispose);

    await tester.tap(find.text('Start Learning'));
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(gateway.actions, [
      RemotePairingAction.start,
      RemotePairingAction.cancel,
    ]);
    expect(find.text('Previous page'), findsOneWidget);
  });
}

Future<GoRouter> _pumpPage(WidgetTester tester, _PairingGateway gateway) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('Previous page')),
      ),
      GoRoute(
        path: TransmitterLearningPage.routePath,
        builder: (_, state) => TransmitterLearningPage(
          deviceId: state.uri.queryParameters['deviceId'] ?? '',
        ),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        deviceCommandHardwareGatewayProvider.overrideWithValue(gateway),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
  unawaited(
    router.push<void>(
      '${TransmitterLearningPage.routePath}?deviceId=ios-device',
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

class _PairingGateway extends MockHardwareGateway {
  _PairingGateway({
    List<RemotePairingStatus>? startStatuses,
    this.holdStartRequest = false,
  }) : _startStatuses = startStatuses ?? const [RemotePairingStatus.success];

  final List<RemotePairingStatus> _startStatuses;
  final bool holdStartRequest;
  final List<RemotePairingAction> actions = [];
  Completer<RemotePairingResult>? _pendingStart;
  var _startCallCount = 0;

  @override
  Future<RemotePairingResult> pairRemote({
    required String requestId,
    required String deviceId,
    required RemotePairingAction action,
  }) async {
    actions.add(action);
    if (action == RemotePairingAction.cancel) {
      final pendingStart = _pendingStart;
      if (pendingStart != null && !pendingStart.isCompleted) {
        pendingStart.complete(
          RemotePairingResult(
            requestId: requestId,
            deviceId: deviceId,
            action: RemotePairingAction.start,
            status: RemotePairingStatus.failure,
            reasonCode: 0,
          ),
        );
      }
      return RemotePairingResult(
        requestId: requestId,
        deviceId: deviceId,
        action: action,
        status: RemotePairingStatus.success,
        reasonCode: 0,
      );
    }

    if (holdStartRequest) {
      _pendingStart = Completer<RemotePairingResult>();
      return _pendingStart!.future;
    }
    final status = _startStatuses[_startCallCount++];
    return RemotePairingResult(
      requestId: requestId,
      deviceId: deviceId,
      action: action,
      status: status,
      reasonCode: status == RemotePairingStatus.success ? 0 : 1,
    );
  }
}
