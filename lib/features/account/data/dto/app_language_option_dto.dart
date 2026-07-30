class AppLanguageOptionDto {
  const AppLanguageOptionDto({required this.locale, required this.nativeName});

  final String locale;
  final String nativeName;

  factory AppLanguageOptionDto.fromJson(Map<String, dynamic> json) {
    return AppLanguageOptionDto(
      locale: json['locale'] as String? ?? '',
      nativeName: json['nativeName'] as String? ?? '',
    );
  }
}
