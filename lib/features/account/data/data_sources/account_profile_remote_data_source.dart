import 'package:dio/dio.dart';

import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/api_business_failure.dart';
import '../../../../core/network/network_exception.dart';
import '../../domain/entities/account_avatar_code.dart';
import '../dto/app_language_option_dto.dart';
import '../dto/app_region_option_dto.dart';
import '../dto/account_profile_remote_dto.dart';
import 'account_profile_api.dart';

abstract interface class AccountProfileRemoteDataSource {
  Future<AccountProfileRemoteDto> fetchProfile({required String requestId});

  Future<List<AppRegionOptionDto>> fetchRegionOptions({
    required String requestId,
  });

  Future<List<AppLanguageOptionDto>> fetchLanguageOptions({
    required String requestId,
  });

  Future<int> uploadImage({
    required List<int> bytes,
    required String fileName,
    required String requestId,
  });
  Future<void> updateProfile({
    String? nickname,
    AccountAvatarCode? avatarCode,
    int? avatarFileId,
    String? regionCode,
    String? locale,
    required String requestId,
  });

  Future<void> updateAvatar({
    AccountAvatarCode? avatarCode,
    int? avatarFileId,
    required String requestId,
  });

  Future<void> updateNickname({
    required String nickname,
    required String requestId,
  });

  Future<void> updateRegion({
    required String regionCode,
    required String requestId,
  });

  Future<void> updateLanguage({
    required String locale,
    required String requestId,
  });

  Future<void> confirmAccountDeletion({required String requestId});
}

class AccountProfileRemoteDataSourceImpl
    implements AccountProfileRemoteDataSource {
  const AccountProfileRemoteDataSourceImpl({required this.api});
  final AccountProfileApi api;

  @override
  Future<AccountProfileRemoteDto> fetchProfile({
    required String requestId,
  }) async {
    try {
      final response = await api.fetchProfile(
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      final data = response.data;
      if (!response.isBusinessSuccess) {
        throw AccountProfileRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
      }
      if (data == null) {
        throw const AccountProfileRemoteException.invalidResponse();
      }
      return data;
    } on DioException catch (error) {
      throw AccountProfileRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on FormatException {
      throw const AccountProfileRemoteException.invalidResponse();
    }
  }

  @override
  Future<List<AppRegionOptionDto>> fetchRegionOptions({
    required String requestId,
  }) async {
    try {
      final response = await api.fetchRegionOptions(
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      final data = response.data;
      if (!response.isBusinessSuccess) {
        throw AccountProfileRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
      }
      if (data == null) {
        throw const AccountProfileRemoteException.invalidResponse();
      }
      return data;
    } on DioException catch (error) {
      throw AccountProfileRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on FormatException {
      throw const AccountProfileRemoteException.invalidResponse();
    }
  }

  @override
  Future<List<AppLanguageOptionDto>> fetchLanguageOptions({
    required String requestId,
  }) async {
    try {
      final response = await api.fetchLanguageOptions(
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      final data = response.data;
      if (!response.isBusinessSuccess) {
        throw AccountProfileRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
      }
      if (data == null) {
        throw const AccountProfileRemoteException.invalidResponse();
      }
      return data;
    } on DioException catch (error) {
      throw AccountProfileRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    } on FormatException {
      throw const AccountProfileRemoteException.invalidResponse();
    }
  }

  @override
  Future<int> uploadImage({
    required List<int> bytes,
    required String fileName,
    required String requestId,
  }) async {
    try {
      final response = await api.uploadImage(
        FormData.fromMap({
          'file': MultipartFile.fromBytes(bytes, filename: fileName),
        }),
        Options(
          contentType: Headers.multipartFormDataContentType,
          extra: {NetworkRequestExtras.requestId: requestId},
        ),
      );
      final data = response.data;
      final raw = data is Map ? data['fileId'] : null;
      final fileId = raw is num
          ? raw.toInt()
          : raw is String
          ? int.tryParse(raw)
          : null;
      if (!response.isBusinessSuccess) {
        throw AccountProfileRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
      }
      if (fileId == null || fileId <= 0) {
        throw const AccountProfileRemoteException.invalidResponse();
      }
      return fileId;
    } on DioException catch (error) {
      throw AccountProfileRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    }
  }

  @override
  Future<void> updateProfile({
    String? nickname,
    AccountAvatarCode? avatarCode,
    int? avatarFileId,
    String? regionCode,
    String? locale,
    required String requestId,
  }) async {
    if (avatarCode != null && avatarFileId != null) {
      throw ArgumentError(
        'avatarCode and avatarFileId are mutually exclusive.',
      );
    }
    try {
      final body = <String, dynamic>{
        'nickname': ?nickname,
        'avatarCode': ?avatarCode?.wireValue,
        'avatarFileId': ?avatarFileId,
        'regionCode': ?regionCode,
        'locale': ?locale,
      };
      final response = await api.updateProfile(
        body,
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      if (!response.isBusinessSuccess) {
        throw AccountProfileRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
      }
    } on DioException catch (error) {
      throw AccountProfileRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    }
  }

  @override
  Future<void> updateAvatar({
    AccountAvatarCode? avatarCode,
    int? avatarFileId,
    required String requestId,
  }) async {
    if (avatarCode != null && avatarFileId != null) {
      throw ArgumentError(
        'avatarCode and avatarFileId are mutually exclusive.',
      );
    }
    try {
      final response = await api.updateAvatar({
        'avatarCode': ?avatarCode?.wireValue,
        'avatarFileId': ?avatarFileId,
      }, Options(extra: {NetworkRequestExtras.requestId: requestId}));
      if (!response.isBusinessSuccess) {
        throw AccountProfileRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
      }
    } on DioException catch (error) {
      throw AccountProfileRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    }
  }

  @override
  Future<void> updateNickname({
    required String nickname,
    required String requestId,
  }) => _updateSingleProfileField(
    requestId: requestId,
    body: {'nickname': nickname},
    request: (body, options) => api.updateNickname(body, options),
  );

  @override
  Future<void> updateRegion({
    required String regionCode,
    required String requestId,
  }) => _updateSingleProfileField(
    requestId: requestId,
    body: {'regionCode': regionCode},
    request: (body, options) => api.updateRegion(body, options),
  );

  @override
  Future<void> updateLanguage({
    required String locale,
    required String requestId,
  }) => _updateSingleProfileField(
    requestId: requestId,
    body: {'locale': locale},
    request: (body, options) => api.updateLanguage(body, options),
  );

  Future<void> _updateSingleProfileField({
    required String requestId,
    required Map<String, dynamic> body,
    required Future<ApiEnvelopeDto<dynamic>> Function(
      Map<String, dynamic> body,
      Options options,
    )
    request,
  }) async {
    try {
      final response = await request(
        body,
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      if (!response.isBusinessSuccess) {
        throw AccountProfileRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
      }
    } on DioException catch (error) {
      throw AccountProfileRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    }
  }

  @override
  Future<void> confirmAccountDeletion({required String requestId}) async {
    try {
      final response = await api.confirmAccountDeletion(
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      if (!response.isBusinessSuccess) {
        throw AccountProfileRemoteException.businessFailure(
          ApiBusinessFailure.fromEnvelope(response),
        );
      }
    } on DioException catch (error) {
      throw AccountProfileRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    }
  }
}

class AccountProfileRemoteException implements Exception {
  const AccountProfileRemoteException._({
    this.network,
    this.businessFailure,
    this.isInvalidResponse = false,
  });
  const AccountProfileRemoteException.invalidResponse()
    : this._(isInvalidResponse: true);
  AccountProfileRemoteException.fromNetwork(NetworkException network)
    : this._(network: network);
  AccountProfileRemoteException.businessFailure(
    ApiBusinessFailure businessFailure,
  ) : this._(businessFailure: businessFailure);
  final NetworkException? network;
  final ApiBusinessFailure? businessFailure;
  final bool isInvalidResponse;
}
