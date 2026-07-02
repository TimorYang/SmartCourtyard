// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'FLINX';

  @override
  String get welcomeHeadline => 'Start your\nsmart life';

  @override
  String get welcomeSubtitle => 'Make your life comfortable';

  @override
  String get loginAction => 'Login';

  @override
  String get registerAction => 'Register';

  @override
  String get loginComingSoon => 'Login page coming soon';

  @override
  String get registerComingSoon => 'Register page coming soon';

  @override
  String get forgotPasswordComingSoon => 'Forgot password page coming soon';

  @override
  String get loginTitle => 'Login';

  @override
  String get loginAccountPlaceholder => 'Enter account number';

  @override
  String get loginPasswordPlaceholder => 'Enter password';

  @override
  String get loginAgreementPrefix => 'I have read and agreed ';

  @override
  String get loginAgreementMiddle => ' and ';

  @override
  String get userAgreementLabel => 'User Agreement';

  @override
  String get privacyPolicyLabel => 'Privacy Policy';

  @override
  String get signInAction => 'Sign in';

  @override
  String get forgotPasswordAction => 'Forgot password';

  @override
  String get continueWithApple => 'Continue Sign in with Apple';

  @override
  String get continueWithGoogle => 'Continue Sign in with Google';

  @override
  String get continueWithAlexa => 'Continue Sign in with Alexa';

  @override
  String get loginSubmitPending => 'Login is not connected yet';

  @override
  String get homeShortcutAction => 'Home';

  @override
  String get homeGreeting => 'Hi xxxxx';

  @override
  String get homeWelcome => 'Welcome';

  @override
  String get homeMenuTooltip => 'Menu';

  @override
  String get homeEditTooltip => 'Edit home';

  @override
  String get homeAddDoorTooltip => 'Add door';

  @override
  String homeDoorCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Doors',
      one: '1 Door',
      zero: '0 Door',
    );
    return '$_temp0';
  }

  @override
  String get homeNoDoorsTitle => 'No doors';

  @override
  String get homeNoDoorsSubtitle => 'Please add Doors';

  @override
  String get homeAddDoorAction => 'New door';

  @override
  String get homeLoadDoorsFailed => 'Unable to load doors.';

  @override
  String get homeDoorStateLabel => 'Door';

  @override
  String get homeConnectionStateLabel => 'Connection';

  @override
  String get homeLifeRemainingLabel => 'Life remaining';
}
