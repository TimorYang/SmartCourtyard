class RegistrationDeviceContext {
  const RegistrationDeviceContext({
    required this.locale,
    required this.timezone,
    this.regionCode,
  });

  final String locale;
  final String timezone;
  final String? regionCode;
}
