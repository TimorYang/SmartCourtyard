class PasswordPolicy {
  const PasswordPolicy._();

  static const minLength = 8;
  static const maxLength = 16;
  static final _validPasswordPattern = RegExp(
    r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d).{8,16}$',
  );

  static bool isLengthValid(String password) {
    return password.length >= minLength && password.length <= maxLength;
  }

  static bool isValid(String password) {
    return _validPasswordPattern.hasMatch(password);
  }
}
