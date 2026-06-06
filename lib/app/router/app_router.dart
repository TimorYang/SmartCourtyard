import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/add_device/presentation/pages/add_device_page.dart';
import '../../features/add_device/presentation/pages/wifi_configuration_page.dart';
import '../../features/hardware_debug/presentation/pages/ble_debug_page.dart';
import '../../features/home/presentation/pages/home_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
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
        path: BleDebugPage.routePath,
        name: BleDebugPage.routeName,
        builder: (context, state) => const BleDebugPage(),
      ),
    ],
  );
});
