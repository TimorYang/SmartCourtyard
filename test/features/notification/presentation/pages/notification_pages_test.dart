import 'package:flinx/app/theme/app_design_tokens.dart';
import 'package:flinx/app/theme/app_theme.dart';
import 'package:flinx/features/notification/application/providers.dart';
import 'package:flinx/features/notification/domain/entities/app_notification.dart';
import 'package:flinx/features/notification/domain/entities/notification_message_page_result.dart';
import 'package:flinx/features/notification/domain/repositories/notification_message_repository.dart';
import 'package:flinx/features/notification/presentation/pages/after_sales_appointment_page.dart';
import 'package:flinx/features/notification/presentation/pages/after_sales_detail_page.dart';
import 'package:flinx/features/notification/presentation/pages/notification_detail_page.dart';
import 'package:flinx/features/notification/presentation/pages/notification_list_page.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';

void main() {
  testWidgets(
    'lists notifications from the repository and opens detail pages',
    (tester) async {
      await tester.pumpWidget(
        _app(initialLocation: NotificationListPage.routePath),
      );
      await tester.pumpAndSettle();

      expect(find.text('Garage door battery is low'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('notification-unread-10001')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('notification-card-10001')));
      await tester.pumpAndSettle();

      expect(
        find.text('Battery below 15%, please arrange service.'),
        findsOneWidget,
      );

      await tester.tap(find.byType(BackButtonIcon));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('notification-unread-10001')),
        findsNothing,
      );
    },
  );

  testWidgets('uses API color tag with a message type fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        initialLocation: NotificationListPage.routePath,
        repository: _ColorTagNotificationMessageRepository(),
      ),
    );
    await tester.pumpAndSettle();

    _expectCategoryColors(
      tester,
      id: 'red',
      background: AppColors.notificationEquipmentTag,
      foreground: AppColors.notificationEquipmentText,
    );
    _expectCategoryColors(
      tester,
      id: 'green',
      background: AppColors.notificationUpgradeTag,
      foreground: AppColors.notificationUpgradeText,
    );
    _expectCategoryColors(
      tester,
      id: 'blue',
      background: AppColors.notificationServiceTag,
      foreground: AppColors.notificationServiceText,
    );
    _expectCategoryColors(
      tester,
      id: 'fallback-device',
      background: AppColors.notificationEquipmentTag,
      foreground: AppColors.notificationEquipmentText,
    );

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
    await tester.pumpAndSettle();

    _expectCategoryColors(
      tester,
      id: 'fallback-firmware',
      background: AppColors.notificationUpgradeTag,
      foreground: AppColors.notificationUpgradeText,
    );
    _expectCategoryColors(
      tester,
      id: 'fallback-other',
      background: AppColors.notificationServiceTag,
      foreground: AppColors.notificationServiceText,
    );
  });

  testWidgets('uses type-specific icons and omits unknown type icons', (
    tester,
  ) async {
    const expectedAssets = <String, String>{
      'FIRMWARE': 'assets/icons/notification/notification_upgrade.png',
      'SERVICE_ORDER': 'assets/icons/notification/notification_after_sales.png',
      'DEVICE': 'assets/icons/notification/notification_device.png',
    };

    for (final entry in expectedAssets.entries) {
      await tester.pumpWidget(
        _app(
          initialLocation: NotificationListPage.routePath,
          repository: _SingleNotificationMessageRepository(type: entry.key),
          scopeKey: ValueKey('notification-icon-test-${entry.key}'),
        ),
      );
      await tester.pumpAndSettle();

      final icon = find.byKey(const ValueKey('notification-icon-icon-test'));
      expect(icon, findsOneWidget);
      final image = tester.widget<Image>(
        find.descendant(of: icon, matching: find.byType(Image)),
      );
      expect((image.image as AssetImage).assetName, entry.value);
    }

    for (final type in <String>['', 'UNKNOWN', 'SECURITY', 'SYSTEM']) {
      await tester.pumpWidget(
        _app(
          initialLocation: NotificationListPage.routePath,
          repository: _SingleNotificationMessageRepository(type: type),
          scopeKey: ValueKey('notification-icon-test-$type'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('notification-card-icon-test')),
        findsOneWidget,
        reason: 'The $type card should remain visible.',
      );
      expect(
        find.byKey(const ValueKey('notification-icon-icon-test')),
        findsNothing,
        reason: 'The $type card should not have an icon.',
      );
    }
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Feedback submitted'), findsOneWidget);
    toastification.dismissAll(delayForAnimation: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Appointment submitted successfully'), findsOneWidget);
    toastification.dismissAll(delayForAnimation: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  });
}

Widget _app({
  required String initialLocation,
  NotificationMessageRepository? repository,
  Key? scopeKey,
}) {
  return _routerApp(
    GoRouter(initialLocation: initialLocation, routes: _routes),
    repository: repository,
    scopeKey: scopeKey,
  );
}

Widget _routerApp(
  GoRouter router, {
  NotificationMessageRepository? repository,
  Key? scopeKey,
}) {
  return ProviderScope(
    key: scopeKey,
    overrides: [
      notificationMessageRepositoryProvider.overrideWithValue(
        repository ?? _FakeNotificationMessageRepository(),
      ),
    ],
    child: ToastificationWrapper(
      child: MaterialApp.router(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
        builder: (context, child) => ToastificationConfigProvider(
          config: const ToastificationConfig(
            alignment: Alignment.topCenter,
            animationDuration: Duration(milliseconds: 220),
          ),
          child: child!,
        ),
      ),
    ),
  );
}

void _expectCategoryColors(
  WidgetTester tester, {
  required String id,
  required Color background,
  required Color foreground,
}) {
  final tag = find.byKey(ValueKey('notification-category-$id'));
  final decoration =
      tester.widget<DecoratedBox>(tag).decoration as BoxDecoration;
  final text = tester.widget<Text>(
    find.descendant(of: tag, matching: find.byType(Text)),
  );
  expect(decoration.color, background);
  expect(text.style?.color, foreground);
}

class _FakeNotificationMessageRepository
    implements NotificationMessageRepository {
  @override
  Future<NotificationMessagePageResult> fetchMessages({
    required int page,
    required int pageSize,
    required String requestId,
  }) async => const NotificationMessagePageResult(
    messages: [
      AppNotification(
        id: '10001',
        templateCode: 'DEVICE_ABNORMAL',
        type: 'DEVICE',
        title: 'Garage door battery is low',
        category: 'Device',
        summary: 'Battery below 15%, please handle it in time.',
        timestamp: '2026-07-01T09:00:00Z',
        isRead: false,
      ),
    ],
    currentPage: 1,
    pageSize: 20,
    total: 1,
    hasMore: false,
  );

  @override
  Future<AppNotificationDetail> fetchMessageDetail({
    required String messageId,
    required String requestId,
  }) async => const AppNotificationDetail(
    id: '10001',
    templateCode: 'DEVICE_ABNORMAL',
    type: 'DEVICE',
    title: 'Garage door battery is low',
    category: 'Device',
    content: 'Battery below 15%, please arrange service.',
    mobileLink: null,
    isRead: true,
    timestamp: '2026-07-01T09:00:00Z',
  );

  @override
  Future<bool> fetchUnreadState({required String requestId}) async => true;

  @override
  Future<void> markAllRead({required String requestId}) async {}
}

class _ColorTagNotificationMessageRepository
    extends _FakeNotificationMessageRepository {
  @override
  Future<NotificationMessagePageResult> fetchMessages({
    required int page,
    required int pageSize,
    required String requestId,
  }) async => NotificationMessagePageResult(
    messages:
        const [
              ('red', 'UNKNOWN', NotificationColorTag.red),
              ('green', 'DEVICE', NotificationColorTag.green),
              ('blue', 'FIRMWARE', NotificationColorTag.blue),
              ('fallback-device', 'DEVICE', NotificationColorTag.unknown),
              ('fallback-firmware', 'FIRMWARE', NotificationColorTag.unknown),
              ('fallback-other', 'UNKNOWN', NotificationColorTag.unknown),
            ]
            .map(
              (item) => AppNotification(
                id: item.$1,
                templateCode: 'TEST',
                type: item.$2,
                colorTag: item.$3,
                title: item.$1,
                category: item.$1,
                summary: item.$1,
                timestamp: '2026-07-01T09:00:00Z',
                isRead: true,
              ),
            )
            .toList(growable: false),
    currentPage: 1,
    pageSize: 20,
    total: 6,
    hasMore: false,
  );
}

class _SingleNotificationMessageRepository
    extends _FakeNotificationMessageRepository {
  _SingleNotificationMessageRepository({required this.type});

  final String type;

  @override
  Future<NotificationMessagePageResult> fetchMessages({
    required int page,
    required int pageSize,
    required String requestId,
  }) async => NotificationMessagePageResult(
    messages: [
      AppNotification(
        id: 'icon-test',
        templateCode: 'LEGACY_TEMPLATE_CODE',
        type: type,
        title: 'Icon test',
        category: 'Test',
        summary: 'Icon test summary',
        timestamp: '2026-07-01T09:00:00Z',
        isRead: true,
      ),
    ],
    currentPage: 1,
    pageSize: 20,
    total: 1,
    hasMore: false,
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
