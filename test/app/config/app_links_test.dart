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
}
