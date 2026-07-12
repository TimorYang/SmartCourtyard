class RegistrationFlowStore {
  String? _email;
  String? _registrationToken;
  DateTime? _tokenExpiresAt;

  String? get email => _email;

  String? get registrationToken {
    final expiresAt = _tokenExpiresAt;
    if (_registrationToken == null ||
        (expiresAt != null && !expiresAt.isAfter(DateTime.now()))) {
      clearVerification();
      return null;
    }
    return _registrationToken;
  }

  void start(String email) {
    _email = email;
    clearVerification();
  }

  void setVerification({required String token, required Duration expiresIn}) {
    _registrationToken = token;
    _tokenExpiresAt = DateTime.now().add(expiresIn);
  }

  void clearVerification() {
    _registrationToken = null;
    _tokenExpiresAt = null;
  }

  void clear() {
    _email = null;
    clearVerification();
  }
}
