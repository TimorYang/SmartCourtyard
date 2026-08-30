import 'package:flutter/foundation.dart';

class GoogleSignInConfiguration {
  const GoogleSignInConfiguration({
    this.iosClientId = '',
    this.serverClientId = '',
    this.hostedDomain = '',
  });

  factory GoogleSignInConfiguration.fromEnvironment() {
    return const GoogleSignInConfiguration(
      iosClientId: String.fromEnvironment('FLINX_GOOGLE_IOS_CLIENT_ID'),
      serverClientId: String.fromEnvironment('FLINX_GOOGLE_SERVER_CLIENT_ID'),
      hostedDomain: String.fromEnvironment('FLINX_GOOGLE_HOSTED_DOMAIN'),
    );
  }

  final String iosClientId;
  final String serverClientId;
  final String hostedDomain;

  bool get isSupportedPlatform {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  bool get hasRequiredClientIds => serverClientId.trim().isNotEmpty;

  String? get optionalIosClientId {
    final value = iosClientId.trim();
    return value.isEmpty ? null : value;
  }

  String? get optionalHostedDomain {
    final value = hostedDomain.trim();
    return value.isEmpty ? null : value;
  }
}
