import 'package:flinx/app/theme/app_theme.dart';
import 'package:flinx/features/home/presentation/pages/device_share_page.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  testWidgets(
    'administrator capabilities can be edited and reset after guest',
    (tester) async {
      await tester.pumpWidget(_DeviceShareTestApp());

      expect(
        _capabilityAsset(tester, 'doorControl'),
        endsWith('garagePlaceholderCapabilitiesSelected.png'),
      );
      expect(
        _capabilityAsset(tester, 'partialOpen'),
        endsWith('garagePlaceholderCapabilitiesSelected.png'),
      );

      await tester.tap(
        find.byKey(const Key('device_share_capability_partialOpen')),
      );
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

      await tester.tap(
        find.byKey(const Key('device_share_capability_doorControl')),
      );
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

  testWidgets('customize access end requires a confirmed time', (tester) async {
    await tester.pumpWidget(_DeviceShareTestApp());
    await tester.enterText(find.byType(TextField), 'alex@example.com');
    await tester.pump();

    await _selectPeriod(tester, 'Customize');
    await tester.tap(find.text('Cancel').last);
    await tester.pump();

    expect(_confirmTap(tester), isNull);
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
  await tester.tap(find.text(currentValue).first);
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

class _DeviceShareTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const DeviceSharePage(),
    );
  }
}
