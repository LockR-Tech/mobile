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

  @override
  String get commonCancelAlt => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonDone => 'Done';

  @override
  String get commonGotIt => 'Got it';

  @override
  String get commonOpenSettings => 'Open Settings';

  @override
  String get commonSearchHint => 'Search...';

  @override
  String get commonSeeAll => 'SEE ALL';

  @override
  String get commonLoginRequiredFeature =>
      'You need to log in to use this feature';

  @override
  String get commonLoginTitleCase => 'Log In';

  @override
  String get commonRegisterTitleCase => 'Sign Up';

  @override
  String get commonBrandEyebrow => 'LOCK.R • SMART LOCKER SYSTEM';

  @override
  String get commonUnknown => 'Unknown';

  @override
  String get commonUndetermined => 'Undetermined';

  @override
  String get commonError => 'Error';

  @override
  String get commonSuccess => 'Successful';

  @override
  String get commonFailed => 'Failed';

  @override
  String get commonPending => 'Pending';

  @override
  String deadlineAt(Object time, Object date) {
    return '$time on $date';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navLockers => 'Lockers';

  @override
  String get navAssistant => 'AI assistant';

  @override
  String get navOrders => 'Orders';

  @override
  String get navProfile => 'Profile';

  @override
  String get routerPolicy => 'Policy';

  @override
  String get routerMissingDestination => 'Destination coordinates are missing.';

  @override
  String get routerDestination => 'Destination';

  @override
  String get backPressAgainToExit => 'Press back again to exit';

  @override
  String get paymentMethodUnsupported =>
      'This payment method is no longer supported. Please pay by SePay bank transfer (VietQR).';

  @override
  String get qrExpired => 'The QR code or session has expired.';

  @override
  String get qrAlreadyUsed => 'The QR code has already been used.';

  @override
  String get errorTimeout => 'Connection timed out. Please try again.';

  @override
  String get errorCannotConnect =>
      'Can\'t connect to the server. Check your network connection.';

  @override
  String get errorRequestCancelled => 'The request was cancelled.';

  @override
  String get errorUnknown => 'An unknown error occurred.';

  @override
  String get errorNoResponse => 'No response from the server.';

  @override
  String get errorSessionExpired =>
      'Your session has expired. Please log in again.';

  @override
  String get errorForbidden => 'You don\'t have permission to do this.';

  @override
  String get errorSystemBusy =>
      'The system is busy or under maintenance. Please try again in a few minutes.';

  @override
  String get errorServer => 'Server error. Please try again later.';

  @override
  String get errorNotSupportedYet =>
      'The server doesn\'t support this feature yet. Please try again later.';

  @override
  String get errorGenericRetry => 'Something went wrong. Please try again.';

  @override
  String bleOpenedBox(Object box) {
    return 'Opened compartment $box';
  }

  @override
  String get bleNotFound =>
      'Locker not found via Bluetooth. Stand close to the locker (within 2 m) and try again.';

  @override
  String get bleConnectFailed =>
      'Couldn\'t connect to the locker via Bluetooth. Try again in a few seconds.';

  @override
  String get bleNoService =>
      'The locker hasn\'t enabled Bluetooth opening (the controller needs an update).';

  @override
  String get bleTimeout =>
      'The locker didn\'t respond. Check whether the compartment opened, then try again.';

  @override
  String get bleOff => 'Your phone\'s Bluetooth is off.';

  @override
  String get blePermissionDenied =>
      'The app doesn\'t have Bluetooth permission.';

  @override
  String get bleUnsupported =>
      'This device doesn\'t support Bluetooth (only available in the Android/iOS app).';

  @override
  String get bleBadCode => 'The locker rejected the opening code.';

  @override
  String get bleExpired =>
      'The opening code has expired. Tap open again to get a new code.';

  @override
  String get bleReplayed =>
      'This code has already been used. Tap open again to get a new code.';

  @override
  String get bleWrongLocker => 'You\'re connected to the wrong locker.';

  @override
  String get bleNoKey =>
      'The locker hasn\'t downloaded its verification key from the server yet (it needs to be online once).';

  @override
  String get bleNotConfigured =>
      'The locker isn\'t registered in the system yet.';

  @override
  String get bleInvalidSlot =>
      'This compartment has no electric lock connected to the controller.';

  @override
  String bleOpenFailed(Object suffix) {
    return 'Couldn\'t open the compartment$suffix.';
  }

  @override
  String bleVeryClose(Object distance) {
    return 'Very close (~${distance}m)';
  }

  @override
  String bleNear(Object distance) {
    return 'Near the locker (~${distance}m)';
  }

  @override
  String bleAway(Object distance) {
    return '~${distance}m from the locker';
  }

  @override
  String get notifEnableTitle => 'Turn on notifications';

  @override
  String get notifEnableBody =>
      'Notifications are turned off, so you won\'t receive delivery status updates. Go to Settings to turn notifications back on for the app.';

  @override
  String get notifNew => 'New notification';

  @override
  String get biometricOpenApp => 'Authenticate to open the app';

  @override
  String get enumLockerToLocker => 'Locker-to-locker delivery';

  @override
  String get enumHomeToLocker => 'Home-to-locker delivery';

  @override
  String get enumPendingProcessing => 'Pending';

  @override
  String get enumAwaitingCourier => 'Awaiting courier';

  @override
  String get enumAwaitingPickup => 'Awaiting pickup';

  @override
  String get enumActive => 'Active';

  @override
  String get enumCompleted => 'Completed';

  @override
  String get enumLockedByBalance => 'Locked due to balance';

  @override
  String get enumCancelled => 'Cancelled';

  @override
  String get enumPending => 'Pending';

  @override
  String get enumAwaitingDropoffConfirm => 'Awaiting drop-off confirmation';

  @override
  String get enumInTransit => 'In transit';

  @override
  String get enumInUse => 'In use';

  @override
  String get enumOverdue => 'Overdue';

  @override
  String get enumConsolidating => 'Consolidating';

  @override
  String get enumPickedUp => 'Picked up';

  @override
  String get enumAwaitingDropoff => 'Awaiting drop-off';

  @override
  String get enumAwaitingPayment => 'Awaiting payment';

  @override
  String get enumUnpaid => 'Unpaid';

  @override
  String get enumPaid => 'Paid';

  @override
  String get enumPartiallyPaid => 'Partially paid';

  @override
  String get enumAwaitingRefund => 'Awaiting refund';

  @override
  String get enumRefunded => 'Refunded';

  @override
  String get enumTopUp => 'Top-up';

  @override
  String get enumRentalFee => 'Locker rental fee';

  @override
  String get enumShippingFee => 'Shipping fee';

  @override
  String get enumOverdueFee => 'Overdue fee';

  @override
  String get enumRefund => 'Refund';

  @override
  String get enumWalletTopUp => 'Wallet top-up';

  @override
  String get enumWithdraw => 'Withdrawal';

  @override
  String get enumShippingService => 'Shipping service';

  @override
  String get enumPersonalRental => 'Personal locker rental';

  @override
  String get enumReady => 'Available';

  @override
  String get enumReserved => 'Reserved';

  @override
  String get enumLockedBalanceShort => 'Locked (balance)';

  @override
  String get enumFaulty => 'Faulty';

  @override
  String get enumPendingCheck => 'Pending check';

  @override
  String get enumMaintenance => 'Maintenance';

  @override
  String get enumInitializing => 'Initializing';

  @override
  String get enumLocked => 'Locked';

  @override
  String get enumUnlocked => 'Unlocked';

  @override
  String get enumOpen => 'Open';

  @override
  String get enumClosed => 'Closed';

  @override
  String get enumOpening => 'Opening...';

  @override
  String get enumClosing => 'Closing...';

  @override
  String get enumOffline => 'Offline';

  @override
  String get enumFood => 'Food';

  @override
  String get enumOther => 'Other';

  @override
  String get unitMinute => 'minute';

  @override
  String get unitHour => 'hour';

  @override
  String get unitDay => 'day';

  @override
  String get unitWeek => 'week';

  @override
  String get unitMonth => 'month';

  @override
  String minutesShort(Object minutes) {
    return '$minutes min';
  }

  @override
  String get qrSendingOpen => 'Sending the open command...';

  @override
  String get qrOpenedTest => 'Compartment opened (locker test)';

  @override
  String get qrNotOpened => 'Couldn\'t open the compartment';

  @override
  String qrLockerBox(Object locker, Object box) {
    return 'Locker #$locker · compartment #$box';
  }

  @override
  String get qrNotLockrCode =>
      'This isn\'t a Lock.R kiosk login or compartment code. Scan the QR code shown on the locker screen.';

  @override
  String get qrConfirmingKiosk => 'Confirming kiosk login...';

  @override
  String qrAtLocker(Object name) {
    return ' at $name';
  }

  @override
  String qrKioskLoggedIn(Object where) {
    return 'Logged in on the kiosk$where';
  }

  @override
  String get qrKioskLoginFailedTitle => 'Couldn\'t log in on the kiosk';

  @override
  String get qrKioskLoginFailed =>
      'Couldn\'t confirm the kiosk login. Please try again.';

  @override
  String get qrScan => 'Scan QR code';

  @override
  String get qrLoginToScan => 'You need to log in to scan QR codes';

  @override
  String get qrKioskLoginByQr => 'Kiosk login by QR';

  @override
  String get qrAimHint =>
      'Point the frame at the QR code on the kiosk screen. You\'ll be asked to confirm before logging in.';

  @override
  String get qrEnterManually => 'Enter code manually';

  @override
  String get qrCameraPermission =>
      'The app doesn\'t have camera permission. Grant it in your device settings or enter the code manually.';

  @override
  String get qrCameraUnsupported =>
      'This device can\'t scan codes with the camera. Please enter the code manually.';

  @override
  String get qrCameraFailed =>
      'Couldn\'t open the camera. Try again or enter the code manually.';

  @override
  String get qrKioskLoginQuestion => 'Log in on the kiosk?';

  @override
  String get qrKioskLoginBody =>
      'Your Lock.R account will be logged in on the kiosk showing this code. Only confirm if you\'re standing in front of that kiosk.';

  @override
  String get qrKioskConfirmCode => 'Confirmation code on the kiosk';

  @override
  String get qrKioskLogin => 'Log in on kiosk';

  @override
  String get qrWrongCode =>
      'Incorrect code. Check the session code and confirmation code shown on the kiosk.';

  @override
  String get qrEnterKioskCode => 'Enter kiosk login code';

  @override
  String get qrEnterKioskCodeHint =>
      'Enter the session code and confirmation code shown below the QR code on the kiosk screen.';

  @override
  String get qrSessionCode => 'Session code';

  @override
  String get qrConfirmCode => 'Confirmation code';

  @override
  String get mapNoLocation =>
      'Couldn\'t get your location — showing the locker only.';

  @override
  String get mapCantOpenMaps => 'Couldn\'t open the maps app.';

  @override
  String get mapFindingRoute => 'Finding a route...';

  @override
  String mapRemaining(Object distance) {
    return '$distance left';
  }

  @override
  String get mapStopNavigation => 'Stop navigation';

  @override
  String get mapStartNavigation => 'Start navigation';

  @override
  String get mapGetMyLocation => 'Get your location';

  @override
  String get mapOpenGoogleMaps => 'Open in Google Maps';

  @override
  String get mediaBadResponse =>
      'The image server returned invalid data, please try again';

  @override
  String get mediaUploadCancelled => 'Image upload cancelled';

  @override
  String get mediaCannotConnect =>
      'Couldn\'t reach the server, check your network and try again';

  @override
  String get mediaPurposeForbidden =>
      'You don\'t have permission to upload this type of image';

  @override
  String get mediaNoUploadPermission =>
      'Couldn\'t get upload permission, please try again';

  @override
  String get mediaUploadNetwork =>
      'Couldn\'t upload the image, check your network and try again';

  @override
  String get mediaSessionExpired =>
      'The upload session has expired, please try again';

  @override
  String get mediaTooLarge => 'The image is too large, please choose another';

  @override
  String get mediaFormatUnsupported =>
      'Unsupported image format (use JPG, PNG, WEBP, HEIC)';

  @override
  String get mediaServerOverloaded =>
      'The image server is overloaded, please try again in a few minutes';

  @override
  String get mediaUploadFailedRetry => 'Image upload failed, please try again';

  @override
  String get mediaStorageDisabled =>
      'Image storage is temporarily disabled. Please submit without photos or try again later.';

  @override
  String get mediaPurposeInvalid => 'Invalid image type';

  @override
  String get mediaSignatureInvalid =>
      'The uploaded image is invalid, please take it again';

  @override
  String get mediaOwnerMismatch =>
      'The image doesn\'t belong to your account, please upload again';

  @override
  String get mediaAttachmentLimit =>
      'The ticket has reached the maximum number of photos';

  @override
  String get mediaAttachmentStageInvalid =>
      'Invalid photo type for this ticket';

  @override
  String get mediaReportNotInProgress => 'The ticket isn\'t in progress';

  @override
  String get mediaReportResolved =>
      'The ticket is resolved, photos can\'t be added';

  @override
  String get mediaReportNotAssigned =>
      'You aren\'t the technician assigned to this ticket';

  @override
  String get mediaReportNotOwned => 'You didn\'t submit this ticket';

  @override
  String get mediaDeleteForbidden =>
      'You don\'t have permission to delete this photo';

  @override
  String get mediaResolutionPhotoRequired =>
      'At least 1 acceptance photo is needed before resolving the ticket';

  @override
  String get mediaAlreadyAttached =>
      'This photo is already attached to the ticket';

  @override
  String mediaTooLargeMax(Object mb) {
    return 'The image is too large (max $mb MB), please choose another';
  }

  @override
  String get photoAdd => 'Add photo';

  @override
  String photoMax(Object count) {
    return 'Up to $count photos';
  }

  @override
  String get photoTakeCamera => 'Take a photo with the camera';

  @override
  String photoPickGalleryMax(Object count) {
    return 'Choose from gallery (up to $count)';
  }

  @override
  String get photoPickGallery => 'Choose from gallery';

  @override
  String get photoCameraDenied =>
      'Couldn\'t open the camera. Grant camera permission in settings.';

  @override
  String get photoGalleryDenied =>
      'Couldn\'t open the photo gallery. Grant photo permission in settings.';

  @override
  String get photoUploadFailed => 'Image upload failed';

  @override
  String photoNumber(Object number) {
    return 'Photo $number';
  }

  @override
  String get attachmentReport => 'On-site photos (reporter)';

  @override
  String get attachmentInspection => 'Technician confirmation photos';

  @override
  String get attachmentProgress => 'Repair progress photos';

  @override
  String get attachmentResolution => 'Acceptance photos';

  @override
  String get attachmentPhoto => 'Photo';

  @override
  String attachmentCount(Object count) {
    return '($count photos):';
  }

  @override
  String get attachmentNone => 'No photos yet';

  @override
  String attachmentLocation(Object lat, Object lng) {
    return 'Location $lat, $lng';
  }

  @override
  String get attachmentLoadFailed => 'Couldn\'t load the image';

  @override
  String get paymentSuccess => 'Payment successful';

  @override
  String get paymentFailed => 'Payment failed';

  @override
  String get paymentSuccessExclaim => 'Payment successful!';

  @override
  String get paymentPreparingPin => 'Preparing the compartment PIN...';

  @override
  String get paymentTapToContinue => 'Tap to continue';

  @override
  String get locationPick => 'Choose location';

  @override
  String get locationSearchAddress => 'Search for an address...';

  @override
  String get locationConfirm => 'Confirm location';
}
