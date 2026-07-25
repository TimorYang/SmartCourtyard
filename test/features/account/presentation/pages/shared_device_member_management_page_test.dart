import 'package:flinx/app/theme/app_theme.dart';
import 'package:flinx/features/account/domain/entities/shared_device_share.dart';
import 'package:flinx/features/account/presentation/pages/shared_device_member_management_page.dart';
import 'package:flinx/features/home/presentation/pages/device_share_page.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('opens the prefilled member-editing share page', (tester) async {
    final router = GoRouter(
      initialLocation: SharedDeviceMemberManagementPage.routePath,
      routes: [
        GoRoute(
          path: SharedDeviceMemberManagementPage.routePath,
          name: SharedDeviceMemberManagementPage.routeName,
          builder: (context, state) => const SharedDeviceMemberManagementPage(),
        ),
        GoRoute(
          path: DeviceSharePage.routePath,
          name: DeviceSharePage.routeName,
          builder: (context, state) => DeviceSharePage(
            editingMember: state.extra as SharedDeviceMember?,
          ),
        ),
      ],
    );

    await tester.pumpWidget(_TestApp(router: router));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        SharedDeviceMemberManagementKeys.editButton('member-admin-001'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DeviceSharePage), findsOneWidget);
    expect(find.byKey(DeviceSharePageKeys.editMemberSummary), findsOneWidget);
    expect(find.byKey(DeviceSharePageKeys.editDeleteAction), findsOneWidget);
    expect(find.text('Andy@forcedoor.cn'), findsOneWidget);
    expect(find.text('2025-10-16 17:54:28'), findsOneWidget);
    expect(find.text('Share'), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '123@123.com',
    );
    expect(find.text('Guest'), findsOneWidget);
    expect(find.text('Customize'), findsOneWidget);
    expect(find.text('18:00 11-04-2026'), findsOneWidget);

    for (final capability in [
      'doorControl',
      'partialOpen',
      'ledDelay',
      'autoClose',
      'doorOpenReminder',
      'doorOpenForce',
      'doorOpenSpeed',
    ]) {
      final image = tester.widget<Image>(
        find.descendant(
          of: find.byKey(Key('device_share_capability_$capability')),
          matching: find.byType(Image),
        ),
      );
      expect(
        (image.image as AssetImage).assetName,
        endsWith('garagePlaceholderCapabilitiesSelected.png'),
      );
    }

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(SharedDeviceMemberManagementPage), findsOneWidget);
  });

  testWidgets('keeps the creation layout when no member is provided', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DeviceSharePage(),
      ),
    );

    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Enjoy the smart life with your family!'), findsOneWidget);
    expect(find.byKey(DeviceSharePageKeys.editMemberSummary), findsNothing);
    expect(find.byKey(DeviceSharePageKeys.editDeleteAction), findsNothing);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
