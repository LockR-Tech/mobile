// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonLogout => 'Log out';

  @override
  String get commonLoggingOut => 'Logging out...';

  @override
  String get commonLoggedOut => 'Logged out';

  @override
  String get commonLogoutConfirm =>
      'Are you sure you want to log out of your account?';

  @override
  String get commonNotifications => 'Notifications';

  @override
  String get commonTransactions => 'Transactions';

  @override
  String get commonPayment => 'Payment';

  @override
  String get commonWebsite => 'Website';

  @override
  String get commonTermsOfUse => 'Terms of use';

  @override
  String get commonPrivacyPolicy => 'Privacy policy';

  @override
  String get languageVietnamese => 'Tiếng Việt';

  @override
  String get languageEnglish => 'English';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileSubtitle => 'Manage your account';

  @override
  String get profileLoading => 'Loading profile...';

  @override
  String get profileLoadFailed => 'Couldn\'t load your profile';

  @override
  String get profileLoadFailedDot => 'Couldn\'t load your profile.';

  @override
  String profileRefreshFailed(Object error) {
    return 'Couldn\'t refresh your profile: $error';
  }

  @override
  String get profileSectionAccount => 'Account';

  @override
  String get profilePersonalInfo => 'Personal information';

  @override
  String get profileRefundAccount => 'Refund bank account';

  @override
  String get profileLoyalty => 'Reward points';

  @override
  String get profileLoyaltySubtitle => 'Points, membership tier and history';

  @override
  String get profileFaceReRegister => 'Re-register face';

  @override
  String get profileFaceRegister => 'Register face';

  @override
  String get profileSecurity => 'Security';

  @override
  String get profileVouchers => 'Offers & gifts';

  @override
  String get profileSectionManage => 'Manage';

  @override
  String get profileDelegations => 'Delegated orders';

  @override
  String get profileRefunds => 'Refunds';

  @override
  String get profileMyReports => 'My reports';

  @override
  String get profileBleTest => 'Test opening a compartment via Bluetooth';

  @override
  String get profileSectionSettings => 'Settings';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileLanguageSheetSubtitle =>
      'Choose the display language for the app';

  @override
  String get profileLanguageViDescription => 'Display in Vietnamese';

  @override
  String get profileLanguageEnDescription => 'Display in English';

  @override
  String get profileTheme => 'Appearance';

  @override
  String get profileLocation => 'Location';

  @override
  String get profileLocationSubtitle =>
      'Location access to find lockers near you';

  @override
  String get profileSectionSupport => 'Support';

  @override
  String get profileAssistant => 'Lock.R AI assistant';

  @override
  String get profileAssistantSubtitle => 'Smart Q&A and support 24/7';

  @override
  String get profileQuickHelp => 'Quick help';

  @override
  String get profileQuickHelpSubtitle => 'How-to guides & FAQ';

  @override
  String get profileContact => 'Contact';

  @override
  String get profileTerms => 'Terms';

  @override
  String get profileHelpSendTitle => 'Send a parcel';

  @override
  String get profileHelpSendBody =>
      'Choose a store → tap an empty compartment → Send parcel → pay → use the PIN or the \"Open locker\" button to drop off the parcel.';

  @override
  String get profileHelpRentTitle => 'Rent a storage locker';

  @override
  String get profileHelpRentBody =>
      'Choose an empty compartment → Rent locker → choose the hours → pay → the PIN works as many times as you need until it expires.';

  @override
  String get profileHelpCantOpenTitle => 'Compartment won\'t open?';

  @override
  String get profileHelpCantOpenBody =>
      'Go to Locker orders → open the order → \"Report faulty compartment\". The maintenance team will handle it and you will be notified.';

  @override
  String get profileHelpPaymentBody =>
      'All orders are paid by SePay bank transfer (VietQR): scan the code or tap \"Pay with banking app\" to open your banking app with the details filled in. Review past payments under Transactions.';

  @override
  String get profileContactTitle => 'Contact support';

  @override
  String get profileContactEmail => 'Support email';

  @override
  String get profileContactHours => 'Support hours';

  @override
  String get profileContactHoursValue => '08:00 – 22:00 daily';

  @override
  String get profileThemeSheetSubtitle => 'Choose the app\'s color theme';

  @override
  String get profileThemeLight => 'Light';

  @override
  String get profileThemeLightDescription => 'White background';

  @override
  String get profileThemeDark => 'Dark';

  @override
  String get profileThemeDarkDescription => 'Dark background';

  @override
  String get profileThemeSystem => 'System default';

  @override
  String get profileThemeSystemDescription => 'Follows your device settings';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonSave => 'Save';

  @override
  String get commonLater => 'Later';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonFullName => 'Full name';

  @override
  String get commonFullNameHint => 'John Smith';

  @override
  String get commonEmail => 'Email';

  @override
  String get commonPhoneNumber => 'Phone number';

  @override
  String get commonPassword => 'Password';

  @override
  String get commonPhoneShort => 'Phone';

  @override
  String get authLogin => 'Log in';

  @override
  String get authRegister => 'Sign up';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authRegisterSuccess => 'Signed up successfully!';

  @override
  String get authRegisterSuccessPleaseLogin =>
      'Signed up successfully! Please log in.';

  @override
  String get authEnterIdentifierAndPassword =>
      'Enter your email/phone and password';

  @override
  String get authPleaseAcceptTerms => 'Please accept the Terms of use';

  @override
  String get authTagline => 'Smart lockers • 24/7 pick-up & drop-off';

  @override
  String get authEmailOrPhone => 'Email / Phone number';

  @override
  String get authLoginWithOtp => 'Log in with OTP';

  @override
  String get authForgotPasswordQuestion => 'Forgot password?';

  @override
  String get authEnterFullName => 'Please enter your full name';

  @override
  String get authEnterEmail => 'Please enter your email';

  @override
  String get authInvalidEmail => 'Invalid email';

  @override
  String get authEnterPhone => 'Please enter your phone number';

  @override
  String get authEnterPassword => 'Please enter your password';

  @override
  String get authPasswordMin6 => 'Password must be at least 6 characters';

  @override
  String get authAgreePrefix => 'I agree to the ';

  @override
  String get authOrContinueWith => 'Or continue with';

  @override
  String get authNoAccount => 'Don\'t have an account? ';

  @override
  String get authHaveAccount => 'Already have an account? ';

  @override
  String get authRegisterNow => 'Sign up now';

  @override
  String get authEnterValidEmailForOtp =>
      'Please enter a valid email to receive the OTP';

  @override
  String get authEnterOtp => 'Enter OTP code';

  @override
  String authOtpSentTo(Object email) {
    return 'The OTP code has been sent to $email';
  }

  @override
  String authOtpSendingTo(Object email) {
    return 'Sending the OTP code to $email...';
  }

  @override
  String get authOtp6Digits => 'OTP code (6 digits)';

  @override
  String get authPasswordHint => 'Enter password';

  @override
  String get authFaceLogin => 'Face login';

  @override
  String get authRegisterFailedRetry => 'Sign-up failed. Please try again.';

  @override
  String get authFaceMismatch =>
      'Face doesn\'t match or hasn\'t been registered';

  @override
  String get authFaceAiBusy => 'The AI system is busy or the photo is invalid';

  @override
  String get authLoginFailedRetry => 'Login failed. Please try again.';

  @override
  String get authNoTokenFromServer =>
      'No authentication token was received from the server.';

  @override
  String get authFaceRegisterFailed => 'Face registration failed';

  @override
  String get authEmailNotRegistered =>
      'This email isn\'t registered. Please check it again.';

  @override
  String get authOtpInvalidOrExpired =>
      'The OTP code is invalid or has expired.';

  @override
  String get authPasswordsDontMatch => 'The passwords don\'t match.';

  @override
  String get authResetPasswordFailed =>
      'Couldn\'t reset the password. Please try again.';

  @override
  String get authEmailTaken =>
      'This email is already registered. Please use another email.';

  @override
  String get authPhoneTaken =>
      'This phone number is already registered. Please use another number.';

  @override
  String get authEmailOrPhoneTaken =>
      'The email or phone number is already registered.';

  @override
  String get authRegisterServerError =>
      'Server error while signing up. Please try again.';

  @override
  String get authOtpServerTokenError =>
      'The OTP code is correct but the authentication system had an internal error (no token returned). Please try again in a few minutes.';

  @override
  String get authOtpVerifyFailed =>
      'Couldn\'t verify the OTP. Please try again.';

  @override
  String get authResetPasswordSuccess =>
      'Password reset successfully. Please log in with your new password.';

  @override
  String get authEnterValidEmail => 'Please enter a valid email.';

  @override
  String get authOtpMustBe6Digits => 'The OTP code has 6 digits.';

  @override
  String get authNewPasswordMin6 =>
      'The new password must be at least 6 characters.';

  @override
  String get authForgotPasswordTitle => 'Forgot password';

  @override
  String get authEnterOtpAndNewPassword => 'Enter the OTP code & new password';

  @override
  String get authResetPassword => 'Reset password';

  @override
  String authResetOtpSentTo(Object email) {
    return 'A 6-digit OTP code has been sent to\n$email (expires in 5 minutes).';
  }

  @override
  String get authResetEnterEmail =>
      'Enter the email registered with your account.\nWe\'ll send an OTP code to reset your password.';

  @override
  String get authSendOtp => 'Send OTP code';

  @override
  String get authResendOtp => 'Resend OTP code';

  @override
  String get authOtpCode => 'OTP code';

  @override
  String get authNewPassword => 'New password';

  @override
  String get authConfirmNewPassword => 'Confirm new password';

  @override
  String get authPhoneLogin => 'Log in with phone number';

  @override
  String authSmsSentTo(Object phone) {
    return 'A 6-digit code has been sent by SMS to $phone.';
  }

  @override
  String get authYourNumber => 'your number';

  @override
  String get authPhoneAutoCreateAccount =>
      'No account yet? One is created automatically when you confirm the code.';

  @override
  String get authPhoneFormatHint =>
      'You can enter a local (0xxx) or international (+84xxx) number.';

  @override
  String get authChangePhone => 'Change phone number';

  @override
  String authResendCodeIn(Object seconds) {
    return 'Resend code (${seconds}s)';
  }

  @override
  String get authResendCode => 'Resend code';

  @override
  String get authProfileSaved => 'Account details saved';

  @override
  String get authProfileSaveFailed =>
      'Couldn\'t save your details. Please try again.';

  @override
  String get authCompleteRegistration => 'Complete sign-up';

  @override
  String get authCompleteRegistrationBody =>
      'Tell us your name so it can be shown on your orders and when you contact support.';

  @override
  String get authEmailOptional => 'Email (optional)';

  @override
  String get authBiometricReason => 'Authenticate to open Lock.R';

  @override
  String get authSplashTagline => '24/7 smart locker system';

  @override
  String get authBiometricRequired =>
      'Biometric authentication is required to continue';

  @override
  String get authBiometricButton => 'Authenticate with fingerprint / Face ID';

  @override
  String get authLogoutUsePassword => 'Log out and use password';

  @override
  String get authGoogleLoginFailed => 'Google login failed';

  @override
  String get authFacebookLoginFailed => 'Facebook login failed';

  @override
  String get authOtp6DigitsShort => 'The OTP code has 6 digits';

  @override
  String get authOtpConfirmFailed =>
      'Couldn\'t confirm the OTP code. Please try again.';

  @override
  String get authOtpVerification => 'OTP verification';

  @override
  String get authCaptureFaceFirst => 'Please capture a face sample first';

  @override
  String get authPhoneLoginDisabled =>
      'Phone login isn\'t enabled. Please log in with your email.';

  @override
  String get authOtpSendFailed =>
      'Couldn\'t send the OTP code. Please try again.';

  @override
  String get authInvalidPhone =>
      'Invalid phone number. Please check it again (e.g. 0912345678).';

  @override
  String get authTooManyRequests =>
      'You\'ve requested a code too many times. Please try again in a few minutes.';

  @override
  String get authSmsQuotaExceeded =>
      'The system has run out of SMS messages for today. Please try again later or log in with your email.';

  @override
  String get authOtpWrong => 'Incorrect OTP code. Please check it again.';

  @override
  String get authEnterOtpCode => 'Please enter the OTP code.';

  @override
  String get authOtpExpired =>
      'The OTP code has expired. Please tap \"Resend code\".';

  @override
  String get authAppNotVerified =>
      'The app isn\'t verified to send OTP codes. Please update the app or log in with your email.';

  @override
  String get authRecaptchaFailed =>
      'reCAPTCHA verification failed. Please try again.';

  @override
  String get authSitePhoneNotAllowed =>
      'This website isn\'t allowed to log in by phone. Please log in with your email.';

  @override
  String get authNoNetwork =>
      'No network connection. Please check your Internet and try again.';

  @override
  String get authAccountDisabled =>
      'This account has been locked. Please contact support.';

  @override
  String get authVerificationCancelled =>
      'Verification was cancelled. Please try again.';

  @override
  String get authGooglePopupBlocked =>
      'The browser blocked the Google sign-in window. Allow pop-ups and try again.';

  @override
  String get authGoogleLoginDisabled =>
      'Google login isn\'t enabled. Please log in with your email.';

  @override
  String get authSiteGoogleNotAllowed =>
      'This website isn\'t allowed to log in with Google. Please log in with your email.';

  @override
  String get authGoogleEmailOtherProvider =>
      'This Google email is linked to a different login method. Please log in the way you did before.';

  @override
  String get authSessionVerifyFailed =>
      'Couldn\'t verify your login session. Please try again.';
}
