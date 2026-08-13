class NotificationMessagePageDto {
  const NotificationMessagePageDto({
    required this.current,
    required this.size,
    required this.total,
    required this.records,
  });

  final String current;
  final String size;
  final String total;
  final List<NotificationMessageCardDto> records;

  factory NotificationMessagePageDto.fromJson(Map<String, dynamic> json) {
    final rawRecords = json['records'];
    if (rawRecords is! List) {
      throw const FormatException('Notification records are missing.');
    }
    return NotificationMessagePageDto(
      current: _numberAsString(json['current']),
      size: _numberAsString(json['size']),
      total: _numberAsString(json['total']),
      records: rawRecords
          .map(
            (item) => NotificationMessageCardDto.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
    'current': current,
    'size': size,
    'total': total,
    'records': records.map((item) => item.toJson()).toList(growable: false),
  };
}

class NotificationMessageCardDto {
  const NotificationMessageCardDto({
    required this.id,
    required this.templateCode,
    required this.type,
    required this.iconCode,
    required this.title,
    required this.label,
    required this.summary,
    required this.read,
    required this.createTime,
  });

  final String id;
  final String templateCode;
  final String type;
  final String? iconCode;
  final String title;
  final String label;
  final String summary;
  final bool read;
  final String createTime;

  factory NotificationMessageCardDto.fromJson(Map<String, dynamic> json) =>
      NotificationMessageCardDto(
        id: _numberAsString(json['id']),
        templateCode: json['templateCode'] as String? ?? '',
        type: json['type'] as String? ?? '',
        iconCode: json['iconCode'] as String?,
        title: json['title'] as String? ?? '',
        label: json['label'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        read: json['read'] as bool? ?? false,
        createTime: json['createTime'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'templateCode': templateCode,
    'type': type,
    'iconCode': iconCode,
    'title': title,
    'label': label,
    'summary': summary,
    'read': read,
    'createTime': createTime,
  };
}

class NotificationMessageDetailDto {
  const NotificationMessageDetailDto({
    required this.id,
    required this.templateCode,
    required this.type,
    required this.title,
    required this.label,
    required this.content,
    required this.mobileLink,
    required this.read,
    required this.createTime,
  });

  final String id;
  final String templateCode;
  final String type;
  final String title;
  final String label;
  final String content;
  final String? mobileLink;
  final bool read;
  final String createTime;

  factory NotificationMessageDetailDto.fromJson(Map<String, dynamic> json) =>
      NotificationMessageDetailDto(
        id: _numberAsString(json['id']),
        templateCode: json['templateCode'] as String? ?? '',
        type: json['type'] as String? ?? '',
        title: json['title'] as String? ?? '',
        label: json['label'] as String? ?? '',
        content: json['content'] as String? ?? '',
        mobileLink: json['mobileLink'] as String?,
        read: json['read'] as bool? ?? false,
        createTime: json['createTime'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'templateCode': templateCode,
    'type': type,
    'title': title,
    'label': label,
    'content': content,
    'mobileLink': mobileLink,
    'read': read,
    'createTime': createTime,
  };
}

class NotificationUnreadStateDto {
  const NotificationUnreadStateDto({required this.hasUnread});

  final bool hasUnread;

  factory NotificationUnreadStateDto.fromJson(Map<String, dynamic> json) =>
      NotificationUnreadStateDto(
        hasUnread: json['hasUnread'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {'hasUnread': hasUnread};
}

String _numberAsString(Object? value) {
  if (value is num || value is String) return value.toString();
  throw const FormatException('Notification numeric field is invalid.');
}
