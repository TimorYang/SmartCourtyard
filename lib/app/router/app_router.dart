import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
        path: BleDebugPage.routePath,
        name: BleDebugPage.routeName,
        builder: (context, state) => const BleDebugPage(),
      ),
    ],
  );
});
