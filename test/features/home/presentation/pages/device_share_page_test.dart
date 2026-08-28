import 'package:flinx/app/theme/app_theme.dart';
import 'package:flinx/features/home/application/door_share_controller.dart';
import 'package:flinx/features/home/application/providers.dart';
import 'package:flinx/features/home/domain/entities/door_share.dart';
import 'package:flinx/features/home/domain/repositories/door_share_repository.dart';
import 'package:flinx/features/home/domain/use_cases/create_door_share_use_case.dart';
import 'package:flinx/features/home/presentation/pages/device_share_page.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  testWidgets('loads share capabilities once when the page opens', (
    tester,
  ) async {
    var loadCount = 0;
    await tester.pumpWidget(
      _DeviceShareTestApp(
        onCapabilitiesLoad: () {
          loadCount++;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(loadCount, 1);
  });

  testWidgets(
    'administrator capabilities can be edited and reset after guest',
    (tester) async {
      await tester.pumpWidget(_DeviceShareTestApp());
      await tester.pumpAndSettle();

      expect(
        _capabilityAsset(tester, 'doorControl'),
        endsWith('garagePlaceholderCapabilitiesSelected.png'),
      );
      expect(
        _capabilityAsset(tester, 'partialOpen'),
        endsWith('garagePlaceholderCapabilitiesSelected.png'),
      );

      final partialOpen = find.byKey(
        const Key('device_share_capability_partialOpen'),
      );
      await tester.ensureVisible(partialOpen);
      await tester.pumpAndSettle();
      await tester.tap(partialOpen);
      await tester.pump();
      expect(
        _capabilityAsset(tester, 'partialOpen'),
        endsWith('garagePlaceholderCapabilitiesNoSelected.png'),
      );

      await _selectPermission(
        tester,
        currentValue: 'Administrator',
        nextValue: 'Guest',
      );
      expect(
        _capabilityAsset(tester, 'doorControl'),
        endsWith('garagePlaceholderCapabilitiesSelected.png'),
      );
      expect(
        _capabilityAsset(tester, 'partialOpen'),
        endsWith('garagePlaceholderCapabilitiesNoSelected.png'),
      );

      final doorControl = find.byKey(
        const Key('device_share_capability_doorControl'),
      );
      await tester.ensureVisible(doorControl);
      await tester.pumpAndSettle();
      await tester.tap(doorControl);
      await tester.pump();
      expect(
        _capabilityAsset(tester, 'doorControl'),
        endsWith('garagePlaceholderCapabilitiesSelected.png'),
      );

      await _selectPermission(
        tester,
        currentValue: 'Guest',
        nextValue: 'Administrator',
      );
      expect(
        _capabilityAsset(tester, 'doorControl'),
        endsWith('garagePlaceholderCapabilitiesSelected.png'),
      );
      expect(
        _capabilityAsset(tester, 'partialOpen'),
        endsWith('garagePlaceholderCapabilitiesSelected.png'),
      );
    },
  );

  testWidgets('confirm requires address and validates its email format', (
    tester,
  ) async {
    await tester.pumpWidget(_DeviceShareTestApp());

    expect(_confirmTap(tester), isNull);

    await tester.enterText(find.byType(TextField), 'not-an-email');
    await tester.pump();
    expect(_confirmTap(tester), isNotNull);

    await tester.tap(find.byKey(const Key('device_share_confirm')));
    await tester.pump();
    expect(find.text('Enter a valid email address'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'alex@example.com');
    await tester.pump();
    expect(find.text('Enter a valid email address'), findsNothing);
    expect(_confirmTap(tester), isNotNull);
  });

  testWidgets('send email defaults off and submits the selected value', (
    tester,
  ) async {
    CreateDoorShareCommand? submittedCommand;
    await tester.pumpWidget(
      _DeviceShareTestApp(
        onCreateShare: (command) {
          submittedCommand = command;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(_sendEmailSemantics(tester).properties.checked, isFalse);

    await tester.tap(find.byKey(DeviceSharePageKeys.sendEmailToggle));
    await tester.pump();

    expect(_sendEmailSemantics(tester).properties.checked, isTrue);

    await tester.enterText(find.byType(TextField), 'alex@example.com');
    await tester.pump();
    await tester.tap(find.byKey(const Key('device_share_confirm')));
    await tester.pumpAndSettle();

    expect(submittedCommand?.sendEmail, isTrue);
  });

  testWidgets('customize access end requires a confirmed time', (tester) async {
    await tester.pumpWidget(_DeviceShareTestApp());
    await tester.enterText(find.byType(TextField), 'alex@example.com');
    await tester.pump();

    await _selectPeriod(tester, 'Customize');
    await tester.tap(find.text('Cancel').last);
    await tester.pump();

    expect(_confirmTap(tester), isNull);
  });

  testWidgets('customize access end allows editing minutes', (tester) async {
    await tester.pumpWidget(_DeviceShareTestApp());

    await _selectPeriod(tester, 'Customize');

    final minuteBox = find.byKey(DeviceSharePageKeys.customTimeMinute);
    final displayedMinute = int.parse(
      tester
          .widget<Text>(
            find.descendant(of: minuteBox, matching: find.byType(Text)),
          )
          .data!,
    );
    final selectedMinute = displayedMinute == 0 ? 1 : displayedMinute - 1;

    await tester.tap(minuteBox);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ValueKey('device-share-minute-option-$selectedMinute')),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: minuteBox,
        matching: find.text(selectedMinute.toString().padLeft(2, '0')),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Confirm').last);
    await tester.pumpAndSettle();

    final expiryText = tester
        .widget<Text>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Text &&
                RegExp(
                  r'^\d{2}:\d{2} \d{2}-\d{2}-\d{4}$',
                ).hasMatch(widget.data ?? ''),
          ),
        )
        .data!;
    expect(
      DateFormat('HH:mm dd-MM-yyyy').parse(expiryText).minute,
      selectedMinute,
    );
  });

  testWidgets('access end locks time for never expired and two hours', (
    tester,
  ) async {
    await tester.pumpWidget(_DeviceShareTestApp());

    expect(_timeTap(tester), isNull);

    final beforeSelection = DateTime.now();
    await _selectPeriod(tester, '2 hours');

    final expiryText = tester
        .widget<Text>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Text &&
                RegExp(
                  r'^\d{2}:\d{2} \d{2}-\d{2}-\d{4}$',
                ).hasMatch(widget.data ?? ''),
          ),
        )
        .data!;
    final expiry = DateFormat('HH:mm dd-MM-yyyy').parse(expiryText);
    expect(
      expiry.difference(beforeSelection).inMinutes,
      inInclusiveRange(119, 120),
    );
    expect(_timeTap(tester), isNull);
  });
}

Future<void> _selectPermission(
  WidgetTester tester, {
  required String currentValue,
  required String nextValue,
}) async {
  await tester.fling(
    find.byType(ListView),
    const Offset(0, 800),
    1200,
  );
  await tester.pumpAndSettle();
  final currentPermission = find.text(currentValue).first;
  await tester.tap(currentPermission);
  await tester.pumpAndSettle();
  await tester.tap(find.text(nextValue).last);
  await tester.pumpAndSettle();
}

Future<void> _selectPeriod(WidgetTester tester, String value) async {
  await tester.tap(find.text('Never expired').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(value).last);
  await tester.pumpAndSettle();
}

String _capabilityAsset(WidgetTester tester, String capability) {
  final image = tester.widget<Image>(
    find.descendant(
      of: find.byKey(Key('device_share_capability_$capability')),
      matching: find.byType(Image),
    ),
  );
  return (image.image as AssetImage).assetName;
}

VoidCallback? _confirmTap(WidgetTester tester) {
  return tester
      .widget<GestureDetector>(find.byKey(const Key('device_share_confirm')))
      .onTap;
}

VoidCallback? _timeTap(WidgetTester tester) {
  return tester
      .widget<GestureDetector>(find.byKey(const Key('device_share_time')))
      .onTap;
}

Semantics _sendEmailSemantics(WidgetTester tester) {
  return tester.widget<Semantics>(
    find.byWidgetPredicate(
      (widget) =>
          widget is Semantics && widget.properties.label == 'Send email',
    ),
  );
}

class _DeviceShareTestApp extends StatelessWidget {
  const _DeviceShareTestApp({this.onCapabilitiesLoad, this.onCreateShare});

  final VoidCallback? onCapabilitiesLoad;
  final ValueChanged<CreateDoorShareCommand>? onCreateShare;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        createDoorShareUseCaseProvider.overrideWithValue(
          CreateDoorShareUseCase(
            repository: _RecordingDoorShareRepository(onCreateShare),
          ),
        ),
        doorShareCapabilitiesProvider(1).overrideWith((ref) async {
          onCapabilitiesLoad?.call();
          return ShareCapability.values;
        }),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DeviceSharePage(doorId: 1),
      ),
    );
  }
}

class _RecordingDoorShareRepository implements DoorShareRepository {
  const _RecordingDoorShareRepository(this.onCreateShare);

  final ValueChanged<CreateDoorShareCommand>? onCreateShare;

  @override
  Future<void> createShare({
    required int doorId,
    required CreateDoorShareCommand command,
    required String requestId,
  }) async {
    onCreateShare?.call(command);
    if (onCreateShare != null) {
      throw StateError('Captured the create command for the widget test.');
    }
  }

  @override
  Future<List<ShareCapability>> fetchCapabilities({
    required int doorId,
    required String requestId,
  }) async => ShareCapability.values;

  @override
  Future<void> updateShare({
    required int shareId,
    required UpdateDoorShareCommand command,
    required String requestId,
  }) async {}
}
