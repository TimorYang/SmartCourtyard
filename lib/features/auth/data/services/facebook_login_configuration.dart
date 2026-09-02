import 'package:flutter/foundation.dart';

class FacebookLoginConfiguration {
  const FacebookLoginConfiguration({
    this.appId = '',
    this.clientToken = '',
    this.displayName = '',
  });

  factory FacebookLoginConfiguration.fromEnvironment() {
    return const FacebookLoginConfiguration(
      appId: String.fromEnvironment('FLINX_FACEBOOK_APP_ID'),
      clientToken: String.fromEnvironment('FLINX_FACEBOOK_CLIENT_TOKEN'),
      displayName: String.fromEnvironment('FLINX_FACEBOOK_DISPLAY_NAME'),
    );
  }

  static const placeholderAppId = '123456789012345';
  static const placeholderClientToken = 'not-configured';
  static final _appIdPattern = RegExp(r'^[0-9]+$');

  final String appId;
  final String clientToken;
  final String displayName;

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
    final configuredDisplayName = displayName.trim();
    return _appIdPattern.hasMatch(configuredAppId) &&
        configuredAppId != placeholderAppId &&
        configuredAppId.isNotEmpty &&
        configuredClientToken.isNotEmpty &&
        configuredClientToken != placeholderClientToken &&
        configuredDisplayName.isNotEmpty;
  }
}
