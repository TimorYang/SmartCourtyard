import 'package:flinx/features/auth/data/services/facebook_login_configuration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts a complete Facebook client configuration', () {
    const configuration = FacebookLoginConfiguration(
      appId: '1732924337995646',
      clientToken: 'client-token',
      displayName: 'force-test',
    );

    expect(configuration.hasRequiredClientConfiguration, isTrue);
  });

  test('requires the display name together with the client credentials', () {
    const configuration = FacebookLoginConfiguration(
      appId: '1732924337995646',
      clientToken: 'client-token',
    );

    expect(configuration.hasRequiredClientConfiguration, isFalse);
  });

  test('rejects blank and placeholder client configuration', () {
    expect(
      const FacebookLoginConfiguration().hasRequiredClientConfiguration,
      isFalse,
    );
    expect(
      const FacebookLoginConfiguration(
        appId: FacebookLoginConfiguration.placeholderAppId,
        clientToken: FacebookLoginConfiguration.placeholderClientToken,
        displayName: 'force-test',
      ).hasRequiredClientConfiguration,
      isFalse,
    );
  });

  test('rejects a non-numeric Facebook App ID', () {
    const configuration = FacebookLoginConfiguration(
      appId: 'app-id',
      clientToken: 'client-token',
      displayName: 'force-test',
    );

    expect(configuration.hasRequiredClientConfiguration, isFalse);
  });
}
