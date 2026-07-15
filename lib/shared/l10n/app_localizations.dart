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

  /// Heading of the device operation record page
  ///
  /// In en, this message translates to:
  /// **'OPERATION RECORD'**
  String get operationRecordTitle;

  /// Description of the time range shown on the device operation record page
  ///
  /// In en, this message translates to:
  /// **'Operation data of the last 14 days'**
  String get operationRecordLast14DaysDescription;

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

  /// No description provided for @registerCodeResending.
  ///
  /// In en, this message translates to:
  /// **'Sending verification code…'**
  String get registerCodeResending;

  /// No description provided for @registerRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to complete registration. Please try again.'**
  String get registerRequestFailed;

  /// No description provided for @registerNetworkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Network unavailable. Please try again.'**
  String get registerNetworkUnavailable;

  /// No description provided for @registerAuthorizationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration is temporarily unavailable.'**
  String get registerAuthorizationFailed;

  /// No description provided for @registerRestartRequired.
  ///
  /// In en, this message translates to:
  /// **'Your registration session has expired. Please start again.'**
  String get registerRestartRequired;

  /// No description provided for @registerSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Registration successful. Please log in.'**
  String get registerSucceeded;

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

  /// Message shown when simulated login fails unexpectedly
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please try again.'**
  String get loginFailed;

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

  /// Title of the device sharing page
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get deviceShareTitle;

  /// Subtitle of the device sharing page
  ///
  /// In en, this message translates to:
  /// **'Enjoy the smart life with your family!'**
  String get deviceShareSubtitle;

  /// Permissions field label on the device sharing page
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get deviceSharePermissionsLabel;

  /// Administrator role option on the device sharing page
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get deviceShareAdministratorRole;

  /// Guest role option on the device sharing page
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get deviceShareGuestRole;

  /// Email field label on the device sharing page
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get deviceShareEmailLabel;

  /// Email input placeholder on the device sharing page
  ///
  /// In en, this message translates to:
  /// **'Email/Account'**
  String get deviceShareEmailPlaceholder;

  /// Sharing period field label on the device sharing page
  ///
  /// In en, this message translates to:
  /// **'Sharing period'**
  String get deviceSharePeriodLabel;

  /// Never expired sharing period option
  ///
  /// In en, this message translates to:
  /// **'Never expired'**
  String get deviceShareNeverExpired;

  /// Two-hour sharing period option
  ///
  /// In en, this message translates to:
  /// **'2 hours'**
  String get deviceShareTwoHours;

  /// Custom sharing period option
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get deviceShareCustomize;

  /// Time summary and custom time dialog label on the device sharing page
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get deviceShareTimeLabel;

  /// Send email toggle label on the device sharing page
  ///
  /// In en, this message translates to:
  /// **'Send email'**
  String get deviceShareSendEmailLabel;

  /// Capabilities section title on the device sharing page
  ///
  /// In en, this message translates to:
  /// **'Capabilities'**
  String get deviceShareCapabilitiesTitle;

  /// Door control capability label on the device sharing page
  ///
  /// In en, this message translates to:
  /// **'Open/stop/close'**
  String get deviceShareCapabilityDoorControl;

  /// Partial open capability label on the device sharing page
  ///
  /// In en, this message translates to:
  /// **'Partial open'**
  String get deviceShareCapabilityPartialOpen;

  /// LED off delay capability label on the device sharing page
  ///
  /// In en, this message translates to:
  /// **'LED off delay'**
  String get deviceShareCapabilityLedDelay;

  /// Cancel button label on the device sharing page
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get deviceShareCancelAction;

  /// Confirm button label on the device sharing page
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get deviceShareConfirmAction;

  /// Title and accessibility label for the account profile menu page
  ///
  /// In en, this message translates to:
  /// **'Account profile'**
  String get accountProfileTitle;

  /// Title for the account details page
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get accountDetailsTitle;

  /// Account details row label for the user's avatar
  ///
  /// In en, this message translates to:
  /// **'Head portrait'**
  String get accountDetailsHeadPortrait;

  /// Account details row label for account number
  ///
  /// In en, this message translates to:
  /// **'Account number'**
  String get accountDetailsAccountNumber;

  /// Account details row label for full name
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get accountDetailsFullName;

  /// Account details row label for mailbox
  ///
  /// In en, this message translates to:
  /// **'Mailbox'**
  String get accountDetailsMailbox;

  /// Account details row label for changing password
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get accountDetailsChangePassword;

  /// Account details row label for forgot password
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get accountDetailsForgotPassword;

  /// Account details log out button label
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get accountDetailsLogout;

  /// Fallback account number shown while account data is unavailable
  ///
  /// In en, this message translates to:
  /// **'34345435@qq.com'**
  String get accountDetailsFallbackNumber;

  /// Fallback full name shown while account data is unavailable
  ///
  /// In en, this message translates to:
  /// **'James'**
  String get accountDetailsFallbackFullName;

  /// Fallback mailbox shown while account data is unavailable
  ///
  /// In en, this message translates to:
  /// **'123456@qq.com'**
  String get accountDetailsFallbackMailbox;

  /// Action for choosing an account avatar from the photo album
  ///
  /// In en, this message translates to:
  /// **'Photo album'**
  String get accountDetailsPhotoAlbumAction;

  /// Action for taking a new account avatar photo
  ///
  /// In en, this message translates to:
  /// **'Photograph'**
  String get accountDetailsPhotographAction;

  /// Cancel action in account details modal sheets
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get accountDetailsCancelAction;

  /// Confirm action in account details modal sheets
  ///
  /// In en, this message translates to:
  /// **'confirm'**
  String get accountDetailsConfirmAction;

  /// Title for the account full-name editing sheet
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get accountDetailsRenameTitle;

  /// Placeholder for the account name input
  ///
  /// In en, this message translates to:
  /// **'JAMES'**
  String get accountDetailsNameInputPlaceholder;

  /// Title for the account password change sheet
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get accountDetailsChangePasswordTitle;

  /// Placeholder for new password fields
  ///
  /// In en, this message translates to:
  /// **'Enter New Password'**
  String get accountDetailsNewPasswordPlaceholder;

  /// Accessibility label for showing a password field
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get accountDetailsShowPasswordAction;

  /// Accessibility label for hiding a password field
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get accountDetailsHidePasswordAction;

  /// Accessibility label for avatar choices in the account avatar sheet
  ///
  /// In en, this message translates to:
  /// **'Avatar option {index}'**
  String accountDetailsAvatarOptionLabel(int index);

  /// Fallback account email shown on the profile page while account data is unavailable
  ///
  /// In en, this message translates to:
  /// **'739059568@qq.com'**
  String get accountFallbackEmail;

  /// Account menu item for devices shared by the user
  ///
  /// In en, this message translates to:
  /// **'Shared devices'**
  String get accountSharedDevices;

  /// Account menu item for devices received from others
  ///
  /// In en, this message translates to:
  /// **'Receiving devices'**
  String get accountReceivingDevices;

  /// Account menu item for managing devices; lowercase matches the provided design
  ///
  /// In en, this message translates to:
  /// **'manage devices'**
  String get accountManageDevices;

  /// Account menu item for messages; lowercase matches the provided design
  ///
  /// In en, this message translates to:
  /// **'message'**
  String get accountMessage;

  /// Account menu item for region settings
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get accountRegion;

  /// Account menu item for language settings
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get accountLanguage;

  /// Account menu item for system permission settings
  ///
  /// In en, this message translates to:
  /// **'System permissions'**
  String get accountSystemPermissions;

  /// Account menu item for checking app updates
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get accountCheckForUpdates;

  /// Account menu item for about page
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get accountAbout;

  /// Default region value shown on the account profile page
  ///
  /// In en, this message translates to:
  /// **'England'**
  String get accountDefaultRegion;

  /// Default language value shown on the account profile page
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get accountDefaultLanguage;

  /// Temporary snackbar shown when tapping account menu rows without a destination page
  ///
  /// In en, this message translates to:
  /// **'{item} is coming soon'**
  String accountMenuComingSoon(String item);

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
  /// **'Add New Device'**
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
  /// **'Smart Opener (Built-in Wi-Fi)'**
  String get addDeviceSmartOpener;

  /// Solar Energy System option on the add device page
  ///
  /// In en, this message translates to:
  /// **'Evolution module'**
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

  /// No description provided for @smartOpenerShareDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'SHARE DEVICE'**
  String get smartOpenerShareDialogTitle;

  /// No description provided for @smartOpenerShareDialogDescription.
  ///
  /// In en, this message translates to:
  /// **'Enjoy the smart life with your family!'**
  String get smartOpenerShareDialogDescription;

  /// No description provided for @smartOpenerShareDialogAccountHint.
  ///
  /// In en, this message translates to:
  /// **'Email/Amazon account /Google account'**
  String get smartOpenerShareDialogAccountHint;

  /// No description provided for @smartOpenerDisconnectFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Unable to disconnect device. Scanning continues.'**
  String get smartOpenerDisconnectFailedMessage;

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

  /// Title for notification list and detail pages
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notificationTitle;

  /// Action that marks all notifications as read
  ///
  /// In en, this message translates to:
  /// **'All read'**
  String get notificationAllRead;

  /// Confirmation after marking all notifications as read
  ///
  /// In en, this message translates to:
  /// **'All notifications have been marked as read'**
  String get notificationAllReadMessage;

  /// Message shown for an unknown notification identifier
  ///
  /// In en, this message translates to:
  /// **'Notification not found'**
  String get notificationNotFound;

  /// Notification action that opens after-sales details
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get notificationViewDetails;

  /// Notification action that starts an after-sales appointment
  ///
  /// In en, this message translates to:
  /// **'Appointment for after-sales service'**
  String get notificationAppointmentAfterSales;

  /// Notification action that starts a device upgrade
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get notificationUpgrade;

  /// Appointment time label on notification details
  ///
  /// In en, this message translates to:
  /// **'Appointment time'**
  String get notificationAppointmentTime;

  /// Placeholder response for the upgrade action
  ///
  /// In en, this message translates to:
  /// **'Device upgrade is coming soon'**
  String get notificationUpgradeComingSoon;

  /// Title of the completed after-sales service detail page
  ///
  /// In en, this message translates to:
  /// **'After sales service details'**
  String get afterSalesDetailsTitle;

  /// Title of the after-sales appointment page
  ///
  /// In en, this message translates to:
  /// **'Appointment for after-sales service'**
  String get afterSalesAppointmentTitle;

  /// Problem description field label
  ///
  /// In en, this message translates to:
  /// **'Problem description'**
  String get afterSalesProblemDescription;

  /// Appointment date and time field label
  ///
  /// In en, this message translates to:
  /// **'appointment time'**
  String get afterSalesAppointmentTime;

  /// Editable remark field label
  ///
  /// In en, this message translates to:
  /// **'Remark'**
  String get afterSalesRemark;

  /// After-sales picture field label
  ///
  /// In en, this message translates to:
  /// **'Picture'**
  String get afterSalesPicture;

  /// Installer confirmation section label
  ///
  /// In en, this message translates to:
  /// **'Installation personnel confirm'**
  String get afterSalesInstallerConfirm;

  /// Confirmed after-sales status
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get afterSalesConfirmed;

  /// After-sales feedback action
  ///
  /// In en, this message translates to:
  /// **'feedback'**
  String get afterSalesFeedback;

  /// Action to contact the assigned installer
  ///
  /// In en, this message translates to:
  /// **'Contact the installer'**
  String get afterSalesContactInstaller;

  /// Placeholder confirmation for feedback
  ///
  /// In en, this message translates to:
  /// **'Feedback submitted'**
  String get afterSalesFeedbackSubmitted;

  /// Placeholder response for installer contact
  ///
  /// In en, this message translates to:
  /// **'Installer contact is coming soon'**
  String get afterSalesContactComingSoon;

  /// Hint below the appointment problem description
  ///
  /// In en, this message translates to:
  /// **'Suggest including key information such as equipment model, fault symptoms, etc'**
  String get afterSalesDescriptionHint;

  /// Submit after-sales appointment button
  ///
  /// In en, this message translates to:
  /// **'Submit to Engineer'**
  String get afterSalesSubmitToEngineer;

  /// Validation message for an empty problem description
  ///
  /// In en, this message translates to:
  /// **'Please enter a problem description'**
  String get afterSalesDescriptionRequired;

  /// Local confirmation after submitting an appointment
  ///
  /// In en, this message translates to:
  /// **'Appointment submitted successfully'**
  String get afterSalesSubmitSuccess;

  /// No description provided for @deviceSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Setting'**
  String get deviceSettingsTitle;

  /// No description provided for @deviceSettingsForUsers.
  ///
  /// In en, this message translates to:
  /// **'For users'**
  String get deviceSettingsForUsers;

  /// No description provided for @deviceSettingsForInstallers.
  ///
  /// In en, this message translates to:
  /// **'For installers'**
  String get deviceSettingsForInstallers;

  /// No description provided for @deviceSettingsTransmitterManagement.
  ///
  /// In en, this message translates to:
  /// **'Transmitter management'**
  String get deviceSettingsTransmitterManagement;

  /// No description provided for @deviceSettingsLedOffDelay.
  ///
  /// In en, this message translates to:
  /// **'LED off delay'**
  String get deviceSettingsLedOffDelay;

  /// No description provided for @deviceSettingsPartialOpen.
  ///
  /// In en, this message translates to:
  /// **'Partial open'**
  String get deviceSettingsPartialOpen;

  /// No description provided for @deviceSettingsPartialOpenHeight.
  ///
  /// In en, this message translates to:
  /// **'Partial open height'**
  String get deviceSettingsPartialOpenHeight;

  /// No description provided for @deviceSettingsAutoClose.
  ///
  /// In en, this message translates to:
  /// **'Auto close'**
  String get deviceSettingsAutoClose;

  /// No description provided for @deviceSettingsOpeningSpeed.
  ///
  /// In en, this message translates to:
  /// **'Opening speed'**
  String get deviceSettingsOpeningSpeed;

  /// No description provided for @deviceSettingsOpeningSpeedValue.
  ///
  /// In en, this message translates to:
  /// **'GMT+8:00'**
  String get deviceSettingsOpeningSpeedValue;

  /// No description provided for @deviceSettingsAboutDevice.
  ///
  /// In en, this message translates to:
  /// **'About the device'**
  String get deviceSettingsAboutDevice;

  /// No description provided for @deviceSettingsDoorOpenReminder.
  ///
  /// In en, this message translates to:
  /// **'Door open reminder'**
  String get deviceSettingsDoorOpenReminder;

  /// No description provided for @deviceSettingsForceMargin.
  ///
  /// In en, this message translates to:
  /// **'Force margin'**
  String get deviceSettingsForceMargin;

  /// No description provided for @deviceSettingsBluetoothName.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth name'**
  String get deviceSettingsBluetoothName;

  /// No description provided for @deviceSettingsFirmwareVersion.
  ///
  /// In en, this message translates to:
  /// **'Firmware version'**
  String get deviceSettingsFirmwareVersion;

  /// No description provided for @deviceSettingsHardwareVersion.
  ///
  /// In en, this message translates to:
  /// **'Hardware version'**
  String get deviceSettingsHardwareVersion;

  /// No description provided for @deviceSettingsCheckVersion.
  ///
  /// In en, this message translates to:
  /// **'Check version'**
  String get deviceSettingsCheckVersion;

  /// No description provided for @deviceSettingsTransmitterLearning.
  ///
  /// In en, this message translates to:
  /// **'Transmitter learning'**
  String get deviceSettingsTransmitterLearning;

  /// No description provided for @deviceSettingsManagement.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get deviceSettingsManagement;

  /// No description provided for @deviceSettingsAutoClosingSetting.
  ///
  /// In en, this message translates to:
  /// **'Auto closing setting'**
  String get deviceSettingsAutoClosingSetting;

  /// No description provided for @deviceSettingsAutoCloseCaption.
  ///
  /// In en, this message translates to:
  /// **'Current setting: 120s (motor setting)\nAuto close position'**
  String get deviceSettingsAutoCloseCaption;

  /// No description provided for @deviceSettingsAutoCloseTime.
  ///
  /// In en, this message translates to:
  /// **'Auto close time'**
  String get deviceSettingsAutoCloseTime;

  /// No description provided for @deviceSettingsUpLimit.
  ///
  /// In en, this message translates to:
  /// **'Up limit'**
  String get deviceSettingsUpLimit;

  /// No description provided for @deviceSettingsAnyPosition.
  ///
  /// In en, this message translates to:
  /// **'Any position'**
  String get deviceSettingsAnyPosition;

  /// No description provided for @deviceSettingsCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get deviceSettingsCancelAction;

  /// No description provided for @deviceSettingsConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get deviceSettingsConfirmAction;

  /// No description provided for @deviceSettingsMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String deviceSettingsMinutes(int minutes);

  /// No description provided for @deviceSettingsSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String deviceSettingsSeconds(int seconds);
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
