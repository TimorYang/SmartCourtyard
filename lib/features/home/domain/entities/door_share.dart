/// A capability the server allows the owner to grant for one physical door.
enum ShareCapability {
  doorControl('DOOR_CONTROL'),
  partialOpen('PARTIAL_OPEN'),
  partialOpenLevel('PARTIAL_OPEN_LEVEL'),
  ledControl('LED_CONTROL'),
  ledOffDelay('LED_OFF_DELAY'),
  autoClose('AUTO_CLOSE'),
  transmitterPairing('TRANSMITTER_PAIRING'),
  forceMargin('FORCE_MARGIN'),
  doorOpenReminder('DOOR_OPEN_REMINDER'),
  openingSpeed('OPENING_SPEED');

  const ShareCapability(this.wireValue);
  final String wireValue;

  static ShareCapability? fromWireValue(String value) {
    for (final capability in values) {
      if (capability.wireValue == value) return capability;
    }
    return null;
  }
}

enum DoorShareRole {
  administrator('0'),
  guest('1');

  const DoorShareRole(this.wireValue);
  final String wireValue;
}

enum DoorShareExpiryType {
  neverExpired('0'),
  twoHours('1'),
  customize('2');

  const DoorShareExpiryType(this.wireValue);
  final String wireValue;
}

/// Page form values normalized before being sent to the share API.
class CreateDoorShareCommand {
  const CreateDoorShareCommand({
    required this.receiverEmail,
    required this.role,
    required this.expiryType,
    required this.capabilities,
    this.expiresAtUtcMillis,
  });

  final String receiverEmail;
  final DoorShareRole role;
  final DoorShareExpiryType expiryType;
  final List<ShareCapability> capabilities;
  final int? expiresAtUtcMillis;
}

/// Editable share-permission values normalized before an update request.
class UpdateDoorShareCommand {
  const UpdateDoorShareCommand({
    required this.role,
    required this.expiryType,
    required this.capabilities,
    this.expiresAtUtcMillis,
  });

  final DoorShareRole role;
  final DoorShareExpiryType expiryType;
  final List<ShareCapability> capabilities;
  final int? expiresAtUtcMillis;
}
