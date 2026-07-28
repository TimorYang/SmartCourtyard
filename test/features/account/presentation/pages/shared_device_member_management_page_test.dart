import 'package:flinx/app/theme/app_theme.dart';
import 'package:flinx/features/account/domain/entities/shared_door_members.dart';
import 'package:flinx/features/home/application/door_share_controller.dart';
import 'package:flinx/features/home/domain/entities/door_share.dart';
import 'package:flinx/features/home/presentation/pages/device_share_page.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders an edit route from real member data', (tester) async {
    final member = SharedDoorMember(
      doorId: 42,
      shareId: 7,
      email: 'andy@forcedoor.cn',
      role: SharedDoorMemberRole.guest,
      expiryType: SharedDoorMemberExpiryType.customize,
      expiresAt: DateTime(2026, 4, 11, 18),
      capabilityCodes: ['DOOR_CONTROL', 'LED_CONTROL'],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          doorShareCapabilitiesProvider(
            42,
          ).overrideWith((ref) async => ShareCapability.values),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DeviceSharePage(doorId: 42, editingMember: member),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(DeviceSharePageKeys.editMemberSummary), findsOneWidget);
    expect(find.byKey(DeviceSharePageKeys.editDeleteAction), findsOneWidget);
    expect(find.text('andy@forcedoor.cn'), findsNWidgets(2));
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'andy@forcedoor.cn',
    );
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
    expect(find.text('Guest'), findsOneWidget);
    expect(find.text('Customize'), findsOneWidget);
    expect(find.byKey(const Key('device_share_confirm')), findsOneWidget);
  });

  testWidgets('does not display an expiry time for never-expired edits', (
    tester,
  ) async {
    final member = SharedDoorMember(
      doorId: 42,
      shareId: 8,
      email: 'owner@forcedoor.cn',
      role: SharedDoorMemberRole.administrator,
      expiryType: SharedDoorMemberExpiryType.neverExpired,
      // The backend may include stale data; it must not affect a permanent share.
      expiresAt: DateTime(2026, 4, 11, 18),
      capabilityCodes: const ['DOOR_CONTROL'],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          doorShareCapabilitiesProvider(
            42,
          ).overrideWith((ref) async => ShareCapability.values),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DeviceSharePage(doorId: 42, editingMember: member),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('18:00 11-04-2026'), findsNothing);
    expect(find.text('Never expired'), findsWidgets);
  });
}
