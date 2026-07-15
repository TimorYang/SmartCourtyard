class PasswordResetVerification {
  const PasswordResetVerification({
    required this.passwordResetToken,
    required this.expiresIn,
  });

  final String passwordResetToken;
  final Duration expiresIn;
}
