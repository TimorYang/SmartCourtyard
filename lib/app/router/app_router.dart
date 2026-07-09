import 'package:flutter/foundation.dart';
import 'package:flutter_debug_tools/flutter_debug_tools.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/add_device/presentation/pages/add_device_page.dart';
import '../../features/add_device/presentation/pages/add_new_doors_page.dart';
import '../../features/add_device/presentation/pages/smart_opener_ble_scan_page.dart';
import '../../features/add_device/presentation/pages/smart_opener_choose_wifi_page.dart';
import '../../features/add_device/presentation/pages/smart_opener_connecting_page.dart';
import '../../features/add_device/presentation/pages/smart_opener_connection_success_page.dart';
import '../../features/add_device/presentation/pages/smart_opener_device_not_found_page.dart';
import '../../features/add_device/presentation/pages/smart_opener_qr_scan_page.dart';
import '../../features/add_device/presentation/pages/smart_opener_scan_guide_page.dart';
import '../../features/add_device/presentation/pages/smart_opener_scan_results_page.dart';
import '../../features/add_device/presentation/pages/wifi_configuration_page.dart';
import '../../features/auth/application/providers.dart';
import '../../features/account/presentation/pages/account_details_page.dart';
import '../../features/account/presentation/pages/account_profile_page.dart';
import '../../features/auth/presentation/pages/forgot_password_code_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/forgot_password_reset_page.dart';
import '../../features/auth/presentation/pages/forgot_password_success_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_code_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/register_password_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/device_control/presentation/pages/device_command_page.dart';
import '../../features/hardware_debug/presentation/pages/ble_debug_page.dart';
import '../../features/home/presentation/pages/choose_scene_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/pages/scene_page.dart';
import '../../features/security_center/presentation/pages/full_report_page.dart';
import '../../features/security_center/presentation/pages/general_evaluation_page.dart';
import '../../features/security_center/presentation/pages/safety_sensors_evaluation_page.dart';
import '../../shared/webview/app_web_view_page.dart';
import '../config/app_links.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  ref.watch(authSessionProvider);

  return GoRouter(
    initialLocation: WelcomePage.routePath,
    observers: kDebugMode ? [DebugNavigatorObserver()] : [],
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
      final isPublicRoute = isAuthRoute || location == AppWebViewPage.routePath;

      if (!isSignedIn && !isPublicRoute) {
        return WelcomePage.routePath;
      }

      if (isSignedIn && isAuthRoute) {
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
        path: ChooseScenePage.routePath,
        name: ChooseScenePage.routeName,
        builder: (context, state) => const ChooseScenePage(),
      ),
      GoRoute(
        path: ScenePage.routePath,
        name: ScenePage.routeName,
        builder: (context, state) => const ScenePage(),
      ),
      GoRoute(
        path: AddDevicePage.routePath,
        name: AddDevicePage.routeName,
        builder: (context, state) => const AddDevicePage(),
      ),
      GoRoute(
        path: AddNewDoorsPage.routePath,
        name: AddNewDoorsPage.routeName,
        builder: (context, state) => const AddNewDoorsPage(),
      ),
      GoRoute(
        path: SmartOpenerScanGuidePage.routePath,
        name: SmartOpenerScanGuidePage.routeName,
        builder: (context, state) => const SmartOpenerScanGuidePage(),
      ),
      GoRoute(
        path: SmartOpenerQrScanPage.routePath,
        name: SmartOpenerQrScanPage.routeName,
        builder: (context, state) => const SmartOpenerQrScanPage(),
      ),
      GoRoute(
        path: SmartOpenerBleScanPage.routePath,
        name: SmartOpenerBleScanPage.routeName,
        builder: (context, state) => const SmartOpenerBleScanPage(),
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
          deviceId: state.uri.queryParameters['deviceId'] ?? '',
        ),
      ),
      GoRoute(
        path: FullReportPage.routePath,
        name: FullReportPage.routeName,
        builder: (context, state) => FullReportPage(
          deviceId: state.uri.queryParameters['deviceId'] ?? '',
        ),
      ),
      GoRoute(
        path: GeneralEvaluationPage.routePath,
        name: GeneralEvaluationPage.routeName,
        builder: (context, state) => GeneralEvaluationPage(
          deviceId: state.uri.queryParameters['deviceId'] ?? '',
        ),
      ),
      GoRoute(
        path: SafetySensorsEvaluationPage.routePath,
        name: SafetySensorsEvaluationPage.routeName,
        builder: (context, state) => SafetySensorsEvaluationPage(
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
