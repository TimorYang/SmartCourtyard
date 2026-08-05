/// 无线传感器管理页的数据聚合；对应页面的传感器卡片列表。
class SafetySensorManagement {
  const SafetySensorManagement({required this.sensors});

  /// 当前可管理的无线传感器列表；对应管理页主体卡片区域；必填；示例：两个无线传感器。
  final List<SafetySensorManagementItem> sensors;

  factory SafetySensorManagement.fromJson(Map<String, dynamic> json) =>
      SafetySensorManagement(
        sensors: (json['sensors'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(SafetySensorManagementItem.fromJson)
            .toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
    'sensors': sensors.map((sensor) => sensor.toJson()).toList(),
  };

  factory SafetySensorManagement.mock() => SafetySensorManagement(
    sensors: [
      SafetySensorManagementItem.mockWicketDoor(),
      SafetySensorManagementItem.mockElectronicLock(),
    ],
  );
}

/// 管理页中的单个无线传感器卡片。
class SafetySensorManagementItem {
  const SafetySensorManagementItem({
    required this.id,
    required this.sensorCode,
    required this.canDelete,
  });

  /// 传感器业务唯一标识；用于定位被点击删除的卡片；必填；示例：`wireless-wicket-1`。
  final String id;

  /// 传感器类型编码；用于解析本地化名称和图标；必填；示例：`WIRELESS_WICKET_DOOR`。
  final String sensorCode;

  /// 是否允许显示并执行删除；对应卡片右侧删除图标；必填；示例：`true`。
  final bool canDelete;

  factory SafetySensorManagementItem.fromJson(Map<String, dynamic> json) =>
      SafetySensorManagementItem(
        id: json['id'] as String? ?? '',
        sensorCode: json['sensorCode'] as String? ?? '',
        canDelete: json['canDelete'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'sensorCode': sensorCode,
    'canDelete': canDelete,
  };

  factory SafetySensorManagementItem.mockWicketDoor() =>
      const SafetySensorManagementItem(
        id: 'wireless-wicket-1',
        sensorCode: 'WIRELESS_WICKET_DOOR',
        canDelete: true,
      );

  factory SafetySensorManagementItem.mockElectronicLock() =>
      const SafetySensorManagementItem(
        id: 'wireless-e-lock-1',
        sensorCode: 'WIRELESS_ELECTRONIC_LOCK',
        canDelete: true,
      );
}
