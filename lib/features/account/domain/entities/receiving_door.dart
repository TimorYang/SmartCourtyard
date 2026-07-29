/// A door shared with the current user by another account.
class ReceivingDoor {
  const ReceivingDoor({
    required this.shareId,
    required this.doorId,
    required this.name,
    required this.ownerEmail,
    required this.expiresAt,
    this.coverFileId,
    this.doorType,
  });

  /// Stable share ID reserved for future receiver-side share operations.
  final int shareId;

  /// Stable physical-door ID reserved for future device entry flows.
  final int doorId;

  /// Primary text rendered on the Receiving devices card.
  final String name;

  /// Secondary text rendered on the Receiving devices card.
  final String ownerEmail;

  final int? coverFileId;
  final int? doorType;

  /// UTC expiry time, or null when the share does not expire.
  final DateTime? expiresAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceivingDoor &&
          other.shareId == shareId &&
          other.doorId == doorId &&
          other.name == name &&
          other.ownerEmail == ownerEmail &&
          other.coverFileId == coverFileId &&
          other.doorType == doorType &&
          other.expiresAt == expiresAt;

  @override
  int get hashCode => Object.hash(
    shareId,
    doorId,
    name,
    ownerEmail,
    coverFileId,
    doorType,
    expiresAt,
  );
}
