import '../../../../platform_bridge/hardware_models.dart';

class SafetySensorPairingRequest {
  const SafetySensorPairingRequest({
    required this.requestId,
    required this.deviceId,
    required this.action,
  });

  final String requestId;
  final String deviceId;
  final SafetyAccessoryPairingAction action;
}

class SafetySensorPairingResult {
  const SafetySensorPairingResult({
    required this.request,
    required this.status,
    this.reasonCode,
    this.nativeCode,
  });

  final SafetySensorPairingRequest request;
  final SafetyAccessoryPairingStatus status;
  final int? reasonCode;
  final String? nativeCode;

  bool get successful => status == SafetyAccessoryPairingStatus.success;
}
