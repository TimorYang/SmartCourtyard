import 'package:flutter/foundation.dart';

class FacebookLoginConfiguration {
  const FacebookLoginConfiguration({this.appId = '', this.clientToken = ''});

  factory FacebookLoginConfiguration.fromEnvironment() {
    return const FacebookLoginConfiguration(
      appId: String.fromEnvironment('FLINX_FACEBOOK_APP_ID'),
      clientToken: String.fromEnvironment('FLINX_FACEBOOK_CLIENT_TOKEN'),
    );
  }

  static const placeholderAppId = '123456789012345';
  static const placeholderClientToken = 'not-configured';

  final String appId;
  final String clientToken;

  bool get isSupportedPlatform {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  bool get hasRequiredClientConfiguration {
    final configuredAppId = appId.trim();
    final configuredClientToken = clientToken.trim();
    return configuredAppId.isNotEmpty &&
        configuredClientToken.isNotEmpty &&
        configuredAppId != placeholderAppId &&
        configuredClientToken != placeholderClientToken;
  }
}
