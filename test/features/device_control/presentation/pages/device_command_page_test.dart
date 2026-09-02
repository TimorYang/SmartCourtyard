import 'dart:async';
import 'dart:typed_data';

import 'package:flinx/app/theme/app_design_tokens.dart';
import 'package:flinx/features/add_device/application/providers.dart';
import 'package:flinx/features/add_device/domain/entities/onboarding_device_key.dart';
import 'package:flinx/features/add_device/domain/entities/onboarded_force_door.dart';
import 'package:flinx/features/add_device/domain/repositories/add_device_onboarding_repository.dart';
import 'package:flinx/features/add_device/domain/use_cases/fetch_onboarding_device_key_use_case.dart';
import 'package:flinx/features/add_device/presentation/navigation/f_box_wiring_test_route.dart';
import 'package:flinx/features/device_control/application/device_command_controller.dart';
import 'package:flinx/features/device_control/domain/entities/door_control_mode.dart';
import 'package:flinx/features/device_control/domain/entities/door_detail.dart';
import 'package:flinx/features/device_control/domain/entities/about_device_info.dart';
import 'package:flinx/features/device_control/domain/entities/door_device.dart';
import 'package:flinx/features/device_control/domain/entities/remote_door_command.dart';
import 'package:flinx/features/device_control/domain/repositories/door_detail_repository.dart';
import 'package:flinx/features/device_control/domain/repositories/remote_door_command_repository.dart';
import 'package:flinx/features/device_control/presentation/pages/device_command_page.dart';
import 'package:flinx/features/device_control/presentation/pages/device_settings_page.dart';
import 'package:flinx/features/device_control/presentation/pages/already_added_devices_page.dart';
import 'package:flinx/features/records/application/providers.dart';
import 'package:flinx/features/records/domain/entities/operation_record_page_result.dart';
import 'package:flinx/features/records/domain/repositories/operation_record_repository.dart';
import 'package:flinx/features/settings/application/providers.dart';
import 'package:flinx/features/settings/domain/entities/device_capability.dart';
import 'package:flinx/features/settings/domain/entities/device_setting.dart';
import 'package:flinx/features/settings/domain/entities/door_setting_snapshot.dart';
import 'package:flinx/features/settings/domain/repositories/device_capability_repository.dart';
import 'package:flinx/features/settings/domain/repositories/door_settings_repository.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flinx/platform_bridge/mock_hardware_gateway.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flinx/shared/widgets/flinx_door_command_button.dart';
import 'package:flinx/shared/widgets/flinx_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';

void main() {
  testWidgets('shows only loading until door detail requests complete', (
    tester,
  ) async {
    final repository = _DelayedDoorDetailRepository();

    await tester.pumpWidget(
      _buildPage(_RecordingHardwareGateway(), repository: repository),
    );

    expect(
      find.byKey(const ValueKey<String>('device-command-loading')),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Garage door'), findsNothing);
    expect(find.text('Operated cycles'), findsNothing);
    expect(find.byTooltip('More'), findsNothing);
    expect(find.byTooltip('Operation records'), findsNothing);

    repository.completeSuccess();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('device-command-loading')),
      findsNothing,
    );
    expect(find.text('Garage door'), findsOneWidget);
    expect(find.text('123'), findsOneWidget);
  });

  testWidgets('shows a standalone retry state when initial loading fails', (
    tester,
  ) async {
    final repository = _FailThenDelayedDoorDetailRepository();

    await _pumpDevicePage(
      tester,
      _RecordingHardwareGateway(),
      repository: repository,
    );

    expect(
      find.byKey(const ValueKey<String>('device-command-load-failure')),
      findsOneWidget,
    );
    expect(
      find.text('Unable to load device controls. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Garage door'), findsNothing);
    expect(find.text('Operated cycles'), findsNothing);
    expect(find.byTooltip('More'), findsNothing);

    repository.shouldFail = false;
    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('device-command-loading')),
      findsOneWidget,
    );
    expect(
      find.text('Unable to load device controls. Please try again.'),
      findsNothing,
    );

    repository.completeSuccess();
    await tester.pumpAndSettle();

    expect(find.text('Garage door'), findsOneWidget);
    expect(find.text('Closed'), findsOneWidget);
  });

  testWidgets('renders garage door controls and sends primary commands', (
    tester,
  ) async {
    final gateway = _RecordingHardwareGateway();
    final reports = <_ReportedOperation>[];

    await _pumpDevicePage(
      tester,
      gateway,
      operationRecordRepository: _EmptyOperationRecordRepository(
        reports: reports,
      ),
    );

    expect(find.text('Garage door'), findsOneWidget);
    expect(find.text('Operated cycles'), findsOneWidget);
    expect(find.text('123'), findsOneWidget);
    expect(find.text('Remaining'), findsOneWidget);
    expect(find.text('4567'), findsOneWidget);
    expect(find.text('Closed'), findsOneWidget);
    expect(find.text('LED'), findsOneWidget);
    expect(find.text('Auto close'), findsOneWidget);
    expect(find.text('Open reminder'), findsOneWidget);
    expect(find.text('10 min'), findsOneWidget);
    expect(find.text('Partial open'), findsOneWidget);
    expect(find.text('More settings'), findsOneWidget);
    expect(find.text('60 cm'), findsOneWidget);
    expect(
      tester
          .widget<FlinxSwitch>(find.byKey(const ValueKey<String>('led-switch')))
          .value,
      isFalse,
    );
    expect(
      tester
          .widget<FlinxSwitch>(
            find.byKey(const ValueKey<String>('auto-close-switch')),
          )
          .value,
      isTrue,
    );

    await tester.tap(find.byTooltip('Open'));
    await tester.pumpAndSettle();

    expect(gateway.commands.last, DoorCommand.open);
    expect(gateway.deviceIds.last, 'mock-ble-device');
    expect(gateway.authenticatedDeviceIds, ['mock-ble-device']);
    expect(find.text('Open command sent (0x1001).'), findsOneWidget);
    expect(reports.single.action, OperationReportAction.open);
    expect(reports.single.operationSource, OperationReportSource.bluetooth);

    await tester.tap(find.byTooltip('Stop'));
    await tester.pumpAndSettle();

    expect(gateway.commands.last, DoorCommand.stop);
    expect(find.text('Stop command sent (0x1003).'), findsOneWidget);
    expect(reports.last.action, OperationReportAction.stop);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(gateway.commands.last, DoorCommand.close);
    expect(find.text('Close command sent (0x1002).'), findsOneWidget);
    expect(reports.last.action, OperationReportAction.close);
  });

  test('maps F-Box control mode using the label before the numeric value', () {
    expect(
      DoorControlMode.fromBackend(value: 1, label: 'PB wiring'),
      DoorControlMode.pb,
    );
    expect(
      DoorControlMode.fromBackend(value: 2, label: 'O/S/C wiring'),
      DoorControlMode.osc,
    );
  });

  test('maps F-Box control mode numeric fallback and unknown values', () {
    expect(DoorControlMode.fromBackend(value: 1), DoorControlMode.osc);
    expect(DoorControlMode.fromBackend(value: 2), DoorControlMode.pb);
    expect(
      DoorControlMode.fromBackend(value: 99, label: 'unknown'),
      DoorControlMode.osc,
    );
    expect(DoorControlMode.fromBackend(), DoorControlMode.osc);
  });

  testWidgets('renders F-Box O/S/C controls and sends commands in order', (
    tester,
  ) async {
    final gateway = _RecordingHardwareGateway();
    const fBoxDevice = DoorDevice(
      deviceId: 'fbox-device',
      sn: 'fbox-sn',
      deviceType: 'fbox',
      bleName: 'Garage door',
      bleConnectionStatus: 1,
      wifiConnectionStatus: 1,
      capabilities: ['DOOR_CONTROL'],
    );

    await _pumpDevicePage(
      tester,
      gateway,
      size: const Size(375, 812),
      repository: const _DeviceListDoorDetailRepository([
        fBoxDevice,
      ], controlMode: 1),
    );

    expect(find.text('Operated cycles'), findsNothing);
    expect(find.text('Remaining'), findsNothing);
    expect(find.text('More settings'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('fbox-device-command-osc')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('fbox-device-command-pb')),
      findsNothing,
    );
    expect(find.text('Control method'), findsOneWidget);
    expect(find.text('About the device'), findsOneWidget);

    final commandButtons = tester
        .widgetList<FlinxDoorCommandButton>(
          find.descendant(
            of: find.byKey(const ValueKey<String>('fbox-device-command-osc')),
            matching: find.byType(FlinxDoorCommandButton),
          ),
        )
        .toList();
    expect(commandButtons, hasLength(3));
    expect(commandButtons.map((button) => button.size), everyElement(52));
    expect(
      commandButtons.map((button) => button.iconSize),
      everyElement(AppSpacingTokens.deviceControlCommandButtonIconSize),
    );

    final close = find.byTooltip('Close');
    final stop = find.byTooltip('Stop');
    final open = find.byTooltip('Open');
    expect(tester.getCenter(close).dx, lessThan(tester.getCenter(stop).dx));
    expect(tester.getCenter(stop).dx, lessThan(tester.getCenter(open).dx));

    await tester.tap(close);
    await tester.pumpAndSettle();
    expect(gateway.commands.last, DoorCommand.close);

    await tester.tap(stop);
    await tester.pumpAndSettle();
    expect(gateway.commands.last, DoorCommand.stop);

    await tester.tap(open);
    await tester.pumpAndSettle();
    expect(gateway.commands.last, DoorCommand.open);
    expect(gateway.deviceIds.last, 'mock-ble-device');
  });

  testWidgets('renders the F-Box PB asset when PB is selected', (tester) async {
    final gateway = _RecordingHardwareGateway();
    const fBoxDevice = DoorDevice(
      deviceId: 'fbox-device',
      sn: 'fbox-sn',
      deviceType: 'fbox',
      bleName: 'Garage door',
      bleConnectionStatus: 1,
      wifiConnectionStatus: 1,
      capabilities: ['DOOR_CONTROL'],
    );

    await _pumpDevicePage(
      tester,
      gateway,
      repository: const _DeviceListDoorDetailRepository([
        fBoxDevice,
      ], controlMode: 2),
    );

    final pbControl = find.byKey(
      const ValueKey<String>('fbox-device-command-pb'),
    );
    expect(pbControl, findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('fbox-device-command-osc')),
      findsNothing,
    );
    final image = tester.widget<Image>(
      find.descendant(of: pbControl, matching: find.byType(Image)),
    );
    expect(
      (image.image as AssetImage).assetName,
      'assets/icons/add_device/f_box_wiring_test_pb_control.png',
    );

    await tester.tap(pbControl);
    await tester.pumpAndSettle();
    expect(gateway.commands.last, DoorCommand.pb);
    expect(find.text('PB command sent (0x1007).'), findsOneWidget);
  });

  testWidgets('uses an explicit O/S/C label before the PB numeric value', (
    tester,
  ) async {
    const fBoxDevice = DoorDevice(
      deviceId: 'fbox-device',
      sn: 'fbox-sn',
      deviceType: 'fbox',
      bleName: 'Garage door',
      bleConnectionStatus: 1,
      wifiConnectionStatus: 1,
      capabilities: ['DOOR_CONTROL'],
    );

    await _pumpDevicePage(
      tester,
      _RecordingHardwareGateway(),
      repository: const _DeviceListDoorDetailRepository(
        [fBoxDevice],
        controlMode: 2,
        controlModeLabel: 'O/S/C wiring',
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('fbox-device-command-osc')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('fbox-device-command-pb')),
      findsNothing,
    );
  });

  testWidgets('opens F-Box control method with the device-command source', (
    tester,
  ) async {
    const fBoxDevice = DoorDevice(
      deviceId: 'fbox-device',
      sn: 'fbox-sn',
      deviceType: 'fbox',
      bleName: 'Garage door',
      bleConnectionStatus: 1,
      wifiConnectionStatus: 1,
      capabilities: ['DOOR_CONTROL'],
    );

    await _pumpDevicePage(
      tester,
      _RecordingHardwareGateway(),
      repository: const _DeviceListDoorDetailRepository([fBoxDevice]),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('fbox-control-method-action')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('wiring source=device-command door=12 device=fbox-device'),
      findsOneWidget,
    );
  });

  testWidgets('requires Bluetooth before opening F-Box control method', (
    tester,
  ) async {
    const fBoxDevice = DoorDevice(
      deviceId: 'fbox-device',
      sn: 'fbox-sn',
      deviceType: 'fbox',
      bleName: 'Garage door',
      bleConnectionStatus: 1,
      wifiConnectionStatus: 1,
      capabilities: ['DOOR_CONTROL'],
    );

    await _pumpDevicePage(
      tester,
      _DisconnectedHardwareGateway(),
      repository: const _DeviceListDoorDetailRepository([fBoxDevice]),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('fbox-control-method-action')),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text(
        'Connect the selected device via Bluetooth to use Control method.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('wiring source='), findsNothing);
    toastification.dismissAll(delayForAnimation: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  });

  testWidgets('opens About the device with the selected F-Box identifiers', (
    tester,
  ) async {
    const fBoxDevice = DoorDevice(
      deviceId: 'fbox-device',
      sn: 'fbox-sn',
      deviceType: 'fbox',
      bleName: 'Garage door',
      bleConnectionStatus: 1,
      wifiConnectionStatus: 1,
      capabilities: ['DOOR_CONTROL'],
    );

    await _pumpDevicePage(
      tester,
      _RecordingHardwareGateway(),
      repository: const _DeviceListDoorDetailRepository([fBoxDevice]),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('fbox-about-device-action')),
    );
    await tester.pumpAndSettle();

    expect(find.text('about door=12 device=fbox-device'), findsOneWidget);
  });

  testWidgets('centers and constrains F-Box content on a wide window', (
    tester,
  ) async {
    const fBoxDevice = DoorDevice(
      deviceId: 'fbox-device',
      sn: 'fbox-sn',
      deviceType: 'fbox',
      bleName: 'Garage door',
      bleConnectionStatus: 1,
      wifiConnectionStatus: 1,
      capabilities: ['DOOR_CONTROL'],
    );

    await _pumpDevicePage(
      tester,
      _RecordingHardwareGateway(),
      size: const Size(1000, 900),
      repository: const _DeviceListDoorDetailRepository([fBoxDevice]),
    );

    final card = find.byKey(
      const ValueKey<String>('fbox-control-method-action'),
    );
    expect(tester.getTopLeft(card).dx, greaterThan(100));
    expect(tester.getSize(card).width, lessThan(350));
  });

  testWidgets('allows a short F-Box window to scroll without overflow', (
    tester,
  ) async {
    const fBoxDevice = DoorDevice(
      deviceId: 'fbox-device',
      sn: 'fbox-sn',
      deviceType: 'fbox',
      bleName: 'Garage door',
      bleConnectionStatus: 1,
      wifiConnectionStatus: 1,
      capabilities: ['DOOR_CONTROL'],
    );

    await _pumpDevicePage(
      tester,
      _RecordingHardwareGateway(),
      size: const Size(375, 500),
      repository: const _DeviceListDoorDetailRepository([fBoxDevice]),
    );

    expect(tester.takeException(), isNull);
    final scroll = find.byKey(
      const PageStorageKey<String>('device-command-fbox-scroll'),
    );
    expect(scroll, findsOneWidget);
    await tester.drag(scroll, const Offset(0, -250));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('fbox-about-device-action')),
    );
    expect(find.text('About the device'), findsOneWidget);
  });

  testWidgets('updates the door frame and state from attribute reports', (
    tester,
  ) async {
    final gateway = _RecordingHardwareGateway();
    await _pumpDevicePage(
      tester,
      gateway,
      repository: const _FakeDoorDetailRepository(
        doorType: 0,
        positionPercent: 0,
      ),
    );

    expect(_doorHeroAsset(tester), endsWith('garage_door_01.png'));
    expect(find.text('Closed'), findsOneWidget);
    expect(find.text('Closed · 0%'), findsNothing);
    final initialDoorHeroImage = _doorHeroImage(tester);
    final initialDoorHeroElement = tester.element(
      find.descendant(
        of: find.byKey(const ValueKey<String>('door-hero-frame')),
        matching: find.byType(Image),
      ),
    );
    expect(initialDoorHeroImage.gaplessPlayback, isTrue);

    gateway.emitDeviceAttributeSnapshot(
      DeviceAttributeSnapshot(
        deviceId: 'mock-ble-device',
        sequence: 1,
        timestampMillis: 1,
        origin: DeviceAttributeReportOrigin.activeReport,
        attributes: [
          DeviceAttribute(id: 0x2715, value: Uint8List.fromList([0x00])),
          DeviceAttribute(id: 0x271C, value: Uint8List.fromList([50])),
        ],
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Opening · 50%'), findsOneWidget);

    expect(_doorHeroAsset(tester), endsWith('garage_door_11.png'));
    final updatedDoorHeroElement = tester.element(
      find.descendant(
        of: find.byKey(const ValueKey<String>('door-hero-frame')),
        matching: find.byType(Image),
      ),
    );
    expect(updatedDoorHeroElement, same(initialDoorHeroElement));

    gateway.emitDeviceAttributeSnapshot(
      DeviceAttributeSnapshot(
        deviceId: 'mock-ble-device',
        sequence: 2,
        timestampMillis: 2,
        origin: DeviceAttributeReportOrigin.activeReport,
        attributes: [
          DeviceAttribute(id: 0x2715, value: Uint8List.fromList([0x00])),
          DeviceAttribute(id: 0x271C, value: Uint8List.fromList([100])),
        ],
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Opened'), findsOneWidget);
    expect(find.text('Opened · 100%'), findsNothing);
    expect(_doorHeroAsset(tester), endsWith('garage_door_20.png'));

    gateway.emitDeviceAttributeSnapshot(
      DeviceAttributeSnapshot(
        deviceId: 'mock-ble-device',
        sequence: 3,
        timestampMillis: 3,
        origin: DeviceAttributeReportOrigin.activeReport,
        attributes: [
          DeviceAttribute(id: 0x2715, value: Uint8List.fromList([0x02])),
          DeviceAttribute(id: 0x271C, value: Uint8List.fromList([50])),
        ],
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Closing · 50%'), findsOneWidget);
    expect(_doorHeroAsset(tester), endsWith('garage_door_11.png'));

    gateway.emitDeviceAttributeSnapshot(
      DeviceAttributeSnapshot(
        deviceId: 'mock-ble-device',
        sequence: 4,
        timestampMillis: 4,
        origin: DeviceAttributeReportOrigin.activeReport,
        attributes: [
          DeviceAttribute(id: 0x2715, value: Uint8List.fromList([0x01])),
          DeviceAttribute(id: 0x271C, value: Uint8List.fromList([50])),
        ],
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Opened · 50%'), findsOneWidget);
    expect(find.text('Stopped · 50%'), findsNothing);

    gateway.emitDeviceAttributeSnapshot(
      DeviceAttributeSnapshot(
        deviceId: 'mock-ble-device',
        sequence: 5,
        timestampMillis: 5,
        origin: DeviceAttributeReportOrigin.activeReport,
        attributes: [
          DeviceAttribute(id: 0x2715, value: Uint8List.fromList([0x02])),
          DeviceAttribute(id: 0x271C, value: Uint8List.fromList([0])),
        ],
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Closed'), findsOneWidget);
    expect(find.text('Closed · 0%'), findsNothing);
    expect(_doorHeroAsset(tester), endsWith('garage_door_01.png'));
  });

  testWidgets('uses swing gate frames for the reported position', (
    tester,
  ) async {
    final gateway = _RecordingHardwareGateway();
    await _pumpDevicePage(
      tester,
      gateway,
      repository: const _FakeDoorDetailRepository(
        doorType: 3,
        positionPercent: 100,
      ),
    );

    expect(_doorHeroAsset(tester), endsWith('swing_door_20.png'));
  });

  testWidgets('quick actions send light, partial open, and open settings', (
    tester,
  ) async {
    final gateway = _RecordingHardwareGateway();
    final reports = <_ReportedOperation>[];

    await _pumpDevicePage(
      tester,
      gateway,
      operationRecordRepository: _EmptyOperationRecordRepository(
        reports: reports,
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('led-switch')));
    await tester.pumpAndSettle();

    expect(gateway.commands.last, DoorCommand.lightOn);
    expect(find.text('Turn LED on command sent (0x1005).'), findsOneWidget);
    expect(reports.single.action, OperationReportAction.ledOn);
    expect(reports.single.operationSource, OperationReportSource.bluetooth);

    final partialOpenAction = find.byKey(
      const ValueKey<String>('partial-open-action'),
    );
    await tester.ensureVisible(partialOpenAction);
    await tester.drag(find.byType(ListView).first, const Offset(0, -80));
    await tester.pumpAndSettle();
    await tester.tap(partialOpenAction);
    await tester.pumpAndSettle();

    expect(gateway.commands.last, DoorCommand.partialOpen);
    expect(find.text('Partial open command sent (0x1004).'), findsOneWidget);
    expect(reports, hasLength(1));

    final moreSettingsAction = find.byKey(
      const ValueKey<String>('more-settings-action'),
    );
    await tester.ensureVisible(moreSettingsAction);
    await tester.drag(find.byType(ListView).first, const Offset(0, -80));
    await tester.pumpAndSettle();
    await tester.tap(moreSettingsAction);
    await tester.pumpAndSettle();

    expect(gateway.queryCount, 0);
    expect(find.text('Setting'), findsOneWidget);
    expect(find.text('Transmitter management'), findsOneWidget);
    expect(
      tester
          .widget<DeviceSettingsPage>(find.byType(DeviceSettingsPage))
          .bleName,
      'Garage door',
    );
  });

  testWidgets(
    'partial-open position badge saves a level without sending a command',
    (tester) async {
      final gateway = _RecordingHardwareGateway();
      final reports = <_ReportedOperation>[];
      await _pumpDevicePage(
        tester,
        gateway,
        operationRecordRepository: _EmptyOperationRecordRepository(
          reports: reports,
        ),
      );

      final positionAction = find.byKey(
        const ValueKey<String>('partial-open-position-action'),
      );
      await tester.ensureVisible(positionAction);
      await tester.tap(positionAction);
      await tester.pumpAndSettle();

      expect(find.text('Partial open height'), findsOneWidget);
      expect(find.text('80 cm'), findsOneWidget);
      final wheel = tester.widget<ListWheelScrollView>(
        find.byType(ListWheelScrollView),
      );
      expect(
        (wheel.controller! as FixedExtentScrollController).selectedItem,
        0,
      );

      await tester.drag(find.byType(ListWheelScrollView), const Offset(0, -50));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(gateway.attributeWriteCount, 1);
      expect(gateway.writtenAttributes.single.id, 0x2711);
      expect(gateway.writtenAttributes.single.unsignedValue, 2);
      expect(gateway.commands, isEmpty);
      expect(find.text('80 cm'), findsOneWidget);
      expect(reports.single.action, OperationReportAction.partialOpenChanged);
      expect(reports.single.operationSource, OperationReportSource.bluetooth);
    },
  );

  testWidgets('partial-open position badge blocks duplicate writes', (
    tester,
  ) async {
    final gateway = _DelayedAttributeWriteHardwareGateway();
    addTearDown(gateway.completeWrite);
    await _pumpDevicePage(tester, gateway);

    final positionAction = find.byKey(
      const ValueKey<String>('partial-open-position-action'),
    );
    await tester.ensureVisible(positionAction);
    await tester.tap(positionAction);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListWheelScrollView), const Offset(0, -50));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(gateway.attributeWriteCount, 1);
    await tester.tap(positionAction);
    await tester.pump();
    expect(gateway.attributeWriteCount, 1);
    expect(find.byType(ListWheelScrollView), findsNothing);

    gateway.completeWrite();
    await tester.pumpAndSettle();
    expect(find.text('80 cm'), findsOneWidget);
    expect(gateway.commands, isEmpty);
  });

  testWidgets('partial-open position badge is inert without level options', (
    tester,
  ) async {
    final gateway = _RecordingHardwareGateway();
    await _pumpDevicePage(
      tester,
      gateway,
      capabilityRepository: const _SettingsDeviceCapabilityRepository(
        partialOpenOptions: [],
      ),
    );

    final positionAction = find.byKey(
      const ValueKey<String>('partial-open-position-action'),
    );
    await tester.ensureVisible(positionAction);
    await tester.tap(positionAction);
    await tester.pumpAndSettle();

    expect(find.byType(ListWheelScrollView), findsNothing);
    expect(gateway.attributeWriteCount, 0);
    expect(gateway.commands, isEmpty);
  });

  testWidgets(
    'shared users cannot edit partial-open height without level permission',
    (tester) async {
      final gateway = _RecordingHardwareGateway();
      await _pumpDevicePage(
        tester,
        gateway,
        repository: const _FakeDoorDetailRepository(
          relationType: 1,
          effectiveCapabilities: ['PARTIAL_OPEN'],
        ),
      );

      final positionAction = find.byKey(
        const ValueKey<String>('partial-open-position-action'),
      );
      await tester.ensureVisible(positionAction);
      await tester.tap(positionAction);
      await tester.pumpAndSettle();

      expect(find.byType(ListWheelScrollView), findsNothing);
      expect(gateway.attributeWriteCount, 0);
      expect(gateway.commands, isEmpty);
      expect(
        find.text("You don't have permission to use this control."),
        findsOneWidget,
      );
      toastification.dismissAll(delayForAnimation: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    },
  );

  testWidgets('failed partial-open level writes keep the previous position', (
    tester,
  ) async {
    final gateway = _FailingAttributeWriteHardwareGateway();
    await _pumpDevicePage(tester, gateway);

    final positionAction = find.byKey(
      const ValueKey<String>('partial-open-position-action'),
    );
    await tester.ensureVisible(positionAction);
    await tester.tap(positionAction);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListWheelScrollView), const Offset(0, -50));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(gateway.attributeWriteCount, 1);
    expect(gateway.commands, isEmpty);
    expect(find.text('60 cm'), findsOneWidget);
    expect(
      find.text('Unable to save the partial-open position. Please try again.'),
      findsOneWidget,
    );
    toastification.dismissAll(delayForAnimation: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  });

  testWidgets('partial-open position badge requires Bluetooth', (tester) async {
    final gateway = _DisconnectedHardwareGateway();
    await _pumpDevicePage(tester, gateway);

    final positionAction = find.byKey(
      const ValueKey<String>('partial-open-position-action'),
    );
    await tester.ensureVisible(positionAction);
    await tester.tap(positionAction);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text(
        'Connect the selected device via Bluetooth to use Partial open height.',
      ),
      findsOneWidget,
    );
    expect(find.byType(ListWheelScrollView), findsNothing);
    expect(gateway.attributeWriteCount, 0);
    expect(gateway.commands, isEmpty);
    toastification.dismissAll(delayForAnimation: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  });

  testWidgets(
    'writes auto close through attributes and reminder through cmd 0x0E09',
    (tester) async {
      final gateway = _RecordingHardwareGateway();
      final reports = <_ReportedOperation>[];
      await _pumpDevicePage(
        tester,
        gateway,
        operationRecordRepository: _EmptyOperationRecordRepository(
          reports: reports,
        ),
      );

      final autoCloseSwitch = find.byKey(
        const ValueKey<String>('auto-close-switch'),
      );
      await tester.tap(autoCloseSwitch);
      await tester.pumpAndSettle();
      await tester.tap(autoCloseSwitch);
      await tester.pumpAndSettle();

      final reminderSwitch = find.byKey(
        const ValueKey<String>('open-reminder-switch'),
      );
      expect(tester.widget<FlinxSwitch>(reminderSwitch).value, isTrue);

      await tester.tap(reminderSwitch);
      await tester.pumpAndSettle();
      await tester.tap(reminderSwitch);
      await tester.pumpAndSettle();

      final snapshot = await gateway.queryDeviceAttributes(
        requestId: 'verify-toggle-attributes',
        deviceId: 'mock-ble-device',
      );
      expect(
        snapshot.attributes
            .singleWhere(
              (attribute) =>
                  attribute.id == DeviceSettingKey.autoCloseTime.attributeId,
            )
            .unsignedValue,
        15,
      );
      expect(
        snapshot.attributes.any((attribute) => attribute.id == 0x2728),
        isFalse,
      );
      expect(gateway.doorOpenReminderValues, <int>[0, 10]);
      final autoCloseWrites = gateway.writtenAttributes.where(
        (attribute) => attribute.id == 0x2712,
      );
      expect(autoCloseWrites.map((attribute) => attribute.unsignedValue), <int>[
        0,
        15,
      ]);
      expect(gateway.attributeWriteCount, 2);
      expect(reports.map((report) => report.action), [
        OperationReportAction.autoCloseToggle,
        OperationReportAction.autoCloseToggle,
        OperationReportAction.doorOpenReminderToggle,
        OperationReportAction.doorOpenReminderToggle,
      ]);
    },
  );

  testWidgets('reads 0x2725 but writes auto-close toggles to 0x2712', (
    tester,
  ) async {
    final gateway = _RecordingHardwareGateway(
      autoCloseAttributeId: 0x2725,
      autoCloseValue: 75,
    );
    await _pumpDevicePage(tester, gateway);

    final autoCloseSwitch = find.byKey(
      const ValueKey<String>('auto-close-switch'),
    );
    expect(tester.widget<FlinxSwitch>(autoCloseSwitch).value, isTrue);

    await tester.tap(autoCloseSwitch);
    await tester.pumpAndSettle();
    await tester.tap(autoCloseSwitch);
    await tester.pumpAndSettle();

    final writes = gateway.writtenAttributes
        .where((attribute) => attribute.id == 0x2712)
        .toList();
    expect(writes, hasLength(2));
    expect(writes[0].value, Uint8List.fromList(<int>[0x00]));
    expect(writes[1].value, Uint8List.fromList(<int>[0x0F]));
    expect(
      gateway.writtenAttributes.any((attribute) => attribute.id == 0x2725),
      isFalse,
    );
  });

  testWidgets('restores reminder switch when cmd 0x0E09 is rejected', (
    tester,
  ) async {
    final gateway = _FailingDoorOpenReminderHardwareGateway();
    await _pumpDevicePage(tester, gateway);

    final reminderSwitch = find.byKey(
      const ValueKey<String>('open-reminder-switch'),
    );
    expect(tester.widget<FlinxSwitch>(reminderSwitch).value, isTrue);

    await tester.tap(reminderSwitch);
    await tester.pumpAndSettle();

    expect(tester.widget<FlinxSwitch>(reminderSwitch).value, isTrue);
    expect(gateway.attributeWriteCount, 0);
  });

  testWidgets('prompts for Bluetooth for BLE-only quick actions', (
    tester,
  ) async {
    final gateway = _DisconnectedHardwareGateway();
    await _pumpDevicePage(tester, gateway);

    await tester.tap(find.byKey(const ValueKey<String>('auto-close-switch')));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester
          .widget<FlinxSwitch>(
            find.byKey(const ValueKey<String>('auto-close-switch')),
          )
          .value,
      isTrue,
    );
    expect(
      find.text('Connect the selected device via Bluetooth to use Auto close.'),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('open-reminder-switch')),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text(
        'Connect the selected device via Bluetooth to use Open reminder.',
      ),
      findsOneWidget,
    );

    final partialOpenAction = find.byKey(
      const ValueKey<String>('partial-open-action'),
    );
    await tester.ensureVisible(partialOpenAction);
    await tester.tap(partialOpenAction);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text(
        'Connect the selected device via Bluetooth to use Partial open.',
      ),
      findsOneWidget,
    );
    expect(gateway.commands, isEmpty);
    expect(gateway.attributeWriteCount, 0);
    toastification.dismissAll(delayForAnimation: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  });

  testWidgets('disables controls whose capabilities are absent', (
    tester,
  ) async {
    final gateway = _RecordingHardwareGateway();

    await _pumpDevicePage(
      tester,
      gateway,
      repository: const _FakeDoorDetailRepository(
        capabilities: ['DOOR_CONTROL'],
      ),
    );

    expect(
      tester
          .widget<FlinxSwitch>(find.byKey(const ValueKey<String>('led-switch')))
          .enabled,
      isFalse,
    );
    expect(
      tester
          .widget<FlinxSwitch>(
            find.byKey(const ValueKey<String>('auto-close-switch')),
          )
          .enabled,
      isFalse,
    );
    expect(
      tester
          .widget<FlinxSwitch>(
            find.byKey(const ValueKey<String>('open-reminder-switch')),
          )
          .enabled,
      isFalse,
    );
    expect(
      tester
          .widget<InkWell>(
            find.descendant(
              of: find.byKey(const ValueKey<String>('partial-open-action')),
              matching: find.byType(InkWell),
            ),
          )
          .onTap,
      isNull,
    );

    await tester.tap(find.byTooltip('Open'));
    await tester.pumpAndSettle();

    expect(gateway.commands, [DoorCommand.open]);
  });

  testWidgets('shows a permission toast for unavailable shared-user controls', (
    tester,
  ) async {
    final gateway = _RecordingHardwareGateway();
    await _pumpDevicePage(
      tester,
      gateway,
      repository: const _FakeDoorDetailRepository(
        relationType: 1,
        effectiveCapabilities: [],
      ),
    );

    Future<void> expectPermissionToast(Finder target) async {
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(
        find.text("You don't have permission to use this control."),
        findsOneWidget,
      );
      toastification.dismissAll(delayForAnimation: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    await expectPermissionToast(find.byTooltip('Open'));
    await expectPermissionToast(
      find.byKey(const ValueKey<String>('led-switch')),
    );
    await expectPermissionToast(
      find.byKey(const ValueKey<String>('auto-close-switch')),
    );
    await expectPermissionToast(
      find.byKey(const ValueKey<String>('open-reminder-switch')),
    );
    await expectPermissionToast(
      find.byKey(const ValueKey<String>('partial-open-action')),
    );
    await expectPermissionToast(
      find.byKey(const ValueKey<String>('partial-open-position-action')),
    );

    expect(gateway.commands, isEmpty);
    expect(gateway.attributeWriteCount, 0);
  });

  testWidgets('owner uses the selected device capabilities', (tester) async {
    final gateway = _RecordingHardwareGateway();

    await _pumpDevicePage(
      tester,
      gateway,
      repository: const _FakeDoorDetailRepository(
        relationType: 0,
        effectiveCapabilities: [],
      ),
    );

    expect(
      tester
          .widget<FlinxSwitch>(find.byKey(const ValueKey<String>('led-switch')))
          .enabled,
      isTrue,
    );
    expect(
      tester
          .widget<FlinxSwitch>(
            find.byKey(const ValueKey<String>('auto-close-switch')),
          )
          .enabled,
      isTrue,
    );
    expect(
      tester
          .widget<FlinxSwitch>(
            find.byKey(const ValueKey<String>('open-reminder-switch')),
          )
          .enabled,
      isTrue,
    );
  });

  testWidgets(
    'shared user uses the intersection of effective and device capabilities',
    (tester) async {
      final gateway = _RecordingHardwareGateway();

      await _pumpDevicePage(
        tester,
        gateway,
        repository: const _FakeDoorDetailRepository(
          relationType: 1,
          effectiveCapabilities: ['DOOR_CONTROL', 'LED_CONTROL'],
        ),
      );

      expect(
        tester
            .widget<FlinxSwitch>(
              find.byKey(const ValueKey<String>('led-switch')),
            )
            .enabled,
        isTrue,
      );
      expect(
        tester
            .widget<FlinxSwitch>(
              find.byKey(const ValueKey<String>('auto-close-switch')),
            )
            .enabled,
        isFalse,
      );
      expect(
        tester
            .widget<FlinxSwitch>(
              find.byKey(const ValueKey<String>('open-reminder-switch')),
            )
            .enabled,
        isFalse,
      );

      final partialOpenAction = find.byKey(
        const ValueKey<String>('partial-open-action'),
      );
      await tester.ensureVisible(partialOpenAction);
      await tester.tap(partialOpenAction);
      await tester.pumpAndSettle();
      expect(gateway.commands, isEmpty);
      toastification.dismissAll(delayForAnimation: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byTooltip('Open'));
      await tester.pumpAndSettle();
      expect(gateway.commands, [DoorCommand.open]);
    },
  );

  testWidgets('missing relation type is treated as a non-owner', (
    tester,
  ) async {
    final gateway = _RecordingHardwareGateway();

    await _pumpDevicePage(
      tester,
      gateway,
      repository: const _FakeDoorDetailRepository(
        relationType: null,
        effectiveCapabilities: ['DOOR_CONTROL'],
      ),
    );

    expect(
      tester
          .widget<FlinxSwitch>(find.byKey(const ValueKey<String>('led-switch')))
          .enabled,
      isFalse,
    );
    await tester.tap(find.byTooltip('Open'));
    await tester.pumpAndSettle();
    expect(gateway.commands, [DoorCommand.open]);
  });

  testWidgets('unknown relation type is treated as a non-owner', (
    tester,
  ) async {
    final gateway = _RecordingHardwareGateway();

    await _pumpDevicePage(
      tester,
      gateway,
      repository: const _FakeDoorDetailRepository(
        relationType: 99,
        effectiveCapabilities: ['DOOR_CONTROL'],
      ),
    );

    expect(
      tester
          .widget<FlinxSwitch>(find.byKey(const ValueKey<String>('led-switch')))
          .enabled,
      isFalse,
    );
    await tester.tap(find.byTooltip('Open'));
    await tester.pumpAndSettle();
    expect(gateway.commands, [DoorCommand.open]);
  });

  testWidgets(
    'shared user with no effective capabilities cannot control devices',
    (tester) async {
      final gateway = _RecordingHardwareGateway();

      await _pumpDevicePage(
        tester,
        gateway,
        repository: const _FakeDoorDetailRepository(
          relationType: 1,
          effectiveCapabilities: [],
        ),
      );

      expect(
        tester
            .widget<FlinxSwitch>(
              find.byKey(const ValueKey<String>('led-switch')),
            )
            .enabled,
        isFalse,
      );
      expect(
        tester
            .widget<FlinxSwitch>(
              find.byKey(const ValueKey<String>('auto-close-switch')),
            )
            .enabled,
        isFalse,
      );
      expect(
        tester
            .widget<FlinxSwitch>(
              find.byKey(const ValueKey<String>('open-reminder-switch')),
            )
            .enabled,
        isFalse,
      );

      await tester.tap(find.byTooltip('Open'));
      await tester.pumpAndSettle();
      expect(gateway.commands, isEmpty);
      toastification.dismissAll(delayForAnimation: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    },
  );

  testWidgets('recomputes capabilities after selecting another device', (
    tester,
  ) async {
    const repository = _DeviceListDoorDetailRepository(
      [
        DoorDevice(
          deviceId: 'opener-with-led',
          sn: 'Opener with LED',
          deviceType: 'opener',
          capabilities: ['DOOR_CONTROL', 'LED_CONTROL'],
        ),
        DoorDevice(
          deviceId: 'opener-without-led',
          sn: 'Opener without LED',
          deviceType: 'opener',
          capabilities: ['DOOR_CONTROL'],
        ),
      ],
      relationType: 1,
      effectiveCapabilities: ['LED_CONTROL'],
    );

    await _pumpDevicePage(
      tester,
      _RecordingHardwareGateway(),
      repository: repository,
    );

    expect(
      tester
          .widget<FlinxSwitch>(find.byKey(const ValueKey<String>('led-switch')))
          .enabled,
      isTrue,
    );

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey<String>('already-added-device-card-Opener without LED'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<FlinxSwitch>(find.byKey(const ValueKey<String>('led-switch')))
          .enabled,
      isFalse,
    );
  });

  testWidgets('passes shared capability scope to more settings', (
    tester,
  ) async {
    await _pumpDevicePage(
      tester,
      _RecordingHardwareGateway(),
      repository: const _FakeDoorDetailRepository(
        capabilities: ['DOOR_CONTROL', 'TRANSMITTER_PAIRING'],
        relationType: 1,
        effectiveCapabilities: ['TRANSMITTER_PAIRING', 'LED_CONTROL'],
      ),
    );

    final moreSettingsAction = find.byKey(
      const ValueKey<String>('more-settings-action'),
    );
    await tester.ensureVisible(moreSettingsAction);
    await tester.tap(moreSettingsAction);
    await tester.pumpAndSettle();

    final settingsPage = tester.widget<DeviceSettingsPage>(
      find.byType(DeviceSettingsPage),
    );
    expect(settingsPage.capabilityScope?.allowedCapabilityCodes, {
      'TRANSMITTER_PAIRING',
    });
    expect(find.text('Transmitter management'), findsOneWidget);
    expect(find.text('Partial open'), findsNothing);
    expect(find.text('About the device'), findsOneWidget);
  });

  testWidgets('uses door-device list to highlight the matching fixed card', (
    tester,
  ) async {
    await _pumpDevicePage(tester, _RecordingHardwareGateway());

    expect(
      _connectionDeviceAsset(tester, 'opener'),
      'assets/icons/device_control/device_command_opener_active.png',
    );
    expect(
      _connectionDeviceAsset(tester, 'dongle'),
      'assets/icons/device_control/device_command_dongle_inactive.png',
    );
    expect(
      _connectionDeviceAsset(tester, 'fbox'),
      'assets/icons/device_control/device_command_fbox_inactive.png',
    );
    expect(
      _connectionDeviceAsset(tester, 'video'),
      'assets/icons/device_control/device_command_video_inactive.png',
    );
    expect(
      _connectionDeviceAsset(tester, 'evolution'),
      'assets/icons/device_control/device_command_evo_inactive.png',
    );
    expect(_connectionGroupAssets(tester, 'opener'), [
      'assets/icons/device_control/device_command_opener_active.png',
      'assets/icons/device_control/device_command_bluetooth_active_placeholder.png',
      'assets/icons/device_control/device_command_wifi_inactive_placeholder.png',
    ]);
    expect(_connectionGroupAssets(tester, 'video'), [
      'assets/icons/device_control/device_command_video_inactive.png',
      'assets/icons/device_control/device_command_wifi_inactive_placeholder.png',
    ]);
    expect(_hasConnectionBorder(tester, 'opener'), isTrue);
    expect(_hasConnectionBorder(tester, 'video'), isFalse);
    expect(_connectionTap(tester, 'opener'), isNotNull);
    expect(_connectionTap(tester, 'dongle'), isNull);
    expect(_connectionTap(tester, 'video'), isNull);
  });

  testWidgets(
    'uses type priority on entry and preserves an already-added selection',
    (tester) async {
      const repository = _DeviceListDoorDetailRepository([
        DoorDevice(
          deviceId: 'mock-device',
          sn: 'Fbox SN',
          deviceType: 'fbox',
          capabilities: ['DOOR_CONTROL'],
        ),
        DoorDevice(
          deviceId: 'opener-device',
          sn: 'Opener SN',
          deviceType: 'opener',
          capabilities: ['DOOR_CONTROL'],
        ),
      ]);
      await _pumpDevicePage(
        tester,
        _RecordingHardwareGateway(),
        repository: repository,
      );

      expect(_hasConnectionBorder(tester, 'opener'), isTrue);
      expect(_hasConnectionBorder(tester, 'fbox'), isFalse);

      await tester.tap(find.byTooltip('More'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('already-added-device-card-Fbox SN')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DeviceCommandPage), findsOneWidget);
      expect(_hasConnectionBorder(tester, 'opener'), isFalse);
      expect(_hasConnectionBorder(tester, 'fbox'), isTrue);
    },
  );

  testWidgets('opens the already added devices page from the more action', (
    tester,
  ) async {
    await _pumpDevicePage(tester, _RecordingHardwareGateway());

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();

    expect(find.text('Already Added'), findsOneWidget);
    expect(
      find.text('The following devices have been connected'),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('already-added-device-card-Garage door'),
      ),
      findsOneWidget,
    );
    expect(find.text('Garage door'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('already-added-add-action')),
      findsOneWidget,
    );

    await tester.tap(
      find.ancestor(
        of: find.byType(BackButtonIcon),
        matching: find.byType(IconButton),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Garage door'), findsOneWidget);
  });

  testWidgets('renders already added devices copy in Chinese', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          doorDetailRepositoryProvider.overrideWithValue(
            const _FakeDoorDetailRepository(),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AlreadyAddedDevicesPage(doorId: '12'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('已添加'), findsOneWidget);
    expect(find.text('以下设备已连接'), findsOneWidget);
    expect(find.text('智能开门器'), findsOneWidget);
    expect(find.text('Garage door'), findsOneWidget);
  });

  testWidgets('unbinds an already added device and refreshes the list', (
    tester,
  ) async {
    final repository = _UnbindDoorDetailRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [doorDetailRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AlreadyAddedDevicesPage(doorId: '12'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const ValueKey<String>('already-added-delete-action-Garage door'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey<String>('already-added-disconnect-confirm-action'),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.unboundDeviceIds, ['3']);
    expect(find.text('No connected devices'), findsOneWidget);
  });

  testWidgets('shows an error message when device unbinding fails', (
    tester,
  ) async {
    final repository = _UnbindDoorDetailRepository(shouldFail: true);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [doorDetailRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AlreadyAddedDevicesPage(doorId: '12'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const ValueKey<String>('already-added-delete-action-Garage door'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey<String>('already-added-disconnect-confirm-action'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Unable to remove device. Please try again.'),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('already-added-device-card-Garage door'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows pending state while a command is in progress', (
    tester,
  ) async {
    final gateway = _PendingCommandGateway();

    await _pumpDevicePage(tester, gateway);

    await tester.tap(find.byTooltip('Open'));
    await tester.pump();

    expect(find.text('Sending Open command (0x1001)...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    for (final button in tester.widgetList<IconButton>(
      find.byType(IconButton),
    )) {
      if (button.tooltip == 'Stop' || button.tooltip == 'Close') {
        expect(button.onPressed, isNull);
      }
    }

    gateway.complete(DoorCommand.open);
    await tester.pumpAndSettle();

    expect(find.text('Open command sent (0x1001).'), findsOneWidget);
  });

  testWidgets('switches between records and command tabs', (tester) async {
    final gateway = _RecordingHardwareGateway();

    await _pumpDevicePage(tester, gateway);

    expect(find.text('Closed'), findsOneWidget);

    await tester.tap(find.byTooltip('Operation records'));
    await tester.pumpAndSettle();

    expect(find.text('Operation Record'), findsOneWidget);

    await tester.tap(find.byTooltip('Device command'));
    await tester.pumpAndSettle();

    expect(find.text('Closed'), findsOneWidget);
    expect(find.text('Garage door'), findsOneWidget);
  });

  testWidgets('renders on a compact screen without overflow', (tester) async {
    final gateway = _RecordingHardwareGateway();
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildPage(gateway));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Security center'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('cleans all managed BLE connections when page is removed', (
    tester,
  ) async {
    final gateway = _RecordingHardwareGateway();

    await _pumpDevicePage(tester, gateway);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(gateway.disconnectAllCount, greaterThanOrEqualTo(1));
  });

  testWidgets(
    'uses remote control without BLE and renders polled door position',
    (tester) async {
      final repository = _SequencedDoorDetailRepository();
      final remoteRepository = _SuccessfulRemoteDoorCommandRepository();
      await _pumpDevicePage(
        tester,
        _DisconnectedHardwareGateway(),
        repository: repository,
        remoteRepository: remoteRepository,
        remotePollInterval: Duration.zero,
      );

      await tester.tap(find.byTooltip('Open'));
      await tester.pumpAndSettle();

      expect(remoteRepository.actions, [RemoteDoorCommandAction.open]);
      expect(find.text('Open command sent (0x1001).'), findsOneWidget);
      expect(find.text('Opened'), findsOneWidget);
      expect(find.text('Opened · 100%'), findsNothing);
      expect(_doorHeroAsset(tester), endsWith('garage_door_20.png'));
    },
  );

  testWidgets('keeps optimistic LED switch on until detail confirms it', (
    tester,
  ) async {
    final repository = _DelayedLightDoorDetailRepository();
    await _pumpDevicePage(
      tester,
      _DisconnectedHardwareGateway(),
      repository: repository,
      remoteRepository: _SuccessfulRemoteDoorCommandRepository(),
      remotePollInterval: Duration.zero,
    );
    final ledSwitch = find.byKey(const ValueKey<String>('led-switch'));

    expect(tester.widget<FlinxSwitch>(ledSwitch).value, isFalse);
    await tester.tap(ledSwitch);
    await tester.pump();

    expect(tester.widget<FlinxSwitch>(ledSwitch).value, isTrue);
    expect(tester.widget<FlinxSwitch>(ledSwitch).enabled, isFalse);

    repository.confirmLightOn();
    await tester.pumpAndSettle();

    expect(tester.widget<FlinxSwitch>(ledSwitch).value, isTrue);
    expect(tester.widget<FlinxSwitch>(ledSwitch).enabled, isTrue);
    expect(find.text('Turn LED on command sent (0x1005).'), findsOneWidget);
  });

  testWidgets('restores LED switch when detail polling times out', (
    tester,
  ) async {
    final reports = <_ReportedOperation>[];
    await _pumpDevicePage(
      tester,
      _DisconnectedHardwareGateway(),
      repository: const _RemoteLightDoorDetailRepository(ledStatus: 1),
      remoteRepository: _SuccessfulRemoteDoorCommandRepository(),
      remotePollInterval: Duration.zero,
      remotePollMaxAttempts: 1,
      operationRecordRepository: _EmptyOperationRecordRepository(
        reports: reports,
      ),
    );
    final ledSwitch = find.byKey(const ValueKey<String>('led-switch'));

    await tester.tap(ledSwitch);
    await tester.pumpAndSettle();

    expect(tester.widget<FlinxSwitch>(ledSwitch).value, isFalse);
    expect(tester.widget<FlinxSwitch>(ledSwitch).enabled, isTrue);
    expect(
      find.text('Turn LED on timed out. Check the door state and try again.'),
      findsOneWidget,
    );
    expect(reports, isEmpty);
  });
}

Widget _buildPage(
  MockHardwareGateway gateway, {
  DoorDetailRepository repository = const _FakeDoorDetailRepository(),
  DeviceCapabilityRepository capabilityRepository =
      const _SettingsDeviceCapabilityRepository(),
  DoorSettingsRepository doorSettingsRepository =
      const _CommandDoorSettingsRepository(),
  RemoteDoorCommandRepository? remoteRepository,
  OperationRecordRepository? operationRecordRepository,
  Duration remotePollInterval = const Duration(seconds: 1),
  int remotePollMaxAttempts = 6,
}) {
  return ProviderScope(
    overrides: [
      deviceCommandHardwareGatewayProvider.overrideWithValue(gateway),
      deviceSettingsHardwareGatewayProvider.overrideWithValue(gateway),
      doorDetailRepositoryProvider.overrideWithValue(repository),
      if (remoteRepository != null)
        remoteDoorCommandRepositoryProvider.overrideWithValue(remoteRepository),
      deviceCommandRemotePollIntervalProvider.overrideWithValue(
        remotePollInterval,
      ),
      deviceCommandRemotePollMaxAttemptsProvider.overrideWithValue(
        remotePollMaxAttempts,
      ),
      fetchOnboardingDeviceKeyUseCaseProvider.overrideWithValue(
        const _FakeFetchOnboardingDeviceKeyUseCase(),
      ),
      operationRecordRepositoryProvider.overrideWithValue(
        operationRecordRepository ?? const _EmptyOperationRecordRepository(),
      ),
      deviceCapabilityRepositoryProvider.overrideWithValue(
        capabilityRepository,
      ),
      doorSettingsRepositoryProvider.overrideWithValue(doorSettingsRepository),
    ],
    child: ToastificationWrapper(
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(
          initialLocation:
              '${DeviceCommandPage.routePath}?doorId=12&deviceId=mock-device',
          routes: [
            GoRoute(
              path: DeviceCommandPage.routePath,
              builder: (context, state) => DeviceCommandPage(
                doorId: state.uri.queryParameters['doorId'] ?? '',
                deviceId: state.uri.queryParameters['deviceId'] ?? '',
              ),
            ),
            GoRoute(
              path: FBoxWiringTestRoute.routePath,
              builder: (context, state) => _RouteResultPage(
                text:
                    'wiring source=${state.uri.queryParameters['source']} '
                    'door=${state.uri.queryParameters['doorId']} '
                    'device=${state.uri.queryParameters['deviceId']}',
              ),
            ),
            GoRoute(
              path: AboutDevicePage.routePath,
              builder: (context, state) => _RouteResultPage(
                text:
                    'about door=${state.uri.queryParameters['doorId']} '
                    'device=${state.uri.queryParameters['deviceId']}',
              ),
            ),
            GoRoute(
              path: DeviceSettingsPage.routePath,
              builder: (context, state) => DeviceSettingsPage(
                doorId: state.uri.queryParameters['doorId'] ?? '',
                deviceId: state.uri.queryParameters['deviceId'] ?? '',
                bleName: state.uri.queryParameters['bleName'] ?? '',
                bleDeviceId: state.uri.queryParameters['bleDeviceId'] ?? '',
                capabilityScope: state.extra is DeviceSettingsCapabilityScope
                    ? state.extra as DeviceSettingsCapabilityScope
                    : null,
              ),
            ),
            GoRoute(
              path: AlreadyAddedDevicesPage.routePath,
              builder: (context, state) => AlreadyAddedDevicesPage(
                doorId: state.uri.queryParameters['doorId'] ?? '',
                deviceId: state.uri.queryParameters['deviceId'] ?? '',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RouteResultPage extends StatelessWidget {
  const _RouteResultPage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(text)));
  }
}

class _SettingsDeviceCapabilityRepository
    implements DeviceCapabilityRepository {
  const _SettingsDeviceCapabilityRepository({
    this.partialOpenOptions = const [
      DeviceCapabilityOption(value: 1, label: '60'),
      DeviceCapabilityOption(value: 2, label: '80'),
    ],
  });

  final List<DeviceCapabilityOption> partialOpenOptions;

  @override
  Future<List<DeviceCapability>> fetchCapabilities({
    required String deviceId,
    required String requestId,
  }) async => [
    const DeviceCapability(
      code: DeviceCapabilityCode.transmitterPairing,
      label: 'Transmitter management',
    ),
    DeviceCapability(
      code: DeviceCapabilityCode.partialOpenLevel,
      label: 'Partial open height',
      unit: 'cm',
      options: partialOpenOptions,
    ),
    const DeviceCapability(
      code: DeviceCapabilityCode.autoClose,
      label: 'Auto close',
      unit: 's',
      options: [
        DeviceCapabilityOption(value: 15, label: '15'),
        DeviceCapabilityOption(value: 30, label: '30'),
        DeviceCapabilityOption(value: 75, label: '75'),
      ],
    ),
  ];
}

class _CommandDoorSettingsRepository implements DoorSettingsRepository {
  const _CommandDoorSettingsRepository();

  @override
  Future<List<DoorSettingSnapshot>> fetchSettings({
    required String doorId,
    required String requestId,
  }) async => const [
    DoorSettingSnapshot(
      code: DeviceCapabilityCode.partialOpen,
      label: 'Partial open',
      supported: true,
      configured: true,
      currentValue: 1,
      unit: 'cm',
    ),
    DoorSettingSnapshot(
      code: DeviceCapabilityCode.autoClose,
      label: 'Auto close',
      supported: true,
      configured: true,
      currentValue: 15,
      unit: 's',
    ),
  ];
}

Future<void> _pumpDevicePage(
  WidgetTester tester,
  MockHardwareGateway gateway, {
  Size size = const Size(393, 852),
  DoorDetailRepository repository = const _FakeDoorDetailRepository(),
  DeviceCapabilityRepository capabilityRepository =
      const _SettingsDeviceCapabilityRepository(),
  DoorSettingsRepository doorSettingsRepository =
      const _CommandDoorSettingsRepository(),
  RemoteDoorCommandRepository? remoteRepository,
  OperationRecordRepository? operationRecordRepository,
  Duration remotePollInterval = const Duration(seconds: 1),
  int remotePollMaxAttempts = 6,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    _buildPage(
      gateway,
      repository: repository,
      capabilityRepository: capabilityRepository,
      doorSettingsRepository: doorSettingsRepository,
      remoteRepository: remoteRepository,
      operationRecordRepository: operationRecordRepository,
      remotePollInterval: remotePollInterval,
      remotePollMaxAttempts: remotePollMaxAttempts,
    ),
  );
  await tester.pumpAndSettle();
}

String _connectionDeviceAsset(WidgetTester tester, String deviceType) {
  return _connectionGroupAssets(tester, deviceType).first;
}

List<String> _connectionGroupAssets(WidgetTester tester, String deviceType) {
  final group = find.byKey(ValueKey<String>('connection-device-$deviceType'));
  return tester
      .widgetList<Image>(
        find.descendant(of: group, matching: find.byType(Image)),
      )
      .map((image) => (image.image as AssetImage).assetName)
      .toList();
}

String _doorHeroAsset(WidgetTester tester) {
  final image = _doorHeroImage(tester);
  return (image.image as AssetImage).assetName;
}

Image _doorHeroImage(WidgetTester tester) {
  final frame = find.byKey(const ValueKey<String>('door-hero-frame'));
  return tester.widget<Image>(
    find.descendant(of: frame, matching: find.byType(Image)),
  );
}

bool _hasConnectionBorder(WidgetTester tester, String deviceType) {
  final group = find.byKey(ValueKey<String>('connection-device-$deviceType'));
  final box = tester.widget<DecoratedBox>(
    find.descendant(of: group, matching: find.byType(DecoratedBox)),
  );
  return (box.decoration as BoxDecoration).border != null;
}

GestureTapCallback? _connectionTap(WidgetTester tester, String deviceType) {
  final group = find.byKey(ValueKey<String>('connection-device-$deviceType'));
  return tester
      .widget<GestureDetector>(
        find.descendant(of: group, matching: find.byType(GestureDetector)),
      )
      .onTap;
}

class _RecordingHardwareGateway extends MockHardwareGateway {
  _RecordingHardwareGateway({
    super.autoCloseAttributeId = 0x2712,
    super.autoCloseValue = 0,
  });

  final List<DoorCommand> commands = <DoorCommand>[];
  final List<String> deviceIds = <String>[];
  final List<DeviceAttribute> writtenAttributes = <DeviceAttribute>[];
  int queryCount = 0;
  final List<String> authenticatedDeviceIds = <String>[];
  int disconnectAllCount = 0;
  int attributeWriteCount = 0;

  @override
  Future<DeviceAttributeWriteResult> setDeviceAttributes({
    required String requestId,
    required String deviceId,
    required List<DeviceAttribute> attributes,
  }) async {
    attributeWriteCount += 1;
    writtenAttributes.addAll(attributes);
    return super.setDeviceAttributes(
      requestId: requestId,
      deviceId: deviceId,
      attributes: attributes,
    );
  }

  @override
  Future<List<BleConnectionEvent>> disconnectAllManagedBleDevices({
    required String requestId,
  }) async {
    disconnectAllCount += 1;
    return super.disconnectAllManagedBleDevices(requestId: requestId);
  }

  @override
  Future<BleAuthenticationResult> authenticateBleDevice({
    required String requestId,
    required String deviceId,
    required String token,
    required String aesKey,
    required String aesKeyVersion,
  }) async {
    authenticatedDeviceIds.add(deviceId);
    return super.authenticateBleDevice(
      requestId: requestId,
      deviceId: deviceId,
      token: token,
      aesKey: aesKey,
      aesKeyVersion: aesKeyVersion,
    );
  }

  @override
  Future<CommandResult> sendDoorCommand({
    required String requestId,
    required String deviceId,
    required DoorCommand command,
  }) async {
    commands.add(command);
    deviceIds.add(deviceId);
    return super.sendDoorCommand(
      requestId: requestId,
      deviceId: deviceId,
      command: command,
    );
  }

  @override
  Future<RemoteControlListResult> queryRemotes({
    required String requestId,
    required String deviceId,
  }) async {
    queryCount += 1;
    return super.queryRemotes(requestId: requestId, deviceId: deviceId);
  }
}

class _FailingAttributeWriteHardwareGateway extends _RecordingHardwareGateway {
  @override
  Future<DeviceAttributeWriteResult> setDeviceAttributes({
    required String requestId,
    required String deviceId,
    required List<DeviceAttribute> attributes,
  }) async {
    attributeWriteCount += 1;
    writtenAttributes.addAll(attributes);
    throw StateError('attribute write failed');
  }
}

class _FailingDoorOpenReminderHardwareGateway
    extends _RecordingHardwareGateway {
  @override
  Future<CommandResult> setDoorOpenReminder({
    required String requestId,
    required String deviceId,
    required int value,
  }) async {
    return CommandResult(
      requestId: requestId,
      deviceId: deviceId,
      accepted: false,
      domainCode: 'door_open_reminder_rejected',
    );
  }
}

class _DelayedAttributeWriteHardwareGateway extends MockHardwareGateway {
  final Completer<void> _writeGate = Completer<void>();
  int attributeWriteCount = 0;
  final List<DoorCommand> commands = <DoorCommand>[];

  @override
  Future<DeviceAttributeWriteResult> setDeviceAttributes({
    required String requestId,
    required String deviceId,
    required List<DeviceAttribute> attributes,
  }) async {
    attributeWriteCount += 1;
    await _writeGate.future;
    return super.setDeviceAttributes(
      requestId: requestId,
      deviceId: deviceId,
      attributes: attributes,
    );
  }

  @override
  Future<CommandResult> sendDoorCommand({
    required String requestId,
    required String deviceId,
    required DoorCommand command,
  }) async {
    commands.add(command);
    return super.sendDoorCommand(
      requestId: requestId,
      deviceId: deviceId,
      command: command,
    );
  }

  void completeWrite() {
    if (!_writeGate.isCompleted) {
      _writeGate.complete();
    }
  }
}

class _FakeFetchOnboardingDeviceKeyUseCase
    extends FetchOnboardingDeviceKeyUseCase {
  const _FakeFetchOnboardingDeviceKeyUseCase()
    : super(repository: const _UnusedDeviceKeyRepository());

  @override
  Future<OnboardingDeviceKey> call({
    required String sn,
    required String requestId,
  }) async {
    return OnboardingDeviceKey(
      sn: sn,
      aesKey: '0123456789abcdef0123456789abcdef',
      aesKeyVersion: 'test',
    );
  }
}

class _DisconnectedHardwareGateway extends _RecordingHardwareGateway {
  @override
  Future<void> startBleScan({
    required String requestId,
    BleScanFilter filter = const BleScanFilter(),
  }) async {}
}

class _SuccessfulRemoteDoorCommandRepository
    implements RemoteDoorCommandRepository {
  final List<RemoteDoorCommandAction> actions = <RemoteDoorCommandAction>[];

  @override
  Future<RemoteDoorCommand> submitCommand({
    required String doorId,
    required RemoteDoorCommandAction action,
    required String requestId,
  }) async {
    actions.add(action);
    return RemoteDoorCommand(
      commandId: 'command-1',
      doorId: doorId,
      action: action,
      status: RemoteDoorCommandStatus.succeeded,
    );
  }
}

class _RemoteLightDoorDetailRepository implements DoorDetailRepository {
  const _RemoteLightDoorDetailRepository({required this.ledStatus});

  final int? ledStatus;

  @override
  Future<DoorDetail> fetchDoorDetail({
    required String doorId,
    required String requestId,
  }) async => _lightDoorDetail(ledStatus);

  @override
  Future<List<DoorDevice>> fetchDoorDevices({
    required String doorId,
    required String requestId,
  }) async => const [
    DoorDevice(
      deviceId: '3',
      sn: 'remote-only',
      deviceType: 'opener',
      capabilities: ['LED_CONTROL'],
    ),
  ];

  @override
  Future<AboutDeviceInfo> fetchAboutDeviceInfo({
    required String doorId,
    required String deviceId,
    required String requestId,
  }) => throw UnimplementedError();

  @override
  Future<void> unbindDoorDevice({
    required String doorId,
    required String deviceId,
    required String requestId,
  }) => throw UnimplementedError();
}

class _DelayedLightDoorDetailRepository
    extends _RemoteLightDoorDetailRepository {
  _DelayedLightDoorDetailRepository() : super(ledStatus: 1);

  final Completer<DoorDetail> _confirmation = Completer<DoorDetail>();
  var _detailFetchCount = 0;

  @override
  Future<DoorDetail> fetchDoorDetail({
    required String doorId,
    required String requestId,
  }) {
    _detailFetchCount += 1;
    if (_detailFetchCount == 1) {
      return Future<DoorDetail>.value(_lightDoorDetail(1));
    }
    return _confirmation.future;
  }

  void confirmLightOn() {
    _confirmation.complete(_lightDoorDetail(2));
  }
}

DoorDetail _lightDoorDetail(int? ledStatus) {
  return DoorDetail(
    id: '12',
    name: 'Garage door',
    doorState: DoorState.closed,
    doorStateLabel: 'Closed',
    relationType: 0,
    operatedCycles: 0,
    remainingCycles: 0,
    ledStatus: ledStatus,
  );
}

class _SequencedDoorDetailRepository implements DoorDetailRepository {
  final List<DoorDetail> _details = <DoorDetail>[
    const DoorDetail(
      id: '12',
      name: 'Garage door',
      doorState: DoorState.closed,
      doorStateLabel: 'Closed',
      relationType: 0,
      positionPercent: 0,
      operatedCycles: 0,
      remainingCycles: 0,
    ),
    const DoorDetail(
      id: '12',
      name: 'Garage door',
      doorState: DoorState.opening,
      doorStateLabel: 'Opening',
      relationType: 0,
      positionPercent: 40,
      operatedCycles: 0,
      remainingCycles: 0,
    ),
    const DoorDetail(
      id: '12',
      name: 'Garage door',
      doorState: DoorState.open,
      doorStateLabel: 'Open',
      relationType: 0,
      positionPercent: 100,
      operatedCycles: 0,
      remainingCycles: 0,
    ),
  ];

  DoorDetail? _lastDetail;

  @override
  Future<DoorDetail> fetchDoorDetail({
    required String doorId,
    required String requestId,
  }) async {
    if (_details.isNotEmpty) {
      _lastDetail = _details.removeAt(0);
    }
    return _lastDetail!;
  }

  @override
  Future<List<DoorDevice>> fetchDoorDevices({
    required String doorId,
    required String requestId,
  }) async => const [
    DoorDevice(
      deviceId: '3',
      sn: 'remote-only',
      deviceType: 'opener',
      capabilities: ['DOOR_CONTROL', 'LED_CONTROL'],
    ),
  ];

  @override
  Future<AboutDeviceInfo> fetchAboutDeviceInfo({
    required String doorId,
    required String deviceId,
    required String requestId,
  }) => throw UnimplementedError();

  @override
  Future<void> unbindDoorDevice({
    required String doorId,
    required String deviceId,
    required String requestId,
  }) {
    throw UnimplementedError();
  }
}

class _UnusedDeviceKeyRepository implements AddDeviceOnboardingRepository {
  const _UnusedDeviceKeyRepository();

  @override
  Future<void> validateBindingStatus({
    required String sn,
    required String requestId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<OnboardedForceDoor> addForceDoor({
    required String sn,
    String? doorId,
    int? sceneId,
    required int doorType,
    required String requestId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<OnboardingDeviceKey> fetchDeviceKey({
    required String sn,
    required String requestId,
  }) {
    throw UnimplementedError();
  }
}

class _FakeDoorDetailRepository implements DoorDetailRepository {
  const _FakeDoorDetailRepository({
    this.capabilities = const [
      'DOOR_CONTROL',
      'PARTIAL_OPEN',
      'PARTIAL_OPEN_LEVEL',
      'LED_CONTROL',
      'AUTO_CLOSE',
      'DOOR_OPEN_REMINDER',
    ],
    this.doorType,
    this.positionPercent,
    this.controlMode,
    this.controlModeLabel,
    this.relationType = 0,
    this.effectiveCapabilities = const <String>[],
  });

  final List<String> capabilities;
  final int? doorType;
  final double? positionPercent;
  final int? controlMode;
  final String? controlModeLabel;
  final int? relationType;
  final List<String> effectiveCapabilities;

  @override
  Future<DoorDetail> fetchDoorDetail({
    required String doorId,
    required String requestId,
  }) async {
    return DoorDetail(
      id: '12',
      name: 'Garage door',
      doorState: DoorState.closed,
      doorStateLabel: 'Closed',
      doorType: doorType,
      relationType: relationType,
      effectiveCapabilities: effectiveCapabilities,
      positionPercent: positionPercent,
      controlMode: controlMode,
      controlModeLabel: controlModeLabel,
      operatedCycles: 123,
      remainingCycles: 4567,
      ledStatus: 1,
      autoCloseEnabled: true,
      openReminderEnabled: true,
      partialOpenValue: 60,
    );
  }

  @override
  Future<List<DoorDevice>> fetchDoorDevices({
    required String doorId,
    required String requestId,
  }) async => [
    DoorDevice(
      deviceId: '3',
      sn: 'opener_B8F86211A9DC',
      deviceType: 'opener',
      bleName: 'Garage door',
      bleConnectionStatus: 1,
      wifiConnectionStatus: 1,
      capabilities: capabilities,
    ),
  ];

  @override
  Future<AboutDeviceInfo> fetchAboutDeviceInfo({
    required String doorId,
    required String deviceId,
    required String requestId,
  }) => throw UnimplementedError();

  @override
  Future<void> unbindDoorDevice({
    required String doorId,
    required String deviceId,
    required String requestId,
  }) => throw UnimplementedError();
}

class _DelayedDoorDetailRepository extends _FakeDoorDetailRepository {
  final Completer<DoorDetail> _detailCompleter = Completer<DoorDetail>();
  final Completer<List<DoorDevice>> _devicesCompleter =
      Completer<List<DoorDevice>>();

  @override
  Future<DoorDetail> fetchDoorDetail({
    required String doorId,
    required String requestId,
  }) => _detailCompleter.future;

  @override
  Future<List<DoorDevice>> fetchDoorDevices({
    required String doorId,
    required String requestId,
  }) => _devicesCompleter.future;

  void completeSuccess() {
    _detailCompleter.complete(_testDoorDetail());
    _devicesCompleter.complete(_testDoorDevices());
  }
}

class _FailThenDelayedDoorDetailRepository
    extends _DelayedDoorDetailRepository {
  bool shouldFail = true;

  @override
  Future<DoorDetail> fetchDoorDetail({
    required String doorId,
    required String requestId,
  }) {
    if (shouldFail) {
      return Future<DoorDetail>.error(StateError('detail failure'));
    }
    return super.fetchDoorDetail(doorId: doorId, requestId: requestId);
  }

  @override
  Future<List<DoorDevice>> fetchDoorDevices({
    required String doorId,
    required String requestId,
  }) {
    if (shouldFail) {
      return Future<List<DoorDevice>>.error(StateError('devices failure'));
    }
    return super.fetchDoorDevices(doorId: doorId, requestId: requestId);
  }
}

DoorDetail _testDoorDetail() {
  return const DoorDetail(
    id: '12',
    name: 'Garage door',
    doorState: DoorState.closed,
    doorStateLabel: 'Closed',
    relationType: 0,
    operatedCycles: 123,
    remainingCycles: 4567,
    ledStatus: 1,
    autoCloseEnabled: true,
    openReminderEnabled: true,
    partialOpenValue: 60,
  );
}

List<DoorDevice> _testDoorDevices() {
  return const [
    DoorDevice(
      deviceId: '3',
      sn: 'opener_B8F86211A9DC',
      deviceType: 'opener',
      bleName: 'Garage door',
      bleConnectionStatus: 1,
      wifiConnectionStatus: 1,
      capabilities: [
        'DOOR_CONTROL',
        'PARTIAL_OPEN',
        'PARTIAL_OPEN_LEVEL',
        'LED_CONTROL',
        'AUTO_CLOSE',
        'DOOR_OPEN_REMINDER',
      ],
    ),
  ];
}

class _DeviceListDoorDetailRepository extends _FakeDoorDetailRepository {
  const _DeviceListDoorDetailRepository(
    this.devices, {
    super.controlMode,
    super.controlModeLabel,
    super.relationType,
    super.effectiveCapabilities,
  });

  final List<DoorDevice> devices;

  @override
  Future<List<DoorDevice>> fetchDoorDevices({
    required String doorId,
    required String requestId,
  }) async => devices;
}

class _UnbindDoorDetailRepository extends _FakeDoorDetailRepository {
  _UnbindDoorDetailRepository({this.shouldFail = false});

  final bool shouldFail;
  List<DoorDevice> devices = <DoorDevice>[
    const DoorDevice(
      deviceId: '3',
      sn: 'opener_B8F86211A9DC',
      deviceType: 'opener',
      bleName: 'Garage door',
    ),
  ];
  final List<String> unboundDeviceIds = <String>[];

  @override
  Future<List<DoorDevice>> fetchDoorDevices({
    required String doorId,
    required String requestId,
  }) async => devices;

  @override
  Future<void> unbindDoorDevice({
    required String doorId,
    required String deviceId,
    required String requestId,
  }) async {
    unboundDeviceIds.add(deviceId);
    if (shouldFail) {
      throw StateError('unbind failure');
    }
    devices = const <DoorDevice>[];
  }
}

class _EmptyOperationRecordRepository implements OperationRecordRepository {
  const _EmptyOperationRecordRepository({this.reports});

  final List<_ReportedOperation>? reports;

  @override
  Future<void> reportOperation({
    required String doorId,
    required OperationReportAction action,
    required OperationReportSource operationSource,
    required String requestId,
  }) async {
    reports?.add(
      _ReportedOperation(
        doorId: doorId,
        action: action,
        operationSource: operationSource,
        requestId: requestId,
      ),
    );
  }

  @override
  Future<OperationRecordPageResult> fetchOperationRecords({
    required String doorId,
    required int page,
    required int pageSize,
    required String requestId,
  }) async => OperationRecordPageResult(
    records: const [],
    currentPage: page,
    pageSize: pageSize,
    total: 0,
    hasMore: false,
  );
}

class _ReportedOperation {
  const _ReportedOperation({
    required this.doorId,
    required this.action,
    required this.operationSource,
    required this.requestId,
  });

  final String doorId;
  final OperationReportAction action;
  final OperationReportSource operationSource;
  final String requestId;
}

class _PendingCommandGateway extends MockHardwareGateway {
  final Completer<CommandResult> _commandCompleter = Completer<CommandResult>();

  @override
  Future<CommandResult> sendDoorCommand({
    required String requestId,
    required String deviceId,
    required DoorCommand command,
  }) {
    return _commandCompleter.future;
  }

  void complete(DoorCommand command) {
    _commandCompleter.complete(
      CommandResult(
        requestId: 'pending-command',
        deviceId: 'mock-device',
        command: command,
        accepted: true,
      ),
    );
  }
}
