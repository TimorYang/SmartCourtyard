/// 安全传感器评估页的完整展示数据。
///
/// 后台接口完成后，应在数据层将接口 DTO 映射为此实体，页面只依赖此领域模型。
class SafetySensorsEvaluation {
  const SafetySensorsEvaluation({
    required this.deviceId,
    required this.totalSensorCount,
    required this.fineSensorCount,
    required this.abnormalSensorCount,
    required this.lowPowerSensorCount,
    this.statisticsStartAt,
    this.statisticsEndAt,
    required this.wiredSensorGroup,
    required this.wirelessSensorGroup,
  });

  /// 门控设备的业务唯一标识，用于请求并关联该设备的安全传感器评估数据。
  final String deviceId;

  /// 当前参与评估的传感器总数量，用于页面顶部的 Sensors 统计卡。
  final int totalSensorCount;

  /// 状态正常的传感器数量，用于页面顶部的 Fine 统计卡。
  final int fineSensorCount;

  /// 状态异常（例如断开或被触发）的传感器数量，用于页面顶部的 Abnormal 统计卡。
  final int abnormalSensorCount;

  /// 电量过低、需要用户关注的传感器数量，用于页面顶部的 Low power 统计卡。
  final int lowPowerSensorCount;

  /// 后端统计窗口的起止时间，供后续在图表中标注统计日期。
  final DateTime? statisticsStartAt;
  final DateTime? statisticsEndAt;

  /// 有线传感器分组的评估结果和展示列表。
  final SafetySensorGroup wiredSensorGroup;

  /// 无线传感器分组的评估结果和展示列表。
  final SafetySensorGroup wirelessSensorGroup;
}

/// 一个有线或无线传感器分组的展示数据。
class SafetySensorGroup {
  const SafetySensorGroup({required this.status, required this.sensors});

  /// 该分组的总体评估状态，用于展示分组标题旁的状态图标。
  final SafetySensorGroupStatus status;

  /// 分组内的传感器列表，接口返回顺序即为页面展示顺序。
  final List<SafetySensor> sensors;
}

/// 传感器分组的总体评估状态。
enum SafetySensorGroupStatus {
  /// 分组内所有传感器状态正常。
  normal,

  /// 分组内存在需要关注的异常传感器。
  abnormal,

  /// 无法获取分组内传感器的实时状态。
  offline,
}

/// 安全传感器评估页中单个传感器的展示数据。
class SafetySensor {
  const SafetySensor({
    required this.id,
    required this.sensorCode,
    required this.status,
    required this.batteryStatus,
    required this.operationPoints,
  });

  /// 传感器业务唯一标识，用于管理、配对、详情和问题排查等后续操作。
  final String id;

  /// 稳定的后端传感器编码；Presentation 层据此取得本地化名称和图标。
  final String sensorCode;

  /// 传感器当前的连接或触发状态，用于展示断开、触发等状态信息。
  final SafetySensorStatus status;

  /// 传感器的电池状态，用于决定正常电池图标、低电量告警和更换电池提示。
  final SafetySensorBatteryStatus batteryStatus;

  /// 传感器操作次数统计点，用于展开后的按小时操作次数图表。
  final List<SafetySensorOperationPoint> operationPoints;
}

/// 传感器当前的连接或触发状态。
enum SafetySensorStatus {
  /// 传感器连接正常且未被触发。
  notTriggered,

  /// 传感器已断开连接或当前不可达。
  disconnected,

  /// 传感器已被触发，需要在页面中提示用户。
  triggered,

  /// 电子锁当前处于解锁状态。
  unlocked,

  /// 电子锁当前处于锁定状态。
  locked,
}

/// 传感器电池状态。
enum SafetySensorBatteryStatus {
  /// 电池电量正常。
  normal,

  /// 电池电量低，需要提示用户及时更换。
  low,

  /// 当前无法读取电池状态。
  unknown,
}

/// 传感器操作次数图表中的一个统计点。
class SafetySensorOperationPoint {
  const SafetySensorOperationPoint({
    required this.occurredAt,
    required this.cycles,
    this.isAbnormal = false,
  });

  /// 统计点对应的发生时间；当前页面使用其小时部分绘制 24 小时横轴。
  final DateTime occurredAt;

  /// 此时间点内的传感器相关操作次数。
  final int cycles;

  /// 当小时触发次数超过后端阈值时为 true，用于绘制告警柱。
  final bool isAbnormal;
}
