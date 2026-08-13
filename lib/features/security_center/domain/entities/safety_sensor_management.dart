/// 通过门机蓝牙协议查询到的安全配件类型。
enum SafetySensorManagementType {
  // TODO(FLINX-SAFETY-DOOR-SENSOR-NAME): 确认 0x01 最终产品文案与切图。
  @Deprecated('0x01 暂命名为“无线门磁”，发布前请确认最终产品文案与切图。')
  wirelessDoorSensor(0x01),
  wirelessWicketDoor(0x02),
  wirelessSlackRope(0x03),
  wirelessSafetyEdge(0x04),
  wirelessPhotoBeam(0x05),
  wirelessElectronicLock(0x06),
  unknown(-1);

  const SafetySensorManagementType(this.protocolCode);

  final int protocolCode;

  static SafetySensorManagementType fromSerialNumber(int serialNumber) {
    final typeCode = (serialNumber >> 24) & 0xFF;
    return SafetySensorManagementType.values.firstWhere(
      (type) => type.protocolCode == typeCode,
      orElse: () => SafetySensorManagementType.unknown,
    );
  }
}

/// 门机在安全配件查询响应中返回的实时状态。
enum SafetySensorManagementStatus {
  unmatched(0x00),
  disconnected(0x0F),
  normal(0x01),
  fault(0x02),
  lowBatteryNormal(0x11),
  lowBatteryFault(0x12),
  unknown(-1);

  const SafetySensorManagementStatus(this.protocolCode);

  final int protocolCode;

  static SafetySensorManagementStatus fromProtocolCode(int code) =>
      SafetySensorManagementStatus.values.firstWhere(
        (status) => status.protocolCode == code,
        orElse: () => SafetySensorManagementStatus.unknown,
      );
}

class SafetySensorManagement {
  const SafetySensorManagement({required this.sensors});

  final List<SafetySensorManagementItem> sensors;
}

class SafetySensorManagementItem {
  const SafetySensorManagementItem({
    required this.serialNumber,
    required this.type,
    required this.status,
  });

  final int serialNumber;
  final SafetySensorManagementType type;
  final SafetySensorManagementStatus status;

  String get id => serialNumber.toRadixString(16).padLeft(8, '0').toUpperCase();
}
