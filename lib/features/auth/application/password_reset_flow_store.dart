class PasswordResetFlowStore {
  String? _email;
  String? _passwordResetToken;
  DateTime? _tokenExpiresAt;

  String? get email => _email;

  String? get passwordResetToken {
    final expiresAt = _tokenExpiresAt;
    if (_passwordResetToken == null ||
        (expiresAt != null && !expiresAt.isAfter(DateTime.now()))) {
      clearVerification();
      return null;
    }
    return _passwordResetToken;
  }

  void start(String email) {
    _email = email;
    clearVerification();
  }

  void setVerification({required String token, required Duration expiresIn}) {
    _passwordResetToken = token;
    _tokenExpiresAt = DateTime.now().add(expiresIn);
  }

  void clearVerification() {
    _passwordResetToken = null;
    _tokenExpiresAt = null;
  }

  void clear() {
    _email = null;
    clearVerification();
  }
}
