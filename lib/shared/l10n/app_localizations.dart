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

  /// No description provided for @networkErrorUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Network unavailable. Check your connection and try again.'**
  String get networkErrorUnavailable;

  /// No description provided for @networkErrorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get networkErrorSessionExpired;

  /// No description provided for @networkErrorAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to complete this action.'**
  String get networkErrorAccessDenied;

  /// No description provided for @networkErrorRequestTimeout.
  ///
  /// In en, this message translates to:
  /// **'The request timed out. Please try again.'**
  String get networkErrorRequestTimeout;

  /// No description provided for @networkErrorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait a moment and try again.'**
  String get networkErrorRateLimited;

  /// No description provided for @networkErrorRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'The request couldn\'t be completed. Please try again.'**
  String get networkErrorRequestFailed;

  /// No description provided for @networkErrorServiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The service is temporarily unavailable. Please try again later.'**
  String get networkErrorServiceUnavailable;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'FLINX'**
  String get appTitle;

  /// Heading of the device operation record page
  ///
  /// In en, this message translates to:
  /// **'Operation Record'**
  String get operationRecordTitle;

  /// Description of the time range shown on the device operation record page
  ///
  /// In en, this message translates to:
  /// **'Operation data of the last 14 days'**
  String get operationRecordLast14DaysDescription;

  /// No description provided for @operationRecordLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load operation records. Tap to retry.'**
  String get operationRecordLoadFailed;

  /// No description provided for @operationRecordLoadMoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load more records. Tap to retry.'**
  String get operationRecordLoadMoreFailed;

  /// No description provided for @operationRecordNoMore.
  ///
  /// In en, this message translates to:
  /// **'No more records'**
  String get operationRecordNoMore;

  /// No description provided for @operationRecordEmpty.
  ///
  /// In en, this message translates to:
  /// **'No operation records yet'**
  String get operationRecordEmpty;

  /// No description provided for @operationRecordUnknownOperator.
  ///
  /// In en, this message translates to:
  /// **'Unknown operator'**
  String get operationRecordUnknownOperator;

  /// No description provided for @operationRecordUnknownTime.
  ///
  /// In en, this message translates to:
  /// **'Unknown time'**
  String get operationRecordUnknownTime;

  /// No description provided for @operationRecordUnknownDoor.
  ///
  /// In en, this message translates to:
  /// **'Unknown door'**
  String get operationRecordUnknownDoor;

  /// No description provided for @operationRecordActionOpen.
  ///
  /// In en, this message translates to:
  /// **'Open door'**
  String get operationRecordActionOpen;

  /// No description provided for @operationRecordActionClose.
  ///
  /// In en, this message translates to:
  /// **'Close door'**
  String get operationRecordActionClose;

  /// No description provided for @operationRecordActionStop.
  ///
  /// In en, this message translates to:
  /// **'Stop door'**
  String get operationRecordActionStop;

  /// No description provided for @operationRecordActionAutoCloseToggle.
  ///
  /// In en, this message translates to:
  /// **'Toggle auto close'**
  String get operationRecordActionAutoCloseToggle;

  /// No description provided for @operationRecordActionLedOn.
  ///
  /// In en, this message translates to:
  /// **'LED on'**
  String get operationRecordActionLedOn;

  /// No description provided for @operationRecordActionLedOff.
  ///
  /// In en, this message translates to:
  /// **'LED off'**
  String get operationRecordActionLedOff;

  /// No description provided for @operationRecordActionLedOffDelayChanged.
  ///
  /// In en, this message translates to:
  /// **'Change LED off delay'**
  String get operationRecordActionLedOffDelayChanged;

  /// No description provided for @operationRecordActionPartialOpenChanged.
  ///
  /// In en, this message translates to:
  /// **'Change partial open'**
  String get operationRecordActionPartialOpenChanged;

  /// No description provided for @operationRecordActionAutoCloseDelayChanged.
  ///
  /// In en, this message translates to:
  /// **'Change auto close delay'**
  String get operationRecordActionAutoCloseDelayChanged;

  /// No description provided for @operationRecordActionDoorOpenReminderToggle.
  ///
  /// In en, this message translates to:
  /// **'Toggle door open reminder'**
  String get operationRecordActionDoorOpenReminderToggle;

  /// No description provided for @operationRecordActionDoorOpenReminderDelayChanged.
  ///
  /// In en, this message translates to:
  /// **'Change door open reminder delay'**
  String get operationRecordActionDoorOpenReminderDelayChanged;

  /// No description provided for @operationRecordActionUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown action'**
  String get operationRecordActionUnknown;

  /// No description provided for @refreshControlPullToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh'**
  String get refreshControlPullToRefresh;

  /// No description provided for @refreshControlReleaseToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Release to refresh'**
  String get refreshControlReleaseToRefresh;

  /// No description provided for @refreshControlRefreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing...'**
  String get refreshControlRefreshing;

  /// No description provided for @refreshControlRefreshSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Refresh succeeded'**
  String get refreshControlRefreshSucceeded;

  /// No description provided for @refreshControlRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Refresh failed'**
  String get refreshControlRefreshFailed;

  /// No description provided for @refreshControlPullToLoad.
  ///
  /// In en, this message translates to:
  /// **'Pull to load more'**
  String get refreshControlPullToLoad;

  /// No description provided for @refreshControlReleaseToLoad.
  ///
  /// In en, this message translates to:
  /// **'Release to load more'**
  String get refreshControlReleaseToLoad;

  /// No description provided for @refreshControlLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get refreshControlLoading;

  /// No description provided for @refreshControlLoadSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Load succeeded'**
  String get refreshControlLoadSucceeded;

  /// No description provided for @refreshControlLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Load failed'**
  String get refreshControlLoadFailed;

  /// No description provided for @refreshControlNoMoreData.
  ///
  /// In en, this message translates to:
  /// **'No more data'**
  String get refreshControlNoMoreData;

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
  /// **'Enter password'**
  String get registerPasswordPlaceholder;

  /// Register confirm password input placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter password again'**
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

  /// Password complexity requirements shown below password confirmation fields
  ///
  /// In en, this message translates to:
  /// **'Password: 8-16 chars, 1 uppercase, lowercase & number'**
  String get authPasswordRule;

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

  /// No description provided for @passwordResetRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to reset password. Please try again.'**
  String get passwordResetRequestFailed;

  /// No description provided for @passwordResetNetworkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Network unavailable. Please try again.'**
  String get passwordResetNetworkUnavailable;

  /// No description provided for @passwordResetAuthorizationFailed.
  ///
  /// In en, this message translates to:
  /// **'Password reset is temporarily unavailable.'**
  String get passwordResetAuthorizationFailed;

  /// No description provided for @passwordResetRestartRequired.
  ///
  /// In en, this message translates to:
  /// **'Your password reset session has expired. Please start again.'**
  String get passwordResetRestartRequired;

  /// No description provided for @passwordResetResponseContractPending.
  ///
  /// In en, this message translates to:
  /// **'Verification succeeded. Password reset will be enabled after the response contract is confirmed.'**
  String get passwordResetResponseContractPending;

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
  /// **'Sign in'**
  String get signInAction;

  /// Forgot password action label
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get forgotPasswordAction;

  /// Accessibility label for clearing the login account field
  ///
  /// In en, this message translates to:
  /// **'Clear account'**
  String get loginClearAccountAction;

  /// Accessibility label for showing the login password
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get loginShowPasswordAction;

  /// Accessibility label for hiding the login password
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get loginHidePasswordAction;

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

  /// Third-party sign in with Facebook label
  ///
  /// In en, this message translates to:
  /// **'Continue Sign in with Facebook'**
  String get continueWithFacebook;

  /// Heading above the compact third-party login options
  ///
  /// In en, this message translates to:
  /// **'Other ways to login'**
  String get otherWaysToLogin;

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

  /// Message shown when Apple sign-in is attempted before accepting the agreements
  ///
  /// In en, this message translates to:
  /// **'Please agree to the User Agreement and Privacy Policy first.'**
  String get appleLoginAgreementRequired;

  /// Message shown when Apple sign-in is not supported or configured
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple is unavailable on this device.'**
  String get appleLoginUnavailable;

  /// Message shown when Apple sign-in fails
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple failed. Please try again.'**
  String get appleLoginFailed;

  /// Message shown when Google sign-in is attempted before accepting the agreements
  ///
  /// In en, this message translates to:
  /// **'Please agree to the User Agreement and Privacy Policy first.'**
  String get googleLoginAgreementRequired;

  /// Message shown when Google sign-in is not supported or configured
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google is unavailable or not configured on this device.'**
  String get googleLoginUnavailable;

  /// Message shown when Google sign-in fails
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed. Please try again.'**
  String get googleLoginFailed;

  /// Message shown when Facebook sign-in is attempted before accepting the agreements
  ///
  /// In en, this message translates to:
  /// **'Please agree to the User Agreement and Privacy Policy first.'**
  String get facebookLoginAgreementRequired;

  /// Message shown when Facebook sign-in is not supported or configured
  ///
  /// In en, this message translates to:
  /// **'Facebook sign-in is unavailable or not configured on this device.'**
  String get facebookLoginUnavailable;

  /// Message shown when Facebook sign-in fails
  ///
  /// In en, this message translates to:
  /// **'Facebook sign-in failed. Please try again.'**
  String get facebookLoginFailed;

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

  /// Message shown when sharing a door that has no device
  ///
  /// In en, this message translates to:
  /// **'No Device'**
  String get homeNoDeviceMessage;

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
  /// **'Address'**
  String get deviceShareEmailLabel;

  /// Email input placeholder on the device sharing page
  ///
  /// In en, this message translates to:
  /// **'Email/Account'**
  String get deviceShareEmailPlaceholder;

  /// Validation message shown when the sharing address is not a valid email
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get deviceShareAddressInvalid;

  /// Sharing period field label on the device sharing page
  ///
  /// In en, this message translates to:
  /// **'Access end'**
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

  /// No description provided for @deviceShareCapabilityPartialOpenLevel.
  ///
  /// In en, this message translates to:
  /// **'Partial opening level'**
  String get deviceShareCapabilityPartialOpenLevel;

  /// No description provided for @deviceShareCapabilityLedControl.
  ///
  /// In en, this message translates to:
  /// **'LED control'**
  String get deviceShareCapabilityLedControl;

  /// LED off delay capability label on the device sharing page
  ///
  /// In en, this message translates to:
  /// **'LED off delay'**
  String get deviceShareCapabilityLedDelay;

  /// Capability option displayed when sharing a device
  ///
  /// In en, this message translates to:
  /// **'Auto-close'**
  String get deviceShareCapabilityAutoClose;

  /// No description provided for @deviceShareCapabilityTransmitterPairing.
  ///
  /// In en, this message translates to:
  /// **'Transmitter pairing'**
  String get deviceShareCapabilityTransmitterPairing;

  /// Capability option displayed when sharing a device
  ///
  /// In en, this message translates to:
  /// **'Door open reminder'**
  String get deviceShareCapabilityDoorOpenReminder;

  /// Capability option displayed when sharing a device
  ///
  /// In en, this message translates to:
  /// **'Door open force'**
  String get deviceShareCapabilityDoorOpenForce;

  /// Capability option displayed when sharing a device
  ///
  /// In en, this message translates to:
  /// **'Door open speed'**
  String get deviceShareCapabilityDoorOpenSpeed;

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

  /// No description provided for @deviceShareDoorUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This door is unavailable for sharing.'**
  String get deviceShareDoorUnavailable;

  /// No description provided for @deviceShareCapabilitiesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load share capabilities. Tap to retry.'**
  String get deviceShareCapabilitiesLoadFailed;

  /// No description provided for @deviceShareSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to create the share. Please try again.'**
  String get deviceShareSubmitFailed;

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

  /// Account details row label for deleting the current account
  ///
  /// In en, this message translates to:
  /// **'Cancel account'**
  String get accountDetailsCancelAccount;

  /// Confirmation prompt before deleting the current account
  ///
  /// In en, this message translates to:
  /// **'Are you sure to cancel the account?'**
  String get accountDetailsDeletionPrompt;

  /// Dismiss account deletion confirmation
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get accountDetailsDeletionNoAction;

  /// Confirm account deletion
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get accountDetailsDeletionYesAction;

  /// Account deletion confirmation action while submitting
  ///
  /// In en, this message translates to:
  /// **'Deleting...'**
  String get accountDetailsDeletionSubmitting;

  /// Shown when account deletion fails
  ///
  /// In en, this message translates to:
  /// **'Unable to cancel the account. Please try again.'**
  String get accountDetailsDeletionFailed;

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

  /// Title shown when taking an account avatar photo requires a denied camera permission
  ///
  /// In en, this message translates to:
  /// **'Camera permission required'**
  String get accountDetailsCameraPermissionDeniedTitle;

  /// Explanation shown when taking an account avatar photo requires a denied camera permission
  ///
  /// In en, this message translates to:
  /// **'Camera access is turned off. Go to Settings to enable it.'**
  String get accountDetailsCameraPermissionDeniedMessage;

  /// Action that opens app settings to enable camera permission for taking an account avatar photo
  ///
  /// In en, this message translates to:
  /// **'Go to Settings'**
  String get accountDetailsCameraPermissionSettingsAction;

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

  /// No description provided for @accountOverviewRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to refresh account overview. Please try again.'**
  String get accountOverviewRefreshFailed;

  /// No description provided for @accountOverviewRefreshTimeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Refresh time unavailable'**
  String get accountOverviewRefreshTimeUnavailable;

  /// Account menu item for devices shared by the user
  ///
  /// In en, this message translates to:
  /// **'Shared devices'**
  String get accountSharedDevices;

  /// Title for the shared devices page
  ///
  /// In en, this message translates to:
  /// **'Shared devices'**
  String get sharedDevicesTitle;

  /// Number of people a device is shared with
  ///
  /// In en, this message translates to:
  /// **'Share to {count} people'**
  String sharedDevicesShareToPeople(int count);

  /// Accessibility label for the shared devices add button
  ///
  /// In en, this message translates to:
  /// **'Add shared device'**
  String get sharedDevicesAddLabel;

  /// Empty state for the shared devices list
  ///
  /// In en, this message translates to:
  /// **'No shared devices yet.'**
  String get sharedDevicesEmpty;

  /// Error state for the shared devices list
  ///
  /// In en, this message translates to:
  /// **'Unable to load shared devices.'**
  String get sharedDevicesLoadFailed;

  /// Retry action for the shared devices list
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get sharedDevicesRetry;

  /// Heading for device administrators in shared member management
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get sharedDeviceMemberAdministrator;

  /// Heading for device guests in shared member management
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get sharedDeviceMemberGuest;

  /// Accepted state for a shared device member
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get sharedDeviceMemberAccepted;

  /// Accessibility label for the shared device member edit action
  ///
  /// In en, this message translates to:
  /// **'Edit shared device member'**
  String get sharedDeviceMemberEditLabel;

  /// Accessibility label for the shared device member delete action
  ///
  /// In en, this message translates to:
  /// **'Delete shared device member'**
  String get sharedDeviceMemberDeleteLabel;

  /// Accessibility label for the shared device member avatar placeholder
  ///
  /// In en, this message translates to:
  /// **'Shared device member avatar'**
  String get sharedDeviceMemberAvatarPlaceholderLabel;

  /// Account menu item for devices received from others
  ///
  /// In en, this message translates to:
  /// **'Receiving devices'**
  String get accountReceivingDevices;

  /// Title for the receiving devices page
  ///
  /// In en, this message translates to:
  /// **'RECEIVING DEVICES'**
  String get receivingDevicesTitle;

  /// Title for the receiving devices page while editing
  ///
  /// In en, this message translates to:
  /// **'RECEIVING DEVICES EDITING'**
  String get receivingDevicesEditingTitle;

  /// Owner email shown below a receiving device name
  ///
  /// In en, this message translates to:
  /// **'Shared by: {ownerEmail}'**
  String receivingDevicesOwnerEmail(String ownerEmail);

  /// Empty state for the receiving devices list
  ///
  /// In en, this message translates to:
  /// **'No receiving devices yet.'**
  String get receivingDevicesEmpty;

  /// Error state for the receiving devices list
  ///
  /// In en, this message translates to:
  /// **'Unable to load receiving devices.'**
  String get receivingDevicesLoadFailed;

  /// Retry action for the receiving devices list
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get receivingDevicesRetry;

  /// Accessibility label for entering receiving devices edit mode
  ///
  /// In en, this message translates to:
  /// **'Edit receiving devices'**
  String get receivingDevicesEditLabel;

  /// Accessibility label for leaving receiving devices edit mode
  ///
  /// In en, this message translates to:
  /// **'Done editing'**
  String get receivingDevicesDoneEditingLabel;

  /// Accessibility label for deleting a receiving device
  ///
  /// In en, this message translates to:
  /// **'Delete receiving device'**
  String get receivingDevicesDeleteLabel;

  /// Error shown when deleting a receiving device fails
  ///
  /// In en, this message translates to:
  /// **'Failed to delete the receiving device. Please try again.'**
  String get receivingDevicesDeleteFailed;

  /// Account menu item for managing devices; lowercase matches the provided design
  ///
  /// In en, this message translates to:
  /// **'manage devices'**
  String get accountManageDevices;

  /// Title of the signed-in device management page
  ///
  /// In en, this message translates to:
  /// **'Manage devices'**
  String get manageDevicesTitle;

  /// Subtitle of the signed-in device management page
  ///
  /// In en, this message translates to:
  /// **'Devices logged in'**
  String get manageDevicesSubtitle;

  /// Empty state for the signed-in device list
  ///
  /// In en, this message translates to:
  /// **'No signed-in devices.'**
  String get manageDevicesEmpty;

  /// Error state for the signed-in device list
  ///
  /// In en, this message translates to:
  /// **'Unable to load signed-in devices.'**
  String get manageDevicesLoadFailed;

  /// Retry action for the signed-in device list
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get manageDevicesRetry;

  /// Fallback name for an iOS signed-in device
  ///
  /// In en, this message translates to:
  /// **'iOS device'**
  String get manageDevicesIosName;

  /// Fallback name for an Android signed-in device
  ///
  /// In en, this message translates to:
  /// **'Android device'**
  String get manageDevicesAndroidName;

  /// Fallback name for a signed-in device with an unknown platform
  ///
  /// In en, this message translates to:
  /// **'Unknown device'**
  String get manageDevicesUnknownDevice;

  /// Fallback timestamp for a signed-in device with no valid login time
  ///
  /// In en, this message translates to:
  /// **'Unknown login time'**
  String get manageDevicesUnknownLoginTime;

  /// Shown when removing a signed-in device fails
  ///
  /// In en, this message translates to:
  /// **'Unable to remove this device. Please try again.'**
  String get manageDevicesRemoveFailed;

  /// Sample phone name displayed in the device management page
  ///
  /// In en, this message translates to:
  /// **'Iphone 16 pro max'**
  String get manageDevicesPhoneName;

  /// Sample tablet name displayed in the device management page
  ///
  /// In en, this message translates to:
  /// **'Ipad air'**
  String get manageDevicesTabletName;

  /// Sample last active time displayed in the device management page
  ///
  /// In en, this message translates to:
  /// **'2025-08-02 11:02'**
  String get manageDevicesLastActiveAt;

  /// Timestamp displayed under a signed-in device name
  ///
  /// In en, this message translates to:
  /// **'{year}-{month}-{day} {hour}:{minute}'**
  String manageDevicesLoginTimestamp(
    int year,
    String month,
    String day,
    String hour,
    String minute,
  );

  /// Accessibility label for the Manage devices edit icon
  ///
  /// In en, this message translates to:
  /// **'Edit signed-in devices'**
  String get manageDevicesEditLabel;

  /// Accessibility label for a signed-in device sign-out icon
  ///
  /// In en, this message translates to:
  /// **'Sign out device'**
  String get manageDevicesLogoutLabel;

  /// Confirmation shown before removing a signed-in device from the Manage devices list
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove\nthis device?'**
  String get manageDevicesRemoveConfirmationMessage;

  /// Action that dismisses the signed-in device removal confirmation
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get manageDevicesRemoveCancelAction;

  /// Action that confirms removal of a signed-in device
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get manageDevicesRemoveConfirmAction;

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

  /// No description provided for @systemPermissionsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM PERMISSIONS'**
  String get systemPermissionsPageTitle;

  /// No description provided for @systemPermissionsLocation.
  ///
  /// In en, this message translates to:
  /// **'Access Geographic Location'**
  String get systemPermissionsLocation;

  /// No description provided for @systemPermissionsCamera.
  ///
  /// In en, this message translates to:
  /// **'Access Camera Permissions'**
  String get systemPermissionsCamera;

  /// No description provided for @systemPermissionsMicrophone.
  ///
  /// In en, this message translates to:
  /// **'Access recording permission'**
  String get systemPermissionsMicrophone;

  /// No description provided for @systemPermissionsStorage.
  ///
  /// In en, this message translates to:
  /// **'Access phone storage'**
  String get systemPermissionsStorage;

  /// No description provided for @systemPermissionsBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Access mobile Bluetooth'**
  String get systemPermissionsBluetooth;

  /// No description provided for @systemPermissionsGranted.
  ///
  /// In en, this message translates to:
  /// **'Granted'**
  String get systemPermissionsGranted;

  /// No description provided for @systemPermissionsDenied.
  ///
  /// In en, this message translates to:
  /// **'Not granted'**
  String get systemPermissionsDenied;

  /// No description provided for @systemPermissionsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load system permissions.'**
  String get systemPermissionsLoadError;

  /// No description provided for @systemPermissionsRequestError.
  ///
  /// In en, this message translates to:
  /// **'Unable to request this permission.'**
  String get systemPermissionsRequestError;

  /// Account menu item for after-sales support
  ///
  /// In en, this message translates to:
  /// **'after-sales service'**
  String get accountAfterSalesService;

  /// Account menu item for manuals and guides
  ///
  /// In en, this message translates to:
  /// **'Manual & guide'**
  String get accountManualGuide;

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

  /// No description provided for @upgradeCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Check the upgraded version'**
  String get upgradeCheckTitle;

  /// No description provided for @upgradeCheckAppSection.
  ///
  /// In en, this message translates to:
  /// **'APP'**
  String get upgradeCheckAppSection;

  /// No description provided for @upgradeCheckAppUpdateName.
  ///
  /// In en, this message translates to:
  /// **'App version update'**
  String get upgradeCheckAppUpdateName;

  /// No description provided for @upgradeCheckFirmwareSection.
  ///
  /// In en, this message translates to:
  /// **'firmware'**
  String get upgradeCheckFirmwareSection;

  /// No description provided for @upgradeCheckStartAction.
  ///
  /// In en, this message translates to:
  /// **'Start upgrading'**
  String get upgradeCheckStartAction;

  /// No description provided for @upgradeCheckUpgrading.
  ///
  /// In en, this message translates to:
  /// **'Upgrading'**
  String get upgradeCheckUpgrading;

  /// No description provided for @upgradeCheckCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get upgradeCheckCompleted;

  /// No description provided for @upgradeCheckDoorDeviceName.
  ///
  /// In en, this message translates to:
  /// **'Door Device Name : {name}'**
  String upgradeCheckDoorDeviceName(String name);

  /// No description provided for @upgradeCheckSerialNumber.
  ///
  /// In en, this message translates to:
  /// **'serial number : {number}'**
  String upgradeCheckSerialNumber(String number);

  /// No description provided for @upgradeCheckCurrentVersion.
  ///
  /// In en, this message translates to:
  /// **'Current Version : {version}'**
  String upgradeCheckCurrentVersion(String version);

  /// No description provided for @upgradeCheckAvailableVersion.
  ///
  /// In en, this message translates to:
  /// **'Available Version : {version}'**
  String upgradeCheckAvailableVersion(String version);

  /// No description provided for @upgradeCheckScheduledFor.
  ///
  /// In en, this message translates to:
  /// **'Scheduled for: {dateTime}'**
  String upgradeCheckScheduledFor(String dateTime);

  /// No description provided for @upgradeCheckExpandDoor.
  ///
  /// In en, this message translates to:
  /// **'Expand {name}'**
  String upgradeCheckExpandDoor(String name);

  /// No description provided for @upgradeCheckCollapseDoor.
  ///
  /// In en, this message translates to:
  /// **'Collapse {name}'**
  String upgradeCheckCollapseDoor(String name);

  /// No description provided for @upgradeCheckSelectionLimit.
  ///
  /// In en, this message translates to:
  /// **'You can select up to 10 upgrade items at a time.'**
  String get upgradeCheckSelectionLimit;

  /// No description provided for @upgradeCheckPartialNotAccepted.
  ///
  /// In en, this message translates to:
  /// **'Some upgrade tasks were not accepted.'**
  String get upgradeCheckPartialNotAccepted;

  /// No description provided for @upgradeCheckSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to submit the upgrade. Try again.'**
  String get upgradeCheckSubmitFailed;

  /// No description provided for @upgradeCheckOpenStoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to open the app store.'**
  String get upgradeCheckOpenStoreFailed;

  /// No description provided for @upgradeCheckSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting'**
  String get upgradeCheckSubmitting;

  /// No description provided for @upgradeCheckSizeBytes.
  ///
  /// In en, this message translates to:
  /// **'{value} B'**
  String upgradeCheckSizeBytes(String value);

  /// No description provided for @upgradeCheckSizeKilobytes.
  ///
  /// In en, this message translates to:
  /// **'{value} KB'**
  String upgradeCheckSizeKilobytes(String value);

  /// No description provided for @upgradeCheckSizeMegabytes.
  ///
  /// In en, this message translates to:
  /// **'{value} MB'**
  String upgradeCheckSizeMegabytes(String value);

  /// No description provided for @upgradeCheckSelectTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Select upgrade time'**
  String get upgradeCheckSelectTimeTitle;

  /// No description provided for @upgradeCheckStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get upgradeCheckStatus;

  /// No description provided for @upgradeCheckUpgradeTime.
  ///
  /// In en, this message translates to:
  /// **'Upgrade time'**
  String get upgradeCheckUpgradeTime;

  /// No description provided for @upgradeCheckImmediate.
  ///
  /// In en, this message translates to:
  /// **'immediate'**
  String get upgradeCheckImmediate;

  /// No description provided for @upgradeCheckPostpone.
  ///
  /// In en, this message translates to:
  /// **'postpone'**
  String get upgradeCheckPostpone;

  /// No description provided for @upgradeCheckDateAndTime.
  ///
  /// In en, this message translates to:
  /// **'date and time'**
  String get upgradeCheckDateAndTime;

  /// No description provided for @upgradeCheckSchedulePastError.
  ///
  /// In en, this message translates to:
  /// **'Choose a time in the future.'**
  String get upgradeCheckSchedulePastError;

  /// No description provided for @upgradeCheckCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get upgradeCheckCancelAction;

  /// No description provided for @upgradeCheckConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get upgradeCheckConfirmAction;

  /// No description provided for @upgradeCheckOnline.
  ///
  /// In en, this message translates to:
  /// **'online'**
  String get upgradeCheckOnline;

  /// No description provided for @upgradeCheckOffline.
  ///
  /// In en, this message translates to:
  /// **'offline'**
  String get upgradeCheckOffline;

  /// No description provided for @upgradeCheckProgressPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String upgradeCheckProgressPercent(int percent);

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

  /// Title of the account language selection dialog
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get accountLanguageDialogTitle;

  /// No description provided for @accountLanguageOptionFrench.
  ///
  /// In en, this message translates to:
  /// **'France'**
  String get accountLanguageOptionFrench;

  /// No description provided for @accountLanguageOptionEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get accountLanguageOptionEnglish;

  /// No description provided for @accountLanguageOptionSimplifiedChinese.
  ///
  /// In en, this message translates to:
  /// **'中文(简体)'**
  String get accountLanguageOptionSimplifiedChinese;

  /// No description provided for @accountLanguageOptionTraditionalChinese.
  ///
  /// In en, this message translates to:
  /// **'中文(繁体)'**
  String get accountLanguageOptionTraditionalChinese;

  /// No description provided for @accountLanguageOptionGerman.
  ///
  /// In en, this message translates to:
  /// **'Das ist Deutsch'**
  String get accountLanguageOptionGerman;

  /// No description provided for @accountLanguageCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get accountLanguageCancelAction;

  /// No description provided for @accountLanguageConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get accountLanguageConfirmAction;

  /// No description provided for @accountLanguageOptionsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading available languages…'**
  String get accountLanguageOptionsLoading;

  /// No description provided for @accountLanguageOptionsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load available languages.'**
  String get accountLanguageOptionsLoadFailed;

  /// No description provided for @accountLanguageOptionsRetryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get accountLanguageOptionsRetryAction;

  /// No description provided for @accountLanguageSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to update the language.'**
  String get accountLanguageSaveFailed;

  /// No description provided for @regionOptionsRetryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get regionOptionsRetryAction;

  /// No description provided for @regionOptionsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to update the region.'**
  String get regionOptionsSaveFailed;

  /// Title for the region selection page
  ///
  /// In en, this message translates to:
  /// **'REGION'**
  String get regionPageTitle;

  /// China option on the region selection page
  ///
  /// In en, this message translates to:
  /// **'China'**
  String get regionChina;

  /// America option on the region selection page
  ///
  /// In en, this message translates to:
  /// **'America'**
  String get regionAmerica;

  /// England option on the region selection page
  ///
  /// In en, this message translates to:
  /// **'England'**
  String get regionEngland;

  /// France option on the region selection page
  ///
  /// In en, this message translates to:
  /// **'La Republique francaise'**
  String get regionFrance;

  /// Canada option on the region selection page
  ///
  /// In en, this message translates to:
  /// **'Canada'**
  String get regionCanada;

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

  /// No description provided for @deviceCustomizeChangePictureFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to change picture. Please try again.'**
  String get deviceCustomizeChangePictureFailed;

  /// No description provided for @deviceCustomizeResetPictureFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to reset the default picture. Please try again.'**
  String get deviceCustomizeResetPictureFailed;

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

  /// Placeholder for the scene selector in the add door dialog
  ///
  /// In en, this message translates to:
  /// **'Select scene'**
  String get addDoorSceneSelectPlaceholder;

  /// Loading status for the scene selector in the add door dialog
  ///
  /// In en, this message translates to:
  /// **'Loading scenes…'**
  String get addDoorSceneLoading;

  /// Empty status for the scene selector in the add door dialog
  ///
  /// In en, this message translates to:
  /// **'No scenes available'**
  String get addDoorSceneEmpty;

  /// Retry message for a failed scene selector request in the add door dialog
  ///
  /// In en, this message translates to:
  /// **'Unable to load scenes. Tap to retry.'**
  String get addDoorSceneLoadFailed;

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

  /// Title of the F-box connection guide
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get fBoxConnectionGuideTitle;

  /// Connection instructions on the F-box connection guide
  ///
  /// In en, this message translates to:
  /// **'1. Connect power supply to door operator, confirm the Wi-Fi light is flashing or steady\n2. Confirm other related accessories have been matched to F-box.'**
  String get fBoxConnectionGuideInstructions;

  /// Manual reference note on the F-box connection guide
  ///
  /// In en, this message translates to:
  /// **'*Connection steps refer to manuals'**
  String get fBoxConnectionGuideManualHint;

  /// Primary action on the F-box connection guide
  ///
  /// In en, this message translates to:
  /// **'NEXT'**
  String get fBoxConnectionGuideNextAction;

  /// Tooltip for the add action on the F-box wiring test page
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get fBoxWiringTestAddTooltip;

  /// Title of the F-box wiring test page
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get fBoxWiringTestTitle;

  /// Instructions on the F-box wiring test page
  ///
  /// In en, this message translates to:
  /// **'Click the button below, if the door operates normally, press \'NEXT\'.\nIf not, change \'O/S/C wiring\' to test again.'**
  String get fBoxWiringTestDescription;

  /// PB wiring mode label
  ///
  /// In en, this message translates to:
  /// **'PB wiring'**
  String get fBoxWiringTestPbWiring;

  /// O/S/C wiring mode label
  ///
  /// In en, this message translates to:
  /// **'O/S/C wiring'**
  String get fBoxWiringTestOscWiring;

  /// F-box wiring test status label
  ///
  /// In en, this message translates to:
  /// **'door operates normally'**
  String get fBoxWiringTestDoorOperatesNormally;

  /// Accessibility label for the PB wiring test control
  ///
  /// In en, this message translates to:
  /// **'Test PB wiring'**
  String get fBoxWiringTestPbAction;

  /// Accessibility label for the O/S/C open control
  ///
  /// In en, this message translates to:
  /// **'Open door'**
  String get fBoxWiringTestOpenAction;

  /// Accessibility label for the O/S/C stop control
  ///
  /// In en, this message translates to:
  /// **'Stop door'**
  String get fBoxWiringTestStopAction;

  /// Accessibility label for the O/S/C close control
  ///
  /// In en, this message translates to:
  /// **'Close door'**
  String get fBoxWiringTestCloseAction;

  /// Shown when the F-box rejects a wiring test command
  ///
  /// In en, this message translates to:
  /// **'The command was not accepted. Try again.'**
  String get fBoxWiringTestCommandRejected;

  /// Shown when an F-box wiring test command fails
  ///
  /// In en, this message translates to:
  /// **'The test failed. Check the connection and try again.'**
  String get fBoxWiringTestCommandFailed;

  /// USB WIFI module option on the add device page
  ///
  /// In en, this message translates to:
  /// **'USB WIFI module'**
  String get addDeviceUsbWifiModule;

  /// Title of the USB Dongle installation guide
  ///
  /// In en, this message translates to:
  /// **'USB Dongle Installation'**
  String get usbDongleGuideTitle;

  /// Description of the USB Dongle installation guide
  ///
  /// In en, this message translates to:
  /// **'Follow the installation guide for the selected door type.'**
  String get usbDongleGuideDescription;

  /// First step title on the USB Dongle installation guide
  ///
  /// In en, this message translates to:
  /// **'1. Insert the USB WIFI module'**
  String get usbDongleGuideInsertTitle;

  /// First step description on the USB Dongle installation guide
  ///
  /// In en, this message translates to:
  /// **'Find the corresponding USB interface and insert the WIFI module.'**
  String get usbDongleGuideInsertDescription;

  /// Second step title on the USB Dongle installation guide
  ///
  /// In en, this message translates to:
  /// **'2. Observe the status of the indicator light'**
  String get usbDongleGuideIndicatorTitle;

  /// Second step description on the USB Dongle installation guide
  ///
  /// In en, this message translates to:
  /// **'2.1 If the USB light is off or flashing, you may search for the device directly.'**
  String get usbDongleGuideIndicatorDescription;

  /// Primary action on the USB Dongle installation guide
  ///
  /// In en, this message translates to:
  /// **'Search for Device'**
  String get usbDongleGuideSearchDeviceAction;

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

  /// Invalid Smart Opener QR code message
  ///
  /// In en, this message translates to:
  /// **'This QR code is not a valid Smart Opener device code.'**
  String get smartOpenerScannerInvalidCode;

  /// Target BLE device was not found after QR scanning
  ///
  /// In en, this message translates to:
  /// **'The device matching this QR code was not found. Please try again.'**
  String get smartOpenerScannerDeviceNotFound;

  /// Target BLE device connection failure after QR scanning
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to the device. Please try scanning again.'**
  String get smartOpenerScannerConnectionFailed;

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

  /// No description provided for @smartOpenerAddedDevicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Already Added'**
  String get smartOpenerAddedDevicesTitle;

  /// No description provided for @smartOpenerAddedDevicesDescription.
  ///
  /// In en, this message translates to:
  /// **'The following devices have been connected'**
  String get smartOpenerAddedDevicesDescription;

  /// No description provided for @smartOpenerAddedDeviceName.
  ///
  /// In en, this message translates to:
  /// **'Smart Opener'**
  String get smartOpenerAddedDeviceName;

  /// No description provided for @smartOpenerAddedDeviceIdentifier.
  ///
  /// In en, this message translates to:
  /// **'opener_B8F86211A9DC'**
  String get smartOpenerAddedDeviceIdentifier;

  /// No description provided for @smartOpenerAddedAddTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add device'**
  String get smartOpenerAddedAddTooltip;

  /// No description provided for @smartOpenerAddedDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove device'**
  String get smartOpenerAddedDeleteTooltip;

  /// Confirmation message before disconnecting an already added device
  ///
  /// In en, this message translates to:
  /// **'Are you sure to disconnect this device?'**
  String get smartOpenerAddedDisconnectConfirmMessage;

  /// Error message shown when removing an already added device fails
  ///
  /// In en, this message translates to:
  /// **'Unable to remove device. Please try again.'**
  String get smartOpenerAddedUnbindFailedMessage;

  /// No description provided for @smartOpenerAddedLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading devices…'**
  String get smartOpenerAddedLoading;

  /// No description provided for @smartOpenerAddedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No connected devices'**
  String get smartOpenerAddedEmptyTitle;

  /// No description provided for @smartOpenerAddedEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Connected devices will appear here.'**
  String get smartOpenerAddedEmptyDescription;

  /// No description provided for @smartOpenerAddedLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load connected devices.'**
  String get smartOpenerAddedLoadFailed;

  /// No description provided for @smartOpenerAddedRetryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get smartOpenerAddedRetryAction;

  /// No description provided for @smartOpenerAddedNoMore.
  ///
  /// In en, this message translates to:
  /// **'No more devices'**
  String get smartOpenerAddedNoMore;

  /// No description provided for @deviceCommandMoreTooltip.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get deviceCommandMoreTooltip;

  /// Accessibility announcement while device control data is loading
  ///
  /// In en, this message translates to:
  /// **'Loading device controls…'**
  String get deviceCommandLoading;

  /// Error shown when the device control page cannot load
  ///
  /// In en, this message translates to:
  /// **'Unable to load device controls. Please try again.'**
  String get deviceCommandLoadFailed;

  /// Retry action for loading the device control page
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get deviceCommandRetry;

  /// Door state shown while the device reports generic movement without a direction
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get deviceCommandDoorStateRunning;

  /// Door state label with the reported open percentage
  ///
  /// In en, this message translates to:
  /// **'{state} · {percent}%'**
  String deviceCommandDoorStateWithPercent(String state, int percent);

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

  /// No description provided for @smartOpenerRefreshWifiTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh Wi-Fi list'**
  String get smartOpenerRefreshWifiTooltip;

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

  /// No description provided for @smartOpenerShareNowAction.
  ///
  /// In en, this message translates to:
  /// **'Share now'**
  String get smartOpenerShareNowAction;

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

  /// No description provided for @smartOpenerRenameFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to update the name. Please try again.'**
  String get smartOpenerRenameFailed;

  /// No description provided for @smartOpenerRenameNetworkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Network unavailable. Please try again.'**
  String get smartOpenerRenameNetworkUnavailable;

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

  /// Empty state message for the choose scene page
  ///
  /// In en, this message translates to:
  /// **'No scenes available'**
  String get chooseSceneEmpty;

  /// Retry message for a failed choose scene request
  ///
  /// In en, this message translates to:
  /// **'Unable to load scenes. Tap to retry.'**
  String get chooseSceneLoadFailed;

  /// Failure message for moving a door to another scene
  ///
  /// In en, this message translates to:
  /// **'Unable to move the door. Please try again.'**
  String get chooseSceneMoveFailed;

  /// Network failure message for moving a door to another scene
  ///
  /// In en, this message translates to:
  /// **'Network unavailable. Please try again.'**
  String get chooseSceneMoveNetworkUnavailable;

  /// Message when the page has no valid door or source scene context
  ///
  /// In en, this message translates to:
  /// **'This door cannot be moved to another scene.'**
  String get chooseSceneMoveUnavailable;

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

  /// No description provided for @notificationEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notificationEmpty;

  /// No description provided for @notificationLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load notifications. Please try again.'**
  String get notificationLoadFailed;

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

  /// No description provided for @deviceSettingsAutoCloseCondition.
  ///
  /// In en, this message translates to:
  /// **'Auto close condition'**
  String get deviceSettingsAutoCloseCondition;

  /// No description provided for @deviceSettingsLoading.
  ///
  /// In en, this message translates to:
  /// **'Reading device attributes…'**
  String get deviceSettingsLoading;

  /// No description provided for @deviceSettingsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to read device attributes.'**
  String get deviceSettingsLoadFailed;

  /// No description provided for @deviceSettingsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get deviceSettingsRetry;

  /// No description provided for @deviceSettingsWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing…'**
  String get deviceSettingsWriting;

  /// No description provided for @deviceSettingsRawUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not reported'**
  String get deviceSettingsRawUnavailable;

  /// No description provided for @deviceSettingsRawValueDisplay.
  ///
  /// In en, this message translates to:
  /// **'{hexValue} ({decimalValue})'**
  String deviceSettingsRawValueDisplay(String hexValue, int decimalValue);

  /// No description provided for @deviceSettingsRawValueHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter the raw device value in decimal or hexadecimal (for example, 30 or 0x1E).'**
  String get deviceSettingsRawValueHelp;

  /// No description provided for @deviceSettingsRawValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Raw value'**
  String get deviceSettingsRawValueLabel;

  /// No description provided for @deviceSettingsRawValueInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a value from 0 to {maximum}.'**
  String deviceSettingsRawValueInvalid(int maximum);

  /// No description provided for @deviceSettingsRawValueProtocolInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a value supported by the device.'**
  String get deviceSettingsRawValueProtocolInvalid;

  /// No description provided for @deviceSettingsBluetoothConnectionRequired.
  ///
  /// In en, this message translates to:
  /// **'Connect this device by Bluetooth before changing settings.'**
  String get deviceSettingsBluetoothConnectionRequired;

  /// No description provided for @deviceSettingsRawCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get deviceSettingsRawCancel;

  /// No description provided for @deviceSettingsRawSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get deviceSettingsRawSave;

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

  /// No description provided for @deviceSettingsDoorOpenReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Door open reminder time'**
  String get deviceSettingsDoorOpenReminderTime;

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

  /// No description provided for @transmitterManagementTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get transmitterManagementTipsTitle;

  /// No description provided for @transmitterManagementSafetyTip.
  ///
  /// In en, this message translates to:
  /// **'1. For safety consideration, we suggest to manage all the transmitters through the app.'**
  String get transmitterManagementSafetyTip;

  /// No description provided for @transmitterManagementHowToTip.
  ///
  /// In en, this message translates to:
  /// **'2. How to manage the transmitters?\nJust relearning the transmitter through the app.'**
  String get transmitterManagementHowToTip;

  /// No description provided for @transmitterManagementEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit transmitter'**
  String get transmitterManagementEditAction;

  /// No description provided for @transmitterManagementDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete transmitter'**
  String get transmitterManagementDeleteAction;

  /// No description provided for @transmitterManagementAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add transmitter'**
  String get transmitterManagementAddAction;

  /// No description provided for @transmitterManagementInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Transmitter info'**
  String get transmitterManagementInfoTitle;

  /// No description provided for @transmitterManagementNameHint.
  ///
  /// In en, this message translates to:
  /// **'Input transmitter name'**
  String get transmitterManagementNameHint;

  /// No description provided for @transmitterManagementDeletePromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Prompt'**
  String get transmitterManagementDeletePromptTitle;

  /// No description provided for @transmitterManagementDeletePromptMessage.
  ///
  /// In en, this message translates to:
  /// **'Please confirm whether you want to delete the transmitter'**
  String get transmitterManagementDeletePromptMessage;

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

  /// No description provided for @deviceSettingsOpeningSpeedCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current setting: {value}% (motor setting)'**
  String deviceSettingsOpeningSpeedCurrent(int value);

  /// No description provided for @deviceSettingsPercent.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String deviceSettingsPercent(int value);

  /// No description provided for @deviceSettingsOpeningSpeedStandardGuide.
  ///
  /// In en, this message translates to:
  /// **'{value}%\n(STD)'**
  String deviceSettingsOpeningSpeedStandardGuide(int value);

  /// No description provided for @deviceSettingsForceMarginMaximumGuide.
  ///
  /// In en, this message translates to:
  /// **'+15%'**
  String get deviceSettingsForceMarginMaximumGuide;

  /// No description provided for @deviceSettingsStandardAbbreviation.
  ///
  /// In en, this message translates to:
  /// **'STD'**
  String get deviceSettingsStandardAbbreviation;

  /// No description provided for @deviceSettingsForceMarginWarning15Days.
  ///
  /// In en, this message translates to:
  /// **'1. This function is temporarily used when you can\'t operate the door due to the spring being loose or the track being blocked.\n\n2. This function is only effective for 15 days. Please contact the maintenance party as soon as possible.'**
  String get deviceSettingsForceMarginWarning15Days;

  /// No description provided for @deviceSettingsForceMarginWarning3Days.
  ///
  /// In en, this message translates to:
  /// **'This temporary setting is effective for three days only. Please contact the maintenance party as soon as possible.'**
  String get deviceSettingsForceMarginWarning3Days;

  /// No description provided for @deviceSettingsForceMarginWarning3DaysFull.
  ///
  /// In en, this message translates to:
  /// **'1. This function is temporarily used when you can\'t operate the door due to the spring being loose or the track being blocked.\n\n2. This function is only effective for three days. Please contact the maintenance party as soon as possible.'**
  String get deviceSettingsForceMarginWarning3DaysFull;

  /// No description provided for @deviceSettingsForceMarginTemporaryCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current setting: standard (motor setting)'**
  String get deviceSettingsForceMarginTemporaryCurrent;

  /// No description provided for @deviceSettingsForceMarginLevel.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String deviceSettingsForceMarginLevel(int level);

  /// No description provided for @deviceSettingsForceMarginLevelCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current setting: Level {level} (motor setting)'**
  String deviceSettingsForceMarginLevelCurrent(int level);

  /// No description provided for @transmitterLearningTitle.
  ///
  /// In en, this message translates to:
  /// **'Transmitter learning'**
  String get transmitterLearningTitle;

  /// No description provided for @transmitterLearningOnSiteTip.
  ///
  /// In en, this message translates to:
  /// **'Be sure to operate on site!'**
  String get transmitterLearningOnSiteTip;

  /// No description provided for @transmitterLearningKeepBluetoothOn.
  ///
  /// In en, this message translates to:
  /// **'Keep Bluetooth on'**
  String get transmitterLearningKeepBluetoothOn;

  /// No description provided for @transmitterLearningReadyDescription.
  ///
  /// In en, this message translates to:
  /// **'1. Make sure the distance between the mobile phone and the opener is less than 5 meters.\n\n2. The learning will end automatically if there\'s no operation within 20 seconds.'**
  String get transmitterLearningReadyDescription;

  /// No description provided for @transmitterLearningInProgress.
  ///
  /// In en, this message translates to:
  /// **'Learning...'**
  String get transmitterLearningInProgress;

  /// No description provided for @transmitterLearningInProgressDescription.
  ///
  /// In en, this message translates to:
  /// **'Click any button (the same button) continuously at least 3 times.'**
  String get transmitterLearningInProgressDescription;

  /// No description provided for @transmitterLearningFailed.
  ///
  /// In en, this message translates to:
  /// **'Transmitter Learning Failed'**
  String get transmitterLearningFailed;

  /// No description provided for @transmitterLearningSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Transmitter Learning Succeed'**
  String get transmitterLearningSucceeded;

  /// No description provided for @transmitterLearningRemoteInstruction.
  ///
  /// In en, this message translates to:
  /// **'Please use the remote control to try'**
  String get transmitterLearningRemoteInstruction;

  /// No description provided for @transmitterLearningStartAction.
  ///
  /// In en, this message translates to:
  /// **'Start Learning'**
  String get transmitterLearningStartAction;

  /// No description provided for @transmitterLearningRestartAction.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get transmitterLearningRestartAction;

  /// No description provided for @transmitterLearningCompleteAction.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get transmitterLearningCompleteAction;

  /// No description provided for @hardwareDiagnosticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Hardware diagnostics'**
  String get hardwareDiagnosticsTitle;

  /// No description provided for @hardwareDiagnosticsDetailedLogging.
  ///
  /// In en, this message translates to:
  /// **'Detailed hardware diagnostics'**
  String get hardwareDiagnosticsDetailedLogging;

  /// No description provided for @hardwareDiagnosticsFlutterLogging.
  ///
  /// In en, this message translates to:
  /// **'Flutter BLE console logging'**
  String get hardwareDiagnosticsFlutterLogging;

  /// No description provided for @hardwareDiagnosticsNativeLogging.
  ///
  /// In en, this message translates to:
  /// **'Native BLE console logging'**
  String get hardwareDiagnosticsNativeLogging;

  /// No description provided for @hardwareDiagnosticsWarning.
  ///
  /// In en, this message translates to:
  /// **'Flutter logging prints formatted Bluetooth frames in the Flutter console. Keep native logging off to avoid duplicate entries. AES keys, tokens, Wi-Fi passwords, and other credentials are never logged.'**
  String get hardwareDiagnosticsWarning;

  /// No description provided for @hardwareDiagnosticsUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update diagnostic logging. Please try again.'**
  String get hardwareDiagnosticsUpdateFailed;

  /// No description provided for @securityCenterTitle.
  ///
  /// In en, this message translates to:
  /// **'Security Center'**
  String get securityCenterTitle;

  /// No description provided for @securityCenterProtecting.
  ///
  /// In en, this message translates to:
  /// **'Protecting...'**
  String get securityCenterProtecting;

  /// No description provided for @securityCenterDownloadFullReport.
  ///
  /// In en, this message translates to:
  /// **'Download the full report'**
  String get securityCenterDownloadFullReport;

  /// No description provided for @securityCenterGeneralEvaluation.
  ///
  /// In en, this message translates to:
  /// **'General Evaluation'**
  String get securityCenterGeneralEvaluation;

  /// No description provided for @securityCenterDoorOperationStatus.
  ///
  /// In en, this message translates to:
  /// **'Door Operation Status'**
  String get securityCenterDoorOperationStatus;

  /// No description provided for @securityCenterDoorOperationRecord.
  ///
  /// In en, this message translates to:
  /// **'Door Operation Record'**
  String get securityCenterDoorOperationRecord;

  /// No description provided for @securityCenterSafetySensorsEvaluation.
  ///
  /// In en, this message translates to:
  /// **'Safety Sensors Evaluation'**
  String get securityCenterSafetySensorsEvaluation;

  /// No description provided for @securityCenterWirelessPhotoBeam.
  ///
  /// In en, this message translates to:
  /// **'Wireless Photo Beam'**
  String get securityCenterWirelessPhotoBeam;

  /// No description provided for @securityCenterWirelessELock.
  ///
  /// In en, this message translates to:
  /// **'Wireless E-lock'**
  String get securityCenterWirelessELock;

  /// No description provided for @securityCenterWirelessSensors.
  ///
  /// In en, this message translates to:
  /// **'Wireless Sensors'**
  String get securityCenterWirelessSensors;

  /// No description provided for @securityCenterWiredSensors.
  ///
  /// In en, this message translates to:
  /// **'Wired Sensors'**
  String get securityCenterWiredSensors;

  /// No description provided for @securityCenterPhotoBeam.
  ///
  /// In en, this message translates to:
  /// **'Photo beam'**
  String get securityCenterPhotoBeam;

  /// No description provided for @securityCenterELock.
  ///
  /// In en, this message translates to:
  /// **'E-lock'**
  String get securityCenterELock;

  /// No description provided for @securityCenterDoorSensor.
  ///
  /// In en, this message translates to:
  /// **'Door sensor'**
  String get securityCenterDoorSensor;

  /// No description provided for @securityCenterRadar.
  ///
  /// In en, this message translates to:
  /// **'Radar'**
  String get securityCenterRadar;

  /// No description provided for @securityCenterRemote.
  ///
  /// In en, this message translates to:
  /// **'Remote'**
  String get securityCenterRemote;

  /// No description provided for @securityCenterSafetyEdge.
  ///
  /// In en, this message translates to:
  /// **'Safety edge'**
  String get securityCenterSafetyEdge;

  /// No description provided for @securityCenterWiredPhotoBeam.
  ///
  /// In en, this message translates to:
  /// **'Wired photo beam'**
  String get securityCenterWiredPhotoBeam;

  /// No description provided for @securityCenterWiredELock.
  ///
  /// In en, this message translates to:
  /// **'Wired E-lock'**
  String get securityCenterWiredELock;

  /// No description provided for @securityCenterWifiDisconnectedMessage.
  ///
  /// In en, this message translates to:
  /// **'Security center can only be accessed when your motor is properly connected to Wi-Fi. Please check the motor status.'**
  String get securityCenterWifiDisconnectedMessage;

  /// No description provided for @securityCenterWifiDisconnectedBackAction.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get securityCenterWifiDisconnectedBackAction;

  /// No description provided for @securityReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety Report'**
  String get securityReportTitle;

  /// No description provided for @securityReportMotorName.
  ///
  /// In en, this message translates to:
  /// **'Garage door motor 01'**
  String get securityReportMotorName;

  /// No description provided for @securityReportSerialNumber.
  ///
  /// In en, this message translates to:
  /// **'Serial number: SFD123456789'**
  String get securityReportSerialNumber;

  /// No description provided for @securityReportDoorName.
  ///
  /// In en, this message translates to:
  /// **'Garage door 01'**
  String get securityReportDoorName;

  /// No description provided for @securityReportOperatedCycles.
  ///
  /// In en, this message translates to:
  /// **'Operated cycles'**
  String get securityReportOperatedCycles;

  /// No description provided for @securityReportRemainingCycles.
  ///
  /// In en, this message translates to:
  /// **'Remaining cycles'**
  String get securityReportRemainingCycles;

  /// No description provided for @securityReportMaintenanceWarning.
  ///
  /// In en, this message translates to:
  /// **'Please maintain the door as soon as possible.'**
  String get securityReportMaintenanceWarning;

  /// No description provided for @securityReportBalanceEvaluation.
  ///
  /// In en, this message translates to:
  /// **'Door balance evaluation'**
  String get securityReportBalanceEvaluation;

  /// No description provided for @securityReportBalanceNote.
  ///
  /// In en, this message translates to:
  /// **'Mark: Evaluation is limited to the door\'s latest open/close operation.'**
  String get securityReportBalanceNote;

  /// No description provided for @securityReportOpenEvaluation.
  ///
  /// In en, this message translates to:
  /// **'Open evaluation'**
  String get securityReportOpenEvaluation;

  /// No description provided for @securityReportCloseEvaluation.
  ///
  /// In en, this message translates to:
  /// **'Close evaluation'**
  String get securityReportCloseEvaluation;

  /// No description provided for @securityReportBalanceStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'--'**
  String get securityReportBalanceStatusUnavailable;

  /// No description provided for @securityReportOverload.
  ///
  /// In en, this message translates to:
  /// **'Over load'**
  String get securityReportOverload;

  /// No description provided for @securityReportOperationRecord.
  ///
  /// In en, this message translates to:
  /// **'Door operation record'**
  String get securityReportOperationRecord;

  /// No description provided for @securityReportLast24Hours.
  ///
  /// In en, this message translates to:
  /// **'Last 24 hours'**
  String get securityReportLast24Hours;

  /// No description provided for @securityReportLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get securityReportLast7Days;

  /// No description provided for @securityReportTimeCyclesAxis.
  ///
  /// In en, this message translates to:
  /// **'X: Time Y: Operation cycles'**
  String get securityReportTimeCyclesAxis;

  /// No description provided for @securityReportDateCyclesAxis.
  ///
  /// In en, this message translates to:
  /// **'X: Date Y: Operation cycles'**
  String get securityReportDateCyclesAxis;

  /// No description provided for @securityReportFrequentOperationWarning.
  ///
  /// In en, this message translates to:
  /// **'Unusually frequent operation on Monday. Please check it.'**
  String get securityReportFrequentOperationWarning;

  /// No description provided for @securityReportMotorFunctionStatus.
  ///
  /// In en, this message translates to:
  /// **'Motor function status'**
  String get securityReportMotorFunctionStatus;

  /// No description provided for @securityReportWiredSensorsDiagnosis.
  ///
  /// In en, this message translates to:
  /// **'Wired sensors diagnosis'**
  String get securityReportWiredSensorsDiagnosis;

  /// No description provided for @securityReportWirelessSensorsDiagnosis.
  ///
  /// In en, this message translates to:
  /// **'Wireless sensors diagnosis'**
  String get securityReportWirelessSensorsDiagnosis;

  /// No description provided for @securityReportNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get securityReportNormal;

  /// No description provided for @securityReportDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get securityReportDisconnect;

  /// No description provided for @safetySensorTriggered.
  ///
  /// In en, this message translates to:
  /// **'Triggered'**
  String get safetySensorTriggered;

  /// No description provided for @safetySensorReplaceBattery.
  ///
  /// In en, this message translates to:
  /// **'How to replace the battery'**
  String get safetySensorReplaceBattery;

  /// No description provided for @safetySensorLowBatterySolution.
  ///
  /// In en, this message translates to:
  /// **'Solution for low battery power'**
  String get safetySensorLowBatterySolution;

  /// No description provided for @batteryReplacementIllustration.
  ///
  /// In en, this message translates to:
  /// **'Battery replacement illustration'**
  String get batteryReplacementIllustration;

  /// No description provided for @safetySensorLowBatteryWarning.
  ///
  /// In en, this message translates to:
  /// **'Low battery power'**
  String get safetySensorLowBatteryWarning;

  /// No description provided for @safetySensorBatteryModel.
  ///
  /// In en, this message translates to:
  /// **'Battery model: {model}'**
  String safetySensorBatteryModel(String model);

  /// No description provided for @safetySensorBatteryModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Battery model: '**
  String get safetySensorBatteryModelLabel;

  /// No description provided for @safetySensorRatedVoltage.
  ///
  /// In en, this message translates to:
  /// **'Rated voltage: {voltage}'**
  String safetySensorRatedVoltage(String voltage);

  /// No description provided for @safetySensorRatedVoltageLabel.
  ///
  /// In en, this message translates to:
  /// **'Rated voltage: '**
  String get safetySensorRatedVoltageLabel;

  /// No description provided for @safetySensorLowBatteryInstruction.
  ///
  /// In en, this message translates to:
  /// **'*Low battery, please replace the battery promptly. Incorrect battery model could cause the device cannot operate'**
  String get safetySensorLowBatteryInstruction;

  /// No description provided for @safetySensorImagePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Image placeholder'**
  String get safetySensorImagePlaceholder;

  /// No description provided for @safetySensorDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Safety sensor'**
  String get safetySensorDefaultName;

  /// No description provided for @securityReportAbnormal.
  ///
  /// In en, this message translates to:
  /// **'Abnormal'**
  String get securityReportAbnormal;

  /// No description provided for @securityReportNotTriggered.
  ///
  /// In en, this message translates to:
  /// **'Not triggered'**
  String get securityReportNotTriggered;

  /// No description provided for @securityReportLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get securityReportLocked;

  /// No description provided for @securityReportBatteryEnough.
  ///
  /// In en, this message translates to:
  /// **'Battery power enough'**
  String get securityReportBatteryEnough;

  /// No description provided for @securityReportBatteryLow.
  ///
  /// In en, this message translates to:
  /// **'Battery is low'**
  String get securityReportBatteryLow;

  /// No description provided for @securityReportWirelessWicketDoor.
  ///
  /// In en, this message translates to:
  /// **'Wireless wicket door'**
  String get securityReportWirelessWicketDoor;

  /// No description provided for @securityReportWirelessSafetyEdge.
  ///
  /// In en, this message translates to:
  /// **'Wireless safety edge'**
  String get securityReportWirelessSafetyEdge;

  /// No description provided for @securityReportWirelessPositionSensor.
  ///
  /// In en, this message translates to:
  /// **'Wireless position sensor'**
  String get securityReportWirelessPositionSensor;

  /// No description provided for @securityReportSafetySuggestion.
  ///
  /// In en, this message translates to:
  /// **'Safety suggestion:'**
  String get securityReportSafetySuggestion;

  /// No description provided for @securityReportSuggestionCycles.
  ///
  /// In en, this message translates to:
  /// **'Operated cycles has reached the maintenance warning;'**
  String get securityReportSuggestionCycles;

  /// No description provided for @securityReportSuggestionBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery power of safety edge is low, replace it in time;'**
  String get securityReportSuggestionBattery;

  /// No description provided for @securityReportSuggestionMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Contact your installer for a necessary maintenance to ensure the safety of the door.'**
  String get securityReportSuggestionMaintenance;

  /// No description provided for @securityReportSuggestionCurrent.
  ///
  /// In en, this message translates to:
  /// **'The opening current of your opener exceeds the maximum value we set.'**
  String get securityReportSuggestionCurrent;

  /// No description provided for @securityReportSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get securityReportSaveAction;

  /// No description provided for @securityReportSavingAction.
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get securityReportSavingAction;

  /// No description provided for @securityReportShareAction.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get securityReportShareAction;

  /// No description provided for @securityReportSharingAction.
  ///
  /// In en, this message translates to:
  /// **'Sharing'**
  String get securityReportSharingAction;

  /// No description provided for @securityReportSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Report saved to album.'**
  String get securityReportSaveSuccess;

  /// No description provided for @securityReportSaveAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Photo library permission is required to save the report.'**
  String get securityReportSaveAccessDenied;

  /// No description provided for @securityReportSaveNoSpace.
  ///
  /// In en, this message translates to:
  /// **'Not enough storage space to save the report.'**
  String get securityReportSaveNoSpace;

  /// No description provided for @securityReportSaveUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Unable to save this image format.'**
  String get securityReportSaveUnsupported;

  /// No description provided for @securityReportSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to save report image.'**
  String get securityReportSaveFailed;

  /// No description provided for @securityReportCaptureFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to create report image.'**
  String get securityReportCaptureFailed;

  /// No description provided for @securityReportShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to share report image.'**
  String get securityReportShareFailed;

  /// No description provided for @securityReportDoorOpeningForce.
  ///
  /// In en, this message translates to:
  /// **'Door opening force'**
  String get securityReportDoorOpeningForce;

  /// No description provided for @securityReportDoorClosingForce.
  ///
  /// In en, this message translates to:
  /// **'Door closing force'**
  String get securityReportDoorClosingForce;

  /// No description provided for @securityReportAutoCloseTime.
  ///
  /// In en, this message translates to:
  /// **'Auto close time'**
  String get securityReportAutoCloseTime;

  /// No description provided for @securityReportAutoCloseCondition.
  ///
  /// In en, this message translates to:
  /// **'Auto close condition'**
  String get securityReportAutoCloseCondition;

  /// No description provided for @securityReportLedOffDelay.
  ///
  /// In en, this message translates to:
  /// **'LED off delay'**
  String get securityReportLedOffDelay;

  /// No description provided for @securityReportPartialOpen.
  ///
  /// In en, this message translates to:
  /// **'Partial open'**
  String get securityReportPartialOpen;

  /// No description provided for @securityReportIgnoreObstructionHeight.
  ///
  /// In en, this message translates to:
  /// **'Ignore obstruction height'**
  String get securityReportIgnoreObstructionHeight;

  /// No description provided for @securityReportPhotoBeamFunction.
  ///
  /// In en, this message translates to:
  /// **'Photo beam function'**
  String get securityReportPhotoBeamFunction;

  /// No description provided for @securityReportCommunityMode.
  ///
  /// In en, this message translates to:
  /// **'Community mode'**
  String get securityReportCommunityMode;

  /// No description provided for @securityReportLevel1.
  ///
  /// In en, this message translates to:
  /// **'Level1'**
  String get securityReportLevel1;

  /// No description provided for @securityReportAnyPosition.
  ///
  /// In en, this message translates to:
  /// **'Any position'**
  String get securityReportAnyPosition;

  /// No description provided for @securityReportOn.
  ///
  /// In en, this message translates to:
  /// **'ON'**
  String get securityReportOn;

  /// No description provided for @generalEvaluationLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load. Tap to retry.'**
  String get generalEvaluationLoadFailed;

  /// No description provided for @safetySensorsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load safety sensors. Tap to retry.'**
  String get safetySensorsLoadFailed;

  /// No description provided for @safetySensorsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No safety sensor data is available.'**
  String get safetySensorsEmpty;

  /// No description provided for @safetySensorsWiredStatus.
  ///
  /// In en, this message translates to:
  /// **'Wired sensor status'**
  String get safetySensorsWiredStatus;

  /// No description provided for @safetySensorsWirelessStatus.
  ///
  /// In en, this message translates to:
  /// **'Wireless Sensors Status'**
  String get safetySensorsWirelessStatus;

  /// No description provided for @safetySensorsMetricSensors.
  ///
  /// In en, this message translates to:
  /// **'Sensors'**
  String get safetySensorsMetricSensors;

  /// No description provided for @safetySensorsMetricFine.
  ///
  /// In en, this message translates to:
  /// **'Fine'**
  String get safetySensorsMetricFine;

  /// No description provided for @safetySensorsMetricAbnormal.
  ///
  /// In en, this message translates to:
  /// **'Abnormal'**
  String get safetySensorsMetricAbnormal;

  /// No description provided for @safetySensorsMetricLowPower.
  ///
  /// In en, this message translates to:
  /// **'Low power'**
  String get safetySensorsMetricLowPower;

  /// No description provided for @safetySensorsMatch.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get safetySensorsMatch;

  /// No description provided for @safetySensorsManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get safetySensorsManage;

  /// No description provided for @safetySensorPairingTitle.
  ///
  /// In en, this message translates to:
  /// **'Sensor pairing'**
  String get safetySensorPairingTitle;

  /// No description provided for @safetySensorPairingGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Sensor match'**
  String get safetySensorPairingGuideTitle;

  /// No description provided for @safetySensorPairingGuideStatus.
  ///
  /// In en, this message translates to:
  /// **'Keep Bluetooth on'**
  String get safetySensorPairingGuideStatus;

  /// No description provided for @safetySensorPairingBluetoothEnabled.
  ///
  /// In en, this message translates to:
  /// **'Keep Bluetooth enabled'**
  String get safetySensorPairingBluetoothEnabled;

  /// No description provided for @safetySensorPairingGuideDescription.
  ///
  /// In en, this message translates to:
  /// **'1.Make sure the distance between the phone and the motor is less than 5 meters.\n2.Make sure the distance between the safety sensor and the motor is less than 10 meters.\n3.If no learning operation is performed within 30 seconds, the learning will end automatically.'**
  String get safetySensorPairingGuideDescription;

  /// No description provided for @safetySensorPairingGuideAction.
  ///
  /// In en, this message translates to:
  /// **'Start Learning'**
  String get safetySensorPairingGuideAction;

  /// No description provided for @safetySensorPairingStart.
  ///
  /// In en, this message translates to:
  /// **'Start pairing'**
  String get safetySensorPairingStart;

  /// No description provided for @safetySensorPairingInProgress.
  ///
  /// In en, this message translates to:
  /// **'Learning...'**
  String get safetySensorPairingInProgress;

  /// No description provided for @safetySensorPairingMatchingDescription.
  ///
  /// In en, this message translates to:
  /// **'Press and hold the pairing button on the wireless sensor.'**
  String get safetySensorPairingMatchingDescription;

  /// No description provided for @safetySensorPairingCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get safetySensorPairingCancel;

  /// No description provided for @safetySensorPairingCancelling.
  ///
  /// In en, this message translates to:
  /// **'Cancelling pairing...'**
  String get safetySensorPairingCancelling;

  /// No description provided for @safetySensorPairingBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get safetySensorPairingBack;

  /// No description provided for @safetySensorPairingFailed.
  ///
  /// In en, this message translates to:
  /// **'Safety device pairing failed'**
  String get safetySensorPairingFailed;

  /// No description provided for @safetySensorPairingTimeout.
  ///
  /// In en, this message translates to:
  /// **'Safety device pairing timed out'**
  String get safetySensorPairingTimeout;

  /// No description provided for @safetySensorPairingFailedDescription.
  ///
  /// In en, this message translates to:
  /// **'Safety device pairing failed. Please go back.'**
  String get safetySensorPairingFailedDescription;

  /// No description provided for @safetySensorPairingTimeoutDescription.
  ///
  /// In en, this message translates to:
  /// **'Safety device pairing timed out. Please go back.'**
  String get safetySensorPairingTimeoutDescription;

  /// No description provided for @safetySensorPairingBluetoothDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth disconnected. Safety device pairing cannot continue.'**
  String get safetySensorPairingBluetoothDisconnected;

  /// No description provided for @safetySensorPairingCommunicationTimeout.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth communication timed out without a device response.'**
  String get safetySensorPairingCommunicationTimeout;

  /// No description provided for @safetySensorPairingReasonCode.
  ///
  /// In en, this message translates to:
  /// **'Fault code: {code}'**
  String safetySensorPairingReasonCode(String code);

  /// No description provided for @safetySensorPairingSuccess.
  ///
  /// In en, this message translates to:
  /// **'Wireless safety sensor learning successful'**
  String get safetySensorPairingSuccess;

  /// No description provided for @safetySensorPairingLearningFailed.
  ///
  /// In en, this message translates to:
  /// **'Wireless safety sensor learning failed'**
  String get safetySensorPairingLearningFailed;

  /// No description provided for @safetySensorPairingComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get safetySensorPairingComplete;

  /// No description provided for @safetySensorPairingImagePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Pairing illustration placeholder'**
  String get safetySensorPairingImagePlaceholder;

  /// No description provided for @safetySensorManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Sensor management'**
  String get safetySensorManagementTitle;

  /// No description provided for @safetySensorManagementEmpty.
  ///
  /// In en, this message translates to:
  /// **'No wireless sensors to manage.'**
  String get safetySensorManagementEmpty;

  /// No description provided for @safetySensorManagementDeleteLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete sensor'**
  String get safetySensorManagementDeleteLabel;

  /// No description provided for @safetySensorManagementDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete {sensorName}? The device will no longer be available and all settings will be cleared. Are you sure?'**
  String safetySensorManagementDeleteMessage(String sensorName);

  /// No description provided for @safetySensorManagementCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get safetySensorManagementCancel;

  /// No description provided for @safetySensorManagementConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get safetySensorManagementConfirm;

  /// No description provided for @safetySensorManagementDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Safety sensor deleted.'**
  String get safetySensorManagementDeleteSuccess;

  /// No description provided for @safetySensorManagementDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to delete the safety sensor. Please try again.'**
  String get safetySensorManagementDeleteFailed;

  /// No description provided for @safetySensorManagementBluetoothDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Connect the current device via Bluetooth first.'**
  String get safetySensorManagementBluetoothDisconnected;

  /// No description provided for @safetySensorManagementWirelessDoorSensor.
  ///
  /// In en, this message translates to:
  /// **'Wireless door sensor'**
  String get safetySensorManagementWirelessDoorSensor;

  /// No description provided for @safetySensorManagementUnknownType.
  ///
  /// In en, this message translates to:
  /// **'Unknown safety sensor'**
  String get safetySensorManagementUnknownType;

  /// No description provided for @safetySensorsWirelessWicketDoor.
  ///
  /// In en, this message translates to:
  /// **'Wireless wicket door'**
  String get safetySensorsWirelessWicketDoor;

  /// No description provided for @safetySensorsWirelessSafetyEdge.
  ///
  /// In en, this message translates to:
  /// **'Wireless safety edge'**
  String get safetySensorsWirelessSafetyEdge;

  /// No description provided for @safetySensorsWirelessSlackRope.
  ///
  /// In en, this message translates to:
  /// **'Wireless slack rope'**
  String get safetySensorsWirelessSlackRope;

  /// No description provided for @safetySensorUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get safetySensorUnlocked;

  /// No description provided for @safetySensorLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get safetySensorLocked;

  /// No description provided for @safetySensorNotTriggered.
  ///
  /// In en, this message translates to:
  /// **'Not triggered'**
  String get safetySensorNotTriggered;

  /// No description provided for @safetySensorOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get safetySensorOffline;

  /// No description provided for @deviceCommandFallbackDoorName.
  ///
  /// In en, this message translates to:
  /// **'Garage door'**
  String get deviceCommandFallbackDoorName;

  /// No description provided for @deviceCommandOperatedCycles.
  ///
  /// In en, this message translates to:
  /// **'Operated cycles'**
  String get deviceCommandOperatedCycles;

  /// No description provided for @deviceCommandRemainingCycles.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get deviceCommandRemainingCycles;

  /// No description provided for @deviceCommandVideoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get deviceCommandVideoTooltip;

  /// No description provided for @deviceCommandCloseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get deviceCommandCloseTooltip;

  /// No description provided for @deviceCommandStopTooltip.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get deviceCommandStopTooltip;

  /// No description provided for @deviceCommandOpenTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get deviceCommandOpenTooltip;

  /// No description provided for @deviceCommandAutoCloseTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto close'**
  String get deviceCommandAutoCloseTitle;

  /// No description provided for @deviceCommandOpenReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Open reminder'**
  String get deviceCommandOpenReminderTitle;

  /// No description provided for @deviceCommandMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String deviceCommandMinutes(int minutes);

  /// No description provided for @deviceCommandLedTitle.
  ///
  /// In en, this message translates to:
  /// **'LED'**
  String get deviceCommandLedTitle;

  /// No description provided for @deviceCommandCentimeters.
  ///
  /// In en, this message translates to:
  /// **'{value} cm'**
  String deviceCommandCentimeters(int value);

  /// No description provided for @deviceCommandPartialOpenTitle.
  ///
  /// In en, this message translates to:
  /// **'Partial open'**
  String get deviceCommandPartialOpenTitle;

  /// No description provided for @deviceCommandPartialOpenSettingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Partial-open positions are temporarily unavailable. Please try again.'**
  String get deviceCommandPartialOpenSettingUnavailable;

  /// No description provided for @deviceCommandPartialOpenSettingFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to save the partial-open position. Please try again.'**
  String get deviceCommandPartialOpenSettingFailed;

  /// No description provided for @deviceCommandMoreSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'More settings'**
  String get deviceCommandMoreSettingsTitle;

  /// No description provided for @deviceCommandControlMethod.
  ///
  /// In en, this message translates to:
  /// **'Control method'**
  String get deviceCommandControlMethod;

  /// No description provided for @deviceCommandActionOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get deviceCommandActionOpen;

  /// No description provided for @deviceCommandActionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get deviceCommandActionClose;

  /// No description provided for @deviceCommandActionStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get deviceCommandActionStop;

  /// No description provided for @deviceCommandActionPartialOpen.
  ///
  /// In en, this message translates to:
  /// **'Partial open'**
  String get deviceCommandActionPartialOpen;

  /// No description provided for @deviceCommandActionLedOn.
  ///
  /// In en, this message translates to:
  /// **'Turn LED on'**
  String get deviceCommandActionLedOn;

  /// No description provided for @deviceCommandActionLedOff.
  ///
  /// In en, this message translates to:
  /// **'Turn LED off'**
  String get deviceCommandActionLedOff;

  /// No description provided for @deviceCommandActionPb.
  ///
  /// In en, this message translates to:
  /// **'PB'**
  String get deviceCommandActionPb;

  /// No description provided for @deviceCommandSending.
  ///
  /// In en, this message translates to:
  /// **'Sending {action} command ({controlCode})...'**
  String deviceCommandSending(String action, String controlCode);

  /// No description provided for @deviceCommandSucceeded.
  ///
  /// In en, this message translates to:
  /// **'{action} command sent ({controlCode}).'**
  String deviceCommandSucceeded(String action, String controlCode);

  /// No description provided for @deviceCommandRejected.
  ///
  /// In en, this message translates to:
  /// **'{action} command was rejected ({controlCode}).'**
  String deviceCommandRejected(String action, String controlCode);

  /// No description provided for @deviceCommandBluetoothRequired.
  ///
  /// In en, this message translates to:
  /// **'Connect the selected device via Bluetooth to use {action}.'**
  String deviceCommandBluetoothRequired(String action);

  /// No description provided for @deviceCommandRemoteFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to complete {action}. Please try again.'**
  String deviceCommandRemoteFailed(String action);

  /// No description provided for @deviceCommandRemoteUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'The device acknowledged {action}, but the actual door movement could not be confirmed.'**
  String deviceCommandRemoteUnconfirmed(String action);

  /// No description provided for @deviceCommandRemoteTimeout.
  ///
  /// In en, this message translates to:
  /// **'{action} timed out. Check the door state and try again.'**
  String deviceCommandRemoteTimeout(String action);

  /// Shown when onboarding finds that the current user already owns the device
  ///
  /// In en, this message translates to:
  /// **'This device is already bound to your account.'**
  String get smartOpenerAlreadyBoundToCurrentUser;

  /// Shown when onboarding finds that another user owns the device
  ///
  /// In en, this message translates to:
  /// **'This device is already bound to another user.'**
  String get smartOpenerAlreadyBoundToAnotherUser;

  /// No description provided for @deviceCommandNetworkFailure.
  ///
  /// In en, this message translates to:
  /// **'Unable to send {action}. Check your network and try again.'**
  String deviceCommandNetworkFailure(String action);
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
