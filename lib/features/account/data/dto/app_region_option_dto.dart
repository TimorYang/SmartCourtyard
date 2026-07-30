class AppRegionOptionDto {
  const AppRegionOptionDto({
    required this.regionCode,
    required this.displayName,
  });

  final String regionCode;
  final String displayName;

  factory AppRegionOptionDto.fromJson(Map<String, dynamic> json) {
    return AppRegionOptionDto(
      regionCode: json['regionCode'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
    );
  }
}
