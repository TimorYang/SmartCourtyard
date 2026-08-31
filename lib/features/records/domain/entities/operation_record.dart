import '../../../account/domain/entities/account_avatar_code.dart';

/// 操作记录页面展示的单条操作数据。
class OperationRecord {
  const OperationRecord({
    required this.action,
    required this.occurredAt,
    required this.doorName,
    this.operatorAccount,
    this.operatorName,
    this.operationMethodLabel,
    this.operatorAvatarCode,
    this.operatorAvatarFileId,
  });

  /// 页面首行展示的操作类型；展示层根据当前语言转换为文案。
  final OperationRecordAction action;

  /// 页面首行右侧展示的发生时间，由接口 [occurredAt] 毫秒时间戳映射。
  final DateTime? occurredAt;

  /// 页面第二行展示的被操作门名称，对应接口 [doorName]。
  final String? doorName;

  /// 页面第二行展示的被操作方式，对应接口 [operationMethodLabel]。
  final String? operationMethodLabel;

  /// 页面操作者信息右侧优先展示的账号，对应接口 [operatorAccount]。
  final String? operatorAccount;

  /// [operatorAccount] 缺失时的操作者展示名称，对应接口 [operatorName]。
  final String? operatorName;

  /// 触发操作用户的内置头像编码。
  final AccountAvatarCode? operatorAvatarCode;

  /// 页面头像关联的自定义头像文件 ID。
  final int? operatorAvatarFileId;

  /// UI 中的操作者文本，账号优先，缺失时回退为名称。
  String? get operatorDisplayName {
    final account = operatorAccount?.trim();
    if (account != null && account.isNotEmpty) return account;
    final name = operatorName?.trim();
    return name != null && name.isNotEmpty ? name : null;
  }
}

enum OperationRecordAction {
  open,
  close,
  stop,
  autoCloseToggle,
  ledOn,
  ledOff,
  ledOffDelayChanged,
  partialOpenChanged,
  autoCloseDelayChanged,
  doorOpenReminderToggle,
  doorOpenReminderDelayChanged,
  unknown,
}
