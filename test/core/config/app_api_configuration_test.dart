import 'package:flinx/core/config/app_api_configuration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const configuration = AppApiConfiguration(
    apiOrigin: 'https://api.flinx.example/',
    apiPathPrefix: '//api/force-door//',
  );

  test('resolves a feature path from the shared API origin and prefix', () {
    expect(
      configuration.resolveApiPath('/app/auth/crypto/public-key').toString(),
      'https://api.flinx.example/api/force-door/app/auth/crypto/public-key',
    );
  });

  test('rejects an origin without an HTTP scheme and host', () {
    const invalid = AppApiConfiguration(
      apiOrigin: 'api.flinx.example',
      apiPathPrefix: '/api',
    );

    expect(
      invalid.validate,
      throwsA(
        isA<AppApiConfigurationException>().having(
          (error) => error.kind,
          'kind',
          AppApiConfigurationErrorKind.invalidOrigin,
        ),
      ),
    );
  });

  test('rejects an empty path prefix', () {
    const invalid = AppApiConfiguration(
      apiOrigin: 'https://api.flinx.example',
      apiPathPrefix: ' / ',
    );

    expect(
      invalid.validate,
      throwsA(
        isA<AppApiConfigurationException>().having(
          (error) => error.kind,
          'kind',
          AppApiConfigurationErrorKind.invalidPathPrefix,
        ),
      ),
    );
  });
}
