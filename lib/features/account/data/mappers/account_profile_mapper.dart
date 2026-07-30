import '../../domain/entities/account_profile.dart';
import '../../domain/entities/account_avatar_code.dart';
import '../dto/account_profile_dto.dart';
import '../dto/account_remote_dto.dart';
import '../dto/account_profile_remote_dto.dart';

extension AccountProfileDtoMapper on AccountProfileDto {
  AccountProfile toDomain() {
    return AccountProfile(
      userId: _fallbackUserId(userId, email),
      email: email,
      nickname: nickname,
      avatarUrl: _blankToNull(avatarUrl),
      avatarCode: AccountAvatarCode.fromWireValue(avatarCode),
      avatarFileId: avatarFileId,
      registeredAt: _parseRegisteredAt(registeredAtIso8601),
      country: _blankToNull(country),
      regionCode: _blankToNull(regionCode),
      locale: _blankToNull(locale),
      telephone: _blankToNull(telephone),
      timezone: _blankToNull(timezone),
    );
  }
}

extension AccountProfileDomainMapper on AccountProfile {
  AccountProfileDto toLocalDto() {
    return AccountProfileDto(
      schemaVersion: AccountProfileDto.currentSchemaVersion,
      userId: userId,
      email: email,
      nickname: nickname,
      avatarUrl: _blankToNull(avatarUrl),
      avatarCode: avatarCode?.wireValue,
      avatarFileId: avatarFileId,
      registeredAtIso8601: registeredAt?.toUtc().toIso8601String() ?? '',
      country: _blankToNull(country),
      regionCode: _blankToNull(regionCode),
      locale: _blankToNull(locale),
      telephone: _blankToNull(telephone),
      timezone: _blankToNull(timezone),
    );
  }
}

extension AccountRemoteDtoMapper on AccountRemoteDto {
  AccountProfile toDomain() {
    return AccountProfile(
      userId: _fallbackUserId(userId, email),
      email: email,
      nickname: nickname,
      avatarUrl: _blankToNull(avatarUrl),
      avatarCode: AccountAvatarCode.fromWireValue(avatarCode),
      registeredAt: _parseRegisteredAt(registeredAtIso8601),
      country: _blankToNull(country),
    );
  }
}

extension AccountProfileRemoteDtoMapper on AccountProfileRemoteDto {
  AccountProfile toDomain({AccountProfile? cachedProfile}) {
    return AccountProfile(
      userId: _fallbackUserId(userId, email),
      email: email,
      nickname: nickname,
      avatarUrl: cachedProfile?.avatarUrl,
      avatarCode: AccountAvatarCode.fromWireValue(avatarCode),
      avatarFileId: avatarFileId,
      registeredAt: cachedProfile?.registeredAt,
      country: _blankToNull(regionCode),
      regionCode: _blankToNull(regionCode),
      locale: _blankToNull(locale),
      telephone: _blankToNull(telephone),
      timezone: _blankToNull(timezone),
    );
  }
}

DateTime? _parseRegisteredAt(String value) {
  return DateTime.tryParse(value)?.toUtc();
}

String? _blankToNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

String _fallbackUserId(String value, String email) {
  final trimmed = value.trim();
  if (trimmed.isNotEmpty) {
    return trimmed;
  }

  return AccountProfile.normalizeEmail(email);
}
