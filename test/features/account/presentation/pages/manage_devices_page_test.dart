import 'package:flinx/app/theme/app_theme.dart';
import 'package:flinx/features/account/presentation/pages/manage_devices_page.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester) {
    return tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ManageDevicesPage(),
        ),
      ),
    );
  }

  testWidgets('opens and cancels the managed device removal confirmation', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ManageDevicesKeys.logoutButton('ipad-air')));
    await tester.pumpAndSettle();

    expect(find.byKey(ManageDevicesKeys.removeDialog), findsOneWidget);
    expect(
      find.text('Are you sure you want to remove\nthis device?'),
      findsOneWidget,
    );
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);

    await tester.tap(find.byKey(ManageDevicesKeys.removeCancelButton));
    await tester.pumpAndSettle();

    expect(find.byKey(ManageDevicesKeys.removeDialog), findsNothing);
    expect(find.byKey(ManageDevicesKeys.phoneCard), findsOneWidget);
    expect(find.byKey(ManageDevicesKeys.tabletCard), findsOneWidget);
  });

  testWidgets('dismisses the confirmation from the modal barrier', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ManageDevicesKeys.logoutButton('ipad-air')));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(8, 550));
    await tester.pumpAndSettle();

    expect(find.byKey(ManageDevicesKeys.removeDialog), findsNothing);
    expect(find.byKey(ManageDevicesKeys.tabletCard), findsOneWidget);
  });

  testWidgets('removes only the confirmed managed device', (tester) async {
    await pumpPage(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ManageDevicesKeys.logoutButton('ipad-air')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ManageDevicesKeys.removeConfirmButton));
    await tester.pumpAndSettle();

    expect(find.byKey(ManageDevicesKeys.removeDialog), findsNothing);
    expect(find.byKey(ManageDevicesKeys.phoneCard), findsOneWidget);
    expect(find.byKey(ManageDevicesKeys.tabletCard), findsNothing);
    expect(find.text('Iphone 16 pro max'), findsOneWidget);
  });
}
