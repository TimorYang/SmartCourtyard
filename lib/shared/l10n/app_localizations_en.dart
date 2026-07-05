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
  String get homeAddSceneMenuAction => 'Add Scene';

  @override
  String get homeAddDoorMenuAction => 'Add Door';

  @override
  String get homeSmartDeviceMenuAction => 'Smart Device';

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
  String get homeDoorStateOpen => 'Opened';

  @override
  String get homeDoorStateOpening => 'Opening';

  @override
  String get homeDoorStateStopped => 'Stopped';

  @override
  String get homeDoorStateClosing => 'Closing';

  @override
  String get homeDoorStateClosed => 'Closed';

  @override
  String get homeDoorStateUnknown => 'Unknown';

  @override
  String get homeDeviceEditingTitle => 'Device editing';

  @override
  String get homeDeviceEditTopAction => 'Top';

  @override
  String get homeDeviceEditShareAction => 'Share';

  @override
  String get homeDeviceEditMoveSceneAction => 'Move Scene';

  @override
  String get homeDeviceEditNameAction => 'Name';

  @override
  String get homeDeviceEditDeleteAction => 'Delete Device';

  @override
  String get homeDeviceEditCustomizeAction => 'Customize';

  @override
  String get deviceNameDialogTitle => 'Device Name';

  @override
  String get deviceNameInputPlaceholder => 'Input Device Name';

  @override
  String get deviceDeleteConfirmMessage =>
      'Are you sure to delete the device ?';

  @override
  String get deviceDeleteCancelAction => 'No';

  @override
  String get deviceDeleteConfirmAction => 'Yes';

  @override
  String get deviceCustomizeTitle => 'Customize';

  @override
  String get deviceCustomizeChangePictureAction => 'Change picture';

  @override
  String get deviceCustomizeDefaultPictureAction => 'Default picture';

  @override
  String get addNewDoorsTitle => 'Add new doors';

  @override
  String get addNewDoorsSubtitle => 'Select the door to be added';

  @override
  String get addNewDoorsBackTooltip => 'Back';

  @override
  String get addNewDoorsGarageDoor => 'Garage door';

  @override
  String get addNewDoorsRollerDoor => 'Roller door';

  @override
  String get addNewDoorsIndustrialDoor => 'Industrial door';

  @override
  String get addNewDoorsSwingGate => 'Swing gate';

  @override
  String get addNewDoorsSlidingGate => 'Sliding gate';

  @override
  String get addDoorNameDialogTitle => 'Door name';

  @override
  String get addDoorNameInputPlaceholder => 'Input door name';

  @override
  String get addDoorSceneDefault => 'Home';

  @override
  String get addDoorNameCancelAction => 'Cancel';

  @override
  String get addDoorNameConfirmAction => 'Confirm';

  @override
  String get addDeviceTitle => 'Add Device';

  @override
  String get addDeviceSubtitle => 'Select the device to be added';

  @override
  String get addDeviceFBoxSection => 'F-box';

  @override
  String get addDeviceSmartControllerSection => 'Smart controller';

  @override
  String get addDeviceSmartAccessorySection => 'Smart accessory';

  @override
  String get addDeviceFBox => 'F-box';

  @override
  String get addDeviceUsbWifiModule => 'USB WIFI module';

  @override
  String get addDeviceSmartOpener => 'Smart Opener';

  @override
  String get addDeviceSolarEnergySystem => 'Solar Energy System';

  @override
  String get addDeviceCamera => 'Camera';

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
  String get sceneEditingTitle => 'SCENE EDITING';

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
  String get sceneDoneEditingTooltip => 'Done editing';

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

  @override
  String get sceneNameDialogTitle => 'Scene Name';

  @override
  String get sceneNameInputPlaceholder => 'Input scene name';

  @override
  String get sceneNameCancelAction => 'Cancel';

  @override
  String get sceneNameConfirmAction => 'confirm';
}
