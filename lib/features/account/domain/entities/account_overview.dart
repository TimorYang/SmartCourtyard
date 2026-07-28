class AccountOverview {
  const AccountOverview({
    required this.nickname,
    required this.ownedDoorCount,
    required this.sharedDoorCount,
    required this.receivingDoorCount,
    required this.refreshedAt,
  });

  final String nickname;
  final int ownedDoorCount;
  final int sharedDoorCount;
  final int receivingDoorCount;
  final DateTime refreshedAt;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AccountOverview &&
            other.nickname == nickname &&
            other.ownedDoorCount == ownedDoorCount &&
            other.sharedDoorCount == sharedDoorCount &&
            other.receivingDoorCount == receivingDoorCount &&
            other.refreshedAt == refreshedAt;
  }

  @override
  int get hashCode => Object.hash(
    nickname,
    ownedDoorCount,
    sharedDoorCount,
    receivingDoorCount,
    refreshedAt,
  );
}
