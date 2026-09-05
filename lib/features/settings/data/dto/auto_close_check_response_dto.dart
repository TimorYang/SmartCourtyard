class AutoCloseCheckResponseDto {
  const AutoCloseCheckResponseDto({
    required this.autoCloseAllowed,
    this.deviceRegionVersion,
    this.deviceRegionVersionLabel,
    this.wirelessInfraredStatus,
    this.wirelessInfraredStatusLabel,
  });

  factory AutoCloseCheckResponseDto.fromJson(Map<String, dynamic> json) {
    return AutoCloseCheckResponseDto(
      autoCloseAllowed: _boolOrNull(json['autoCloseAllowed']),
      deviceRegionVersion: json['deviceRegionVersion']?.toString(),
      deviceRegionVersionLabel: json['deviceRegionVersionLabel']?.toString(),
      wirelessInfraredStatus: json['wirelessInfraredStatus']?.toString(),
      wirelessInfraredStatusLabel: json['wirelessInfraredStatusLabel']
          ?.toString(),
    );
  }

  final bool? autoCloseAllowed;
  final String? deviceRegionVersion;
  final String? deviceRegionVersionLabel;
  final String? wirelessInfraredStatus;
  final String? wirelessInfraredStatusLabel;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'autoCloseAllowed': autoCloseAllowed,
    'deviceRegionVersion': deviceRegionVersion,
    'deviceRegionVersionLabel': deviceRegionVersionLabel,
    'wirelessInfraredStatus': wirelessInfraredStatus,
    'wirelessInfraredStatusLabel': wirelessInfraredStatusLabel,
  };

  static bool? _boolOrNull(Object? value) => value is bool ? value : null;
}
