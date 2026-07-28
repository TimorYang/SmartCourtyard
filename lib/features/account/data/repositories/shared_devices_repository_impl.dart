import '../../../../core/errors/app_error.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/shared_door.dart';
import '../../domain/entities/shared_door_members.dart';
import '../../domain/repositories/shared_devices_repository.dart';
import '../data_sources/shared_devices_remote_data_source.dart';
import '../dto/shared_door_response_dto.dart';
import '../dto/shared_door_members_response_dto.dart';

class SharedDevicesRepositoryImpl implements SharedDevicesRepository {
  const SharedDevicesRepositoryImpl({
    required this.remoteDataSource,
    required this.logger,
  });

  final SharedDevicesRemoteDataSource remoteDataSource;
  final AppLogger logger;

  @override
  Future<List<SharedDoor>> fetchSharedDoors({required String requestId}) async {
    try {
      final doors = await remoteDataSource.fetchSharedDoors(
        requestId: requestId,
      );
      logger.info(
        'Fetched shared doors.',
        requestId: requestId,
        context: {'doorCount': doors.length},
      );
      return doors.map((door) => door.toDomain()).toList(growable: false);
    } on SharedDevicesRemoteException catch (error, stackTrace) {
      logger.error(
        'Failed to fetch shared doors.',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'statusCode': error.statusCode},
      );
      throw _mapError(error, requestId);
    }
  }

  @override
  Future<SharedDoorMembers> fetchDoorMembers({
    required int doorId,
    required String requestId,
  }) async {
    try {
      final dto = await remoteDataSource.fetchDoorMembers(
        doorId: doorId,
        requestId: requestId,
      );
      return SharedDoorMembers(
        doorId: dto.doorId,
        doorName: dto.doorName.trim().isEmpty ? 'Door $doorId' : dto.doorName,
        administrators: dto.administrators
            .map((member) => member.toDomain(dto.doorId))
            .toList(growable: false),
        guests: dto.guests
            .map((member) => member.toDomain(dto.doorId))
            .toList(growable: false),
      );
    } on SharedDevicesRemoteException catch (error, stackTrace) {
      logger.error(
        'Failed to fetch shared door members.',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'doorId': doorId, 'statusCode': error.statusCode},
      );
      throw _mapError(error, requestId);
    }
  }

  @override
  Future<void> deleteDoorMember({
    required int shareId,
    required String requestId,
  }) async {
    try {
      await remoteDataSource.deleteDoorMember(
        shareId: shareId,
        requestId: requestId,
      );
    } on SharedDevicesRemoteException catch (error, stackTrace) {
      logger.error(
        'Failed to delete shared door member.',
        requestId: requestId,
        error: error,
        stackTrace: stackTrace,
        context: {'shareId': shareId},
      );
      throw _mapError(error, requestId);
    }
  }

  AppError _mapError(SharedDevicesRemoteException error, String requestId) {
    if (error.kind == SharedDevicesRemoteErrorKind.network &&
        (error.statusCode == 401 || error.statusCode == 403)) {
      return AppError(
        code: AppErrorCode.accessDenied,
        messageKey: 'sharedDevices.accessDenied',
        requestId: requestId,
      );
    }
    if (error.kind == SharedDevicesRemoteErrorKind.network) {
      return AppError(
        code: AppErrorCode.networkUnavailable,
        messageKey: 'sharedDevices.networkUnavailable',
        action: AppErrorAction.retry,
        requestId: requestId,
        retryable: true,
      );
    }
    return AppError(
      code: AppErrorCode.serverError,
      messageKey: 'sharedDevices.failed',
      action: AppErrorAction.retry,
      requestId: requestId,
      retryable: true,
    );
  }
}

extension SharedDoorMemberResponseDtoMapper on SharedDoorMemberResponseDto {
  SharedDoorMember toDomain(int doorId) => SharedDoorMember(
    doorId: doorId,
    shareId: shareId,
    email: receiverEmail,
    role: role == '0'
        ? SharedDoorMemberRole.administrator
        : SharedDoorMemberRole.guest,
    expiryType: switch (expiryType) {
      '0' => SharedDoorMemberExpiryType.neverExpired,
      '1' => SharedDoorMemberExpiryType.twoHours,
      _ => SharedDoorMemberExpiryType.customize,
    },
    capabilityCodes: capabilities,
    expiresAt: expiresAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
            expiresAt!,
            isUtc: true,
          ).toLocal(),
  );
}

extension SharedDoorResponseDtoMapper on SharedDoorResponseDto {
  SharedDoor toDomain() => SharedDoor(
    doorId: doorId,
    name: name.trim().isEmpty ? 'Door $doorId' : name.trim(),
    sharedUserCount: sharedUserCount,
  );
}
