import 'package:flutter/foundation.dart';

enum AppLinkDestination {
  userAgreement('/user-agreement'),
  privacyPolicy('/privacy-policy');

  const AppLinkDestination(this.path);

  final String path;
}

class AppLinks {
  const AppLinks._();

  static const baseUrl = String.fromEnvironment(
    'FLINX_WEB_BASE_URL',
    defaultValue: 'https://www.flinx.com',
  );

  static Uri uriFor(AppLinkDestination destination) {
    return Uri.parse(baseUrl).resolve(destination.path);
  }

  static String webViewLocation({
    required AppLinkDestination destination,
    required String title,
  }) {
    return Uri(
      path: '/webview',
      queryParameters: {'title': title, 'url': uriFor(destination).toString()},
    ).toString();
  }

  static bool isAllowed(Uri uri) {
    final base = Uri.parse(baseUrl);
    return uri.scheme == base.scheme && uri.host == base.host;
  }

  static Uri safeUriFromEncoded(String? encodedUrl) {
    final fallback = uriFor(AppLinkDestination.userAgreement);
    if (encodedUrl == null || encodedUrl.isEmpty) {
      return fallback;
    }

    final uri = Uri.tryParse(encodedUrl);
    if (uri == null || !isAllowed(uri)) {
      debugPrint('Blocked unsupported web link: $encodedUrl');
      return fallback;
    }

    return uri;
  }
}
