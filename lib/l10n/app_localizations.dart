import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('vi'),
  ];

  /// No description provided for @commonRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get commonRetry;

  /// No description provided for @commonCancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get commonCancel;

  /// No description provided for @commonLogout.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get commonLogout;

  /// No description provided for @commonLoggingOut.
  ///
  /// In vi, this message translates to:
  /// **'Đang đăng xuất...'**
  String get commonLoggingOut;

  /// No description provided for @commonLoggedOut.
  ///
  /// In vi, this message translates to:
  /// **'Đã đăng xuất'**
  String get commonLoggedOut;

  /// No description provided for @commonLogoutConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản?'**
  String get commonLogoutConfirm;

  /// No description provided for @commonNotifications.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo'**
  String get commonNotifications;

  /// No description provided for @commonTransactions.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch'**
  String get commonTransactions;

  /// No description provided for @commonPayment.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán'**
  String get commonPayment;

  /// No description provided for @commonWebsite.
  ///
  /// In vi, this message translates to:
  /// **'Website'**
  String get commonWebsite;

  /// No description provided for @commonTermsOfUse.
  ///
  /// In vi, this message translates to:
  /// **'Điều khoản sử dụng'**
  String get commonTermsOfUse;

  /// No description provided for @commonPrivacyPolicy.
  ///
  /// In vi, this message translates to:
  /// **'Chính sách bảo mật'**
  String get commonPrivacyPolicy;

  /// No description provided for @languageVietnamese.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Việt'**
  String get languageVietnamese;

  /// No description provided for @languageEnglish.
  ///
  /// In vi, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @profileTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ'**
  String get profileTitle;

  /// No description provided for @profileSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý tài khoản của bạn'**
  String get profileSubtitle;

  /// No description provided for @profileLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải hồ sơ...'**
  String get profileLoading;

  /// No description provided for @profileLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được hồ sơ'**
  String get profileLoadFailed;

  /// No description provided for @profileLoadFailedDot.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được hồ sơ.'**
  String get profileLoadFailedDot;

  /// No description provided for @profileRefreshFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không làm mới được hồ sơ: {error}'**
  String profileRefreshFailed(Object error);

  /// No description provided for @profileSectionAccount.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản'**
  String get profileSectionAccount;

  /// No description provided for @profilePersonalInfo.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin cá nhân'**
  String get profilePersonalInfo;

  /// No description provided for @profileRefundAccount.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản nhận hoàn tiền'**
  String get profileRefundAccount;

  /// No description provided for @profileLoyalty.
  ///
  /// In vi, this message translates to:
  /// **'Điểm thưởng'**
  String get profileLoyalty;

  /// No description provided for @profileLoyaltySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Điểm tích lũy, hạng thành viên và lịch sử'**
  String get profileLoyaltySubtitle;

  /// No description provided for @profileFaceReRegister.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký lại khuôn mặt'**
  String get profileFaceReRegister;

  /// No description provided for @profileFaceRegister.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký khuôn mặt'**
  String get profileFaceRegister;

  /// No description provided for @profileSecurity.
  ///
  /// In vi, this message translates to:
  /// **'Bảo mật'**
  String get profileSecurity;

  /// No description provided for @profileVouchers.
  ///
  /// In vi, this message translates to:
  /// **'Ưu đãi & Quà tặng'**
  String get profileVouchers;

  /// No description provided for @profileSectionManage.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý'**
  String get profileSectionManage;

  /// No description provided for @profileDelegations.
  ///
  /// In vi, this message translates to:
  /// **'Đơn ủy quyền'**
  String get profileDelegations;

  /// No description provided for @profileRefunds.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tiền'**
  String get profileRefunds;

  /// No description provided for @profileMyReports.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo của tôi'**
  String get profileMyReports;

  /// No description provided for @profileBleTest.
  ///
  /// In vi, this message translates to:
  /// **'Thử mở ô qua Bluetooth'**
  String get profileBleTest;

  /// No description provided for @profileSectionSettings.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get profileSectionSettings;

  /// No description provided for @profileLanguage.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get profileLanguage;

  /// No description provided for @profileLanguageSheetSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ngôn ngữ hiển thị cho ứng dụng'**
  String get profileLanguageSheetSubtitle;

  /// No description provided for @profileLanguageViDescription.
  ///
  /// In vi, this message translates to:
  /// **'Hiển thị bằng tiếng Việt'**
  String get profileLanguageViDescription;

  /// No description provided for @profileLanguageEnDescription.
  ///
  /// In vi, this message translates to:
  /// **'Hiển thị bằng tiếng Anh'**
  String get profileLanguageEnDescription;

  /// No description provided for @profileTheme.
  ///
  /// In vi, this message translates to:
  /// **'Giao diện'**
  String get profileTheme;

  /// No description provided for @profileLocation.
  ///
  /// In vi, this message translates to:
  /// **'Vị trí'**
  String get profileLocation;

  /// No description provided for @profileLocationSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Quyền truy cập vị trí để tìm tủ gần bạn'**
  String get profileLocationSubtitle;

  /// No description provided for @profileSectionSupport.
  ///
  /// In vi, this message translates to:
  /// **'Hỗ trợ'**
  String get profileSectionSupport;

  /// No description provided for @profileAssistant.
  ///
  /// In vi, this message translates to:
  /// **'Trợ lý AI Lock.R'**
  String get profileAssistant;

  /// No description provided for @profileAssistantSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Hỏi đáp & hỗ trợ thông minh 24/7'**
  String get profileAssistantSubtitle;

  /// No description provided for @profileQuickHelp.
  ///
  /// In vi, this message translates to:
  /// **'Trợ giúp nhanh'**
  String get profileQuickHelp;

  /// No description provided for @profileQuickHelpSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Hướng dẫn sử dụng & câu hỏi thường gặp'**
  String get profileQuickHelpSubtitle;

  /// No description provided for @profileContact.
  ///
  /// In vi, this message translates to:
  /// **'Liên hệ'**
  String get profileContact;

  /// No description provided for @profileTerms.
  ///
  /// In vi, this message translates to:
  /// **'Điều khoản'**
  String get profileTerms;

  /// No description provided for @profileHelpSendTitle.
  ///
  /// In vi, this message translates to:
  /// **'Gửi hàng'**
  String get profileHelpSendTitle;

  /// No description provided for @profileHelpSendBody.
  ///
  /// In vi, this message translates to:
  /// **'Chọn cửa hàng → chạm ô trống → Gửi hàng → thanh toán → dùng PIN/nút \"Mở tủ\" để bỏ hàng.'**
  String get profileHelpSendBody;

  /// No description provided for @profileHelpRentTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thuê tủ giữ đồ'**
  String get profileHelpRentTitle;

  /// No description provided for @profileHelpRentBody.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ô trống → Thuê tủ → chọn số giờ → thanh toán → PIN dùng nhiều lần tới hết hạn.'**
  String get profileHelpRentBody;

  /// No description provided for @profileHelpCantOpenTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được ô?'**
  String get profileHelpCantOpenTitle;

  /// No description provided for @profileHelpCantOpenBody.
  ///
  /// In vi, this message translates to:
  /// **'Vào Đơn tủ → mở đơn → \"Báo ô lỗi\". Đội bảo trì sẽ xử lý và bạn nhận được thông báo.'**
  String get profileHelpCantOpenBody;

  /// No description provided for @profileHelpPaymentBody.
  ///
  /// In vi, this message translates to:
  /// **'Mọi đơn thanh toán bằng chuyển khoản SePay (VietQR): quét mã hoặc bấm \"Thanh toán bằng app ngân hàng\" để mở app ngân hàng điền sẵn. Xem lại các khoản đã trả ở mục Giao dịch.'**
  String get profileHelpPaymentBody;

  /// No description provided for @profileContactTitle.
  ///
  /// In vi, this message translates to:
  /// **'Liên hệ hỗ trợ'**
  String get profileContactTitle;

  /// No description provided for @profileContactEmail.
  ///
  /// In vi, this message translates to:
  /// **'Email hỗ trợ'**
  String get profileContactEmail;

  /// No description provided for @profileContactHours.
  ///
  /// In vi, this message translates to:
  /// **'Giờ hỗ trợ'**
  String get profileContactHours;

  /// No description provided for @profileContactHoursValue.
  ///
  /// In vi, this message translates to:
  /// **'08:00 – 22:00 hằng ngày'**
  String get profileContactHoursValue;

  /// No description provided for @profileThemeSheetSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Chọn chủ đề hiển thị cho ứng dụng'**
  String get profileThemeSheetSubtitle;

  /// No description provided for @profileThemeLight.
  ///
  /// In vi, this message translates to:
  /// **'Sáng'**
  String get profileThemeLight;

  /// No description provided for @profileThemeLightDescription.
  ///
  /// In vi, this message translates to:
  /// **'Giao diện nền trắng'**
  String get profileThemeLightDescription;

  /// No description provided for @profileThemeDark.
  ///
  /// In vi, this message translates to:
  /// **'Tối'**
  String get profileThemeDark;

  /// No description provided for @profileThemeDarkDescription.
  ///
  /// In vi, this message translates to:
  /// **'Giao diện nền tối'**
  String get profileThemeDarkDescription;

  /// No description provided for @profileThemeSystem.
  ///
  /// In vi, this message translates to:
  /// **'Theo hệ thống'**
  String get profileThemeSystem;

  /// No description provided for @profileThemeSystemDescription.
  ///
  /// In vi, this message translates to:
  /// **'Tự động theo cài đặt thiết bị'**
  String get profileThemeSystemDescription;

  /// No description provided for @commonConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận'**
  String get commonConfirm;

  /// No description provided for @commonContinue.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get commonContinue;

  /// No description provided for @commonSave.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get commonSave;

  /// No description provided for @commonLater.
  ///
  /// In vi, this message translates to:
  /// **'Để sau'**
  String get commonLater;

  /// No description provided for @commonLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải...'**
  String get commonLoading;

  /// No description provided for @commonFullName.
  ///
  /// In vi, this message translates to:
  /// **'Họ và tên'**
  String get commonFullName;

  /// No description provided for @commonFullNameHint.
  ///
  /// In vi, this message translates to:
  /// **'Nguyễn Văn A'**
  String get commonFullNameHint;

  /// No description provided for @commonEmail.
  ///
  /// In vi, this message translates to:
  /// **'Email'**
  String get commonEmail;

  /// No description provided for @commonPhoneNumber.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại'**
  String get commonPhoneNumber;

  /// No description provided for @commonPassword.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu'**
  String get commonPassword;

  /// No description provided for @commonPhoneShort.
  ///
  /// In vi, this message translates to:
  /// **'SĐT'**
  String get commonPhoneShort;

  /// No description provided for @authLogin.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get authLogin;

  /// No description provided for @authRegister.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký'**
  String get authRegister;

  /// No description provided for @authCreateAccount.
  ///
  /// In vi, this message translates to:
  /// **'Tạo tài khoản'**
  String get authCreateAccount;

  /// No description provided for @authRegisterSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký thành công!'**
  String get authRegisterSuccess;

  /// No description provided for @authRegisterSuccessPleaseLogin.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký thành công! Vui lòng đăng nhập.'**
  String get authRegisterSuccessPleaseLogin;

  /// No description provided for @authEnterIdentifierAndPassword.
  ///
  /// In vi, this message translates to:
  /// **'Nhập email/SĐT và mật khẩu'**
  String get authEnterIdentifierAndPassword;

  /// No description provided for @authPleaseAcceptTerms.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng đồng ý với Điều khoản sử dụng'**
  String get authPleaseAcceptTerms;

  /// No description provided for @authTagline.
  ///
  /// In vi, this message translates to:
  /// **'Tủ thông minh • Giao nhận 24/7'**
  String get authTagline;

  /// No description provided for @authEmailOrPhone.
  ///
  /// In vi, this message translates to:
  /// **'Email / Số điện thoại'**
  String get authEmailOrPhone;

  /// No description provided for @authLoginWithOtp.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập bằng OTP'**
  String get authLoginWithOtp;

  /// No description provided for @authForgotPasswordQuestion.
  ///
  /// In vi, this message translates to:
  /// **'Quên mật khẩu?'**
  String get authForgotPasswordQuestion;

  /// No description provided for @authEnterFullName.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập họ và tên'**
  String get authEnterFullName;

  /// No description provided for @authEnterEmail.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập email'**
  String get authEnterEmail;

  /// No description provided for @authInvalidEmail.
  ///
  /// In vi, this message translates to:
  /// **'Email không hợp lệ'**
  String get authInvalidEmail;

  /// No description provided for @authEnterPhone.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập số điện thoại'**
  String get authEnterPhone;

  /// No description provided for @authEnterPassword.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập mật khẩu'**
  String get authEnterPassword;

  /// No description provided for @authPasswordMin6.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu phải có ít nhất 6 ký tự'**
  String get authPasswordMin6;

  /// No description provided for @authAgreePrefix.
  ///
  /// In vi, this message translates to:
  /// **'Tôi đồng ý với '**
  String get authAgreePrefix;

  /// No description provided for @authOrContinueWith.
  ///
  /// In vi, this message translates to:
  /// **'Hoặc tiếp tục với'**
  String get authOrContinueWith;

  /// No description provided for @authNoAccount.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có tài khoản? '**
  String get authNoAccount;

  /// No description provided for @authHaveAccount.
  ///
  /// In vi, this message translates to:
  /// **'Đã có tài khoản? '**
  String get authHaveAccount;

  /// No description provided for @authRegisterNow.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký ngay'**
  String get authRegisterNow;

  /// No description provided for @authEnterValidEmailForOtp.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập Email hợp lệ để nhận OTP'**
  String get authEnterValidEmailForOtp;

  /// No description provided for @authEnterOtp.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã OTP'**
  String get authEnterOtp;

  /// No description provided for @authOtpSentTo.
  ///
  /// In vi, this message translates to:
  /// **'Mã OTP đã được gửi đến {email}'**
  String authOtpSentTo(Object email);

  /// No description provided for @authOtpSendingTo.
  ///
  /// In vi, this message translates to:
  /// **'Đang gửi mã OTP đến {email}...'**
  String authOtpSendingTo(Object email);

  /// No description provided for @authOtp6Digits.
  ///
  /// In vi, this message translates to:
  /// **'Mã OTP (6 số)'**
  String get authOtp6Digits;

  /// No description provided for @authPasswordHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mật khẩu'**
  String get authPasswordHint;

  /// No description provided for @authFaceLogin.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập khuôn mặt'**
  String get authFaceLogin;

  /// No description provided for @authRegisterFailedRetry.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký thất bại. Vui lòng thử lại.'**
  String get authRegisterFailedRetry;

  /// No description provided for @authFaceMismatch.
  ///
  /// In vi, this message translates to:
  /// **'Khuôn mặt không khớp hoặc chưa được đăng ký'**
  String get authFaceMismatch;

  /// No description provided for @authFaceAiBusy.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống AI đang bận hoặc ảnh không hợp lệ'**
  String get authFaceAiBusy;

  /// No description provided for @authLoginFailedRetry.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập thất bại. Vui lòng thử lại.'**
  String get authLoginFailedRetry;

  /// No description provided for @authNoTokenFromServer.
  ///
  /// In vi, this message translates to:
  /// **'Không nhận được token xác thực từ server.'**
  String get authNoTokenFromServer;

  /// No description provided for @authFaceRegisterFailed.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký khuôn mặt thất bại'**
  String get authFaceRegisterFailed;

  /// No description provided for @authEmailNotRegistered.
  ///
  /// In vi, this message translates to:
  /// **'Email chưa được đăng ký tài khoản. Vui lòng kiểm tra lại.'**
  String get authEmailNotRegistered;

  /// No description provided for @authOtpInvalidOrExpired.
  ///
  /// In vi, this message translates to:
  /// **'Mã OTP không hợp lệ hoặc đã hết hạn.'**
  String get authOtpInvalidOrExpired;

  /// No description provided for @authPasswordsDontMatch.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu nhập lại không khớp.'**
  String get authPasswordsDontMatch;

  /// No description provided for @authResetPasswordFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể đặt lại mật khẩu. Vui lòng thử lại.'**
  String get authResetPasswordFailed;

  /// No description provided for @authEmailTaken.
  ///
  /// In vi, this message translates to:
  /// **'Email đã được đăng ký. Vui lòng dùng email khác.'**
  String get authEmailTaken;

  /// No description provided for @authPhoneTaken.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại đã được đăng ký. Vui lòng dùng số khác.'**
  String get authPhoneTaken;

  /// No description provided for @authEmailOrPhoneTaken.
  ///
  /// In vi, this message translates to:
  /// **'Email hoặc số điện thoại đã được đăng ký.'**
  String get authEmailOrPhoneTaken;

  /// No description provided for @authRegisterServerError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi server khi đăng ký. Vui lòng thử lại.'**
  String get authRegisterServerError;

  /// No description provided for @authOtpServerTokenError.
  ///
  /// In vi, this message translates to:
  /// **'Mã OTP đúng nhưng hệ thống xác thực đang lỗi nội bộ (chưa trả được token). Vui lòng thử lại sau ít phút.'**
  String get authOtpServerTokenError;

  /// No description provided for @authOtpVerifyFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể xác thực OTP. Vui lòng thử lại.'**
  String get authOtpVerifyFailed;

  /// No description provided for @authResetPasswordSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đặt lại mật khẩu thành công. Vui lòng đăng nhập bằng mật khẩu mới.'**
  String get authResetPasswordSuccess;

  /// No description provided for @authEnterValidEmail.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập email hợp lệ.'**
  String get authEnterValidEmail;

  /// No description provided for @authOtpMustBe6Digits.
  ///
  /// In vi, this message translates to:
  /// **'Mã OTP gồm 6 chữ số.'**
  String get authOtpMustBe6Digits;

  /// No description provided for @authNewPasswordMin6.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu mới phải có ít nhất 6 ký tự.'**
  String get authNewPasswordMin6;

  /// No description provided for @authForgotPasswordTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quên mật khẩu'**
  String get authForgotPasswordTitle;

  /// No description provided for @authEnterOtpAndNewPassword.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã OTP & mật khẩu mới'**
  String get authEnterOtpAndNewPassword;

  /// No description provided for @authResetPassword.
  ///
  /// In vi, this message translates to:
  /// **'Đặt lại mật khẩu'**
  String get authResetPassword;

  /// No description provided for @authResetOtpSentTo.
  ///
  /// In vi, this message translates to:
  /// **'Mã OTP gồm 6 chữ số đã được gửi tới\n{email} (hết hạn sau 5 phút).'**
  String authResetOtpSentTo(Object email);

  /// No description provided for @authResetEnterEmail.
  ///
  /// In vi, this message translates to:
  /// **'Nhập email đã đăng ký tài khoản.\nChúng tôi sẽ gửi mã OTP để đặt lại mật khẩu.'**
  String get authResetEnterEmail;

  /// No description provided for @authSendOtp.
  ///
  /// In vi, this message translates to:
  /// **'Gửi mã OTP'**
  String get authSendOtp;

  /// No description provided for @authResendOtp.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại mã OTP'**
  String get authResendOtp;

  /// No description provided for @authOtpCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã OTP'**
  String get authOtpCode;

  /// No description provided for @authNewPassword.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu mới'**
  String get authNewPassword;

  /// No description provided for @authConfirmNewPassword.
  ///
  /// In vi, this message translates to:
  /// **'Nhập lại mật khẩu mới'**
  String get authConfirmNewPassword;

  /// No description provided for @authPhoneLogin.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập bằng số điện thoại'**
  String get authPhoneLogin;

  /// No description provided for @authSmsSentTo.
  ///
  /// In vi, this message translates to:
  /// **'Mã 6 số đã được gửi qua SMS tới {phone}.'**
  String authSmsSentTo(Object phone);

  /// No description provided for @authYourNumber.
  ///
  /// In vi, this message translates to:
  /// **'số của bạn'**
  String get authYourNumber;

  /// No description provided for @authPhoneAutoCreateAccount.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có tài khoản? Hệ thống tự tạo tài khoản khi bạn xác nhận mã.'**
  String get authPhoneAutoCreateAccount;

  /// No description provided for @authPhoneFormatHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập số nội địa (0xxx) hoặc quốc tế (+84xxx) đều được.'**
  String get authPhoneFormatHint;

  /// No description provided for @authChangePhone.
  ///
  /// In vi, this message translates to:
  /// **'Đổi số điện thoại'**
  String get authChangePhone;

  /// No description provided for @authResendCodeIn.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại mã ({seconds}s)'**
  String authResendCodeIn(Object seconds);

  /// No description provided for @authResendCode.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại mã'**
  String get authResendCode;

  /// No description provided for @authProfileSaved.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu thông tin tài khoản'**
  String get authProfileSaved;

  /// No description provided for @authProfileSaveFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không lưu được thông tin. Vui lòng thử lại.'**
  String get authProfileSaveFailed;

  /// No description provided for @authCompleteRegistration.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất đăng ký'**
  String get authCompleteRegistration;

  /// No description provided for @authCompleteRegistrationBody.
  ///
  /// In vi, this message translates to:
  /// **'Cho chúng tôi biết tên của bạn để hiển thị trên đơn hàng và khi liên hệ hỗ trợ.'**
  String get authCompleteRegistrationBody;

  /// No description provided for @authEmailOptional.
  ///
  /// In vi, this message translates to:
  /// **'Email (không bắt buộc)'**
  String get authEmailOptional;

  /// No description provided for @authBiometricReason.
  ///
  /// In vi, this message translates to:
  /// **'Xác thực để mở Lock.R'**
  String get authBiometricReason;

  /// No description provided for @authSplashTagline.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống tủ khóa thông minh 24/7'**
  String get authSplashTagline;

  /// No description provided for @authBiometricRequired.
  ///
  /// In vi, this message translates to:
  /// **'Cần xác thực sinh trắc học để tiếp tục'**
  String get authBiometricRequired;

  /// No description provided for @authBiometricButton.
  ///
  /// In vi, this message translates to:
  /// **'Xác thực vân tay / Face ID'**
  String get authBiometricButton;

  /// No description provided for @authLogoutUsePassword.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất và dùng mật khẩu'**
  String get authLogoutUsePassword;

  /// No description provided for @authGoogleLoginFailed.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập Google thất bại'**
  String get authGoogleLoginFailed;

  /// No description provided for @authFacebookLoginFailed.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập Facebook thất bại'**
  String get authFacebookLoginFailed;

  /// No description provided for @authOtp6DigitsShort.
  ///
  /// In vi, this message translates to:
  /// **'Mã OTP gồm 6 chữ số'**
  String get authOtp6DigitsShort;

  /// No description provided for @authOtpConfirmFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không xác nhận được mã OTP. Vui lòng thử lại.'**
  String get authOtpConfirmFailed;

  /// No description provided for @authOtpVerification.
  ///
  /// In vi, this message translates to:
  /// **'Xác thực OTP'**
  String get authOtpVerification;

  /// No description provided for @authCaptureFaceFirst.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng lấy mẫu khuôn mặt trước'**
  String get authCaptureFaceFirst;

  /// No description provided for @authPhoneLoginDisabled.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập bằng SĐT chưa được bật. Vui lòng dùng email để đăng nhập.'**
  String get authPhoneLoginDisabled;

  /// No description provided for @authOtpSendFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không gửi được mã OTP. Vui lòng thử lại.'**
  String get authOtpSendFailed;

  /// No description provided for @authInvalidPhone.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại không hợp lệ. Vui lòng kiểm tra lại (VD: 0912345678).'**
  String get authInvalidPhone;

  /// No description provided for @authTooManyRequests.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã yêu cầu mã quá nhiều lần. Vui lòng thử lại sau ít phút.'**
  String get authTooManyRequests;

  /// No description provided for @authSmsQuotaExceeded.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống đã hết lượt gửi SMS trong hôm nay. Vui lòng thử lại sau hoặc đăng nhập bằng email.'**
  String get authSmsQuotaExceeded;

  /// No description provided for @authOtpWrong.
  ///
  /// In vi, this message translates to:
  /// **'Mã OTP không đúng. Vui lòng kiểm tra lại.'**
  String get authOtpWrong;

  /// No description provided for @authEnterOtpCode.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập mã OTP.'**
  String get authEnterOtpCode;

  /// No description provided for @authOtpExpired.
  ///
  /// In vi, this message translates to:
  /// **'Mã OTP đã hết hạn. Vui lòng bấm \"Gửi lại mã\".'**
  String get authOtpExpired;

  /// No description provided for @authAppNotVerified.
  ///
  /// In vi, this message translates to:
  /// **'Ứng dụng chưa được xác minh để gửi mã OTP. Vui lòng cập nhật ứng dụng hoặc dùng email để đăng nhập.'**
  String get authAppNotVerified;

  /// No description provided for @authRecaptchaFailed.
  ///
  /// In vi, this message translates to:
  /// **'Xác minh reCAPTCHA không thành công. Vui lòng thử lại.'**
  String get authRecaptchaFailed;

  /// No description provided for @authSitePhoneNotAllowed.
  ///
  /// In vi, this message translates to:
  /// **'Trang web này chưa được phép đăng nhập bằng SĐT. Vui lòng dùng email để đăng nhập.'**
  String get authSitePhoneNotAllowed;

  /// No description provided for @authNoNetwork.
  ///
  /// In vi, this message translates to:
  /// **'Không có kết nối mạng. Vui lòng kiểm tra Internet rồi thử lại.'**
  String get authNoNetwork;

  /// No description provided for @authAccountDisabled.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản này đã bị khoá. Vui lòng liên hệ hỗ trợ.'**
  String get authAccountDisabled;

  /// No description provided for @authVerificationCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Đã huỷ xác minh. Vui lòng thử lại.'**
  String get authVerificationCancelled;

  /// No description provided for @authGooglePopupBlocked.
  ///
  /// In vi, this message translates to:
  /// **'Trình duyệt đã chặn cửa sổ đăng nhập Google. Hãy cho phép cửa sổ bật lên rồi thử lại.'**
  String get authGooglePopupBlocked;

  /// No description provided for @authGoogleLoginDisabled.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập bằng Google chưa được bật. Vui lòng dùng email để đăng nhập.'**
  String get authGoogleLoginDisabled;

  /// No description provided for @authSiteGoogleNotAllowed.
  ///
  /// In vi, this message translates to:
  /// **'Trang web này chưa được phép đăng nhập bằng Google. Vui lòng dùng email để đăng nhập.'**
  String get authSiteGoogleNotAllowed;

  /// No description provided for @authGoogleEmailOtherProvider.
  ///
  /// In vi, this message translates to:
  /// **'Email Google này đã gắn với cách đăng nhập khác. Vui lòng đăng nhập bằng cách bạn đã dùng trước đó.'**
  String get authGoogleEmailOtherProvider;

  /// No description provided for @authSessionVerifyFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không xác thực được phiên đăng nhập. Vui lòng thử lại.'**
  String get authSessionVerifyFailed;

  /// No description provided for @commonCancelAlt.
  ///
  /// In vi, this message translates to:
  /// **'Huỷ'**
  String get commonCancelAlt;

  /// No description provided for @commonClose.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get commonClose;

  /// No description provided for @commonDone.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất'**
  String get commonDone;

  /// No description provided for @commonGotIt.
  ///
  /// In vi, this message translates to:
  /// **'Đã hiểu'**
  String get commonGotIt;

  /// No description provided for @commonOpenSettings.
  ///
  /// In vi, this message translates to:
  /// **'Mở Cài đặt'**
  String get commonOpenSettings;

  /// No description provided for @commonSearchHint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm...'**
  String get commonSearchHint;

  /// No description provided for @commonSeeAll.
  ///
  /// In vi, this message translates to:
  /// **'XEM TẤT CẢ'**
  String get commonSeeAll;

  /// No description provided for @commonLoginRequiredFeature.
  ///
  /// In vi, this message translates to:
  /// **'Bạn cần đăng nhập để sử dụng tính năng này'**
  String get commonLoginRequiredFeature;

  /// No description provided for @commonLoginTitleCase.
  ///
  /// In vi, this message translates to:
  /// **'Đăng Nhập'**
  String get commonLoginTitleCase;

  /// No description provided for @commonRegisterTitleCase.
  ///
  /// In vi, this message translates to:
  /// **'Đăng Ký'**
  String get commonRegisterTitleCase;

  /// No description provided for @commonBrandEyebrow.
  ///
  /// In vi, this message translates to:
  /// **'LOCK.R • HỆ THỐNG TỦ THÔNG MINH'**
  String get commonBrandEyebrow;

  /// No description provided for @commonUnknown.
  ///
  /// In vi, this message translates to:
  /// **'Không xác định'**
  String get commonUnknown;

  /// No description provided for @commonUndetermined.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xác định'**
  String get commonUndetermined;

  /// No description provided for @commonError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi'**
  String get commonError;

  /// No description provided for @commonSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Thành công'**
  String get commonSuccess;

  /// No description provided for @commonFailed.
  ///
  /// In vi, this message translates to:
  /// **'Thất bại'**
  String get commonFailed;

  /// No description provided for @commonPending.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ'**
  String get commonPending;

  /// No description provided for @deadlineAt.
  ///
  /// In vi, this message translates to:
  /// **'{time} ngày {date}'**
  String deadlineAt(Object time, Object date);

  /// No description provided for @navHome.
  ///
  /// In vi, this message translates to:
  /// **'Trang chủ'**
  String get navHome;

  /// No description provided for @navLockers.
  ///
  /// In vi, this message translates to:
  /// **'Tủ'**
  String get navLockers;

  /// No description provided for @navAssistant.
  ///
  /// In vi, this message translates to:
  /// **'Trợ lý AI'**
  String get navAssistant;

  /// No description provided for @navOrders.
  ///
  /// In vi, this message translates to:
  /// **'Đơn hàng'**
  String get navOrders;

  /// No description provided for @navProfile.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ'**
  String get navProfile;

  /// No description provided for @routerPolicy.
  ///
  /// In vi, this message translates to:
  /// **'Chính sách'**
  String get routerPolicy;

  /// No description provided for @routerMissingDestination.
  ///
  /// In vi, this message translates to:
  /// **'Thiếu toạ độ điểm đến.'**
  String get routerMissingDestination;

  /// No description provided for @routerDestination.
  ///
  /// In vi, this message translates to:
  /// **'Điểm đến'**
  String get routerDestination;

  /// No description provided for @backPressAgainToExit.
  ///
  /// In vi, this message translates to:
  /// **'Bấm quay lại lần nữa để thoát'**
  String get backPressAgainToExit;

  /// No description provided for @paymentMethodUnsupported.
  ///
  /// In vi, this message translates to:
  /// **'Phương thức thanh toán này không còn được hỗ trợ. Vui lòng thanh toán bằng chuyển khoản SePay (VietQR).'**
  String get paymentMethodUnsupported;

  /// No description provided for @qrExpired.
  ///
  /// In vi, this message translates to:
  /// **'Mã QR hết hạn hoặc phiên đã hết hạn.'**
  String get qrExpired;

  /// No description provided for @qrAlreadyUsed.
  ///
  /// In vi, this message translates to:
  /// **'Mã QR đã được sử dụng.'**
  String get qrAlreadyUsed;

  /// No description provided for @errorTimeout.
  ///
  /// In vi, this message translates to:
  /// **'Kết nối timeout. Vui lòng thử lại.'**
  String get errorTimeout;

  /// No description provided for @errorCannotConnect.
  ///
  /// In vi, this message translates to:
  /// **'Không thể kết nối đến server. Kiểm tra kết nối mạng.'**
  String get errorCannotConnect;

  /// No description provided for @errorRequestCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Request đã bị hủy.'**
  String get errorRequestCancelled;

  /// No description provided for @errorUnknown.
  ///
  /// In vi, this message translates to:
  /// **'Đã xảy ra lỗi không xác định.'**
  String get errorUnknown;

  /// No description provided for @errorNoResponse.
  ///
  /// In vi, this message translates to:
  /// **'Không có response từ server.'**
  String get errorNoResponse;

  /// No description provided for @errorSessionExpired.
  ///
  /// In vi, this message translates to:
  /// **'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.'**
  String get errorSessionExpired;

  /// No description provided for @errorForbidden.
  ///
  /// In vi, this message translates to:
  /// **'Bạn không có quyền thực hiện hành động này.'**
  String get errorForbidden;

  /// No description provided for @errorSystemBusy.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống đang bận hoặc đang bảo trì. Vui lòng thử lại sau ít phút.'**
  String get errorSystemBusy;

  /// No description provided for @errorServer.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi server. Vui lòng thử lại sau.'**
  String get errorServer;

  /// No description provided for @errorNotSupportedYet.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ chưa hỗ trợ chức năng này. Vui lòng thử lại sau.'**
  String get errorNotSupportedYet;

  /// No description provided for @errorGenericRetry.
  ///
  /// In vi, this message translates to:
  /// **'Đã xảy ra lỗi. Vui lòng thử lại.'**
  String get errorGenericRetry;

  /// No description provided for @bleOpenedBox.
  ///
  /// In vi, this message translates to:
  /// **'Đã mở ô {box}'**
  String bleOpenedBox(Object box);

  /// No description provided for @bleNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không thấy tủ qua Bluetooth. Hãy đứng sát tủ (dưới 2 m) rồi thử lại.'**
  String get bleNotFound;

  /// No description provided for @bleConnectFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không kết nối được Bluetooth với tủ. Thử lại sau vài giây.'**
  String get bleConnectFailed;

  /// No description provided for @bleNoService.
  ///
  /// In vi, this message translates to:
  /// **'Tủ chưa bật chức năng mở ô qua Bluetooth (bộ điều khiển cần cập nhật).'**
  String get bleNoService;

  /// No description provided for @bleTimeout.
  ///
  /// In vi, this message translates to:
  /// **'Tủ không trả lời. Kiểm tra ô đã mở chưa rồi thử lại.'**
  String get bleTimeout;

  /// No description provided for @bleOff.
  ///
  /// In vi, this message translates to:
  /// **'Bluetooth của điện thoại đang tắt.'**
  String get bleOff;

  /// No description provided for @blePermissionDenied.
  ///
  /// In vi, this message translates to:
  /// **'App chưa được cấp quyền Bluetooth.'**
  String get blePermissionDenied;

  /// No description provided for @bleUnsupported.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị này không hỗ trợ Bluetooth (chỉ dùng được trên app Android/iOS).'**
  String get bleUnsupported;

  /// No description provided for @bleBadCode.
  ///
  /// In vi, this message translates to:
  /// **'Tủ không chấp nhận mã mở ô.'**
  String get bleBadCode;

  /// No description provided for @bleExpired.
  ///
  /// In vi, this message translates to:
  /// **'Mã mở ô đã hết hạn. Bấm mở lại để lấy mã mới.'**
  String get bleExpired;

  /// No description provided for @bleReplayed.
  ///
  /// In vi, this message translates to:
  /// **'Mã này đã dùng rồi. Bấm mở lại để lấy mã mới.'**
  String get bleReplayed;

  /// No description provided for @bleWrongLocker.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đang kết nối nhầm tủ.'**
  String get bleWrongLocker;

  /// No description provided for @bleNoKey.
  ///
  /// In vi, this message translates to:
  /// **'Tủ chưa tải được khoá kiểm mã từ máy chủ (cần có mạng một lần).'**
  String get bleNoKey;

  /// No description provided for @bleNotConfigured.
  ///
  /// In vi, this message translates to:
  /// **'Tủ chưa được gán trên hệ thống.'**
  String get bleNotConfigured;

  /// No description provided for @bleInvalidSlot.
  ///
  /// In vi, this message translates to:
  /// **'Ô này không có khoá điện nối vào bộ điều khiển.'**
  String get bleInvalidSlot;

  /// No description provided for @bleOpenFailed.
  ///
  /// In vi, this message translates to:
  /// **'Mở ô không thành công{suffix}.'**
  String bleOpenFailed(Object suffix);

  /// No description provided for @bleVeryClose.
  ///
  /// In vi, this message translates to:
  /// **'Rất gần (~{distance}m)'**
  String bleVeryClose(Object distance);

  /// No description provided for @bleNear.
  ///
  /// In vi, this message translates to:
  /// **'Gần tủ (~{distance}m)'**
  String bleNear(Object distance);

  /// No description provided for @bleAway.
  ///
  /// In vi, this message translates to:
  /// **'Cách tủ ~{distance}m'**
  String bleAway(Object distance);

  /// No description provided for @notifEnableTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bật thông báo'**
  String get notifEnableTitle;

  /// No description provided for @notifEnableBody.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã tắt quyền thông báo nên sẽ không nhận được cập nhật trạng thái giao hàng. Hãy vào Cài đặt để bật lại thông báo cho ứng dụng.'**
  String get notifEnableBody;

  /// No description provided for @notifNew.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo mới'**
  String get notifNew;

  /// No description provided for @biometricOpenApp.
  ///
  /// In vi, this message translates to:
  /// **'Xác thực để mở ứng dụng'**
  String get biometricOpenApp;

  /// No description provided for @enumLockerToLocker.
  ///
  /// In vi, this message translates to:
  /// **'Giao từ tủ qua tủ'**
  String get enumLockerToLocker;

  /// No description provided for @enumHomeToLocker.
  ///
  /// In vi, this message translates to:
  /// **'Giao từ nhà tới tủ'**
  String get enumHomeToLocker;

  /// No description provided for @enumPendingProcessing.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ xử lý'**
  String get enumPendingProcessing;

  /// No description provided for @enumAwaitingCourier.
  ///
  /// In vi, this message translates to:
  /// **'Chờ người giao hàng'**
  String get enumAwaitingCourier;

  /// No description provided for @enumAwaitingPickup.
  ///
  /// In vi, this message translates to:
  /// **'Chờ lấy hàng'**
  String get enumAwaitingPickup;

  /// No description provided for @enumActive.
  ///
  /// In vi, this message translates to:
  /// **'Đang hoạt động'**
  String get enumActive;

  /// No description provided for @enumCompleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã hoàn tất'**
  String get enumCompleted;

  /// No description provided for @enumLockedByBalance.
  ///
  /// In vi, this message translates to:
  /// **'Bị khóa do số dư'**
  String get enumLockedByBalance;

  /// No description provided for @enumCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Đã hủy'**
  String get enumCancelled;

  /// No description provided for @enumPending.
  ///
  /// In vi, this message translates to:
  /// **'Chờ xử lý'**
  String get enumPending;

  /// No description provided for @enumAwaitingDropoffConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Chờ xác nhận gửi hàng'**
  String get enumAwaitingDropoffConfirm;

  /// No description provided for @enumInTransit.
  ///
  /// In vi, this message translates to:
  /// **'Đang vận chuyển'**
  String get enumInTransit;

  /// No description provided for @enumInUse.
  ///
  /// In vi, this message translates to:
  /// **'Đang sử dụng'**
  String get enumInUse;

  /// No description provided for @enumOverdue.
  ///
  /// In vi, this message translates to:
  /// **'Quá hạn'**
  String get enumOverdue;

  /// No description provided for @enumConsolidating.
  ///
  /// In vi, this message translates to:
  /// **'Đang gom hàng'**
  String get enumConsolidating;

  /// No description provided for @enumPickedUp.
  ///
  /// In vi, this message translates to:
  /// **'Đã lấy hàng'**
  String get enumPickedUp;

  /// No description provided for @enumAwaitingDropoff.
  ///
  /// In vi, this message translates to:
  /// **'Chờ gửi hàng'**
  String get enumAwaitingDropoff;

  /// No description provided for @enumAwaitingPayment.
  ///
  /// In vi, this message translates to:
  /// **'Chờ thanh toán'**
  String get enumAwaitingPayment;

  /// No description provided for @enumUnpaid.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thanh toán'**
  String get enumUnpaid;

  /// No description provided for @enumPaid.
  ///
  /// In vi, this message translates to:
  /// **'Đã thanh toán'**
  String get enumPaid;

  /// No description provided for @enumPartiallyPaid.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán một phần'**
  String get enumPartiallyPaid;

  /// No description provided for @enumAwaitingRefund.
  ///
  /// In vi, this message translates to:
  /// **'Chờ hoàn tiền'**
  String get enumAwaitingRefund;

  /// No description provided for @enumRefunded.
  ///
  /// In vi, this message translates to:
  /// **'Đã hoàn tiền'**
  String get enumRefunded;

  /// No description provided for @enumTopUp.
  ///
  /// In vi, this message translates to:
  /// **'Nạp tiền'**
  String get enumTopUp;

  /// No description provided for @enumRentalFee.
  ///
  /// In vi, this message translates to:
  /// **'Phí thuê tủ'**
  String get enumRentalFee;

  /// No description provided for @enumShippingFee.
  ///
  /// In vi, this message translates to:
  /// **'Phí vận chuyển'**
  String get enumShippingFee;

  /// No description provided for @enumOverdueFee.
  ///
  /// In vi, this message translates to:
  /// **'Phí quá hạn'**
  String get enumOverdueFee;

  /// No description provided for @enumRefund.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tiền'**
  String get enumRefund;

  /// No description provided for @enumWalletTopUp.
  ///
  /// In vi, this message translates to:
  /// **'Nạp tiền vào ví'**
  String get enumWalletTopUp;

  /// No description provided for @enumWithdraw.
  ///
  /// In vi, this message translates to:
  /// **'Rút tiền'**
  String get enumWithdraw;

  /// No description provided for @enumShippingService.
  ///
  /// In vi, this message translates to:
  /// **'Dịch vụ vận chuyển'**
  String get enumShippingService;

  /// No description provided for @enumPersonalRental.
  ///
  /// In vi, this message translates to:
  /// **'Thuê tủ cá nhân'**
  String get enumPersonalRental;

  /// No description provided for @enumReady.
  ///
  /// In vi, this message translates to:
  /// **'Sẵn sàng'**
  String get enumReady;

  /// No description provided for @enumReserved.
  ///
  /// In vi, this message translates to:
  /// **'Đã đặt trước'**
  String get enumReserved;

  /// No description provided for @enumLockedBalanceShort.
  ///
  /// In vi, this message translates to:
  /// **'Khóa do số dư'**
  String get enumLockedBalanceShort;

  /// No description provided for @enumFaulty.
  ///
  /// In vi, this message translates to:
  /// **'Bị lỗi'**
  String get enumFaulty;

  /// No description provided for @enumPendingCheck.
  ///
  /// In vi, this message translates to:
  /// **'Chờ kiểm tra'**
  String get enumPendingCheck;

  /// No description provided for @enumMaintenance.
  ///
  /// In vi, this message translates to:
  /// **'Bảo trì'**
  String get enumMaintenance;

  /// No description provided for @enumInitializing.
  ///
  /// In vi, this message translates to:
  /// **'Đang khởi tạo'**
  String get enumInitializing;

  /// No description provided for @enumLocked.
  ///
  /// In vi, this message translates to:
  /// **'Đã khóa'**
  String get enumLocked;

  /// No description provided for @enumUnlocked.
  ///
  /// In vi, this message translates to:
  /// **'Đã mở khóa'**
  String get enumUnlocked;

  /// No description provided for @enumOpen.
  ///
  /// In vi, this message translates to:
  /// **'Đang mở'**
  String get enumOpen;

  /// No description provided for @enumClosed.
  ///
  /// In vi, this message translates to:
  /// **'Đã đóng'**
  String get enumClosed;

  /// No description provided for @enumOpening.
  ///
  /// In vi, this message translates to:
  /// **'Đang mở...'**
  String get enumOpening;

  /// No description provided for @enumClosing.
  ///
  /// In vi, this message translates to:
  /// **'Đang đóng...'**
  String get enumClosing;

  /// No description provided for @enumOffline.
  ///
  /// In vi, this message translates to:
  /// **'Ngoại tuyến'**
  String get enumOffline;

  /// No description provided for @enumFood.
  ///
  /// In vi, this message translates to:
  /// **'Thực phẩm'**
  String get enumFood;

  /// No description provided for @enumOther.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get enumOther;

  /// No description provided for @unitMinute.
  ///
  /// In vi, this message translates to:
  /// **'phút'**
  String get unitMinute;

  /// No description provided for @unitHour.
  ///
  /// In vi, this message translates to:
  /// **'giờ'**
  String get unitHour;

  /// No description provided for @unitDay.
  ///
  /// In vi, this message translates to:
  /// **'ngày'**
  String get unitDay;

  /// No description provided for @unitWeek.
  ///
  /// In vi, this message translates to:
  /// **'tuần'**
  String get unitWeek;

  /// No description provided for @unitMonth.
  ///
  /// In vi, this message translates to:
  /// **'tháng'**
  String get unitMonth;

  /// No description provided for @minutesShort.
  ///
  /// In vi, this message translates to:
  /// **'{minutes} phút'**
  String minutesShort(Object minutes);

  /// No description provided for @qrSendingOpen.
  ///
  /// In vi, this message translates to:
  /// **'Đang gửi lệnh mở ô...'**
  String get qrSendingOpen;

  /// No description provided for @qrOpenedTest.
  ///
  /// In vi, this message translates to:
  /// **'Đã mở ô (thử tủ)'**
  String get qrOpenedTest;

  /// No description provided for @qrNotOpened.
  ///
  /// In vi, this message translates to:
  /// **'Chưa mở được ô'**
  String get qrNotOpened;

  /// No description provided for @qrLockerBox.
  ///
  /// In vi, this message translates to:
  /// **'Tủ #{locker} · ô #{box}'**
  String qrLockerBox(Object locker, Object box);

  /// No description provided for @qrNotLockrCode.
  ///
  /// In vi, this message translates to:
  /// **'Đây không phải mã đăng nhập kiosk hay mã mở ô Lock.R. Hãy quét mã QR đang hiện trên màn hình tủ.'**
  String get qrNotLockrCode;

  /// No description provided for @qrConfirmingKiosk.
  ///
  /// In vi, this message translates to:
  /// **'Đang xác nhận đăng nhập kiosk...'**
  String get qrConfirmingKiosk;

  /// No description provided for @qrAtLocker.
  ///
  /// In vi, this message translates to:
  /// **' tại {name}'**
  String qrAtLocker(Object name);

  /// No description provided for @qrKioskLoggedIn.
  ///
  /// In vi, this message translates to:
  /// **'Đã đăng nhập trên kiosk{where}'**
  String qrKioskLoggedIn(Object where);

  /// No description provided for @qrKioskLoginFailedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đăng nhập được kiosk'**
  String get qrKioskLoginFailedTitle;

  /// No description provided for @qrKioskLoginFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không xác nhận được đăng nhập kiosk. Vui lòng thử lại.'**
  String get qrKioskLoginFailed;

  /// No description provided for @qrScan.
  ///
  /// In vi, this message translates to:
  /// **'Quét mã QR'**
  String get qrScan;

  /// No description provided for @qrLoginToScan.
  ///
  /// In vi, this message translates to:
  /// **'Bạn cần đăng nhập để quét mã QR'**
  String get qrLoginToScan;

  /// No description provided for @qrKioskLoginByQr.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập kiosk bằng QR'**
  String get qrKioskLoginByQr;

  /// No description provided for @qrAimHint.
  ///
  /// In vi, this message translates to:
  /// **'Đưa khung vào mã QR trên màn hình kiosk. Bạn sẽ được hỏi lại trước khi đăng nhập.'**
  String get qrAimHint;

  /// No description provided for @qrEnterManually.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã thủ công'**
  String get qrEnterManually;

  /// No description provided for @qrCameraPermission.
  ///
  /// In vi, this message translates to:
  /// **'Ứng dụng chưa được cấp quyền camera. Hãy cấp quyền trong cài đặt máy hoặc nhập mã thủ công.'**
  String get qrCameraPermission;

  /// No description provided for @qrCameraUnsupported.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị không hỗ trợ quét mã bằng camera. Hãy nhập mã thủ công.'**
  String get qrCameraUnsupported;

  /// No description provided for @qrCameraFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được camera. Hãy thử lại hoặc nhập mã thủ công.'**
  String get qrCameraFailed;

  /// No description provided for @qrKioskLoginQuestion.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập kiosk?'**
  String get qrKioskLoginQuestion;

  /// No description provided for @qrKioskLoginBody.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản Lock.R của bạn sẽ được đăng nhập trên kiosk vừa hiện mã. Chỉ xác nhận khi bạn đang đứng trước kiosk đó.'**
  String get qrKioskLoginBody;

  /// No description provided for @qrKioskConfirmCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã xác nhận trên kiosk'**
  String get qrKioskConfirmCode;

  /// No description provided for @qrKioskLogin.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập kiosk'**
  String get qrKioskLogin;

  /// No description provided for @qrWrongCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã chưa đúng. Kiểm tra lại mã phiên và mã xác nhận đang hiện trên kiosk.'**
  String get qrWrongCode;

  /// No description provided for @qrEnterKioskCode.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã đăng nhập kiosk'**
  String get qrEnterKioskCode;

  /// No description provided for @qrEnterKioskCodeHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã phiên và mã xác nhận đang hiện dưới mã QR trên màn hình kiosk.'**
  String get qrEnterKioskCodeHint;

  /// No description provided for @qrSessionCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã phiên'**
  String get qrSessionCode;

  /// No description provided for @qrConfirmCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã xác nhận'**
  String get qrConfirmCode;

  /// No description provided for @mapNoLocation.
  ///
  /// In vi, this message translates to:
  /// **'Không lấy được vị trí của bạn — chỉ hiển thị tủ.'**
  String get mapNoLocation;

  /// No description provided for @mapCantOpenMaps.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được ứng dụng bản đồ.'**
  String get mapCantOpenMaps;

  /// No description provided for @mapFindingRoute.
  ///
  /// In vi, this message translates to:
  /// **'Đang tìm đường...'**
  String get mapFindingRoute;

  /// No description provided for @mapRemaining.
  ///
  /// In vi, this message translates to:
  /// **'{distance} còn lại'**
  String mapRemaining(Object distance);

  /// No description provided for @mapStopNavigation.
  ///
  /// In vi, this message translates to:
  /// **'Dừng dẫn đường'**
  String get mapStopNavigation;

  /// No description provided for @mapStartNavigation.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu dẫn đường'**
  String get mapStartNavigation;

  /// No description provided for @mapGetMyLocation.
  ///
  /// In vi, this message translates to:
  /// **'Lấy vị trí của bạn'**
  String get mapGetMyLocation;

  /// No description provided for @mapOpenGoogleMaps.
  ///
  /// In vi, this message translates to:
  /// **'Mở trên Google Maps'**
  String get mapOpenGoogleMaps;

  /// No description provided for @mediaBadResponse.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ ảnh trả về dữ liệu không hợp lệ, vui lòng thử lại'**
  String get mediaBadResponse;

  /// No description provided for @mediaUploadCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Đã huỷ tải ảnh'**
  String get mediaUploadCancelled;

  /// No description provided for @mediaCannotConnect.
  ///
  /// In vi, this message translates to:
  /// **'Không kết nối được máy chủ, kiểm tra mạng rồi thử lại'**
  String get mediaCannotConnect;

  /// No description provided for @mediaPurposeForbidden.
  ///
  /// In vi, this message translates to:
  /// **'Bạn không có quyền tải loại ảnh này'**
  String get mediaPurposeForbidden;

  /// No description provided for @mediaNoUploadPermission.
  ///
  /// In vi, this message translates to:
  /// **'Không lấy được quyền tải ảnh, vui lòng thử lại'**
  String get mediaNoUploadPermission;

  /// No description provided for @mediaUploadNetwork.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được ảnh lên, kiểm tra kết nối mạng rồi thử lại'**
  String get mediaUploadNetwork;

  /// No description provided for @mediaSessionExpired.
  ///
  /// In vi, this message translates to:
  /// **'Phiên tải ảnh đã hết hạn, vui lòng thử lại'**
  String get mediaSessionExpired;

  /// No description provided for @mediaTooLarge.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh quá lớn, vui lòng chọn ảnh khác'**
  String get mediaTooLarge;

  /// No description provided for @mediaFormatUnsupported.
  ///
  /// In vi, this message translates to:
  /// **'Định dạng ảnh không được hỗ trợ (dùng JPG, PNG, WEBP, HEIC)'**
  String get mediaFormatUnsupported;

  /// No description provided for @mediaServerOverloaded.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ ảnh đang quá tải, vui lòng thử lại sau ít phút'**
  String get mediaServerOverloaded;

  /// No description provided for @mediaUploadFailedRetry.
  ///
  /// In vi, this message translates to:
  /// **'Tải ảnh lên thất bại, vui lòng thử lại'**
  String get mediaUploadFailedRetry;

  /// No description provided for @mediaStorageDisabled.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống lưu ảnh đang tạm tắt. Vui lòng gửi không kèm ảnh hoặc thử lại sau.'**
  String get mediaStorageDisabled;

  /// No description provided for @mediaPurposeInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Loại ảnh tải lên không hợp lệ'**
  String get mediaPurposeInvalid;

  /// No description provided for @mediaSignatureInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh tải lên không hợp lệ, vui lòng chụp lại'**
  String get mediaSignatureInvalid;

  /// No description provided for @mediaOwnerMismatch.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh không thuộc tài khoản của bạn, vui lòng tải lại'**
  String get mediaOwnerMismatch;

  /// No description provided for @mediaAttachmentLimit.
  ///
  /// In vi, this message translates to:
  /// **'Phiếu đã đạt số ảnh tối đa cho phép'**
  String get mediaAttachmentLimit;

  /// No description provided for @mediaAttachmentStageInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Loại ảnh không hợp lệ cho phiếu này'**
  String get mediaAttachmentStageInvalid;

  /// No description provided for @mediaReportNotInProgress.
  ///
  /// In vi, this message translates to:
  /// **'Phiếu chưa ở trạng thái đang xử lý'**
  String get mediaReportNotInProgress;

  /// No description provided for @mediaReportResolved.
  ///
  /// In vi, this message translates to:
  /// **'Phiếu đã hoàn tất, không thể thêm ảnh'**
  String get mediaReportResolved;

  /// No description provided for @mediaReportNotAssigned.
  ///
  /// In vi, this message translates to:
  /// **'Bạn không phải kỹ thuật viên được giao phiếu này'**
  String get mediaReportNotAssigned;

  /// No description provided for @mediaReportNotOwned.
  ///
  /// In vi, this message translates to:
  /// **'Bạn không phải người gửi phiếu này'**
  String get mediaReportNotOwned;

  /// No description provided for @mediaDeleteForbidden.
  ///
  /// In vi, this message translates to:
  /// **'Bạn không có quyền xoá ảnh này'**
  String get mediaDeleteForbidden;

  /// No description provided for @mediaResolutionPhotoRequired.
  ///
  /// In vi, this message translates to:
  /// **'Cần ít nhất 1 ảnh nghiệm thu trước khi hoàn tất phiếu'**
  String get mediaResolutionPhotoRequired;

  /// No description provided for @mediaAlreadyAttached.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh này đã được gắn vào phiếu'**
  String get mediaAlreadyAttached;

  /// No description provided for @mediaTooLargeMax.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh quá lớn (tối đa {mb} MB), vui lòng chọn ảnh khác'**
  String mediaTooLargeMax(Object mb);

  /// No description provided for @photoAdd.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ảnh'**
  String get photoAdd;

  /// No description provided for @photoMax.
  ///
  /// In vi, this message translates to:
  /// **'Tối đa {count} ảnh'**
  String photoMax(Object count);

  /// No description provided for @photoTakeCamera.
  ///
  /// In vi, this message translates to:
  /// **'Chụp ảnh từ máy ảnh'**
  String get photoTakeCamera;

  /// No description provided for @photoPickGalleryMax.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh từ thư viện (tối đa {count})'**
  String photoPickGalleryMax(Object count);

  /// No description provided for @photoPickGallery.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh từ thư viện'**
  String get photoPickGallery;

  /// No description provided for @photoCameraDenied.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được máy ảnh. Hãy cấp quyền camera trong cài đặt.'**
  String get photoCameraDenied;

  /// No description provided for @photoGalleryDenied.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được thư viện ảnh. Hãy cấp quyền ảnh trong cài đặt.'**
  String get photoGalleryDenied;

  /// No description provided for @photoUploadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Tải ảnh thất bại'**
  String get photoUploadFailed;

  /// No description provided for @photoNumber.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh {number}'**
  String photoNumber(Object number);

  /// No description provided for @attachmentReport.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh hiện trường (người báo)'**
  String get attachmentReport;

  /// No description provided for @attachmentInspection.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh xác nhận của KTV'**
  String get attachmentInspection;

  /// No description provided for @attachmentProgress.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh trong quá trình sửa'**
  String get attachmentProgress;

  /// No description provided for @attachmentResolution.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh nghiệm thu'**
  String get attachmentResolution;

  /// No description provided for @attachmentPhoto.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh'**
  String get attachmentPhoto;

  /// No description provided for @attachmentCount.
  ///
  /// In vi, this message translates to:
  /// **'({count} ảnh):'**
  String attachmentCount(Object count);

  /// No description provided for @attachmentNone.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ảnh'**
  String get attachmentNone;

  /// No description provided for @attachmentLocation.
  ///
  /// In vi, this message translates to:
  /// **'Vị trí {lat}, {lng}'**
  String attachmentLocation(Object lat, Object lng);

  /// No description provided for @attachmentLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được ảnh'**
  String get attachmentLoadFailed;

  /// No description provided for @paymentSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán thành công'**
  String get paymentSuccess;

  /// No description provided for @paymentFailed.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán thất bại'**
  String get paymentFailed;

  /// No description provided for @paymentSuccessExclaim.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán thành công!'**
  String get paymentSuccessExclaim;

  /// No description provided for @paymentPreparingPin.
  ///
  /// In vi, this message translates to:
  /// **'Đang chuẩn bị mã PIN mở ô tủ...'**
  String get paymentPreparingPin;

  /// No description provided for @paymentTapToContinue.
  ///
  /// In vi, this message translates to:
  /// **'Chạm để tiếp tục'**
  String get paymentTapToContinue;

  /// No description provided for @locationPick.
  ///
  /// In vi, this message translates to:
  /// **'Chọn vị trí'**
  String get locationPick;

  /// No description provided for @locationSearchAddress.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm địa chỉ...'**
  String get locationSearchAddress;

  /// No description provided for @locationConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận vị trí'**
  String get locationConfirm;

  /// No description provided for @commonYou.
  ///
  /// In vi, this message translates to:
  /// **'Bạn'**
  String get commonYou;

  /// No description provided for @commonSeeAllLower.
  ///
  /// In vi, this message translates to:
  /// **'Xem tất cả'**
  String get commonSeeAllLower;

  /// No description provided for @commonDirections.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ đường'**
  String get commonDirections;

  /// No description provided for @commonAddress.
  ///
  /// In vi, this message translates to:
  /// **'Địa chỉ'**
  String get commonAddress;

  /// No description provided for @commonDistance.
  ///
  /// In vi, this message translates to:
  /// **'Khoảng cách'**
  String get commonDistance;

  /// No description provided for @commonStatus.
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái'**
  String get commonStatus;

  /// No description provided for @commonLocation.
  ///
  /// In vi, this message translates to:
  /// **'Vị trí'**
  String get commonLocation;

  /// No description provided for @commonSize.
  ///
  /// In vi, this message translates to:
  /// **'Kích cỡ'**
  String get commonSize;

  /// No description provided for @commonBack.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get commonBack;

  /// No description provided for @commonNoAddress.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có địa chỉ'**
  String get commonNoAddress;

  /// No description provided for @commonFavorites.
  ///
  /// In vi, this message translates to:
  /// **'Yêu thích'**
  String get commonFavorites;

  /// No description provided for @commonOffers.
  ///
  /// In vi, this message translates to:
  /// **'Ưu đãi'**
  String get commonOffers;

  /// No description provided for @commonReportIssue.
  ///
  /// In vi, this message translates to:
  /// **'Báo sự cố'**
  String get commonReportIssue;

  /// No description provided for @commonReports.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo'**
  String get commonReports;

  /// No description provided for @commonStatusActive.
  ///
  /// In vi, this message translates to:
  /// **'Hoạt động'**
  String get commonStatusActive;

  /// No description provided for @commonStatusSuspended.
  ///
  /// In vi, this message translates to:
  /// **'Tạm ngưng'**
  String get commonStatusSuspended;

  /// No description provided for @commonDisconnected.
  ///
  /// In vi, this message translates to:
  /// **'Mất kết nối'**
  String get commonDisconnected;

  /// No description provided for @commonOnline.
  ///
  /// In vi, this message translates to:
  /// **'Trực tuyến'**
  String get commonOnline;

  /// No description provided for @commonInUseShort.
  ///
  /// In vi, this message translates to:
  /// **'Đang dùng'**
  String get commonInUseShort;

  /// No description provided for @commonReservedShort.
  ///
  /// In vi, this message translates to:
  /// **'Đã đặt'**
  String get commonReservedShort;

  /// No description provided for @commonBroken.
  ///
  /// In vi, this message translates to:
  /// **'Hỏng'**
  String get commonBroken;

  /// No description provided for @commonEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Trống'**
  String get commonEmpty;

  /// No description provided for @commonExpired.
  ///
  /// In vi, this message translates to:
  /// **'Hết hạn'**
  String get commonExpired;

  /// No description provided for @commonHistory.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử'**
  String get commonHistory;

  /// No description provided for @commonAvailable.
  ///
  /// In vi, this message translates to:
  /// **'Khả dụng'**
  String get commonAvailable;

  /// No description provided for @commonCopiedValue.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép: {value}'**
  String commonCopiedValue(Object value);

  /// No description provided for @commonStartDate.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu'**
  String get commonStartDate;

  /// No description provided for @commonEndDate.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc'**
  String get commonEndDate;

  /// No description provided for @commonHowToUse.
  ///
  /// In vi, this message translates to:
  /// **'Cách sử dụng'**
  String get commonHowToUse;

  /// No description provided for @commonTapToCopy.
  ///
  /// In vi, this message translates to:
  /// **'Chạm để sao chép mã'**
  String get commonTapToCopy;

  /// No description provided for @commonUnlimitedTime.
  ///
  /// In vi, this message translates to:
  /// **'Không giới hạn thời gian'**
  String get commonUnlimitedTime;

  /// No description provided for @commonExchange.
  ///
  /// In vi, this message translates to:
  /// **'Đổi'**
  String get commonExchange;

  /// No description provided for @commonSaved.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu'**
  String get commonSaved;

  /// No description provided for @commonLoadFailedData.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được dữ liệu'**
  String get commonLoadFailedData;

  /// No description provided for @boxNumberLabel.
  ///
  /// In vi, this message translates to:
  /// **'Ô số {number}'**
  String boxNumberLabel(Object number);

  /// No description provided for @boxRowCol.
  ///
  /// In vi, this message translates to:
  /// **'Ô hàng {row}, cột {col}'**
  String boxRowCol(Object row, Object col);

  /// No description provided for @rowCol.
  ///
  /// In vi, this message translates to:
  /// **'Hàng {row}, cột {col}'**
  String rowCol(Object row, Object col);

  /// No description provided for @boxHash.
  ///
  /// In vi, this message translates to:
  /// **'Ô #{number}'**
  String boxHash(Object number);

  /// No description provided for @orderHash.
  ///
  /// In vi, this message translates to:
  /// **'Đơn #{id}'**
  String orderHash(Object id);

  /// No description provided for @homeSendByDrone.
  ///
  /// In vi, this message translates to:
  /// **'Gửi hàng bằng drone'**
  String get homeSendByDrone;

  /// No description provided for @homeDropPoints.
  ///
  /// In vi, this message translates to:
  /// **'Điểm gửi'**
  String get homeDropPoints;

  /// No description provided for @homeRentLocker.
  ///
  /// In vi, this message translates to:
  /// **'Thuê tủ'**
  String get homeRentLocker;

  /// No description provided for @homeLockerOrders.
  ///
  /// In vi, this message translates to:
  /// **'Đơn tủ'**
  String get homeLockerOrders;

  /// No description provided for @homeUtilities.
  ///
  /// In vi, this message translates to:
  /// **'Tiện ích'**
  String get homeUtilities;

  /// No description provided for @homeDroneDelivery.
  ///
  /// In vi, this message translates to:
  /// **'Giao bằng drone'**
  String get homeDroneDelivery;

  /// No description provided for @homeActiveOrders.
  ///
  /// In vi, this message translates to:
  /// **'Đơn đang xử lý'**
  String get homeActiveOrders;

  /// No description provided for @homePickupDeadline.
  ///
  /// In vi, this message translates to:
  /// **'Hạn lấy đồ'**
  String get homePickupDeadline;

  /// No description provided for @stepCreateOrder.
  ///
  /// In vi, this message translates to:
  /// **'Tạo đơn'**
  String get stepCreateOrder;

  /// No description provided for @stepFlightTeamAccepted.
  ///
  /// In vi, this message translates to:
  /// **'Đội bay nhận'**
  String get stepFlightTeamAccepted;

  /// No description provided for @stepFlying.
  ///
  /// In vi, this message translates to:
  /// **'Đang bay'**
  String get stepFlying;

  /// No description provided for @stepDropReported.
  ///
  /// In vi, this message translates to:
  /// **'Báo rơi kiện'**
  String get stepDropReported;

  /// No description provided for @stepIntoLocker.
  ///
  /// In vi, this message translates to:
  /// **'Vào tủ nhận'**
  String get stepIntoLocker;

  /// No description provided for @stepDropIntoLocker.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ vào tủ'**
  String get stepDropIntoLocker;

  /// No description provided for @stepStoring.
  ///
  /// In vi, this message translates to:
  /// **'Đang lưu tủ'**
  String get stepStoring;

  /// No description provided for @stepInLocker.
  ///
  /// In vi, this message translates to:
  /// **'Đã vào tủ'**
  String get stepInLocker;

  /// No description provided for @stepTransit.
  ///
  /// In vi, this message translates to:
  /// **'Vận chuyển'**
  String get stepTransit;

  /// No description provided for @stepAwaitingPickup.
  ///
  /// In vi, this message translates to:
  /// **'Chờ nhận'**
  String get stepAwaitingPickup;

  /// No description provided for @homeUtilitiesServices.
  ///
  /// In vi, this message translates to:
  /// **'Tiện ích & Dịch vụ'**
  String get homeUtilitiesServices;

  /// No description provided for @homeSendDrone.
  ///
  /// In vi, this message translates to:
  /// **'Gửi drone'**
  String get homeSendDrone;

  /// No description provided for @homeKioskLocations.
  ///
  /// In vi, this message translates to:
  /// **'Các nơi đặt kiosk'**
  String get homeKioskLocations;

  /// No description provided for @homeNoLockerLocations.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có nơi đặt locker nào'**
  String get homeNoLockerLocations;

  /// No description provided for @homeOngoingOffers.
  ///
  /// In vi, this message translates to:
  /// **'Ưu đãi đang diễn ra'**
  String get homeOngoingOffers;

  /// No description provided for @storeDefaultName.
  ///
  /// In vi, this message translates to:
  /// **'Cửa hàng'**
  String get storeDefaultName;

  /// No description provided for @storeFavoritesLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được danh sách yêu thích.'**
  String get storeFavoritesLoadFailed;

  /// No description provided for @storeFavoritesSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Điểm gửi bạn đã lưu'**
  String get storeFavoritesSubtitle;

  /// No description provided for @storeFavoritesLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải danh sách yêu thích...'**
  String get storeFavoritesLoading;

  /// No description provided for @storeNoFavorites.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có cửa hàng yêu thích'**
  String get storeNoFavorites;

  /// No description provided for @storeNoFavoritesHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhấn vào biểu tượng trái tim ở một cửa hàng để lưu lại đây.'**
  String get storeNoFavoritesHint;

  /// No description provided for @storeExplore.
  ///
  /// In vi, this message translates to:
  /// **'Khám phá cửa hàng'**
  String get storeExplore;

  /// No description provided for @storeAddedFavorite.
  ///
  /// In vi, this message translates to:
  /// **'Đã thêm vào yêu thích'**
  String get storeAddedFavorite;

  /// No description provided for @storeRemovedFavorite.
  ///
  /// In vi, this message translates to:
  /// **'Đã bỏ khỏi yêu thích'**
  String get storeRemovedFavorite;

  /// No description provided for @storeFavoriteSaveFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không lưu được danh sách yêu thích.'**
  String get storeFavoriteSaveFailed;

  /// No description provided for @storeEnableLocation.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng bật dịch vụ định vị.'**
  String get storeEnableLocation;

  /// No description provided for @storeNeedLocation.
  ///
  /// In vi, this message translates to:
  /// **'Cần quyền vị trí để tìm cửa hàng gần bạn.'**
  String get storeNeedLocation;

  /// No description provided for @storeNoCurrentLocation.
  ///
  /// In vi, this message translates to:
  /// **'Không lấy được vị trí hiện tại.'**
  String get storeNoCurrentLocation;

  /// No description provided for @storeListLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được danh sách cửa hàng.'**
  String get storeListLoadFailed;

  /// No description provided for @storeListSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Khám phá điểm tủ & đối tác liên kết'**
  String get storeListSubtitle;

  /// No description provided for @storeSearchHint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm theo tên hoặc địa chỉ'**
  String get storeSearchHint;

  /// No description provided for @storeListLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải danh sách điểm tủ...'**
  String get storeListLoading;

  /// No description provided for @storeNone.
  ///
  /// In vi, this message translates to:
  /// **'Không có cửa hàng nào'**
  String get storeNone;

  /// No description provided for @storeRatingsLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được đánh giá.'**
  String get storeRatingsLoadFailed;

  /// No description provided for @storeInfoLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được thông tin cửa hàng.'**
  String get storeInfoLoadFailed;

  /// No description provided for @storeNoLocation.
  ///
  /// In vi, this message translates to:
  /// **'Cửa hàng chưa có vị trí.'**
  String get storeNoLocation;

  /// No description provided for @storeCantOpenMap.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được bản đồ.'**
  String get storeCantOpenMap;

  /// No description provided for @storeDetailTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết điểm gửi'**
  String get storeDetailTitle;

  /// No description provided for @storeDetailSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Điểm tủ & đối tác liên kết'**
  String get storeDetailSubtitle;

  /// No description provided for @storeInfoLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải thông tin...'**
  String get storeInfoLoading;

  /// No description provided for @storeRatingCount.
  ///
  /// In vi, this message translates to:
  /// **'  ·  {count} đánh giá'**
  String storeRatingCount(Object count);

  /// No description provided for @storeViewLockers.
  ///
  /// In vi, this message translates to:
  /// **'Xem tủ'**
  String get storeViewLockers;

  /// No description provided for @storeCustomerReviews.
  ///
  /// In vi, this message translates to:
  /// **'Đánh giá từ khách hàng'**
  String get storeCustomerReviews;

  /// No description provided for @storeNoReviews.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có đánh giá nào'**
  String get storeNoReviews;

  /// No description provided for @storeTemporarilyClosed.
  ///
  /// In vi, this message translates to:
  /// **'Tạm đóng'**
  String get storeTemporarilyClosed;

  /// No description provided for @storeCustomer.
  ///
  /// In vi, this message translates to:
  /// **'Khách hàng'**
  String get storeCustomer;

  /// No description provided for @storeOpen.
  ///
  /// In vi, this message translates to:
  /// **'Mở cửa'**
  String get storeOpen;

  /// No description provided for @storeDistanceFromYou.
  ///
  /// In vi, this message translates to:
  /// **'Cách bạn {km} km'**
  String storeDistanceFromYou(Object km);

  /// No description provided for @lockerHash.
  ///
  /// In vi, this message translates to:
  /// **'Tủ #{id}'**
  String lockerHash(Object id);

  /// No description provided for @lockerLockerTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tủ locker'**
  String get lockerLockerTitle;

  /// No description provided for @lockerPhysicalLocation.
  ///
  /// In vi, this message translates to:
  /// **'Vị trí tủ vật lý'**
  String get lockerPhysicalLocation;

  /// No description provided for @lockerListLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải danh sách tủ...'**
  String get lockerListLoading;

  /// No description provided for @lockerDroneCellHint.
  ///
  /// In vi, this message translates to:
  /// **'Chạm vào ô drone còn trống (màu tím) để gửi hàng bằng drone tới tủ khác.'**
  String get lockerDroneCellHint;

  /// No description provided for @lockerViewOnMap.
  ///
  /// In vi, this message translates to:
  /// **'Xem vị trí trên bản đồ'**
  String get lockerViewOnMap;

  /// No description provided for @lockerKioskPoint.
  ///
  /// In vi, this message translates to:
  /// **'ĐIỂM ĐẶT KIOSK'**
  String get lockerKioskPoint;

  /// No description provided for @lockerCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} tủ locker'**
  String lockerCount(Object count);

  /// No description provided for @lockerTapToSeeFree.
  ///
  /// In vi, this message translates to:
  /// **'Chạm vào tủ để xem ô trống'**
  String get lockerTapToSeeFree;

  /// No description provided for @lockerDefaultName.
  ///
  /// In vi, this message translates to:
  /// **'Tủ'**
  String get lockerDefaultName;

  /// No description provided for @lockerOfflineCantBook.
  ///
  /// In vi, this message translates to:
  /// **'Tủ đang mất kết nối với máy chủ nên tạm thời chưa đặt được ô.'**
  String get lockerOfflineCantBook;

  /// No description provided for @lockerUnderMaintenance.
  ///
  /// In vi, this message translates to:
  /// **'Tủ đang bảo trì kỹ thuật, tạm ngưng nhận đơn.'**
  String get lockerUnderMaintenance;

  /// No description provided for @lockerSuspended.
  ///
  /// In vi, this message translates to:
  /// **'Tủ đang tạm ngưng hoạt động.'**
  String get lockerSuspended;

  /// No description provided for @lockerFreeOfTotal.
  ///
  /// In vi, this message translates to:
  /// **'{available}/{total} ô trống'**
  String lockerFreeOfTotal(Object available, Object total);

  /// No description provided for @lockerNoCellsConfigured.
  ///
  /// In vi, this message translates to:
  /// **'Tủ chưa có ô nào được cấu hình'**
  String get lockerNoCellsConfigured;

  /// No description provided for @lockerBoxPendingCheck.
  ///
  /// In vi, this message translates to:
  /// **'đang chờ kỹ thuật viên kiểm tra sự cố'**
  String get lockerBoxPendingCheck;

  /// No description provided for @lockerBoxBroken.
  ///
  /// In vi, this message translates to:
  /// **'đang hỏng'**
  String get lockerBoxBroken;

  /// No description provided for @lockerBoxUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'{box} {state}. Hãy chọn ô khác.'**
  String lockerBoxUnavailable(Object box, Object state);

  /// No description provided for @lockerBoxUnavailableReason.
  ///
  /// In vi, this message translates to:
  /// **'{box} {state}: {reason}. Hãy chọn ô khác.'**
  String lockerBoxUnavailableReason(Object box, Object state, Object reason);

  /// No description provided for @lockerScreen7.
  ///
  /// In vi, this message translates to:
  /// **'Màn hình 7\"'**
  String get lockerScreen7;

  /// No description provided for @lockerFaultBroken.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi / Hỏng'**
  String get lockerFaultBroken;

  /// No description provided for @lockerDoorOpen.
  ///
  /// In vi, this message translates to:
  /// **'Cửa mở'**
  String get lockerDoorOpen;

  /// No description provided for @lockerDoorClosed.
  ///
  /// In vi, this message translates to:
  /// **'Cửa đóng'**
  String get lockerDoorClosed;

  /// No description provided for @lockerScreen.
  ///
  /// In vi, this message translates to:
  /// **'Màn hình'**
  String get lockerScreen;

  /// No description provided for @lockerKioskScreen.
  ///
  /// In vi, this message translates to:
  /// **'Màn hình kiosk'**
  String get lockerKioskScreen;

  /// No description provided for @lockerKioskHelp.
  ///
  /// In vi, this message translates to:
  /// **'Tại màn hình kiosk, bạn có thể nhập mã PIN của đơn để mở ô, hoặc đăng nhập bằng cách quét mã QR trên kiosk với nút quét ở trang chủ ứng dụng.'**
  String get lockerKioskHelp;

  /// No description provided for @lockerKioskOffline.
  ///
  /// In vi, this message translates to:
  /// **'Tủ đang mất kết nối với máy chủ: màn hình có thể không phản hồi và chưa đặt được ô mới.'**
  String get lockerKioskOffline;

  /// No description provided for @lockerReportKioskIssue.
  ///
  /// In vi, this message translates to:
  /// **'Báo sự cố màn hình kiosk'**
  String get lockerReportKioskIssue;

  /// No description provided for @lockerBrokenUpper.
  ///
  /// In vi, this message translates to:
  /// **'HỎNG'**
  String get lockerBrokenUpper;

  /// No description provided for @lockerPendingCheckUpper.
  ///
  /// In vi, this message translates to:
  /// **'CHỜ KIỂM TRA'**
  String get lockerPendingCheckUpper;

  /// No description provided for @lockerPendingCheck.
  ///
  /// In vi, this message translates to:
  /// **'Chờ kiểm tra'**
  String get lockerPendingCheck;

  /// No description provided for @lockerCleaning.
  ///
  /// In vi, this message translates to:
  /// **'Vệ sinh'**
  String get lockerCleaning;

  /// No description provided for @lockerDroneReceive.
  ///
  /// In vi, this message translates to:
  /// **'Nhận Drone'**
  String get lockerDroneReceive;

  /// No description provided for @lockerReady.
  ///
  /// In vi, this message translates to:
  /// **'Sẵn sàng'**
  String get lockerReady;

  /// No description provided for @sizeSmall.
  ///
  /// In vi, this message translates to:
  /// **'Nhỏ (S)'**
  String get sizeSmall;

  /// No description provided for @sizeMedium.
  ///
  /// In vi, this message translates to:
  /// **'Vừa (M)'**
  String get sizeMedium;

  /// No description provided for @sizeLarge.
  ///
  /// In vi, this message translates to:
  /// **'Lớn (L)'**
  String get sizeLarge;

  /// No description provided for @sizeXlSuitcase.
  ///
  /// In vi, this message translates to:
  /// **'Vali cỡ lớn (XL)'**
  String get sizeXlSuitcase;

  /// No description provided for @lockerEmptySuitcaseBox.
  ///
  /// In vi, this message translates to:
  /// **'Ô tủ vali trống'**
  String get lockerEmptySuitcaseBox;

  /// No description provided for @lockerEmptyBox.
  ///
  /// In vi, this message translates to:
  /// **'Ô tủ trống'**
  String get lockerEmptyBox;

  /// No description provided for @lockerWhatToDo.
  ///
  /// In vi, this message translates to:
  /// **'Bạn muốn làm gì với ô tủ này?'**
  String get lockerWhatToDo;

  /// No description provided for @lockerRentSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Theo giờ hoặc ngày'**
  String get lockerRentSubtitle;

  /// No description provided for @lockerSendParcel.
  ///
  /// In vi, this message translates to:
  /// **'Gửi hàng'**
  String get lockerSendParcel;

  /// No description provided for @lockerSendSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển C2C'**
  String get lockerSendSubtitle;

  /// No description provided for @lockerSuitcaseRentOnly.
  ///
  /// In vi, this message translates to:
  /// **'Ô vali chỉ dùng để thuê giữ đồ, không nhận gửi hàng.'**
  String get lockerSuitcaseRentOnly;

  /// No description provided for @lockerReportBoxIssue.
  ///
  /// In vi, this message translates to:
  /// **'Gặp sự cố với ô này? Báo cáo ngay'**
  String get lockerReportBoxIssue;

  /// No description provided for @lockerNoLockers.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có tủ locker'**
  String get lockerNoLockers;

  /// No description provided for @lockerStoreNoActiveLockers.
  ///
  /// In vi, this message translates to:
  /// **'Cửa hàng này chưa có tủ locker đang hoạt động.'**
  String get lockerStoreNoActiveLockers;

  /// No description provided for @lockerCabinetIdRequired.
  ///
  /// In vi, this message translates to:
  /// **'Cabinet ID không được để trống'**
  String get lockerCabinetIdRequired;

  /// No description provided for @lockerLocationIdRequired.
  ///
  /// In vi, this message translates to:
  /// **'Location ID không được để trống'**
  String get lockerLocationIdRequired;

  /// No description provided for @lockerOfflinePickOther.
  ///
  /// In vi, this message translates to:
  /// **'Tủ đang mất kết nối nên chưa đặt được ô. Vui lòng chọn tủ khác hoặc thử lại sau.'**
  String get lockerOfflinePickOther;

  /// No description provided for @lockerMaintenancePickOther.
  ///
  /// In vi, this message translates to:
  /// **'Tủ đang bảo trì nên tạm ngưng nhận đơn. Vui lòng chọn tủ khác.'**
  String get lockerMaintenancePickOther;

  /// No description provided for @lockerSuspendedCantBook.
  ///
  /// In vi, this message translates to:
  /// **'Tủ đang tạm ngưng hoạt động nên chưa đặt được ô.'**
  String get lockerSuspendedCantBook;

  /// No description provided for @groupSmall.
  ///
  /// In vi, this message translates to:
  /// **'Ô nhỏ (S)'**
  String get groupSmall;

  /// No description provided for @groupMedium.
  ///
  /// In vi, this message translates to:
  /// **'Ô vừa (M)'**
  String get groupMedium;

  /// No description provided for @groupLarge.
  ///
  /// In vi, this message translates to:
  /// **'Ô lớn (L)'**
  String get groupLarge;

  /// No description provided for @groupStandard.
  ///
  /// In vi, this message translates to:
  /// **'Ô thường'**
  String get groupStandard;

  /// No description provided for @groupXl.
  ///
  /// In vi, this message translates to:
  /// **'Ô vali (XL)'**
  String get groupXl;

  /// No description provided for @groupDrone.
  ///
  /// In vi, this message translates to:
  /// **'Ô drone'**
  String get groupDrone;

  /// No description provided for @cellTypeDroneRoof.
  ///
  /// In vi, this message translates to:
  /// **'Drone (Nóc tủ)'**
  String get cellTypeDroneRoof;

  /// No description provided for @cellTypeSuitcase.
  ///
  /// In vi, this message translates to:
  /// **'Vali (XL)'**
  String get cellTypeSuitcase;

  /// No description provided for @cellTypeStandard.
  ///
  /// In vi, this message translates to:
  /// **'Tiêu chuẩn'**
  String get cellTypeStandard;

  /// No description provided for @cellOutOfService.
  ///
  /// In vi, this message translates to:
  /// **'Ngưng dùng'**
  String get cellOutOfService;

  /// No description provided for @lockerSizeSmallDesc.
  ///
  /// In vi, this message translates to:
  /// **'Kích thước nhỏ, phù hợp cho túi xách, ví'**
  String get lockerSizeSmallDesc;

  /// No description provided for @lockerSizeMediumDesc.
  ///
  /// In vi, this message translates to:
  /// **'Kích thước trung bình, phù hợp cho ba lô'**
  String get lockerSizeMediumDesc;

  /// No description provided for @lockerSizeLargeDesc.
  ///
  /// In vi, this message translates to:
  /// **'Kích thước lớn, phù hợp cho vali'**
  String get lockerSizeLargeDesc;

  /// No description provided for @lockerStatusAvailable.
  ///
  /// In vi, this message translates to:
  /// **'Có sẵn'**
  String get lockerStatusAvailable;

  /// No description provided for @lockerStatusInUse.
  ///
  /// In vi, this message translates to:
  /// **'Đang sử dụng'**
  String get lockerStatusInUse;

  /// No description provided for @lockerStatusReserved.
  ///
  /// In vi, this message translates to:
  /// **'Đã đặt trước'**
  String get lockerStatusReserved;

  /// No description provided for @lockerStatusMaintenance.
  ///
  /// In vi, this message translates to:
  /// **'Đang bảo trì'**
  String get lockerStatusMaintenance;

  /// No description provided for @lockerStatusOutOfService.
  ///
  /// In vi, this message translates to:
  /// **'Ngừng hoạt động'**
  String get lockerStatusOutOfService;

  /// No description provided for @lockerAlreadyRented.
  ///
  /// In vi, this message translates to:
  /// **'Tủ này đang được thuê.'**
  String get lockerAlreadyRented;

  /// No description provided for @lockerInsufficientBalance.
  ///
  /// In vi, this message translates to:
  /// **'Số dư không đủ.'**
  String get lockerInsufficientBalance;

  /// No description provided for @lockerFixedRentFailed.
  ///
  /// In vi, this message translates to:
  /// **'Thuê tủ cố định thất bại.'**
  String get lockerFixedRentFailed;

  /// No description provided for @lockerOpenCommandSent.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi lệnh mở tủ.'**
  String get lockerOpenCommandSent;

  /// No description provided for @lockerCloseCommandSent.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi lệnh đóng tủ.'**
  String get lockerCloseCommandSent;

  /// No description provided for @lockerDetailSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết vị trí tủ Lock.R'**
  String get lockerDetailSubtitle;

  /// No description provided for @lockerNoCoordinates.
  ///
  /// In vi, this message translates to:
  /// **'Tủ chưa có toạ độ nên chưa hiển thị được bản đồ và chỉ đường.'**
  String get lockerNoCoordinates;

  /// No description provided for @lockerBookService.
  ///
  /// In vi, this message translates to:
  /// **'Đặt dịch vụ'**
  String get lockerBookService;

  /// No description provided for @lockerViewLayout.
  ///
  /// In vi, this message translates to:
  /// **'Xem sơ đồ ô tủ'**
  String get lockerViewLayout;

  /// No description provided for @lockerMapTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bản đồ tủ khóa'**
  String get lockerMapTitle;

  /// No description provided for @lockerMapSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tìm điểm tủ Lock.R gần bạn nhất'**
  String get lockerMapSubtitle;

  /// No description provided for @lockerMapLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải bản đồ...'**
  String get lockerMapLoading;

  /// No description provided for @lockerNoneYet.
  ///
  /// In vi, this message translates to:
  /// **'Hiện tại chưa có tủ nào!'**
  String get lockerNoneYet;

  /// No description provided for @lockerGettingLocation.
  ///
  /// In vi, this message translates to:
  /// **'Đang lấy vị trí...'**
  String get lockerGettingLocation;

  /// No description provided for @lockerUseMyLocation.
  ///
  /// In vi, this message translates to:
  /// **'Sử dụng vị trí của bạn'**
  String get lockerUseMyLocation;

  /// No description provided for @lockerMapLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải bản đồ. Toạ độ có thể không hợp lệ.'**
  String get lockerMapLoadFailed;

  /// No description provided for @lockerInvalidCoordsHidden.
  ///
  /// In vi, this message translates to:
  /// **'{count} địa điểm có toạ độ không hợp lệ đã được ẩn.'**
  String lockerInvalidCoordsHidden(Object count);

  /// No description provided for @lockerLocating.
  ///
  /// In vi, this message translates to:
  /// **'Đang xác định vị trí...'**
  String get lockerLocating;

  /// No description provided for @lockerAddressFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể xác định địa chỉ, vui lòng thử lại'**
  String get lockerAddressFailed;

  /// No description provided for @lockerAddressFailedError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể xác định địa chỉ, vui lòng thử lại: {error}'**
  String lockerAddressFailedError(Object error);

  /// No description provided for @lockerLocationServiceOff.
  ///
  /// In vi, this message translates to:
  /// **'Dịch vụ vị trí đang tắt. Vui lòng bật GPS.'**
  String get lockerLocationServiceOff;

  /// No description provided for @lockerLocationDenied.
  ///
  /// In vi, this message translates to:
  /// **'Quyền truy cập vị trí bị từ chối.'**
  String get lockerLocationDenied;

  /// No description provided for @lockerLocationDeniedForever.
  ///
  /// In vi, this message translates to:
  /// **'Quyền vị trí bị từ chối vĩnh viễn. Hãy bật lại trong cài đặt.'**
  String get lockerLocationDeniedForever;

  /// No description provided for @lockerOtherKiosk.
  ///
  /// In vi, this message translates to:
  /// **'Kiosk khác'**
  String get lockerOtherKiosk;

  /// No description provided for @lockerCountShort.
  ///
  /// In vi, this message translates to:
  /// **'{count} tủ'**
  String lockerCountShort(Object count);

  /// No description provided for @commonAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get commonAll;

  /// No description provided for @lockerLocationList.
  ///
  /// In vi, this message translates to:
  /// **'Danh sách địa điểm'**
  String get lockerLocationList;

  /// No description provided for @lockerLoginToSeeLocations.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập để xem các địa điểm khả dụng'**
  String get lockerLoginToSeeLocations;

  /// No description provided for @lockerLoginRequiredLocations.
  ///
  /// In vi, this message translates to:
  /// **'Bạn cần đăng nhập để xem danh sách địa điểm'**
  String get lockerLoginRequiredLocations;

  /// No description provided for @lockerPickLocation.
  ///
  /// In vi, this message translates to:
  /// **'Chọn địa điểm để xem chi tiết'**
  String get lockerPickLocation;

  /// No description provided for @lockerSearchLocation.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm địa điểm...'**
  String get lockerSearchLocation;

  /// No description provided for @lockerNoLocations.
  ///
  /// In vi, this message translates to:
  /// **'Hiện tại chưa có địa điểm nào!'**
  String get lockerNoLocations;

  /// No description provided for @lockerNotFoundHere.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy tủ tại địa điểm này'**
  String get lockerNotFoundHere;

  /// No description provided for @lockerTryOtherLocation.
  ///
  /// In vi, this message translates to:
  /// **'Thử chọn địa điểm khác hoặc xem tất cả địa điểm khả dụng.'**
  String get lockerTryOtherLocation;

  /// No description provided for @lockerViewAllLocations.
  ///
  /// In vi, this message translates to:
  /// **'Xem tất cả địa điểm'**
  String get lockerViewAllLocations;

  /// No description provided for @lockerLoadingFreeCells.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải số ô trống...'**
  String get lockerLoadingFreeCells;

  /// No description provided for @lockerCellsLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tải được số ô: {error}'**
  String lockerCellsLoadFailed(Object error);

  /// No description provided for @lockerFreeCells.
  ///
  /// In vi, this message translates to:
  /// **'Ô trống'**
  String get lockerFreeCells;

  /// No description provided for @lockerConnectionUnknown.
  ///
  /// In vi, this message translates to:
  /// **'Chưa rõ kết nối'**
  String get lockerConnectionUnknown;

  /// No description provided for @lockerMostUsed.
  ///
  /// In vi, this message translates to:
  /// **'Hay dùng nhất'**
  String get lockerMostUsed;

  /// No description provided for @promoUnlimited.
  ///
  /// In vi, this message translates to:
  /// **'Không giới hạn'**
  String get promoUnlimited;

  /// No description provided for @promoExpired.
  ///
  /// In vi, this message translates to:
  /// **'Đã hết hạn'**
  String get promoExpired;

  /// No description provided for @promoDaysLeft.
  ///
  /// In vi, this message translates to:
  /// **'Còn {days} ngày'**
  String promoDaysLeft(Object days);

  /// No description provided for @promoHoursLeft.
  ///
  /// In vi, this message translates to:
  /// **'Còn {hours} giờ'**
  String promoHoursLeft(Object hours);

  /// No description provided for @promoMinutesLeft.
  ///
  /// In vi, this message translates to:
  /// **'Còn {minutes} phút'**
  String promoMinutesLeft(Object minutes);

  /// No description provided for @promoMinOrder.
  ///
  /// In vi, this message translates to:
  /// **'Đơn tối thiểu {amount}'**
  String promoMinOrder(Object amount);

  /// No description provided for @promoSystemWide.
  ///
  /// In vi, this message translates to:
  /// **'Toàn hệ thống'**
  String get promoSystemWide;

  /// No description provided for @promoAppliesAt.
  ///
  /// In vi, this message translates to:
  /// **'Áp dụng tại: {name}'**
  String promoAppliesAt(Object name);

  /// No description provided for @promoSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Khám phá ưu đãi đang hiệu lực hôm nay'**
  String get promoSubtitle;

  /// No description provided for @promoLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải khuyến mãi...'**
  String get promoLoading;

  /// No description provided for @promoNoneActive.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ưu đãi nào đang hiệu lực'**
  String get promoNoneActive;

  /// No description provided for @promoExpiringSoon.
  ///
  /// In vi, this message translates to:
  /// **'Sắp hết hạn'**
  String get promoExpiringSoon;

  /// No description provided for @promoSavedToMine.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu mã {code} vào \"Ưu đãi của tôi\"'**
  String promoSavedToMine(Object code);

  /// No description provided for @promoSaveNotSupported.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ chưa hỗ trợ lưu mã. Vui lòng thử lại sau.'**
  String get promoSaveNotSupported;

  /// No description provided for @promoSaveFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không lưu được mã — kiểm tra đăng nhập và thử lại'**
  String get promoSaveFailed;

  /// No description provided for @promoCopiedCode.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép mã: {code}'**
  String promoCopiedCode(Object code);

  /// No description provided for @promoDiscountPercent.
  ///
  /// In vi, this message translates to:
  /// **'Giảm {percent}%'**
  String promoDiscountPercent(Object percent);

  /// No description provided for @promoDiscountAmount.
  ///
  /// In vi, this message translates to:
  /// **'Giảm {amount}'**
  String promoDiscountAmount(Object amount);

  /// No description provided for @promoDetailTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết ưu đãi'**
  String get promoDetailTitle;

  /// No description provided for @promoOfferExpired.
  ///
  /// In vi, this message translates to:
  /// **'Ưu đãi đã hết hạn'**
  String get promoOfferExpired;

  /// No description provided for @promoCodeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mã khuyến mãi'**
  String get promoCodeLabel;

  /// No description provided for @promoDiscountLevel.
  ///
  /// In vi, this message translates to:
  /// **'Mức giảm'**
  String get promoDiscountLevel;

  /// No description provided for @promoScope.
  ///
  /// In vi, this message translates to:
  /// **'Phạm vi'**
  String get promoScope;

  /// No description provided for @promoMaxDiscount.
  ///
  /// In vi, this message translates to:
  /// **'Giảm tối đa'**
  String get promoMaxDiscount;

  /// No description provided for @promoMinOrderLabel.
  ///
  /// In vi, this message translates to:
  /// **'Đơn tối thiểu'**
  String get promoMinOrderLabel;

  /// No description provided for @promoActive.
  ///
  /// In vi, this message translates to:
  /// **'Đang hiệu lực'**
  String get promoActive;

  /// No description provided for @promoExpiredCantUse.
  ///
  /// In vi, this message translates to:
  /// **'Ưu đãi này đã hết hạn và không thể sử dụng.'**
  String get promoExpiredCantUse;

  /// No description provided for @promoStep1Any.
  ///
  /// In vi, this message translates to:
  /// **'Vào trang Thuê tủ, Gửi hàng hoặc Gửi drone và chọn tủ'**
  String get promoStep1Any;

  /// No description provided for @promoStep1At.
  ///
  /// In vi, this message translates to:
  /// **'Vào trang Thuê tủ, Gửi hàng hoặc Gửi drone tại {locker} (đơn drone: tủ drone cất cánh)'**
  String promoStep1At(Object locker);

  /// No description provided for @promoStep2.
  ///
  /// In vi, this message translates to:
  /// **'Ở mục \"Mã giảm giá\", chạm \"Chọn mã giảm giá\" rồi chọn mã này trong danh sách'**
  String get promoStep2;

  /// No description provided for @promoStep3.
  ///
  /// In vi, this message translates to:
  /// **'Mức giảm được trừ vào tổng tiền nếu đơn đủ điều kiện (đơn tối thiểu, tủ áp dụng)'**
  String get promoStep3;

  /// No description provided for @promoLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được ưu đãi'**
  String get promoLoadFailed;

  /// No description provided for @promoAtThisLocker.
  ///
  /// In vi, this message translates to:
  /// **'Ưu đãi tại tủ này'**
  String get promoAtThisLocker;

  /// No description provided for @voucherMine.
  ///
  /// In vi, this message translates to:
  /// **'Ưu đãi của tôi'**
  String get voucherMine;

  /// No description provided for @voucherMineSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Mã giảm giá & quà tặng của bạn'**
  String get voucherMineSubtitle;

  /// No description provided for @voucherExchangeTab.
  ///
  /// In vi, this message translates to:
  /// **'Đổi điểm'**
  String get voucherExchangeTab;

  /// No description provided for @voucherLoginToSee.
  ///
  /// In vi, this message translates to:
  /// **'Bạn cần đăng nhập để xem ưu đãi đã lưu'**
  String get voucherLoginToSee;

  /// No description provided for @voucherLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải ưu đãi...'**
  String get voucherLoading;

  /// No description provided for @voucherNone.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa có ưu đãi nào'**
  String get voucherNone;

  /// No description provided for @voucherExploreAndSave.
  ///
  /// In vi, this message translates to:
  /// **'Khám phá ưu đãi và lưu mã'**
  String get voucherExploreAndSave;

  /// No description provided for @voucherGift.
  ///
  /// In vi, this message translates to:
  /// **'Quà tặng'**
  String get voucherGift;

  /// No description provided for @voucherGiftUpper.
  ///
  /// In vi, this message translates to:
  /// **'QUÀ TẶNG'**
  String get voucherGiftUpper;

  /// No description provided for @voucherDiscountUpper.
  ///
  /// In vi, this message translates to:
  /// **'GIẢM GIÁ'**
  String get voucherDiscountUpper;

  /// No description provided for @voucherUsed.
  ///
  /// In vi, this message translates to:
  /// **'Đã dùng'**
  String get voucherUsed;

  /// No description provided for @voucherUsedLong.
  ///
  /// In vi, this message translates to:
  /// **'Đã sử dụng'**
  String get voucherUsedLong;

  /// No description provided for @voucherCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép mã voucher'**
  String get voucherCopied;

  /// No description provided for @voucherCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã voucher'**
  String get voucherCode;

  /// No description provided for @voucherOffer.
  ///
  /// In vi, this message translates to:
  /// **'Ưu đãi'**
  String get voucherOffer;

  /// No description provided for @voucherCampaign.
  ///
  /// In vi, this message translates to:
  /// **'Chiến dịch'**
  String get voucherCampaign;

  /// No description provided for @voucherValidUntil.
  ///
  /// In vi, this message translates to:
  /// **'Hạn sử dụng'**
  String get voucherValidUntil;

  /// No description provided for @voucherExpiredCantUse.
  ///
  /// In vi, this message translates to:
  /// **'Voucher này đã hết hạn và không thể sử dụng.'**
  String get voucherExpiredCantUse;

  /// No description provided for @voucherAlreadyUsed.
  ///
  /// In vi, this message translates to:
  /// **'Voucher này đã được sử dụng.'**
  String get voucherAlreadyUsed;

  /// No description provided for @voucherStepCopy.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép mã voucher ở trên'**
  String get voucherStepCopy;

  /// No description provided for @voucherStepBookAny.
  ///
  /// In vi, this message translates to:
  /// **'Vào trang đặt dịch vụ (Thuê tủ / Gửi hàng / Gửi drone)'**
  String get voucherStepBookAny;

  /// No description provided for @voucherStepBookAt.
  ///
  /// In vi, this message translates to:
  /// **'Đặt dịch vụ tại {locker} (đơn drone: tủ drone cất cánh)'**
  String voucherStepBookAt(Object locker);

  /// No description provided for @voucherStepEnter.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã vào ô \"Mã giảm giá\" và nhấn Áp dụng'**
  String get voucherStepEnter;

  /// No description provided for @voucherStepDeducted.
  ///
  /// In vi, this message translates to:
  /// **'Mức giảm sẽ được trừ vào tổng tiền thanh toán'**
  String get voucherStepDeducted;

  /// No description provided for @voucherExchangeNotSupported.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ chưa hỗ trợ đổi điểm. Vui lòng thử lại sau.'**
  String get voucherExchangeNotSupported;

  /// No description provided for @voucherExchangeLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được danh sách đổi điểm. Vui lòng thử lại.'**
  String get voucherExchangeLoadFailed;

  /// No description provided for @voucherExchangeFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đổi được voucher. Vui lòng thử lại.'**
  String get voucherExchangeFailed;

  /// No description provided for @voucherWalletNotSupported.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ chưa hỗ trợ kho ưu đãi. Vui lòng thử lại sau.'**
  String get voucherWalletNotSupported;

  /// No description provided for @voucherMineLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được ưu đãi của bạn. Vui lòng thử lại.'**
  String get voucherMineLoadFailed;

  /// No description provided for @pointsCount.
  ///
  /// In vi, this message translates to:
  /// **'{points} điểm'**
  String pointsCount(Object points);

  /// No description provided for @voucherMaxSuffix.
  ///
  /// In vi, this message translates to:
  /// **' (tối đa {amount})'**
  String voucherMaxSuffix(Object amount);

  /// No description provided for @voucherExchangeLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải voucher đổi điểm...'**
  String get voucherExchangeLoading;

  /// No description provided for @voucherExchangeNone.
  ///
  /// In vi, this message translates to:
  /// **'Hiện chưa có voucher nào để đổi điểm'**
  String get voucherExchangeNone;

  /// No description provided for @voucherExchangeQuestion.
  ///
  /// In vi, this message translates to:
  /// **'Đổi voucher?'**
  String get voucherExchangeQuestion;

  /// No description provided for @voucherExchangeConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Dùng {points} đổi voucher \"{reward}\". Voucher sẽ nằm trong mục Khả dụng, dùng bằng mã {code} khi đặt đơn.'**
  String voucherExchangeConfirm(Object points, Object reward, Object code);

  /// No description provided for @voucherExchanged.
  ///
  /// In vi, this message translates to:
  /// **'Đã đổi voucher {code} — xem ở mục Khả dụng'**
  String voucherExchanged(Object code);

  /// No description provided for @voucherYourPoints.
  ///
  /// In vi, this message translates to:
  /// **'Điểm của bạn'**
  String get voucherYourPoints;

  /// No description provided for @voucherPointRate.
  ///
  /// In vi, this message translates to:
  /// **'1 điểm = {amount} · đổi lấy voucher giảm giá cho đơn'**
  String voucherPointRate(Object amount);

  /// No description provided for @voucherOwned.
  ///
  /// In vi, this message translates to:
  /// **'Đã có'**
  String get voucherOwned;

  /// No description provided for @voucherMissingPoints.
  ///
  /// In vi, this message translates to:
  /// **'Thiếu {points}'**
  String voucherMissingPoints(Object points);

  /// No description provided for @voucherOrderFrom.
  ///
  /// In vi, this message translates to:
  /// **'Đơn từ {amount}'**
  String voucherOrderFrom(Object amount);
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
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
