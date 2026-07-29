import 'package:dio/dio.dart';

import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/network_exception.dart';
import 'account_profile_api.dart';

abstract interface class AccountProfileRemoteDataSource {
  Future<int> uploadImage({
    required List<int> bytes,
    required String fileName,
    required String requestId,
  });
  Future<void> updateProfile({
    String? nickname,
    int? avatarFileId,
    required String requestId,
  });
}

class AccountProfileRemoteDataSourceImpl
    implements AccountProfileRemoteDataSource {
  const AccountProfileRemoteDataSourceImpl({required this.api});
  final AccountProfileApi api;

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
          fileId <= 0)
        throw const AccountProfileRemoteException.invalidResponse();
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
    int? avatarFileId,
    required String requestId,
  }) async {
    try {
      final body = <String, dynamic>{
        if (nickname != null) 'nickname': nickname,
        if (avatarFileId != null) 'avatarFileId': avatarFileId,
      };
      final response = await api.updateProfile(
        body,
        Options(extra: {NetworkRequestExtras.requestId: requestId}),
      );
      if (!_success(response.code, response.success))
        throw const AccountProfileRemoteException.invalidResponse();
    } on DioException catch (error) {
      throw AccountProfileRemoteException.fromNetwork(
        NetworkException.fromDio(error),
      );
    }
  }

  bool _success(int code, bool success) => code == 200 && success;
}

class AccountProfileRemoteException implements Exception {
  const AccountProfileRemoteException._(this.network);
  const AccountProfileRemoteException.invalidResponse() : this._(null);
  AccountProfileRemoteException.fromNetwork(this.network);
  final NetworkException? network;
}
