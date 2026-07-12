class RegistrationVerification {
  const RegistrationVerification({
    required this.registrationToken,
    required this.expiresIn,
  });

  final String registrationToken;
  final Duration expiresIn;
}
