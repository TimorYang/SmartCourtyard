import 'package:flinx/app/config/app_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolves the legal H5 paths from the configured web base URL', () {
    expect(
      AppLinks.uriFor(AppLinkDestination.userAgreement).path,
      '/h5/legal/user-agreement',
    );
    expect(
      AppLinks.uriFor(AppLinkDestination.privacyPolicy).path,
      '/h5/legal/privacy-policy',
    );
  });

  test('adds the selected language to localized H5 pages', () {
    final aboutUri = AppLinks.uriFor(
      AppLinkDestination.about,
      queryParameters: const {'lang': 'de-DE'},
    );
    final helpCenterUri = AppLinks.uriFor(
      AppLinkDestination.helpCenter,
      queryParameters: const {'lang': 'de-DE'},
    );

    expect(aboutUri.path, '/h5/about');
    expect(aboutUri.queryParameters['lang'], 'de-DE');
    expect(helpCenterUri.path, '/h5/help-center');
    expect(helpCenterUri.queryParameters['lang'], 'de-DE');
  });
}
