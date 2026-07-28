/// A door owned by the current user that has been shared with others.
class SharedDoor {
  const SharedDoor({
    required this.doorId,
    required this.name,
    required this.sharedUserCount,
  });

  /// Stable physical-door ID reserved for subsequent share-management flows.
  final int doorId;

  /// Door name rendered as the primary text on the Shared devices card.
  final String name;

  /// Number rendered in the Shared devices card's sharing-status subtitle.
  final int sharedUserCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SharedDoor &&
          other.doorId == doorId &&
          other.name == name &&
          other.sharedUserCount == sharedUserCount;

  @override
  int get hashCode => Object.hash(doorId, name, sharedUserCount);
}
