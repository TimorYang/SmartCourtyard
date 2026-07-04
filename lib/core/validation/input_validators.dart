import 'app_regex_patterns.dart';

class InputValidators {
  const InputValidators._();

  static bool isValidEmail(String value) {
    return AppRegexPatterns.email.hasMatch(value.trim());
  }
}
