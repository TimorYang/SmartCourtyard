import 'package:flutter/foundation.dart';
import 'package:flutter_debug_tools/flutter_debug_tools.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/add_device/presentation/pages/add_device_page.dart';
import '../../features/add_device/application/device_type_ble_filter.dart';
import '../../features/add_device/presentation/pages/add_new_doors_page.dart';
import '../../features/add_device/presentation/pages/f_box_connection_guide_page.dart';
import '../../features/add_device/presentation/pages/f_box_wiring_test_page.dart';
import '../../features/add_device/presentation/navigation/f_box_wiring_test_route.dart';
import '../../features/add_device/presentation/pages/smart_opener_ble_scan_page.dart';
import '../../features/add_device/presentation/pages/smart_opener_choose_wifi_page.dart';
import '../../features/add_device/presentation/pages/smart_opener_connecting_page.dart';
import '../../features/add_device/presentation/pages/smart_opener_connection_success_page.dart';
import '../../features/add_device/presentation/pages/smart_opener_device_not_found_page.dart';
import '../../features/add_device/presentation/pages/smart_opener_qr_scan_page.dart';
import '../../features/add_device/presentation/pages/smart_opener_scan_guide_page.dart';
import '../../features/add_device/presentation/pages/smart_opener_scan_results_page.dart';
import '../../features/add_device/presentation/pages/usb_dongle_guide_page.dart';
import '../../features/add_device/presentation/pages/wifi_configuration_page.dart';
import '../../features/auth/application/providers.dart';
import '../../features/account/presentation/pages/account_details_page.dart';
import '../../features/account/presentation/pages/account_profile_page.dart';
import '../../features/account/presentation/pages/check_upgraded_version_page.dart';
import '../../features/account/presentation/pages/hardware_diagnostics_page.dart';
import '../../features/account/presentation/pages/manage_devices_page.dart';
import '../../features/account/presentation/pages/receiving_devices_page.dart';
import '../../features/account/presentation/pages/region_page.dart';
import '../../features/account/presentation/pages/shared_devices_page.dart';
import '../../features/account/presentation/pages/shared_device_member_management_page.dart';
import '../../features/account/domain/entities/shared_door.dart';
import '../../features/account/presentation/pages/system_permissions_page.dart';
import '../../features/auth/presentation/pages/forgot_password_code_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/forgot_password_reset_page.dart';
import '../../features/auth/presentation/pages/forgot_password_success_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_code_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/register_password_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/device_control/presentation/pages/already_added_devices_page.dart';
import '../../features/device_control/presentation/pages/device_command_page.dart';
import '../../features/device_control/presentation/pages/device_settings_page.dart';
import '../../features/device_control/presentation/pages/transmitter_learning_page.dart';
import '../../features/device_control/presentation/pages/transmitter_list_page.dart';
import '../../features/hardware_debug/presentation/pages/ble_debug_page.dart';
import '../../features/home/presentation/pages/choose_scene_page.dart';
import '../../features/home/presentation/pages/device_share_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/pages/scene_page.dart';
import '../../features/notification/presentation/pages/after_sales_appointment_page.dart';
import '../../features/notification/presentation/pages/after_sales_detail_page.dart';
import '../../features/notification/presentation/pages/notification_detail_page.dart';
import '../../features/notification/presentation/pages/notification_list_page.dart';
import '../../features/security_center/presentation/pages/full_report_page.dart';
import '../../features/security_center/presentation/pages/general_evaluation_page.dart';
import '../../features/security_center/presentation/pages/safety_sensor_battery_solution_page.dart';
import '../../features/security_center/presentation/pages/safety_sensor_management_page.dart';
import '../../features/security_center/presentation/pages/safety_sensor_pairing_pages.dart';
import '../../features/security_center/presentation/pages/safety_sensors_evaluation_page.dart';
import '../../platform_bridge/hardware_models.dart';
import '../../shared/webview/app_web_view_page.dart';
import '../config/app_links.dart';
import 'app_route_observer.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  ref.watch(authSessionProvider);

  return GoRouter(
    initialLocation: WelcomePage.routePath,
    observers: [appRouteObserver, if (kDebugMode) DebugNavigatorObserver()],
    redirect: (context, state) async {
      final session = await ref.read(authSessionProvider.future);
      final isSignedIn = session.isAuthenticated;
      final location = state.matchedLocation;
      final isAuthRoute =
          location == WelcomePage.routePath ||
          location == LoginPage.routePath ||
          location == ForgotPasswordPage.routePath ||
          location == ForgotPasswordCodePage.routePath ||
          location == ForgotPasswordResetPage.routePath ||
          location == ForgotPasswordSuccessPage.routePath ||
          location == RegisterPage.routePath ||
          location == RegisterCodePage.routePath ||
          location == RegisterPasswordPage.routePath;
      final isPublicRoute =
          isAuthRoute ||
          location == AppWebViewPage.routePath ||
          location == SmartOpenerConnectionSuccessPage.routePath;
      final isRecoveryRoute =
          location == ForgotPasswordPage.routePath ||
          location == ForgotPasswordCodePage.routePath ||
          location == ForgotPasswordResetPage.routePath ||
          location == ForgotPasswordSuccessPage.routePath;

      if (!isSignedIn && !isPublicRoute) {
        return LoginPage.routePath;
      }

      if (isSignedIn && isAuthRoute && !isRecoveryRoute) {
        return HomePage.routePath;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: WelcomePage.routePath,
        name: WelcomePage.routeName,
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: LoginPage.routePath,
        name: LoginPage.routeName,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: ForgotPasswordPage.routePath,
        name: ForgotPasswordPage.routeName,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: ForgotPasswordCodePage.routePath,
        name: ForgotPasswordCodePage.routeName,
        builder: (context, state) => ForgotPasswordCodePage(
          email: state.uri.queryParameters['email'] ?? '',
        ),
      ),
      GoRoute(
        path: ForgotPasswordResetPage.routePath,
        name: ForgotPasswordResetPage.routeName,
        builder: (context, state) => ForgotPasswordResetPage(
          email: state.uri.queryParameters['email'] ?? '',
        ),
      ),
      GoRoute(
        path: ForgotPasswordSuccessPage.routePath,
        name: ForgotPasswordSuccessPage.routeName,
        builder: (context, state) => const ForgotPasswordSuccessPage(),
      ),
      GoRoute(
        path: RegisterPage.routePath,
        name: RegisterPage.routeName,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: RegisterCodePage.routePath,
        name: RegisterCodePage.routeName,
        builder: (context, state) =>
            RegisterCodePage(email: state.uri.queryParameters['email'] ?? ''),
      ),
      GoRoute(
        path: RegisterPasswordPage.routePath,
        name: RegisterPasswordPage.routeName,
        builder: (context, state) => RegisterPasswordPage(
          email: state.uri.queryParameters['email'] ?? '',
        ),
      ),
      GoRoute(
        path: AppWebViewPage.routePath,
        name: AppWebViewPage.routeName,
        builder: (context, state) {
          final title = state.uri.queryParameters['title'] ?? '';
          final initialUrl = AppLinks.safeUriFromEncoded(
            state.uri.queryParameters['url'],
          );
          return AppWebViewPage(initialUrl: initialUrl, title: title);
        },
      ),
      GoRoute(
        path: HomePage.routePath,
        name: HomePage.routeName,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AccountDetailsPage.routePath,
        name: AccountDetailsPage.routeName,
        builder: (context, state) => const AccountDetailsPage(),
      ),
      GoRoute(
        path: AccountProfilePage.routePath,
        name: AccountProfilePage.routeName,
        builder: (context, state) => const AccountProfilePage(),
      ),
      GoRoute(
        path: CheckUpgradedVersionPage.routePath,
        name: CheckUpgradedVersionPage.routeName,
        builder: (context, state) => const CheckUpgradedVersionPage(),
      ),
      GoRoute(
        path: SystemPermissionsPage.routePath,
        name: SystemPermissionsPage.routeName,
        builder: (context, state) => const SystemPermissionsPage(),
      ),
      GoRoute(
        path: SharedDevicesPage.routePath,
        name: SharedDevicesPage.routeName,
        builder: (context, state) => const SharedDevicesPage(),
      ),
      GoRoute(
        path: SharedDeviceMemberManagementPage.routePath,
        name: SharedDeviceMemberManagementPage.routeName,
        builder: (context, state) => SharedDeviceMemberManagementPage(
          device: state.extra is SharedDoor ? state.extra! as SharedDoor : null,
        ),
      ),
      GoRoute(
        path: ReceivingDevicesPage.routePath,
        name: ReceivingDevicesPage.routeName,
        builder: (context, state) => const ReceivingDevicesPage(),
      ),
      GoRoute(
        path: RegionPage.routePath,
        name: RegionPage.routeName,
        builder: (context, state) => const RegionPage(),
      ),
      GoRoute(
        path: ManageDevicesPage.routePath,
        name: ManageDevicesPage.routeName,
        builder: (context, state) => const ManageDevicesPage(),
      ),
      GoRoute(
        path: HardwareDiagnosticsPage.routePath,
        name: HardwareDiagnosticsPage.routeName,
        builder: (context, state) => const HardwareDiagnosticsPage(),
      ),
      GoRoute(
        path: NotificationListPage.routePath,
        name: NotificationListPage.routeName,
        builder: (context, state) => const NotificationListPage(),
      ),
      GoRoute(
        path: NotificationDetailPage.routePath,
        name: NotificationDetailPage.routeName,
        builder: (context, state) => NotificationDetailPage(
          notificationId: state.pathParameters['notificationId'] ?? '',
        ),
      ),
      GoRoute(
        path: AfterSalesDetailPage.routePath,
        name: AfterSalesDetailPage.routeName,
        builder: (context, state) => const AfterSalesDetailPage(),
      ),
      GoRoute(
        path: AfterSalesAppointmentPage.routePath,
        name: AfterSalesAppointmentPage.routeName,
        builder: (context, state) => const AfterSalesAppointmentPage(),
      ),
      GoRoute(
        path: ChooseScenePage.routePath,
        name: ChooseScenePage.routeName,
        builder: (context, state) => ChooseScenePage(
          door: state.extra is DeviceSummary
              ? state.extra! as DeviceSummary
              : null,
        ),
      ),
      GoRoute(
        path: DeviceSharePage.routePath,
        name: DeviceSharePage.routeName,
        builder: (context, state) {
          final extra = state.extra;
          final createData = extra is DeviceShareCreateRouteData ? extra : null;
          final editingData = extra is DeviceShareEditRouteData ? extra : null;
          return DeviceSharePage(
            doorId:
                createData?.doorId ??
                editingData?.doorId ??
                (extra is int ? extra : null) ??
                (extra is DeviceSummary ? int.tryParse(extra.id) : null),
            initialAddress: createData?.initialAddress,
            editingMember: editingData?.member,
          );
        },
      ),
      GoRoute(
        path: ScenePage.routePath,
        name: ScenePage.routeName,
        builder: (context, state) => const ScenePage(),
      ),
      GoRoute(
        path: AddDevicePage.routePath,
        name: AddDevicePage.routeName,
        builder: (context, state) => AddDevicePage(
          doorId: state.uri.queryParameters[AddDevicePage.doorIdQueryParameter],
          sceneId: int.tryParse(
            state.uri.queryParameters[AddDevicePage.sceneIdQueryParameter] ??
                '',
          ),
          doorType: DoorType.fromWireValue(
            int.tryParse(
              state.uri.queryParameters[AddDevicePage.doorTypeQueryParameter] ??
                  '',
            ),
          ),
        ),
      ),
      GoRoute(
        path: AddNewDoorsPage.routePath,
        name: AddNewDoorsPage.routeName,
        builder: (context, state) => const AddNewDoorsPage(),
      ),
      GoRoute(
        path: FBoxConnectionGuidePage.routePath,
        name: FBoxConnectionGuidePage.routeName,
        builder: (context, state) => const FBoxConnectionGuidePage(),
      ),
      GoRoute(
        path: FBoxWiringTestPage.routePath,
        name: FBoxWiringTestPage.routeName,
        builder: (context, state) => FBoxWiringTestPage(
          routeData: FBoxWiringTestRoute.fromQueryParameters(
            state.uri.queryParameters,
          ),
        ),
      ),
      GoRoute(
        path: SmartOpenerScanGuidePage.routePath,
        name: SmartOpenerScanGuidePage.routeName,
        builder: (context, state) => SmartOpenerScanGuidePage(
          deviceType: normalizeDoorDeviceType(
            state.uri.queryParameters[AddDevicePage.deviceTypeQueryParameter],
          ),
        ),
      ),
      GoRoute(
        path: UsbDongleGuidePage.routePath,
        name: UsbDongleGuidePage.routeName,
        builder: (context, state) => UsbDongleGuidePage(
          doorType: DoorType.fromWireValue(
            int.tryParse(
              state.uri.queryParameters[AddDevicePage.doorTypeQueryParameter] ??
                  '',
            ),
          ),
        ),
      ),
      GoRoute(
        path: SmartOpenerQrScanPage.routePath,
        name: SmartOpenerQrScanPage.routeName,
        builder: (context, state) => SmartOpenerQrScanPage(
          deviceType: normalizeDoorDeviceType(
            state.uri.queryParameters[AddDevicePage.deviceTypeQueryParameter],
          ),
        ),
      ),
      GoRoute(
        path: SmartOpenerBleScanPage.routePath,
        name: SmartOpenerBleScanPage.routeName,
        builder: (context, state) => SmartOpenerBleScanPage(
          targetSn: state.uri.queryParameters['targetSn'],
          deviceType: normalizeDoorDeviceType(
            state.uri.queryParameters[AddDevicePage.deviceTypeQueryParameter],
          ),
        ),
      ),
      GoRoute(
        path: SmartOpenerScanResultsPage.routePath,
        name: SmartOpenerScanResultsPage.routeName,
        builder: (context, state) => const SmartOpenerScanResultsPage(),
      ),
      GoRoute(
        path: SmartOpenerDeviceNotFoundPage.routePath,
        name: SmartOpenerDeviceNotFoundPage.routeName,
        builder: (context, state) => const SmartOpenerDeviceNotFoundPage(),
      ),
      GoRoute(
        path: SmartOpenerChooseWifiPage.routePath,
        name: SmartOpenerChooseWifiPage.routeName,
        builder: (context, state) => const SmartOpenerChooseWifiPage(),
      ),
      GoRoute(
        path: SmartOpenerConnectingPage.routePath,
        name: SmartOpenerConnectingPage.routeName,
        builder: (context, state) => SmartOpenerConnectingPage(
          isWifiSkipped: state.uri.queryParameters['skipWifi'] == 'true',
        ),
      ),
      GoRoute(
        path: SmartOpenerConnectionSuccessPage.routePath,
        name: SmartOpenerConnectionSuccessPage.routeName,
        builder: (context, state) => const SmartOpenerConnectionSuccessPage(),
      ),
      GoRoute(
        path: WifiConfigurationPage.routePath,
        name: WifiConfigurationPage.routeName,
        builder: (context, state) => WifiConfigurationPage(
          qrPayload: state.uri.queryParameters['qrPayload'],
        ),
      ),
      GoRoute(
        path: DeviceCommandPage.routePath,
        name: DeviceCommandPage.routeName,
        builder: (context, state) => DeviceCommandPage(
          doorId:
              state.uri.queryParameters['doorId'] ??
              state.uri.queryParameters['deviceId'] ??
              '',
          deviceId: state.uri.queryParameters['deviceId'] ?? '',
          onboardingFlowId: state.uri.queryParameters['onboardingFlowId'],
        ),
      ),
      GoRoute(
        path: AlreadyAddedDevicesPage.routePath,
        name: AlreadyAddedDevicesPage.routeName,
        builder: (context, state) => AlreadyAddedDevicesPage(
          doorId: state.uri.queryParameters['doorId'] ?? '',
          deviceId: state.uri.queryParameters['deviceId'] ?? '',
        ),
      ),
      GoRoute(
        path: DeviceSettingsPage.routePath,
        name: DeviceSettingsPage.routeName,
        builder: (context, state) => DeviceSettingsPage(
          doorId:
              state.uri.queryParameters['doorId'] ??
              state.uri.queryParameters['deviceId'] ??
              '',
          deviceId: state.uri.queryParameters['deviceId'] ?? '',
          bleName: state.uri.queryParameters['bleName'] ?? '',
          bleDeviceId: state.uri.queryParameters['bleDeviceId'] ?? '',
          capabilityScope: state.extra is DeviceSettingsCapabilityScope
              ? state.extra as DeviceSettingsCapabilityScope
              : null,
        ),
      ),
      GoRoute(
        path: AboutDevicePage.routePath,
        name: AboutDevicePage.routeName,
        builder: (context, state) => AboutDevicePage(
          doorId: state.uri.queryParameters['doorId'] ?? '',
          deviceId: state.uri.queryParameters['deviceId'] ?? '',
        ),
      ),
      GoRoute(
        path: TransmitterManagementPage.routePath,
        name: TransmitterManagementPage.routeName,
        builder: (context, state) => TransmitterManagementPage(
          deviceId: state.uri.queryParameters['deviceId'] ?? '',
        ),
      ),
      GoRoute(
        path: TransmitterLearningPage.routePath,
        name: TransmitterLearningPage.routeName,
        builder: (context, state) => TransmitterLearningPage(
          deviceId: state.uri.queryParameters['deviceId'] ?? '',
        ),
      ),
      GoRoute(
        path: TransmitterListPage.routePath,
        name: TransmitterListPage.routeName,
        builder: (context, state) => TransmitterListPage(
          deviceId: state.uri.queryParameters['deviceId'] ?? '',
        ),
      ),
      GoRoute(
        path: FullReportPage.routePath,
        name: FullReportPage.routeName,
        builder: (context, state) => FullReportPage(
          doorId: state.uri.queryParameters['doorId'] ?? '',
          deviceId: state.uri.queryParameters['deviceId'] ?? '',
        ),
      ),
      GoRoute(
        path: GeneralEvaluationPage.routePath,
        name: GeneralEvaluationPage.routeName,
        builder: (context, state) => GeneralEvaluationPage(
          doorId: state.uri.queryParameters['doorId'] ?? '',
          deviceId: state.uri.queryParameters['deviceId'] ?? '',
        ),
      ),
      GoRoute(
        path: SafetySensorsEvaluationPage.routePath,
        name: SafetySensorsEvaluationPage.routeName,
        builder: (context, state) => SafetySensorsEvaluationPage(
          doorId: state.uri.queryParameters['doorId'] ?? '',
          deviceId: state.uri.queryParameters['deviceId'] ?? '',
        ),
      ),
      GoRoute(
        path: SafetySensorBatterySolutionPage.routePath,
        name: SafetySensorBatterySolutionPage.routeName,
        builder: (context, state) => SafetySensorBatterySolutionPage(
          doorId: state.uri.queryParameters['doorId'] ?? '',
          deviceId: state.uri.queryParameters['deviceId'] ?? '',
          sensorId: state.uri.queryParameters['sensorId'] ?? '',
        ),
      ),
      GoRoute(
        path: SafetySensorManagementPage.routePath,
        name: SafetySensorManagementPage.routeName,
        builder: (context, state) => SafetySensorManagementPage(
          doorId: state.uri.queryParameters['doorId'] ?? '',
          deviceId: state.uri.queryParameters['deviceId'] ?? '',
        ),
      ),
      GoRoute(
        path: SafetySensorPairingGuidePage.routePath,
        name: SafetySensorPairingGuidePage.routeName,
        builder: (context, state) => SafetySensorPairingGuidePage(
          doorId: state.uri.queryParameters['doorId'] ?? '',
          deviceId: state.uri.queryParameters['deviceId'] ?? '',
        ),
      ),
      GoRoute(
        path: SafetySensorPairingMatchingPage.routePath,
        name: SafetySensorPairingMatchingPage.routeName,
        builder: (context, state) => SafetySensorPairingMatchingPage(
          doorId: state.uri.queryParameters['doorId'] ?? '',
          deviceId: state.uri.queryParameters['deviceId'] ?? '',
        ),
      ),
      GoRoute(
        path: SafetySensorPairingSuccessPage.routePath,
        name: SafetySensorPairingSuccessPage.routeName,
        builder: (context, state) => SafetySensorPairingSuccessPage(
          doorId: state.uri.queryParameters['doorId'] ?? '',
          deviceId: state.uri.queryParameters['deviceId'] ?? '',
        ),
      ),
      GoRoute(
        path: SafetySensorPairingFailurePage.routePath,
        name: SafetySensorPairingFailurePage.routeName,
        builder: (context, state) => SafetySensorPairingFailurePage(
          doorId: state.uri.queryParameters['doorId'] ?? '',
          deviceId: state.uri.queryParameters['deviceId'] ?? '',
        ),
      ),
      GoRoute(
        path: BleDebugPage.routePath,
        name: BleDebugPage.routeName,
        builder: (context, state) => const BleDebugPage(),
      ),
    ],
  );
});
