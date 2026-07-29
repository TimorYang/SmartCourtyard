import '../../../core/config/app_api_configuration.dart';
import '../../../core/network/dio_factory.dart';

class HomeDoorCoverImageSource {
  const HomeDoorCoverImageSource({required this.url, required this.headers});

  final String url;
  final Map<String, String> headers;

  factory HomeDoorCoverImageSource.fromFileId({
    required int? fileId,
    required AppApiConfiguration configuration,
    required String? accessToken,
  }) {
    if (fileId == null || fileId <= 0) {
      throw ArgumentError.value(
        fileId,
        'fileId',
        'Must be a positive file ID.',
      );
    }
    final token = accessToken?.trim();
    return HomeDoorCoverImageSource(
      url: configuration.resolveApiPath('attachments/$fileId').toString(),
      headers: token == null || token.isEmpty
          ? const <String, String>{}
          : <String, String>{NetworkHeaders.bladeAuth: token},
    );
  }
}
