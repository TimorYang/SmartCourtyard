class PasswordPolicy {
  const PasswordPolicy._();

  static const maxLength = 16;
  static final _validPasswordPattern = RegExp(
    r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d).{8,16}$',
  );

  static bool isValid(String password) {
    return _validPasswordPattern.hasMatch(password);
  }
}
