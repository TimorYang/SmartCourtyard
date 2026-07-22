/// 操作记录页面展示的单条操作数据。
class OperationRecord {
  const OperationRecord({
    required this.operationName,
    required this.operationTimeText,
    required this.deviceName,
    required this.operatorEmail,
    this.operatorAvatarUrl = '',
  });

  /// 页面首行展示的操作名称，例如“Open door”。
  final String operationName;

  /// 页面首行右侧展示的操作时间；由后端按展示格式返回。
  final String operationTimeText;

  /// 页面第二行展示的被操作设备名称。
  final String deviceName;

  /// 页面操作者信息左侧展示的头像图片 URL；为空时显示本地占位头像。
  final String operatorAvatarUrl;

  /// 页面操作者信息右侧展示的操作者邮箱。
  final String operatorEmail;
}
