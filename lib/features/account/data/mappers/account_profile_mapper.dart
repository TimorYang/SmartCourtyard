import '../../domain/entities/account_profile.dart';
import '../dto/account_profile_dto.dart';
import '../dto/account_remote_dto.dart';

extension AccountProfileDtoMapper on AccountProfileDto {
  AccountProfile toDomain() {
    return AccountProfile(
      email: email,
      nickname: nickname,
      avatarUrl: _blankToNull(avatarUrl),
      registeredAt: _parseRegisteredAt(registeredAtIso8601),
      country: _blankToNull(country),
    );
  }
}

extension AccountProfileDomainMapper on AccountProfile {
  AccountProfileDto toLocalDto() {
    return AccountProfileDto(
      schemaVersion: AccountProfileDto.currentSchemaVersion,
      email: email,
      nickname: nickname,
      avatarUrl: _blankToNull(avatarUrl),
      registeredAtIso8601: registeredAt.toUtc().toIso8601String(),
      country: _blankToNull(country),
    );
  }
}

extension AccountRemoteDtoMapper on AccountRemoteDto {
  AccountProfile toDomain() {
    return AccountProfile(
      email: email,
      nickname: nickname,
      avatarUrl: _blankToNull(avatarUrl),
      registeredAt: _parseRegisteredAt(registeredAtIso8601),
      country: _blankToNull(country),
    );
  }
}

DateTime _parseRegisteredAt(String value) {
  return DateTime.tryParse(value)?.toUtc() ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}

String? _blankToNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}
