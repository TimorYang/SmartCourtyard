class SecurityBalanceRefreshResult {
  const SecurityBalanceRefreshResult({
    required this.requestId,
    required this.status,
  });

  /// 服务端评估快照 ID；接口接受但尚未创建快照时可为空。
  final String? requestId;
  final String? status;
}
