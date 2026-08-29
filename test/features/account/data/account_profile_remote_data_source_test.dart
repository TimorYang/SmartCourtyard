import 'package:dio/dio.dart';
import 'package:flinx/core/network/api_envelope_dto.dart';
import 'package:flinx/core/network/dio_factory.dart';
import 'package:flinx/features/account/data/data_sources/account_profile_api.dart';
import 'package:flinx/features/account/data/data_sources/account_profile_remote_data_source.dart';
import 'package:flinx/features/account/data/dto/account_profile_remote_dto.dart';
import 'package:flinx/features/account/data/dto/app_language_option_dto.dart';
import 'package:flinx/features/account/data/dto/app_region_option_dto.dart';
import 'package:flinx/features/account/domain/entities/account_avatar_code.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('updates an avatar with the API body and request ID', () async {
    final api = _FakeAccountProfileApi();
    final dataSource = AccountProfileRemoteDataSourceImpl(api: api);

    await dataSource.updateAvatar(
      avatarCode: AccountAvatarCode.avatar02,
      requestId: 'account-avatar-123',
    );

    expect(api.avatarBody, {'avatarCode': 'AVATAR_02'});
    expect(
      api.avatarOptions.extra?[NetworkRequestExtras.requestId],
      'account-avatar-123',
    );
  });

  test('rejects an avatar response with code zero', () async {
    final api = _FakeAccountProfileApi(code: 0);
    final dataSource = AccountProfileRemoteDataSourceImpl(api: api);

    await expectLater(
      dataSource.updateAvatar(
        avatarCode: AccountAvatarCode.avatar02,
        requestId: 'account-avatar-invalid-code',
      ),
      throwsA(isA<AccountProfileRemoteException>()),
    );
  });

  test(
    'updates nickname, region, and language with their own request body',
    () async {
      final api = _FakeAccountProfileApi();
      final dataSource = AccountProfileRemoteDataSourceImpl(api: api);

      await dataSource.updateNickname(
        nickname: 'Alice F',
        requestId: 'account-nickname-123',
      );
      await dataSource.updateRegion(
        regionCode: 'US',
        requestId: 'account-region-123',
      );
      await dataSource.updateLanguage(
        locale: 'en-US',
        requestId: 'account-language-123',
      );

      expect(api.nicknameBody, {'nickname': 'Alice F'});
      expect(api.regionBody, {'regionCode': 'US'});
      expect(api.languageBody, {'locale': 'en-US'});
      expect(
        api.languageOptions.extra?[NetworkRequestExtras.requestId],
        'account-language-123',
      );
    },
  );
}

class _FakeAccountProfileApi implements AccountProfileApi {
  _FakeAccountProfileApi({this.code = 200});

  final int code;
  late Map<String, dynamic> avatarBody;
  late Options avatarOptions;
  late Map<String, dynamic> nicknameBody;
  late Map<String, dynamic> regionBody;
  late Map<String, dynamic> languageBody;
  late Options languageOptions;

  @override
  Future<ApiEnvelopeDto<dynamic>> updateAvatar(
    Map<String, dynamic> body,
    Options options,
  ) async {
    avatarBody = body;
    avatarOptions = options;
    return ApiEnvelopeDto(code: code, success: true, data: <String, dynamic>{});
  }

  @override
  Future<ApiEnvelopeDto<dynamic>> updateProfile(
    Map<String, dynamic> body,
    Options options,
  ) => throw UnimplementedError();

  @override
  Future<ApiEnvelopeDto<dynamic>> updateNickname(
    Map<String, dynamic> body,
    Options options,
  ) async {
    nicknameBody = body;
    return ApiEnvelopeDto(code: code, success: true, data: <String, dynamic>{});
  }

  @override
  Future<ApiEnvelopeDto<dynamic>> updateRegion(
    Map<String, dynamic> body,
    Options options,
  ) async {
    regionBody = body;
    return ApiEnvelopeDto(code: code, success: true, data: <String, dynamic>{});
  }

  @override
  Future<ApiEnvelopeDto<dynamic>> updateLanguage(
    Map<String, dynamic> body,
    Options options,
  ) async {
    languageBody = body;
    languageOptions = options;
    return ApiEnvelopeDto(code: code, success: true, data: <String, dynamic>{});
  }

  @override
  Future<ApiEnvelopeDto<dynamic>> uploadImage(FormData body, Options options) =>
      throw UnimplementedError();

  @override
  Future<ApiEnvelopeDto<AccountProfileRemoteDto>> fetchProfile(
    Options options,
  ) => throw UnimplementedError();

  @override
  Future<ApiEnvelopeDto<List<AppRegionOptionDto>>> fetchRegionOptions(
    Options options,
  ) => throw UnimplementedError();

  @override
  Future<ApiEnvelopeDto<List<AppLanguageOptionDto>>> fetchLanguageOptions(
    Options options,
  ) => throw UnimplementedError();

  @override
  Future<ApiEnvelopeDto<dynamic>> confirmAccountDeletion(Options options) =>
      throw UnimplementedError();
}
