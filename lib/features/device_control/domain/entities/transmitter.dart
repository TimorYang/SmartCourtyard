/// 遥控器实体，用于承载遥控器列表接口返回并在页面展示的数据。
class Transmitter {
  const Transmitter({required this.id, required this.name});

  /// 遥控器唯一标识，用于编辑、删除等接口操作。
  final String id;

  /// 遥控器名称，用于遥控器管理列表展示。
  final String name;
}
