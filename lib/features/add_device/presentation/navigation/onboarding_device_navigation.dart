import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../device_control/presentation/pages/already_added_devices_page.dart';
import '../../../device_control/presentation/pages/device_command_page.dart';
import '../pages/add_new_doors_page.dart';
import 'f_box_wiring_test_route.dart';

class OnboardingDeviceNavigation {
  const OnboardingDeviceNavigation._();

  static void openDeviceCommandFromOnboarding(
    BuildContext context, {
    required String doorId,
    required String deviceId,
    required String onboardingFlowId,
  }) {
    final router = GoRouter.of(context);
    final navigator = Navigator.of(context);
    final location = DeviceCommandPage.location(
      doorId: doorId,
      deviceId: deviceId,
      onboardingFlowId: onboardingFlowId,
    );
    final boundaryRouteName = _popToOnboardingBoundary(navigator);

    if (boundaryRouteName == AlreadyAddedDevicesPage.routeName &&
        navigator.canPop()) {
      navigator.pop(deviceId);
      return;
    }

    router.pushReplacement(location);
  }

  static void handleFBoxBack(
    BuildContext context, {
    required FBoxWiringTestRouteData routeData,
  }) {
    final navigator = Navigator.of(context);
    if (routeData.entryPoint == FBoxWiringTestEntryPoint.deviceCommand) {
      navigator.maybePop();
      return;
    }

    _popToOnboardingBoundary(navigator);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  static void finishFBoxTest(
    BuildContext context, {
    required FBoxWiringTestRouteData routeData,
  }) {
    final navigator = Navigator.of(context);
    if (routeData.entryPoint == FBoxWiringTestEntryPoint.deviceCommand) {
      navigator.pop(routeData.deviceId);
      return;
    }

    final router = GoRouter.of(context);
    final boundaryRouteName = _popToOnboardingBoundary(navigator);
    if (boundaryRouteName == AlreadyAddedDevicesPage.routeName &&
        navigator.canPop()) {
      navigator.pop(routeData.deviceId);
      return;
    }

    router.pushReplacement(
      DeviceCommandPage.location(
        doorId: routeData.doorId,
        deviceId: routeData.deviceId,
        onboardingFlowId: routeData.onboardingFlowId ?? '',
      ),
    );
  }

  static String? _popToOnboardingBoundary(NavigatorState navigator) {
    String? boundaryRouteName;
    navigator.popUntil((route) {
      final routeName = route.settings.name;
      if (routeName == AddNewDoorsPage.routeName ||
          routeName == AlreadyAddedDevicesPage.routeName) {
        boundaryRouteName = routeName;
        return true;
      }
      return route.isFirst;
    });
    return boundaryRouteName;
  }
}
