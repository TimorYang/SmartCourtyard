import 'package:flinx/app/theme/app_theme.dart';
import 'package:flinx/features/notification/presentation/pages/after_sales_appointment_page.dart';
import 'package:flinx/features/notification/presentation/pages/after_sales_detail_page.dart';
import 'package:flinx/features/notification/presentation/pages/notification_detail_page.dart';
import 'package:flinx/features/notification/presentation/pages/notification_list_page.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('lists notifications and opens their detail pages', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(initialLocation: NotificationListPage.routePath),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('The appointment for after-sales service has been confirmed'),
      findsOneWidget,
    );
    expect(
      find.text('Pre order after-sales service is about to begin'),
      findsOneWidget,
    );
    expect(find.text('Upgrading to a new version prompt'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('notification-card-appointment-reminder')),
    );
    await tester.pumpAndSettle();

    expect(find.text('View details'), findsOneWidget);
    await tester.tap(find.text('View details'));
    await tester.pumpAndSettle();

    expect(find.text('After sales service details'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('after-sales-remark-field')),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('shows upgrade placeholder and appointment action variants', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(initialLocation: '/notifications/upgrade-prompt'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Upgrade'), findsOneWidget);
    await tester.tap(find.text('Upgrade'));
    await tester.pump();
    expect(find.text('Device upgrade is coming soon'), findsOneWidget);

    final router = GoRouter(
      initialLocation: '/notifications/low-battery',
      routes: _routes,
    );
    await tester.pumpWidget(_routerApp(router));
    await tester.pumpAndSettle();

    expect(find.text('Appointment for after-sales service'), findsOneWidget);
    await tester.tap(find.text('Appointment for after-sales service'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('after-sales-problem-description-field')),
      findsOneWidget,
    );
  });

  testWidgets('after-sales detail actions show local feedback', (tester) async {
    await tester.pumpWidget(
      _app(initialLocation: AfterSalesDetailPage.routePath),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('after-sales-remark-field')),
      'Battery replaced and verified.',
    );
    expect(find.text('Battery replaced and verified.'), findsOneWidget);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('feedback'));
    await tester.pump();
    expect(find.text('Feedback submitted'), findsOneWidget);
  });

  testWidgets('appointment form edits fields and submits locally', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(initialLocation: AfterSalesAppointmentPage.routePath),
    );
    await tester.pumpAndSettle();

    final description = find.byKey(
      const ValueKey('after-sales-problem-description-field'),
    );
    await tester.enterText(description, 'Battery drains within one hour.');
    await tester.ensureVisible(
      find.byKey(const ValueKey('after-sales-submit-button')),
    );
    await tester.tap(find.byKey(const ValueKey('after-sales-submit-button')));
    await tester.pump();

    expect(find.text('Appointment submitted successfully'), findsOneWidget);
  });
}

Widget _app({required String initialLocation}) {
  return _routerApp(
    GoRouter(initialLocation: initialLocation, routes: _routes),
  );
}

Widget _routerApp(GoRouter router) {
  return MaterialApp.router(
    theme: AppTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  );
}

final _routes = [
  GoRoute(
    path: NotificationListPage.routePath,
    name: NotificationListPage.routeName,
    builder: (_, _) => const NotificationListPage(),
  ),
  GoRoute(
    path: NotificationDetailPage.routePath,
    name: NotificationDetailPage.routeName,
    builder: (_, state) => NotificationDetailPage(
      notificationId: state.pathParameters['notificationId'] ?? '',
    ),
  ),
  GoRoute(
    path: AfterSalesDetailPage.routePath,
    name: AfterSalesDetailPage.routeName,
    builder: (_, _) => const AfterSalesDetailPage(),
  ),
  GoRoute(
    path: AfterSalesAppointmentPage.routePath,
    name: AfterSalesAppointmentPage.routeName,
    builder: (_, _) => const AfterSalesAppointmentPage(),
  ),
];
