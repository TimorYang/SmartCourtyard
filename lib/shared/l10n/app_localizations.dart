import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'FLINX'**
  String get appTitle;

  /// Headline shown on the unauthenticated welcome page
  ///
  /// In en, this message translates to:
  /// **'Start your\nsmart life'**
  String get welcomeHeadline;

  /// Subtitle shown on the unauthenticated welcome page
  ///
  /// In en, this message translates to:
  /// **'Make your life comfortable'**
  String get welcomeSubtitle;

  /// Primary login button label
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginAction;

  /// Secondary register button label
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerAction;

  /// Placeholder text for the login page
  ///
  /// In en, this message translates to:
  /// **'Login page coming soon'**
  String get loginComingSoon;

  /// Placeholder text for the register page
  ///
  /// In en, this message translates to:
  /// **'Register page coming soon'**
  String get registerComingSoon;

  /// Register page heading
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerTitle;

  /// Register page helper text asking for the account email address
  ///
  /// In en, this message translates to:
  /// **'Please enter the address associated your account'**
  String get registerDescription;

  /// Register email input placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get registerEmailPlaceholder;

  /// Register privacy agreement prefix
  ///
  /// In en, this message translates to:
  /// **'I have read and agreed '**
  String get registerAgreementPrefix;

  /// Register send verification code button label
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCodeAction;

  /// Temporary message shown when the user submits the register form
  ///
  /// In en, this message translates to:
  /// **'Verification code is not connected yet'**
  String get registerSendPending;

  /// Register verification code page heading
  ///
  /// In en, this message translates to:
  /// **'Enter Code'**
  String get registerCodeTitle;

  /// Register verification code helper text
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent an email to {email} with a confirmation code. Enter the code below to continue registration.'**
  String registerCodeDescription(String email);

  /// Accessibility label for the verification code input
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get registerCodeInputLabel;

  /// Register verification resend countdown label
  ///
  /// In en, this message translates to:
  /// **'Send Again OTP ({seconds}s)'**
  String registerCodeResend(int seconds);

  /// Register verification resend action label when the countdown has finished
  ///
  /// In en, this message translates to:
  /// **'Send Again OTP'**
  String get registerCodeResendAction;

  /// Register password setup page heading
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get registerPasswordTitle;

  /// Register password setup helper text
  ///
  /// In en, this message translates to:
  /// **'Set your password'**
  String get registerPasswordDescription;

  /// Register password input placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter an 8-digit password'**
  String get registerPasswordPlaceholder;

  /// Register confirm password input placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter the 8-digit password again'**
  String get registerConfirmPasswordPlaceholder;

  /// Temporary message shown when the user submits the register password form
  ///
  /// In en, this message translates to:
  /// **'Password registration is not connected yet'**
  String get registerPasswordPending;

  /// Forgot password page heading
  ///
  /// In en, this message translates to:
  /// **'Forget Password?'**
  String get forgotPasswordTitle;

  /// Forgot password page helper text asking for the account email address
  ///
  /// In en, this message translates to:
  /// **'Please enter the address associated your account'**
  String get forgotPasswordDescription;

  /// Temporary message shown when the user submits the forgot password form
  ///
  /// In en, this message translates to:
  /// **'Password reset code is not connected yet'**
  String get forgotPasswordSendPending;

  /// Forgot password verification code page heading
  ///
  /// In en, this message translates to:
  /// **'Enter Code'**
  String get forgotPasswordCodeTitle;

  /// Forgot password verification code helper text
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent an email to {email} with a confirmation code. Enter the code below to reset your password.'**
  String forgotPasswordCodeDescription(String email);

  /// Forgot password reset page heading
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get forgotPasswordResetTitle;

  /// Forgot password reset helper text
  ///
  /// In en, this message translates to:
  /// **'Set your password'**
  String get forgotPasswordResetDescription;

  /// Finish button label
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finishAction;

  /// Temporary message shown when the user submits the reset password form
  ///
  /// In en, this message translates to:
  /// **'Password reset is not connected yet'**
  String get forgotPasswordResetPending;

  /// Password reset success page heading
  ///
  /// In en, this message translates to:
  /// **'Reset Succeeded'**
  String get passwordResetSucceededTitle;

  /// Password reset success page helper text
  ///
  /// In en, this message translates to:
  /// **'Password reset succeeded'**
  String get passwordResetSucceededDescription;

  /// Button label for returning from password reset success to login
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLoginAction;

  /// Login page heading
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// Login email input placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get loginAccountPlaceholder;

  /// Validation message shown when the login email format is invalid
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get loginEmailInvalid;

  /// Login password input placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get loginPasswordPlaceholder;

  /// Agreement prefix text on the login page
  ///
  /// In en, this message translates to:
  /// **'I have read and agreed '**
  String get loginAgreementPrefix;

  /// Agreement middle text on the login page
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get loginAgreementMiddle;

  /// User agreement link label
  ///
  /// In en, this message translates to:
  /// **'User Agreement'**
  String get userAgreementLabel;

  /// Privacy policy link label
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyLabel;

  /// Login submit button label
  ///
  /// In en, this message translates to:
  /// **'Login in'**
  String get signInAction;

  /// Forgot password action label
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get forgotPasswordAction;

  /// Third-party sign in with Apple label
  ///
  /// In en, this message translates to:
  /// **'Continue Sign in with Apple'**
  String get continueWithApple;

  /// Third-party sign in with Google label
  ///
  /// In en, this message translates to:
  /// **'Continue Sign in with Google'**
  String get continueWithGoogle;

  /// Third-party sign in with Alexa label
  ///
  /// In en, this message translates to:
  /// **'Continue Sign in with Alexa'**
  String get continueWithAlexa;

  /// Temporary message shown when the user submits the login form
  ///
  /// In en, this message translates to:
  /// **'Login is not connected yet'**
  String get loginSubmitPending;

  /// Temporary shortcut button from the welcome page to the home page
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeShortcutAction;

  /// Greeting title on the home page
  ///
  /// In en, this message translates to:
  /// **'Hi xxxxx'**
  String get homeGreeting;

  /// Greeting subtitle on the home page
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get homeWelcome;

  /// Tooltip for the home menu action
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get homeMenuTooltip;

  /// Tooltip for editing a home
  ///
  /// In en, this message translates to:
  /// **'Edit home'**
  String get homeEditTooltip;

  /// Tooltip for adding a door from the home header
  ///
  /// In en, this message translates to:
  /// **'Add door'**
  String get homeAddDoorTooltip;

  /// Add scene action in the home add menu
  ///
  /// In en, this message translates to:
  /// **'Add Scene'**
  String get homeAddSceneMenuAction;

  /// Add door action in the home add menu
  ///
  /// In en, this message translates to:
  /// **'Add Door'**
  String get homeAddDoorMenuAction;

  /// Smart device action in the home add menu
  ///
  /// In en, this message translates to:
  /// **'Smart Device'**
  String get homeSmartDeviceMenuAction;

  /// Number of doors bound under the current home
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 Door} =1{1 Door} other{{count} Doors}}'**
  String homeDoorCount(int count);

  /// Title for the empty home state when no doors are bound
  ///
  /// In en, this message translates to:
  /// **'No doors'**
  String get homeNoDoorsTitle;

  /// Subtitle for the empty home state when no doors are bound
  ///
  /// In en, this message translates to:
  /// **'Please add Doors'**
  String get homeNoDoorsSubtitle;

  /// Add door button label on the empty home state
  ///
  /// In en, this message translates to:
  /// **'New door'**
  String get homeAddDoorAction;

  /// Error message shown when home door loading fails
  ///
  /// In en, this message translates to:
  /// **'Unable to load doors.'**
  String get homeLoadDoorsFailed;

  /// Device card label for door state
  ///
  /// In en, this message translates to:
  /// **'Door'**
  String get homeDoorStateLabel;

  /// Device card label for connection state
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get homeConnectionStateLabel;

  /// Device card label for remaining device life
  ///
  /// In en, this message translates to:
  /// **'Life remaining'**
  String get homeLifeRemainingLabel;

  /// Open door state on the home device card
  ///
  /// In en, this message translates to:
  /// **'Opened'**
  String get homeDoorStateOpen;

  /// Opening door state on the home device card
  ///
  /// In en, this message translates to:
  /// **'Opening'**
  String get homeDoorStateOpening;

  /// Stopped door state on the home device card
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get homeDoorStateStopped;

  /// Closing door state on the home device card
  ///
  /// In en, this message translates to:
  /// **'Closing'**
  String get homeDoorStateClosing;

  /// Closed door state on the home device card
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get homeDoorStateClosed;

  /// Unknown door state on the home device card
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get homeDoorStateUnknown;

  /// Title of the home device editing sheet
  ///
  /// In en, this message translates to:
  /// **'Device editing'**
  String get homeDeviceEditingTitle;

  /// Top action in the home device editing sheet
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get homeDeviceEditTopAction;

  /// Share action in the home device editing sheet
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get homeDeviceEditShareAction;

  /// Move scene action in the home device editing sheet
  ///
  /// In en, this message translates to:
  /// **'Move Scene'**
  String get homeDeviceEditMoveSceneAction;

  /// Name action in the home device editing sheet
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get homeDeviceEditNameAction;

  /// Delete device action in the home device editing sheet
  ///
  /// In en, this message translates to:
  /// **'Delete Device'**
  String get homeDeviceEditDeleteAction;

  /// Customize action in the home device editing sheet
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get homeDeviceEditCustomizeAction;

  /// Title of the dialog for editing a device name
  ///
  /// In en, this message translates to:
  /// **'Device Name'**
  String get deviceNameDialogTitle;

  /// Placeholder for the device name input
  ///
  /// In en, this message translates to:
  /// **'Input Device Name'**
  String get deviceNameInputPlaceholder;

  /// Confirmation message for deleting a device
  ///
  /// In en, this message translates to:
  /// **'Are you sure to delete the device ?'**
  String get deviceDeleteConfirmMessage;

  /// Cancel action for deleting a device
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get deviceDeleteCancelAction;

  /// Confirm action for deleting a device
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get deviceDeleteConfirmAction;

  /// Title of the device customization dialog
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get deviceCustomizeTitle;

  /// Change picture action in the device customization dialog
  ///
  /// In en, this message translates to:
  /// **'Change picture'**
  String get deviceCustomizeChangePictureAction;

  /// Default picture action in the device customization dialog
  ///
  /// In en, this message translates to:
  /// **'Default picture'**
  String get deviceCustomizeDefaultPictureAction;

  /// Add new doors page title
  ///
  /// In en, this message translates to:
  /// **'Add new doors'**
  String get addNewDoorsTitle;

  /// Add new doors page subtitle
  ///
  /// In en, this message translates to:
  /// **'Select the door to be added'**
  String get addNewDoorsSubtitle;

  /// Tooltip for the add new doors back action
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get addNewDoorsBackTooltip;

  /// Garage door option on the add new doors page
  ///
  /// In en, this message translates to:
  /// **'Garage door'**
  String get addNewDoorsGarageDoor;

  /// Roller door option on the add new doors page
  ///
  /// In en, this message translates to:
  /// **'Roller door'**
  String get addNewDoorsRollerDoor;

  /// Industrial door option on the add new doors page
  ///
  /// In en, this message translates to:
  /// **'Industrial door'**
  String get addNewDoorsIndustrialDoor;

  /// Swing gate option on the add new doors page
  ///
  /// In en, this message translates to:
  /// **'Swing gate'**
  String get addNewDoorsSwingGate;

  /// Sliding gate option on the add new doors page
  ///
  /// In en, this message translates to:
  /// **'Sliding gate'**
  String get addNewDoorsSlidingGate;

  /// Title of the dialog for naming a door
  ///
  /// In en, this message translates to:
  /// **'Door name'**
  String get addDoorNameDialogTitle;

  /// Placeholder for the door name input
  ///
  /// In en, this message translates to:
  /// **'Input door name'**
  String get addDoorNameInputPlaceholder;

  /// Default scene value in the add door dialog
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get addDoorSceneDefault;

  /// Cancel button label in the add door name dialog
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get addDoorNameCancelAction;

  /// Confirm button label in the add door name dialog
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get addDoorNameConfirmAction;

  /// Add device page title
  ///
  /// In en, this message translates to:
  /// **'Add Device'**
  String get addDeviceTitle;

  /// Add device page subtitle
  ///
  /// In en, this message translates to:
  /// **'Select the device to be added'**
  String get addDeviceSubtitle;

  /// F-box section title on the add device page
  ///
  /// In en, this message translates to:
  /// **'F-box'**
  String get addDeviceFBoxSection;

  /// Smart controller section title on the add device page
  ///
  /// In en, this message translates to:
  /// **'Smart controller'**
  String get addDeviceSmartControllerSection;

  /// Smart accessory section title on the add device page
  ///
  /// In en, this message translates to:
  /// **'Smart accessory'**
  String get addDeviceSmartAccessorySection;

  /// F-box option on the add device page
  ///
  /// In en, this message translates to:
  /// **'F-box'**
  String get addDeviceFBox;

  /// USB WIFI module option on the add device page
  ///
  /// In en, this message translates to:
  /// **'USB WIFI module'**
  String get addDeviceUsbWifiModule;

  /// Smart Opener option on the add device page
  ///
  /// In en, this message translates to:
  /// **'Smart Opener'**
  String get addDeviceSmartOpener;

  /// Solar Energy System option on the add device page
  ///
  /// In en, this message translates to:
  /// **'Solar Energy System'**
  String get addDeviceSolarEnergySystem;

  /// Camera option on the add device page
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get addDeviceCamera;

  /// Smart Opener package QR scan guide title
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get smartOpenerScanTitle;

  /// Smart Opener package QR scan guide description
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code inside the package with your smart phone.'**
  String get smartOpenerScanDescription;

  /// Smart Opener scan guide primary action
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get smartOpenerScanAction;

  /// Manual add action on the QR scanner page
  ///
  /// In en, this message translates to:
  /// **'No QR code available? Add manually'**
  String get smartOpenerScannerManualAction;

  /// Gallery action on the QR scanner page
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get smartOpenerScannerGalleryAction;

  /// Flashlight action on the QR scanner page
  ///
  /// In en, this message translates to:
  /// **'Flashlight'**
  String get smartOpenerScannerFlashlightAction;

  /// Back tooltip on Smart Opener scanner pages
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get smartOpenerScannerBackTooltip;

  /// Bluetooth scan shortcut tooltip on the QR scanner page
  ///
  /// In en, this message translates to:
  /// **'Scan Bluetooth devices'**
  String get smartOpenerScannerBluetoothTooltip;

  /// Camera permission error on QR scanner page
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required to scan the QR code.'**
  String get smartOpenerScannerPermissionError;

  /// Generic scanner error on QR scanner page
  ///
  /// In en, this message translates to:
  /// **'Unable to start the scanner.'**
  String get smartOpenerScannerUnknownError;

  /// Gallery image no QR code message
  ///
  /// In en, this message translates to:
  /// **'No QR code found in the selected image.'**
  String get smartOpenerScannerNoCodeFound;

  /// Gallery image scan failure message
  ///
  /// In en, this message translates to:
  /// **'Unable to read the selected image.'**
  String get smartOpenerScannerImageFailed;

  /// Wi-Fi page message when a QR payload is handed off
  ///
  /// In en, this message translates to:
  /// **'QR code received. Continue by connecting the device.'**
  String get smartOpenerQrPayloadReceived;

  /// Bluetooth scanning page title
  ///
  /// In en, this message translates to:
  /// **'Scanning'**
  String get smartOpenerBleScanningTitle;

  /// Bluetooth scanning page description
  ///
  /// In en, this message translates to:
  /// **'Be sure to operate on site!'**
  String get smartOpenerBleScanningDescription;

  /// Bluetooth scanning page status
  ///
  /// In en, this message translates to:
  /// **'Scanning the device, please wait...'**
  String get smartOpenerBleScanningStatus;

  /// No description provided for @smartOpenerScanResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'SCAN RESULTS'**
  String get smartOpenerScanResultsTitle;

  /// No description provided for @smartOpenerScanResultsCount.
  ///
  /// In en, this message translates to:
  /// **'Found {count} Devices'**
  String smartOpenerScanResultsCount(int count);

  /// No description provided for @smartOpenerAddAction.
  ///
  /// In en, this message translates to:
  /// **'+ Add'**
  String get smartOpenerAddAction;

  /// No description provided for @smartOpenerDefaultDeviceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Default encoding door|54-89'**
  String get smartOpenerDefaultDeviceSubtitle;

  /// No description provided for @smartOpenerDeviceNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Device not found'**
  String get smartOpenerDeviceNotFoundTitle;

  /// No description provided for @smartOpenerDeviceNotFoundDescription.
  ///
  /// In en, this message translates to:
  /// **'No nearby device is detected. Please confirm the device has been reset successfully and try scanning again!'**
  String get smartOpenerDeviceNotFoundDescription;

  /// No description provided for @smartOpenerRescanAction.
  ///
  /// In en, this message translates to:
  /// **'Rescan'**
  String get smartOpenerRescanAction;

  /// No description provided for @smartOpenerBackHomeAction.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get smartOpenerBackHomeAction;

  /// No description provided for @smartOpenerChooseWifiTitle.
  ///
  /// In en, this message translates to:
  /// **'CHOOSE WIFI'**
  String get smartOpenerChooseWifiTitle;

  /// No description provided for @smartOpenerChooseWifiDescription.
  ///
  /// In en, this message translates to:
  /// **'Device only supports a 2.4GHZ Wi-Fi connection'**
  String get smartOpenerChooseWifiDescription;

  /// No description provided for @smartOpenerSelectWifiPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select Wi-Fi'**
  String get smartOpenerSelectWifiPlaceholder;

  /// No description provided for @smartOpenerWifiPasswordPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter the Wi-Fi password'**
  String get smartOpenerWifiPasswordPlaceholder;

  /// No description provided for @smartOpenerWifiPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi password error is one of the most common reasons for failure. Please check your Wi-Fi password carefully'**
  String get smartOpenerWifiPasswordHint;

  /// No description provided for @smartOpenerEnableBluetoothTip.
  ///
  /// In en, this message translates to:
  /// **'Enable Bluetooth before submission'**
  String get smartOpenerEnableBluetoothTip;

  /// No description provided for @smartOpenerNextAction.
  ///
  /// In en, this message translates to:
  /// **'NEXT'**
  String get smartOpenerNextAction;

  /// No description provided for @smartOpenerSkipAction.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get smartOpenerSkipAction;

  /// No description provided for @smartOpenerSkipTip.
  ///
  /// In en, this message translates to:
  /// **'Only use Bluetooth mode to operate, skip Wifi distribution network'**
  String get smartOpenerSkipTip;

  /// No description provided for @smartOpenerSelectWifiTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Wi-Fi'**
  String get smartOpenerSelectWifiTitle;

  /// No description provided for @smartOpenerConnectingTitle.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get smartOpenerConnectingTitle;

  /// No description provided for @smartOpenerConnectingTip.
  ///
  /// In en, this message translates to:
  /// **'Keep your phone as close to the device as possible'**
  String get smartOpenerConnectingTip;

  /// No description provided for @smartOpenerConnectionFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Connection failed. Please check Wi-Fi password and try again.'**
  String get smartOpenerConnectionFailedMessage;

  /// No description provided for @smartOpenerOkAction.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get smartOpenerOkAction;

  /// No description provided for @smartOpenerStopAdditionTitle.
  ///
  /// In en, this message translates to:
  /// **'STOP DEVICE ADDITION'**
  String get smartOpenerStopAdditionTitle;

  /// No description provided for @smartOpenerStopAdditionDescription.
  ///
  /// In en, this message translates to:
  /// **'The device is being added. The WIFI module needs to be reset before add it again after termination.'**
  String get smartOpenerStopAdditionDescription;

  /// No description provided for @smartOpenerCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get smartOpenerCancelAction;

  /// No description provided for @smartOpenerConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get smartOpenerConfirmAction;

  /// No description provided for @smartOpenerConnectionSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection successful'**
  String get smartOpenerConnectionSuccessTitle;

  /// No description provided for @smartOpenerConnectionSuccessDescription.
  ///
  /// In en, this message translates to:
  /// **'configure the device information'**
  String get smartOpenerConnectionSuccessDescription;

  /// No description provided for @smartOpenerDeviceNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Device Name'**
  String get smartOpenerDeviceNamePlaceholder;

  /// No description provided for @smartOpenerSelectScenePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select scene'**
  String get smartOpenerSelectScenePlaceholder;

  /// No description provided for @smartOpenerInviteFamilyTip.
  ///
  /// In en, this message translates to:
  /// **'Invite the family to use it'**
  String get smartOpenerInviteFamilyTip;

  /// No description provided for @smartOpenerShareAction.
  ///
  /// In en, this message translates to:
  /// **'To share'**
  String get smartOpenerShareAction;

  /// No description provided for @smartOpenerTryAction.
  ///
  /// In en, this message translates to:
  /// **'Try it'**
  String get smartOpenerTryAction;

  /// Choose scene page title
  ///
  /// In en, this message translates to:
  /// **'CHOOSE A SCENE'**
  String get chooseSceneTitle;

  /// Tooltip for the choose scene page back action
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get chooseSceneBackTooltip;

  /// Tooltip for the choose scene page edit action
  ///
  /// In en, this message translates to:
  /// **'Edit scene'**
  String get chooseSceneEditTooltip;

  /// Number of devices in a scene
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 Devices} =1{1 Device} other{{count} Devices}}'**
  String chooseSceneDeviceCount(int count);

  /// New scene card action label
  ///
  /// In en, this message translates to:
  /// **'New scene'**
  String get chooseSceneNewSceneAction;

  /// Tooltip for opening the scene page from the home page
  ///
  /// In en, this message translates to:
  /// **'Scene'**
  String get sceneHomeShortcutTooltip;

  /// Scene page title
  ///
  /// In en, this message translates to:
  /// **'SCENE'**
  String get sceneTitle;

  /// Scene page title while editing scenes
  ///
  /// In en, this message translates to:
  /// **'SCENE EDITING'**
  String get sceneEditingTitle;

  /// Number of scenes on the scene page
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 Scenes} =1{1 Scene} other{{count} Scenes}}'**
  String sceneCount(int count);

  /// Tooltip for the scene page back action
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get sceneBackTooltip;

  /// Tooltip for the scene page edit action
  ///
  /// In en, this message translates to:
  /// **'Edit scene'**
  String get sceneEditTooltip;

  /// Tooltip for leaving scene editing mode
  ///
  /// In en, this message translates to:
  /// **'Done editing'**
  String get sceneDoneEditingTooltip;

  /// Number of devices in a scene on the scene page
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 Devices} =1{1 Device} other{{count} Devices}}'**
  String sceneDeviceCount(int count);

  /// New scene card action label on the scene page
  ///
  /// In en, this message translates to:
  /// **'New scene'**
  String get sceneNewSceneAction;

  /// Title of the dialog for creating a scene
  ///
  /// In en, this message translates to:
  /// **'Scene Name'**
  String get sceneNameDialogTitle;

  /// Placeholder for the scene name input
  ///
  /// In en, this message translates to:
  /// **'Input scene name'**
  String get sceneNameInputPlaceholder;

  /// Cancel button label in the scene name dialog
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get sceneNameCancelAction;

  /// Confirm button label in the scene name dialog
  ///
  /// In en, this message translates to:
  /// **'confirm'**
  String get sceneNameConfirmAction;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
