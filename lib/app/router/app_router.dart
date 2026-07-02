import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/add_device/presentation/pages/add_device_page.dart';
import '../../features/auth/application/providers.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_code_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/add_device/presentation/pages/wifi_configuration_page.dart';
import '../../features/device_control/presentation/pages/device_command_page.dart';
import '../../features/hardware_debug/presentation/pages/ble_debug_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../shared/webview/app_web_view_page.dart';
import '../config/app_links.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(authSessionProvider);

  return GoRouter(
    initialLocation: WelcomePage.routePath,
    redirect: (context, state) {
      final isSignedIn = session.isAuthenticated;
      final location = state.matchedLocation;
      final isAuthRoute =
          location == WelcomePage.routePath ||
          location == LoginPage.routePath ||
          location == ForgotPasswordPage.routePath ||
          location == RegisterPage.routePath ||
          location == RegisterCodePage.routePath;
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
        path: AddDevicePage.routePath,
        name: AddDevicePage.routeName,
        builder: (context, state) => const AddDevicePage(),
      ),
      GoRoute(
        path: WifiConfigurationPage.routePath,
        name: WifiConfigurationPage.routeName,
        builder: (context, state) => const WifiConfigurationPage(),
      ),
      GoRoute(
        path: DeviceCommandPage.routePath,
        name: DeviceCommandPage.routeName,
        builder: (context, state) => DeviceCommandPage(
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
