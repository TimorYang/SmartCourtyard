import 'package:flinx/core/config/app_api_configuration.dart';
import 'package:flinx/core/config/providers.dart';
import 'package:flinx/core/network/dio_factory.dart';
import 'package:flinx/features/home/application/home_door_cover_image_source.dart';
import 'package:flinx/features/home/application/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const configuration = AppApiConfiguration(
    apiOrigin: 'https://api.example.com',
    apiPathPrefix: '/api/force-door',
  );

  test(
    'creates an authenticated attachment image source from a cover file ID',
    () {
      final source = HomeDoorCoverImageSource.fromFileId(
        fileId: 30001,
        configuration: configuration,
        accessToken: 'access-token',
      );

      expect(
        source.url,
        'https://api.example.com/api/force-door/attachments/30001',
      );
      expect(source.headers, {NetworkHeaders.bladeAuth: 'access-token'});
    },
  );

  test('omits authentication header when no access token is available', () {
    final source = HomeDoorCoverImageSource.fromFileId(
      fileId: 30001,
      configuration: configuration,
      accessToken: null,
    );

    expect(source.headers, isEmpty);
  });

  test('does not create a cover source for a missing or invalid file ID', () {
    final container = ProviderContainer(
      overrides: [appApiConfigurationProvider.overrideWithValue(configuration)],
    );
    addTearDown(container.dispose);

    expect(container.read(homeDoorCoverImageSourceProvider(null)), isNull);
    expect(container.read(homeDoorCoverImageSourceProvider(0)), isNull);
    expect(
      () => HomeDoorCoverImageSource.fromFileId(
        fileId: 0,
        configuration: configuration,
        accessToken: null,
      ),
      throwsArgumentError,
    );
  });
}
