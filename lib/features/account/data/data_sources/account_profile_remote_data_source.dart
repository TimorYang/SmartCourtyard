import 'package:dio/dio.dart';

import '../../../../core/network/dio_factory.dart';
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
      if (!_accountSuccess(response.code, response.success) || data == null) {
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
      if (!_accountSuccess(response.code, response.success) || data == null) {
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
      if (!_languageOptionsSuccess(response.code, response.success) ||
          data == null) {
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
      if (!_success(response.code, response.success) ||
          fileId == null ||
          fileId <= 0) {
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
        if (nickname != null) 'nickname': nickname,
        if (avatarCode != null) 'avatarCode': avatarCode.wireValue,
        if (avatarFileId != null) 'avatarFileId': avatarFileId,
        if (regionCode != null) 'regionCode': regionCode,
        if (locale != null) 'locale': locale,
      };
      final response = await api.updateProfile(
        body,
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      if (!_accountSuccess(response.code, response.success)) {
        throw const AccountProfileRemoteException.invalidResponse();
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
      if (!_accountSuccess(response.code, response.success)) {
        throw const AccountProfileRemoteException.invalidResponse();
      }
    } on DioException catch (error) {
      throw AccountProfileRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    }
  }

  bool _success(int code, bool success) => code == 200 && success;

  bool _languageOptionsSuccess(int code, bool success) {
    return success && (code == 0 || code == 200);
  }

  bool _accountSuccess(int code, bool success) {
    return success && (code == 0 || code == 200);
  }
}

class AccountProfileRemoteException implements Exception {
  const AccountProfileRemoteException._(this.network);
  const AccountProfileRemoteException.invalidResponse() : this._(null);
  AccountProfileRemoteException.fromNetwork(this.network);
  final NetworkException? network;
}
