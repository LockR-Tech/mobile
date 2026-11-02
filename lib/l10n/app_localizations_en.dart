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

  @override
  String get commonYou => 'Guest';

  @override
  String get commonSeeAllLower => 'See all';

  @override
  String get commonDirections => 'Directions';

  @override
  String get commonAddress => 'Address';

  @override
  String get commonDistance => 'Distance';

  @override
  String get commonStatus => 'Status';

  @override
  String get commonLocation => 'Location';

  @override
  String get commonSize => 'Size';

  @override
  String get commonBack => 'Back';

  @override
  String get commonNoAddress => 'No address yet';

  @override
  String get commonFavorites => 'Favorites';

  @override
  String get commonOffers => 'Offers';

  @override
  String get commonReportIssue => 'Report an issue';

  @override
  String get commonReports => 'Reports';

  @override
  String get commonStatusActive => 'Active';

  @override
  String get commonStatusSuspended => 'Suspended';

  @override
  String get commonDisconnected => 'Disconnected';

  @override
  String get commonOnline => 'Online';

  @override
  String get commonInUseShort => 'In use';

  @override
  String get commonReservedShort => 'Reserved';

  @override
  String get commonBroken => 'Broken';

  @override
  String get commonEmpty => 'Empty';

  @override
  String get commonExpired => 'Expired';

  @override
  String get commonHistory => 'History';

  @override
  String get commonAvailable => 'Available';

  @override
  String commonCopiedValue(Object value) {
    return 'Copied: $value';
  }

  @override
  String get commonStartDate => 'Start';

  @override
  String get commonEndDate => 'End';

  @override
  String get commonHowToUse => 'How to use';

  @override
  String get commonTapToCopy => 'Tap to copy the code';

  @override
  String get commonUnlimitedTime => 'No time limit';

  @override
  String get commonExchange => 'Redeem';

  @override
  String get commonSaved => 'Saved';

  @override
  String get commonLoadFailedData => 'Couldn\'t load data';

  @override
  String boxNumberLabel(Object number) {
    return 'Compartment $number';
  }

  @override
  String boxRowCol(Object row, Object col) {
    return 'Compartment row $row, column $col';
  }

  @override
  String rowCol(Object row, Object col) {
    return 'Row $row, column $col';
  }

  @override
  String boxHash(Object number) {
    return 'Box #$number';
  }

  @override
  String orderHash(Object id) {
    return 'Order #$id';
  }

  @override
  String get homeSendByDrone => 'Send by drone';

  @override
  String get homeDropPoints => 'Drop-off points';

  @override
  String get homeRentLocker => 'Rent a locker';

  @override
  String get homeLockerOrders => 'Locker orders';

  @override
  String get homeUtilities => 'Utilities';

  @override
  String get homeDroneDelivery => 'Drone delivery';

  @override
  String get homeActiveOrders => 'Orders in progress';

  @override
  String get homePickupDeadline => 'Pickup deadline';

  @override
  String get stepCreateOrder => 'Order created';

  @override
  String get stepFlightTeamAccepted => 'Flight team accepted';

  @override
  String get stepFlying => 'In flight';

  @override
  String get stepDropReported => 'Drop reported';

  @override
  String get stepIntoLocker => 'In pickup locker';

  @override
  String get stepDropIntoLocker => 'Placed in locker';

  @override
  String get stepStoring => 'Stored';

  @override
  String get stepInLocker => 'In locker';

  @override
  String get stepTransit => 'In transit';

  @override
  String get stepAwaitingPickup => 'Awaiting pickup';

  @override
  String get homeUtilitiesServices => 'Utilities & services';

  @override
  String get homeSendDrone => 'Send drone';

  @override
  String get homeKioskLocations => 'Kiosk locations';

  @override
  String get homeNoLockerLocations => 'No locker locations yet';

  @override
  String get homeOngoingOffers => 'Ongoing offers';

  @override
  String get storeDefaultName => 'Store';

  @override
  String get storeFavoritesLoadFailed => 'Couldn\'t load your favorites.';

  @override
  String get storeFavoritesSubtitle => 'Drop-off points you saved';

  @override
  String get storeFavoritesLoading => 'Loading favorites...';

  @override
  String get storeNoFavorites => 'No favorite stores yet';

  @override
  String get storeNoFavoritesHint =>
      'Tap the heart icon on a store to save it here.';

  @override
  String get storeExplore => 'Explore stores';

  @override
  String get storeAddedFavorite => 'Added to favorites';

  @override
  String get storeRemovedFavorite => 'Removed from favorites';

  @override
  String get storeFavoriteSaveFailed => 'Couldn\'t save your favorites.';

  @override
  String get storeEnableLocation => 'Please turn on location services.';

  @override
  String get storeNeedLocation =>
      'Location permission is needed to find stores near you.';

  @override
  String get storeNoCurrentLocation => 'Couldn\'t get your current location.';

  @override
  String get storeListLoadFailed => 'Couldn\'t load the store list.';

  @override
  String get storeListSubtitle => 'Explore locker points & partners';

  @override
  String get storeSearchHint => 'Search by name or address';

  @override
  String get storeListLoading => 'Loading locker points...';

  @override
  String get storeNone => 'No stores';

  @override
  String get storeRatingsLoadFailed => 'Couldn\'t load ratings.';

  @override
  String get storeInfoLoadFailed => 'Couldn\'t load store information.';

  @override
  String get storeNoLocation => 'This store has no location yet.';

  @override
  String get storeCantOpenMap => 'Couldn\'t open the map.';

  @override
  String get storeDetailTitle => 'Drop-off point details';

  @override
  String get storeDetailSubtitle => 'Locker point & partner';

  @override
  String get storeInfoLoading => 'Loading information...';

  @override
  String storeRatingCount(Object count) {
    return '  ·  $count reviews';
  }

  @override
  String get storeViewLockers => 'View lockers';

  @override
  String get storeCustomerReviews => 'Customer reviews';

  @override
  String get storeNoReviews => 'No reviews yet';

  @override
  String get storeTemporarilyClosed => 'Temporarily closed';

  @override
  String get storeCustomer => 'Customer';

  @override
  String get storeOpen => 'Open';

  @override
  String storeDistanceFromYou(Object km) {
    return '$km km away';
  }

  @override
  String lockerHash(Object id) {
    return 'Locker #$id';
  }

  @override
  String get lockerLockerTitle => 'Lockers';

  @override
  String get lockerPhysicalLocation => 'Physical locker location';

  @override
  String get lockerListLoading => 'Loading lockers...';

  @override
  String get lockerDroneCellHint =>
      'Tap an empty drone compartment (purple) to send a parcel by drone to another locker.';

  @override
  String get lockerViewOnMap => 'View location on map';

  @override
  String get lockerKioskPoint => 'KIOSK LOCATION';

  @override
  String lockerCount(Object count) {
    return '$count lockers';
  }

  @override
  String get lockerTapToSeeFree => 'Tap a locker to see free compartments';

  @override
  String get lockerDefaultName => 'Locker';

  @override
  String get lockerOfflineCantBook =>
      'The locker is disconnected from the server, so compartments can\'t be booked right now.';

  @override
  String get lockerUnderMaintenance =>
      'The locker is under technical maintenance and isn\'t accepting orders.';

  @override
  String get lockerSuspended => 'The locker is temporarily out of service.';

  @override
  String lockerFreeOfTotal(Object available, Object total) {
    return '$available/$total free';
  }

  @override
  String get lockerNoCellsConfigured =>
      'This locker has no compartments configured yet';

  @override
  String get lockerBoxPendingCheck => 'is waiting for a technician to check it';

  @override
  String get lockerBoxBroken => 'is out of order';

  @override
  String lockerBoxUnavailable(Object box, Object state) {
    return '$box $state. Please choose another compartment.';
  }

  @override
  String lockerBoxUnavailableReason(Object box, Object state, Object reason) {
    return '$box $state: $reason. Please choose another compartment.';
  }

  @override
  String get lockerScreen7 => '7\" screen';

  @override
  String get lockerFaultBroken => 'Fault / Broken';

  @override
  String get lockerDoorOpen => 'Door open';

  @override
  String get lockerDoorClosed => 'Door closed';

  @override
  String get lockerScreen => 'Screen';

  @override
  String get lockerKioskScreen => 'Kiosk screen';

  @override
  String get lockerKioskHelp =>
      'At the kiosk screen you can enter your order PIN to open a compartment, or log in by scanning the kiosk\'s QR code with the scan button on the app\'s home page.';

  @override
  String get lockerKioskOffline =>
      'The locker is disconnected from the server: the screen may not respond and new compartments can\'t be booked.';

  @override
  String get lockerReportKioskIssue => 'Report a kiosk screen issue';

  @override
  String get lockerBrokenUpper => 'BROKEN';

  @override
  String get lockerPendingCheckUpper => 'PENDING CHECK';

  @override
  String get lockerPendingCheck => 'Pending check';

  @override
  String get lockerCleaning => 'Cleaning';

  @override
  String get lockerDroneReceive => 'Drone receiving';

  @override
  String get lockerReady => 'Ready';

  @override
  String get sizeSmall => 'Small (S)';

  @override
  String get sizeMedium => 'Medium (M)';

  @override
  String get sizeLarge => 'Large (L)';

  @override
  String get sizeXlSuitcase => 'Large suitcase (XL)';

  @override
  String get lockerEmptySuitcaseBox => 'Empty suitcase compartment';

  @override
  String get lockerEmptyBox => 'Empty compartment';

  @override
  String get lockerWhatToDo =>
      'What would you like to do with this compartment?';

  @override
  String get lockerRentSubtitle => 'By the hour or day';

  @override
  String get lockerSendParcel => 'Send parcel';

  @override
  String get lockerSendSubtitle => 'C2C transfer';

  @override
  String get lockerSuitcaseRentOnly =>
      'Suitcase compartments are for storage rental only, not for sending parcels.';

  @override
  String get lockerReportBoxIssue =>
      'Problem with this compartment? Report it now';

  @override
  String get lockerNoLockers => 'No lockers yet';

  @override
  String get lockerStoreNoActiveLockers =>
      'This store has no active lockers yet.';

  @override
  String get lockerCabinetIdRequired => 'Cabinet ID is required';

  @override
  String get lockerLocationIdRequired => 'Location ID is required';

  @override
  String get lockerOfflinePickOther =>
      'The locker is disconnected, so compartments can\'t be booked. Please choose another locker or try again later.';

  @override
  String get lockerMaintenancePickOther =>
      'The locker is under maintenance and isn\'t accepting orders. Please choose another locker.';

  @override
  String get lockerSuspendedCantBook =>
      'The locker is temporarily out of service, so compartments can\'t be booked.';

  @override
  String get groupSmall => 'Small (S)';

  @override
  String get groupMedium => 'Medium (M)';

  @override
  String get groupLarge => 'Large (L)';

  @override
  String get groupStandard => 'Standard';

  @override
  String get groupXl => 'Suitcase (XL)';

  @override
  String get groupDrone => 'Drone';

  @override
  String get cellTypeDroneRoof => 'Drone (roof)';

  @override
  String get cellTypeSuitcase => 'Suitcase (XL)';

  @override
  String get cellTypeStandard => 'Standard';

  @override
  String get cellOutOfService => 'Out of service';

  @override
  String get lockerSizeSmallDesc => 'Small, fits handbags and wallets';

  @override
  String get lockerSizeMediumDesc => 'Medium, fits backpacks';

  @override
  String get lockerSizeLargeDesc => 'Large, fits suitcases';

  @override
  String get lockerStatusAvailable => 'Available';

  @override
  String get lockerStatusInUse => 'In use';

  @override
  String get lockerStatusReserved => 'Reserved';

  @override
  String get lockerStatusMaintenance => 'Under maintenance';

  @override
  String get lockerStatusOutOfService => 'Out of service';

  @override
  String get lockerAlreadyRented => 'This locker is already rented.';

  @override
  String get lockerInsufficientBalance => 'Insufficient balance.';

  @override
  String get lockerFixedRentFailed => 'Fixed locker rental failed.';

  @override
  String get lockerOpenCommandSent => 'Open command sent.';

  @override
  String get lockerCloseCommandSent => 'Close command sent.';

  @override
  String get lockerDetailSubtitle => 'Lock.R locker location details';

  @override
  String get lockerNoCoordinates =>
      'This locker has no coordinates yet, so the map and directions can\'t be shown.';

  @override
  String get lockerBookService => 'Book a service';

  @override
  String get lockerViewLayout => 'View compartment layout';

  @override
  String get lockerMapTitle => 'Locker map';

  @override
  String get lockerMapSubtitle => 'Find the nearest Lock.R locker';

  @override
  String get lockerMapLoading => 'Loading map...';

  @override
  String get lockerNoneYet => 'There are no lockers yet!';

  @override
  String get lockerGettingLocation => 'Getting your location...';

  @override
  String get lockerUseMyLocation => 'Use your location';

  @override
  String get lockerMapLoadFailed =>
      'Couldn\'t load the map. The coordinates may be invalid.';

  @override
  String lockerInvalidCoordsHidden(Object count) {
    return '$count locations with invalid coordinates were hidden.';
  }

  @override
  String get lockerLocating => 'Locating...';

  @override
  String get lockerAddressFailed =>
      'Couldn\'t determine the address, please try again';

  @override
  String lockerAddressFailedError(Object error) {
    return 'Couldn\'t determine the address, please try again: $error';
  }

  @override
  String get lockerLocationServiceOff =>
      'Location services are off. Please turn on GPS.';

  @override
  String get lockerLocationDenied => 'Location permission was denied.';

  @override
  String get lockerLocationDeniedForever =>
      'Location permission was permanently denied. Turn it back on in settings.';

  @override
  String get lockerOtherKiosk => 'Other kiosks';

  @override
  String lockerCountShort(Object count) {
    return '$count lockers';
  }

  @override
  String get commonAll => 'All';

  @override
  String get lockerLocationList => 'Locations';

  @override
  String get lockerLoginToSeeLocations => 'Log in to see available locations';

  @override
  String get lockerLoginRequiredLocations =>
      'You need to log in to see the location list';

  @override
  String get lockerPickLocation => 'Choose a location to see details';

  @override
  String get lockerSearchLocation => 'Search locations...';

  @override
  String get lockerNoLocations => 'There are no locations yet!';

  @override
  String get lockerNotFoundHere => 'No lockers found at this location';

  @override
  String get lockerTryOtherLocation =>
      'Try another location or view all available locations.';

  @override
  String get lockerViewAllLocations => 'View all locations';

  @override
  String get lockerLoadingFreeCells => 'Loading free compartments...';

  @override
  String lockerCellsLoadFailed(Object error) {
    return 'Couldn\'t load compartments: $error';
  }

  @override
  String get lockerFreeCells => 'Free compartments';

  @override
  String get lockerConnectionUnknown => 'Connection unknown';

  @override
  String get lockerMostUsed => 'Most used';

  @override
  String get promoUnlimited => 'Unlimited';

  @override
  String get promoExpired => 'Expired';

  @override
  String promoDaysLeft(Object days) {
    return '$days days left';
  }

  @override
  String promoHoursLeft(Object hours) {
    return '$hours hours left';
  }

  @override
  String promoMinutesLeft(Object minutes) {
    return '$minutes minutes left';
  }

  @override
  String promoMinOrder(Object amount) {
    return 'Minimum order $amount';
  }

  @override
  String get promoSystemWide => 'System-wide';

  @override
  String promoAppliesAt(Object name) {
    return 'Applies at: $name';
  }

  @override
  String get promoSubtitle => 'Explore offers available today';

  @override
  String get promoLoading => 'Loading promotions...';

  @override
  String get promoNoneActive => 'No active offers yet';

  @override
  String get promoExpiringSoon => 'Expiring soon';

  @override
  String promoSavedToMine(Object code) {
    return 'Saved code $code to \"My offers\"';
  }

  @override
  String get promoSaveNotSupported =>
      'The server doesn\'t support saving codes yet. Please try again later.';

  @override
  String get promoSaveFailed =>
      'Couldn\'t save the code — check that you\'re logged in and try again';

  @override
  String promoCopiedCode(Object code) {
    return 'Copied code: $code';
  }

  @override
  String promoDiscountPercent(Object percent) {
    return '$percent% off';
  }

  @override
  String promoDiscountAmount(Object amount) {
    return '$amount off';
  }

  @override
  String get promoDetailTitle => 'Offer details';

  @override
  String get promoOfferExpired => 'Offer expired';

  @override
  String get promoCodeLabel => 'Promo code';

  @override
  String get promoDiscountLevel => 'Discount';

  @override
  String get promoScope => 'Scope';

  @override
  String get promoMaxDiscount => 'Max discount';

  @override
  String get promoMinOrderLabel => 'Minimum order';

  @override
  String get promoActive => 'Active';

  @override
  String get promoExpiredCantUse =>
      'This offer has expired and can\'t be used.';

  @override
  String get promoStep1Any =>
      'Go to Rent locker, Send parcel or Send drone and choose a locker';

  @override
  String promoStep1At(Object locker) {
    return 'Go to Rent locker, Send parcel or Send drone at $locker (drone orders: the take-off drone locker)';
  }

  @override
  String get promoStep2 =>
      'In \"Discount code\", tap \"Choose a discount code\" and pick this code from the list';

  @override
  String get promoStep3 =>
      'The discount is deducted from the total if the order qualifies (minimum order, eligible locker)';

  @override
  String get promoLoadFailed => 'Couldn\'t load offers';

  @override
  String get promoAtThisLocker => 'Offers at this locker';

  @override
  String get voucherMine => 'My offers';

  @override
  String get voucherMineSubtitle => 'Your discount codes & gifts';

  @override
  String get voucherExchangeTab => 'Redeem points';

  @override
  String get voucherLoginToSee => 'You need to log in to see your saved offers';

  @override
  String get voucherLoading => 'Loading offers...';

  @override
  String get voucherNone => 'You don\'t have any offers yet';

  @override
  String get voucherExploreAndSave => 'Explore offers and save codes';

  @override
  String get voucherGift => 'Gift';

  @override
  String get voucherGiftUpper => 'GIFT';

  @override
  String get voucherDiscountUpper => 'DISCOUNT';

  @override
  String get voucherUsed => 'Used';

  @override
  String get voucherUsedLong => 'Used';

  @override
  String get voucherCopied => 'Voucher code copied';

  @override
  String get voucherCode => 'Voucher code';

  @override
  String get voucherOffer => 'Offer';

  @override
  String get voucherCampaign => 'Campaign';

  @override
  String get voucherValidUntil => 'Valid until';

  @override
  String get voucherExpiredCantUse =>
      'This voucher has expired and can\'t be used.';

  @override
  String get voucherAlreadyUsed => 'This voucher has already been used.';

  @override
  String get voucherStepCopy => 'Copy the voucher code above';

  @override
  String get voucherStepBookAny =>
      'Go to a booking page (Rent locker / Send parcel / Send drone)';

  @override
  String voucherStepBookAt(Object locker) {
    return 'Book a service at $locker (drone orders: the take-off drone locker)';
  }

  @override
  String get voucherStepEnter =>
      'Enter the code in \"Discount code\" and tap Apply';

  @override
  String get voucherStepDeducted =>
      'The discount will be deducted from the total';

  @override
  String get voucherExchangeNotSupported =>
      'The server doesn\'t support redeeming points yet. Please try again later.';

  @override
  String get voucherExchangeLoadFailed =>
      'Couldn\'t load the points rewards. Please try again.';

  @override
  String get voucherExchangeFailed =>
      'Couldn\'t redeem the voucher. Please try again.';

  @override
  String get voucherWalletNotSupported =>
      'The server doesn\'t support saved offers yet. Please try again later.';

  @override
  String get voucherMineLoadFailed =>
      'Couldn\'t load your offers. Please try again.';

  @override
  String pointsCount(Object points) {
    return '$points points';
  }

  @override
  String voucherMaxSuffix(Object amount) {
    return ' (up to $amount)';
  }

  @override
  String get voucherExchangeLoading => 'Loading point vouchers...';

  @override
  String get voucherExchangeNone => 'No vouchers to redeem with points yet';

  @override
  String get voucherExchangeQuestion => 'Redeem voucher?';

  @override
  String voucherExchangeConfirm(Object points, Object reward, Object code) {
    return 'Use $points to redeem the voucher \"$reward\". It will appear under Available; use code $code when placing an order.';
  }

  @override
  String voucherExchanged(Object code) {
    return 'Redeemed voucher $code — see it under Available';
  }

  @override
  String get voucherYourPoints => 'Your points';

  @override
  String voucherPointRate(Object amount) {
    return '1 point = $amount · redeem for order discount vouchers';
  }

  @override
  String get voucherOwned => 'Owned';

  @override
  String voucherMissingPoints(Object points) {
    return '$points short';
  }

  @override
  String voucherOrderFrom(Object amount) {
    return 'Orders from $amount';
  }

  @override
  String get commonDetails => 'Details';

  @override
  String get commonNotYet => 'Not yet';

  @override
  String get commonNote => 'Note';

  @override
  String get commonReload => 'Reload';

  @override
  String get commonService => 'Service';

  @override
  String get commonDiscount => 'Discount';

  @override
  String get commonVoucher => 'Voucher';

  @override
  String get commonAmount => 'Amount';

  @override
  String get commonLocker => 'Locker';

  @override
  String get commonBox => 'Compartment';

  @override
  String get commonToday => 'Today';

  @override
  String get commonYesterday => 'Yesterday';

  @override
  String get commonUnknownDate => 'Unknown date';

  @override
  String dateDayMonthYear(Object day, Object month, Object year) {
    return '$day/$month/$year';
  }

  @override
  String hoursValue(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String pricePerHour(Object price) {
    return '$price/hour';
  }

  @override
  String photosMore(Object count) {
    return '+$count photos';
  }

  @override
  String get boxThisLower => 'this compartment';

  @override
  String boxNumberLower(Object number) {
    return 'compartment $number';
  }

  @override
  String get boxThis => 'This compartment';

  @override
  String get ordIncomingNotSupported =>
      'The server doesn\'t support Incoming parcels yet. Please try again later.';

  @override
  String get ordNotFoundInList => 'The order wasn\'t found in your list.';

  @override
  String get ordEmptyRecent => 'No orders in the last 7 days.';

  @override
  String get ordEmptyActive => 'No orders are currently in use.';

  @override
  String get ordEmptyCompleted => 'No completed orders yet.';

  @override
  String get ordEmptyRental => 'No locker rentals yet.';

  @override
  String get ordEmptySend => 'No parcel orders yet.';

  @override
  String get ordEmptyCanceled => 'No cancelled orders.';

  @override
  String get ordEmptyHint =>
      'Create a Send parcel or Rent locker order from the home screen.';

  @override
  String get ordCancelQuestion => 'Cancel order?';

  @override
  String ordCancelBody(Object code) {
    return 'Order $code will be cancelled, the opening code will stop working and the held compartment will be released.';
  }

  @override
  String get ordCancelPaidNote =>
      ' Paid amounts aren\'t refunded automatically — after cancelling, open the order again and choose \"Request a refund\".';

  @override
  String get ordKeepOrder => 'Keep order';

  @override
  String get ordCancelOrderAlt => 'Cancel order';

  @override
  String get ordExtendRental => 'Extend rental';

  @override
  String ordAddHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'Add $hours hours',
      one: 'Add 1 hour',
    );
    return '$_temp0';
  }

  @override
  String ordMaxHoursPerExtension(Object hours) {
    return 'Up to $hours hours per extension';
  }

  @override
  String get ordExtend => 'Extend';

  @override
  String ordExtended(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'Extended by $hours hours',
      one: 'Extended by 1 hour',
    );
    return '$_temp0';
  }

  @override
  String get ordReportFaultyBox => 'Report faulty compartment';

  @override
  String get ordDescribeIssueHint =>
      'Describe the issue (won\'t open, door stuck...)';

  @override
  String ordOnsitePhotosOptional(Object max) {
    return 'On-site photos (optional, up to $max)';
  }

  @override
  String get ordPhotosHelp =>
      'Photos help the maintenance team resolve it faster.';

  @override
  String get ordDescribeOrAttach =>
      'Please describe the issue or attach a photo.';

  @override
  String get ordUploadingPhotos => 'Uploading photos...';

  @override
  String get ordSendReport => 'Send report';

  @override
  String get ordBoxFaultDefault =>
      'The compartment has a problem (see attached photos)';

  @override
  String ordReportSentFor(Object box) {
    return 'Report sent for $box — the maintenance team will handle it';
  }

  @override
  String get ordPickupAtKiosk => 'Pick up at the kiosk';

  @override
  String get ordPickupAtKioskBody =>
      'Use this code at the kiosk to open the compartment, take your items out, then close the door before confirming the end of the rental. You can also open it directly in the app if you\'re near the locker.';

  @override
  String ordOpenBoxOnPhone(Object box) {
    return 'Open $box on your phone (GPS/QR)';
  }

  @override
  String get ordPickedUpAndClosed => 'Items taken and locker closed';

  @override
  String get ordRentalEnded => 'Rental ended';

  @override
  String get ordNoLockerInfo => 'The order has no locker information.';

  @override
  String get ordLockerNoLocation =>
      'The locker has no location for directions.';

  @override
  String get ordCantOpenMapsApp => 'Couldn\'t open a maps app on this device.';

  @override
  String ordExtensionPaymentFor(Object id) {
    return 'Rental extension payment for order #$id';
  }

  @override
  String get ordPaidSuccessfully => 'Your order has been paid successfully.';

  @override
  String get ordPaymentNotCompleted =>
      'The transaction wasn\'t completed or was cancelled. Please try again.';

  @override
  String get ordAwaitingPaymentPull =>
      'Waiting for payment confirmation — pull down to refresh in a few minutes.';

  @override
  String get ordAwaitingPaymentConfirmPickup =>
      'Waiting for payment confirmation — tap \"Confirm pickup\" again once the order shows Paid.';

  @override
  String get ordConfirmPickup => 'Confirm pickup';

  @override
  String get ordConfirmPickupBody =>
      'Do you confirm you\'ve received all items from this order? This will close and complete the order.';

  @override
  String get ordPickedUpComplete => 'Picked up — Complete';

  @override
  String get ordCompletedTitle => 'Order completed!';

  @override
  String get ordPaidAndPickedUp =>
      'You\'ve paid and picked up your items. The order is complete.';

  @override
  String get ordReceivedComplete => 'Items received — order complete';

  @override
  String get ordPaidNotCompletedTitle => 'Paid — order not completed';

  @override
  String ordPaidNotCompletedBody(Object reason) {
    return 'The payment was recorded but the order couldn\'t be completed: $reason\nYou can try \"Confirm pickup\" again or file a complaint in the order details.';
  }

  @override
  String get ordNoOvertimeFeeDue => 'This order has no overtime fee to pay';

  @override
  String get ordLockrLocker => 'Lock.R locker';

  @override
  String get ordOverdue => 'Overdue';

  @override
  String get ordOverdueFee => 'Overdue fee';

  @override
  String get ordAwaitingPaymentOpenBox =>
      'Waiting for payment confirmation — open the compartment once the order shows Paid.';

  @override
  String get ordOvertimePaidOpening =>
      'Overtime fee paid — preparing to open the compartment';

  @override
  String ordSendingOpenCommand(Object box) {
    return 'Sending the command to open $box...';
  }

  @override
  String ordBoxOpened(Object box) {
    return '$box is open — please use it and close the door.';
  }

  @override
  String ordBoxOpenFailed(Object box, Object detail) {
    return 'Couldn\'t open $box$detail';
  }

  @override
  String get ordNoBoxPinInfo =>
      'The order has no compartment/PIN information to open the locker.';

  @override
  String get ordOverdueRentalNotice =>
      'The rental is overdue. The overtime fee has been recorded — please open the compartment, take your items and close the locker to finish.';

  @override
  String ordDelegatedTo(Object to) {
    return 'Pickup delegated$to. The old PIN no longer works.';
  }

  @override
  String ordDelegatedToPhone(Object phone) {
    return ' to $phone';
  }

  @override
  String get ordChangePinQuestion => 'Change PIN?';

  @override
  String get ordChangePinReceiver =>
      'The current PIN will stop working. The recipient needs the new code to pick up — please send it to them again.';

  @override
  String get ordChangePinNow =>
      'The current PIN will stop working immediately and be replaced with a new one.';

  @override
  String get ordChangeCode => 'Change code';

  @override
  String get ordPinChangedSeeDetail =>
      'PIN changed — see the new code in the order details.';

  @override
  String ordPinChangedNew(Object pin) {
    return 'New PIN: $pin';
  }

  @override
  String get ordPinChangeNotSupported =>
      'The server doesn\'t support changing the PIN yet.';

  @override
  String ordReceiverEmailSaved(Object email) {
    return 'Saved recipient email $email. Lock.R will notify the recipient once the order is paid.';
  }

  @override
  String ordPickupCodeSentTo(Object email) {
    return 'Sent the locker code to $email.';
  }

  @override
  String ordOrderInfoResentTo(Object email) {
    return 'Resent the order details to $email.';
  }

  @override
  String get ordEmailCodeNotSupported =>
      'The server doesn\'t support sending codes by email yet.';

  @override
  String get ordNewOrderCreated => 'New order created — see it in the list';

  @override
  String get ordDropoffConfirmed => 'Drop-off confirmed';

  @override
  String get ordConfirmPickedUpQuestion =>
      'Confirm you\'ve picked up your items?';

  @override
  String get ordConfirmPickedUpBody =>
      'The order will be completed and the compartment released. Only confirm once you\'ve taken your items out.';

  @override
  String get ordPickedUp => 'Picked up';

  @override
  String ordBoxHasTicket(Object id) {
    return 'This compartment already has ticket RPT-$id being handled by a technician.';
  }

  @override
  String get ordCancelled => 'Order cancelled';

  @override
  String get ordMyOrdersSubtitle => 'Manage your orders';

  @override
  String get ordTabRecent => 'Recent';

  @override
  String get ordTabInUse => 'In use';

  @override
  String get ordTabCompleted => 'Completed';

  @override
  String get ordTabCancelled => 'Cancelled';

  @override
  String get ordTabAwaitingPickup => 'To pick up';

  @override
  String get ordListLoading => 'Loading orders...';

  @override
  String get ordNoOrdersYet => 'No orders yet';

  @override
  String get ordNoMatchingOrders => 'No matching orders';

  @override
  String get ordIncomingLoading => 'Loading incoming parcels...';

  @override
  String get ordNoIncoming => 'No incoming parcels';

  @override
  String get ordNoIncomingHint =>
      'When someone sends a parcel to your phone number, it will appear here.';

  @override
  String get ordNoIncomingMatch =>
      'No incoming parcels match the selected filter.';

  @override
  String get ordMyOrders => 'My orders';

  @override
  String get ordIncoming => 'Incoming';

  @override
  String ordPickupDeadlineValue(Object time) {
    return 'Pick up by: $time';
  }

  @override
  String get ordLockerNameUnknown => 'Locker name unavailable';

  @override
  String get ordPayAndPickup => 'Pay & pick up';

  @override
  String get ordAwaitingTechnician => 'Awaiting technician';

  @override
  String get ordReview => 'Review';

  @override
  String get ordDropIntoLocker => 'Drop off in locker';

  @override
  String get ordPickupNow => 'Pick up now';

  @override
  String get ordOvertimePausedNoTime =>
      'Overtime fee paused — waiting for a technician, no payment needed yet';

  @override
  String ordOvertimePausedSince(Object time) {
    return 'Overtime fee paused since $time — no payment needed yet';
  }

  @override
  String ordStorageExpiredTapPay(Object hours) {
    return 'Storage period expired $hours — Tap to pay & pick up';
  }

  @override
  String get ordOverdueMayCharge => 'Order overdue — fees may apply';

  @override
  String ordRelocatedTitle(Object box) {
    return 'Safely moved to compartment $box';
  }

  @override
  String ordRelocatedSubtitle(Object oldBox) {
    return 'A technician moved your items from the old compartment (#$oldBox) to a new one due to an issue. The new PIN is ready.';
  }

  @override
  String ordCheckedNoIssueTitle(Object box) {
    return 'Technician checked: $box has no issue';
  }

  @override
  String get ordCheckedNoIssueSubtitle =>
      'The compartment works normally; pick up with your PIN as usual. See the technician\'s response in the ticket.';

  @override
  String ordResolvedTitle(Object box) {
    return '$box has been checked & fixed by a technician';
  }

  @override
  String get ordResolvedSubtitle =>
      'Your belongings in the compartment are kept safe.';

  @override
  String ordReportedTitle(Object box) {
    return '$box has been reported';
  }

  @override
  String get ordReportedCancelHint =>
      'Please cancel this order and book another compartment (or contact a technician).';

  @override
  String get ordReportedBlocked =>
      'Your items are still safe in the compartment. A technician is on it — the overtime fee is paused, no payment needed yet.';

  @override
  String get ordReportedCanOpen =>
      'A technician will check the compartment. You can still open it with your PIN — the overtime fee is paused from the time of the report.';

  @override
  String ordReasonValue(Object reason) {
    return 'Reason: $reason';
  }

  @override
  String get ordViewRelocation => 'View relocation details & technician photos';

  @override
  String get ordViewRecord => 'View record & evidence photos';

  @override
  String get ordPayOvertimeFee => 'Pay overtime fee';

  @override
  String get ordOriginalDeadline => 'Original return deadline';

  @override
  String get ordOverdueDuration => 'Time overdue';

  @override
  String get ordOvertimeRate => 'Overtime rate';

  @override
  String get ordCapRule => 'Fee cap rule';

  @override
  String ordCapMax(Object amount) {
    return 'Max $amount';
  }

  @override
  String ordCapPercent(Object percent) {
    return '$percent% of order';
  }

  @override
  String get ordOvertimeFee => 'Overtime fee';

  @override
  String get ordAmountDue => 'Amount due:';

  @override
  String ordPayAmount(Object amount) {
    return 'Pay $amount';
  }

  @override
  String get ordOpenBoxPickup => 'Open compartment to pick up';

  @override
  String get ordBoxReleased => 'Compartment released';

  @override
  String get ordBoxNotAssigned => 'No compartment assigned';

  @override
  String get ordPinCancelledSecurity => '•••••• (Cancelled for security)';

  @override
  String get ordTechInCharge => 'Assigned technician';

  @override
  String get ordRelocationRecordUpper => 'SAFE COMPARTMENT RELOCATION RECORD';

  @override
  String get ordRelocationRecordSubtitle =>
      'Your items were moved to a new compartment because the old one had a technical issue';

  @override
  String get ordOriginalBoxUpper => 'ORIGINAL COMPARTMENT';

  @override
  String ordBoxNumberHash(Object number) {
    return 'Compartment #$number';
  }

  @override
  String get ordTechnicalIssue => 'Technical issue';

  @override
  String get ordNewBoxUpper => 'NEW COMPARTMENT';

  @override
  String get ordHoldingSafely => 'Holding items safely';

  @override
  String get ordOldBoxCheckedAt => 'Old compartment checked at';

  @override
  String get ordMovedAt => 'Moved to new compartment at';

  @override
  String get ordOriginalBoxPin => 'Original compartment PIN';

  @override
  String get ordPinDisabled => 'Disabled (old code expired)';

  @override
  String ordNewBoxPin(Object box) {
    return 'New compartment PIN (#$box)';
  }

  @override
  String ordPinActive(Object pin) {
    return '$pin (Active)';
  }

  @override
  String ordTechPhotos(Object count) {
    return 'Technician photos of the check & relocation ($count photos):';
  }

  @override
  String get ordViewFullRecord =>
      'View the full technician incident record & log ➔';

  @override
  String ordOrderDetailHash(Object id) {
    return 'Order details #$id';
  }

  @override
  String ordServiceHash(Object id) {
    return 'Service #$id';
  }

  @override
  String get ordReviewDroneJourney => 'Review drone journey';

  @override
  String get ordTrackDrone => 'Track drone delivery';

  @override
  String ordPayAndCompletePickup(Object amount) {
    return 'Pay ($amount) & complete pickup';
  }

  @override
  String get ordIPickedUpCompleteOrder => 'I\'ve picked up — Complete order';

  @override
  String ordOpenBoxToPickup(Object box) {
    return 'Open $box to pick up';
  }

  @override
  String get ordReorder => 'Reorder';

  @override
  String ordOpenBoxToDrop(Object box) {
    return 'Open $box to drop off';
  }

  @override
  String get ordIDroppedOff => 'I\'ve dropped off the items';

  @override
  String ordPayOvertimeAndOpen(Object amount) {
    return 'Pay overtime fee ($amount) & open';
  }

  @override
  String get ordIPickedUpComplete => 'I\'ve picked up — complete';

  @override
  String ordOpenBoxToReturn(Object box) {
    return 'Open $box to return the locker & pick up';
  }

  @override
  String get ordEndRentalPickup => 'End rental & pick up';

  @override
  String get ordDelegatePickup => 'Delegate pickup';

  @override
  String get ordChangePin => 'Change PIN';

  @override
  String get ordAddReceiverEmail => 'Add recipient email';

  @override
  String get ordChangeReceiverEmail => 'Change recipient email';

  @override
  String get ordResendToReceiver => 'Resend details to recipient';

  @override
  String get ordCancelOrder => 'Cancel order';

  @override
  String get ordDirectionsToLocker => 'Directions to locker';

  @override
  String get ordRequestRefund => 'Request a refund';

  @override
  String ordStorageExpiredPay(Object hours) {
    return 'The storage period has expired $hours. The compartment was released and your items were moved to safe storage. Please pay the remaining fee and tap \"Pay & pick up\" to finish.';
  }

  @override
  String ordStorageExpiredCheck(Object hours) {
    return 'The storage period has expired $hours. The compartment was released and your items were moved to safe storage. Please check and collect your items, then tap \"I\'ve picked up — Complete order\" to finish.';
  }

  @override
  String get ordOverduePaidOpen =>
      'The overtime fee for this overdue order is paid. Please open the compartment, take your items and return the locker.';

  @override
  String ordOverdueNeedPay(Object policy) {
    return 'The pickup is overdue — pay the overtime fee to open the locker. $policy';
  }

  @override
  String ordUnpaidHold(Object minutes) {
    return 'This order is unpaid. Please pay within $minutes minutes to hold the locker, or tap \"Cancel order\" below to release the compartment now.';
  }

  @override
  String get ordPlace => 'Place';

  @override
  String get ordNewBox => 'New compartment';

  @override
  String ordNewBoxValue(Object box) {
    return 'Compartment $box (Safe)';
  }

  @override
  String get ordOriginalBox => 'Original compartment';

  @override
  String ordOriginalBoxValue(Object box) {
    return 'Compartment $box (Had an issue)';
  }

  @override
  String get ordOldBoxOpenedAt => 'Old compartment opened at';

  @override
  String get ordBoxMovedAt => 'Compartment moved at';

  @override
  String get ordOriginalPin => 'Original PIN';

  @override
  String get ordOrderDate => 'Order date';

  @override
  String get ordRentalDuration => 'Rental duration';

  @override
  String get ordOriginalDeadlineShort => 'Original deadline';

  @override
  String get ordCapRuleShort => 'Fee cap';

  @override
  String get ordOvertimeFeeEstimate => 'Estimated overtime fee';

  @override
  String get ordPenaltyStatus => 'Penalty status';

  @override
  String get ordDueToOpen => 'Due to open';

  @override
  String get ordRecipient => 'Recipient';

  @override
  String get ordRecipientEmail => 'Recipient email';

  @override
  String get ordDelegatedToLabel => 'Pickup delegated to';

  @override
  String get ordDelegatee => 'Delegate';

  @override
  String get ordDelegationMessage => 'Delegation message';

  @override
  String get ordDelegatedAt => 'Delegated at';

  @override
  String get ordExpectedPickup => 'Expected pickup';

  @override
  String get ordDeliveryAddress => 'Delivery address';

  @override
  String get ordFromLocker => 'Sent from locker';

  @override
  String get ordFlightDistance => 'Flight distance';

  @override
  String get ordBasePrice => 'Base price';

  @override
  String get ordExtraFees => 'Extra fees';

  @override
  String get ordPointsUsed => 'Points used';

  @override
  String get ordTotal => 'Total';

  @override
  String get ordRemaining => 'Remaining';

  @override
  String get ordPaidAt => 'Paid at';

  @override
  String get ordParcel => 'Parcel';

  @override
  String get ordDeliveryIncident => 'Delivery incident';

  @override
  String get ordPaused => 'Paused';

  @override
  String get ordPausedAt => 'Paused at';

  @override
  String get ordDeliveryIncomplete => 'Delivery not completed';

  @override
  String get ordRecordedAt => 'Recorded at';

  @override
  String get ordParcelReturned => 'Parcel returned to you';

  @override
  String ordNewBoxPinUpper(Object box) {
    return 'PIN for the NEW compartment (#$box):';
  }

  @override
  String get ordOldPinDisabledNote =>
      '🔒 The old compartment PIN has been disabled. Only use the code above to open the new compartment.';

  @override
  String get ordPickupCodeForTech =>
      'Pickup code — read it to the technician when they arrive';

  @override
  String get ordTimeline => 'Timeline';

  @override
  String get payMethodWallet => 'Lock.R wallet';

  @override
  String get payMethodSepay => 'Bank transfer (SePay)';

  @override
  String get payMethodCash => 'Cash';

  @override
  String get ordPaymentMethod => 'Payment method';

  @override
  String get ordTransactionId => 'Transaction ID';

  @override
  String get ordPaymentTime => 'Payment time';

  @override
  String get ordTransferred => 'Transferred';

  @override
  String get ordRejected => 'Rejected';

  @override
  String get ordAwaitingTransfer => 'Awaiting transfer';

  @override
  String ordRefundHash(Object id) {
    return 'Refund #$id';
  }

  @override
  String get ordRefundAmount => 'Refund amount';

  @override
  String get ordReceivingAccount => 'Receiving account';

  @override
  String get ordCompletedAt => 'Completed at';

  @override
  String get ordRequestedAt => 'Requested at';

  @override
  String get ordSeeRefunds => 'See details under Refunds';

  @override
  String get ordExtensionPayment => 'Rental extension payment';

  @override
  String ordAttemptN(Object n) {
    return 'Attempt $n';
  }

  @override
  String get ordInterventionRecord => 'Intervention & asset protection record:';

  @override
  String ordBoxIncidentTitle(Object code) {
    return 'Compartment incident - Order #$code';
  }

  @override
  String get ordViewTechEvidence => 'View details & technician evidence photos';

  @override
  String get ordInfoRelocated =>
      'ℹ️ Your items have been moved to a new compartment. Please check the new opening code in the app.';

  @override
  String get ordInfoSealedHub =>
      'ℹ️ Your items were sealed safely and taken to the Hub. Staff will contact you to rearrange.';

  @override
  String get ordInfoHandedOver =>
      'ℹ️ Your items were handed over in person. If you have questions, please contact customer support.';

  @override
  String get ordEmailWithCode =>
      'Lock.R will resend the locker code, pickup place and deadline to this email. Edit the email if the recipient didn\'t get the message.';

  @override
  String get ordEmailOrderInfo =>
      'The parcel isn\'t in the locker yet: Lock.R will resend the upcoming-order email (without a code). The locker code is sent once you drop the parcel off.';

  @override
  String get ordEmailSaveOnly =>
      'The order is unpaid. Lock.R will notify the recipient at this email once it\'s paid, and send the locker code when you drop the parcel off.';

  @override
  String get ordEnterRecipientEmail => 'Enter the recipient\'s email';

  @override
  String get ordSaveEmail => 'Save email';

  @override
  String get ordSendEmail => 'Send email';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonCopyTapHint => 'Tap to copy';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonFullNameShort => 'Full name';

  @override
  String get commonSubtotal => 'Subtotal';

  @override
  String get commonDiscountCode => 'Discount code';

  @override
  String get commonRewardPoints => 'Reward points';

  @override
  String get commonChooseLocker => 'Choose locker';

  @override
  String get commonBoxType => 'Compartment type';

  @override
  String get commonSelectedLocker => 'Selected locker';

  @override
  String get commonNoFreeBoxes => 'Full';

  @override
  String commonFreeBoxes(Object count) {
    return '$count free';
  }

  @override
  String get commonStayToPay => 'Stay and pay';

  @override
  String get commonCancelAndExit => 'Cancel order & exit';

  @override
  String get commonPaymentEyebrow => 'LOCK.R • PAYMENT';

  @override
  String commonOrderCode(Object code) {
    return 'Order $code';
  }

  @override
  String commonScanQrPayHold(Object minutes) {
    return 'Scan the QR code above and transfer within $minutes minutes to hold the compartment — the drop-off code will appear automatically after payment.';
  }

  @override
  String commonScanQrPayHoldRent(Object minutes) {
    return 'Scan the QR code above and transfer within $minutes minutes to hold the compartment — the opening code will appear automatically after payment.';
  }

  @override
  String get commonPaySuccessPinReady =>
      'Payment successful! Your compartment PIN is ready.';

  @override
  String daysValue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String pricePerDay(Object price) {
    return '$price/day';
  }

  @override
  String get sizeSmallShort => 'Small';

  @override
  String get sizeMediumShort => 'Medium';

  @override
  String get sizeLargeShort => 'Large';

  @override
  String get boxOfOrder => 'the order\'s compartment';

  @override
  String get sendBoxOpened =>
      'The compartment is open — put the parcel in, close the door and tap confirm.';

  @override
  String get sendBoxOpenFailed => 'Couldn\'t open the compartment';

  @override
  String get sendDroppedShare =>
      'Parcel dropped off. Send the pickup code to the recipient with the Share button below.';

  @override
  String get sendEnterRecipientEmail =>
      'Enter the recipient\'s email so Lock.R can send the locker code';

  @override
  String get sendEnterRecipientPhone => 'Enter the recipient\'s phone number';

  @override
  String get sendPhone10Digits =>
      'The phone number has 10 digits and starts with 0';

  @override
  String get sendCancelCreateQuestion => 'Cancel this order?';

  @override
  String sendCancelCreateBody(Object minutes) {
    return 'The order isn\'t paid yet. If you leave now or don\'t pay within $minutes minutes, the order will be cancelled and the compartment released.';
  }

  @override
  String get sendCancelledReleased =>
      'Order cancelled and compartment released.';

  @override
  String get sendTitle => 'Send via locker';

  @override
  String get sendSubtitle => 'Send items quickly & easily';

  @override
  String get sendCreateAndGetPin => 'Create order & get drop-off PIN';

  @override
  String get sendLoadingLockers => 'Loading lockers...';

  @override
  String get sendIntro =>
      'Send a parcel to someone via a locker: you drop it off with a PIN, and the system generates a new PIN for the recipient to pick it up.';

  @override
  String get sendStandardOnly =>
      'Parcels use standard compartments; suitcase (XL) compartments are for storage rental only. Make sure your parcel fits before creating the order.';

  @override
  String get sendRecipientPhoneHint => 'Recipient\'s phone number';

  @override
  String get sendRecipientNameHint => 'Recipient\'s name (optional)';

  @override
  String get sendRecipientEmailHint => 'Recipient\'s email';

  @override
  String get sendEmailInfo =>
      'Lock.R emails the recipient as soon as the order is paid (an upcoming-parcel notice) and sends the pickup code when you drop the parcel off. You can resend it from the order details; tap \"Share code with recipient\" to also send it via Zalo/SMS.';

  @override
  String get sendRecipientMessage => 'Message for the recipient';

  @override
  String get sendMessageHint => 'E.g. Fragile, handle with care (optional)';

  @override
  String sendBoxSize(Object size) {
    return '$size compartment';
  }

  @override
  String get sendSelectedBox => 'Selected compartment';

  @override
  String sendFeePerParcel(Object price) {
    return '$price/parcel';
  }

  @override
  String get sendBoxTaken =>
      'This compartment was just booked — choose another';

  @override
  String get sendStep1Title => 'Step 1 — Drop off the parcel';

  @override
  String sendStep1Body(Object box) {
    return 'Go to the locker, enter the PIN below to open $box, put the parcel in and close the door.';
  }

  @override
  String get sendStep2Title => 'Step 2 — Parcel dropped off';

  @override
  String get sendPinSentToRecipient =>
      'The pickup PIN has been sent to the recipient\'s account.';

  @override
  String get sendSharePinWithRecipient =>
      'Please send the pickup PIN below to the recipient.';

  @override
  String get sendRecipientEntersPin =>
      'The recipient enters the PIN at the locker to pick up';

  @override
  String get sendEnterPinToDrop =>
      'Enter the PIN at the locker to open the compartment and drop off';

  @override
  String get sendLockrAccount => 'Lock.R account';

  @override
  String get sendHasAccount => 'Yes — the PIN goes straight to the app';

  @override
  String get sendNoAccount => 'No — you need to send the PIN to the recipient';

  @override
  String sendPickupBefore(Object deadline, Object remaining, Object policy) {
    return 'The recipient must pick up before $deadline ($remaining). $policy';
  }

  @override
  String get sendDropInstructions =>
      'Open the compartment with the button below or enter the PIN at the locker, put the parcel in, close the door and confirm. You can also confirm on the locker screen.';

  @override
  String get sendOpenToDrop => 'Open compartment to drop off';

  @override
  String get sendIDropped => 'I\'ve dropped off the parcel';

  @override
  String get sendStepDrop => 'Drop off';

  @override
  String get sendStepRecipientPicks => 'Recipient picks up';

  @override
  String get rentPaymentWaiting =>
      'Waiting for payment confirmation, please wait a moment';

  @override
  String get rentOpenedStart => 'Compartment opened — your rental has started!';

  @override
  String get rentOpenSimulated =>
      'Couldn\'t open the real compartment (simulated: drop-off confirmed & rental started)';

  @override
  String get rentCancelQuestion => 'Cancel this rental?';

  @override
  String rentCancelBody(Object minutes) {
    return 'The rental isn\'t paid yet. If you leave now or don\'t pay within $minutes minutes, the order will be cancelled and the compartment released.';
  }

  @override
  String get rentCancelledReleased =>
      'Rental cancelled and compartment released.';

  @override
  String get rentTitle => 'Rent a storage locker';

  @override
  String get rentSubtitle => 'Choose a locker & rental time';

  @override
  String get rentNow => 'Rent now';

  @override
  String get rentLoadingInfo => 'Loading locker information...';

  @override
  String get rentIntro =>
      'Rent a compartment to store your things by the hour or day. The PIN can be used as many times as you need during the rental.';

  @override
  String get rentDuration => 'Rental duration';

  @override
  String get rentOptionalHint => 'Optional...';

  @override
  String rentDiscountValue(Object amount) {
    return 'Discount: -$amount';
  }

  @override
  String rentPointsValue(Object value) {
    return 'Reward points: $value';
  }

  @override
  String get rentByHour => 'By hour';

  @override
  String get rentByDay => 'By day';

  @override
  String get rentMinusDay => '1 day less';

  @override
  String rentDaysHours(Object days, Object hours) {
    return '$days days · $hours hours';
  }

  @override
  String get rentPlusDay => '1 more day';

  @override
  String get rentRunning => 'Rental in progress';

  @override
  String rentPinUntil(Object time) {
    return 'The PIN opens the compartment as many times as needed until $time.';
  }

  @override
  String get rentPinMultiUse => 'The PIN can be reused during the rental';

  @override
  String rentExpiresAt(Object deadline, Object remaining, Object policy) {
    return 'Rental ends: $deadline ($remaining). $policy';
  }

  @override
  String get rentHeldDropOff => 'Compartment held — drop off your items';

  @override
  String rentEnterPinToOpen(Object box) {
    return 'Enter the PIN to open $box or use the button below to start the rental.';
  }

  @override
  String get rentOpenToDrop => 'Open compartment to drop off';

  @override
  String get rentExtensionUnpaid =>
      'There\'s an unpaid extension fee — pay it before ending the rental.';

  @override
  String get rentDoneSeeOrders => 'Done — see it in My orders';

  @override
  String get cellAvailable => 'Free';

  @override
  String get cellReservedHeld => 'Held';

  @override
  String get cellOccupied => 'Occupied';

  @override
  String get cellAwaitingTechCheck => 'Awaiting technician check';

  @override
  String get cellCleaning => 'Cleaning';

  @override
  String get stAwaitingDropoff => 'Awaiting drop-off';

  @override
  String get stAwaitingDispatch => 'Awaiting dispatch';

  @override
  String get stAccepted => 'Accepted';

  @override
  String get stLaunching => 'Launching';

  @override
  String get stDropReported => 'Drop reported';

  @override
  String get stPickupAssigned => 'Technician on the way to collect';

  @override
  String get stPickedUpByTech => 'Collected by technician';

  @override
  String get stFailed => 'Delivery failed';

  @override
  String get stDeparted => 'Drone departed';

  @override
  String get stEnRoute => 'Drone in flight';

  @override
  String get stApproaching => 'Drone approaching';

  @override
  String get stArrived => 'Drone arrived';

  @override
  String get stReadyForPickup => 'Ready for pickup';

  @override
  String get stStoring => 'In locker';

  @override
  String get stCollected => 'Collected';

  @override
  String get stProcessing => 'Processing';

  @override
  String get stReadyToReturn => 'Ready to return';

  @override
  String get stNew => 'New';

  @override
  String get stDone => 'Done';

  @override
  String get stNotConfirmed => 'Not confirmed';

  @override
  String get typeLaundry => 'Laundry';

  @override
  String get typeStorage => 'Storage';

  @override
  String get typeParcel => 'Parcel pickup';

  @override
  String incidentSince(Object time) {
    return ' since $time';
  }

  @override
  String incidentReportedCanOpen(Object since) {
    return 'You reported a compartment issue — a technician will come to check it. You can still open the compartment with your PIN to take your items; the overtime fee is paused$since.';
  }

  @override
  String incidentBlocked(Object since) {
    return 'The compartment is waiting for a technician. Your items are still safe inside and the overtime fee is paused$since — no payment or extension needed. Lock.R will let you know when you can pick up.';
  }

  @override
  String durDaysHours(Object days, Object hours) {
    return '${days}d ${hours}h';
  }

  @override
  String durHoursMinutes(Object hours, Object minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String get durUnderMinute => 'under 1 minute';

  @override
  String timeRemaining(Object time) {
    return '$time left';
  }

  @override
  String timeOverdueBy(Object time) {
    return 'Overdue by $time';
  }

  @override
  String get credEnterPinAtLocker =>
      'Enter the PIN on the locker screen to open the compartment';

  @override
  String get credPinCopied => 'PIN copied';

  @override
  String credAt(Object name) {
    return 'At: $name';
  }

  @override
  String get unlockBlePermissionBlocked =>
      'Bluetooth (Nearby devices) permission is blocked. Open Settings to allow it, then scan again.';

  @override
  String get unlockBlePermissionDenied =>
      'The app needs Bluetooth permission to find the locker. Tap Scan again and choose Allow.';

  @override
  String get unlockBleOff =>
      'Your phone\'s Bluetooth is off. Turn it on and tap Scan again.';

  @override
  String get unlockBleUnsupported =>
      'This device doesn\'t support Bluetooth. Use QR scan or the PIN.';

  @override
  String get unlockNoSignal => 'No locker Bluetooth signal detected nearby.';

  @override
  String unlockOpenBox(Object box) {
    return 'Open $box';
  }

  @override
  String get unlockOverdueRental =>
      'The rental is overdue. The overtime fee has been recorded — please take your items and close the locker to finish returning it.';

  @override
  String get unlockEndsRental =>
      'Opening the compartment will end the rental and release it. Please take all your items.';

  @override
  String get unlockScanQr => 'Scan QR';

  @override
  String get unlockPin => 'PIN';

  @override
  String get unlockScanning => 'Scanning for the locker\'s Bluetooth signal...';

  @override
  String unlockStandClose(Object locker) {
    return 'Please stand within 2 m of locker $locker';
  }

  @override
  String get unlockConnected => 'Connected to the locker via Bluetooth';

  @override
  String get unlockSimulateRpi => 'Simulate RPi';

  @override
  String unlockDistanceSignal(Object distance, Object rssi) {
    return 'Distance: $distance • Signal $rssi dBm';
  }

  @override
  String unlockOpenAndReturn(Object box) {
    return 'Open $box & return locker';
  }

  @override
  String unlockOpenNow(Object box) {
    return 'Open $box now (one tap)';
  }

  @override
  String get unlockNotFound => 'Locker Bluetooth signal not found';

  @override
  String get unlockEnsureBluetooth =>
      'Make sure Bluetooth is on, or use QR scan instead.';

  @override
  String get unlockScanAgain => 'Scan again';

  @override
  String get unlockRescan => 'Search again';

  @override
  String get unlockQrTitle => 'Verify with the QR sticker on the locker';

  @override
  String unlockQrBody(Object locker, Object box) {
    return 'Use your phone camera to scan the QR code on locker $locker to open $box.';
  }

  @override
  String get unlockStartCamera => 'Turn on camera to scan QR sticker';

  @override
  String get unlockKioskPinUpper => 'PIN TO ENTER ON THE KIOSK SCREEN';

  @override
  String get unlockCodeCopied => 'Code copied';

  @override
  String get unlockCopyPin => 'Copy PIN';

  @override
  String get unlockKioskGuide => 'How to open at the kiosk screen:';

  @override
  String unlockKioskStep1(Object locker) {
    return 'Go to the touchscreen of $locker.';
  }

  @override
  String get unlockKioskStep2 => 'Tap \"Open locker\" or \"Pick up\".';

  @override
  String unlockKioskStep3(Object pin, Object box) {
    return 'Enter PIN $pin to unlatch $box.';
  }

  @override
  String get extrasNotEligible => 'This order isn\'t eligible for this code';

  @override
  String get extrasCodeInvalid => 'Invalid or expired code';

  @override
  String extrasCodeApplied(Object code) {
    return 'Applied code \"$code\"';
  }

  @override
  String get extrasChooseCode => 'Choose a discount code';

  @override
  String get extrasNoCodes => 'No discount codes yet.';

  @override
  String get extrasNoCodesHere =>
      'No discount codes available for this locker.';

  @override
  String get tierBronze => 'Bronze';

  @override
  String get tierSilver => 'Silver';

  @override
  String get tierGold => 'Gold';

  @override
  String get tierPlatinum => 'Platinum';

  @override
  String tierNextPoints(Object points, Object tier) {
    return '$points points to $tier';
  }

  @override
  String tierYouHavePoints(Object points) {
    return 'You have $points points';
  }

  @override
  String tierRank(Object tier) {
    return '$tier tier';
  }

  @override
  String get tierHighest => 'top tier';

  @override
  String get payStatusPaid => 'Paid';

  @override
  String get payStatusPending => 'Awaiting payment';

  @override
  String get payStatusFailed => 'Payment error';

  @override
  String get payStatusNone => 'No payment yet';

  @override
  String rulesRentRange(Object min, Object max) {
    return 'Rent from $min to $max.';
  }

  @override
  String rulesEvery24h(Object price) {
    return 'Each 24 hours costs $price.';
  }

  @override
  String rulesDailyCapFrom(Object hours, Object price) {
    return 'Renting $hours hours or more in a day is charged the daily rate of $price.';
  }

  @override
  String rulesRentalOvertime(Object rate) {
    return 'Overtime is charged at $rate until you pick up or extend.';
  }

  @override
  String get rulesNoOvertimeFee => 'No overtime fee.';

  @override
  String rulesPercentOfOrder(Object percent) {
    return '$percent% of the order value';
  }

  @override
  String rulesCapSuffix(Object caps) {
    return ' (up to $caps)';
  }

  @override
  String get rulesAnd => ' and ';

  @override
  String rulesOvertimeFee(Object rate, Object cap) {
    return 'Overtime fee $rate$cap.';
  }

  @override
  String rulesSendPickup(Object hours, Object policy) {
    return 'The recipient has $hours hours to pick up after you drop off the parcel. $policy';
  }

  @override
  String rulesDronePickup(Object hours, Object policy) {
    return 'The order is stored for $hours hours after the drone drops it into the compartment. The exact deadline is announced as soon as it arrives. $policy';
  }

  @override
  String rulesDroneStoredUntil(Object hours, Object deadline) {
    return 'The order is stored for $hours hours; please pick it up before $deadline.';
  }

  @override
  String rulesLoyaltyEarn(Object percent, Object value) {
    return 'Earn $percent% of what you pay as points (1 point = $value), added when the order is completed.';
  }

  @override
  String get rulesRedeemDisabled => 'Paying with points isn\'t available yet.';

  @override
  String rulesRedeemMin(Object points) {
    return ' (from $points points)';
  }

  @override
  String rulesRedeem(Object value, Object percent, Object min) {
    return '1 point = $value at checkout, up to $percent% of the order value$min.';
  }

  @override
  String get loyaltyRedeemDisabled => 'Paying with points isn\'t available yet';

  @override
  String get loyaltyFullyDiscounted =>
      'The order is fully discounted, no points needed';

  @override
  String get loyaltyNoPoints =>
      'You have no points yet — points are added when an order is completed';

  @override
  String loyaltyBelowMin(Object balance, Object min) {
    return 'You have $balance points; at least $min points are needed per use';
  }

  @override
  String loyaltyOrderTooSmall(Object min) {
    return 'The order value is too low to use the minimum $min points';
  }

  @override
  String loyaltyOffer(Object points, Object amount) {
    return 'Use $points points · $amount off';
  }

  @override
  String loyaltyYouHave(Object balance) {
    return 'You have $balance points';
  }

  @override
  String loyaltyRule(Object value, Object percent) {
    return '1 point = $value, up to $percent% of the order value';
  }

  @override
  String loyaltyPointsDiscount(Object amount, Object points) {
    return '-$amount ($points points)';
  }

  @override
  String get loyaltyCantUseNow =>
      'Reward points can\'t be used right now — the order is charged in full.';

  @override
  String loyaltyPlusPoints(Object points) {
    return '+$points points';
  }

  @override
  String get loyaltyWillEarn => 'Points to be earned';

  @override
  String get loyaltyEarned => 'Points earned';

  @override
  String get loyaltyNotRecorded => 'Not recorded yet';

  @override
  String loyaltyReversed(Object text, Object points) {
    return '$text · $points reversed';
  }

  @override
  String get loyaltyChecking => 'Checking reward points...';

  @override
  String get loyaltyLoadFailed =>
      'Couldn\'t load reward points — the order is charged in full.';

  @override
  String get loyaltyUsePoints => 'Use reward points';

  @override
  String get sepayCreateFailed =>
      'Couldn\'t create the payment. Please try again.';

  @override
  String get sepayNoQr =>
      'The server didn\'t return a VietQR code for this payment. Please try again later.';

  @override
  String get sepayNoTxForSim =>
      'No transaction ID to simulate yet. Please try again.';

  @override
  String get sepayReceivedUpdating =>
      'Payment received, updating your order...';

  @override
  String sepayPartial(Object received, Object remaining) {
    return 'Received $received — $remaining still due. The QR code below is for the remaining amount.';
  }

  @override
  String get sepayScanToPay => 'Scan the VietQR code to pay';

  @override
  String get sepayQrLoadFailed => 'Couldn\'t load the QR code';

  @override
  String get sepayAccountNumber => 'Account number:';

  @override
  String get sepayAmountToTransfer => 'Amount to transfer:';

  @override
  String get sepayTransferContent => 'Transfer description:';

  @override
  String get sepayContentCopied => 'Transfer description copied';

  @override
  String get sepayWaiting => 'Waiting for payment confirmation…';

  @override
  String get sepayAutoUpdate =>
      'Updates automatically once the payment arrives.';

  @override
  String get sepayPayWithBankApp => 'Pay with banking app';

  @override
  String get sepayTransferExact =>
      'Transfer to the exact account number, amount and description below.';

  @override
  String get sepayCreatingQr => 'Creating payment code…';

  @override
  String get apiErrBleTestNotGranted =>
      'Your account hasn\'t been allowed by an admin to test Bluetooth opening at this locker.';

  @override
  String get apiErrResolutionPhotoRequired =>
      'At least 1 acceptance photo is needed before resolving the ticket.';

  @override
  String get apiErrLandingPadAbsent => 'This locker has no drone landing pad.';

  @override
  String get apiErrLandingPadStatusInvalid => 'Invalid landing pad status.';

  @override
  String get apiErrReportNotClaimable =>
      'The ticket is no longer waiting to be claimed.';

  @override
  String get apiErrDroneRouteRequired =>
      'Please choose both the sending and receiving lockers.';

  @override
  String get apiErrDroneRouteInvalid =>
      'The sending and receiving lockers must be different.';

  @override
  String get apiErrDroneRouteTooFar =>
      'The receiving locker is beyond the drone\'s range from this pickup area.';

  @override
  String get apiErrDroneRouteTooShort =>
      'The receiving locker is too close to the pickup point for drone delivery — please drop the parcel directly at the receiving locker.';

  @override
  String get apiErrDronePickupOutOfRange =>
      'The pinned location is outside the pickup radius of the drone sending locker. This distance is measured from your home to the sending locker, not the flight distance between the two lockers. Check the pin on the map and choose the location again.';

  @override
  String get apiErrDroneNoSourceLocker =>
      'No locker near you is ready to launch a drone right now. Please try again later.';

  @override
  String get apiErrDroneLockerLocationMissing =>
      'The receiving locker has no coordinates yet, so drones can\'t deliver there.';

  @override
  String get apiErrDronePickupAddressRequired =>
      'Please enter the pickup address.';

  @override
  String get apiErrDronePickupLocationRequired =>
      'Please choose the pickup location on the map.';

  @override
  String get apiErrDroneSenderNameRequired =>
      'Please enter the sender\'s name.';

  @override
  String get apiErrDroneSenderPhoneInvalid =>
      'The sender\'s phone number is invalid.';

  @override
  String get apiErrDroneSenderEmailInvalid => 'The sender\'s email is invalid.';

  @override
  String get apiErrDroneReceiverNameRequired =>
      'Please enter the recipient\'s name.';

  @override
  String get apiErrDroneReceiverEmailInvalid =>
      'The recipient\'s email is invalid.';

  @override
  String get apiErrDroneParcelCategoryRequired =>
      'Please choose the parcel type.';

  @override
  String get apiErrDronePickupNotOffered =>
      'This pickup is no longer offered to you.';

  @override
  String get apiErrDronePickupOfferExpired => 'The pickup offer has expired.';

  @override
  String get apiErrDronePickupNotAssignedToUser =>
      'This pickup isn\'t assigned to you.';

  @override
  String get apiErrDronePickupNotFound =>
      'The order has no pickup job yet (it may not be paid).';

  @override
  String get apiErrDronePickupCodeInvalid =>
      'Incorrect pickup code. Ask the sender to read the code in the order again.';

  @override
  String get apiErrDronePickupParcelNotVerified =>
      'Confirm the parcel matches its declaration, or report that it couldn\'t be collected.';

  @override
  String get apiErrDroneParcelNotPickedUp =>
      'The parcel hasn\'t been collected from the sender yet.';

  @override
  String get apiErrDroneOrderBlocked =>
      'The order is paused due to an incident; pickup is on hold for now.';

  @override
  String get apiErrDroneTechnicianLocationRequired =>
      'Turn on location to start a shift for pickup jobs.';

  @override
  String get apiErrDroneTechnicianHasActivePickup =>
      'You still have an accepted pickup. Complete it or report it as not collected before ending your shift.';

  @override
  String get apiErrDroneTechnicianOffDuty => 'This technician isn\'t on shift.';

  @override
  String get apiErrDroneTechnicianBusy =>
      'This technician is busy with another job.';

  @override
  String get apiErrDroneFailureReasonInvalid =>
      'Invalid reason for this action.';

  @override
  String get apiErrDroneUnchanged =>
      'This drone is already assigned to the mission.';

  @override
  String get apiErrDroneFlightsSuspended =>
      'Drone delivery is temporarily suspended (weather or an operational incident).';

  @override
  String get apiErrDroneOutsideFlightHours =>
      'Outside the allowed drone flight hours.';

  @override
  String get apiErrDroneOpenOrderLimit =>
      'You have too many unfinished drone orders. Complete or cancel some before placing another.';

  @override
  String get apiErrDroneProhibitedItemsNotDeclared =>
      'You must confirm the parcel contains no items prohibited from flight.';

  @override
  String get apiErrDroneParcelSizeInvalid =>
      'Enter the parcel\'s length, width and height, or leave all three empty.';

  @override
  String get apiErrDroneParcelTooLarge =>
      'The parcel doesn\'t fit the drone\'s cargo bay.';

  @override
  String get apiErrDroneParcelCategoryInvalid => 'Invalid parcel type.';

  @override
  String get apiErrDroneDeclaredValueTooHigh =>
      'The declared value exceeds what a drone is allowed to carry.';

  @override
  String get apiErrDroneParcelNotDropped =>
      'The sender hasn\'t confirmed dropping the parcel into the sending compartment, so it can\'t be accepted yet.';

  @override
  String get apiErrDroneParcelReturnNotPending =>
      'This order has no parcel waiting to be returned.';

  @override
  String get apiErrDroneBatteryUnknown =>
      'The drone\'s battery level is unknown; update it before flying.';

  @override
  String get apiErrDroneSurchargeNotOwed =>
      'The order no longer owes a weight surcharge.';

  @override
  String get apiErrDroneSourceNotFound => 'Sending locker not found.';

  @override
  String get apiErrDroneDestinationNotFound => 'Receiving locker not found.';

  @override
  String get apiErrDroneLockerInactive =>
      'The sending or receiving locker is out of service.';

  @override
  String get apiErrDroneSourceCellUnavailable =>
      'The drone compartment at the sending locker has another order. Please wait for the flight team to load it or choose another locker.';

  @override
  String get apiErrDroneSourceCellMismatch =>
      'The selected drone compartment doesn\'t belong to this sending locker.';

  @override
  String get apiErrDroneCellRequired =>
      'Drone delivery can only be booked from a drone compartment.';

  @override
  String get apiErrBoxNotAvailable =>
      'The compartment is no longer free. Please choose another compartment or locker.';

  @override
  String get apiErrDroneDemoNotAllowed =>
      'Your account isn\'t allowed to use drone simulation mode.';

  @override
  String get apiErrDroneOrderUnpaid =>
      'The order is unpaid, so it can\'t be accepted yet.';

  @override
  String get apiErrDroneOrderStatusInvalid =>
      'The order is no longer at a step that allows this action.';

  @override
  String get apiErrDroneMissionAlreadyExists =>
      'Another dispatcher has already accepted this order.';

  @override
  String get apiErrDroneMissionStatusInvalid =>
      'The mission is no longer at a step that allows this action.';

  @override
  String get apiErrDroneMissionNotAssignedToUser =>
      'Only the dispatcher who accepted this mission can act on it.';

  @override
  String get apiErrDroneWrongSourceLocker =>
      'The selected drone isn\'t parked at the order\'s sending locker.';

  @override
  String get apiErrDroneInactive => 'The drone is out of service.';

  @override
  String get apiErrDroneNotIdle =>
      'The drone is no longer available; choose another one.';

  @override
  String get apiErrDroneBatteryTooLow =>
      'The drone\'s battery is too low to fly; charge it first.';

  @override
  String get apiErrDroneStatusConflict =>
      'The drone\'s status just changed; reload and try again.';

  @override
  String get apiErrDroneReservationLost =>
      'The drone is no longer reserved for this mission (it may have reported a fault).';

  @override
  String get apiErrDronePayloadTooHeavy =>
      'The parcel exceeds the drone\'s payload limit.';

  @override
  String get apiErrDroneLoadingNotConfirmed =>
      'Confirm loading before launching.';

  @override
  String get apiErrDroneSurchargeUnpaid =>
      'The parcel is heavier than declared. Wait for the customer to pay the difference before launching.';

  @override
  String get apiErrDroneParcelWeightInvalid => 'Invalid parcel weight.';

  @override
  String get apiErrDroneAlreadyInFlight =>
      'The drone has already taken off; the mission can\'t be cancelled.';

  @override
  String get apiErrDroneCancelNoteRequired =>
      'Please add a note when choosing the Other reason.';

  @override
  String get apiErrDroneStageAutomated =>
      'Simulated orders advance automatically; no manual confirmation needed.';

  @override
  String get apiErrDroneReceiverPhoneInvalid =>
      'The recipient\'s phone number is invalid.';

  @override
  String get apiErrLockerInactive => 'The locker is out of service.';

  @override
  String get apiErrLandingPadUnavailable =>
      'The drone landing pad isn\'t ready.';

  @override
  String get apiErrDroneOwnershipRequired =>
      'You need to take charge of this drone first.';

  @override
  String get apiErrDroneAlreadyAssigned =>
      'Another technician is already in charge of this drone.';

  @override
  String get apiErrDroneActiveMission =>
      'The drone has an active mission; you can only report a fault (FAULT).';

  @override
  String get apiErrDroneFaultReasonRequired =>
      'Please enter a reason when reporting a drone fault.';

  @override
  String get apiErrDronePaymentRequiredBeforePickup =>
      'Please pay for the drone order before opening the locker to pick up.';

  @override
  String get apiErrOrderStatusInvalid =>
      'The order is no longer in a state that allows this action.';

  @override
  String get apiErrNotSupportedUpdate =>
      'The server doesn\'t support this feature yet. Please update the system and try again.';

  @override
  String get apiErrForbidden => 'You don\'t have permission to do this';

  @override
  String get apiErrConnection => 'Server connection error';

  @override
  String get apiErrGeneric => 'Something went wrong';

  @override
  String get commonSending => 'Sending...';

  @override
  String get commonDescription => 'Description';

  @override
  String get commonNo => 'No';

  @override
  String get commonOrder => 'Order';

  @override
  String get commonTime => 'Time';

  @override
  String get commonMessage => 'Message';

  @override
  String get recvLoadFailed =>
      'Couldn\'t read the order details. Please try again.';

  @override
  String get recvNotInList =>
      'The order is no longer in your list (it may have been delegated to someone else). Showing saved information.';

  @override
  String get recvSummaryOnly =>
      'The server doesn\'t support full details yet — showing a summary.';

  @override
  String recvEmailSent(Object withCode, Object email) {
    return 'Sent the order details$withCode to $email.';
  }

  @override
  String get recvWithCode => ' with the locker code';

  @override
  String get recvYourEmail => 'your email';

  @override
  String get recvNoEmail => 'No email yet';

  @override
  String get recvNoEmailBody =>
      'Your account has no email to receive order details. Add an email in Profile and send again.';

  @override
  String get recvAddEmail => 'Add email';

  @override
  String get recvDelegateDetail => 'Delegated pickup details';

  @override
  String get recvDetail => 'Incoming order details';

  @override
  String get recvDelegator => 'Delegated by';

  @override
  String get recvSender => 'Sender';

  @override
  String get recvPickupCode => 'Pickup code';

  @override
  String recvOpenBoxPickup(Object box) {
    return 'Open $box to pick up';
  }

  @override
  String get recvTrackDrone => 'Track drone';

  @override
  String get recvSendingEmail => 'Sending email…';

  @override
  String get recvResendEmail => 'Resend details by email';

  @override
  String get recvSenderPhone => 'Sender phone';

  @override
  String get recvSenderEmail => 'Sender email';

  @override
  String get recvRecipientName => 'Recipient name';

  @override
  String get recvRecipientPhone => 'Recipient phone';

  @override
  String get recvDelegatePerson => 'Pickup delegate';

  @override
  String recvYouSuffix(Object name) {
    return '$name (you)';
  }

  @override
  String get recvYou => 'You';

  @override
  String get recvDelegatePhone => 'Delegate phone';

  @override
  String get recvDelegation => 'Delegation';

  @override
  String get recvOwnerDelegated =>
      'The order owner delegated pickup to someone else';

  @override
  String get recvLockerAndBox => 'Locker & compartment';

  @override
  String get recvReceivingLocker => 'Receiving locker';

  @override
  String get recvLockerCode => 'Locker code';

  @override
  String get recvBoxSize => 'Compartment size';

  @override
  String get recvSourceAddress => 'Sending locker address';

  @override
  String get recvSenderNote => 'Sender\'s note';

  @override
  String get recvPickupDeadline => 'Pickup deadline';

  @override
  String get recvTimeLeft => 'Time left';

  @override
  String get recvExpectedPickup => 'Expected pickup';

  @override
  String get recvCreatedAt => 'Created at';

  @override
  String get recvCompletedAt => 'Completed at';

  @override
  String get recvUpdatedAt => 'Last updated';

  @override
  String get recvTimeline => 'Timeline';

  @override
  String get recvDroneJourney => 'Drone journey';

  @override
  String get recvCurrentStage => 'Current stage';

  @override
  String get recvEta => 'Expected arrival';

  @override
  String get recvArrived => 'Arrived';

  @override
  String recvAboutMinutes(Object minutes) {
    return 'About $minutes min';
  }

  @override
  String get recvIncident => 'Incident';

  @override
  String get recvParcelReturnedToSender => 'Parcel returned to sender';

  @override
  String get recvCodeMovedToDelegate =>
      'The order owner delegated pickup to someone else, so the pickup code is no longer shown here.';

  @override
  String get recvCredCaption =>
      'Enter the PIN or scan the QR at the locker, or open the compartment right in the app';

  @override
  String get recvOverdueMayCharge =>
      'The pickup is overdue — overtime fees may apply.';

  @override
  String get recvCompleted =>
      'The order is complete — the parcel has been picked up.';

  @override
  String recvCompletedAtTime(Object time) {
    return 'The order is complete — the parcel was picked up at $time.';
  }

  @override
  String get recvCancelled =>
      'The order was cancelled, so there\'s no pickup code.';

  @override
  String get recvExpired =>
      'The pickup deadline passed and the compartment was reclaimed. Please contact the sender or Lock.R support.';

  @override
  String recvDroneNotReady(Object stage) {
    return '$stage. The pickup code will appear once the drone has placed the parcel in the receiving compartment.';
  }

  @override
  String get recvSenderNotDropped =>
      'The sender hasn\'t dropped off the parcel yet. The pickup code will appear once it\'s in the compartment.';

  @override
  String get recvNotReady =>
      'The parcel isn\'t ready yet. The pickup code will appear once it\'s in the compartment.';

  @override
  String get recvSenderPaid => 'Paid by the sender';

  @override
  String get recvRefundingSender => 'Refunding the sender';

  @override
  String get recvSenderRefunded => 'Refunded to the sender';

  @override
  String get recvSenderUnpaid => 'Not paid by the sender';

  @override
  String get recvOrderCodeCopied => 'Order code copied';

  @override
  String get recvCopyOrderCode => 'Copy order code';

  @override
  String get recvYouAreDelegate =>
      'You\'ve been delegated to pick up this order.';

  @override
  String get recvYouAreRecipient => 'You\'re the recipient of this order.';

  @override
  String recvOverdueBy(Object duration) {
    return 'The pickup is $duration overdue — pick it up soon to avoid overtime fees.';
  }

  @override
  String get recvNoCodeYet =>
      'The order has no pickup code yet — the parcel may not be in the compartment.';

  @override
  String recvBoxOpenedPickup(Object box) {
    return '$box is open — take your parcel and close the door.';
  }

  @override
  String get recvOpenByCodeNotSupported =>
      'The server doesn\'t support opening by code yet. Please enter the code on the locker screen.';

  @override
  String recvLockerWithCode(Object code) {
    return 'Locker $code';
  }

  @override
  String get recvDelegatorColon => 'Delegated by:';

  @override
  String get recvSenderColon => 'Sender:';

  @override
  String get recvDelegatedPickup => 'Delegated';

  @override
  String get recvIncomingParcel => 'Incoming';

  @override
  String get recvStorageBox => 'Storage compartment';

  @override
  String get recvCodeMovedShort =>
      'The order owner delegated pickup to someone else, so the pickup code is no longer shown here.';

  @override
  String get recvCredCaptionShort =>
      'Enter the PIN at the locker or open the compartment in the app';

  @override
  String get recvReceived => 'Received';

  @override
  String get recvDelegated => 'Pickup delegated';

  @override
  String get recvOverdueHurry =>
      'The pickup is overdue — pick it up soon to avoid extra fees.';

  @override
  String get recvCodeTransferred =>
      'The order owner delegated pickup — the pickup code has moved to the delegate.';

  @override
  String get detailCantCall => 'This device can\'t make calls.';

  @override
  String detailCopiedLabel(Object label) {
    return 'Copied $label';
  }

  @override
  String detailCallLabel(Object label) {
    return 'Call $label';
  }

  @override
  String detailCopyLabel(Object label) {
    return 'Copy $label';
  }

  @override
  String get parcelCategory => 'Parcel type';

  @override
  String get parcelWeight => 'Weight';

  @override
  String get parcelSize => 'Dimensions';

  @override
  String get parcelFragile => 'Fragile';

  @override
  String get parcelFragileYes => 'Yes — handle with care';

  @override
  String get parcelDeclaredValue => 'Declared value';

  @override
  String get parcelNoProhibited => 'No prohibited items declared';

  @override
  String get delegateTitle => 'Delegate pickup';

  @override
  String get delegateBody =>
      'The delegate will see the order and the opening code under \"Delegated orders\" in the app (matched by phone number). The current PIN will be replaced.';

  @override
  String get delegatePhone => 'Delegate\'s phone number';

  @override
  String get delegateName => 'Delegate\'s name (optional)';

  @override
  String get delegateMessage => 'Message (optional)';

  @override
  String get delegateInvalidPhone =>
      'Enter a valid phone number (9–11 digits).';

  @override
  String get delegateNotSupported =>
      'The server doesn\'t support pickup delegation yet.';

  @override
  String get delegateAction => 'Delegate';

  @override
  String get shareCopiedMessage =>
      'Message copied — paste it into Zalo, Messenger or SMS to send to the recipient.';

  @override
  String get shareCantOpenSheet => 'Couldn\'t open the share sheet';

  @override
  String get shareCantOpenSms => 'Couldn\'t open the messaging app';

  @override
  String get shareTheRecipient => 'the recipient';

  @override
  String get shareTitle => 'Send the code to the recipient';

  @override
  String shareBody(Object who) {
    return 'The recipient enters the code on the locker screen to open the compartment. Send a ready-made message to $who via Zalo, Messenger or SMS.';
  }

  @override
  String get shareButton => 'Share code with recipient';

  @override
  String get shareSms => 'Send SMS';

  @override
  String get shareCopyMessage => 'Copy message';

  @override
  String shareMsgLocker(Object where) {
    return 'You have a parcel waiting at locker $where.';
  }

  @override
  String shareMsgDrone(Object where) {
    return 'You have a drone-delivered parcel waiting at locker $where.';
  }

  @override
  String shareMsgBox(Object number) {
    return 'Compartment $number.';
  }

  @override
  String shareMsgCode(Object code) {
    return 'Pickup code: $code.';
  }

  @override
  String shareMsgDeadline(Object deadline) {
    return 'Pick up by: $deadline.';
  }

  @override
  String get shareMsgHowTo =>
      'Enter the code on the locker screen (kiosk) to open the compartment.';

  @override
  String get timelineTitle => 'Status history';

  @override
  String get timelineLoadFailed => 'Couldn\'t load the status history.';

  @override
  String get timelineEmpty => 'No status changes yet.';

  @override
  String timelineFrom(Object status) {
    return 'From $status';
  }

  @override
  String get pickerNoLockers => 'No lockers available';

  @override
  String get pickerTapToChange => 'Tap to choose another locker';

  @override
  String pickerUnavailable(Object reason) {
    return 'Temporarily unavailable: $reason';
  }

  @override
  String payTransferAmount(Object amount) {
    return 'Bank transfer · $amount';
  }

  @override
  String get payScanAnyBank =>
      'Scan the code with any banking app or open your banking app directly.';

  @override
  String get svcRentSubtitle => 'Rent by the hour, reusable PIN';

  @override
  String get svcSendSubtitle =>
      'Drop off the parcel, send the PIN to the recipient';

  @override
  String get qrEnterLockerCode => 'Please enter the locker code.';

  @override
  String get qrThisLocker => 'this locker';

  @override
  String qrLockerCodeMismatch(Object locker) {
    return 'The locker code doesn\'t match $locker.';
  }

  @override
  String get qrEnterLockerCodeTitle => 'Enter locker code';

  @override
  String get qrLockerCodeHint => 'Code printed on the locker';

  @override
  String qrCodeMismatch(Object locker) {
    return 'The QR code doesn\'t match $locker.\nPlease scan the QR code on the locker.';
  }

  @override
  String get qrLockerBoxGeneric => 'compartment';

  @override
  String qrScanToOpen(Object box) {
    return 'Scan to open $box';
  }

  @override
  String qrLockerCodeValue(Object code) {
    return 'Locker code: $code';
  }

  @override
  String get qrPointCamera =>
      'Point the camera at the QR sticker on the locker to verify you\'re standing there.';

  @override
  String get qrCantScan => 'Can\'t scan? Enter the locker code';

  @override
  String secondsValue(Object seconds) {
    return '${seconds}s';
  }

  @override
  String durDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String durDaysHoursLong(Object days, Object hours) {
    return '${days}d ${hours}h';
  }

  @override
  String durHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String durHoursMinutesLong(Object hours, Object minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String durMinutesSeconds(Object minutes, Object seconds) {
    return '${minutes}m ${seconds}s';
  }

  @override
  String get incStReported => 'Reported';

  @override
  String get incStEvidencePending => 'Collecting evidence';

  @override
  String get incStInvestigating => 'Investigating';

  @override
  String get incStRecoveryInProgress => 'Recovering the parcel';

  @override
  String get incStAwaitingAdmin => 'Awaiting admin review';

  @override
  String get incStResolutionProposed => 'Resolution proposed';

  @override
  String get incStAwaitingCustomer => 'Awaiting your response';

  @override
  String get incStResolutionInProgress => 'Resolution in progress';

  @override
  String get incStDisputed => 'Under review at your request';

  @override
  String get incStResolved => 'Resolved';

  @override
  String get incStClosed => 'Closed';

  @override
  String get incStManual => 'Staff handling it directly';

  @override
  String get recStOpen => 'Newly opened';

  @override
  String get recStAwaitingAssignment => 'Awaiting recovery assignment';

  @override
  String get recStAssigned => 'Assigned';

  @override
  String get recStAccepted => 'Accepted by staff';

  @override
  String get recStSearching => 'Searching for the parcel';

  @override
  String get recStFound => 'Parcel found';

  @override
  String get recStNotFound => 'Parcel not found yet';

  @override
  String get recStRecovered => 'Parcel recovered';

  @override
  String get recStSubmitted => 'Recovery result reported';

  @override
  String get recStVerified => 'Result verified';

  @override
  String get recStClosed => 'Parcel handed over to the warehouse';

  @override
  String get recStCancelled => 'Cancelled';

  @override
  String get parStInTransit => 'In transit';

  @override
  String get parStDropReported => 'Drop reported';

  @override
  String get parStRecoveryPending => 'Awaiting recovery';

  @override
  String get parStFound => 'Found';

  @override
  String get parStRecovered => 'Recovered';

  @override
  String get parStDamaged => 'Damaged';

  @override
  String get parStLost => 'Lost';

  @override
  String get parStReturnedToHub => 'Back at the Lock.R warehouse';

  @override
  String get parStRedeliveryPending => 'Awaiting redelivery';

  @override
  String get parStRedelivered => 'Redelivered';

  @override
  String get parStCompensated => 'Compensated';

  @override
  String get incEvReported => 'Parcel drop from drone recorded';

  @override
  String get incEvRecoveryAssigned => 'Recovery staff assigned';

  @override
  String get incEvRecoveryAccept => 'Staff accepted the recovery';

  @override
  String get incEvRecoverySearching => 'Staff started searching';

  @override
  String get incEvReturnFlightConfirmed => 'Drone returned to station';

  @override
  String get incEvRecoverySubmitted => 'Recovery result reported';

  @override
  String get incEvRecoveryVerified => 'Recovery result verified';

  @override
  String get incEvStationDispatched =>
      'Parcel routed to a flight station for redelivery';

  @override
  String get incEvStationUnavailable =>
      'Arranging a station to receive the parcel';

  @override
  String get incEvReturnedToHub => 'Parcel arrived at the Lock.R warehouse';

  @override
  String get incEvResolutionProposed => 'Lock.R proposed a resolution';

  @override
  String get incEvCustomerAccept => 'You accepted the resolution';

  @override
  String get incEvCustomerReview => 'You requested a review';

  @override
  String get incEvReturnFlightUpdated => 'Return flight update';

  @override
  String get incEvRedeliveryRequested => 'Redelivery order created';

  @override
  String get incEvRedeliveryUnavailable =>
      'Couldn\'t create a redelivery order — staff will contact you';

  @override
  String get incEvRedeliveryCompleted => 'Redelivered successfully';

  @override
  String get incEvCompensationSubmitted => 'Compensation payout requested';

  @override
  String get incEvCompensationPaid => 'Compensation paid';

  @override
  String get incEvCompensationFailed => 'Compensation payout failed';

  @override
  String get incEvResolved => 'Incident resolved';

  @override
  String get resFreeRedelivery => 'Free redelivery';

  @override
  String get resRedeliveryPartial => 'Redelivery with partial compensation';

  @override
  String get resCompensationOnly => 'Compensation';

  @override
  String get resManual => 'Separate agreement';

  @override
  String get condIntact => 'intact';

  @override
  String get condMinor => 'minor damage';

  @override
  String get condMajor => 'major damage';

  @override
  String get condUnusable => 'unusable';

  @override
  String get propAwaiting => 'Awaiting your response';

  @override
  String get propAccepted => 'You accepted';

  @override
  String get propDisputed => 'Review requested';

  @override
  String get propSuperseded => 'Replaced by a new proposal';

  @override
  String get incEvRecoveryUpdate => 'Recovery update';

  @override
  String get incEvCompensationUpdate => 'Compensation update';

  @override
  String get incEvRedeliveryUpdate => 'Redelivery update';

  @override
  String get msNotInit => 'Not started';

  @override
  String get msAwaitingLoading => 'Awaiting loading';

  @override
  String get msReadyToLaunch => 'Ready to launch';

  @override
  String get msLaunching => 'Launching';

  @override
  String get msDeparted => 'Departed';

  @override
  String get msEnRoute => 'In flight';

  @override
  String get msApproaching => 'Approaching the receiving locker';

  @override
  String get msArrived => 'Arrived at the receiving locker';

  @override
  String get msDeposited => 'Parcel deposited';

  @override
  String get msFailed => 'Flight failed';

  @override
  String get msDropReported => 'Stopped due to a parcel drop';

  @override
  String get dosAwaitingDispatch => 'Drone delivery in progress';

  @override
  String get dosStoring => 'In the receiving locker';

  @override
  String get dosExpired => 'Pickup overdue';

  @override
  String get cancelWeather => 'Bad weather';

  @override
  String get cancelDroneFault => 'Drone fault';

  @override
  String get cancelPadNotReady => 'Landing pad not ready';

  @override
  String get cancelOperational => 'Operational reason';

  @override
  String get cancelOther => 'Other reason';

  @override
  String cancelReasonCode(Object code) {
    return 'Reason #$code';
  }

  @override
  String get modeDemo => 'Simulation (DEMO)';

  @override
  String get modeStandard => 'Real drone';

  @override
  String get stgTitleAwaitingTech =>
      'Waiting for a technician to accept the pickup';

  @override
  String get stgTitleTechOnWay => 'Technician on the way to collect';

  @override
  String get stgTitlePickedUp => 'Collected, heading to the drone';

  @override
  String get stgTitleLoading => 'Loading onto the drone';

  @override
  String get stgTitleLaunching => 'Drone launching';

  @override
  String get stgTitleDeparted => 'Drone departed';

  @override
  String get stgTitleEnRoute => 'Drone on the way';

  @override
  String get stgTitleApproaching => 'Drone approaching';

  @override
  String get stgTitleArrived => 'Drone arrived at the locker';

  @override
  String get stgTitleReady => 'Ready for pickup';

  @override
  String get stgTitleDelayed => 'Order delayed';

  @override
  String get stgTitleFailed => 'Delivery not completed';

  @override
  String get stgTitleDrop => 'Parcel dropped';

  @override
  String get stgTitleCancelled => 'Drone order cancelled';

  @override
  String get stgTitleReceived => 'Received';

  @override
  String get stgTitleExpired => 'Pickup overdue';

  @override
  String get stgTitleUpdate => 'Order update';

  @override
  String get stgDescAwaitingTech =>
      'After payment, the system finds the nearest available drone technician';

  @override
  String get stgDescTechOnWay =>
      'The technician is heading to the pickup point; have the parcel and pickup code ready';

  @override
  String get stgDescPickedUp =>
      'The parcel is being taken to the drone for direct loading, not into a locker compartment';

  @override
  String get stgDescLoading =>
      'A drone is assigned; the technician is weighing and loading the parcel';

  @override
  String get stgDescLaunching =>
      'The flight team is running the launch procedure';

  @override
  String get stgDescDeparted =>
      'The drone has taken off from the source station';

  @override
  String get stgDescEnRoute => 'The drone is flying to the receiving locker';

  @override
  String stgDescEnRouteEta(Object eta) {
    return 'The drone is expected to arrive in $eta';
  }

  @override
  String get stgDescApproaching =>
      'The drone is approaching your receiving locker';

  @override
  String get stgDescArrived =>
      'The drone has arrived and is depositing the parcel';

  @override
  String get stgDescReady =>
      'The parcel is in the receiving locker; use the order\'s PIN/QR to open the compartment';

  @override
  String get stgDescDelayed => 'The order is running behind schedule';

  @override
  String stgDescDelayedEta(Object eta) {
    return 'The order is delayed, now expected in $eta';
  }

  @override
  String get stgDescFailed => 'The delivery wasn\'t completed';

  @override
  String get stgDescDrop =>
      'The parcel was reported dropped from the drone during flight. See the recovery progress and resolution in the order\'s incident card.';

  @override
  String get stgDescCancelled => 'The order stopped before the drone took off';

  @override
  String get stgDescReceived =>
      'The recipient has taken the parcel from the locker';

  @override
  String get stgDescExpired =>
      'The pickup deadline has passed, please contact support';

  @override
  String get stgDescUpdate => 'Your order has a new update';

  @override
  String get droneNoWeatherData => 'No weather data yet.';

  @override
  String get failWeather =>
      'Flights paused due to weather or an operations order';

  @override
  String get failWeatherUnsafe => 'Unsafe weather on the flight route';

  @override
  String get failStationSuspended => 'The flight station is suspended';

  @override
  String get failDroneFault => 'Drone fault';

  @override
  String get failNoDrone => 'No drone available at the sending locker';

  @override
  String get failSourceLocker => 'Sending locker fault';

  @override
  String get failDestinationLocker => 'Receiving locker fault';

  @override
  String get failLandingPad => 'Drone landing pad not ready';

  @override
  String get failNoTechnician => 'No technician accepted the pickup';

  @override
  String get failLaunchOverdue => 'Drone launch overdue after pickup';

  @override
  String get failCustomerAbsent =>
      'Couldn\'t meet the sender at the pickup point';

  @override
  String get failParcelRejected => 'The parcel didn\'t match its declaration';

  @override
  String get failAddressNotFound => 'Pickup address not found';

  @override
  String get failFlightIncident => 'In-flight incident';

  @override
  String get failShortCustomerAbsent => 'Sender not met';

  @override
  String get failShortParcelRejected => 'Parcel didn\'t match';

  @override
  String get failShortAddressNotFound => 'Address not found';

  @override
  String get failShortNoDrone => 'No drone available';

  @override
  String get failShortSourceLocker => 'Sending locker fault';

  @override
  String get failShortDestinationLocker => 'Receiving locker fault';

  @override
  String get failShortFlightIncident => 'In-flight incident';

  @override
  String get catDocument => 'Documents';

  @override
  String get catFood => 'Food';

  @override
  String get catClothing => 'Clothing';

  @override
  String get catElectronics => 'Electronics';

  @override
  String get catCosmetics => 'Cosmetics';

  @override
  String get heldSourceBox => 'Still in the sending compartment';

  @override
  String get heldFlightTeam => 'Held by the flight team';

  @override
  String get blockDisconnected => 'disconnected';

  @override
  String get blockMaintenance => 'under maintenance';

  @override
  String get blockSuspended => 'suspended';

  @override
  String get blockNoPad => 'no drone landing pad';

  @override
  String get blockPadMaintenance => 'landing pad under maintenance';

  @override
  String get blockPadFault => 'landing pad fault';

  @override
  String get droneErrOwnerOnly =>
      'Only the person who placed the order can do this.';

  @override
  String get droneErrNotYourIncident =>
      'This incident doesn\'t belong to your order.';

  @override
  String get droneErrNoReview =>
      'The order\'s policy doesn\'t allow requesting a review of the resolution.';

  @override
  String get droneErrAlreadyResponded =>
      'This proposal has already been answered. Please reload.';

  @override
  String get droneErrNoProposal =>
      'There\'s no proposal waiting for your response.';

  @override
  String get droneErrInvalidChoice => 'Invalid choice.';

  @override
  String get droneErrRecipientLookup =>
      'Couldn\'t look up the recipient. Please try again later.';

  @override
  String get droneNoPermission =>
      'You don\'t have permission to view this drone order. Only the sender and recipient can track it.';

  @override
  String get droneStatusLoadFailedRetrying =>
      'Couldn\'t load the delivery status. Retrying...';

  @override
  String get dronePickupCodeNotSupported =>
      'The server doesn\'t support looking up the pickup code in the app yet. Use the PIN sent by notification, email or SMS.';

  @override
  String get droneTrackingDisabled =>
      'Drone delivery tracking is temporarily disabled.';

  @override
  String get droneStatusLoadFailed => 'Couldn\'t load the delivery status.';

  @override
  String get ddTlPayment => 'Payment';

  @override
  String get ddTlParcelDropped => 'Parcel placed in sending compartment';

  @override
  String get ddTlHomePickup => 'Pickup at the sender\'s home';

  @override
  String get ddTlLoaded => 'Loaded onto the drone';

  @override
  String get ddTlReady => 'Ready to launch';

  @override
  String get ddTlCodeSent => 'Code sent to the recipient';

  @override
  String get ddTlPickupDeadline => 'Pickup deadline';

  @override
  String get ddTlReceived => 'Recipient picked up';

  @override
  String get ddProgress => 'Delivery progress';

  @override
  String get ddClosedTitle => 'Drone order closed';

  @override
  String get ddClosedBody =>
      'The flight wasn\'t completed, so this order is closed; see the resolution in the order\'s incident section.';

  @override
  String get ddAwaitingPaymentTitle => 'Awaiting payment';

  @override
  String get ddAwaitingPaymentBody =>
      'Once paid, the system will find a drone technician to collect the parcel';

  @override
  String get ddAwaitingTeamTitle => 'Awaiting the flight team';

  @override
  String get ddAwaitingTeamBody =>
      'The parcel is ready at the Lock.R station, waiting for a drone technician to load and launch it';

  @override
  String get ddReadyBody =>
      'The parcel is loaded and sealed on the drone, waiting for the flight team to launch';

  @override
  String ddAboutMinutesLeft(Object minutes) {
    return 'About $minutes min left';
  }

  @override
  String ddSince(Object time) {
    return 'Since $time';
  }

  @override
  String ddOverdueAt(Object deadline, Object policy) {
    return 'The pickup deadline passed at $deadline. $policy';
  }

  @override
  String ddPickupDeadline(Object deadline, Object hours) {
    return 'Recipient pickup deadline: $deadline (stored for $hours hours).';
  }

  @override
  String get ddFlightIncompleteClosed =>
      'The flight wasn\'t completed, so this order is closed. See the resolution (redelivery or compensation) in the order\'s incident section.';

  @override
  String get ddUnpaidSearch =>
      'The order is unpaid. Once paid, the system will start looking for a drone technician to collect it.';

  @override
  String ddAt(Object time) {
    return 'At: $time';
  }

  @override
  String ddReason(Object reason) {
    return 'Reason: $reason';
  }

  @override
  String ddNoteValue(Object note) {
    return 'Note: $note';
  }

  @override
  String ddTicket(Object id) {
    return 'Incident ticket: #$id';
  }

  @override
  String get ddParcelWithSender =>
      'The parcel hasn\'t been collected and is still with the sender.';

  @override
  String get ddRefundRecorded =>
      'The refund request has been recorded. An admin will transfer it to the orderer\'s bank account.';

  @override
  String get ddRefundDone => 'The refund has been transferred to the orderer.';

  @override
  String get ddRefundByIncident =>
      'The amount paid is handled under the incident resolution: free redelivery or compensation transferred to the linked bank account.';

  @override
  String get ddRefundNotRecorded =>
      'No refund request was recorded — please contact support.';

  @override
  String ddWeightOver(Object actual, Object expected) {
    return 'The parcel actually weighs $actual, more than the declared $expected.';
  }

  @override
  String ddSurchargeOperator(Object amount) {
    return 'Waiting for the customer to pay an extra $amount before launching.';
  }

  @override
  String ddSurchargeReceiver(Object amount) {
    return 'Waiting for the sender to pay an extra $amount for the drone to take off.';
  }

  @override
  String ddSurchargeSender(Object amount) {
    return 'You need to pay an extra $amount for the drone to take off. If you don\'t agree, you can cancel: what you paid will be refunded and the flight team will return the parcel.';
  }

  @override
  String get ddUnpaidOperator =>
      'The customer hasn\'t paid. It can only be accepted once paid.';

  @override
  String get ddUnpaidReceiver =>
      'The sender hasn\'t paid yet. The flight team will accept it once the sender pays.';

  @override
  String get ddUnpaidSender =>
      'The order is unpaid. The flight team will only accept it after you pay.';

  @override
  String get ddPaySurcharge => 'Pay the difference';

  @override
  String get ddPayNow => 'Pay now';

  @override
  String get ddDeclineSurcharge => 'Decline · cancel and get a refund';

  @override
  String ddIncidentLabel(Object label) {
    return 'The order has an incident: $label';
  }

  @override
  String ddFromTime(Object time) {
    return 'Since: $time';
  }

  @override
  String ddAutoCloseOperator(Object time) {
    return 'If not fixed before $time, the order automatically ends as \"delivery not completed\" and the customer is refunded.';
  }

  @override
  String ddAutoCloseCustomer(Object time) {
    return 'If it isn\'t fixed before $time, the order will end and you\'ll be refunded.';
  }

  @override
  String get ddChangePlan =>
      'Change the plan or confirm the delivery as not completed.';

  @override
  String get ddTeamHandling => 'The flight team is handling it.';

  @override
  String ddPickedUp(Object at) {
    return 'Collected$at';
  }

  @override
  String ddPickedUpAt(Object time) {
    return ' at $time';
  }

  @override
  String get ddTechnician => 'Technician';

  @override
  String get ddYouHeadingToPickup => 'You\'re on your way to collect';

  @override
  String ddTechHeadingToPickup(Object who) {
    return '$who is on the way to collect';
  }

  @override
  String get ddYouAreInvited => 'You\'ve been invited to collect';

  @override
  String get ddSearchingTech => 'Looking for the nearest drone technician';

  @override
  String get ddAwaitingDispatchPickup => 'Awaiting pickup dispatch';

  @override
  String get ddTechAfterPayment =>
      'A technician will collect the parcel after the order is paid';

  @override
  String get ddHomePickup => 'Home pickup';

  @override
  String get ddPickupCode => 'Pickup code';

  @override
  String get ddPickupCodeHint =>
      'Read this code to the technician when handing over the parcel. Don\'t share it with anyone else.';

  @override
  String get ddPickupPoint => 'Pickup point';

  @override
  String get ddDirections => 'Instructions';

  @override
  String get ddTechPhone => 'Technician phone';

  @override
  String get ddDistanceAtAccept => 'Distance when accepted';

  @override
  String get ddPickupToSource => 'Pickup point → sending locker';

  @override
  String get ddPickupNote => 'Pickup note';

  @override
  String get ddPickupPhoto => 'Parcel photo at pickup';

  @override
  String ddPhotoTakenAt(Object time) {
    return 'Taken at $time';
  }

  @override
  String get ddDroneBoxAtSource =>
      'the drone compartment at the sending locker';

  @override
  String ddDroneBoxNumberAtSource(Object box) {
    return 'drone compartment $box at the sending locker';
  }

  @override
  String ddSenderNotDroppedOperator(Object where) {
    return 'The sender hasn\'t confirmed placing the parcel in $where. It can only be accepted once the parcel is inside.';
  }

  @override
  String ddWaitingSenderDrop(Object where) {
    return 'Waiting for the sender to place the parcel in $where.';
  }

  @override
  String ddDropThenConfirm(Object where) {
    return 'Place the parcel in $where and confirm below. The flight team only accepts the order after you confirm.';
  }

  @override
  String get ddIDropped => 'I\'ve placed the parcel';

  @override
  String ddParcelReturnedAt(Object time) {
    return 'The parcel was returned to the sender at $time.';
  }

  @override
  String get ddParcelInBoxOperator =>
      'The parcel is still in the sending compartment. Take it out, return it to the sender, then confirm.';

  @override
  String get ddParcelWithTeamOperator =>
      'The flight team is holding the parcel. Return it to the sender, then confirm.';

  @override
  String get ddParcelInBoxCustomer =>
      'Your parcel is still in the sending compartment. The flight team will contact you to return it.';

  @override
  String ddParcelHeldByTech(Object where) {
    return 'The technician is holding the parcel and will bring it back$where.';
  }

  @override
  String get ddToSender => ' to the sender';

  @override
  String ddAtAddress(Object address) {
    return ' at $address';
  }

  @override
  String get ddCancelOrder => 'Cancel order';

  @override
  String get ddCancelAllowed =>
      'You can cancel the order until the flight team accepts it.';

  @override
  String get ddRoute => 'Delivery route';

  @override
  String get ddSystemPickedStation =>
      'Flight locker chosen by the system (the technician loads the parcel directly onto the drone)';

  @override
  String ddLegacyBox(Object box) {
    return 'Older order: the parcel was placed in compartment $box';
  }

  @override
  String ddSentAt(Object time) {
    return 'Sent at: $time';
  }

  @override
  String get ddNotSentYet => 'Not sent yet';

  @override
  String get ddDirectionsToDrone =>
      'Directions to the drone at the flight locker';

  @override
  String get ddReceiverLockerOperator =>
      'Receiving locker chosen by the customer (recipient picks up)';

  @override
  String get ddReceiverLockerCustomer =>
      'Receiving locker you chose (recipient picks up)';

  @override
  String ddReceiveBox(Object box) {
    return 'Receiving compartment $box';
  }

  @override
  String ddDepositedAt(Object time) {
    return 'In the locker at: $time';
  }

  @override
  String get ddNotArrived => 'Not yet';

  @override
  String ddCodeSentAt(Object time) {
    return 'Code sent to the recipient at: $time';
  }

  @override
  String ddReceivedAt(Object time) {
    return 'Recipient picked up at: $time';
  }

  @override
  String get ddNotReceived => 'Not picked up';

  @override
  String get ddDirectionsToReceiver => 'Directions to the receiving locker';

  @override
  String get ddLockerNoAddress =>
      'This locker has no address or coordinates for directions.';

  @override
  String get ddCantOpenMaps => 'Couldn\'t open a maps app on this device.';

  @override
  String get ddOrderInfo => 'Order information';

  @override
  String get ddOrderCode => 'Order code';

  @override
  String get ddOrderStatus => 'Order status';

  @override
  String get ddPausedDrop => 'Paused due to a parcel drop';

  @override
  String get ddDroneFee => 'Drone delivery fee';

  @override
  String get ddWeightSurcharge => 'Of which weight surcharge';

  @override
  String ddDiscountCodeValue(Object code) {
    return 'Discount code $code';
  }

  @override
  String ddUsePoints(Object points) {
    return 'Used $points points';
  }

  @override
  String get ddAmountPaid => 'Amount paid';

  @override
  String get ddMethod => 'Method';

  @override
  String get ddPaymentRef => 'Payment reference';

  @override
  String get ddBoxAtLocker => 'Receiving compartment';

  @override
  String get ddDeclaredWeight => 'Declared weight';

  @override
  String get ddParcelSize => 'Parcel dimensions';

  @override
  String get ddCaution => 'Caution';

  @override
  String get ddDroppedAtLabel => 'Placed in sending compartment at';

  @override
  String get ddTechReceivedAt => 'Technician collected at';

  @override
  String get ddParcelDescription => 'Parcel description';

  @override
  String get ddNoDescription => 'No description';

  @override
  String get ddFlightMode => 'Flight mode';

  @override
  String get ddPeople => 'People involved';

  @override
  String get ddDroneTech => 'Drone technician';

  @override
  String get ddNoTechYet => 'Not accepted yet';

  @override
  String get ddTechAccepted => 'Accepted';

  @override
  String get ddLoader => 'Loaded by';

  @override
  String get ddNotLoaded => 'Not loaded';

  @override
  String get ddLoaded => 'Loaded';

  @override
  String get ddNotChecked => 'Not checked';

  @override
  String get ddPass => 'Passed';

  @override
  String get ddFail => 'Failed';

  @override
  String get ddMissionRecord => 'Flight mission & loading record';

  @override
  String get ddMissionCode => 'Mission ID';

  @override
  String get ddNotAssigned => 'Not assigned';

  @override
  String get ddMissionStatus => 'Mission status';

  @override
  String get ddDronePosition => 'Current drone position';

  @override
  String get ddNoData => 'No data yet';

  @override
  String get ddActualWeight => 'Actual weight';

  @override
  String get ddSealCode => 'Seal code';

  @override
  String get ddNotSealed => 'Not sealed';

  @override
  String get ddParcelMatched => 'Correct parcel, correct order';

  @override
  String get ddPayloadSecured => 'Parcel secured';

  @override
  String get ddCompartmentLocked => 'Cargo bay locked';

  @override
  String get ddLoadingNote => 'Loading note';

  @override
  String get ddEvLoaded => 'Loaded onto the drone';

  @override
  String get ddEvCodeSent => 'Pickup code sent to the recipient';

  @override
  String get ddEvCreated => 'Drone order created';

  @override
  String get ddJourneyLog => 'Journey log · newest first';

  @override
  String get ddNoJourney => 'No journey events yet.';

  @override
  String get ddSystem => 'System';

  @override
  String get ddLockrStaff => 'Lock.R staff';

  @override
  String get ddNewest => 'Latest';

  @override
  String dbBoxTaken(Object box) {
    return '$box was just taken by someone else. Please choose another drone compartment.';
  }

  @override
  String get dbYourBox => 'The compartment you chose';

  @override
  String get dbCheckingBoxes => 'Checking drone compartments…';

  @override
  String get dbNoFreeBoxes => 'No free drone compartments';

  @override
  String get dbChooseBox =>
      'Choose the compartment the recipient will pick up from';

  @override
  String dbDistancePrefix(Object distance) {
    return '$distance away · ';
  }

  @override
  String get dbNoPad => 'No drone landing pad';

  @override
  String get dbNoCoordinates => 'Locker has no coordinates';

  @override
  String get dbCheckingBoxesShort => 'Checking drone compartments';

  @override
  String get dbOutOfBoxes => 'No free drone compartments';

  @override
  String dbFreeBoxes(Object count) {
    return '$count free drone compartments';
  }

  @override
  String dbEnterName(Object who) {
    return 'Enter the $who\'s name';
  }

  @override
  String dbInvalidPhone(Object who) {
    return 'The $who\'s phone number is invalid';
  }

  @override
  String dbInvalidEmail(Object who) {
    return 'The $who\'s email is invalid';
  }

  @override
  String get dbChoosePickup => 'Choose the pickup point';

  @override
  String get dbWhoSender => 'sender';

  @override
  String get dbWhoReceiver => 'recipient';

  @override
  String get dbChooseReceiverLocker => 'Choose the receiving locker';

  @override
  String get dbCheckingReceiverBoxes =>
      'Checking free drone compartments at the receiving locker, please wait a moment';

  @override
  String get dbReceiverFull =>
      'This receiving locker has no free drone compartments, please choose another';

  @override
  String get dbChooseReceiverBox =>
      'Choose a free drone compartment at the receiving locker';

  @override
  String get dbChooseCategory => 'Choose the parcel type';

  @override
  String get dbSizeAllOrNone =>
      'Enter the parcel\'s length, width and height (cm), or leave all three empty';

  @override
  String dbTooLarge(Object l, Object w, Object h) {
    return 'The parcel doesn\'t fit the drone bay (max $l × $w × $h cm)';
  }

  @override
  String dbMaxValue(Object amount) {
    return 'Drones only carry parcels worth up to $amount';
  }

  @override
  String get dbConfirmNoProhibited =>
      'You must confirm the parcel contains no items prohibited from flight';

  @override
  String get dbPaidByVoucher =>
      'The order was covered by your offer. The flight team will accept your order.';

  @override
  String dbCreatedNotPaid(Object error) {
    return 'The drone order was created but payment failed: $error';
  }

  @override
  String get dbTitle => 'Send by drone';

  @override
  String get dbIntro =>
      'After you book and pay, the nearest drone technician collects your parcel and takes it to the drone at the flight locker to load it directly (not into a compartment). The drone then flies to the receiving compartment you chose. The recipient picks up with an opening code sent by email.';

  @override
  String get dbSuspended =>
      'Drone delivery is temporarily suspended (weather or an operational incident). Please try again later.';

  @override
  String get dbPickupAt => 'Pick up at';

  @override
  String get dbTechInstructions => 'Instructions for the technician (optional)';

  @override
  String get dbTechInstructionsHint => 'Floor, gate, when you\'re home…';

  @override
  String get dbSenderName => 'Sender\'s full name *';

  @override
  String get dbSenderPhone => 'Sender\'s phone number *';

  @override
  String get dbSenderEmail => 'Sender\'s email *';

  @override
  String get dbReceiverName => 'Recipient\'s full name *';

  @override
  String get dbReceiverPhone => 'Recipient\'s phone number *';

  @override
  String get dbReceiverEmail => 'Recipient\'s email *';

  @override
  String get dbEmailInfo =>
      'When the drone launches, both sender and recipient get an email. When the parcel reaches the locker, the opening code is emailed to the recipient.';

  @override
  String get dbReceiverLockerField => 'Receiving locker *';

  @override
  String get dbLoadingLockers => 'Loading receiving lockers...';

  @override
  String get dbNoLockersInSystem => 'No lockers in the system yet';

  @override
  String get dbReceiverBoxField => 'Receiving drone compartment *';

  @override
  String dbFreeReceiverBoxes(Object count) {
    return 'Free drone compartments: $count';
  }

  @override
  String get dbChecking => 'checking…';

  @override
  String dbLockerCantReceive(Object reason) {
    return 'This locker can\'t receive drones: $reason';
  }

  @override
  String dbWeightField(Object max) {
    return 'Weight * (max $max per order)';
  }

  @override
  String dbWeightHint(Object tolerance) {
    return 'Choose a level equal to or above the real weight. The technician re-weighs it when loading: if it\'s more than $tolerance g over, you pay the difference before the drone flies; lighter parcels aren\'t refunded.';
  }

  @override
  String get dbCategoryField => 'Parcel type *';

  @override
  String get dbDescriptionField => 'Item description (optional)';

  @override
  String get dbLength => 'Length';

  @override
  String get dbWidth => 'Width';

  @override
  String dbSizeHint(Object size) {
    return 'Dimensions are optional. The drone bay fits up to $size cm.';
  }

  @override
  String get dbDeclaredValueField => 'Declared value (optional)';

  @override
  String dbDeclaredValueHint(Object amount) {
    return 'Used for compensation if the parcel is damaged or lost. Up to $amount.';
  }

  @override
  String get dbRouteAndFee => 'Route and fee';

  @override
  String dbAutoCancel(Object minutes) {
    return 'Unpaid orders are cancelled automatically after $minutes minutes.';
  }

  @override
  String get dbNoProhibitedCheckbox =>
      'I confirm the parcel contains no items prohibited from flight: loose batteries, liquids, flammable or explosive materials, or items banned by law. *';

  @override
  String dbCreateAndPay(Object amount) {
    return 'Create order and pay $amount';
  }

  @override
  String get dbCreateFree => 'Create order (fee fully covered by offer)';

  @override
  String dbLockerCodeOnly(Object locker) {
    return 'Locker-specific codes only work when the drone takes off from $locker.';
  }

  @override
  String get dbChoosePickupHint =>
      'Choose the pickup point * — use your current location or type/pin it on the map';

  @override
  String dbLatLngTap(Object lat, Object lng) {
    return 'Latitude $lat · longitude $lng · tap to change';
  }

  @override
  String get dbQuoteHint =>
      'Choose the pickup point and receiving locker to see the sending locker, distance and fee.';

  @override
  String get dbCalculatingRoute => 'Calculating route…';

  @override
  String dbSystemStation(Object locker) {
    return 'Flight locker chosen by the system: $locker';
  }

  @override
  String dbRouteSummary(Object pickup, Object route) {
    return 'The technician carries the parcel $pickup to the drone at the flight locker for direct loading · the drone flies $route to the receiving compartment';
  }

  @override
  String dbFeeValue(Object amount) {
    return 'Drone delivery fee: $amount';
  }

  @override
  String dbWind(Object speed) {
    return 'wind $speed km/h';
  }

  @override
  String dbGust(Object speed) {
    return 'gusts $speed km/h';
  }

  @override
  String dbRain(Object mm) {
    return 'rain $mm mm';
  }

  @override
  String dbUpdatedAt(Object time) {
    return 'Updated $time';
  }

  @override
  String dbSource(Object source) {
    return 'source $source';
  }

  @override
  String get dbWeatherOk => 'Route weather: Suitable';

  @override
  String get dbWeatherUnknown => 'Weather not confirmed';

  @override
  String get dbWeatherSuspended => 'Route weather: Flights paused';

  @override
  String get dbWeatherRefresh => 'Refresh weather';

  @override
  String dbWeatherWindow(Object minutes, Object locker) {
    return 'Forecast for the next $minutes minutes (expected delivery time) from pickup → $locker → receiving locker';
  }

  @override
  String dbWeatherOnlyWhenSafe(Object message) {
    return '$message Orders can only be placed when the weather is suitable for flying.';
  }

  @override
  String get dtTitle => 'Drone delivery tracking';

  @override
  String get dtCheckConnection => 'Please check your connection and try again.';

  @override
  String get dtConfirmDroppedTitle => 'Confirm parcel placed';

  @override
  String dtConfirmDroppedBody(Object where) {
    return 'Have you placed the parcel in $where and closed the door? The flight team will load it after you confirm.';
  }

  @override
  String get dtDropped => 'Placed';

  @override
  String get dtDroppedDone =>
      'Recorded. The flight team will accept your order.';

  @override
  String get dtCancelSurchargeTitle =>
      'Cancel because you decline the surcharge';

  @override
  String dtCancelSurchargeBody(Object code) {
    return 'Order $code will be cancelled. A refund request is recorded for what you paid and the flight team will contact you to return the parcel. This can\'t be undone.';
  }

  @override
  String get dtCancelledReturn =>
      'Order cancelled. The flight team will return the parcel to you.';

  @override
  String get dtMapSimulated => 'Track on map (simulated)';

  @override
  String get dtMap => 'Track on map';

  @override
  String get dtInLockerShare =>
      'The parcel is in the receiving locker. Open \"View order details\" to share the opening code with the recipient.';

  @override
  String get dtInLockerPickup =>
      'The parcel is in the receiving locker. Open the PIN to pick it up at the locker.';

  @override
  String get dtViewDetail => 'View order details';

  @override
  String get dtPickup => 'Pick up';

  @override
  String get dtOffline =>
      'Disconnected · retrying; the information below is from the last update';

  @override
  String get dtLive => 'Live · status refreshes automatically on changes';

  @override
  String get dtLoadFailed => 'Couldn\'t load the delivery status';

  @override
  String get rmNoCoordinates =>
      'The sending or receiving locker has no coordinates, so the route map can\'t be drawn.';

  @override
  String get rmZoomHint => 'Pinch or tap +/− to zoom; tap ⤢ for full screen.';

  @override
  String rmTotal(Object distance) {
    return 'Distance $distance';
  }

  @override
  String rmRemaining(Object distance) {
    return 'About $distance left';
  }

  @override
  String get rmLiveCoords =>
      'Coordinates update whenever the drone reports its position. Tap the coordinates to open Google Maps.';

  @override
  String get rmEstimatedCamera =>
      'The drone position is estimated from the current flight stage. See real flight data (GPS, battery, mode) in the camera panel above.';

  @override
  String rmEstimatedOpenMap(Object mode) {
    return 'The drone position is estimated from the current flight stage. Open \"Track on map\" to see the $mode position.';
  }

  @override
  String get rmSimulated => 'simulated';

  @override
  String get rmLive => 'live';

  @override
  String get rmEstimated =>
      'The drone position is estimated from the current flight stage.';

  @override
  String get rmZoomIn => 'Zoom in';

  @override
  String get rmZoomOut => 'Zoom out';

  @override
  String get rmFitRoute => 'Fit route';

  @override
  String get rmFullscreen => 'Full screen';

  @override
  String get rmRouteMap => 'Route map';

  @override
  String rmDroneSentAt(Object time, Object suffix) {
    return 'Drone reported at $time$suffix';
  }

  @override
  String get rmSimSuffix => ' · simulated';

  @override
  String get rmAtReceiver => 'At the receiving locker';

  @override
  String get rmSimByStage => 'Simulated by flight stage';

  @override
  String get rmTelemetry => 'From drone telemetry';

  @override
  String get rmEstimatedByStage => 'Estimated by flight stage';

  @override
  String get rmAtSourceNotLaunched => 'At the sending locker, not launched yet';

  @override
  String get plServiceOff => 'Location services are off. Please turn on GPS.';

  @override
  String get plDenied => 'Location permission was denied.';

  @override
  String get plDeniedForever =>
      'Location permission was permanently denied. Turn it back on in settings.';

  @override
  String get plNoLocation => 'Couldn\'t get your current location.';

  @override
  String get plNoLocationHint =>
      'Couldn\'t get your current location. Move to an open area or type an address to search.';

  @override
  String get plNoAddressForPoint =>
      'Couldn\'t find the address for this point. Please enter it below.';

  @override
  String get plMin3Chars =>
      'Enter at least 3 characters to search for an address.';

  @override
  String get plNotFound =>
      'Address not found. Try typing more precisely or tap the map to drop a pin.';

  @override
  String get plNoPoint => 'No pickup location chosen on the map.';

  @override
  String get plEnterAddress =>
      'Enter the pickup address (house number, street, ward…).';

  @override
  String get plTitle => 'Choose pickup point';

  @override
  String get plSearchHint => 'Type an address (house number, street, ward…)';

  @override
  String get plClear => 'Clear';

  @override
  String plTapToSeePin(Object lng) {
    return '$lng · tap to see the pin';
  }

  @override
  String get plCurrentLocation => 'Current location';

  @override
  String get plAddressField => 'Pickup address';

  @override
  String get plTapMapToPin => 'Tap the map to pin the pickup point';

  @override
  String plPinInfo(Object lat, Object lng) {
    return 'Latitude $lat · longitude $lng · the pin is used to check the service area; make sure it matches the address before confirming';
  }

  @override
  String get plPickupHere => 'Pick up here';

  @override
  String get psLoadFailed =>
      'Couldn\'t load the pickup code. Please try again.';

  @override
  String get psReceivingLocker => 'Receiving locker';

  @override
  String get psNotInQueue =>
      'This order isn\'t in your incoming list. It may have been picked up, or the pickup code was sent to another phone number.';

  @override
  String psDelegated(Object name) {
    return 'You delegated pickup of this order to $name, so the pickup code has moved to them.';
  }

  @override
  String get psSomeoneElse => 'someone else';

  @override
  String get psNotReady =>
      'The pickup code isn\'t ready yet. It will be available once the parcel is in the receiving compartment.';

  @override
  String get psPin => 'Compartment PIN';

  @override
  String get psEnterAtKiosk =>
      'Enter this code on the kiosk screen at the locker to open the compartment.';

  @override
  String get psReceiveBox => 'Receiving compartment';

  @override
  String get psPickupBefore => 'Pick up before';

  @override
  String ocPaidRefund(Object amount) {
    return 'The order is paid: $amount will be refunded by bank transfer after admin approval. Please check your refund bank account in Profile.';
  }

  @override
  String get ocDroneFee => 'the drone delivery fee';

  @override
  String get ocUnpaidNoFee => 'The order is unpaid, so there\'s no fee.';

  @override
  String get ocTitle => 'Cancel the drone delivery?';

  @override
  String ocBody(Object code, Object refund) {
    return 'Order $code will be cancelled and the held receiving compartment released. $refund';
  }

  @override
  String get ocRefundPending =>
      'Order cancelled. The refund request has been recorded and an admin will transfer it to you.';

  @override
  String get ocRefunded =>
      'Order cancelled. The refund has been transferred to you.';

  @override
  String get ocPaidNoRefund =>
      'Order cancelled. No refund request was recorded, please contact support.';

  @override
  String get ocCancelled => 'Order cancelled.';

  @override
  String get ocAlreadyAccepted =>
      'The flight team has accepted it, so the order can no longer be cancelled in the app.';

  @override
  String get ocOwnerOnly =>
      'Only the person who placed the order can cancel it.';

  @override
  String get lmTitleSimulated => 'Drone tracking · simulated';

  @override
  String lmSignalLost(Object time) {
    return 'Signal lost · position at $time';
  }

  @override
  String get lmConnecting => 'Connecting to the drone...';

  @override
  String get lmNoPosition => 'No drone position yet. Retrying...';

  @override
  String get lmOnTheWay => 'On the way to the receiving locker';

  @override
  String get lmAlmostThere => 'Almost there';

  @override
  String get lmEta => 'Expected arrival';

  @override
  String get lmSpeed => 'Speed';

  @override
  String get lmLiveSimulated => 'simulated · live updates';

  @override
  String get lmLiveUpdates => 'live updates';

  @override
  String get clCantOpenMaps => 'Couldn\'t open Google Maps.';

  @override
  String clCopied(Object coords) {
    return 'Copied coordinates $coords';
  }

  @override
  String clDronePosition(Object note) {
    return 'Drone position · $note';
  }

  @override
  String get clCopyCoords => 'Copy coordinates';

  @override
  String get clPickupPin => 'Pickup point pinned by the sender';

  @override
  String get clTechnician => 'Technician\'s position at the time';

  @override
  String get clSourceLocker => 'At the station/sending locker';

  @override
  String get clDroneGps => 'Drone position (GPS)';

  @override
  String get clDroneSim => 'Drone position (simulated)';

  @override
  String get clDestination => 'At the receiving locker';

  @override
  String get clAtEvent => 'Position when recorded';

  @override
  String get lpIntro =>
      'Choose the receiving locker (sorted by distance). The system picks the flight locker and a technician collects the parcel from your home.';

  @override
  String lpLoadFailed(Object error) {
    return 'Couldn\'t load lockers: $error';
  }

  @override
  String get lpNoLockers => 'No lockers in the system yet.';

  @override
  String lpDistance(Object distance) {
    return '$distance away';
  }

  @override
  String get lpChecking => 'Checking drone compartments';

  @override
  String lpFreeSlots(Object count) {
    return '$count free drone compartments';
  }

  @override
  String lpUnavailable(Object reason) {
    return 'Drone delivery unavailable: $reason';
  }

  @override
  String get asTitle => 'The drone is almost there';

  @override
  String get asPrepare => 'Please get ready to collect your parcel.';

  @override
  String asDroneCode(Object code) {
    return '\nDrone code: $code';
  }

  @override
  String asEta(Object eta) {
    return 'Expected: $eta';
  }

  @override
  String get opPaid => 'Paid. The flight team will accept your order.';

  @override
  String get opPending =>
      'Waiting for payment confirmation; the status will update automatically.';

  @override
  String get opFailed =>
      'Payment didn\'t go through. The order is kept and you can pay again.';

  @override
  String get opUnpaid =>
      'The drone order is unpaid. Pay so the flight team can accept it.';

  @override
  String tlMovedAfter(Object duration) {
    return 'Moved after $duration';
  }

  @override
  String tlInStageFor(Object duration) {
    return 'In this stage for $duration';
  }

  @override
  String get tlNotYet => 'Not yet';

  @override
  String get rbChooseBank => 'Please choose a bank';

  @override
  String get rbSaved => 'Refund bank account saved';

  @override
  String get rbSaveFailed =>
      'Couldn\'t save the details. Please check them again';

  @override
  String get rbOneTimeSetup => 'One-time setup';

  @override
  String get rbIntro =>
      'Refunds are transferred directly to this account when an order has a problem (stuck locker, cancelled drone, laundry issue...). You won\'t need to enter it again.';

  @override
  String get rbBeneficiaryBank => 'Beneficiary bank';

  @override
  String get rbChooseBankShort => 'Choose a bank';

  @override
  String get rbAccountNumber => 'Bank account number';

  @override
  String get rbAccountNumberHint => 'Enter your account number';

  @override
  String get rbEnterAccountNumber => 'Please enter the account number';

  @override
  String get rbInvalidAccountNumber => 'Invalid account number';

  @override
  String get rbHolderName => 'Account holder\'s full name';

  @override
  String get rbHolderHint => 'E.g. JOHN SMITH';

  @override
  String get rbEnterHolder => 'Please enter the account holder\'s name';

  @override
  String get rbUpdate => 'Update account';

  @override
  String get rbSave => 'Save refund account';

  @override
  String get rbSearchHint => 'Search by bank name or code...';

  @override
  String rfCantPickImage(Object error) {
    return 'Couldn\'t pick the image: $error';
  }

  @override
  String get rfChooseOrder => 'Please choose the order to refund';

  @override
  String get rfInvalidOrder => 'Invalid order code';

  @override
  String get rfEnterReason => 'Please enter the reason for the refund';

  @override
  String get rfEnterBank => 'Please fill in the receiving bank account details';

  @override
  String get rfSending => 'Sending refund request...';

  @override
  String get rfSent => 'Refund request sent!';

  @override
  String rfError(Object message) {
    return 'Error: $message';
  }

  @override
  String get rfSubtitle => 'Manage and create refund requests for orders';

  @override
  String get rfMyRequests => 'My requests';

  @override
  String get rfNewRequest => 'New request';

  @override
  String get rfEmptyRecent => 'No refund requests in the last 7 days.';

  @override
  String get rfEmptyPending => 'No pending refund requests.';

  @override
  String get rfEmptyCompleted => 'No refunds have been transferred yet.';

  @override
  String get rfEmptyRejected => 'No rejected refund requests.';

  @override
  String get rfEmptyCanceled => 'No cancelled refund requests.';

  @override
  String get rfEmptyHint =>
      'You can create a new refund request from the next tab.';

  @override
  String get rfNone => 'No refund requests yet';

  @override
  String get rfNoneHint =>
      'If a locker won\'t open, a drone flight is cancelled or there\'s a laundry issue, you can request a refund here.';

  @override
  String get rfCreateNow => 'Request a refund now';

  @override
  String get rfNoneShort => 'No refund requests yet';

  @override
  String get rfNoMatch => 'No matching requests';

  @override
  String rfTicketHash(Object id) {
    return 'Refund ticket #$id';
  }

  @override
  String get rfSentAt => 'Submitted at';

  @override
  String get rfHasTransferSlip => 'Transfer slip';

  @override
  String get rfHasPhoto => 'Photo';

  @override
  String get rfViewDetail => 'View details';

  @override
  String get rfDetailSubtitle => 'Request details & transfer information';

  @override
  String get rfTransferDone => 'Transfer completed successfully';

  @override
  String get rfRejectedTitle => 'The refund request was rejected';

  @override
  String get rfAwaitingAdmin =>
      'Waiting for an admin to reconcile and transfer';

  @override
  String get rfInfo => 'Refund information';

  @override
  String get rfOrderCodeCopied => 'Order code copied';

  @override
  String get rfAccountHolder => 'Account holder';

  @override
  String get rfReason => 'Refund reason';

  @override
  String get rfTransferId => 'Transfer ID';

  @override
  String get rfTransferIdCopied => 'Transaction ID copied';

  @override
  String get rfRejectReason => 'Rejection reason';

  @override
  String get rfEvidence => 'Documents & evidence photos';

  @override
  String get rfYourPhotos => 'Evidence photos you sent:';

  @override
  String get rfAdminSlip => 'Admin transfer receipt (slip):';

  @override
  String get rfChooseOrderTitle => 'Choose the order to refund';

  @override
  String get rfTapToChooseOrder => 'Tap here to choose an order';

  @override
  String get rfChoosePaidOrder => 'Choose the paid order you want refunded';

  @override
  String rfOrderValue(Object code) {
    return 'Order: $code';
  }

  @override
  String get rfAmountLabel => 'Amount: ';

  @override
  String get rfChange => 'Change';

  @override
  String get rfChoose => 'Choose';

  @override
  String get rfSavedDefault => 'Saved as default';

  @override
  String get rfChooseReceivingBank => 'Choose the receiving bank';

  @override
  String get rfAccountNumberField => 'Receiving account number';

  @override
  String get rfAccountNumberHint => 'Enter account number';

  @override
  String get rfHolderField => 'Account holder name (uppercase, no accents)';

  @override
  String get rfSaveAsDefault => 'Save as default refund account';

  @override
  String get rfReasonTitle => 'Reason for the refund';

  @override
  String get rfQuickStuck => 'Stuck compartment';

  @override
  String get rfQuickDroneCancel => 'Drone flight cancelled';

  @override
  String get rfQuickDoubleCharge => 'Charged twice by the payment gateway';

  @override
  String get rfQuickLaundry => 'Laundry service issue';

  @override
  String get rfReasonHint => 'Describe the reason and the problem in detail...';

  @override
  String get rfEvidenceOptional => 'Evidence photos (optional)';

  @override
  String get rfTakePhoto => 'Take photo';

  @override
  String get rfPickGallery => 'From gallery';

  @override
  String get rfChangePhoto => 'Change photo';

  @override
  String get rfExpectedAmount => 'Expected refund:';

  @override
  String get rfSubmit => 'Submit refund request';

  @override
  String get rfEvidenceDetail => 'Evidence photo details';

  @override
  String get rfRules => 'Refund rules';

  @override
  String get rfRulesIntro => 'Lock.R supports refunds in these cases:';

  @override
  String get rfRule1 =>
      '• A technical issue where the compartment won\'t open or the door is stuck > 30 minutes.';

  @override
  String get rfRule2 =>
      '• A drone delivery later than promised or a cancelled flight.';

  @override
  String get rfRule3 => '• The payment gateway charged twice (double billing).';

  @override
  String get rfRule4 => '• Goods/laundry damaged by the laundry partner.';

  @override
  String get rfProcessingTime => 'Processing time:';

  @override
  String get rfProcessingBody =>
      'An admin will reconcile and transfer within 24 working hours. You\'ll get a notification with the transfer slip right in the app.';

  @override
  String get rfNoOrders => 'No orders';

  @override
  String get rfSelected => '✓ Selected';

  @override
  String get rfChooseBeneficiary => 'Choose beneficiary bank';

  @override
  String get rfSearchBank => 'Search banks (code, name)...';

  @override
  String get bankUnknown =>
      'Couldn\'t identify the receiving bank. Please scan the QR code with your banking app.';

  @override
  String bankCantOpen(Object app) {
    return 'Couldn\'t open $app. It may not be installed — please scan the QR code with your banking app.';
  }

  @override
  String get bankTitle => 'Pay with banking app';

  @override
  String get bankIntro =>
      'Choose your banking app — the account number, amount and description are filled in, you just confirm.';

  @override
  String get bankSearch => 'Search banks';

  @override
  String get bankLoadFailed =>
      'Couldn\'t load the banking apps.\nYou can scan the QR code with your banking app.';

  @override
  String get bankNoMatch => 'No matching bank';

  @override
  String get simBusy => 'Simulating…';

  @override
  String get simButton => 'Simulate payment (test)';

  @override
  String get simFailed => 'Couldn\'t simulate';

  @override
  String get simTitle => 'Simulate a transfer';

  @override
  String get simBody =>
      'For testing only — no real money. Enter less than the amount due to test an underpayment.';

  @override
  String get simReceived => 'Amount received';

  @override
  String get simAction => 'Simulate';

  @override
  String get txSepay => 'SePay QR gateway';

  @override
  String get txVnpay => 'VNPay gateway';

  @override
  String get txMomo => 'MoMo wallet';

  @override
  String get txWithdraw => 'Withdrawal';

  @override
  String get txTitleTopup => 'Wallet top-up';

  @override
  String get txTitleWithdrawRefund => 'Withdrawal refunded';

  @override
  String get txTitleWithdraw => 'Withdrawal to bank account';

  @override
  String get txTitleRefund => 'Refund to wallet';

  @override
  String get txTitleAdjustPlus => 'Balance adjustment (credit)';

  @override
  String get txTitleAdjustMinus => 'Balance adjustment (debit)';

  @override
  String get txTitleOrderWallet => 'Order paid with wallet';

  @override
  String txTitleOrderVia(Object method) {
    return 'Order paid via $method';
  }

  @override
  String get txTitleIn => 'Money in';

  @override
  String get txTitleOut => 'Money out';

  @override
  String get txSvcLaundry => 'Laundry';

  @override
  String get txSvcOrder => 'Order payment';

  @override
  String get txSvcTopup => 'Wallet top-up';

  @override
  String get txSvcAdjust => 'Balance adjustment';

  @override
  String get txLoadFailed => 'Couldn\'t load your transaction history.';

  @override
  String get txHistory => 'Transaction history';

  @override
  String get txSubtitle => 'Your payments & spending';

  @override
  String get txStats => 'Spending stats';

  @override
  String get txThisMonth => 'This month';

  @override
  String get txThisYear => 'This year';

  @override
  String get txTotalSpent => 'Total spent';

  @override
  String get txTotalIn => 'Total in';

  @override
  String get txNet => 'Net change:';

  @override
  String get txByMethod => 'Totals by method';

  @override
  String get txByService => 'Breakdown by service';

  @override
  String get txMethod => 'Method';

  @override
  String get txSvcSmartRental => 'Smart locker rental';

  @override
  String get txSvcSend => 'Sending / delivery';

  @override
  String get txSvcLaundryLocker => 'Locker laundry';

  @override
  String get txSvcWithdrawBank => 'Withdrawal to bank';

  @override
  String get txSvcOtherOrder => 'Other order payments';

  @override
  String txCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
    );
    return '$_temp0';
  }

  @override
  String get txAllMethods => 'All methods';

  @override
  String get txSepayShort => 'SePay gateway';

  @override
  String get txFilterByMethod => 'Filter by payment method';

  @override
  String txAllCount(Object count) {
    return 'All ($count txns):';
  }

  @override
  String txFilterCount(Object label, Object count) {
    return '$label ($count txns):';
  }

  @override
  String get txLoading => 'Loading transaction history...';

  @override
  String get txNone => 'No transactions';

  @override
  String get txNoMatch => 'No transactions match the selected filter';

  @override
  String get txWithdrawRequest => 'Withdrawal request';

  @override
  String get txMethodLabel => 'Method';

  @override
  String get txType => 'Type';

  @override
  String get txDirection => 'Direction';

  @override
  String get txCredit => 'Credited to wallet';

  @override
  String get txDebit => 'Debited from wallet';

  @override
  String get txDirect => 'Paid directly via gateway';

  @override
  String get txId => 'Transaction ID';

  @override
  String get txBalanceAfter => 'Wallet balance after';

  @override
  String get commonUser => 'User';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonUpdateNow => 'Update now';

  @override
  String get reminderFieldEmail => 'an email';

  @override
  String get reminderFieldPhone => 'a phone number';

  @override
  String reminderMissing(Object fields) {
    return 'Your account doesn\'t have $fields yet.';
  }

  @override
  String get reminderTitle => 'Complete your account details';

  @override
  String reminderBody(Object missing) {
    return '$missing Add it to receive locker codes, order notifications and recover your account if needed.';
  }

  @override
  String reminderLater(Object days) {
    return 'Later (remind me in $days days)';
  }

  @override
  String loyEarn(Object order) {
    return 'Points earned for order$order';
  }

  @override
  String loyRedeem(Object order) {
    return 'Points used for order$order';
  }

  @override
  String loyRedeemRefund(Object order) {
    return 'Points returned for cancelled order$order';
  }

  @override
  String loyEarnReversal(Object order) {
    return 'Points reversed for refunded order$order';
  }

  @override
  String get loyVoucherExchange => 'Points redeemed for a voucher';

  @override
  String get loyVoucherRefund => 'Voucher points returned';

  @override
  String get loyExchange => 'Points redeemed';

  @override
  String get loyAdjustment => 'Points adjustment';

  @override
  String get loyChange => 'Points change';

  @override
  String get pwEnterCurrent => 'Please enter your current password';

  @override
  String get pwEnterNew => 'Please enter a new password';

  @override
  String pwMinLength(Object min) {
    return 'The new password must be at least $min characters';
  }

  @override
  String get pwSameAsCurrent =>
      'The new password must differ from the current one';

  @override
  String get pwConfirmMismatch => 'The confirmation password doesn\'t match';

  @override
  String get pwCurrentWrong => 'The current password is incorrect';

  @override
  String get pwChangeFailed => 'Password change failed. Please try again.';

  @override
  String nameMin(Object min) {
    return 'Full name must be at least $min characters';
  }

  @override
  String nameMax(Object max) {
    return 'Full name can\'t exceed $max characters';
  }

  @override
  String get nameLettersOnly => 'Full name may only contain letters and spaces';

  @override
  String get nameRealName => 'Please enter your real name';

  @override
  String get profErrPhoneUsed => 'This phone number is used by another account';

  @override
  String get profErrEmailUsed => 'This email is used by another account';

  @override
  String get profErrLoginUpdate =>
      'Couldn\'t update your login account, please try again';

  @override
  String get profErrUpdateFailed => 'Profile update failed. Please try again.';

  @override
  String avTooLarge(Object size) {
    return 'The image can\'t exceed 5MB (current size: ${size}MB)';
  }

  @override
  String avTooSmall(Object min, Object width, Object height) {
    return 'The image must be at least ${min}x${min}px (current size: ${width}x${height}px)';
  }

  @override
  String avTooBig(Object max, Object width, Object height) {
    return 'The image can\'t exceed ${max}x${max}px (current size: ${width}x${height}px)';
  }

  @override
  String get avUnknownFormat => 'Couldn\'t determine the file format';

  @override
  String get avFormats => 'Only JPG, PNG and WebP are supported';

  @override
  String get avNotFound => 'File not found';

  @override
  String avCantCheck(Object error) {
    return 'Couldn\'t check the file: $error';
  }

  @override
  String get pwStrengthEnter => 'Enter a password';

  @override
  String get pwStrengthWeak => 'Weak password';

  @override
  String get pwStrengthMedium => 'Medium password';

  @override
  String get pwStrengthStrong => 'Strong password';

  @override
  String get pwStrengthVeryStrong => 'Very strong password';

  @override
  String get pwMin8 => 'Password must be at least 8 characters';

  @override
  String get pwNeedUpper => 'Password must contain at least 1 uppercase letter';

  @override
  String get pwNeedLower => 'Password must contain at least 1 lowercase letter';

  @override
  String get pwNeedNumber => 'Password must contain at least 1 number';

  @override
  String get pwNeedSpecial =>
      'Password must contain at least 1 special character';

  @override
  String get pwConfirmNew => 'Please confirm the new password';

  @override
  String get pwConfirmNotMatch => 'The confirmation password doesn\'t match';

  @override
  String get pwReq8 => 'At least 8 characters';

  @override
  String get pwReqUpper => 'At least 1 uppercase letter';

  @override
  String get pwReqLower => 'At least 1 lowercase letter';

  @override
  String get pwReqNumber => 'At least 1 number';

  @override
  String get pwReqSpecial => 'At least 1 special character';

  @override
  String get loyInvalidData => 'Invalid reward points data';

  @override
  String get pwChangeNotSupported =>
      'The server doesn\'t support changing the password from the app yet. Please try again later.';

  @override
  String get avWaitSync => 'Please wait for syncing to finish';

  @override
  String get avChooseAvatar => 'Choose a profile photo';

  @override
  String get avEditAvatar => 'Edit profile photo';

  @override
  String get avCamera => 'the camera';

  @override
  String get avGallery => 'the photo gallery';

  @override
  String avCantAccess(Object source) {
    return 'Couldn\'t access $source. Please grant permission in settings.';
  }

  @override
  String get avSelected =>
      'Photo selected. Tap \"Save profile photo\" to update.';

  @override
  String get avNothingToUpload => 'No photo to upload';

  @override
  String get avNoAccount =>
      'Couldn\'t identify the account to update the profile photo';

  @override
  String get avInvalid => 'Invalid image';

  @override
  String get avUpdated => 'Profile photo updated!';

  @override
  String get avCancelled => 'Profile photo change cancelled';

  @override
  String get avChooseSource => 'Choose photo source';

  @override
  String get avLibrary => 'Gallery';

  @override
  String get avUploading => 'Uploading';

  @override
  String avProgress(Object percent) {
    return '$percent complete';
  }

  @override
  String get avPleaseWait => 'Please wait a moment';

  @override
  String get epUpdated => 'Updated successfully!';

  @override
  String get epSaveFailed => 'Couldn\'t save your profile';

  @override
  String get epTakePhoto => 'Take photo';

  @override
  String get epFromGallery => 'Choose from gallery';

  @override
  String get epRemoveAvatar => 'Remove profile photo';

  @override
  String get epNoAccountPhoto =>
      'Couldn\'t identify the account to update the photo';

  @override
  String get epUpdatingAvatar => 'Updating profile photo...';

  @override
  String get epAvatarUpdated => 'Profile photo updated';

  @override
  String get epRemoveQuestion => 'Remove profile photo?';

  @override
  String get epRemoveBody =>
      'The current profile photo will be removed from your account.';

  @override
  String get epRemoving => 'Removing profile photo...';

  @override
  String get epRemoved => 'Profile photo removed';

  @override
  String get epTitle => 'Edit profile';

  @override
  String get epSubtitle => 'Update your account details';

  @override
  String get epNameHint => 'Enter your full name';

  @override
  String get epPhoneHint => 'Enter your phone number';

  @override
  String get epInvalidPhone => 'Invalid phone number';

  @override
  String get epEmailHint => 'Enter your email';

  @override
  String get epLoginInfoNote =>
      'Changing your phone number or email also changes your login details.';

  @override
  String get frSuccess => 'Face registered successfully';

  @override
  String get frFailed => 'Registration failed';

  @override
  String get frNoCamera => 'No camera found on this device.';

  @override
  String get frCantOpenCamera =>
      'Couldn\'t open the camera. Please check permissions.';

  @override
  String get frNoUser => 'User information not found';

  @override
  String frCaptureError(Object error) {
    return 'Error while capturing and registering: $error';
  }

  @override
  String get frSample => 'Face sampling';

  @override
  String get frHoldPhone =>
      'Hold the phone straight in front of your face and tap the button below to start.';

  @override
  String frCapturing(Object count, Object total) {
    return 'Capturing: $count/$total';
  }

  @override
  String get frProcessing => 'Processing registration...';

  @override
  String get frStartScan => 'Start scan';

  @override
  String get fvSuccess => 'FaceID verified';

  @override
  String fvMatched(Object id) {
    return 'Recognized ID: $id';
  }

  @override
  String get fvFailedRetry => 'Couldn\'t verify FaceID. Please try again.';

  @override
  String get fvCameraError =>
      'Couldn\'t open the camera or take the verification photo.';

  @override
  String get fvFailed => 'Verification failed';

  @override
  String get fvUsePassword => 'Use password';

  @override
  String get fvVerifying => 'Verifying...';

  @override
  String get fvLookStraight =>
      'Please look straight at the camera and hold the phone still so the system can recognize your face.';

  @override
  String get fvNotSupported => 'Face login isn\'t supported yet.';

  @override
  String get locChecking => 'Checking...';

  @override
  String get locServiceOff => 'Device location is off';

  @override
  String get locGranted => 'Location permission granted';

  @override
  String get locNotGranted => 'Location permission not granted';

  @override
  String get locDenied => 'Location permission denied';

  @override
  String get locCantOpenSettings =>
      'Couldn\'t open settings. Go to device Settings → Apps → Lock.R → Permissions to turn on Location.';

  @override
  String get locCantOpenLocationSettings =>
      'Couldn\'t open the device\'s location settings.';

  @override
  String get locSubtitle => 'The app\'s location permission';

  @override
  String get locAlways => 'The app can use your location at any time.';

  @override
  String get locWhileInUse => 'The app can use your location while it\'s open.';

  @override
  String get locTurnOnGps =>
      'Turn on Location (GPS) in your device settings so the app can get your location.';

  @override
  String get locGrantToFind =>
      'Grant permission to find lockers near you and get directions.';

  @override
  String get locBlocked =>
      'You\'ve blocked location permission. Open the app settings to turn it back on.';

  @override
  String get locRecheck => 'Check again';

  @override
  String get locGrant => 'Grant location permission';

  @override
  String get locOpenAppSettings => 'Open app settings';

  @override
  String get locTurnOn => 'Turn on location';

  @override
  String get locChangeInSettings => 'Change in system settings';

  @override
  String get locUsesFor => 'Lock.R uses your location to';

  @override
  String get locUseFind => 'Find stores / lockers near you';

  @override
  String get locUseDirections => 'Get directions to lockers';

  @override
  String get locUsePhotos =>
      'Tag photos with coordinates when reporting issues';

  @override
  String get loyHistoryNotSupported =>
      'The server doesn\'t support points history yet.';

  @override
  String get loyNotSupported =>
      'The server doesn\'t support reward points yet. Please try again later.';

  @override
  String get loySubtitle => 'Earn points when orders are completed';

  @override
  String get loyLoading => 'Loading reward points...';

  @override
  String get loyHistory => 'Points history';

  @override
  String get loyEmpty =>
      'No points activity yet. Points are added automatically when your orders are completed.';

  @override
  String get loyCurrent => 'Current points';

  @override
  String loyTier(Object tier) {
    return '$tier tier';
  }

  @override
  String get loyTopTier => 'You\'re at the top tier.';

  @override
  String loyToNext(Object points, Object tier) {
    return '$points points to reach $tier.';
  }

  @override
  String loyLifetime(Object points) {
    return 'Lifetime points: $points (used for tiers; spending points doesn\'t lower your tier)';
  }

  @override
  String get polLoadFailed => 'Couldn\'t load the content';

  @override
  String get polAgree => 'I agree to the terms of use';

  @override
  String get pdTitle => 'Personal information';

  @override
  String get pdSubtitle => 'Your account details';

  @override
  String get pdNoData => 'No data';

  @override
  String get pdStatusActive => 'Account status: Active';

  @override
  String get pdStatusInactive => 'Account status: Not activated';

  @override
  String get pdStatusLocked => 'Account status: Locked';

  @override
  String get pdDisabled =>
      'Your account is currently disabled. Please contact support.';

  @override
  String get pdYourEmail => 'Your email';

  @override
  String get pdNotUpdated => 'Not set';

  @override
  String get pdPasswordNotSet => 'Password (not set — tap to set)';

  @override
  String get pdNotSet => 'Not set';

  @override
  String get secNoBiometric =>
      'This device has no fingerprint/face registered in system settings.';

  @override
  String get secEnableReason => 'Authenticate to turn on app lock';

  @override
  String get secAuthFailed => 'Authentication failed';

  @override
  String get secLockOn => 'Biometric app lock turned on';

  @override
  String get secLockOff => 'Biometric app lock turned off';

  @override
  String get secPasswordSet => 'Password set';

  @override
  String get secPasswordChanged => 'Password changed';

  @override
  String get secSubtitle => 'Protect your account and device';

  @override
  String get secBiometricLock => 'Biometric app lock';

  @override
  String get secBiometricOn =>
      'Require fingerprint/face each time you open the app.';

  @override
  String get secBiometricUnavailable =>
      'No biometrics registered on this device.';

  @override
  String secLoadFailed(Object error) {
    return 'Couldn\'t load account details: $error';
  }

  @override
  String get secChangePassword => 'Change password';

  @override
  String get secSetPassword => 'Set password';

  @override
  String get secChangeHint =>
      'Enter your current and new password. Other devices will need to log in again.';

  @override
  String get secSetHint =>
      'Your account signs in with Google or OTP, so it has no password yet. Set one to log in with your email/phone number and password.';

  @override
  String get secCurrentPassword => 'Current password';

  @override
  String secMinChars(Object min) {
    return 'At least $min characters';
  }

  @override
  String get secConfirmNew => 'Confirm new password';

  @override
  String get profSaveFailedNetwork =>
      'Couldn\'t save. Check your network and try again.';

  @override
  String get phSyncing => 'Syncing...';

  @override
  String get phSaveAvatar => 'Save profile photo';

  @override
  String get tcTitle => 'Terms of service';

  @override
  String get tcBody =>
      'Before using Lock.R, please read and accept the Terms of service and Privacy policy. They cover locker rental, sending and receiving parcels, drone delivery, fees, refunds and compensation for incidents.';

  @override
  String get tcReadTerms => 'Read the Terms of service';

  @override
  String get tcReadPrivacy => 'Read the Privacy policy';

  @override
  String get tcAgreeCheckbox =>
      'I have read and agree to Lock.R\'s Terms of service and Privacy policy.';

  @override
  String get tcAgreeContinue => 'Agree and continue';

  @override
  String get qlNotConfirmed =>
      'The server didn\'t confirm the kiosk login. Please scan the code on the kiosk again.';

  @override
  String get qlExpired =>
      'The login code has expired. Generate a new one on the kiosk and scan again.';

  @override
  String get qlUsed =>
      'This login code has already been used. Generate a new one on the kiosk.';

  @override
  String get qlInvalid => 'The kiosk login code is invalid or no longer valid.';

  @override
  String get qlInactive =>
      'Your account is locked or not activated, so it can\'t log in on the kiosk.';

  @override
  String get qlSessionExpired =>
      'Your app session has expired. Please log in again and scan the code.';

  @override
  String get qlTooFast =>
      'Too many attempts. Please try again in a few minutes.';

  @override
  String get qlNoConnection =>
      'Couldn\'t reach the server. Check your network and try again.';

  @override
  String get qlNotSupported =>
      'The server doesn\'t support kiosk login by QR code yet. Please log in with your phone number on the kiosk.';

  @override
  String get aoChooseLocker => 'Please choose a locker.';

  @override
  String get aoEnterCode => 'Please enter the pickup code.';

  @override
  String get aoPickupBox => 'the pickup compartment';

  @override
  String get aoOpened =>
      'The compartment is open — take your parcel and close the door.';

  @override
  String aoOpenFailed(Object detail) {
    return 'Couldn\'t open the compartment$detail';
  }

  @override
  String get aoTitle => 'Delegated locker opening';

  @override
  String get aoSubtitle => 'Pick up with the code sent to you';

  @override
  String get aoIntro =>
      'Enter the pickup code (PIN) you received — it\'s under \"Delegated orders\" or was sent to you by the sender. You need to be at the locker to open the compartment.';

  @override
  String get aoOrder => 'Order';

  @override
  String get aoTapToChoose => 'Tap to choose the pickup locker';

  @override
  String get aoOpenBox => 'Open compartment to pick up';

  @override
  String get mdSubtitle => 'Orders others asked you to pick up';

  @override
  String get mdEmpty => 'No delegated orders yet';

  @override
  String get mdEmptyHint =>
      'When someone delegates a pickup to you (by your phone number), the order will appear here.';

  @override
  String get mdNotSupported =>
      'The server doesn\'t support Delegated orders yet. Please try again later.';

  @override
  String get dnTitleEnRoute => 'Drone delivering';

  @override
  String get dnTitleApproaching => 'Drone approaching';

  @override
  String get dnTitleArrived => 'Drone arrived';

  @override
  String get dnTitleDelivered => 'Delivered';

  @override
  String get dnTitleDelayed => 'Order delayed';

  @override
  String get dnTitleFailed => 'Delivery failed';

  @override
  String get dnTitleUpdate => 'Order update';

  @override
  String get dnBodyEnRoute => 'The drone is on its way with your parcel';

  @override
  String get dnBodyApproaching =>
      'The drone is almost there, please get ready to collect';

  @override
  String get dnBodyArrived =>
      'The drone has arrived, please collect your parcel';

  @override
  String get dnBodyDelivered => 'Delivered successfully. Thank you!';

  @override
  String dnBodyDelayedEta(Object eta) {
    return 'Your order is delayed, now expected in $eta';
  }

  @override
  String get dnBodyDelayed => 'Your order is running behind schedule';

  @override
  String get dnBodyFailed => 'Delivery failed, the drone is returning';

  @override
  String get dnBodyUpdate => 'Your order has a new update';

  @override
  String get nlSubtitle => 'Latest updates from Lock.R';

  @override
  String get nlLoginRequired => 'You need to log in to see notifications';

  @override
  String get nlReadAll => 'Mark all as read';

  @override
  String get nlLoading => 'Loading notifications...';

  @override
  String get nlAllSeen => 'You\'re all caught up';

  @override
  String get nlEmpty => 'No notifications yet';

  @override
  String get nlEmptyHint => 'New notifications will appear here';

  @override
  String get nlLoadFailed => 'Couldn\'t load notifications';

  @override
  String get nlDeleteAllQuestion => 'Delete all notifications?';

  @override
  String get nlDeleteAllBody =>
      'All notifications on your account will be deleted and can\'t be recovered.';

  @override
  String get nlDeleteAll => 'Delete all';

  @override
  String get nlDeletedAll => 'All notifications deleted';

  @override
  String get nlJustNow => 'Just now';

  @override
  String nlMinutesAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String nlHoursAgo(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String nlDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get npLoadFailed => 'Couldn\'t load notifications. Please try again.';

  @override
  String get npLoadMoreFailed =>
      'Couldn\'t load more notifications. Please try again.';

  @override
  String get npDeleteNotFound =>
      'Notification not found or the server doesn\'t support deleting yet.';

  @override
  String get npDeleteFailed =>
      'Couldn\'t delete the notification. Please try again.';

  @override
  String get npDeleteNotSupported =>
      'The server doesn\'t support deleting notifications yet. Please try again later.';

  @override
  String get crNoLockers => 'No lockers found to report.';

  @override
  String get crNetworkError => 'Network connection error';

  @override
  String get crSessionExpired =>
      'Your session has expired, please log in again.';

  @override
  String get crEnterTitle => 'Please enter a title';

  @override
  String get crEnterDescription => 'Please enter a detailed description';

  @override
  String get crChooseLocker => 'Please choose the affected locker';

  @override
  String get crAttachPhoto => 'Please attach at least 1 photo of the issue';

  @override
  String get crSending => 'Sending report...';

  @override
  String get crSent => 'Report sent';

  @override
  String crSendFailed(Object error) {
    return 'Couldn\'t send the report: $error';
  }

  @override
  String crFirstPhotosOnly(Object count, Object max) {
    return 'Only the first $count photos were added (max $max)';
  }

  @override
  String get crTitle => 'Report an issue';

  @override
  String get crTitleField => 'Title';

  @override
  String get crTitleHint => 'Enter a title for the issue';

  @override
  String get crDescriptionField => 'Detailed description';

  @override
  String get crDescriptionHint => 'Describe the problem clearly';

  @override
  String get crCancelOrList => 'Cancel / List';

  @override
  String get crBack => 'Back';

  @override
  String get crSubmit => 'Send report';

  @override
  String get crFaultyLocker => 'Faulty locker';

  @override
  String get crTapToChoose => 'Tap to choose the affected locker';

  @override
  String get crChooseBox => 'Choose the affected compartment ';

  @override
  String get crOptional => '(Optional)';

  @override
  String get crLayout => 'Layout';

  @override
  String get crCards => 'Cards';

  @override
  String get crDeselect => 'Deselect';

  @override
  String get crNoBoxes =>
      'No compartment list found, or the issue affects the whole station.';

  @override
  String crSelectedBox(Object number, Object type, Object status) {
    return 'Selected: Box #$number • $type • $status';
  }

  @override
  String get crDoorOpenWarning =>
      '⚠️ This compartment\'s door is currently OPEN in the system.';

  @override
  String get crSelectedKiosk =>
      'Selected: 7\" kiosk touchscreen (station-wide issue)';

  @override
  String get crKioskHint =>
      'Report a frozen/off screen, touch problems, or issues not tied to a specific compartment.';

  @override
  String get crKioskTitle => '7-inch kiosk touchscreen issue';

  @override
  String get crKioskScreen => 'Kiosk screen';

  @override
  String get crTapToReport => 'Tap to report';

  @override
  String get crSuitcaseBayUpper => 'LARGE SUITCASE BAY';

  @override
  String get crOpen => 'Open';

  @override
  String get crPhotos => 'On-site photos of the issue';

  @override
  String crPhotoCount(Object count) {
    return '$count photos';
  }

  @override
  String crPhotosHint(Object max) {
    return 'You can add several photos from the gallery at once or take them one by one with the camera (up to $max photos)';
  }

  @override
  String get crPickMany => 'Choose several photos';

  @override
  String get cdiLoadFailed => 'Couldn\'t load the order\'s incident details';

  @override
  String get cdiInProgress => 'The parcel drop incident is being handled';

  @override
  String get cdiResolved => 'The parcel drop incident has been resolved';

  @override
  String get cdiCode => 'Incident code';

  @override
  String get cdiRecovery => 'Parcel recovery';

  @override
  String get cdiParcelState => 'Parcel condition';

  @override
  String get cdiFieldNote => 'On-site note';

  @override
  String get cdiRecoveryPhotos => 'Parcel photos at recovery';

  @override
  String get cdiLastUpdate => 'Last update';

  @override
  String get cdiProposal => 'Proposed resolution';

  @override
  String cdiProposalVersion(Object version) {
    return ' (version $version)';
  }

  @override
  String cdiContent(Object note) {
    return 'Details: $note';
  }

  @override
  String get cdiPolicy =>
      'The incident policy at the time of your order applies';

  @override
  String get cdiNoBank => 'No bank account for compensation yet';

  @override
  String get cdiNoBankBody =>
      'The resolution includes a refund/compensation. Please link a bank account so the system can transfer it.';

  @override
  String get cdiUpdateBank => 'Update bank account';

  @override
  String get cdiSenderDecides =>
      'The sender will accept or request a review of this proposal.';

  @override
  String get cdiRequestReview => 'Request review';

  @override
  String get cdiAccept => 'Accept';

  @override
  String get cdiAcceptQuestion => 'Accept the proposal?';

  @override
  String get cdiReviewQuestion => 'Ask Lock.R to review it again?';

  @override
  String get cdiNoteOptional => 'Note (optional)';

  @override
  String get cdiReviewReason => 'Reason for review *';

  @override
  String get cdiEnterReason => 'Please enter the reason for the review.';

  @override
  String get cdiAccepted => 'Your choice has been recorded.';

  @override
  String get cdiReviewSent => 'Review request sent.';

  @override
  String cdiCompensation(Object amount) {
    return 'Compensation $amount';
  }

  @override
  String get cdiFreeRedelivery => 'free redelivery';

  @override
  String get cdiRefundShipping => 'shipping fee refunded';

  @override
  String get crSelectLocker => 'Please choose the affected locker.';

  @override
  String aiErrLength(Object max) {
    return 'Questions must be 1 to $max characters.';
  }

  @override
  String get aiErrBadResponse => 'Invalid response from the server.';

  @override
  String get aiErrGeneric => 'Something went wrong, please try again.';

  @override
  String get aiErrNotFound =>
      'Conversation not found; it may have been deleted.';

  @override
  String get aiErrLength2000 => 'Questions must be 1 to 2000 characters.';

  @override
  String get aiErrServer => 'Server error, please try again later.';

  @override
  String get aiErrConnectTimeout =>
      'The connection took too long, please try again.';

  @override
  String get aiErrReplyTimeout =>
      'The assistant took too long to reply, please try again.';

  @override
  String get aiErrNoConnection =>
      'Can\'t connect to the server. Check your network connection.';

  @override
  String get aiErrCancelled => 'Request cancelled.';

  @override
  String get aiErrSession => 'Your session has expired. Please log in again.';

  @override
  String get aiErrForbidden => 'You don\'t have access to the Q&A assistant.';

  @override
  String get aiErrRateLimit =>
      'You\'ve asked too many questions, please try again later.';

  @override
  String get aiErrBusy =>
      'The assistant is busy or having problems, please try again later.';

  @override
  String get aiDocument => 'Document';

  @override
  String get aiConversation => 'Conversation';

  @override
  String get aiEyebrow => 'LOCK.R • ASSISTANT';

  @override
  String get aiTitle => 'Q&A assistant';

  @override
  String get aiSubtitle => 'Answers from official documents, with sources';

  @override
  String get aiHistory => 'Q&A history';

  @override
  String get aiNewConversation => 'New conversation';

  @override
  String get aiDisabledTitle => 'The assistant is temporarily off';

  @override
  String get aiDisabledBody =>
      'The Q&A feature is temporarily off. Please come back later.';

  @override
  String get aiNotReadyTitle => 'The assistant isn\'t ready';

  @override
  String get aiNotReadyBody =>
      'The Q&A assistant isn\'t fully set up yet. Please come back later or contact Lock.R support.';

  @override
  String get aiWaiting => 'Waiting for the assistant…';

  @override
  String get aiInputHint => 'Type your question…';

  @override
  String get aiSend => 'Send question';

  @override
  String get aiDeleteQuestion => 'Delete conversation?';

  @override
  String aiDeleteBody(Object title) {
    return 'The conversation “$title” will be permanently deleted and can\'t be recovered.';
  }

  @override
  String get aiDeleted => 'Conversation deleted';

  @override
  String get aiHistorySubtitle => 'Your conversations with the assistant';

  @override
  String get aiNoConversations => 'No conversations yet';

  @override
  String get aiNoConversationsBody =>
      'Questions you ask the assistant are saved here to revisit.';

  @override
  String get aiAsk => 'Ask a question';

  @override
  String aiMessageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages',
      one: '1 message',
    );
    return '$_temp0';
  }

  @override
  String aiTodayAt(Object time) {
    return 'Today, $time';
  }

  @override
  String aiYesterdayAt(Object time) {
    return 'Yesterday, $time';
  }

  @override
  String get aiQTechInspection =>
      'What do I do if a periodic inspection fails?';

  @override
  String get aiQTechDoor =>
      'What should I check when a compartment reports a door error?';

  @override
  String get aiQTechTicket => 'What\'s the incident ticket process?';

  @override
  String get aiQTechIot =>
      'What do I do if the locker\'s IoT device disconnects?';

  @override
  String get aiQDroneLaunch => 'How are drone orders accepted and launched?';

  @override
  String get aiQDroneCancel => 'When can a mission be cancelled before flight?';

  @override
  String get aiQDronePad =>
      'What do I do if the drone landing pad reports an error?';

  @override
  String get aiQSend => 'How do I send a parcel via a locker?';

  @override
  String get aiQPay => 'How can I pay?';

  @override
  String get aiQRentEnd => 'What happens when my rental time runs out?';

  @override
  String get aiQCantOpen => 'What should I do if a compartment won\'t open?';

  @override
  String get aiDocsStaff => 'operating procedures, technical guides, policies';

  @override
  String get aiDocsCustomer => 'user guides, policies, FAQ';

  @override
  String get aiHello => 'Hi! I\'m the Lock.R assistant';

  @override
  String aiIntro(Object docs) {
    return 'I answer from Lock.R\'s official documents ($docs) and always cite my sources. If the documents don\'t cover something, I\'ll say so so you can contact support.';
  }

  @override
  String get aiOfficialDocs => 'Official documents';

  @override
  String get aiWithSources => 'With sources';

  @override
  String get aiYouCanAsk => 'You can ask';

  @override
  String get aiNotSent => 'Not sent';

  @override
  String get aiNotInDocs => 'Not in the documents';

  @override
  String get aiTyping => 'The assistant is replying';

  @override
  String aiSources(Object count) {
    return 'Sources ($count)';
  }

  @override
  String get aiCitationsUpper => 'SOURCE CITATIONS';

  @override
  String get aiNoExcerpt => 'No excerpt.';

  @override
  String get aiVerbatim => 'Quoted verbatim from Lock.R\'s official documents.';

  @override
  String get tagAccepted => '[ACCEPTED]';

  @override
  String get tagFieldNote => '[ON-SITE NOTE]';

  @override
  String get tagSlaExtended => '[SLA EXTENDED]';

  @override
  String get tagRepairProgress => '[REPAIR PROGRESS]';

  @override
  String get urdInspectionPhotos =>
      'The technician took on-site inspection photos.';

  @override
  String get urdProgressPhotos => 'The technician updated progress photos.';

  @override
  String urdSlaExtended(Object hours) {
    return 'The ticket was extended by $hours hours.';
  }

  @override
  String urdNewDeadline(Object time) {
    return '- New deadline: $time';
  }

  @override
  String urdReason(Object reason) {
    return '- Reason: $reason';
  }

  @override
  String get urdTechResolved => 'The technician resolved the ticket.';

  @override
  String get urdTechSentAcceptance => 'The technician sent acceptance photos.';

  @override
  String get urdKioskNoLocation => 'The kiosk station has no map location yet.';

  @override
  String get urdPhotosAdded => 'Photos added!';

  @override
  String get urdKioskStation => 'Kiosk station';

  @override
  String get urdRecordTitle => 'Technical incident ticket details';

  @override
  String urdCreatedAt(Object time) {
    return 'Created: $time';
  }

  @override
  String urdTechInCharge(Object name) {
    return 'Technician: $name';
  }

  @override
  String get urdDispatching => 'Assigning a technician';

  @override
  String urdResolvedAt(Object time) {
    return 'Resolved: $time';
  }

  @override
  String urdDeadline(Object time) {
    return 'Due: $time';
  }

  @override
  String urdBoxIncident(Object box) {
    return 'Compartment #$box incident';
  }

  @override
  String get urdKioskIncident => 'Kiosk station incident';

  @override
  String urdOrder(Object code) {
    return 'Order: $code';
  }

  @override
  String get urdDirectionsKiosk => 'Directions to the kiosk';

  @override
  String get urdCopyPhone => 'Copy phone number';

  @override
  String get urdPhoneCopied => 'Phone number copied';

  @override
  String get urdReportContent => 'Issue description:';

  @override
  String get urdMorePhotos => 'Add more photos';

  @override
  String get urdYourPhotos => 'On-site photos you sent';

  @override
  String get urdProgressTitle => 'Incident handling progress:';

  @override
  String get urdTeamResponse => 'Response from the technical team:';

  @override
  String urdTechId(Object id) {
    return 'Technician #$id';
  }

  @override
  String get urdDispatchingAccept => 'Assigning a technician to accept';

  @override
  String urdTechAcceptedAt(Object tech, Object time) {
    return '$tech · Accepted: $time';
  }

  @override
  String urdTechAccepted(Object tech) {
    return '$tech accepted the assignment';
  }

  @override
  String get urdTechInspected =>
      'The technician inspected and handled it on site';

  @override
  String urdHandledAt(Object time, Object desc) {
    return 'Handled at $time$desc';
  }

  @override
  String get urdCheckedHandled => 'Inspected & handled';

  @override
  String urdFixedAt(Object time) {
    return 'Fixed at $time';
  }

  @override
  String get urdFixed => 'Fully fixed';

  @override
  String get urdTechInspecting =>
      'The technician is inspecting and handling it on site';

  @override
  String get urdWaitingTech => 'Waiting for a technician to visit the kiosk';

  @override
  String urdClosedAt(Object time, Object feedback) {
    return 'Closed at $time$feedback';
  }

  @override
  String urdFeedback(Object text) {
    return 'Response: $text';
  }

  @override
  String get urdCheckedNormal =>
      'The technician checked it; the compartment works normally';

  @override
  String urdAcceptedAt(Object time, Object note) {
    return 'Accepted: $time$note';
  }

  @override
  String urdAcceptedDone(Object note) {
    return 'Accepted and completed$note';
  }

  @override
  String urdExpectedBy(Object time) {
    return 'Expected by: $time';
  }

  @override
  String get urdAwaitingAcceptance => 'Awaiting acceptance & closure';

  @override
  String urdSentAt(Object time) {
    return 'Sent: $time';
  }

  @override
  String get urdRecorded => 'The system recorded the incident';

  @override
  String get urdStepTechAccepts => 'Technician accepts';

  @override
  String get urdStepInspect => 'Inspect & handle at the kiosk';

  @override
  String get urdStepRejected => 'Technician didn\'t confirm the issue';

  @override
  String get urdStepAccept => 'Acceptance & closure';

  @override
  String get urdTechProgress => 'Technician\'s progress:';

  @override
  String get urdAcceptingTech => 'Accepting technician';

  @override
  String get urdNoTechNotes =>
      'The technician hasn\'t logged any steps yet. Their actions will appear here.';

  @override
  String get urdSlaApproval => 'SLA extension approval';

  @override
  String urdRepairPhotos(Object count) {
    return 'Repair photos ($count photos):';
  }

  @override
  String get urdKioskTech => 'Kiosk technician';

  @override
  String get urdCustomerView =>
      'Customer view · Technicians update the log & evidence in the mobile app';

  @override
  String urdSteps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count steps',
      one: '1 step',
    );
    return '$_temp0';
  }

  @override
  String get urdThanksRating => 'Thanks for your rating!';

  @override
  String urdRatingError(Object error) {
    return 'Couldn\'t send the rating: $error';
  }

  @override
  String get urdYourRating => 'Your rating of the technician';

  @override
  String get urdRateTech => 'Rate the technician\'s service';

  @override
  String urdComment(Object text) {
    return 'Comment: \"$text\"';
  }

  @override
  String get urdRatePrompt =>
      'The incident ticket is resolved. Please rate your satisfaction:';

  @override
  String get urdRateHint =>
      'Any comments on the technician\'s attitude or speed (optional)...';

  @override
  String get urdSendRating => 'Send rating';

  @override
  String get urdChoosePhoto => 'Please choose at least 1 photo.';

  @override
  String get urdAddPhotosTitle => 'Add incident photos';

  @override
  String urdAddPhotosHint(Object max) {
    return 'Up to $max photos at a time. Photos help the maintenance team bring the right parts.';
  }

  @override
  String get urdSendPhotos => 'Send photos';

  @override
  String get mrUnknownTime => 'Unknown time';

  @override
  String get mrAwaiting => 'Awaiting';

  @override
  String get mrNone => 'No reports yet';

  @override
  String get mrNoneHint =>
      'Issues reported from order details or the \"New report\" tab will appear here.';

  @override
  String get mrReportNow => 'Report an issue now';

  @override
  String get mrNoMatch => 'No matching reports';

  @override
  String mrNoMatchFilter(Object filter) {
    return 'No incident tickets match the \"$filter\" filter.';
  }

  @override
  String get mrViewAll => 'View all reports';

  @override
  String get mrEyebrow => 'LOCK.R • REPORTS';

  @override
  String get mrSubtitle => 'Track progress and report compartment issues';

  @override
  String get mrNewReport => 'New report';

  @override
  String mrTicketHash(Object id) {
    return 'Incident ticket #$id';
  }

  @override
  String get mrLockerPoint => 'Locker location';

  @override
  String get mrBox => 'Compartment';

  @override
  String get fbDamaged => 'Damaged goods';

  @override
  String get fbMissing => 'Missing / lost items';

  @override
  String get fbLocker => 'Locker / compartment issue';

  @override
  String get fbPayment => 'Payment / fees';

  @override
  String get fbService => 'Service quality';

  @override
  String get fbStPending => 'Pending';

  @override
  String get fbStProcessing => 'Processing';

  @override
  String get fbStResolved => 'Resolved';

  @override
  String get fbStRejected => 'Rejected';

  @override
  String get fbStRecorded => 'Recorded';

  @override
  String get fbRateOrder => 'Rate the order';

  @override
  String get fbRateHint => 'Share your experience (optional)';

  @override
  String get fbRateNotSupported =>
      'The server doesn\'t support order ratings yet.';

  @override
  String get fbThanks => 'Thanks for rating your order.';

  @override
  String get fbComplain => 'File a complaint';

  @override
  String get fbIssue => 'Issue';

  @override
  String get fbIssueHint => 'Describe the problem in detail';

  @override
  String get fbDescribe => 'Please describe the issue.';

  @override
  String get fbComplainNotSupported =>
      'The server doesn\'t support order complaints yet.';

  @override
  String get fbComplaintSent =>
      'Complaint sent — support will reply via notification.';

  @override
  String get fbRateAndComplain => 'Rating & complaints';

  @override
  String get fbComplaint => 'Complaint';

  @override
  String get fbEditRating => 'Edit rating';

  @override
  String fbSentAt(Object time) {
    return 'Sent at $time';
  }

  @override
  String get fbNotSupported =>
      'The server doesn\'t support order ratings / complaints yet. Please try again later.';

  @override
  String btBoxOccupied(Object box) {
    return 'Compartment $box has items';
  }

  @override
  String get btBoxOccupiedBody =>
      'This compartment holds an order\'s items. Only open it if you\'re assigned to inspect the locker, and close it right after testing.';

  @override
  String get btOpenAnyway => 'Open anyway';

  @override
  String get btFetchingCode => 'Getting the opening code from the server…';

  @override
  String get btScanning => 'Searching for the locker via Bluetooth…';

  @override
  String get btConnecting => 'Connecting to the locker…';

  @override
  String get btSending => 'Sending the open command…';

  @override
  String get btWaiting => 'Waiting for the locker to unlock…';

  @override
  String get btSubtitle =>
      'Stand next to the locker, choose a compartment and tap open';

  @override
  String get btChooseBox => 'Choose a compartment to open';

  @override
  String btOpenBox(Object box) {
    return 'Open compartment $box via Bluetooth';
  }

  @override
  String get btLoadFailed => 'Couldn\'t load lockers';

  @override
  String get btNotAllowed => 'Not allowed yet';

  @override
  String get btNotAllowedBody =>
      'An admin hasn\'t allowed this account to test Bluetooth opening at any locker.';

  @override
  String get btHint =>
      'Turn on Bluetooth and stand within 2 m of the locker. Every opening is recorded in the locker\'s log.';

  @override
  String get btChooseBoxLabel => 'Choose compartment';

  @override
  String btOpened(Object box) {
    return 'Opened compartment $box';
  }

  @override
  String get btNotOpened => 'Couldn\'t open';

  @override
  String get btCloseAfter => 'Remember to close the door after testing.';

  @override
  String get btNoBoxes => 'The locker has no compartments.';

  @override
  String btBox(Object number) {
    return 'Box $number';
  }

  @override
  String get apiErrValidation =>
      'The submitted data is invalid, please check it again.';

  @override
  String get apiErrInternal =>
      'The server had an error or doesn\'t support this action yet. Please try again later.';

  @override
  String get apiErrNotFound =>
      'Data not found (it may have been deleted or changed).';

  @override
  String get apiErrLockerServiceUnavailable =>
      'The locker service is temporarily unavailable, please try again later.';

  @override
  String get dbHeight => 'Height';

  @override
  String get commonView => 'View';

  @override
  String get ordFilterDrone => 'Drone delivery';

  @override
  String get recvDroneDelivery => 'Drone delivery';

  @override
  String get holderNameHint => 'JOHN SMITH';

  @override
  String techHomeScheduleNotFound(Object id) {
    return 'Inspection schedule #$id not found (it may have been deleted or belong to a locker you can\'t view).';
  }

  @override
  String techHomeLoadPartialFailed(Object details) {
    return 'Couldn\'t load all data: $details';
  }

  @override
  String get techHomeLogoutShiftTitle => 'Log out of shift';

  @override
  String get techHomeLogoutShiftConfirm =>
      'End your shift and log out of the locker technician account?';

  @override
  String get techHomeLockerTechnician => 'Locker technician';

  @override
  String get techHomePhoneNotSet => 'No phone number yet';

  @override
  String get techHomeLockerTechnicianRole =>
      'Locker technician (compartments & hardware)';

  @override
  String get techHomeStatReceived => 'Tickets taken';

  @override
  String get techHomeStatInProgress => 'In progress';

  @override
  String get techHomeQualityRatingLabel => 'Quality rating: ';

  @override
  String get techHomeNoRatingYet => 'No ratings yet';

  @override
  String get techHomeSlaPolicyLabel => 'SLA status: ';

  @override
  String get techHomeTechPhoneLabel => 'Technician phone: ';

  @override
  String get techHomeViewEditProfile => 'View & edit profile';

  @override
  String get techHomeSlaRestrictedTitle => 'New work restricted';

  @override
  String get techHomeSlaRestrictedBody =>
      'SLA policy: when your overdue tickets exceed the limit set by admins, you temporarily can\'t take new work. Go to the \"My work\" tab and finish your pending jobs.';

  @override
  String get techHomeViewMyWork => 'View my work';

  @override
  String get techHomeOpenTicket => 'Open ticket';

  @override
  String get techHomeBoxBackOnline => 'Compartment is back in service';

  @override
  String techHomeTicketLoadFailed(Object id) {
    return 'Couldn\'t load ticket RPT-$id';
  }

  @override
  String techHomeTicketAlreadyClosed(Object id) {
    return 'Ticket RPT-$id has been closed.';
  }

  @override
  String techHomeTicketHandledByOther(Object id, Object assignee) {
    return 'Ticket RPT-$id is being handled by $assignee — only the assignee can complete it.';
  }

  @override
  String techHomeTicketUnassignedTitle(Object id) {
    return 'Ticket RPT-$id is unassigned';
  }

  @override
  String get techHomeTicketUnassignedBody =>
      'This compartment/landing pad has an open incident ticket. Take the ticket, then do the acceptance (photos after repair) to bring it back into service.';

  @override
  String get techHomeClaimAndAccept => 'Take & accept';

  @override
  String get techHomeLockerNoLocation =>
      'This locker has no location for directions yet.';

  @override
  String get techHomeGreetingMorning => '☀️ Good morning';

  @override
  String get techHomeGreetingNoon => '🌤️ Good day';

  @override
  String get techHomeGreetingAfternoon => '🌅 Good afternoon';

  @override
  String get techHomeGreetingEvening => '🌙 Good evening';

  @override
  String techHomeSlaSuspended(Object count) {
    return 'SLA: Suspended ($count overdue)';
  }

  @override
  String techHomeSlaRestricted(Object count) {
    return 'SLA: Restricted ($count overdue)';
  }

  @override
  String techHomeSlaWarning(Object count) {
    return 'SLA: Warning ($count overdue)';
  }

  @override
  String techHomeSlaNormalWithCount(Object count) {
    return 'SLA: Normal ($count in progress)';
  }

  @override
  String get techHomeSlaNormal => 'SLA: Normal';

  @override
  String techHomeSlaUnknownWithOverdue(Object count) {
    return 'SLA: $count overdue · penalty level not loaded';
  }

  @override
  String get techHomeSlaUnknown => 'SLA: status not loaded';

  @override
  String get techHomeProfileAndEdit => 'Profile & edit';

  @override
  String get techHomeHudRoutine => 'Routine';

  @override
  String get techHomeHudStations => 'Stations';

  @override
  String get techHomeTabInspect => 'Inspect';

  @override
  String techHomeTabIncidents(Object count) {
    return 'Incidents ($count)';
  }

  @override
  String techHomeTabMyWork(Object count) {
    return 'My work ($count)';
  }

  @override
  String techHomeTabRoutine(Object count) {
    return 'Routine ($count)';
  }

  @override
  String techHomeTabIotDevices(Object count) {
    return 'IoT devices ($count)';
  }

  @override
  String techHomeTabParcelRecovery(Object count) {
    return 'Parcel recovery ($count)';
  }

  @override
  String techHomeRecoveryBannerTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dropped-parcel recovery tasks',
      one: '1 dropped-parcel recovery task',
    );
    return '$_temp0';
  }

  @override
  String get techHomeRecoveryBannerHint =>
      'Tap to open the \"Parcel recovery\" tab.';

  @override
  String get techHomePickLockerToInspect => 'Pick a locker to inspect';

  @override
  String get techHomeLockersLoadFailed => 'Couldn\'t load the locker list';

  @override
  String get techHomeNoLockers => 'No lockers yet';

  @override
  String techHomeLayoutLoadFailed(Object error) {
    return 'Couldn\'t load the locker layout: $error';
  }

  @override
  String get techHomeKioskPhysicalLayout => 'Kiosk station physical layout';

  @override
  String get techHomeTapBoxHint =>
      'Tap a compartment to report a fault, emergency-open it, or reopen it after repair.';

  @override
  String get techHomeWorkingWell => 'Working';

  @override
  String get techHomeDroneLandingPad => 'Drone landing pad';

  @override
  String techHomeTicketOpenPill(Object id) {
    return 'Ticket RPT-$id open';
  }

  @override
  String get techHomeLandingPadHint =>
      'Broken/Maintenance ⇒ opens a landing-pad ticket assigned to you. Back to \"Working\" with an open ticket ⇒ do the ticket acceptance (photos after repair).';

  @override
  String get techHomeLandingPadBackOnline => 'Landing pad is back in service';

  @override
  String techHomeLandingPadStatus(Object status) {
    return 'Landing pad: $status';
  }

  @override
  String techHomeLandingPadStatusTicketOpened(Object status) {
    return 'Landing pad: $status — an incident ticket was opened and assigned to you';
  }

  @override
  String get techHomeReasonLabel => 'Reason';

  @override
  String get techHomeLandingPadFaultHint =>
      'E.g. marker peeling, cracked pad surface...';

  @override
  String get techHomeLandingPadMaintenanceHint =>
      'E.g. cleaning, repainting the marker...';

  @override
  String get techHomeReasonRequired => 'Please enter a reason.';

  @override
  String get techHomeNoBoxesConfigured => 'No compartments configured yet.';

  @override
  String get techHomeXlColumn => 'XL suitcase column';

  @override
  String techHomeRowLabel(Object row) {
    return 'Row $row';
  }

  @override
  String get techHomeBoxHardwareTitle => 'Compartment hardware status';

  @override
  String techHomeNeedsAttentionCount(Object count) {
    return '$count need attention';
  }

  @override
  String get techHomeNoDoorSensorData =>
      'No door sensor data for this locker yet (the cabinet hasn\'t reported or the IoT service is off).';

  @override
  String techHomeDoorOpenNotOccupied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count compartments have their doors OPEN but aren\'t \"occupied\" — please check (stuck or left open).',
      one:
          '1 compartment has its door OPEN but isn\'t \"occupied\" — please check (stuck or left open).',
    );
    return '$_temp0';
  }

  @override
  String get techHomeNoDoorSignal => 'No door signal yet';

  @override
  String get techHomeDoorOpenCaps => 'Door OPEN';

  @override
  String techHomeReportedAt(Object time) {
    return 'Reported at $time';
  }

  @override
  String get techHomeControllerOnline => 'Controller: online';

  @override
  String get techHomeControllerOffline => 'Controller: disconnected';

  @override
  String techHomeReservedCount(Object count) {
    return 'Reserved: $count';
  }

  @override
  String techHomeOccupiedCount(Object count) {
    return 'Occupied: $count';
  }

  @override
  String get techHomeYourLocker => 'Your locker';

  @override
  String get techHomeVisualCheckHint =>
      'Visually check each compartment and only report a fault once you\'ve confirmed a physical issue at the locker.';

  @override
  String get techHomeReportWholeLocker => 'Report whole-locker incident';

  @override
  String get techHomeLockerIncidentTitleHint =>
      'E.g. kiosk screen won\'t turn on, power loss...';

  @override
  String techHomeScenePhotosOptional(Object max) {
    return 'On-site photos (optional, up to $max)';
  }

  @override
  String get techHomeBlockWholeLocker =>
      'Block whole locker (stop taking orders)';

  @override
  String get techHomeBlockWholeLockerHint =>
      'The locker goes into maintenance until the ticket is completed.';

  @override
  String get techHomeTitleAndDescRequired =>
      'Please enter a title and description.';

  @override
  String techHomeLockerTicketCreated(Object id, Object locker) {
    return 'Created ticket RPT-$id for $locker.';
  }

  @override
  String techHomeLockerTicketCreatedBlocked(Object id, Object locker) {
    return 'Created ticket RPT-$id for $locker — the locker has stopped taking orders.';
  }

  @override
  String techHomeLockerIncidentSent(Object locker) {
    return 'Incident report sent for $locker.';
  }

  @override
  String get techHomeTotalBoxes => 'Total';

  @override
  String get techHomeFaultyBoxes => 'Faulty';

  @override
  String get techHomeXlTallBay => 'XL tall bay';

  @override
  String techHomeFixedAcceptTicket(Object id) {
    return 'Fixed — accept ticket RPT-$id';
  }

  @override
  String get techHomeFixedReopenBox => 'Fixed — reopen compartment';

  @override
  String get techHomeConfirmBoxFaulty => 'Confirm compartment faulty (lock it)';

  @override
  String techHomeViewTicketToCheck(Object id) {
    return 'View ticket RPT-$id to check';
  }

  @override
  String get techHomeFinishCleaning => 'Finish cleaning';

  @override
  String get techHomeRestoreBox => 'Restore compartment';

  @override
  String get techHomeReportBoxFault => 'Report compartment fault';

  @override
  String get techHomeTakeBoxOutOfService => 'Take compartment out of service';

  @override
  String get techHomeMarkCleaning => 'Mark as cleaning';

  @override
  String get techHomeBoxCleaning => 'Compartment is being cleaned';

  @override
  String get techHomeEmergencyOpen => 'Emergency open';

  @override
  String techHomeBoxNumberWithType(Object number, Object type) {
    return 'Compartment #$number · $type';
  }

  @override
  String techHomeStatusLine(Object status) {
    return 'Status: $status';
  }

  @override
  String get techHomeDefaultFaultReason => 'Broken lock';

  @override
  String techHomeReportBoxFaultTitle(Object number) {
    return 'Report fault: compartment #$number';
  }

  @override
  String get techHomeFaultReasonLabel => 'Fault reason';

  @override
  String get techHomeFaultReasonRequired => 'Please enter the fault reason.';

  @override
  String get techHomeReportFaultAction => 'Report fault';

  @override
  String get techHomeBoxFaultReported => 'Compartment fault reported';

  @override
  String techHomeBoxFaultReportedWithPhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Compartment fault reported with $count photos',
      one: 'Compartment fault reported with 1 photo',
    );
    return '$_temp0';
  }

  @override
  String techHomeOutOfServiceTitle(Object number) {
    return 'Take compartment #$number out of service';
  }

  @override
  String get techHomeOutOfServiceHint =>
      'The compartment won\'t be assigned to customers until it\'s restored.';

  @override
  String get techHomeReasonOptionalLabel => 'Reason (optional)';

  @override
  String get techHomeBoxOutOfServiceDone => 'Compartment taken out of service';

  @override
  String get techHomeHardwareAlertsTitle =>
      'Hardware alerts (doors open unexpectedly)';

  @override
  String techHomeDoorOpenEmpty(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count compartments have their doors OPEN but are empty — please check (stuck or left open).',
      one:
          '1 compartment has its door OPEN but is empty — please check (stuck or left open).',
    );
    return '$_temp0';
  }

  @override
  String techHomeAnomalyBoxTitle(Object locker, Object number, Object type) {
    return '$locker · Compartment #$number ($type)';
  }

  @override
  String techHomeDoorOpenReportedAt(Object time) {
    return 'Door OPEN · reported at $time';
  }

  @override
  String get techHomeDoorOpenShort => 'Door OPEN';

  @override
  String techHomeAllWithCount(Object count) {
    return 'All ($count)';
  }

  @override
  String techHomeMyLockersWithCount(Object count) {
    return 'My lockers ($count)';
  }

  @override
  String get techHomeFilterAllStatuses => 'All statuses';

  @override
  String get techHomeFilterUnclaimed => 'Unclaimed';

  @override
  String get techHomeFilterInProgress => 'In progress';

  @override
  String get techHomeNoAssignedLockers =>
      'You haven\'t been assigned any lockers — new tickets go to all locker technicians.';

  @override
  String techHomeAssignedLockersBanner(int count, Object names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'You\'re in charge of $count lockers: $names. New tickets at these lockers are routed straight to you.',
      one:
          'You\'re in charge of 1 locker: $names. New tickets there are routed straight to you.',
    );
    return '$_temp0';
  }

  @override
  String get techHomePhysicalFaultsTitle => 'Compartments with physical faults';

  @override
  String techHomeLockerBoxTitle(Object locker, Object number) {
    return '$locker · Compartment #$number';
  }

  @override
  String get techHomeUnknownReason => 'Unknown reason';

  @override
  String techHomeFixedWithTicket(Object id) {
    return 'Fixed · ticket RPT-$id';
  }

  @override
  String get techHomeFixed => 'Fixed';

  @override
  String techHomeRoutedTicketsTitle(Object count) {
    return 'Tickets waiting for you ($count)';
  }

  @override
  String get techHomeNoRoutedTickets => 'No tickets waiting for you';

  @override
  String get techHomeNoRoutedTicketsHint =>
      'Your lockers have no new incidents.';

  @override
  String techHomeSystemWideTickets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'SYSTEM-WIDE: $count KIOSK INCIDENT TICKETS',
      one: 'SYSTEM-WIDE: 1 KIOSK INCIDENT TICKET',
    );
    return '$_temp0';
  }

  @override
  String techHomeCountUnclaimed(Object count) {
    return '$count unclaimed';
  }

  @override
  String techHomeCountInProgress(Object count) {
    return '$count in progress';
  }

  @override
  String techHomeCountDone(Object count) {
    return '$count done';
  }

  @override
  String techHomeIncidentsAwaitingTech(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count incidents waiting for a technician to take them',
      one: '1 incident waiting for a technician to take it',
    );
    return '$_temp0';
  }

  @override
  String get techHomeIncidentsAwaitingTitle => 'Incidents awaiting pickup';

  @override
  String get techHomeBeingHandledTitle => 'Being handled';

  @override
  String get techHomeRecentlyDoneTitle => 'Recently completed';

  @override
  String get techHomeNoIncidents => 'No incidents';

  @override
  String get techHomeNoIncidentsHint =>
      'No incident tickets or faulty compartments in the system.';

  @override
  String get techHomeShiftOverview => 'Shift overview';

  @override
  String get techHomeMetricReceived => 'Tickets\ntaken';

  @override
  String get techHomeMetricInProgress => 'In\nprogress';

  @override
  String get techHomeMetricDone => 'Tickets\ndone';

  @override
  String get techHomeMetricSlaOverdue => 'SLA\noverdue';

  @override
  String techHomeYourRating(Object rating) {
    return 'Your rating: $rating';
  }

  @override
  String get techHomeNoCustomerRatings =>
      'No customer ratings yet for the tickets you\'ve handled.';

  @override
  String get techHomeStandardProcedure =>
      'Standard procedure: check the locker location, take the ticket, go to the right compartment, take acceptance photos, then complete to clear the fault.';

  @override
  String get techHomeSlaCardRestricted => 'Restricted from taking new work';

  @override
  String get techHomeSlaCardWarning => 'SLA time violation warning';

  @override
  String get techHomeSlaCardSuspended => 'Account suspended';

  @override
  String get techHomeSlaCardNormal => 'Technician record in good standing';

  @override
  String get techHomeSlaCardUnknown => 'Couldn\'t load SLA status';

  @override
  String get techHomeSlaPullToReload =>
      'Pull down to reload the penalty status from the server.';

  @override
  String techHomeCompletedCount(Object count) {
    return 'Completed: $count';
  }

  @override
  String techHomeInProgressCount(Object count) {
    return 'In progress: $count';
  }

  @override
  String techHomeSlaOverdueCount(Object count) {
    return 'SLA overdue: $count';
  }

  @override
  String get techHomeNoWorkYet => 'You haven\'t taken any work yet';

  @override
  String get techHomeNoWorkYetHint =>
      'Go to the \"Incidents\" tab to browse and take new work.';

  @override
  String techHomeActiveIncidentsTitle(Object count) {
    return 'Incidents in progress ($count)';
  }

  @override
  String techHomeCompletedHistoryTitle(Object count) {
    return 'Completed history ($count)';
  }

  @override
  String get techHomeScheduleIntro =>
      'Kiosk routine inspection schedules are created by admins and assigned to technicians. When one is due, tap \"Inspect\" and rate each item: all pass ⇒ moved to the next cycle; any fail ⇒ the system opens a ticket assigned to you and the due date only moves once the ticket is completed.';

  @override
  String techHomeMineWithCount(Object count) {
    return 'Mine ($count)';
  }

  @override
  String techHomeAnyDueWithCount(Object count) {
    return 'Any due date ($count)';
  }

  @override
  String techHomeDueWithCount(Object count) {
    return 'Due ($count)';
  }

  @override
  String techHomeUpcomingWithCount(Object count) {
    return 'Upcoming ($count)';
  }

  @override
  String get techHomeNoDueSchedules => 'No Kiosk inspections due';

  @override
  String get techHomeNoUpcomingSchedules => 'No upcoming Kiosk inspections';

  @override
  String get techHomeNoAssignedSchedules =>
      'You haven\'t been assigned any inspection schedules';

  @override
  String get techHomeNoSchedulesAtAll =>
      'No Kiosk routine inspection plans yet';

  @override
  String get techHomeNoAssignedSchedulesHint =>
      'Choose \"All\" to see other technicians\' schedules.';

  @override
  String get techHomeNoSchedulesHint =>
      'All Kiosk devices are within their normal maintenance cycle.';

  @override
  String techHomeOverdueByDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Overdue by $days days',
      one: 'Overdue by 1 day',
    );
    return '$_temp0';
  }

  @override
  String get techHomeDueToday => 'Due today';

  @override
  String techHomeDueInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Due in $days days',
      one: 'Due in 1 day',
    );
    return '$_temp0';
  }

  @override
  String techHomeLastFailedCompleteTicket(Object id) {
    return 'Last inspection failed — complete ticket RPT-$id before inspecting again.';
  }

  @override
  String get techHomeScheduleOwnedByOther =>
      'This schedule belongs to another technician.';

  @override
  String get techHomeRoutineScheduleDefault => 'Routine inspection';

  @override
  String get techHomeDueBadge => 'Due';

  @override
  String techHomeDueAt(Object date) {
    return 'Due: $date';
  }

  @override
  String techHomeCycleEveryDays(Object days) {
    return 'Cycle: every $days days';
  }

  @override
  String get techHomeAssignedBadge => 'Assigned';

  @override
  String techHomeLastFailedBanner(Object id) {
    return 'Last inspection FAILED · Complete ticket RPT-$id before inspecting again';
  }

  @override
  String techHomeHandleTicket(Object id) {
    return 'Handle ticket RPT-$id';
  }

  @override
  String get techHomeInspectAction => 'Inspect';

  @override
  String techHomeInspectionFailedTicket(Object id) {
    return 'Inspection FAILED — ticket RPT-$id was opened and assigned to you. The next due date only moves once the ticket is completed.';
  }

  @override
  String get techHomeKioskLocker => 'Kiosk locker';

  @override
  String techHomeInspectionFailedRecorded(Object title) {
    return 'Recorded FAIL for \"$title\".';
  }

  @override
  String techHomeInspectionPassedRecorded(Object title) {
    return 'Recorded PASS for \"$title\".';
  }

  @override
  String techHomeInspectionPassedNextDue(Object title, Object date) {
    return 'Recorded PASS for \"$title\" — next due $date.';
  }

  @override
  String get techHomeViewWork => 'View work';

  @override
  String get techHomeSlaExtendAssigneeOnly =>
      'Only the assigned technician can extend the SLA.';

  @override
  String techHomeSlaExtendLimitReached(Object id, Object used, Object max) {
    return 'Ticket RPT-$id has been extended $used/$max times — contact an admin if you need more time.';
  }

  @override
  String techHomeSlaExtended(Object id) {
    return 'Extended the SLA of ticket RPT-$id';
  }

  @override
  String techHomeSlaExtendedNewDue(Object id, Object due) {
    return 'Extended the SLA of ticket RPT-$id — new due $due';
  }

  @override
  String techHomeReleaseTicketTitle(Object id) {
    return 'Release ticket RPT-$id';
  }

  @override
  String get techHomeReleaseTicketHint =>
      'The ticket goes back to the queue for another technician; the reason is written to the ticket log.';

  @override
  String get techHomeReleaseReasonLabel => 'Reason for releasing (required)';

  @override
  String get techHomeReleaseReasonHint =>
      'E.g. parts not in stock, shift change...';

  @override
  String get techHomeReleaseReasonRequired =>
      'Please enter the reason for releasing the ticket.';

  @override
  String get techHomeReleaseTicketAction => 'Release ticket';

  @override
  String techHomeTicketReleased(Object id) {
    return 'Ticket RPT-$id returned to the queue.';
  }

  @override
  String techHomeRejectIncidentTitle(Object id) {
    return 'Reject incident RPT-$id';
  }

  @override
  String get techHomeRejectIncidentHint =>
      'Use this when you\'ve checked at the locker and the compartment works normally. The ticket is closed, the compartment goes back into service and the feedback below is sent to the reporter.';

  @override
  String get techHomeReporterFeedbackLabel =>
      'Feedback to the reporter (required)';

  @override
  String get techHomeReporterFeedbackHint =>
      'E.g. opened/closed the compartment 3 times, the door and lock work normally.';

  @override
  String get techHomeReporterFeedbackRequired =>
      'Please write feedback for the reporter.';

  @override
  String get techHomeCloseAndReply => 'Close ticket & reply';

  @override
  String techHomeTicketRejectedDone(Object id) {
    return 'Closed ticket RPT-$id and sent feedback to the reporter.';
  }

  @override
  String techHomeDevicesLoadFailed(Object error) {
    return 'Couldn\'t load the device list: $error';
  }

  @override
  String get techHomeIotDevices => 'IoT devices';

  @override
  String get techHomeNoDevices => 'No devices';

  @override
  String get techHomeNoDevicesHint =>
      'No controllers are attached to your lockers yet.';

  @override
  String techHomeDeviceNumber(Object id) {
    return 'Device #$id';
  }

  @override
  String techHomeLastSignal(Object time) {
    return 'Last signal: $time';
  }

  @override
  String get techHomeNoSignalYet => 'No signal received yet';

  @override
  String get techHomeDevicesHint =>
      'Status is computed by the server from the device\'s latest signal. Tap a device to view its log or restart the controller.';

  @override
  String get techHomeLandingPadPill => 'Landing pad';

  @override
  String get techHomeLockerLevelPill => 'Locker-level';

  @override
  String get techHomeBlocksLockerPill => 'Whole locker blocked';

  @override
  String techHomeFromRoutineInspection(Object id) {
    return 'From routine inspection #$id';
  }

  @override
  String get techHomeNewBadge => 'NEW';

  @override
  String techHomeLockerBoxShort(Object locker, Object box) {
    return '$locker · Compartment $box';
  }

  @override
  String get techHomeClaimSuccess => 'Ticket taken';

  @override
  String get techHomeClaimAction => 'Take';

  @override
  String get techHomeNoExtensionsLeft => 'No extensions left';

  @override
  String get techHomeAddPhotosShort => 'Photos (+)';

  @override
  String get techHomeAcceptanceAction => 'Acceptance';

  @override
  String techHomeTicketJustUpdated(Object id) {
    return 'Ticket RPT-$id was just updated.';
  }

  @override
  String techHomeSlaExtendedHours(Object hours) {
    return 'SLA extended (+$hours h)';
  }

  @override
  String techHomeOverdueAfterExtension(Object hours) {
    return 'Overdue (after +$hours h extension)';
  }

  @override
  String get techHomeSlaOverdueBadge => 'SLA overdue';

  @override
  String techHomeAssigneeYou(Object name) {
    return '$name (you)';
  }

  @override
  String techHomeSlaDueAt(Object time) {
    return 'SLA due: $time';
  }

  @override
  String techHomeExtensionReason(Object reason) {
    return 'Extension reason: $reason';
  }

  @override
  String get techHomeCustomerComplaint => 'Customer\'s report:';

  @override
  String get techHomeCustomerScenePhotos => 'On-site photos from the customer';

  @override
  String get techHomeClaimNow => 'Take it now';

  @override
  String get techHomeInspectAndLockBox =>
      'Check compartment & lock incident at Kiosk';

  @override
  String get techHomeAcceptAndComplete => 'Accept & complete';

  @override
  String get techHomeNotAsDescribed =>
      'Not as described — close ticket & reply';

  @override
  String get techHomeReleaseToQueue => 'Return ticket to the queue';

  @override
  String techHomeTicketHandledByName(Object assignee) {
    return 'This ticket is being handled by $assignee — only the assignee can complete it.';
  }

  @override
  String get techHomeTicketBeingHandled => 'This ticket is being handled.';

  @override
  String get techHomeTicketNoKiosk =>
      'This incident ticket isn\'t linked to any Kiosk station.';

  @override
  String get techHomeBoxIncidentResolved =>
      'Compartment status updated and incident resolved!';

  @override
  String get techHomeScenePhotosSaved => 'On-site confirmation photos saved';

  @override
  String techHomeOpenForDays(Object count) {
    return 'Open ${count}d';
  }

  @override
  String techHomeOpenForHours(Object count) {
    return 'Open ${count}h';
  }

  @override
  String techHomeOpenForMinutes(Object count) {
    return 'Open ${count}m';
  }

  @override
  String get techHomeJustOpened => 'Just opened';

  @override
  String get techHomeMarkDeviceErrorTitle => 'Mark device as faulty';

  @override
  String get techHomeMarkDeviceOfflineTitle => 'Mark device as disconnected';

  @override
  String techHomeMarkDeviceErrorBody(Object device) {
    return 'Device \"$device\" will be marked as faulty until the controller sends a signal again. Continue?';
  }

  @override
  String techHomeMarkDeviceOfflineBody(Object device) {
    return 'Device \"$device\" will be marked as disconnected until the controller sends a signal again. Continue?';
  }

  @override
  String get techHomeMarkAction => 'Mark';

  @override
  String get techHomeDeviceMarkedError => 'Device marked as faulty.';

  @override
  String get techHomeDeviceMarkedOffline => 'Device marked as disconnected.';

  @override
  String get techHomeRestartControllerTitle => 'Restart controller';

  @override
  String techHomeRestartControllerBody(Object device) {
    return 'Controller \"$device\" will restart the locker control process (not the machine). Compartments can\'t be opened in the meantime. Continue?';
  }

  @override
  String get techHomeRestartAction => 'Restart';

  @override
  String get techHomeDeviceIdLabel => 'Device ID';

  @override
  String get techHomeLastSignalLabel => 'Last signal';

  @override
  String get techHomeNoSignalShort => 'No signal yet';

  @override
  String get techHomeConnectionLabel => 'Connection';

  @override
  String techHomeDeviceLoadFailed(Object error) {
    return 'Couldn\'t load the device: $error';
  }

  @override
  String get techHomeDeviceStatusHint =>
      'Status is computed by the server from the latest signal; only mark it manually when you\'re sure the device is disconnected or broken.';

  @override
  String get techHomeWaitingForLocker => 'Waiting for the locker to respond...';

  @override
  String get techHomeMarkOffline => 'Mark disconnected';

  @override
  String get techHomeMarkError => 'Mark faulty';

  @override
  String get techHomeActivityLog => 'Activity log';

  @override
  String techHomeLogLoadFailed(Object error) {
    return 'Couldn\'t load the log: $error';
  }

  @override
  String get techHomeNoLogsYet => 'No log entries yet.';

  @override
  String get techHomeQuickChipInspectScene => '📸 Inspected the site';

  @override
  String get techHomeQuickChipReplacePart => '🔧 Replaced a part';

  @override
  String get techHomeQuickChipCheckPowerBoard => '⚡ Checked the power board';

  @override
  String get techHomeQuickChipCleanBox => '🧹 Cleaned the compartment';

  @override
  String get techHomeQuickChipAdjustLatch => '🚪 Adjusted latch & bolt';

  @override
  String get techHomeTechLogTitle => 'Technician log & history:';

  @override
  String techHomeTechLogLoadFailed(Object error) {
    return 'Couldn\'t load the work log: $error';
  }

  @override
  String get techHomeNoTechLogsHint =>
      'No work notes yet. \"Check compartment & lock incident\" or \"Acceptance\" actions are saved here automatically.';

  @override
  String techHomeTechNumber(Object id) {
    return 'Tech #$id';
  }

  @override
  String techHomeLogViewerTitle(Object time) {
    return 'Log · $time';
  }

  @override
  String get techHomeAddLogStep => 'Add a work step / quick note...';

  @override
  String get techHomeLogNoteHint => 'Enter a work note...';

  @override
  String get techHomeQuickNoteReplacedLock =>
      'Replaced the electronic lock part';

  @override
  String get techHomeQuickNoteAdjustedHinge =>
      'Adjusted the compartment door bolt & hinge';

  @override
  String get techHomeQuickNoteCheckedBoard =>
      'Checked the control board & power';

  @override
  String get techHomeQuickNoteCleanedTested =>
      'Cleaned, tested open/close 3 times';

  @override
  String get techHomeBoxNotInLayout =>
      'Compartment not found in the locker layout.';

  @override
  String get techHomeBoxHoldsOrderNoTest =>
      'The compartment holds a customer\'s items/order — no test open.';

  @override
  String techHomeBoxCheckFailed(Object error) {
    return 'Couldn\'t check the compartment ($error).';
  }

  @override
  String get techHomeAfterPhotoRequired =>
      'Please take at least 1 after-repair photo for the acceptance.';

  @override
  String techHomeBoxLabelLower(Object number) {
    return 'compartment #$number';
  }

  @override
  String get techHomeLandingPadRestored =>
      'The landing pad is back in service.';

  @override
  String get techHomeLockerRestored => 'The locker is back in service.';

  @override
  String techHomeBoxRestoredTestOpened(Object box) {
    return 'The compartment is back in service; test-open command sent to $box.';
  }

  @override
  String get techHomeBoxRestored => 'The compartment is back in service.';

  @override
  String techHomeResolvedWithRestored(Object restored) {
    return 'Incident accepted and completed! $restored';
  }

  @override
  String techHomeResolvedTestOpenFailed(Object box, Object error) {
    return 'Incident accepted and completed, but couldn\'t test-open $box: $error';
  }

  @override
  String get techHomeRequiredBadge => 'Required';

  @override
  String techHomeIncidentRpt(Object id) {
    return 'Incident RPT-$id';
  }

  @override
  String get techHomeResolveSheetTitle => 'Repair acceptance';

  @override
  String techHomeResolveSheetSubtitleWithBox(
    Object locker,
    Object box,
    Object id,
    Object title,
  ) {
    return '$locker · Compartment $box · RPT-$id · $title';
  }

  @override
  String get techHomeScenePhotosBeforeAfter =>
      'On-site photos (before & after repair)';

  @override
  String get techHomeBeforeRepair => 'Before repair';

  @override
  String techHomeExistingScenePhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count on-site / reporter photos for comparison',
      one: '1 on-site / reporter photo for comparison',
    );
    return '$_temp0';
  }

  @override
  String get techHomeBeforeRepairOptional =>
      'Optional · saved as on-site confirmation photos';

  @override
  String get techHomeScenePhotosBeforeRepair => 'On-site photos before repair';

  @override
  String get techHomeTakeMorePhotos => 'Take more photos';

  @override
  String get techHomeDuringRepair => 'During repair';

  @override
  String get techHomeDuringRepairHint =>
      'Photos of the technical work, part replacement (optional)';

  @override
  String get techHomeTakeRepairPhotos => 'Take repair photos';

  @override
  String get techHomeAfterRepair => 'After repair';

  @override
  String get techHomeAcceptancePhotoRequired =>
      'Acceptance photos — at least 1 required';

  @override
  String get techHomeAcceptancePhotoOptional => 'Acceptance photos (optional)';

  @override
  String get techHomeTechNotesTitle => 'Technical notes & parts';

  @override
  String get techHomeTechNotesHint =>
      'Describe the replaced parts and the steps taken...';

  @override
  String get techHomeCheckingTestOpen =>
      'Checking the compartment before allowing a test open...';

  @override
  String get techHomeTestOpenAfterRepair => 'Test-open after repair';

  @override
  String techHomeTestOpenHintWithBox(Object box) {
    return 'After completing the ticket, send an open command to compartment #$box to check the latch.';
  }

  @override
  String get techHomeTestOpenHint =>
      'After completing the ticket, send an open command to the compartment to check the latch.';

  @override
  String techHomeTestOpenNotSuggested(Object reason) {
    return 'Test open not suggested: $reason';
  }

  @override
  String get techHomeSavingAcceptance => 'Saving acceptance...';

  @override
  String get techHomeConfirmAndCompleteRepair => 'Confirm & complete repair';

  @override
  String get techHomeScenePhotoRequired =>
      'Please take at least 1 on-site photo.';

  @override
  String get techHomeSceneConfirmTitle => 'On-site confirmation';

  @override
  String get techHomeSceneConfirmHint =>
      'Photograph the compartment\'s condition as soon as you arrive (door, lock, board...). Photos are saved to the ticket as pre-repair evidence.';

  @override
  String get techHomeSceneNoteHint => 'Condition note (optional)...';

  @override
  String get techHomeSaveScenePhotos => 'Save on-site photos';

  @override
  String get techHomeCustomerShort => 'Customer';

  @override
  String techHomeOpenBoxError(Object error) {
    return 'Couldn\'t open the compartment: $error';
  }

  @override
  String get techHomeInvalidTicket => 'Invalid ticket.';

  @override
  String get techHomeBoxIncidentSheetTitle =>
      'Check compartment & resolve incident';

  @override
  String get techHomeStep1PickBox =>
      '1. Pick the faulty compartment at the Kiosk:';

  @override
  String get techHomeKioskNoBoxes => 'This Kiosk has no compartment list yet.';

  @override
  String techHomeOrderLookupFailed(Object error) {
    return 'Couldn\'t look up the order in this compartment ($error). Check it in person (emergency open) before choosing an option — for now you can only lock the compartment.';
  }

  @override
  String get techHomeEmergencyOpenShort => 'Emergency open';

  @override
  String get techHomeBoxHasCustomerItems => 'COMPARTMENT HOLDS CUSTOMER ITEMS!';

  @override
  String techHomeActiveOrderLine(Object code, Object customer) {
    return 'Order: $code · Customer: $customer';
  }

  @override
  String get techHomeBoxNoActiveOrder => 'NO ACTIVE ORDER IN THIS COMPARTMENT';

  @override
  String get techHomeBoxNoActiveOrderHint =>
      'No order was found in this compartment. The customer may have already collected the items, a sensor may be stuck, or the wrong compartment was reported. Emergency-open it to check in person.';

  @override
  String get techHomeBoxCurrentlyEmpty =>
      'The compartment is empty (nothing inside)';

  @override
  String get techHomeStep2PickGoodsOption =>
      '2. Choose how to handle the items in the compartment:';

  @override
  String get techHomeStep2PickOption => '2. Choose a resolution:';

  @override
  String get techHomeOptionRelocateTitle =>
      'Move to a new empty compartment (Recommended)';

  @override
  String get techHomeOptionRelocateHint =>
      'Move the items to another empty compartment at the same Kiosk, issue a new PIN to the customer & lock the old compartment.';

  @override
  String get techHomeNoFreeBoxes =>
      '⚠️ This Kiosk has no empty compartments left! Choose direct handover or seal instead.';

  @override
  String get techHomePickTargetBox => 'Choose the target empty compartment';

  @override
  String techHomeTargetBoxOption(Object number, Object type) {
    return 'Compartment #$number ($type)';
  }

  @override
  String get techHomeOptionHandoverTitle =>
      'Customer present - Hand over directly';

  @override
  String get techHomeOptionHandoverHint =>
      'The customer is at the station and takes the items directly; complete the order & lock the old compartment.';

  @override
  String get techHomeHandoverCodeLabel =>
      '6-digit PIN or order QR code (required)';

  @override
  String get techHomeHandoverCodeHint =>
      'The customer reads/shows the pickup code to confirm the handover';

  @override
  String get techHomeOptionHubTitle => 'Kiosk full - Seal and take to Hub';

  @override
  String get techHomeOptionHubHint =>
      'Pack the items in a seal bag, scan the seal code, take it to the Hub for storage & lock the old compartment.';

  @override
  String get techHomeSealCodeLabel => 'Seal code (required)';

  @override
  String get techHomeSealCodeHint =>
      'Enter the code printed on the seal bag exactly';

  @override
  String get techHomeOptionQuickFixKeepTitle =>
      'Check & fix on site (don\'t move items)';

  @override
  String get techHomeOptionQuickFixKeepHint =>
      'Check the sensor, close the door firmly or help the customer on site without moving the items.';

  @override
  String get techHomeOptionQuickFixTitle => 'Check & fix on site (Recommended)';

  @override
  String get techHomeOptionQuickFixHint =>
      'Physical check (sensor, latch, cleaning). If the user reported by mistake or a minor issue is already fixed, no need to lock the compartment.';

  @override
  String get techHomeOptionLockFaultTitle =>
      'Confirm hardware fault & lock for maintenance (FAULT)';

  @override
  String get techHomeOptionLockFaultHint =>
      'Needs replacement parts or deep maintenance. The compartment is suspended so a technician can repair it.';

  @override
  String get techHomeLockForMaintenance =>
      'Lock compartment for maintenance (Status: FAULT)';

  @override
  String get techHomeKeepActiveWithGoods =>
      'Keep compartment active (holding customer items)';

  @override
  String get techHomeKeepActiveNormal =>
      'Keep compartment active as normal (AVAILABLE)';

  @override
  String get techHomeLockOnlyHint =>
      'The maintenance lock (FAULT) option always locks the compartment for servicing. If you don\'t need to lock it, choose \"Check & fix on site\".';

  @override
  String get techHomeLockedHint =>
      'The compartment will be suspended and won\'t take new orders until the repair is completed.';

  @override
  String get techHomeNotLockedWithGoodsHint =>
      'The compartment isn\'t locked. The customer\'s items stay safely inside and it won\'t be returned to empty.';

  @override
  String get techHomeNotLockedHint =>
      'The compartment isn\'t locked. Suitable when the customer reported by mistake or the issue was fixed on site.';

  @override
  String get techHomeStep3ReasonNotes => '3. Reason & work notes:';

  @override
  String get techHomeSystemRecordedIncident =>
      'Compartment incident recorded by the system';

  @override
  String get techHomeFailedInspectionContent =>
      'Failed routine inspection details:';

  @override
  String get techHomeCustomerReportedReason => 'Customer\'s reported reason:';

  @override
  String get techHomeTechFieldNotesLabel =>
      'Technician\'s on-site notes (separate):';

  @override
  String get techHomeTechFieldNotesHint =>
      'Enter what you found and your assessment...';

  @override
  String get techHomeStep4ScenePhotos =>
      '4. On-site / comparison photos (technician check):';

  @override
  String techHomeExistingScenePhotosColon(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count on-site / reporter photos for comparison:',
      one: '1 on-site / reporter photo for comparison:',
    );
    return '$_temp0';
  }

  @override
  String get techHomeComparisonScenePhotos => 'On-site comparison photos';

  @override
  String get techHomeTakeMoreScenePhotos =>
      'Take more on-site photos (optional):';

  @override
  String get techHomeStep5RepairPhotos => '5. Repair progress photos:';

  @override
  String get techHomeStep5RepairPhotosHint =>
      'Photograph part removal/installation, technical work, sensor checks or item handling:';

  @override
  String techHomeExistingRepairPhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repair progress photos:',
      one: '1 repair progress photo:',
    );
    return '$_temp0';
  }

  @override
  String get techHomeTakeMoreRepairPhotos =>
      'Take more repair photos (optional):';

  @override
  String get techHomeUpdating => 'Updating...';

  @override
  String get techHomeConfirmAndUpdate => 'Confirm & update system';

  @override
  String get techHomeCellTypeStandard => 'Standard';

  @override
  String get techHomeForceOpenReasonForgotPin =>
      'Customer forgot the PIN / can\'t be reached';

  @override
  String get techHomeForceOpenReasonJammed =>
      'Door mechanically stuck / magnetic latch fault';

  @override
  String get techHomeForceOpenReasonTicketCheck =>
      'Compartment check while handling an incident ticket';

  @override
  String get techHomeForceOpenReasonManagement =>
      'Check requested by management';

  @override
  String get techHomeForceOpenReasonEmergency =>
      'Emergency / suspected leak or foreign object';

  @override
  String get techHomeForceOpenReasonOther => 'Other reason…';

  @override
  String techHomeForceOpenSent(Object box) {
    return 'Emergency open command sent to $box.';
  }

  @override
  String techHomeForceOpenConfirmed(Object box) {
    return 'The locker confirmed $box is open.';
  }

  @override
  String techHomeForceOpenTitle(Object box) {
    return 'Emergency open $box';
  }

  @override
  String techHomeForceOpenHintWithTicket(Object id) {
    return 'The compartment is opened with a Master command and written to the access log. The reason, note and photos are saved to the log of ticket RPT-$id.';
  }

  @override
  String get techHomeForceOpenHint =>
      'The compartment is opened with a Master command and written to the access log with the reason.';

  @override
  String get techHomeForceOpenReasonLabel =>
      'Reason for intervention (required):';

  @override
  String get techHomeEnterReason => 'Enter a reason';

  @override
  String get techHomeNoteOptional => 'Note (optional)';

  @override
  String get techHomeForceOpenReasonRequired =>
      'Please enter the reason for the emergency open.';

  @override
  String get techHomeConfirmOpen => 'Confirm open';

  @override
  String get techHomeSlaReasonWaitingParts => 'Waiting for replacement parts';

  @override
  String get techHomeSlaReasonDeepCircuitCheck =>
      'Circuit needs an in-depth check';

  @override
  String get techHomeSlaReasonHardToReach => 'Locker hard to access';

  @override
  String get techHomeSlaReasonBuildingOps =>
      'Coordinating with building operations';

  @override
  String get techHomeSlaReasonRequired =>
      'Please enter the reason for the SLA extension.';

  @override
  String techHomeMaxExtensionsPerTicket(Object count) {
    return 'Max $count times per ticket';
  }

  @override
  String techHomeExtendSlaTitle(Object id) {
    return 'Extend SLA of ticket RPT-$id';
  }

  @override
  String get techHomeCurrentDueLabel => 'Current due:';

  @override
  String get techHomeNewDueLabel => 'New due (estimated):';

  @override
  String get techHomePickExtensionHours => 'Choose extension time:';

  @override
  String techHomePickExtensionHoursCapped(Object hours) {
    return 'Choose extension time (max $hours h each):';
  }

  @override
  String techHomePlusHours(Object hours) {
    return '+$hours h';
  }

  @override
  String get techHomeExtensionReasonLabel => 'Extension reason (required):';

  @override
  String get techHomeExtensionReasonHint => 'Enter why you need more time...';

  @override
  String get techHomeConfirmExtendSla => 'Confirm SLA extension';

  @override
  String get techHomeDeletePhotoTitle => 'Delete this photo?';

  @override
  String techHomeDeletePhotoBody(Object stage, Object id) {
    return '$stage will be removed from ticket RPT-$id.';
  }

  @override
  String get techHomePhotoDeleted => 'Photo removed from the ticket.';

  @override
  String techHomeTicketPhotosLoadFailed(Object error) {
    return 'Couldn\'t load the ticket photos: $error';
  }

  @override
  String techHomeYourAttachedPhotos(Object count) {
    return 'Your attached photos ($count) — tap ✕ to delete a wrong upload';
  }

  @override
  String get techHomeStageOnSite => 'On site';

  @override
  String get techHomeStageRepairing => 'Repairing';

  @override
  String techHomeSlaRemainingExtended(Object time, Object hours) {
    return '$time left (+${hours}h)';
  }

  @override
  String techHomeSlaRemaining(Object time) {
    return '$time left';
  }

  @override
  String techHomeSlaOverdueByExtended(Object time, Object hours) {
    return 'Overdue $time (+${hours}h)';
  }

  @override
  String techHomeSlaOverdueBy(Object time) {
    return 'Overdue $time';
  }

  @override
  String techHomeTechName(Object name) {
    return 'Tech $name';
  }

  @override
  String get techUiRestartUnconfirmed =>
      'Restart command sent, but the server hasn\'t confirmed it yet — check the device status in a few minutes.';

  @override
  String get techUiRestartAccepted =>
      'The locker controller accepted the command and is restarting.';

  @override
  String get techUiRestartTimeout =>
      'The locker didn\'t respond to the restart command — check its connection.';

  @override
  String get techUiRestartFailed => 'Restart failed — please try again.';

  @override
  String get techUiAdminAccountTitle => 'Admin account';

  @override
  String get techUiAdminWebOnly =>
      'The admin console (dashboard, statistics, users, orders, promotions...) is only available on the web.\nPlease sign in from a browser to continue.';

  @override
  String get techUiRoleDrone => 'drone technician';

  @override
  String get techUiRoleLocker => 'locker technician';

  @override
  String techUiSlaExtensionUsage(int used, int max) {
    return 'Extended $used/$max';
  }

  @override
  String techUiSlaExtensionLimit(int used, int max) {
    return 'No extensions left ($used/$max)';
  }

  @override
  String get techUiExtendSla => 'Extend SLA';

  @override
  String get techUiSlaSuspended => 'Suspended';

  @override
  String get techUiSlaRestricted => 'Restricted';

  @override
  String get techUiSlaWarning => 'Warning';

  @override
  String get techUiSlaNormal => 'Normal';

  @override
  String get techUiSlaNotLoaded => 'Not loaded';

  @override
  String techUiRatingSummary(String average, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ratings',
      one: '1 rating',
    );
    return '$average/5 ($_temp0)';
  }

  @override
  String get techUiSelectIncidentBox => 'Please select the faulty compartment.';

  @override
  String get techUiSelectTargetBox =>
      'Please select an empty compartment to move the items to.';

  @override
  String get techUiEnterHandoverCode =>
      'Enter the order\'s 6-digit PIN or QR code to confirm the handover.';

  @override
  String get techUiPinSixDigits => 'The pickup PIN must be exactly 6 digits.';

  @override
  String get techUiEnterSealCode =>
      'Enter the seal code printed on the sealed bag.';

  @override
  String get techUiLocationDeniedForever =>
      'Location permission was permanently denied. Please open Settings to turn on location.';

  @override
  String get techUiLocationAccessTitle => 'Location access';

  @override
  String get techUiForTechnicianAccounts => 'For technician accounts';

  @override
  String get techUiLocationRationale =>
      'To dispatch the nearest locker incidents and drone tasks to you accurately, the app needs your device location while you\'re on shift.';

  @override
  String get techUiBenefitDispatchTitle => 'Location-based dispatch';

  @override
  String get techUiBenefitDispatchBody =>
      'Automatically assigns tickets, routine inspections and drone rescues at lockers near you.';

  @override
  String get techUiBenefitAutoOffTitle => 'Turns off when your shift ends';

  @override
  String get techUiBenefitAutoOffBody =>
      'Location is only accessed after you start your shift. When you end it, location tracking turns off completely to protect your privacy.';

  @override
  String get techUiBenefitBatteryTitle => 'Battery & data friendly';

  @override
  String get techUiBenefitBatteryBody =>
      'Location updates adapt to how far you move, so your battery isn\'t drained.';

  @override
  String get techUiAllowLocation => 'Allow location access';

  @override
  String get techUiGpsServiceOff =>
      'GPS is turned off. Please turn on GPS on your device.';

  @override
  String get techUiLocationBlockedForever =>
      'Location access is permanently blocked. Please open Settings to grant permission.';

  @override
  String get techUiGpsUpdated => 'GPS location updated.';

  @override
  String techUiLocationUpdateFailed(String error) {
    return 'Couldn\'t update location: $error';
  }

  @override
  String get techUiEndShiftQuestion => 'End your shift?';

  @override
  String get techUiEndShiftBody =>
      'You\'ll stop receiving new incidents and location access will be turned off completely.';

  @override
  String get techUiEndShift => 'End shift';

  @override
  String get techUiShiftStarted => 'Shift started and GPS location turned on.';

  @override
  String get techUiShiftEnded => 'Shift ended and GPS location turned off.';

  @override
  String techUiShiftUpdateFailed(String error) {
    return 'Couldn\'t update shift: $error';
  }

  @override
  String get techUiNoLocationYet => 'No location yet';

  @override
  String get techUiOnShift => 'On shift';

  @override
  String get techUiOffShift => 'Off shift';

  @override
  String get techUiOnShiftLocationNote =>
      'Your location is used to dispatch the nearest jobs to you';

  @override
  String get techUiOffShiftLocationNote => 'GPS location is fully turned off';

  @override
  String get techUiDeviceGpsInfo => 'DEVICE GPS INFO';

  @override
  String get techUiGpsCoordinates => 'GPS coordinates';

  @override
  String get techUiGpsAccuracy => 'GPS accuracy';

  @override
  String techUiAccuracyMeters(String meters) {
    return '±$meters m';
  }

  @override
  String get techUiNotYet => 'Not yet';

  @override
  String get techUiOpenGoogleMaps => 'Open Google Maps';

  @override
  String get techUiUpdateGps => 'Update GPS';

  @override
  String get techUiNoGpsYet =>
      'No GPS coordinates yet. Start your shift or tap Update GPS.';

  @override
  String get techUiGetCurrentLocation => 'Get current location';

  @override
  String get techUiPrivacyCommitment =>
      'Privacy promise: your location is only accessed while you\'re on shift. When your shift ends, location tracking turns off completely.';

  @override
  String get techUiLoadingShift => 'Loading shift status...';

  @override
  String get techUiOnShiftBadge => 'ON SHIFT';

  @override
  String get techUiOffShiftBadge => 'OFF SHIFT';

  @override
  String techUiGpsActive(String accuracy, String time) {
    return 'GPS: Active$accuracy · $time';
  }

  @override
  String get techUiGpsSearching => 'Searching for GPS signal...';

  @override
  String get techUiGpsOffHint =>
      'GPS off · Start your shift to turn on location';

  @override
  String get techUiRefreshGps => 'Refresh GPS';

  @override
  String get techUiEndShiftShort => 'End shift';

  @override
  String get techUiStartShift => 'Start shift';

  @override
  String get techUiNotApplicable => 'N/A';

  @override
  String get techUiInvalidScheduleId => 'Invalid inspection schedule ID.';

  @override
  String get techUiDroneRoutineMaintenance => 'Drone routine maintenance';

  @override
  String get techUiKioskRoutineInspection => 'Kiosk routine inspection';

  @override
  String get techUiKioskLocker => 'Kiosk locker';

  @override
  String get techUiConfirmRoutineInspection => 'Confirm routine inspection';

  @override
  String techUiCycleDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Cycle: $_temp0';
  }

  @override
  String techUiChecklistProgress(int answered, int total) {
    return 'Checklist items ($answered/$total)';
  }

  @override
  String get techUiNoChecklistPickOverall =>
      'This schedule has no checklist — choose an overall result:';

  @override
  String get techUiInspectionNoteLabel => 'Inspection notes (optional)';

  @override
  String get techUiInspectionNoteHintDrone =>
      'Battery, motors, propellers, sensors or parts replaced...';

  @override
  String get techUiInspectionNoteHintKiosk =>
      'General condition, compartment cleaning, parts replaced if any...';

  @override
  String get techUiFieldPhotosOptional => 'On-site photos (optional):';

  @override
  String get techUiFieldPhotosHintDrone =>
      'Photograph the drone, battery or parts you checked for the record.';

  @override
  String get techUiFieldPhotosHintKiosk =>
      'Photograph the whole locker, locks or parts you checked for the record.';

  @override
  String get techUiUpdating => 'Updating...';

  @override
  String get techUiConfirmComplete => 'Confirm completion';

  @override
  String get techUiFaultDescOptional => 'Describe the fault found (optional)';

  @override
  String get techUiNoteOptional => 'Note (optional)';

  @override
  String techUiItemsRemaining(int remaining, int total) {
    return '$remaining/$total items not rated yet.';
  }

  @override
  String get techUiPickPassOrFail =>
      'Choose Passed or Failed for this inspection.';

  @override
  String get techUiResultFailWithTicket =>
      'Result: FAILED — an incident ticket will be opened and assigned to you. The next inspection date only moves once the ticket is completed.';

  @override
  String get techUiResultFail => 'Result: FAILED.';

  @override
  String techUiResultPass(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Result: PASSED — the next inspection is due in $_temp0.';
  }

  @override
  String get techUiFaultyBoxOptional => 'Faulty compartment (optional)';

  @override
  String get techUiFaultyBoxHint =>
      'Pick a compartment ⇒ it\'s marked Broken and the ticket is linked to it; none ⇒ locker-level ticket.';

  @override
  String get techUiNoBoxLockerLevel => 'No compartment — locker-level incident';

  @override
  String techUiBoxWithStatus(String number, String status) {
    return 'Compartment #$number · $status';
  }

  @override
  String get techUiIncidentDescOptional => 'Incident description (optional)';

  @override
  String get techUiIncidentDescHint =>
      'Leave blank ⇒ the ticket lists the failed items';

  @override
  String techUiOverdueDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Overdue by $_temp0';
  }

  @override
  String get techUiDueToday => 'Due today';

  @override
  String techUiDueInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Due in $_temp0';
  }

  @override
  String techUiPrevFailedFinishTicket(Object id) {
    return 'Last inspection failed — complete ticket RPT-$id before re-inspecting.';
  }

  @override
  String get techUiScheduleOtherTech =>
      'This schedule is assigned to another technician.';

  @override
  String get techUiPriorityUrgent => 'Urgent';

  @override
  String get techUiPriorityHigh => 'High';

  @override
  String get techUiPriorityLow => 'Low';

  @override
  String get techUiPriorityNormalDrone => 'Normal (standard drone)';

  @override
  String get techUiPriorityNormalStation => 'Normal (standard station)';

  @override
  String get techUiRoutineSchedule => 'Routine inspection schedule';

  @override
  String get techUiDroneRoutine => 'Drone routine';

  @override
  String get techUiKioskRoutine => 'Kiosk routine';

  @override
  String get techUiSchedulePlanRecord => 'Routine maintenance plan details';

  @override
  String get techUiDroneMaintenancePlan => 'Drone routine maintenance plan';

  @override
  String get techUiKioskInspectionPlan => 'Kiosk routine inspection plan';

  @override
  String get techUiDronePlanNote =>
      'This is a recurring drone maintenance schedule set by an admin; checklist results are saved to the operations record.';

  @override
  String get techUiKioskPlanNote =>
      'This is a recurring routine inspection of the kiosk station set by an admin (not an incident ticket).';

  @override
  String get techUiInspectionDue => 'Inspection due';

  @override
  String techUiPriorityLabel(String priority) {
    return 'Priority: $priority';
  }

  @override
  String techUiCycleEveryDays(String days) {
    return 'Cycle: every $days days';
  }

  @override
  String techUiShiftSlot(String slot) {
    return 'Slot: $slot';
  }

  @override
  String get techUiNoTechAssigned => 'No technician assigned';

  @override
  String get techUiTechInChargeYou => 'Technician: You';

  @override
  String techUiPlacementInBuilding(String note) {
    return 'Location in building: $note';
  }

  @override
  String get techUiDirectionsDroneStation => 'Directions to drone station';

  @override
  String get techUiPlanAndDeadline => 'Plan & deadline:';

  @override
  String get techUiDueDateLabel => 'Next due date:';

  @override
  String get techUiStartTimeLabel => 'Scheduled start time:';

  @override
  String get techUiTimeSlotLabel => 'Time slot / shift:';

  @override
  String get techUiFlexibleSlot => 'Flexible time';

  @override
  String get techUiRepeatCycleLabel => 'Repeats:';

  @override
  String techUiEveryDaysOnce(String days) {
    return 'Once every $days days';
  }

  @override
  String get techUiPriorityLevelLabel => 'Priority:';

  @override
  String get techUiTechnicianLabel => 'Assigned technician:';

  @override
  String get techUiUnassignedWaiting => 'Unassigned (waiting)';

  @override
  String get techUiYouAssigned => 'You (assigned to me)';

  @override
  String get techUiLastInspectionLabel => 'Last inspection:';

  @override
  String get techUiNoInspectionHistory => 'No inspection history yet';

  @override
  String techUiChecklistCriteria(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return 'Inspection checklist ($_temp0 to complete):';
  }

  @override
  String get techUiDroneFullCheck =>
      'Full check of the drone\'s operating condition.';

  @override
  String get techUiKioskFullCheck => 'Full check of the kiosk locker station.';

  @override
  String get techUiSopGuide => 'Procedure (SOP notes from admin):';

  @override
  String get techUiPrevResultLabel => 'Previous inspection result:';

  @override
  String techUiInspectionLogsFailed(String error) {
    return 'Couldn\'t load inspection logs: $error';
  }

  @override
  String get techUiCheckedNoOverall =>
      'Inspected — no overall result in the log';

  @override
  String get techUiPassedAllCriteria => 'PASSED — all criteria met';

  @override
  String get techUiFailedHasIssues => 'FAILED — some items need fixing';

  @override
  String techUiLogTime(String time) {
    return 'Time: $time';
  }

  @override
  String techUiLogTimeWithTech(String time, String name) {
    return 'Time: $time · Technician: $name';
  }

  @override
  String techUiItemDetails(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return 'Item-by-item results ($_temp0):';
  }

  @override
  String techUiTechNote(String note) {
    return 'Technician note: $note';
  }

  @override
  String get techUiNoItemResultsInLog =>
      'The last log has no per-item results — only the overall result above.';

  @override
  String techUiTechNoteQuoted(String note) {
    return 'Technician note: \"$note\"';
  }

  @override
  String techUiFieldPhotosCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return 'On-site photos by the technician ($_temp0):';
  }

  @override
  String get techUiPrevInspectionPhotos => 'Previous inspection photos';

  @override
  String techUiRelatedTicket(Object id) {
    return 'Related incident ticket: RPT-$id';
  }

  @override
  String get techUiFailedTicketOpenedNote =>
      'Because the last inspection failed, an incident ticket was opened. Resolve it and complete the acceptance to reopen this schedule for the next inspection.';

  @override
  String techUiOpenTicketToHandle(Object id) {
    return 'Open ticket RPT-$id to resolve';
  }

  @override
  String get techUiNoPrevInspection =>
      'No previous inspection data (new schedule).';

  @override
  String techUiHandleTicket(Object id) {
    return 'Resolve ticket RPT-$id';
  }

  @override
  String get techUiScheduleOtherTechShort => 'Assigned to another technician';

  @override
  String get techUiStartInspectionDue => 'Start inspection now (due)';

  @override
  String get techUiInspectNow => 'Inspect now';

  @override
  String get techUiIncidentReport => 'Incident report';

  @override
  String get techUiSavingChanges => 'Saving changes...';

  @override
  String get techUiProfileUpdated => 'Profile updated!';

  @override
  String get techUiAvatar => 'Profile photo';

  @override
  String get techUiTakeNewPhoto => 'Take a new photo';

  @override
  String get techUiChooseFromGallery => 'Choose from gallery';

  @override
  String get techUiDeleteAvatar => 'Remove profile photo';

  @override
  String get techUiUploadingAvatar => 'Uploading profile photo...';

  @override
  String get techUiAccountIdUnknown => 'Couldn\'t determine your account ID';

  @override
  String techUiPhotoUploadFailed(String error) {
    return 'Photo upload failed: $error';
  }

  @override
  String get techUiAvatarUpdated => 'Profile photo updated';

  @override
  String techUiPhotoUploadError(String error) {
    return 'Photo upload error: $error';
  }

  @override
  String get techUiDeleteAvatarQuestion => 'Remove profile photo?';

  @override
  String get techUiDeleteAvatarBody =>
      'Are you sure you want to remove your current profile photo?';

  @override
  String get techUiDelete => 'Remove';

  @override
  String get techUiDeletingPhoto => 'Removing photo...';

  @override
  String techUiPhotoDeleteFailed(String error) {
    return 'Couldn\'t remove photo: $error';
  }

  @override
  String get techUiAvatarDeleted => 'Profile photo removed';

  @override
  String techUiPhotoDeleteError(String error) {
    return 'Error removing photo: $error';
  }

  @override
  String get techUiLogoutShift => 'Log out of shift';

  @override
  String techUiLogoutConfirm(String role) {
    return 'Are you sure you want to end your shift and log out of your $role account?';
  }

  @override
  String get techUiLockerTechnician => 'Locker technician';

  @override
  String get techUiSaving => 'Saving...';

  @override
  String get techUiSaveProfileChanges => 'Save changes';

  @override
  String get techUiLogoutAccount => 'Log out of account';

  @override
  String get techUiTechnicianProfile => 'Technician profile';

  @override
  String get techUiRoleBadgeDrone => 'DRONE · Drone technician';

  @override
  String get techUiRoleBadgeLocker => 'KIOSK · Locker technician';

  @override
  String techUiStatsLoadFailed(String error) {
    return 'Couldn\'t load all stats: $error';
  }

  @override
  String get techUiShiftMetrics => 'Shift performance';

  @override
  String get techUiMetricReceived => 'Assigned';

  @override
  String get techUiMetricInProgress => 'In progress';

  @override
  String get techUiQualityRating => 'Quality rating: ';

  @override
  String get techUiNoRatingYet => 'No ratings yet';

  @override
  String get techUiEditPersonalInfo => 'Edit personal info';

  @override
  String get techUiFullNameLabel => 'Technician full name *';

  @override
  String get techUiFullNameHint => 'Enter your full name';

  @override
  String get techUiFullNameMin => 'Full name must be at least 2 characters';

  @override
  String get techUiContactPhone => 'Contact phone';

  @override
  String get techUiPhoneHint => 'e.g. 0912345678';

  @override
  String get techUiPhoneMin => 'Phone number must have at least 9 digits';

  @override
  String get techUiAccountEmailFixed => 'Account email (fixed)';

  @override
  String get techUiIdentity => 'ID';

  @override
  String get techUiRoleDroneLong => 'Drone technician (flight team)';

  @override
  String get techUiRoleLockerLong =>
      'Locker technician (compartments & hardware)';

  @override
  String get techUiRoleDroneDesc =>
      'Dispatches and maintains drones and resolves drone incident tickets.';

  @override
  String get techUiRoleLockerDesc =>
      'Maintains compartments and IoT devices and resolves locker incident tickets.';

  @override
  String techRecLoadError(Object error) {
    return 'Couldn\'t load recovery tasks: $error';
  }

  @override
  String get techRecEmptyTitle => 'No parcel recovery tasks yet';

  @override
  String get techRecEmptyHint => 'Tasks assigned to you will appear here.';

  @override
  String get techRecBanner =>
      'Recover parcels at the verified drop location. Take real photos and record GPS and parcel condition before sending to the admin for review.';

  @override
  String get techRecUrgentTag => 'Urgent search task · Drone down';

  @override
  String techRecIncidentHash(Object id) {
    return 'Incident #$id';
  }

  @override
  String get techRecNoGps => 'No GPS · check the evidence before heading out';

  @override
  String get techRecSituation => 'Situation';

  @override
  String get techRecDataAccuracy => 'Data accuracy';

  @override
  String techRecAccuracyLine(Object source, Object accuracy, Object telemetry) {
    return 'Location source: $source · accuracy $accuracy · telemetry $telemetry';
  }

  @override
  String get techRecUnknown => 'unknown';

  @override
  String get techRecTelemetryStale => 'stale';

  @override
  String get techRecTelemetryLive => 'live';

  @override
  String get techRecGpsSourceDrone => 'drone GPS';

  @override
  String get techRecGpsSourceFlightPath => 'estimated from flight path';

  @override
  String get techRecGpsSourceNone => 'none yet';

  @override
  String get techRecDirectionsToDrop => 'Directions to drop location';

  @override
  String get techRecEvidence => 'Existing evidence';

  @override
  String get techRecImageLoadError => 'Can\'t load image';

  @override
  String get techRecAccept => 'Accept task';

  @override
  String get techRecStartSearch => 'Start searching';

  @override
  String get techRecRecordResult => 'Record search result';

  @override
  String get techRecConfirmHubHandover => 'Confirm handover to Hub / warehouse';

  @override
  String techRecConfirmStationHandover(Object station) {
    return 'Confirm parcel delivered to station $station';
  }

  @override
  String get techRecSubmittedTitle => 'Result submitted';

  @override
  String get techRecSubmittedBody =>
      'The admin will verify the evidence and decide the next step.';

  @override
  String get techRecClosedTitle => 'Recovery completed';

  @override
  String get techRecClosedHubBody =>
      'The admin has verified it and the parcel is back at the Hub / warehouse. Nothing more for you to do.';

  @override
  String techRecClosedStationBody(Object station) {
    return 'The parcel was delivered to station $station. Nothing more for you to do.';
  }

  @override
  String get techRecNoGpsTitle => 'Couldn\'t get GPS location';

  @override
  String get techRecNoGpsBody =>
      'Recovery results need the coordinates where photos were taken so the admin can cross-check. Turn on location and grant location permission, then try again. Only send without GPS if location is truly unavailable — the admin will see that the evidence has no coordinates.';

  @override
  String get techRecRetryLater => 'Try later';

  @override
  String get techRecSendWithoutGps => 'Send without GPS';

  @override
  String techRecStationTitle(Object station) {
    return 'Station $station';
  }

  @override
  String get techRecHandoverHubTitle =>
      'Hand the parcel over to the Hub / warehouse?';

  @override
  String techRecHandoverStationTitle(Object station) {
    return 'Parcel delivered to station $station?';
  }

  @override
  String get techRecHandoverHubBody =>
      'Only confirm once the parcel is at the Hub / warehouse and someone has received it. After this step the Hub is responsible for the parcel.';

  @override
  String techRecHandoverStationBody(Object station) {
    return 'Only confirm once the parcel is at station $station and someone has received it. After this step the parcel waits for a drone to redeliver it to the customer.';
  }

  @override
  String get techRecHandedOver => 'Handed over';

  @override
  String get techRecHubHandoverDone =>
      'Parcel confirmed at the Hub / warehouse.';

  @override
  String techRecStationHandoverDone(Object station) {
    return 'Delivery to station $station confirmed.';
  }

  @override
  String get techRecTagIntact => 'Parcel intact, seal OK';

  @override
  String get techRecTagPackagingDamaged =>
      'Packaging slightly torn/dented from impact';

  @override
  String get techRecTagDroneStuck => 'Drone arm broken, stuck in a tree';

  @override
  String get techRecTagNotFound => 'Searched the whole area, parcel not found';

  @override
  String get techRecTagUnsafe => 'Area unsafe, can\'t be reached';

  @override
  String get techRecSheetTitle => 'Field report & recovery result';

  @override
  String get techRecSheetHint =>
      'Locker technicians must confirm their actual coordinates at the search point, add a condition note and take evidence photos.';

  @override
  String get techRecGpsConfirmed => 'Field coordinates confirmed';

  @override
  String get techRecConfirmGpsTitle => 'Confirm GPS coordinates on site';

  @override
  String get techRecConfirmGpsHint =>
      'Tap the button below to get the exact GPS coordinates where you are standing, to compare with the drone drop point.';

  @override
  String get techRecGpsUnavailable =>
      'Couldn\'t get GPS coordinates. Please turn on location and grant location permission.';

  @override
  String get techRecReadingGps => 'Reading GPS signal...';

  @override
  String get techRecConfirmGpsButton => 'Confirm field coordinates';

  @override
  String techRecCoordinates(Object lat, Object lng, Object accuracy) {
    return 'Coordinates: $lat, $lng (accuracy: ±$accuracy m)';
  }

  @override
  String techRecWithinRange(Object meters) {
    return '✓ Within the site (~$meters m from the drop point)';
  }

  @override
  String techRecOutOfRange(Object meters) {
    return '⚠️ ~$meters m from the drop point (move closer if you can)';
  }

  @override
  String get techRecRefreshGps => 'Refresh GPS';

  @override
  String get techRecSearchResult => 'Search result';

  @override
  String get techRecOutcomeFound => 'Parcel found';

  @override
  String get techRecOutcomeNotFound => 'Parcel not found';

  @override
  String get techRecOutcomeUnsafe => 'Area unsafe to search';

  @override
  String get techRecCondIntact => 'Intact';

  @override
  String get techRecCondMinor => 'Minor damage';

  @override
  String get techRecCondMajor => 'Major damage';

  @override
  String get techRecCondUnusable => 'Unusable';

  @override
  String get techRecNoteLabel => 'Field note (description required)';

  @override
  String get techRecNoteHint =>
      'Where it was found, drone state, parcel condition, temporary storage...';

  @override
  String get techRecPhotoHelper =>
      'At least 1 photo taken on site is required (with coordinates).';

  @override
  String get techRecPhotoRequired => 'Please take at least 1 photo on site.';

  @override
  String get techRecNoteRequired => 'Please enter a field note.';

  @override
  String get techRecSubmit => 'Send for admin verification';

  @override
  String techRecBringToStation(Object name) {
    return 'Take the parcel to station $name';
  }

  @override
  String techRecDistanceFromFound(Object km) {
    return '~$km km from where it was found';
  }

  @override
  String get techRecStationNoDrone =>
      'Station is out of drones — the parcel waits there for one';

  @override
  String get techRecStationHasDrone => 'Station has a drone ready to redeliver';

  @override
  String get techRecDirectionsToStation => 'Directions to station';

  @override
  String get techRecErrHandoverFailed =>
      'Direct handover failed — check the order\'s 6-digit PIN or QR code and try again.';

  @override
  String get techRecErrInvalidOtp => 'The order\'s PIN/QR code is incorrect.';

  @override
  String get techRecErrRelocateFailed =>
      'Couldn\'t move the order to the new compartment. The items are still in the old one — try again or choose another option.';

  @override
  String get techRecErrSlaNotAssignee =>
      'Only the technician assigned to the ticket can extend its SLA.';

  @override
  String get techRecErrSlaLimitReached =>
      'This ticket has no SLA self-extensions left — contact an admin if you need more time.';

  @override
  String get techRecErrSlaHoursExceeded =>
      'The extension exceeds the hours allowed per extension.';

  @override
  String get techRecErrSlaReasonRequired =>
      'Please give a reason for the SLA extension.';

  @override
  String get techRecErrInvalidExtensionHours =>
      'The extension must be at least 1 hour.';

  @override
  String get techRecErrSlaRestricted =>
      'You have too many tickets past their SLA, so you can\'t take new jobs for now.';

  @override
  String get techRecErrReleaseReasonRequired =>
      'Please give a reason for returning the ticket to the queue.';

  @override
  String get techRecErrReportNotClaimed =>
      'The ticket is still in the queue — no technician has taken it.';

  @override
  String get techRecErrReportResolved => 'This ticket is already completed.';

  @override
  String get techRecErrReportOpen =>
      'This compartment/landing pad has an open incident ticket — complete that ticket first.';

  @override
  String get techRecErrTargetBoxRequired =>
      'Choose an empty target compartment to move the items to.';

  @override
  String get techRecErrTargetBoxUnavailable =>
      'The target compartment is no longer empty — reload the layout and choose another.';

  @override
  String get techRecErrBoxNotFault =>
      'The compartment is no longer in a fault state.';

  @override
  String get techRecErrHandoverOtpRequired =>
      'The order\'s 6-digit PIN or QR code is required for handover.';

  @override
  String get techRecErrHandoverOtpUnavailable =>
      'The order has no pickup code yet, so it can\'t be handed over directly.';

  @override
  String get techRecErrSealRequired =>
      'Enter the seal number printed on the seal bag.';

  @override
  String get techRecErrIncidentActionInvalid => 'Invalid resolution option.';

  @override
  String get techRecErrIncidentBoxNotInLocker =>
      'The selected compartment isn\'t in this ticket\'s locker.';

  @override
  String get techRecErrForceOpenReportRequired =>
      'Emergency-open photos can only be saved when opening from an incident ticket.';

  @override
  String get techRecErrForceOpenReportMismatch =>
      'The incident ticket doesn\'t belong to this compartment\'s locker.';

  @override
  String get techRecErrDroneReportRequired => 'This isn\'t a drone ticket.';

  @override
  String get techRecErrDeviceNotPaired =>
      'The device isn\'t paired with any locker.';

  @override
  String get techRecErrDeviceNotInScope =>
      'The device isn\'t in a locker you\'re responsible for.';

  @override
  String get techRecErrDeviceOnlineNotAllowed =>
      'Online status is computed by the server and can\'t be set manually.';
}
