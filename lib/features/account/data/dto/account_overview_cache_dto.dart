class AccountOverviewCacheDto {
  const AccountOverviewCacheDto({
    required this.nickname,
    required this.ownedDoorCount,
    required this.sharedDoorCount,
    required this.receivingDoorCount,
    required this.refreshedAtIso8601,
  });

  final String nickname;
  final int ownedDoorCount;
  final int sharedDoorCount;
  final int receivingDoorCount;
  final String refreshedAtIso8601;

  factory AccountOverviewCacheDto.fromJson(Map<String, Object?> json) {
    return AccountOverviewCacheDto(
      nickname: json['nickname'] as String? ?? '',
      ownedDoorCount: json['ownedDoorCount'] as int? ?? 0,
      sharedDoorCount: json['sharedDoorCount'] as int? ?? 0,
      receivingDoorCount: json['receivingDoorCount'] as int? ?? 0,
      refreshedAtIso8601: json['refreshedAt'] as String? ?? '',
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'nickname': nickname,
    'ownedDoorCount': ownedDoorCount,
    'sharedDoorCount': sharedDoorCount,
    'receivingDoorCount': receivingDoorCount,
    'refreshedAt': refreshedAtIso8601,
  };
}
