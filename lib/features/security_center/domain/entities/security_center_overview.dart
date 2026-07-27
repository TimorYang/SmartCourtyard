import 'safety_sensors_evaluation.dart';

/// 安全中心页面一次加载所需的完整展示数据。
class SecurityCenterOverview {
  const SecurityCenterOverview({
    required this.deviceId,
    required this.protectionStatus,
    required this.generalEvaluation,
    required this.safetySensorEvaluation,
  });

  /// 门控设备的业务唯一标识，用于与请求参数及设备详情关联。
  final String deviceId;

  /// 设备当前的整体保护结果，用于顶部保护状态及异常提示。
  final SecurityEvaluationStatus protectionStatus;

  /// 门体运行、记录等通用安全检查的评估数据。
  final SecurityEvaluationSection generalEvaluation;

  /// 有线和无线安全传感器的评估数据。
  final SecuritySensorEvaluation safetySensorEvaluation;
}

/// 一个安全评估卡片的结果与所包含的检查项。
class SecurityEvaluationSection {
  const SecurityEvaluationSection({required this.status, required this.items});

  /// 此评估卡片的汇总状态，用于展示成功、警告或异常图标。
  final SecurityEvaluationStatus status;

  /// 此卡片需要在页面上展示的检查项及其结果。
  final List<SecurityEvaluationItem> items;
}

/// 单个通用安全检查项。
class SecurityEvaluationItem {
  const SecurityEvaluationItem({required this.type, required this.status});

  /// 检查项类型，客户端据此显示本地化名称。
  final SecurityEvaluationItemType type;

  /// 当前检查项的结果，可用于后续展示更细粒度的异常状态。
  final SecurityEvaluationStatus status;
}

/// 传感器评估卡片的数据集合。
class SecuritySensorEvaluation {
  const SecuritySensorEvaluation({
    required this.status,
    required this.highlightedSensorTypes,
    required this.wirelessSensors,
    required this.wiredSensors,
  });

  /// 传感器评估的汇总状态，用于卡片右上角状态图标。
  final SecurityEvaluationStatus status;

  /// 需要在卡片顶部重点展示的传感器类型。
  final List<SecuritySensorType> highlightedSensorTypes;

  /// 无线传感器列表，按接口返回顺序在页面上从左到右展示。
  final List<SecuritySensorSnapshot> wirelessSensors;

  /// 有线传感器列表，按接口返回顺序在页面上从左到右展示。
  final List<SecuritySensorSnapshot> wiredSensors;
}

/// 页面上一个传感器的实时展示快照。
class SecuritySensorSnapshot {
  const SecuritySensorSnapshot({
    required this.id,
    required this.type,
    required this.status,
    required this.batteryPercentage,
    this.batteryStatus = SafetySensorBatteryStatus.unknown,
    this.hasBattery = true,
  });

  /// 传感器业务唯一标识，用于进入详情、管理或故障排查。
  final String id;

  /// 传感器类型，客户端据此选择图标和本地化名称。
  final SecuritySensorType type;

  /// 传感器运行、连接或故障状态，用于状态环和图标颜色。
  final SecurityEvaluationStatus status;

  /// 电池剩余百分比，取值范围为 0 至 100；有线传感器可由接口返回 100。
  ///
  /// 仅供既有 Mock 数据和旧页面使用；连接状态接口不会提供该值。
  final int batteryPercentage;

  /// 接口提供的电池状态；无线传感器以它决定低电量图标。
  final SafetySensorBatteryStatus batteryStatus;

  /// 有线传感器没有电池，不展示电池图标。
  final bool hasBattery;
}

/// 安全中心统一使用的评估结果枚举。
enum SecurityEvaluationStatus {
  /// 当前检查正常，无需用户处理。
  normal,

  /// 检查发现需关注的问题，但设备仍可正常工作。
  warning,

  /// 检查发现影响安全或功能的异常，需要用户处理。
  critical,

  /// 无法获取设备或传感器实时状态。
  offline,
}

/// 通用评估卡片支持展示的检查项类型。
enum SecurityEvaluationItemType {
  /// 门体运行状态检查项。
  doorOperationStatus,

  /// 门体运行记录检查项。
  doorOperationRecord,
}

/// 当前安全中心页面支持展示的传感器类型。
enum SecuritySensorType {
  /// 光电保护传感器。
  photoBeam(
    'photoBeam',
    'assets/icons/security_center/security_center_sensor_photo_beam.png',
  ),

  /// 电锁传感器。
  eLock(
    'eLock',
    'assets/icons/security_center/security_center_sensor_e_lock.png',
  ),

  /// 门磁或门体位置传感器。
  doorSensor(
    'doorSensor',
    'assets/icons/security_center/security_center_sensor_door_sensor.png',
  ),

  /// 雷达传感器。
  radar(
    'radar',
    'assets/icons/security_center/security_center_sensor_radar.png',
  ),

  /// 遥控器传感器。
  remote(
    'remote',
    'assets/icons/security_center/security_center_sensor_remote.png',
  ),

  /// 安全边传感器。
  safetyEdge(
    'safetyEdge',
    'assets/icons/security_center/security_center_sensor_safety_edge.png',
  ),

  /// 有线光电保护传感器。
  wiredPhotoBeam(
    'wiredPhotoBeam',
    'assets/icons/security_center/security_center_sensor_wired_photo_beam.png',
  ),

  /// 有线电锁传感器。
  wiredELock(
    'wiredELock',
    'assets/icons/security_center/security_center_sensor_wired_e_lock.png',
  );

  const SecuritySensorType(this.backendKey, this.imageAsset);

  /// 后台用于表示该传感器类型的稳定 key。
  final String backendKey;

  /// 传感器在安全中心卡片中使用的本地图片资源。
  final String imageAsset;

  /// 将后台返回的传感器类型 key 转换为领域枚举。
  static SecuritySensorType? fromBackendKey(String key) {
    for (final type in SecuritySensorType.values) {
      if (type.backendKey == key) {
        return type;
      }
    }
    return null;
  }
}
