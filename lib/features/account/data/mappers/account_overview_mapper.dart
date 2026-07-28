import '../../domain/entities/account_overview.dart';
import '../dto/account_overview_cache_dto.dart';
import '../dto/account_overview_dto.dart';

extension AccountOverviewDtoMapper on AccountOverviewDto {
  AccountOverview toDomain({required DateTime refreshedAt}) {
    return AccountOverview(
      nickname: profile.nickname.trim(),
      ownedDoorCount: doorSummary.ownedDoorCount,
      sharedDoorCount: doorSummary.sharedDoorCount,
      receivingDoorCount: doorSummary.receivingDoorCount,
      refreshedAt: refreshedAt,
    );
  }
}

extension AccountOverviewCacheDtoMapper on AccountOverviewCacheDto {
  AccountOverview? toDomain() {
    final refreshedAt = DateTime.tryParse(refreshedAtIso8601)?.toLocal();
    if (refreshedAt == null) {
      return null;
    }
    return AccountOverview(
      nickname: nickname.trim(),
      ownedDoorCount: ownedDoorCount,
      sharedDoorCount: sharedDoorCount,
      receivingDoorCount: receivingDoorCount,
      refreshedAt: refreshedAt,
    );
  }
}

extension AccountOverviewDomainMapper on AccountOverview {
  AccountOverviewCacheDto toCacheDto() => AccountOverviewCacheDto(
    nickname: nickname,
    ownedDoorCount: ownedDoorCount,
    sharedDoorCount: sharedDoorCount,
    receivingDoorCount: receivingDoorCount,
    refreshedAtIso8601: refreshedAt.toUtc().toIso8601String(),
  );
}
