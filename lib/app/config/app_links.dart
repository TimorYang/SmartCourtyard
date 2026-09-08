import 'package:flutter/foundation.dart';

enum AppLinkDestination {
  userAgreement('/h5/legal/user-agreement'),
  privacyPolicy('/h5/legal/privacy-policy'),
  about('/h5/about'),
  helpCenter('/h5/help-center');

  const AppLinkDestination(this.path);

  final String path;
}

class AppLinks {
  const AppLinks._();

  static const baseUrl = String.fromEnvironment(
    'FLINX_WEB_BASE_URL',
    defaultValue: 'https://forcedoor.feizhoukeji.com:15429',
  );

  static Uri uriFor(
    AppLinkDestination destination, {
    Map<String, String>? queryParameters,
  }) {
    final uri = Uri.parse(baseUrl).resolve(destination.path);
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }

    return uri.replace(
      queryParameters: {...uri.queryParameters, ...queryParameters},
    );
  }

  static String webViewLocation({
    required AppLinkDestination destination,
    required String title,
    Map<String, String>? queryParameters,
  }) {
    return Uri(
      path: '/webview',
      queryParameters: {
        'title': title,
        'url': uriFor(destination, queryParameters: queryParameters).toString(),
      },
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
