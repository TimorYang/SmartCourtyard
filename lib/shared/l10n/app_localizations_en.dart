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
  String get registerTitle => 'Register';

  @override
  String get registerDescription =>
      'Please enter the address associated your account';

  @override
  String get registerEmailPlaceholder => 'Enter your email address';

  @override
  String get registerAgreementPrefix => 'I have read and agreed ';

  @override
  String get sendCodeAction => 'Send code';

  @override
  String get registerSendPending => 'Verification code is not connected yet';

  @override
  String get registerCodeTitle => 'Enter Code';

  @override
  String registerCodeDescription(String email) {
    return 'We\'ve sent an email to $email with a confirmation code. Enter the code below to continue registration.';
  }

  @override
  String get registerCodeInputLabel => 'Verification code';

  @override
  String registerCodeResend(int seconds) {
    return 'Send Again OTP (${seconds}s)';
  }

  @override
  String get registerCodeResendAction => 'Send Again OTP';

  @override
  String get registerPasswordTitle => 'Password';

  @override
  String get registerPasswordDescription => 'Set your password';

  @override
  String get registerPasswordPlaceholder => 'Enter an 8-digit password';

  @override
  String get registerConfirmPasswordPlaceholder =>
      'Enter the 8-digit password again';

  @override
  String get registerPasswordPending =>
      'Password registration is not connected yet';

  @override
  String get forgotPasswordTitle => 'Forget Password?';

  @override
  String get forgotPasswordDescription =>
      'Please enter the address associated your account';

  @override
  String get forgotPasswordSendPending =>
      'Password reset code is not connected yet';

  @override
  String get forgotPasswordCodeTitle => 'Enter Code';

  @override
  String forgotPasswordCodeDescription(String email) {
    return 'We\'ve sent an email to $email with a confirmation code. Enter the code below to reset your password.';
  }

  @override
  String get forgotPasswordResetTitle => 'Password';

  @override
  String get forgotPasswordResetDescription => 'Set your password';

  @override
  String get finishAction => 'Finish';

  @override
  String get forgotPasswordResetPending =>
      'Password reset is not connected yet';

  @override
  String get passwordResetSucceededTitle => 'Reset Succeeded';

  @override
  String get passwordResetSucceededDescription => 'Password reset succeeded';

  @override
  String get backToLoginAction => 'Back to Login';

  @override
  String get loginTitle => 'Login';

  @override
  String get loginAccountPlaceholder => 'Enter your email address';

  @override
  String get loginEmailInvalid => 'Enter a valid email address';

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
  String get signInAction => 'Login in';

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

  @override
  String get chooseSceneTitle => 'CHOOSE A SCENE';

  @override
  String get chooseSceneBackTooltip => 'Back';

  @override
  String get chooseSceneEditTooltip => 'Edit scene';

  @override
  String chooseSceneDeviceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Devices',
      one: '1 Device',
      zero: '0 Devices',
    );
    return '$_temp0';
  }

  @override
  String get chooseSceneNewSceneAction => 'New scene';

  @override
  String get sceneHomeShortcutTooltip => 'Scene';

  @override
  String get sceneTitle => 'SCENE';

  @override
  String sceneCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Scenes',
      one: '1 Scene',
      zero: '0 Scenes',
    );
    return '$_temp0';
  }

  @override
  String get sceneBackTooltip => 'Back';

  @override
  String get sceneEditTooltip => 'Edit scene';

  @override
  String sceneDeviceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Devices',
      one: '1 Device',
      zero: '0 Devices',
    );
    return '$_temp0';
  }

  @override
  String get sceneNewSceneAction => 'New scene';
}
