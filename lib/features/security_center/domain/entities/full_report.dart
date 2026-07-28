import 'safety_sensors_evaluation.dart';

/// 完整安全报告的领域数据；后台接口完成后应映射为此实体供页面展示。
class FullReport {
  const FullReport({
    required this.deviceId,
    required this.motorName,
    required this.serialNumber,
    required this.cycleSummary,
    required this.openBalanceEvaluation,
    required this.closeBalanceEvaluation,
    required this.last24HoursRecord,
    required this.last7DaysRecord,
    required this.motorFunctionStatus,
    required this.wiredSensorDiagnosis,
    required this.wirelessSensorDiagnosis,
    required this.safetySuggestions,
  });

  /// 设备业务唯一标识，用于请求完整报告及关联设备详情。
  final String deviceId;

  /// 报告顶部展示的开门机名称。
  final String motorName;

  /// 报告顶部展示的设备序列号。
  final String serialNumber;

  /// 门体运行次数与维护预警摘要。
  final FullReportCycleSummary cycleSummary;

  /// 门体开门过程的平衡评估结果。
  final FullReportBalanceEvaluation openBalanceEvaluation;

  /// 门体关门过程的平衡评估结果。
  final FullReportBalanceEvaluation closeBalanceEvaluation;

  /// 最近 24 小时的运行次数记录。
  final FullReportOperationRecord last24HoursRecord;

  /// 最近 7 天的运行次数记录。
  final FullReportOperationRecord last7DaysRecord;

  /// 开门机功能参数的当前配置。
  final FullReportMotorFunctionStatus motorFunctionStatus;

  /// 有线安全传感器的汇总与明细。
  final FullReportSensorDiagnosis wiredSensorDiagnosis;

  /// 无线安全传感器的汇总与明细。
  final FullReportSensorDiagnosis wirelessSensorDiagnosis;

  /// 需要展示在报告底部的安全建议代码列表。
  final List<FullReportSafetySuggestionCode> safetySuggestions;
}

/// 门体运行次数和维护状态。
class FullReportCycleSummary {
  const FullReportCycleSummary({
    required this.doorName,
    required this.operatedCycles,
    required this.remainingCycles,
    required this.needsMaintenance,
  });

  /// 周期摘要卡展示的门体名称。
  final String doorName;

  /// 门体累计运行次数。
  final int operatedCycles;

  /// 门体剩余建议运行次数。
  final int remainingCycles;

  /// 是否需要在周期摘要中展示维护预警。
  final bool needsMaintenance;
}

/// 一次开门或关门的平衡评估结果。
class FullReportBalanceEvaluation {
  const FullReportBalanceEvaluation({
    required this.indicatorPercentage,
    required this.segments,
    this.hasOverloadOrOvercurrent = false,
  });

  /// 门体在本次行程中用于定位箭头的百分比，取值范围为 0 至 100。
  final int indicatorPercentage;

  /// 平衡评估结果，按从 80%~100% 到 0%~20% 的顺序返回。
  final List<FullReportBalanceSegment> segments;

  /// Whether the response reports an overload or overcurrent condition.
  final bool hasOverloadOrOvercurrent;
}

/// 单个平衡区间的服务端评估结果。
class FullReportBalanceSegment {
  const FullReportBalanceSegment({
    this.startPercent,
    this.endPercent,
    this.status,
    this.statusLabel,
  });

  /// The inclusive range start reported by the server.
  final int? startPercent;

  /// The inclusive range end reported by the server.
  final int? endPercent;

  /// 服务端状态码。仅值 1 表示正常。
  final int? status;

  /// 服务端提供的展示文案。
  final String? statusLabel;

  bool get isNormal => status == 1;

  bool matchesRange(int startPercent, int endPercent) =>
      this.startPercent == startPercent && this.endPercent == endPercent;
}

/// 运行次数图表与频繁操作预警数据。
class FullReportOperationRecord {
  const FullReportOperationRecord({
    required this.points,
    this.hasFrequentOperationAlert = false,
  });

  /// 图表数据点；24 小时报表按小时返回，7 天报表按日期返回。
  final List<FullReportOperationCyclePoint> points;

  /// 是否展示频繁操作预警。
  final bool hasFrequentOperationAlert;
}

/// 运行次数图表的单个时间点。
class FullReportOperationCyclePoint {
  const FullReportOperationCyclePoint({
    required this.occurredAt,
    required this.cycles,
    this.axisLabel,
    this.isFrequentOperation = false,
  });

  /// 数据点对应的发生时间或统计周期起始时间。
  final DateTime occurredAt;

  /// 该时间点内的门体运行次数。
  final int cycles;

  /// 图表 X 轴显示文本；由数据层按统计范围映射。
  final String? axisLabel;

  /// 该统计 bucket 是否存在频繁运行异常，由接口的 `abnormal` 标记映射。
  final bool isFrequentOperation;
}

/// 开门机功能参数。
class FullReportMotorFunctionStatus {
  const FullReportMotorFunctionStatus({
    required this.openingForceLevel,
    required this.closingForceLevel,
    required this.autoCloseSeconds,
    required this.autoCloseCondition,
    required this.ledOffDelayMinutes,
    required this.partialOpenCentimeters,
    required this.ignoreObstructionHeightCentimeters,
    required this.photoBeamEnabled,
    required this.communityModeEnabled,
    required this.wiredELockEnabled,
    this.autoCloseUnit,
    this.ledOffDelayUnit,
    this.partialOpenUnit,
    this.ignoreObstructionHeightUnit,
  });

  /// 开门力度等级。
  final int openingForceLevel;

  /// 关门力度等级。
  final int closingForceLevel;

  /// 自动关门等待时间，单位为秒；0 表示关闭自动关门。
  final int autoCloseSeconds;

  /// 自动关门的触发条件。
  final FullReportAutoCloseCondition autoCloseCondition;

  /// LED 熄灭延迟，单位为分钟。
  final int ledOffDelayMinutes;

  /// 部分开门高度，单位为厘米。
  final int partialOpenCentimeters;

  /// 忽略障碍物高度，单位为厘米。
  final int ignoreObstructionHeightCentimeters;

  /// 光电保护功能是否启用。
  final bool photoBeamEnabled;

  /// 社区模式是否启用。
  final bool communityModeEnabled;

  /// 有线电锁功能是否启用。
  final bool wiredELockEnabled;

  /// 自动关门等待时间的接口单位；为空时由 UI 使用既有秒单位。
  final String? autoCloseUnit;

  /// LED 熄灭延迟的接口单位；为空时由 UI 使用既有分钟单位。
  final String? ledOffDelayUnit;

  /// 部分开门高度的接口单位；为空时由 UI 使用既有厘米单位。
  final String? partialOpenUnit;

  /// 忽略障碍物高度的接口单位；为空时由 UI 使用既有厘米单位。
  final String? ignoreObstructionHeightUnit;
}

/// 自动关门条件。
enum FullReportAutoCloseCondition {
  /// 门体处于任意位置时均可自动关门。
  anyPosition,

  /// 门体仅在顶部位置时自动关门。
  topPosition,
}

/// 一组有线或无线安全传感器诊断数据。
class FullReportSensorDiagnosis {
  const FullReportSensorDiagnosis({
    required this.summary,
    required this.sensors,
  });

  /// 诊断卡顶部展示的正常、断开与异常计数。
  final FullReportSensorSummary summary;

  /// 诊断区中按展示顺序排列的传感器明细。
  final List<FullReportSensor> sensors;
}

/// 安全传感器状态计数。
class FullReportSensorSummary {
  const FullReportSensorSummary({
    required this.normalCount,
    required this.disconnectedCount,
    required this.abnormalCount,
  });

  /// 正常传感器数量。
  final int normalCount;

  /// 已断开传感器数量。
  final int disconnectedCount;

  /// 异常传感器数量。
  final int abnormalCount;
}

/// 报告中展示的单个安全传感器。
class FullReportSensor {
  const FullReportSensor({
    required this.id,
    required this.type,
    required this.states,
    this.status,
    this.batteryStatus,
    this.statusLabel,
  });

  /// 传感器业务唯一标识。
  final String id;

  /// 传感器类型，用于决定本地化名称和客户端图标。
  final FullReportSensorType type;

  /// 传感器需要展示的状态代码，按页面展示顺序返回。
  final List<FullReportSensorDisplayState> states;

  /// 实时接口状态；为空时使用 [states] 兼容静态报告内容。
  final SafetySensorStatus? status;

  /// 无线传感器的实时电池状态。
  final SafetySensorBatteryStatus? batteryStatus;

  /// 接口原样返回的状态标签，用于无线传感器第二行。
  final String? statusLabel;
}

/// 完整报告当前支持的传感器类型。
enum FullReportSensorType {
  /// 有线光电保护传感器。
  wiredPhotoBeam,

  /// 无线光电保护传感器。
  wirelessPhotoBeam,

  /// 有线电锁。
  wiredELock,

  /// 无线小门传感器。
  wirelessWicketDoor,

  /// 无线安全边。
  wirelessSafetyEdge,

  /// 无线位置传感器。
  wirelessPositionSensor,

  /// 无线松绳传感器。
  wirelessSlackRope,

  /// 无线电锁。
  wirelessELock,
}

/// 传感器卡中的单条状态。
enum FullReportSensorDisplayState {
  /// 电池电量充足。
  batterySufficient,

  /// 传感器未被触发。
  notTriggered,

  /// 电锁处于锁定状态。
  locked,
}

/// 完整报告底部的安全建议类型。
enum FullReportSafetySuggestionCode {
  /// 运行次数达到维护预警值。
  cycleMaintenance,

  /// 安全边电池电量低。
  safetyEdgeLowBattery,

  /// 需要联系安装人员进行维护。
  contactInstaller,

  /// 开门机开门电流超过设定最大值。
  openingCurrentExceeded,
}
