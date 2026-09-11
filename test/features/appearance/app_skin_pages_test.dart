import 'package:flinx/features/account/application/region_selection_controller.dart';
import 'package:flinx/app/theme/app_skin_catalog.dart';
import 'package:flinx/app/theme/app_theme.dart';
import 'package:flinx/features/account/application/account_controller.dart';
import 'package:flinx/features/account/application/account_overview_controller.dart';
import 'package:flinx/features/account/application/providers.dart';
import 'package:flinx/features/account/application/system_permissions_controller.dart';
import 'package:flinx/features/account/domain/entities/account_overview.dart';
import 'package:flinx/features/account/domain/entities/account_profile.dart';
import 'package:flinx/features/account/domain/entities/system_permission.dart';
import 'package:flinx/features/account/presentation/pages/account_profile_page.dart';
import 'package:flinx/features/account/presentation/pages/system_permissions_page.dart';
import 'package:flinx/features/add_device/presentation/pages/add_device_page.dart';
import 'package:flinx/features/add_device/presentation/pages/wifi_configuration_page.dart';
import 'package:flinx/features/appearance/domain/entities/app_skin_id.dart';
import 'package:flinx/features/auth/presentation/pages/login_page.dart';
import 'package:flinx/features/auth/presentation/pages/welcome_page.dart';
import 'package:flinx/features/home/application/providers.dart';
import 'package:flinx/features/home/domain/entities/home_scene.dart';
import 'package:flinx/features/home/presentation/pages/home_page.dart';
import 'package:flinx/features/notification/application/notification_messages_controller.dart';
import 'package:flinx/features/notification/application/providers.dart';
import 'package:flinx/features/notification/presentation/pages/notification_list_page.dart';
import 'package:flinx/platform_bridge/hardware_models.dart';
import 'package:flinx/platform_bridge/mock_hardware_gateway.dart';
import 'package:flinx/platform_bridge/providers.dart';
import 'package:flinx/shared/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/skin_qa.dart';

void main() {
  setUpAll(loadSkinQaFont);
  for (final skin in AppSkinId.values) {
    testWidgets('skin QA main pages and blocked states for $skin', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final pages = <String, Widget>{
        'welcome': const WelcomePage(),
        'login': const LoginPage(),
        'home_empty': const HomePage(),
        'home_offline': const HomePage(),
        'account': const AccountProfilePage(),
        'add_device': const AddDevicePage(doorType: DoorType.garage),
        'wifi_no_device': const WifiConfigurationPage(),
        'permissions_blocked': const SystemPermissionsPage(),
        'notifications_empty': const NotificationListPage(),
        'notifications_loading': const NotificationListPage(),
        'notifications_error': const NotificationListPage(),
      };
      for (final entry in pages.entries) {
        await tester.pumpWidget(const SizedBox.shrink());
        final key = GlobalKey();
        final router = GoRouter(
          routes: [GoRoute(path: '/', builder: (_, _) => entry.value)],
        );
        final notifications = NotificationMessagesState(
          isInitialLoading: entry.key == 'notifications_loading',
          initialLoadFailed: entry.key == 'notifications_error',
        );
        final container = ProviderContainer(
          overrides: [
            regionSelectionControllerProvider.overrideWith(
              _QaRegionController.new,
            ),
            accountControllerProvider.overrideWith(_QaAccountController.new),
            accountOverviewControllerProvider.overrideWith(
              _QaOverviewController.new,
            ),
            accountOverviewAutoRefreshProvider.overrideWithValue(false),
            systemPermissionsControllerProvider.overrideWith(
              _QaPermissionsController.new,
            ),
            notificationMessagesControllerProvider.overrideWith(
              () => _QaNotificationsController(notifications),
            ),
            notificationUnreadStateProvider.overrideWith((_) async => false),
            hardwareGatewayProvider.overrideWithValue(MockHardwareGateway()),
            homeScenesProvider.overrideWith(
              (_) async => const [
                HomeScene(id: 1, name: 'Home', doorCount: 1, isDefault: true),
              ],
            ),
            homeDevicesProvider.overrideWith(
              (_) async => entry.key == 'home_offline'
                  ? const [
                      DeviceSummary(
                        id: 'door',
                        name: 'Garage door',
                        sceneId: 1,
                        onlineState: DeviceOnlineState.offline,
                        bleState: BleConnectionState.disconnected,
                        doorState: DoorState.closed,
                        cycleCount: 123,
                        remainingLifePercent: 80,
                        hasBoundDevices: true,
                      ),
                    ]
                  : const [],
            ),
          ],
        );
        try {
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp.router(
                theme: AppTheme.forSkin(skin),
                locale: const Locale('en'),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                routerConfig: router,
                builder: (_, child) => RepaintBoundary(key: key, child: child),
              ),
            ),
          );
          if (notifications.isInitialLoading) {
            await tester.pump(const Duration(milliseconds: 300));
          } else {
            await tester.pumpAndSettle();
          }
          final page = find.byWidget(entry.value);
          expect(page, findsOneWidget);
          expect(
            Theme.of(tester.element(page)).extension<AppSkinTokens>()!.id,
            skin,
          );
          expect(tester.takeException(), isNull, reason: entry.key);
          if (notifications.isInitialLoading) {
            expect(find.byType(CircularProgressIndicator), findsOneWidget);
          }
          await captureSkinQa(tester, key, '${skin.storageValue}_${entry.key}');
          expect(tester.takeException(), isNull, reason: entry.key);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          router.dispose();
          container.dispose();
        }
      }
    });
  }
}

class _QaAccountController extends AccountController {
  @override
  Future<AccountProfile?> build() async =>
      AccountProfile(userId: 'qa', email: 'qa@example.com', nickname: 'Alex');
  @override
  Future<bool> refreshProfile() async => true;
}

class _QaOverviewController extends AccountOverviewController {
  @override
  Future<AccountOverview?> build() async => AccountOverview(
    nickname: 'Alex',
    ownedDoorCount: 1,
    sharedDoorCount: 0,
    receivingDoorCount: 0,
    refreshedAt: DateTime(2026, 9, 10),
  );
}

class _QaPermissionsController extends SystemPermissionsController {
  @override
  SystemPermissionsViewState build() => SystemPermissionsViewState(
    permissions: [
      for (final permission in SystemPermission.values)
        SystemPermissionState(
          permission: permission,
          status: SystemPermissionStatus.blocked,
        ),
    ],
  );
}

class _QaNotificationsController extends NotificationMessagesController {
  _QaNotificationsController(this.initial);
  final NotificationMessagesState initial;
  @override
  NotificationMessagesState build() => initial;
  @override
  Future<void> loadInitial() async {}
}

class _QaRegionController extends RegionSelectionController {
  @override
  Future<RegionSelectionState> build() async =>
      const RegionSelectionState(regions: [], selectedRegionCode: null);
}
