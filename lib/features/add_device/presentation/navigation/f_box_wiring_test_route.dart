import 'package:flutter/foundation.dart';

enum FBoxWiringTestEntryPoint {
  tryIt('try-it'),
  deviceCommand('device-command');

  const FBoxWiringTestEntryPoint(this.queryValue);

  final String queryValue;

  static FBoxWiringTestEntryPoint fromQueryValue(String? value) {
    return FBoxWiringTestEntryPoint.values.firstWhere(
      (entryPoint) => entryPoint.queryValue == value,
      orElse: () => FBoxWiringTestEntryPoint.tryIt,
    );
  }
}

@immutable
class FBoxWiringTestRouteData {
  const FBoxWiringTestRouteData({
    this.doorId = '',
    this.deviceId = '',
    this.onboardingFlowId,
    this.entryPoint = FBoxWiringTestEntryPoint.tryIt,
  });

  final String doorId;
  final String deviceId;
  final String? onboardingFlowId;
  final FBoxWiringTestEntryPoint entryPoint;

  String get location => FBoxWiringTestRoute.location(
    doorId: doorId,
    deviceId: deviceId,
    onboardingFlowId: onboardingFlowId,
    entryPoint: entryPoint,
  );

  @override
  bool operator ==(Object other) {
    return other is FBoxWiringTestRouteData &&
        other.doorId == doorId &&
        other.deviceId == deviceId &&
        other.onboardingFlowId == onboardingFlowId &&
        other.entryPoint == entryPoint;
  }

  @override
  int get hashCode =>
      Object.hash(doorId, deviceId, onboardingFlowId, entryPoint);
}

class FBoxWiringTestRoute {
  const FBoxWiringTestRoute._();

  static const routeName = 'f-box-wiring-test';
  static const routePath = '/add-device/f-box/wiring-test';

  static String location({
    required String doorId,
    required String deviceId,
    String? onboardingFlowId,
    FBoxWiringTestEntryPoint entryPoint = FBoxWiringTestEntryPoint.tryIt,
  }) {
    final queryParameters = <String, String>{
      'doorId': doorId,
      'deviceId': deviceId,
      'source': entryPoint.queryValue,
    };
    final flowId = onboardingFlowId?.trim();
    if (flowId != null && flowId.isNotEmpty) {
      queryParameters['onboardingFlowId'] = flowId;
    }
    return Uri(path: routePath, queryParameters: queryParameters).toString();
  }

  static FBoxWiringTestRouteData fromQueryParameters(
    Map<String, String> queryParameters,
  ) {
    return FBoxWiringTestRouteData(
      doorId: queryParameters['doorId'] ?? '',
      deviceId: queryParameters['deviceId'] ?? '',
      onboardingFlowId: queryParameters['onboardingFlowId'],
      entryPoint: FBoxWiringTestEntryPoint.fromQueryValue(
        queryParameters['source'],
      ),
    );
  }
}
