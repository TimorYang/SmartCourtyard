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
    required this.bandStatuses,
  });

  /// 门体在本次行程中用于定位箭头的百分比，取值范围为 0 至 100。
  final int indicatorPercentage;

  /// 五个固定平衡区间的评估结果，按从 80%~100% 到 0%~20% 的顺序返回。
  final List<FullReportBalanceBandStatus> bandStatuses;
}

/// 平衡区间的评估状态。
enum FullReportBalanceBandStatus {
  /// 区间负载正常。
  normal,

  /// 区间检测到负载过高。
  overload,
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
  });

  /// 数据点对应的发生时间或统计周期起始时间。
  final DateTime occurredAt;

  /// 该时间点内的门体运行次数。
  final int cycles;
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
  });

  /// 传感器业务唯一标识。
  final String id;

  /// 传感器类型，用于决定本地化名称和客户端图标。
  final FullReportSensorType type;

  /// 传感器需要展示的状态代码，按页面展示顺序返回。
  final List<FullReportSensorDisplayState> states;
}

/// 完整报告当前支持的传感器类型。
enum FullReportSensorType {
  /// 有线光电保护传感器。
  wiredPhotoBeam,

  /// 有线电锁。
  wiredELock,

  /// 无线小门传感器。
  wirelessWicketDoor,

  /// 无线安全边。
  wirelessSafetyEdge,

  /// 无线位置传感器。
  wirelessPositionSensor,

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
