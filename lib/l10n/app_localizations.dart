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

  /// No description provided for @commonDetails.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết'**
  String get commonDetails;

  /// No description provided for @commonNotYet.
  ///
  /// In vi, this message translates to:
  /// **'Chưa'**
  String get commonNotYet;

  /// No description provided for @commonNote.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú'**
  String get commonNote;

  /// No description provided for @commonReload.
  ///
  /// In vi, this message translates to:
  /// **'Tải lại'**
  String get commonReload;

  /// No description provided for @commonService.
  ///
  /// In vi, this message translates to:
  /// **'Dịch vụ'**
  String get commonService;

  /// No description provided for @commonDiscount.
  ///
  /// In vi, this message translates to:
  /// **'Giảm giá'**
  String get commonDiscount;

  /// No description provided for @commonVoucher.
  ///
  /// In vi, this message translates to:
  /// **'Voucher'**
  String get commonVoucher;

  /// No description provided for @commonAmount.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền'**
  String get commonAmount;

  /// No description provided for @commonLocker.
  ///
  /// In vi, this message translates to:
  /// **'Tủ'**
  String get commonLocker;

  /// No description provided for @commonBox.
  ///
  /// In vi, this message translates to:
  /// **'Ô'**
  String get commonBox;

  /// No description provided for @commonToday.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get commonToday;

  /// No description provided for @commonYesterday.
  ///
  /// In vi, this message translates to:
  /// **'Hôm qua'**
  String get commonYesterday;

  /// No description provided for @commonUnknownDate.
  ///
  /// In vi, this message translates to:
  /// **'Không rõ ngày'**
  String get commonUnknownDate;

  /// No description provided for @dateDayMonthYear.
  ///
  /// In vi, this message translates to:
  /// **'{day} tháng {month}, {year}'**
  String dateDayMonthYear(Object day, Object month, Object year);

  /// No description provided for @hoursValue.
  ///
  /// In vi, this message translates to:
  /// **'{hours} giờ'**
  String hoursValue(int hours);

  /// No description provided for @pricePerHour.
  ///
  /// In vi, this message translates to:
  /// **'{price}/giờ'**
  String pricePerHour(Object price);

  /// No description provided for @photosMore.
  ///
  /// In vi, this message translates to:
  /// **'+{count} ảnh'**
  String photosMore(Object count);

  /// No description provided for @boxThisLower.
  ///
  /// In vi, this message translates to:
  /// **'ô này'**
  String get boxThisLower;

  /// No description provided for @boxNumberLower.
  ///
  /// In vi, this message translates to:
  /// **'ô số {number}'**
  String boxNumberLower(Object number);

  /// No description provided for @boxThis.
  ///
  /// In vi, this message translates to:
  /// **'Ô này'**
  String get boxThis;

  /// No description provided for @ordIncomingNotSupported.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ chưa hỗ trợ mục Hàng chờ nhận. Vui lòng thử lại sau.'**
  String get ordIncomingNotSupported;

  /// No description provided for @ordNotFoundInList.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy đơn trong danh sách của bạn.'**
  String get ordNotFoundInList;

  /// No description provided for @ordEmptyRecent.
  ///
  /// In vi, this message translates to:
  /// **'Không có đơn hàng nào trong 7 ngày gần đây.'**
  String get ordEmptyRecent;

  /// No description provided for @ordEmptyActive.
  ///
  /// In vi, this message translates to:
  /// **'Hiện không có đơn hàng nào đang trong quá trình sử dụng.'**
  String get ordEmptyActive;

  /// No description provided for @ordEmptyCompleted.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có đơn hàng nào đã hoàn tất.'**
  String get ordEmptyCompleted;

  /// No description provided for @ordEmptyRental.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có đơn thuê tủ nào.'**
  String get ordEmptyRental;

  /// No description provided for @ordEmptySend.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có đơn gửi hàng nào.'**
  String get ordEmptySend;

  /// No description provided for @ordEmptyCanceled.
  ///
  /// In vi, this message translates to:
  /// **'Không có đơn nào đã hủy.'**
  String get ordEmptyCanceled;

  /// No description provided for @ordEmptyHint.
  ///
  /// In vi, this message translates to:
  /// **'Tạo đơn Gửi hàng hoặc Thuê tủ từ màn hình chính.'**
  String get ordEmptyHint;

  /// No description provided for @ordCancelQuestion.
  ///
  /// In vi, this message translates to:
  /// **'Huỷ đơn?'**
  String get ordCancelQuestion;

  /// No description provided for @ordCancelBody.
  ///
  /// In vi, this message translates to:
  /// **'Đơn {code} sẽ bị huỷ, mã mở ô hết hiệu lực và ô đang giữ được nhả.'**
  String ordCancelBody(Object code);

  /// No description provided for @ordCancelPaidNote.
  ///
  /// In vi, this message translates to:
  /// **' Tiền đã thanh toán không tự hoàn — sau khi huỷ, mở lại đơn và chọn \"Yêu cầu hoàn tiền\".'**
  String get ordCancelPaidNote;

  /// No description provided for @ordKeepOrder.
  ///
  /// In vi, this message translates to:
  /// **'Giữ đơn'**
  String get ordKeepOrder;

  /// No description provided for @ordCancelOrderAlt.
  ///
  /// In vi, this message translates to:
  /// **'Huỷ đơn'**
  String get ordCancelOrderAlt;

  /// No description provided for @ordExtendRental.
  ///
  /// In vi, this message translates to:
  /// **'Gia hạn thuê'**
  String get ordExtendRental;

  /// No description provided for @ordAddHours.
  ///
  /// In vi, this message translates to:
  /// **'Thêm {hours} giờ'**
  String ordAddHours(int hours);

  /// No description provided for @ordMaxHoursPerExtension.
  ///
  /// In vi, this message translates to:
  /// **'Tối đa {hours} giờ mỗi lần gia hạn'**
  String ordMaxHoursPerExtension(Object hours);

  /// No description provided for @ordExtend.
  ///
  /// In vi, this message translates to:
  /// **'Gia hạn'**
  String get ordExtend;

  /// No description provided for @ordExtended.
  ///
  /// In vi, this message translates to:
  /// **'Đã gia hạn {hours} giờ'**
  String ordExtended(int hours);

  /// No description provided for @ordReportFaultyBox.
  ///
  /// In vi, this message translates to:
  /// **'Báo ô lỗi'**
  String get ordReportFaultyBox;

  /// No description provided for @ordDescribeIssueHint.
  ///
  /// In vi, this message translates to:
  /// **'Mô tả sự cố (ô không mở, kẹt cửa...)'**
  String get ordDescribeIssueHint;

  /// No description provided for @ordOnsitePhotosOptional.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh hiện trường (không bắt buộc, tối đa {max})'**
  String ordOnsitePhotosOptional(Object max);

  /// No description provided for @ordPhotosHelp.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh giúp đội bảo trì xử lý nhanh hơn.'**
  String get ordPhotosHelp;

  /// No description provided for @ordDescribeOrAttach.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng mô tả sự cố hoặc đính kèm ảnh.'**
  String get ordDescribeOrAttach;

  /// No description provided for @ordUploadingPhotos.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải ảnh...'**
  String get ordUploadingPhotos;

  /// No description provided for @ordSendReport.
  ///
  /// In vi, this message translates to:
  /// **'Gửi báo lỗi'**
  String get ordSendReport;

  /// No description provided for @ordBoxFaultDefault.
  ///
  /// In vi, this message translates to:
  /// **'Ô tủ gặp sự cố (xem ảnh đính kèm)'**
  String get ordBoxFaultDefault;

  /// No description provided for @ordReportSentFor.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi báo lỗi cho {box} — đội bảo trì sẽ xử lý'**
  String ordReportSentFor(Object box);

  /// No description provided for @ordPickupAtKiosk.
  ///
  /// In vi, this message translates to:
  /// **'Lấy đồ tại kiosk'**
  String get ordPickupAtKiosk;

  /// No description provided for @ordPickupAtKioskBody.
  ///
  /// In vi, this message translates to:
  /// **'Dùng mã này tại kiosk để mở ô, lấy đồ ra, rồi đóng cửa tủ lại trước khi xác nhận kết thúc thuê. Bạn cũng có thể bấm mở trực tiếp trên app nếu đang ở gần tủ.'**
  String get ordPickupAtKioskBody;

  /// No description provided for @ordOpenBoxOnPhone.
  ///
  /// In vi, this message translates to:
  /// **'Mở {box} trên điện thoại (GPS/QR)'**
  String ordOpenBoxOnPhone(Object box);

  /// No description provided for @ordPickedUpAndClosed.
  ///
  /// In vi, this message translates to:
  /// **'Đã lấy đồ và đóng tủ'**
  String get ordPickedUpAndClosed;

  /// No description provided for @ordRentalEnded.
  ///
  /// In vi, this message translates to:
  /// **'Đã kết thúc kỳ thuê'**
  String get ordRentalEnded;

  /// No description provided for @ordNoLockerInfo.
  ///
  /// In vi, this message translates to:
  /// **'Đơn chưa có thông tin tủ.'**
  String get ordNoLockerInfo;

  /// No description provided for @ordLockerNoLocation.
  ///
  /// In vi, this message translates to:
  /// **'Tủ chưa có vị trí để chỉ đường.'**
  String get ordLockerNoLocation;

  /// No description provided for @ordCantOpenMapsApp.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được ứng dụng bản đồ trên máy này.'**
  String get ordCantOpenMapsApp;

  /// No description provided for @ordExtensionPaymentFor.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán gia hạn thời gian đơn #{id}'**
  String ordExtensionPaymentFor(Object id);

  /// No description provided for @ordPaidSuccessfully.
  ///
  /// In vi, this message translates to:
  /// **'Đơn hàng của bạn đã được thanh toán thành công.'**
  String get ordPaidSuccessfully;

  /// No description provided for @ordPaymentNotCompleted.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch chưa hoàn tất hoặc đã bị hủy. Vui lòng thử lại.'**
  String get ordPaymentNotCompleted;

  /// No description provided for @ordAwaitingPaymentPull.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ xác nhận thanh toán — kéo xuống để làm mới sau ít phút.'**
  String get ordAwaitingPaymentPull;

  /// No description provided for @ordAwaitingPaymentConfirmPickup.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ xác nhận thanh toán — bấm lại \"Xác nhận lấy đồ\" sau khi đơn hiện Đã thanh toán.'**
  String get ordAwaitingPaymentConfirmPickup;

  /// No description provided for @ordConfirmPickup.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận lấy đồ'**
  String get ordConfirmPickup;

  /// No description provided for @ordConfirmPickupBody.
  ///
  /// In vi, this message translates to:
  /// **'Bạn xác nhận đã nhận lại đầy đủ đồ đạc của đơn hàng này? Thao tác này sẽ đóng và hoàn tất đơn hàng.'**
  String get ordConfirmPickupBody;

  /// No description provided for @ordPickedUpComplete.
  ///
  /// In vi, this message translates to:
  /// **'Đã lấy đồ — Hoàn tất'**
  String get ordPickedUpComplete;

  /// No description provided for @ordCompletedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất đơn hàng!'**
  String get ordCompletedTitle;

  /// No description provided for @ordPaidAndPickedUp.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã thanh toán và lấy đồ thành công. Đơn hàng đã hoàn tất.'**
  String get ordPaidAndPickedUp;

  /// No description provided for @ordReceivedComplete.
  ///
  /// In vi, this message translates to:
  /// **'Đã nhận đồ — đơn hoàn tất'**
  String get ordReceivedComplete;

  /// No description provided for @ordPaidNotCompletedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đã thanh toán — chưa hoàn tất đơn'**
  String get ordPaidNotCompletedTitle;

  /// No description provided for @ordPaidNotCompletedBody.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống đã ghi nhận thanh toán nhưng chưa hoàn tất được đơn: {reason}\nBạn có thể thử lại \"Xác nhận lấy đồ\" hoặc gửi khiếu nại trong chi tiết đơn.'**
  String ordPaidNotCompletedBody(Object reason);

  /// No description provided for @ordNoOvertimeFeeDue.
  ///
  /// In vi, this message translates to:
  /// **'Đơn hàng không có phí quá giờ cần thanh toán'**
  String get ordNoOvertimeFeeDue;

  /// No description provided for @ordLockrLocker.
  ///
  /// In vi, this message translates to:
  /// **'Tủ Lock.R'**
  String get ordLockrLocker;

  /// No description provided for @ordOverdue.
  ///
  /// In vi, this message translates to:
  /// **'Đã quá hạn'**
  String get ordOverdue;

  /// No description provided for @ordOverdueFee.
  ///
  /// In vi, this message translates to:
  /// **'Phí quá hạn'**
  String get ordOverdueFee;

  /// No description provided for @ordAwaitingPaymentOpenBox.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ xác nhận thanh toán — mở ô sau khi đơn hiện Đã thanh toán.'**
  String get ordAwaitingPaymentOpenBox;

  /// No description provided for @ordOvertimePaidOpening.
  ///
  /// In vi, this message translates to:
  /// **'Đã thanh toán phí quá giờ — chuẩn bị mở ô'**
  String get ordOvertimePaidOpening;

  /// No description provided for @ordSendingOpenCommand.
  ///
  /// In vi, this message translates to:
  /// **'Đang gửi lệnh mở {box} tới tủ...'**
  String ordSendingOpenCommand(Object box);

  /// No description provided for @ordBoxOpened.
  ///
  /// In vi, this message translates to:
  /// **'Tủ đã mở {box} — mời bạn thao tác rồi đóng cửa.'**
  String ordBoxOpened(Object box);

  /// No description provided for @ordBoxOpenFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được {box}{detail}'**
  String ordBoxOpenFailed(Object box, Object detail);

  /// No description provided for @ordNoBoxPinInfo.
  ///
  /// In vi, this message translates to:
  /// **'Đơn chưa có thông tin ô/PIN để mở tủ.'**
  String get ordNoBoxPinInfo;

  /// No description provided for @ordOverdueRentalNotice.
  ///
  /// In vi, this message translates to:
  /// **'Đơn thuê đã quá hạn. Đã ghi nhận xử lý phí quá giờ — mời bạn mở ô lấy đồ và đóng tủ để hoàn tất.'**
  String get ordOverdueRentalNotice;

  /// No description provided for @ordDelegatedTo.
  ///
  /// In vi, this message translates to:
  /// **'Đã ủy quyền lấy hộ{to}. Mã PIN cũ đã hết hiệu lực.'**
  String ordDelegatedTo(Object to);

  /// No description provided for @ordDelegatedToPhone.
  ///
  /// In vi, this message translates to:
  /// **' cho {phone}'**
  String ordDelegatedToPhone(Object phone);

  /// No description provided for @ordChangePinQuestion.
  ///
  /// In vi, this message translates to:
  /// **'Đổi mã PIN?'**
  String get ordChangePinQuestion;

  /// No description provided for @ordChangePinReceiver.
  ///
  /// In vi, this message translates to:
  /// **'Mã PIN hiện tại sẽ hết hiệu lực. Người nhận cần mã mới để lấy hàng — hãy gửi lại mã mới cho họ.'**
  String get ordChangePinReceiver;

  /// No description provided for @ordChangePinNow.
  ///
  /// In vi, this message translates to:
  /// **'Mã PIN hiện tại sẽ hết hiệu lực ngay và được thay bằng mã mới.'**
  String get ordChangePinNow;

  /// No description provided for @ordChangeCode.
  ///
  /// In vi, this message translates to:
  /// **'Đổi mã'**
  String get ordChangeCode;

  /// No description provided for @ordPinChangedSeeDetail.
  ///
  /// In vi, this message translates to:
  /// **'Đã đổi mã PIN — xem mã mới trong chi tiết đơn.'**
  String get ordPinChangedSeeDetail;

  /// No description provided for @ordPinChangedNew.
  ///
  /// In vi, this message translates to:
  /// **'Đã đổi mã PIN mới: {pin}'**
  String ordPinChangedNew(Object pin);

  /// No description provided for @ordPinChangeNotSupported.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ chưa hỗ trợ đổi mã PIN.'**
  String get ordPinChangeNotSupported;

  /// No description provided for @ordReceiverEmailSaved.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu email người nhận {email}. Lock.R báo người nhận khi đơn được thanh toán.'**
  String ordReceiverEmailSaved(Object email);

  /// No description provided for @ordPickupCodeSentTo.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi mã mở tủ tới {email}.'**
  String ordPickupCodeSentTo(Object email);

  /// No description provided for @ordOrderInfoResentTo.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi lại thông tin đơn tới {email}.'**
  String ordOrderInfoResentTo(Object email);

  /// No description provided for @ordEmailCodeNotSupported.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ chưa hỗ trợ gửi mã qua email.'**
  String get ordEmailCodeNotSupported;

  /// No description provided for @ordNewOrderCreated.
  ///
  /// In vi, this message translates to:
  /// **'Đã tạo đơn mới — xem trong danh sách'**
  String get ordNewOrderCreated;

  /// No description provided for @ordDropoffConfirmed.
  ///
  /// In vi, this message translates to:
  /// **'Đã xác nhận bỏ đồ'**
  String get ordDropoffConfirmed;

  /// No description provided for @ordConfirmPickedUpQuestion.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận đã lấy đồ?'**
  String get ordConfirmPickedUpQuestion;

  /// No description provided for @ordConfirmPickedUpBody.
  ///
  /// In vi, this message translates to:
  /// **'Đơn sẽ hoàn tất và ô tủ được giải phóng. Chỉ xác nhận khi bạn đã lấy đồ ra khỏi ô.'**
  String get ordConfirmPickedUpBody;

  /// No description provided for @ordPickedUp.
  ///
  /// In vi, this message translates to:
  /// **'Đã lấy đồ'**
  String get ordPickedUp;

  /// No description provided for @ordBoxHasTicket.
  ///
  /// In vi, this message translates to:
  /// **'Ô này đã có phiếu RPT-{id} đang được KTV xử lý.'**
  String ordBoxHasTicket(Object id);

  /// No description provided for @ordCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Đã hủy đơn'**
  String get ordCancelled;

  /// No description provided for @ordMyOrdersSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý các đơn hàng của bạn'**
  String get ordMyOrdersSubtitle;

  /// No description provided for @ordTabRecent.
  ///
  /// In vi, this message translates to:
  /// **'Gần đây'**
  String get ordTabRecent;

  /// No description provided for @ordTabInUse.
  ///
  /// In vi, this message translates to:
  /// **'Đang dùng'**
  String get ordTabInUse;

  /// No description provided for @ordTabCompleted.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn thành'**
  String get ordTabCompleted;

  /// No description provided for @ordTabCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Đã hủy'**
  String get ordTabCancelled;

  /// No description provided for @ordTabAwaitingPickup.
  ///
  /// In vi, this message translates to:
  /// **'Chờ lấy'**
  String get ordTabAwaitingPickup;

  /// No description provided for @ordListLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải danh sách đơn...'**
  String get ordListLoading;

  /// No description provided for @ordNoOrdersYet.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có đơn nào'**
  String get ordNoOrdersYet;

  /// No description provided for @ordNoMatchingOrders.
  ///
  /// In vi, this message translates to:
  /// **'Không có đơn phù hợp'**
  String get ordNoMatchingOrders;

  /// No description provided for @ordIncomingLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải hàng chờ nhận...'**
  String get ordIncomingLoading;

  /// No description provided for @ordNoIncoming.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có hàng chờ nhận'**
  String get ordNoIncoming;

  /// No description provided for @ordNoIncomingHint.
  ///
  /// In vi, this message translates to:
  /// **'Khi có người gửi hàng tới số điện thoại của bạn, đơn sẽ hiện ở đây.'**
  String get ordNoIncomingHint;

  /// No description provided for @ordNoIncomingMatch.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy đơn hàng chờ nhận nào theo bộ lọc đã chọn.'**
  String get ordNoIncomingMatch;

  /// No description provided for @ordMyOrders.
  ///
  /// In vi, this message translates to:
  /// **'Đơn của tôi'**
  String get ordMyOrders;

  /// No description provided for @ordIncoming.
  ///
  /// In vi, this message translates to:
  /// **'Hàng chờ nhận'**
  String get ordIncoming;

  /// No description provided for @ordPickupDeadlineValue.
  ///
  /// In vi, this message translates to:
  /// **'Hạn lấy: {time}'**
  String ordPickupDeadlineValue(Object time);

  /// No description provided for @ordLockerNameUnknown.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tra được tên tủ'**
  String get ordLockerNameUnknown;

  /// No description provided for @ordPayAndPickup.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán & lấy đồ'**
  String get ordPayAndPickup;

  /// No description provided for @ordAwaitingTechnician.
  ///
  /// In vi, this message translates to:
  /// **'Chờ KTV xử lý'**
  String get ordAwaitingTechnician;

  /// No description provided for @ordReview.
  ///
  /// In vi, this message translates to:
  /// **'Xem lại'**
  String get ordReview;

  /// No description provided for @ordDropIntoLocker.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ đồ vào tủ'**
  String get ordDropIntoLocker;

  /// No description provided for @ordPickupNow.
  ///
  /// In vi, this message translates to:
  /// **'Lấy đồ ngay'**
  String get ordPickupNow;

  /// No description provided for @ordOvertimePausedNoTime.
  ///
  /// In vi, this message translates to:
  /// **'Phí quá giờ tạm dừng — chờ KTV xử lý ô, chưa cần thanh toán'**
  String get ordOvertimePausedNoTime;

  /// No description provided for @ordOvertimePausedSince.
  ///
  /// In vi, this message translates to:
  /// **'Phí quá giờ tạm dừng từ {time} — chưa cần thanh toán'**
  String ordOvertimePausedSince(Object time);

  /// No description provided for @ordStorageExpiredTapPay.
  ///
  /// In vi, this message translates to:
  /// **'Đơn đã hết hạn lưu tủ {hours} — Bấm để thanh toán & lấy đồ'**
  String ordStorageExpiredTapPay(Object hours);

  /// No description provided for @ordOverdueMayCharge.
  ///
  /// In vi, this message translates to:
  /// **'Đơn đã quá hạn — có thể phát sinh phí'**
  String get ordOverdueMayCharge;

  /// No description provided for @ordRelocatedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đã điều chuyển sang Ô số {box} an toàn'**
  String ordRelocatedTitle(Object box);

  /// No description provided for @ordRelocatedSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'KTV đã chuyển đồ từ ô cũ (#{oldBox}) sang ô mới do sự cố. Mã PIN mới đã sẵn sàng.'**
  String ordRelocatedSubtitle(Object oldBox);

  /// No description provided for @ordCheckedNoIssueTitle.
  ///
  /// In vi, this message translates to:
  /// **'KTV đã kiểm tra: {box} không có sự cố'**
  String ordCheckedNoIssueTitle(Object box);

  /// No description provided for @ordCheckedNoIssueSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Ô hoạt động bình thường, bạn lấy đồ bằng mã PIN như thường lệ. Xem phản hồi của KTV trong phiếu.'**
  String get ordCheckedNoIssueSubtitle;

  /// No description provided for @ordResolvedTitle.
  ///
  /// In vi, this message translates to:
  /// **'{box} đã được KTV kiểm tra & xử lý xong'**
  String ordResolvedTitle(Object box);

  /// No description provided for @ordResolvedSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tài sản trong ô được bảo vệ an toàn.'**
  String get ordResolvedSubtitle;

  /// No description provided for @ordReportedTitle.
  ///
  /// In vi, this message translates to:
  /// **'{box} đã được báo sự cố'**
  String ordReportedTitle(Object box);

  /// No description provided for @ordReportedCancelHint.
  ///
  /// In vi, this message translates to:
  /// **'Hãy hủy đơn này và đặt ô khác (hoặc liên hệ KTV).'**
  String get ordReportedCancelHint;

  /// No description provided for @ordReportedBlocked.
  ///
  /// In vi, this message translates to:
  /// **'Đồ của bạn vẫn được giữ an toàn trong ô. KTV đang xử lý — phí quá giờ tạm dừng, bạn chưa cần thanh toán.'**
  String get ordReportedBlocked;

  /// No description provided for @ordReportedCanOpen.
  ///
  /// In vi, this message translates to:
  /// **'KTV sẽ tới kiểm tra ô. Bạn vẫn mở ô bằng mã PIN để lấy đồ được — phí quá giờ tạm dừng từ lúc báo.'**
  String get ordReportedCanOpen;

  /// No description provided for @ordReasonValue.
  ///
  /// In vi, this message translates to:
  /// **'Lý do: {reason}'**
  String ordReasonValue(Object reason);

  /// No description provided for @ordViewRelocation.
  ///
  /// In vi, this message translates to:
  /// **'Xem chi tiết điều chuyển & ảnh KTV'**
  String get ordViewRelocation;

  /// No description provided for @ordViewRecord.
  ///
  /// In vi, this message translates to:
  /// **'Xem biên bản & ảnh minh chứng'**
  String get ordViewRecord;

  /// No description provided for @ordPayOvertimeFee.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán phí quá giờ'**
  String get ordPayOvertimeFee;

  /// No description provided for @ordOriginalDeadline.
  ///
  /// In vi, this message translates to:
  /// **'Hạn trả ban đầu'**
  String get ordOriginalDeadline;

  /// No description provided for @ordOverdueDuration.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian quá hạn'**
  String get ordOverdueDuration;

  /// No description provided for @ordOvertimeRate.
  ///
  /// In vi, this message translates to:
  /// **'Đơn giá quá giờ'**
  String get ordOvertimeRate;

  /// No description provided for @ordCapRule.
  ///
  /// In vi, this message translates to:
  /// **'Quy định mức trần'**
  String get ordCapRule;

  /// No description provided for @ordCapMax.
  ///
  /// In vi, this message translates to:
  /// **'Tối đa {amount}'**
  String ordCapMax(Object amount);

  /// No description provided for @ordCapPercent.
  ///
  /// In vi, this message translates to:
  /// **'{percent}% đơn'**
  String ordCapPercent(Object percent);

  /// No description provided for @ordOvertimeFee.
  ///
  /// In vi, this message translates to:
  /// **'Phí quá giờ'**
  String get ordOvertimeFee;

  /// No description provided for @ordAmountDue.
  ///
  /// In vi, this message translates to:
  /// **'Cần thanh toán:'**
  String get ordAmountDue;

  /// No description provided for @ordPayAmount.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán {amount}'**
  String ordPayAmount(Object amount);

  /// No description provided for @ordOpenBoxPickup.
  ///
  /// In vi, this message translates to:
  /// **'Mở ô lấy đồ'**
  String get ordOpenBoxPickup;

  /// No description provided for @ordBoxReleased.
  ///
  /// In vi, this message translates to:
  /// **'Đã giải phóng ô'**
  String get ordBoxReleased;

  /// No description provided for @ordBoxNotAssigned.
  ///
  /// In vi, this message translates to:
  /// **'Chưa gán ô'**
  String get ordBoxNotAssigned;

  /// No description provided for @ordPinCancelledSecurity.
  ///
  /// In vi, this message translates to:
  /// **'•••••• (Đã hủy để bảo mật)'**
  String get ordPinCancelledSecurity;

  /// No description provided for @ordTechInCharge.
  ///
  /// In vi, this message translates to:
  /// **'KTV phụ trách'**
  String get ordTechInCharge;

  /// No description provided for @ordRelocationRecordUpper.
  ///
  /// In vi, this message translates to:
  /// **'HỒ SƠ ĐIỀU CHUYỂN Ô AN TOÀN'**
  String get ordRelocationRecordUpper;

  /// No description provided for @ordRelocationRecordSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Hàng đã được chuyển sang ô mới do ô cũ gặp sự cố kỹ thuật'**
  String get ordRelocationRecordSubtitle;

  /// No description provided for @ordOriginalBoxUpper.
  ///
  /// In vi, this message translates to:
  /// **'Ô BAN ĐẦU'**
  String get ordOriginalBoxUpper;

  /// No description provided for @ordBoxNumberHash.
  ///
  /// In vi, this message translates to:
  /// **'Ô số #{number}'**
  String ordBoxNumberHash(Object number);

  /// No description provided for @ordTechnicalIssue.
  ///
  /// In vi, this message translates to:
  /// **'Gặp sự cố kỹ thuật'**
  String get ordTechnicalIssue;

  /// No description provided for @ordNewBoxUpper.
  ///
  /// In vi, this message translates to:
  /// **'Ô TIẾP NHẬN MỚI'**
  String get ordNewBoxUpper;

  /// No description provided for @ordHoldingSafely.
  ///
  /// In vi, this message translates to:
  /// **'Đang chứa hàng an toàn'**
  String get ordHoldingSafely;

  /// No description provided for @ordOldBoxCheckedAt.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian mở ô cũ kiểm tra'**
  String get ordOldBoxCheckedAt;

  /// No description provided for @ordMovedAt.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian chuyển qua ô mới'**
  String get ordMovedAt;

  /// No description provided for @ordOriginalBoxPin.
  ///
  /// In vi, this message translates to:
  /// **'Mã PIN ô ban đầu'**
  String get ordOriginalBoxPin;

  /// No description provided for @ordPinDisabled.
  ///
  /// In vi, this message translates to:
  /// **'Đã vô hiệu hoá (Mã cũ hết hạn)'**
  String get ordPinDisabled;

  /// No description provided for @ordNewBoxPin.
  ///
  /// In vi, this message translates to:
  /// **'Mã PIN mở ô mới (#{box})'**
  String ordNewBoxPin(Object box);

  /// No description provided for @ordPinActive.
  ///
  /// In vi, this message translates to:
  /// **'{pin} (Đang kích hoạt)'**
  String ordPinActive(Object pin);

  /// No description provided for @ordTechPhotos.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh KTV chụp quá trình kiểm tra & chuyển ô ({count} ảnh):'**
  String ordTechPhotos(Object count);

  /// No description provided for @ordViewFullRecord.
  ///
  /// In vi, this message translates to:
  /// **'Xem toàn bộ biên bản sự cố KTV & nhật ký ➔'**
  String get ordViewFullRecord;

  /// No description provided for @ordOrderDetailHash.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết đơn #{id}'**
  String ordOrderDetailHash(Object id);

  /// No description provided for @ordServiceHash.
  ///
  /// In vi, this message translates to:
  /// **'Dịch vụ #{id}'**
  String ordServiceHash(Object id);

  /// No description provided for @ordReviewDroneJourney.
  ///
  /// In vi, this message translates to:
  /// **'Xem lại hành trình drone'**
  String get ordReviewDroneJourney;

  /// No description provided for @ordTrackDrone.
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi giao drone'**
  String get ordTrackDrone;

  /// No description provided for @ordPayAndCompletePickup.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán ({amount}) & Lấy đồ hoàn tất'**
  String ordPayAndCompletePickup(Object amount);

  /// No description provided for @ordIPickedUpCompleteOrder.
  ///
  /// In vi, this message translates to:
  /// **'Tôi đã lấy đồ — Hoàn tất đơn'**
  String get ordIPickedUpCompleteOrder;

  /// No description provided for @ordOpenBoxToPickup.
  ///
  /// In vi, this message translates to:
  /// **'Mở {box} để lấy đồ'**
  String ordOpenBoxToPickup(Object box);

  /// No description provided for @ordReorder.
  ///
  /// In vi, this message translates to:
  /// **'Đặt lại đơn'**
  String get ordReorder;

  /// No description provided for @ordOpenBoxToDrop.
  ///
  /// In vi, this message translates to:
  /// **'Mở {box} để bỏ đồ'**
  String ordOpenBoxToDrop(Object box);

  /// No description provided for @ordIDroppedOff.
  ///
  /// In vi, this message translates to:
  /// **'Tôi đã bỏ đồ vào ô'**
  String get ordIDroppedOff;

  /// No description provided for @ordPayOvertimeAndOpen.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán phí quá giờ ({amount}) & Mở ô'**
  String ordPayOvertimeAndOpen(Object amount);

  /// No description provided for @ordIPickedUpComplete.
  ///
  /// In vi, this message translates to:
  /// **'Tôi đã lấy đồ — hoàn tất'**
  String get ordIPickedUpComplete;

  /// No description provided for @ordOpenBoxToReturn.
  ///
  /// In vi, this message translates to:
  /// **'Mở {box} để trả tủ & lấy đồ'**
  String ordOpenBoxToReturn(Object box);

  /// No description provided for @ordEndRentalPickup.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc thuê & lấy đồ'**
  String get ordEndRentalPickup;

  /// No description provided for @ordDelegatePickup.
  ///
  /// In vi, this message translates to:
  /// **'Ủy quyền lấy hộ'**
  String get ordDelegatePickup;

  /// No description provided for @ordChangePin.
  ///
  /// In vi, this message translates to:
  /// **'Đổi mã PIN'**
  String get ordChangePin;

  /// No description provided for @ordAddReceiverEmail.
  ///
  /// In vi, this message translates to:
  /// **'Thêm email người nhận'**
  String get ordAddReceiverEmail;

  /// No description provided for @ordChangeReceiverEmail.
  ///
  /// In vi, this message translates to:
  /// **'Đổi email người nhận'**
  String get ordChangeReceiverEmail;

  /// No description provided for @ordResendToReceiver.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại thông tin cho người nhận'**
  String get ordResendToReceiver;

  /// No description provided for @ordCancelOrder.
  ///
  /// In vi, this message translates to:
  /// **'Hủy đơn'**
  String get ordCancelOrder;

  /// No description provided for @ordDirectionsToLocker.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ đường tới tủ'**
  String get ordDirectionsToLocker;

  /// No description provided for @ordRequestRefund.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu hoàn tiền'**
  String get ordRequestRefund;

  /// No description provided for @ordStorageExpiredPay.
  ///
  /// In vi, this message translates to:
  /// **'Đơn đã quá hạn lưu tủ {hours}. Ô tủ đã được giải phóng và đồ đã chuyển về bảo quản an toàn. Quý khách vui lòng thanh toán phí còn lại và bấm \"Thanh toán & lấy đồ\" để hoàn tất.'**
  String ordStorageExpiredPay(Object hours);

  /// No description provided for @ordStorageExpiredCheck.
  ///
  /// In vi, this message translates to:
  /// **'Đơn đã quá hạn lưu tủ {hours}. Ô tủ đã được giải phóng và đồ đã chuyển về bảo quản an toàn. Quý khách vui lòng kiểm tra nhận đồ và bấm \"Tôi đã lấy đồ — Hoàn tất đơn\" để hoàn tất.'**
  String ordStorageExpiredCheck(Object hours);

  /// No description provided for @ordOverduePaidOpen.
  ///
  /// In vi, this message translates to:
  /// **'Đơn quá hạn đã thanh toán phí quá giờ. Mời bạn mở ô để lấy đồ và hoàn tất trả tủ.'**
  String get ordOverduePaidOpen;

  /// No description provided for @ordOverdueNeedPay.
  ///
  /// In vi, this message translates to:
  /// **'Đơn đã quá hạn lấy — cần thanh toán phí quá giờ để mở tủ. {policy}'**
  String ordOverdueNeedPay(Object policy);

  /// No description provided for @ordUnpaidHold.
  ///
  /// In vi, this message translates to:
  /// **'Đơn hàng chưa thanh toán. Vui lòng thanh toán trong vòng {minutes} phút để giữ chỗ tủ, hoặc bấm \"Hủy đơn\" bên dưới để giải phóng ô tủ ngay.'**
  String ordUnpaidHold(Object minutes);

  /// No description provided for @ordPlace.
  ///
  /// In vi, this message translates to:
  /// **'Địa điểm'**
  String get ordPlace;

  /// No description provided for @ordNewBox.
  ///
  /// In vi, this message translates to:
  /// **'Ô mới tiếp nhận'**
  String get ordNewBox;

  /// No description provided for @ordNewBoxValue.
  ///
  /// In vi, this message translates to:
  /// **'Ô số {box} (Đang an toàn)'**
  String ordNewBoxValue(Object box);

  /// No description provided for @ordOriginalBox.
  ///
  /// In vi, this message translates to:
  /// **'Ô ban đầu'**
  String get ordOriginalBox;

  /// No description provided for @ordOriginalBoxValue.
  ///
  /// In vi, this message translates to:
  /// **'Ô số {box} (Gặp sự cố)'**
  String ordOriginalBoxValue(Object box);

  /// No description provided for @ordOldBoxOpenedAt.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian mở ô cũ'**
  String get ordOldBoxOpenedAt;

  /// No description provided for @ordBoxMovedAt.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian chuyển ô'**
  String get ordBoxMovedAt;

  /// No description provided for @ordOriginalPin.
  ///
  /// In vi, this message translates to:
  /// **'Mã PIN ban đầu'**
  String get ordOriginalPin;

  /// No description provided for @ordOrderDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày đặt'**
  String get ordOrderDate;

  /// No description provided for @ordRentalDuration.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian thuê'**
  String get ordRentalDuration;

  /// No description provided for @ordOriginalDeadlineShort.
  ///
  /// In vi, this message translates to:
  /// **'Hạn ban đầu'**
  String get ordOriginalDeadlineShort;

  /// No description provided for @ordCapRuleShort.
  ///
  /// In vi, this message translates to:
  /// **'Quy định trần'**
  String get ordCapRuleShort;

  /// No description provided for @ordOvertimeFeeEstimate.
  ///
  /// In vi, this message translates to:
  /// **'Phí quá giờ tạm tính'**
  String get ordOvertimeFeeEstimate;

  /// No description provided for @ordPenaltyStatus.
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái phạt'**
  String get ordPenaltyStatus;

  /// No description provided for @ordDueToOpen.
  ///
  /// In vi, this message translates to:
  /// **'Cần nộp để mở ô'**
  String get ordDueToOpen;

  /// No description provided for @ordRecipient.
  ///
  /// In vi, this message translates to:
  /// **'Người nhận'**
  String get ordRecipient;

  /// No description provided for @ordRecipientEmail.
  ///
  /// In vi, this message translates to:
  /// **'Email người nhận'**
  String get ordRecipientEmail;

  /// No description provided for @ordDelegatedToLabel.
  ///
  /// In vi, this message translates to:
  /// **'Ủy quyền lấy hộ cho'**
  String get ordDelegatedToLabel;

  /// No description provided for @ordDelegatee.
  ///
  /// In vi, this message translates to:
  /// **'Người được ủy quyền'**
  String get ordDelegatee;

  /// No description provided for @ordDelegationMessage.
  ///
  /// In vi, this message translates to:
  /// **'Lời nhắn ủy quyền'**
  String get ordDelegationMessage;

  /// No description provided for @ordDelegatedAt.
  ///
  /// In vi, this message translates to:
  /// **'Ủy quyền lúc'**
  String get ordDelegatedAt;

  /// No description provided for @ordExpectedPickup.
  ///
  /// In vi, this message translates to:
  /// **'Dự kiến người nhận lấy'**
  String get ordExpectedPickup;

  /// No description provided for @ordDeliveryAddress.
  ///
  /// In vi, this message translates to:
  /// **'Địa chỉ giao'**
  String get ordDeliveryAddress;

  /// No description provided for @ordFromLocker.
  ///
  /// In vi, this message translates to:
  /// **'Gửi từ tủ'**
  String get ordFromLocker;

  /// No description provided for @ordFlightDistance.
  ///
  /// In vi, this message translates to:
  /// **'Quãng đường bay'**
  String get ordFlightDistance;

  /// No description provided for @ordBasePrice.
  ///
  /// In vi, this message translates to:
  /// **'Giá gốc'**
  String get ordBasePrice;

  /// No description provided for @ordExtraFees.
  ///
  /// In vi, this message translates to:
  /// **'Phí phát sinh'**
  String get ordExtraFees;

  /// No description provided for @ordPointsUsed.
  ///
  /// In vi, this message translates to:
  /// **'Điểm đã dùng'**
  String get ordPointsUsed;

  /// No description provided for @ordTotal.
  ///
  /// In vi, this message translates to:
  /// **'Tổng tiền'**
  String get ordTotal;

  /// No description provided for @ordRemaining.
  ///
  /// In vi, this message translates to:
  /// **'Còn phải trả'**
  String get ordRemaining;

  /// No description provided for @ordPaidAt.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán lúc'**
  String get ordPaidAt;

  /// No description provided for @ordParcel.
  ///
  /// In vi, this message translates to:
  /// **'Kiện hàng'**
  String get ordParcel;

  /// No description provided for @ordDeliveryIncident.
  ///
  /// In vi, this message translates to:
  /// **'Sự cố giao hàng'**
  String get ordDeliveryIncident;

  /// No description provided for @ordPaused.
  ///
  /// In vi, this message translates to:
  /// **'Đang tạm dừng'**
  String get ordPaused;

  /// No description provided for @ordPausedAt.
  ///
  /// In vi, this message translates to:
  /// **'Tạm dừng lúc'**
  String get ordPausedAt;

  /// No description provided for @ordDeliveryIncomplete.
  ///
  /// In vi, this message translates to:
  /// **'Giao không hoàn tất'**
  String get ordDeliveryIncomplete;

  /// No description provided for @ordRecordedAt.
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhận lúc'**
  String get ordRecordedAt;

  /// No description provided for @ordParcelReturned.
  ///
  /// In vi, this message translates to:
  /// **'Đã trả kiện cho bạn'**
  String get ordParcelReturned;

  /// No description provided for @ordNewBoxPinUpper.
  ///
  /// In vi, this message translates to:
  /// **'Mã PIN mở Ô MỚI (#{box}):'**
  String ordNewBoxPinUpper(Object box);

  /// No description provided for @ordOldPinDisabledNote.
  ///
  /// In vi, this message translates to:
  /// **'🔒 Mã PIN ô cũ đã bị vô hiệu hoá. Chỉ sử dụng mã trên để mở ô mới an toàn.'**
  String get ordOldPinDisabledNote;

  /// No description provided for @ordPickupCodeForTech.
  ///
  /// In vi, this message translates to:
  /// **'Mã lấy hàng — đọc cho kỹ thuật viên khi tới lấy'**
  String get ordPickupCodeForTech;

  /// No description provided for @ordTimeline.
  ///
  /// In vi, this message translates to:
  /// **'Mốc thời gian'**
  String get ordTimeline;

  /// No description provided for @payMethodWallet.
  ///
  /// In vi, this message translates to:
  /// **'Ví Lock.R'**
  String get payMethodWallet;

  /// No description provided for @payMethodSepay.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển khoản (SePay)'**
  String get payMethodSepay;

  /// No description provided for @payMethodCash.
  ///
  /// In vi, this message translates to:
  /// **'Tiền mặt'**
  String get payMethodCash;

  /// No description provided for @ordPaymentMethod.
  ///
  /// In vi, this message translates to:
  /// **'Hình thức thanh toán'**
  String get ordPaymentMethod;

  /// No description provided for @ordTransactionId.
  ///
  /// In vi, this message translates to:
  /// **'Mã giao dịch'**
  String get ordTransactionId;

  /// No description provided for @ordPaymentTime.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian thanh toán'**
  String get ordPaymentTime;

  /// No description provided for @ordTransferred.
  ///
  /// In vi, this message translates to:
  /// **'Đã chuyển tiền'**
  String get ordTransferred;

  /// No description provided for @ordRejected.
  ///
  /// In vi, this message translates to:
  /// **'Bị từ chối'**
  String get ordRejected;

  /// No description provided for @ordAwaitingTransfer.
  ///
  /// In vi, this message translates to:
  /// **'Chờ chuyển khoản'**
  String get ordAwaitingTransfer;

  /// No description provided for @ordRefundHash.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tiền #{id}'**
  String ordRefundHash(Object id);

  /// No description provided for @ordRefundAmount.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền hoàn'**
  String get ordRefundAmount;

  /// No description provided for @ordReceivingAccount.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản nhận'**
  String get ordReceivingAccount;

  /// No description provided for @ordCompletedAt.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian hoàn tất'**
  String get ordCompletedAt;

  /// No description provided for @ordRequestedAt.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian yêu cầu'**
  String get ordRequestedAt;

  /// No description provided for @ordSeeRefunds.
  ///
  /// In vi, this message translates to:
  /// **'Xem chi tiết ở mục Hoàn tiền'**
  String get ordSeeRefunds;

  /// No description provided for @ordExtensionPayment.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán gia hạn thời gian'**
  String get ordExtensionPayment;

  /// No description provided for @ordAttemptN.
  ///
  /// In vi, this message translates to:
  /// **'Lần {n}'**
  String ordAttemptN(Object n);

  /// No description provided for @ordInterventionRecord.
  ///
  /// In vi, this message translates to:
  /// **'Biên bản can thiệp & bảo vệ tài sản:'**
  String get ordInterventionRecord;

  /// No description provided for @ordBoxIncidentTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sự cố ô tủ - Đơn hàng #{code}'**
  String ordBoxIncidentTitle(Object code);

  /// No description provided for @ordViewTechEvidence.
  ///
  /// In vi, this message translates to:
  /// **'Xem chi tiết & ảnh minh chứng KTV'**
  String get ordViewTechEvidence;

  /// No description provided for @ordInfoRelocated.
  ///
  /// In vi, this message translates to:
  /// **'ℹ️ Hàng của bạn đã được chuyển sang ô mới. Vui lòng kiểm tra mã mở ô mới trong app.'**
  String get ordInfoRelocated;

  /// No description provided for @ordInfoSealedHub.
  ///
  /// In vi, this message translates to:
  /// **'ℹ️ Hàng được niêm phong an toàn và đưa về Hub. Nhân viên sẽ liên hệ bạn để thu xếp lại.'**
  String get ordInfoSealedHub;

  /// No description provided for @ordInfoHandedOver.
  ///
  /// In vi, this message translates to:
  /// **'ℹ️ Hàng đã được bàn giao trực tiếp. Nếu có thắc mắc vui lòng liên hệ bộ phận CSKH.'**
  String get ordInfoHandedOver;

  /// No description provided for @ordEmailWithCode.
  ///
  /// In vi, this message translates to:
  /// **'Lock.R gửi lại mã mở tủ, nơi lấy và hạn lấy hàng tới email này. Sửa email nếu người nhận chưa nhận được thư.'**
  String get ordEmailWithCode;

  /// No description provided for @ordEmailOrderInfo.
  ///
  /// In vi, this message translates to:
  /// **'Hàng chưa vào tủ: Lock.R gửi lại thư báo có đơn sắp tới (chưa kèm mã). Mã mở tủ được gửi khi bạn bỏ hàng vào ô.'**
  String get ordEmailOrderInfo;

  /// No description provided for @ordEmailSaveOnly.
  ///
  /// In vi, this message translates to:
  /// **'Đơn chưa thanh toán. Lock.R báo người nhận qua email này khi đơn được thanh toán, và gửi mã mở tủ khi bạn bỏ hàng vào ô.'**
  String get ordEmailSaveOnly;

  /// No description provided for @ordEnterRecipientEmail.
  ///
  /// In vi, this message translates to:
  /// **'Nhập email người nhận'**
  String get ordEnterRecipientEmail;

  /// No description provided for @ordSaveEmail.
  ///
  /// In vi, this message translates to:
  /// **'Lưu email'**
  String get ordSaveEmail;

  /// No description provided for @ordSendEmail.
  ///
  /// In vi, this message translates to:
  /// **'Gửi email'**
  String get ordSendEmail;

  /// No description provided for @commonCopy.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép'**
  String get commonCopy;

  /// No description provided for @commonCopyTapHint.
  ///
  /// In vi, this message translates to:
  /// **'Chạm để sao chép'**
  String get commonCopyTapHint;

  /// No description provided for @commonRemove.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ'**
  String get commonRemove;

  /// No description provided for @commonFullNameShort.
  ///
  /// In vi, this message translates to:
  /// **'Họ tên'**
  String get commonFullNameShort;

  /// No description provided for @commonSubtotal.
  ///
  /// In vi, this message translates to:
  /// **'Tạm tính'**
  String get commonSubtotal;

  /// No description provided for @commonDiscountCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã giảm giá'**
  String get commonDiscountCode;

  /// No description provided for @commonRewardPoints.
  ///
  /// In vi, this message translates to:
  /// **'Điểm thưởng'**
  String get commonRewardPoints;

  /// No description provided for @commonChooseLocker.
  ///
  /// In vi, this message translates to:
  /// **'Chọn tủ'**
  String get commonChooseLocker;

  /// No description provided for @commonBoxType.
  ///
  /// In vi, this message translates to:
  /// **'Loại ô'**
  String get commonBoxType;

  /// No description provided for @commonSelectedLocker.
  ///
  /// In vi, this message translates to:
  /// **'Tủ đã chọn'**
  String get commonSelectedLocker;

  /// No description provided for @commonNoFreeBoxes.
  ///
  /// In vi, this message translates to:
  /// **'Hết ô'**
  String get commonNoFreeBoxes;

  /// No description provided for @commonFreeBoxes.
  ///
  /// In vi, this message translates to:
  /// **'Còn {count} ô trống'**
  String commonFreeBoxes(Object count);

  /// No description provided for @commonStayToPay.
  ///
  /// In vi, this message translates to:
  /// **'Ở lại thanh toán'**
  String get commonStayToPay;

  /// No description provided for @commonCancelAndExit.
  ///
  /// In vi, this message translates to:
  /// **'Hủy đơn & Thoát'**
  String get commonCancelAndExit;

  /// No description provided for @commonPaymentEyebrow.
  ///
  /// In vi, this message translates to:
  /// **'LOCK.R • THANH TOÁN'**
  String get commonPaymentEyebrow;

  /// No description provided for @commonOrderCode.
  ///
  /// In vi, this message translates to:
  /// **'Đơn {code}'**
  String commonOrderCode(Object code);

  /// No description provided for @commonScanQrPayHold.
  ///
  /// In vi, this message translates to:
  /// **'Quét mã QR trên và chuyển khoản trong {minutes} phút để giữ ô — mã bỏ hàng sẽ tự hiện sau khi thanh toán.'**
  String commonScanQrPayHold(Object minutes);

  /// No description provided for @commonScanQrPayHoldRent.
  ///
  /// In vi, this message translates to:
  /// **'Quét mã QR trên và chuyển khoản trong {minutes} phút để giữ ô — mã mở ô sẽ tự hiện sau khi thanh toán.'**
  String commonScanQrPayHoldRent(Object minutes);

  /// No description provided for @commonPaySuccessPinReady.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán thành công! Mã PIN mở ô tủ đã sẵn sàng.'**
  String get commonPaySuccessPinReady;

  /// No description provided for @daysValue.
  ///
  /// In vi, this message translates to:
  /// **'{days} ngày'**
  String daysValue(int days);

  /// No description provided for @pricePerDay.
  ///
  /// In vi, this message translates to:
  /// **'{price}/ngày'**
  String pricePerDay(Object price);

  /// No description provided for @sizeSmallShort.
  ///
  /// In vi, this message translates to:
  /// **'Nhỏ'**
  String get sizeSmallShort;

  /// No description provided for @sizeMediumShort.
  ///
  /// In vi, this message translates to:
  /// **'Vừa'**
  String get sizeMediumShort;

  /// No description provided for @sizeLargeShort.
  ///
  /// In vi, this message translates to:
  /// **'Lớn'**
  String get sizeLargeShort;

  /// No description provided for @boxOfOrder.
  ///
  /// In vi, this message translates to:
  /// **'ô của đơn'**
  String get boxOfOrder;

  /// No description provided for @sendBoxOpened.
  ///
  /// In vi, this message translates to:
  /// **'Ô đã mở — đặt hàng vào, đóng cửa rồi bấm xác nhận.'**
  String get sendBoxOpened;

  /// No description provided for @sendBoxOpenFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được ô'**
  String get sendBoxOpenFailed;

  /// No description provided for @sendDroppedShare.
  ///
  /// In vi, this message translates to:
  /// **'Đã bỏ hàng. Gửi mã lấy hàng cho người nhận bằng nút Chia sẻ bên dưới.'**
  String get sendDroppedShare;

  /// No description provided for @sendEnterRecipientEmail.
  ///
  /// In vi, this message translates to:
  /// **'Nhập email người nhận để Lock.R gửi mã mở tủ'**
  String get sendEnterRecipientEmail;

  /// No description provided for @sendEnterRecipientPhone.
  ///
  /// In vi, this message translates to:
  /// **'Nhập số điện thoại người nhận'**
  String get sendEnterRecipientPhone;

  /// No description provided for @sendPhone10Digits.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại gồm 10 số, bắt đầu bằng 0'**
  String get sendPhone10Digits;

  /// No description provided for @sendCancelCreateQuestion.
  ///
  /// In vi, this message translates to:
  /// **'Hủy tạo đơn hàng?'**
  String get sendCancelCreateQuestion;

  /// No description provided for @sendCancelCreateBody.
  ///
  /// In vi, this message translates to:
  /// **'Đơn hàng chưa được thanh toán. Nếu bạn thoát bây giờ hoặc không hoàn tất thanh toán trong vòng {minutes} phút, đơn hàng sẽ bị hủy và ô tủ sẽ được giải phóng.'**
  String sendCancelCreateBody(Object minutes);

  /// No description provided for @sendCancelledReleased.
  ///
  /// In vi, this message translates to:
  /// **'Đã hủy đơn hàng và giải phóng ô tủ.'**
  String get sendCancelledReleased;

  /// No description provided for @sendTitle.
  ///
  /// In vi, this message translates to:
  /// **'Gửi hàng qua tủ'**
  String get sendTitle;

  /// No description provided for @sendSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Gửi đồ nhanh chóng & tiện lợi'**
  String get sendSubtitle;

  /// No description provided for @sendCreateAndGetPin.
  ///
  /// In vi, this message translates to:
  /// **'Tạo đơn & lấy PIN bỏ hàng'**
  String get sendCreateAndGetPin;

  /// No description provided for @sendLoadingLockers.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải danh sách tủ...'**
  String get sendLoadingLockers;

  /// No description provided for @sendIntro.
  ///
  /// In vi, this message translates to:
  /// **'Gửi hàng cho người khác qua tủ: bạn bỏ hàng vào ô bằng PIN, hệ thống sinh PIN mới gửi người nhận để họ tới lấy.'**
  String get sendIntro;

  /// No description provided for @sendStandardOnly.
  ///
  /// In vi, this message translates to:
  /// **'Gửi hàng dùng ô thường; ô vali (XL) chỉ để thuê giữ đồ. Hãy chắc kiện hàng vừa ô trước khi tạo đơn.'**
  String get sendStandardOnly;

  /// No description provided for @sendRecipientPhoneHint.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại người nhận'**
  String get sendRecipientPhoneHint;

  /// No description provided for @sendRecipientNameHint.
  ///
  /// In vi, this message translates to:
  /// **'Tên người nhận (tùy chọn)'**
  String get sendRecipientNameHint;

  /// No description provided for @sendRecipientEmailHint.
  ///
  /// In vi, this message translates to:
  /// **'Email người nhận'**
  String get sendRecipientEmailHint;

  /// No description provided for @sendEmailInfo.
  ///
  /// In vi, this message translates to:
  /// **'Lock.R gửi email cho người nhận ngay khi đơn được thanh toán (báo có hàng sắp tới) và gửi mã lấy hàng khi bạn bỏ hàng vào ô. Gửi lại được trong chi tiết đơn; bấm \"Chia sẻ mã cho người nhận\" để gửi thêm qua Zalo/SMS.'**
  String get sendEmailInfo;

  /// No description provided for @sendRecipientMessage.
  ///
  /// In vi, this message translates to:
  /// **'Lời nhắn cho người nhận'**
  String get sendRecipientMessage;

  /// No description provided for @sendMessageHint.
  ///
  /// In vi, this message translates to:
  /// **'VD: Hàng dễ vỡ, mở nhẹ tay (tùy chọn)'**
  String get sendMessageHint;

  /// No description provided for @sendBoxSize.
  ///
  /// In vi, this message translates to:
  /// **'Ô {size}'**
  String sendBoxSize(Object size);

  /// No description provided for @sendSelectedBox.
  ///
  /// In vi, this message translates to:
  /// **'Ô đã chọn'**
  String get sendSelectedBox;

  /// No description provided for @sendFeePerParcel.
  ///
  /// In vi, this message translates to:
  /// **'{price}/lượt gửi'**
  String sendFeePerParcel(Object price);

  /// No description provided for @sendBoxTaken.
  ///
  /// In vi, this message translates to:
  /// **'Ô vừa được đặt — chọn ô khác'**
  String get sendBoxTaken;

  /// No description provided for @sendStep1Title.
  ///
  /// In vi, this message translates to:
  /// **'Bước 1 — Bỏ hàng vào ô'**
  String get sendStep1Title;

  /// No description provided for @sendStep1Body.
  ///
  /// In vi, this message translates to:
  /// **'Đến tủ, nhập PIN bên dưới để mở {box}, đặt hàng vào rồi đóng cửa.'**
  String sendStep1Body(Object box);

  /// No description provided for @sendStep2Title.
  ///
  /// In vi, this message translates to:
  /// **'Bước 2 — Đã bỏ hàng xong'**
  String get sendStep2Title;

  /// No description provided for @sendPinSentToRecipient.
  ///
  /// In vi, this message translates to:
  /// **'PIN nhận hàng đã được gửi tới tài khoản người nhận.'**
  String get sendPinSentToRecipient;

  /// No description provided for @sendSharePinWithRecipient.
  ///
  /// In vi, this message translates to:
  /// **'Hãy chuyển mã PIN nhận hàng bên dưới cho người nhận.'**
  String get sendSharePinWithRecipient;

  /// No description provided for @sendRecipientEntersPin.
  ///
  /// In vi, this message translates to:
  /// **'Người nhận nhập PIN tại tủ để lấy hàng'**
  String get sendRecipientEntersPin;

  /// No description provided for @sendEnterPinToDrop.
  ///
  /// In vi, this message translates to:
  /// **'Nhập PIN tại tủ để mở ô và bỏ hàng'**
  String get sendEnterPinToDrop;

  /// No description provided for @sendLockrAccount.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản Lock.R'**
  String get sendLockrAccount;

  /// No description provided for @sendHasAccount.
  ///
  /// In vi, this message translates to:
  /// **'Đã có — PIN gửi thẳng vào app'**
  String get sendHasAccount;

  /// No description provided for @sendNoAccount.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có — bạn cần chuyển PIN cho người nhận'**
  String get sendNoAccount;

  /// No description provided for @sendPickupBefore.
  ///
  /// In vi, this message translates to:
  /// **'Người nhận cần lấy hàng trước {deadline} ({remaining}). {policy}'**
  String sendPickupBefore(Object deadline, Object remaining, Object policy);

  /// No description provided for @sendDropInstructions.
  ///
  /// In vi, this message translates to:
  /// **'Mở ô bằng nút bên dưới hoặc nhập PIN tại tủ, đặt hàng vào, đóng cửa rồi xác nhận. Xác nhận ngay trên màn hình tủ cũng được.'**
  String get sendDropInstructions;

  /// No description provided for @sendOpenToDrop.
  ///
  /// In vi, this message translates to:
  /// **'Mở ô để bỏ hàng'**
  String get sendOpenToDrop;

  /// No description provided for @sendIDropped.
  ///
  /// In vi, this message translates to:
  /// **'Tôi đã bỏ hàng vào ô'**
  String get sendIDropped;

  /// No description provided for @sendStepDrop.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ hàng'**
  String get sendStepDrop;

  /// No description provided for @sendStepRecipientPicks.
  ///
  /// In vi, this message translates to:
  /// **'Người nhận lấy'**
  String get sendStepRecipientPicks;

  /// No description provided for @rentPaymentWaiting.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ xác nhận thanh toán, vui lòng đợi giây lát'**
  String get rentPaymentWaiting;

  /// No description provided for @rentOpenedStart.
  ///
  /// In vi, this message translates to:
  /// **'Ô đã mở thành công — bắt đầu kỳ thuê!'**
  String get rentOpenedStart;

  /// No description provided for @rentOpenSimulated.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được ô thật (giả lập: đã xác nhận bỏ đồ & bắt đầu kỳ thuê)'**
  String get rentOpenSimulated;

  /// No description provided for @rentCancelQuestion.
  ///
  /// In vi, this message translates to:
  /// **'Hủy tạo đơn thuê tủ?'**
  String get rentCancelQuestion;

  /// No description provided for @rentCancelBody.
  ///
  /// In vi, this message translates to:
  /// **'Đơn thuê tủ chưa được thanh toán. Nếu bạn thoát bây giờ hoặc không hoàn tất thanh toán trong vòng {minutes} phút, đơn sẽ bị hủy và ô tủ sẽ được giải phóng.'**
  String rentCancelBody(Object minutes);

  /// No description provided for @rentCancelledReleased.
  ///
  /// In vi, this message translates to:
  /// **'Đã hủy đơn thuê tủ và giải phóng ô tủ.'**
  String get rentCancelledReleased;

  /// No description provided for @rentTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thuê tủ giữ đồ'**
  String get rentTitle;

  /// No description provided for @rentSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Chọn điểm tủ & thời gian sử dụng'**
  String get rentSubtitle;

  /// No description provided for @rentNow.
  ///
  /// In vi, this message translates to:
  /// **'Thuê ngay'**
  String get rentNow;

  /// No description provided for @rentLoadingInfo.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải thông tin điểm tủ...'**
  String get rentLoadingInfo;

  /// No description provided for @rentIntro.
  ///
  /// In vi, this message translates to:
  /// **'Thuê ô để giữ đồ cá nhân theo giờ hoặc theo ngày. PIN mở ô được dùng nhiều lần trong suốt kỳ thuê.'**
  String get rentIntro;

  /// No description provided for @rentDuration.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian thuê'**
  String get rentDuration;

  /// No description provided for @rentOptionalHint.
  ///
  /// In vi, this message translates to:
  /// **'Tùy chọn...'**
  String get rentOptionalHint;

  /// No description provided for @rentDiscountValue.
  ///
  /// In vi, this message translates to:
  /// **'Giảm: -{amount}'**
  String rentDiscountValue(Object amount);

  /// No description provided for @rentPointsValue.
  ///
  /// In vi, this message translates to:
  /// **'Điểm thưởng: {value}'**
  String rentPointsValue(Object value);

  /// No description provided for @rentByHour.
  ///
  /// In vi, this message translates to:
  /// **'Theo giờ'**
  String get rentByHour;

  /// No description provided for @rentByDay.
  ///
  /// In vi, this message translates to:
  /// **'Theo ngày'**
  String get rentByDay;

  /// No description provided for @rentMinusDay.
  ///
  /// In vi, this message translates to:
  /// **'Bớt 1 ngày'**
  String get rentMinusDay;

  /// No description provided for @rentDaysHours.
  ///
  /// In vi, this message translates to:
  /// **'{days} ngày · {hours} giờ'**
  String rentDaysHours(Object days, Object hours);

  /// No description provided for @rentPlusDay.
  ///
  /// In vi, this message translates to:
  /// **'Thêm 1 ngày'**
  String get rentPlusDay;

  /// No description provided for @rentRunning.
  ///
  /// In vi, this message translates to:
  /// **'Kỳ thuê đang chạy'**
  String get rentRunning;

  /// No description provided for @rentPinUntil.
  ///
  /// In vi, this message translates to:
  /// **'PIN mở ô nhiều lần tới {time}.'**
  String rentPinUntil(Object time);

  /// No description provided for @rentPinMultiUse.
  ///
  /// In vi, this message translates to:
  /// **'PIN dùng nhiều lần trong kỳ thuê'**
  String get rentPinMultiUse;

  /// No description provided for @rentExpiresAt.
  ///
  /// In vi, this message translates to:
  /// **'Hết hạn thuê: {deadline} ({remaining}). {policy}'**
  String rentExpiresAt(Object deadline, Object remaining, Object policy);

  /// No description provided for @rentHeldDropOff.
  ///
  /// In vi, this message translates to:
  /// **'Đã giữ ô — bỏ đồ vào'**
  String get rentHeldDropOff;

  /// No description provided for @rentEnterPinToOpen.
  ///
  /// In vi, this message translates to:
  /// **'Nhập PIN để mở {box} hoặc mở bằng nút bên dưới để bắt đầu kỳ thuê.'**
  String rentEnterPinToOpen(Object box);

  /// No description provided for @rentOpenToDrop.
  ///
  /// In vi, this message translates to:
  /// **'Mở ô để bỏ đồ'**
  String get rentOpenToDrop;

  /// No description provided for @rentExtensionUnpaid.
  ///
  /// In vi, this message translates to:
  /// **'Còn phí gia hạn chưa thanh toán — cần trả trước khi kết thúc thuê.'**
  String get rentExtensionUnpaid;

  /// No description provided for @rentDoneSeeOrders.
  ///
  /// In vi, this message translates to:
  /// **'Xong — xem trong Đơn của tôi'**
  String get rentDoneSeeOrders;

  /// No description provided for @cellAvailable.
  ///
  /// In vi, this message translates to:
  /// **'Trống'**
  String get cellAvailable;

  /// No description provided for @cellReservedHeld.
  ///
  /// In vi, this message translates to:
  /// **'Đã giữ chỗ'**
  String get cellReservedHeld;

  /// No description provided for @cellOccupied.
  ///
  /// In vi, this message translates to:
  /// **'Có đồ'**
  String get cellOccupied;

  /// No description provided for @cellAwaitingTechCheck.
  ///
  /// In vi, this message translates to:
  /// **'Chờ KTV kiểm tra'**
  String get cellAwaitingTechCheck;

  /// No description provided for @cellCleaning.
  ///
  /// In vi, this message translates to:
  /// **'Đang vệ sinh'**
  String get cellCleaning;

  /// No description provided for @stAwaitingDropoff.
  ///
  /// In vi, this message translates to:
  /// **'Chờ bỏ đồ'**
  String get stAwaitingDropoff;

  /// No description provided for @stAwaitingDispatch.
  ///
  /// In vi, this message translates to:
  /// **'Chờ điều phối'**
  String get stAwaitingDispatch;

  /// No description provided for @stAccepted.
  ///
  /// In vi, this message translates to:
  /// **'Đã tiếp nhận'**
  String get stAccepted;

  /// No description provided for @stLaunching.
  ///
  /// In vi, this message translates to:
  /// **'Đang khởi phóng'**
  String get stLaunching;

  /// No description provided for @stDropReported.
  ///
  /// In vi, this message translates to:
  /// **'Đã báo rơi kiện'**
  String get stDropReported;

  /// No description provided for @stPickupAssigned.
  ///
  /// In vi, this message translates to:
  /// **'KTV đang tới lấy hàng'**
  String get stPickupAssigned;

  /// No description provided for @stPickedUpByTech.
  ///
  /// In vi, this message translates to:
  /// **'KTV đã lấy hàng'**
  String get stPickedUpByTech;

  /// No description provided for @stFailed.
  ///
  /// In vi, this message translates to:
  /// **'Giao không thành công'**
  String get stFailed;

  /// No description provided for @stDeparted.
  ///
  /// In vi, this message translates to:
  /// **'Drone đã rời trạm'**
  String get stDeparted;

  /// No description provided for @stEnRoute.
  ///
  /// In vi, this message translates to:
  /// **'Drone đang bay'**
  String get stEnRoute;

  /// No description provided for @stApproaching.
  ///
  /// In vi, this message translates to:
  /// **'Drone sắp đến'**
  String get stApproaching;

  /// No description provided for @stArrived.
  ///
  /// In vi, this message translates to:
  /// **'Drone đã đến tủ'**
  String get stArrived;

  /// No description provided for @stReadyForPickup.
  ///
  /// In vi, this message translates to:
  /// **'Chờ nhận hàng'**
  String get stReadyForPickup;

  /// No description provided for @stStoring.
  ///
  /// In vi, this message translates to:
  /// **'Đang trong tủ'**
  String get stStoring;

  /// No description provided for @stCollected.
  ///
  /// In vi, this message translates to:
  /// **'Đã thu gom'**
  String get stCollected;

  /// No description provided for @stProcessing.
  ///
  /// In vi, this message translates to:
  /// **'Đang xử lý'**
  String get stProcessing;

  /// No description provided for @stReadyToReturn.
  ///
  /// In vi, this message translates to:
  /// **'Sẵn sàng trả'**
  String get stReadyToReturn;

  /// No description provided for @stNew.
  ///
  /// In vi, this message translates to:
  /// **'Mới'**
  String get stNew;

  /// No description provided for @stDone.
  ///
  /// In vi, this message translates to:
  /// **'Đã xong'**
  String get stDone;

  /// No description provided for @stNotConfirmed.
  ///
  /// In vi, this message translates to:
  /// **'Không xác nhận'**
  String get stNotConfirmed;

  /// No description provided for @typeLaundry.
  ///
  /// In vi, this message translates to:
  /// **'Giặt ủi'**
  String get typeLaundry;

  /// No description provided for @typeStorage.
  ///
  /// In vi, this message translates to:
  /// **'Gửi đồ'**
  String get typeStorage;

  /// No description provided for @typeParcel.
  ///
  /// In vi, this message translates to:
  /// **'Nhận hàng'**
  String get typeParcel;

  /// No description provided for @incidentSince.
  ///
  /// In vi, this message translates to:
  /// **' từ {time}'**
  String incidentSince(Object time);

  /// No description provided for @incidentReportedCanOpen.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã báo sự cố ô — kỹ thuật viên sẽ tới kiểm tra. Bạn vẫn có thể mở ô bằng mã PIN để lấy đồ; phí quá giờ tạm dừng{since}.'**
  String incidentReportedCanOpen(Object since);

  /// No description provided for @incidentBlocked.
  ///
  /// In vi, this message translates to:
  /// **'Ô đang chờ kỹ thuật viên xử lý sự cố. Đồ của bạn vẫn được giữ an toàn trong ô, phí quá giờ tạm dừng{since} — bạn chưa cần thanh toán hay gia hạn. Lock.R sẽ báo khi lấy được đồ.'**
  String incidentBlocked(Object since);

  /// No description provided for @durDaysHours.
  ///
  /// In vi, this message translates to:
  /// **'{days} ngày {hours} giờ'**
  String durDaysHours(Object days, Object hours);

  /// No description provided for @durHoursMinutes.
  ///
  /// In vi, this message translates to:
  /// **'{hours} giờ {minutes} phút'**
  String durHoursMinutes(Object hours, Object minutes);

  /// No description provided for @durUnderMinute.
  ///
  /// In vi, this message translates to:
  /// **'dưới 1 phút'**
  String get durUnderMinute;

  /// No description provided for @timeRemaining.
  ///
  /// In vi, this message translates to:
  /// **'Còn {time}'**
  String timeRemaining(Object time);

  /// No description provided for @timeOverdueBy.
  ///
  /// In vi, this message translates to:
  /// **'Quá hạn {time}'**
  String timeOverdueBy(Object time);

  /// No description provided for @credEnterPinAtLocker.
  ///
  /// In vi, this message translates to:
  /// **'Nhập PIN tại màn hình tủ để mở ô'**
  String get credEnterPinAtLocker;

  /// No description provided for @credPinCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép mã PIN'**
  String get credPinCopied;

  /// No description provided for @credAt.
  ///
  /// In vi, this message translates to:
  /// **'Tại: {name}'**
  String credAt(Object name);

  /// No description provided for @unlockBlePermissionBlocked.
  ///
  /// In vi, this message translates to:
  /// **'Quyền Bluetooth (Thiết bị lân cận) đang bị chặn. Mở Cài đặt để cho phép rồi quét lại.'**
  String get unlockBlePermissionBlocked;

  /// No description provided for @unlockBlePermissionDenied.
  ///
  /// In vi, this message translates to:
  /// **'App cần quyền Bluetooth để dò tủ. Bấm Quét lại và chọn Cho phép.'**
  String get unlockBlePermissionDenied;

  /// No description provided for @unlockBleOff.
  ///
  /// In vi, this message translates to:
  /// **'Bluetooth của điện thoại đang tắt. Bật Bluetooth rồi bấm Quét lại.'**
  String get unlockBleOff;

  /// No description provided for @unlockBleUnsupported.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị này không hỗ trợ Bluetooth. Dùng Quét mã QR hoặc mã PIN.'**
  String get unlockBleUnsupported;

  /// No description provided for @unlockNoSignal.
  ///
  /// In vi, this message translates to:
  /// **'Chưa phát hiện sóng Bluetooth của tủ gần đây.'**
  String get unlockNoSignal;

  /// No description provided for @unlockOpenBox.
  ///
  /// In vi, this message translates to:
  /// **'Mở {box}'**
  String unlockOpenBox(Object box);

  /// No description provided for @unlockOverdueRental.
  ///
  /// In vi, this message translates to:
  /// **'Đơn thuê đã quá hạn. Đã ghi nhận xử lý phí quá giờ — mời bạn lấy đồ và đóng tủ để hoàn tất trả tủ.'**
  String get unlockOverdueRental;

  /// No description provided for @unlockEndsRental.
  ///
  /// In vi, this message translates to:
  /// **'Mở ô sẽ kết thúc kỳ thuê và giải phóng ô tủ. Vui lòng lấy hết đồ.'**
  String get unlockEndsRental;

  /// No description provided for @unlockScanQr.
  ///
  /// In vi, this message translates to:
  /// **'Quét QR'**
  String get unlockScanQr;

  /// No description provided for @unlockPin.
  ///
  /// In vi, this message translates to:
  /// **'Mã PIN'**
  String get unlockPin;

  /// No description provided for @unlockScanning.
  ///
  /// In vi, this message translates to:
  /// **'Đang quét sóng Bluetooth của tủ...'**
  String get unlockScanning;

  /// No description provided for @unlockStandClose.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng đứng cách tủ {locker} dưới 2m'**
  String unlockStandClose(Object locker);

  /// No description provided for @unlockConnected.
  ///
  /// In vi, this message translates to:
  /// **'Đã kết nối Bluetooth tủ'**
  String get unlockConnected;

  /// No description provided for @unlockSimulateRpi.
  ///
  /// In vi, this message translates to:
  /// **'Mô phỏng RPi'**
  String get unlockSimulateRpi;

  /// No description provided for @unlockDistanceSignal.
  ///
  /// In vi, this message translates to:
  /// **'Khoảng cách: {distance} • Tín hiệu {rssi} dBm'**
  String unlockDistanceSignal(Object distance, Object rssi);

  /// No description provided for @unlockOpenAndReturn.
  ///
  /// In vi, this message translates to:
  /// **'Mở {box} & Trả tủ'**
  String unlockOpenAndReturn(Object box);

  /// No description provided for @unlockOpenNow.
  ///
  /// In vi, this message translates to:
  /// **'Mở {box} ngay (1-chạm)'**
  String unlockOpenNow(Object box);

  /// No description provided for @unlockNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy sóng Bluetooth của tủ'**
  String get unlockNotFound;

  /// No description provided for @unlockEnsureBluetooth.
  ///
  /// In vi, this message translates to:
  /// **'Đảm bảo điện thoại đã bật Bluetooth hoặc dùng Quét mã QR thay thế.'**
  String get unlockEnsureBluetooth;

  /// No description provided for @unlockScanAgain.
  ///
  /// In vi, this message translates to:
  /// **'Quét lại'**
  String get unlockScanAgain;

  /// No description provided for @unlockRescan.
  ///
  /// In vi, this message translates to:
  /// **'Dò sóng lại'**
  String get unlockRescan;

  /// No description provided for @unlockQrTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xác thực qua tem QR trên tủ'**
  String get unlockQrTitle;

  /// No description provided for @unlockQrBody.
  ///
  /// In vi, this message translates to:
  /// **'Dùng camera điện thoại quét mã QR dán trên thân tủ {locker} để mở {box}.'**
  String unlockQrBody(Object locker, Object box);

  /// No description provided for @unlockStartCamera.
  ///
  /// In vi, this message translates to:
  /// **'Bật Camera quét tem QR'**
  String get unlockStartCamera;

  /// No description provided for @unlockKioskPinUpper.
  ///
  /// In vi, this message translates to:
  /// **'MÃ PIN MỞ TRÊN MÀN HÌNH KIOSK'**
  String get unlockKioskPinUpper;

  /// No description provided for @unlockCodeCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép mã'**
  String get unlockCodeCopied;

  /// No description provided for @unlockCopyPin.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép mã PIN'**
  String get unlockCopyPin;

  /// No description provided for @unlockKioskGuide.
  ///
  /// In vi, this message translates to:
  /// **'Hướng dẫn mở tại màn hình Kiosk:'**
  String get unlockKioskGuide;

  /// No description provided for @unlockKioskStep1.
  ///
  /// In vi, this message translates to:
  /// **'Đến trước màn hình cảm ứng của {locker}.'**
  String unlockKioskStep1(Object locker);

  /// No description provided for @unlockKioskStep2.
  ///
  /// In vi, this message translates to:
  /// **'Chọn nút \"Mở tủ\" hoặc \"Nhận đồ\".'**
  String get unlockKioskStep2;

  /// No description provided for @unlockKioskStep3.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã PIN {pin} để cửa {box} bung chốt.'**
  String unlockKioskStep3(Object pin, Object box);

  /// No description provided for @extrasNotEligible.
  ///
  /// In vi, this message translates to:
  /// **'Đơn chưa đủ điều kiện áp mã này'**
  String get extrasNotEligible;

  /// No description provided for @extrasCodeInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Mã không hợp lệ hoặc đã hết hạn'**
  String get extrasCodeInvalid;

  /// No description provided for @extrasCodeApplied.
  ///
  /// In vi, this message translates to:
  /// **'Đã áp mã \"{code}\"'**
  String extrasCodeApplied(Object code);

  /// No description provided for @extrasChooseCode.
  ///
  /// In vi, this message translates to:
  /// **'Chọn mã giảm giá'**
  String get extrasChooseCode;

  /// No description provided for @extrasNoCodes.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có mã giảm giá nào.'**
  String get extrasNoCodes;

  /// No description provided for @extrasNoCodesHere.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có mã giảm giá dùng được ở tủ này.'**
  String get extrasNoCodesHere;

  /// No description provided for @tierBronze.
  ///
  /// In vi, this message translates to:
  /// **'Đồng'**
  String get tierBronze;

  /// No description provided for @tierSilver.
  ///
  /// In vi, this message translates to:
  /// **'Bạc'**
  String get tierSilver;

  /// No description provided for @tierGold.
  ///
  /// In vi, this message translates to:
  /// **'Vàng'**
  String get tierGold;

  /// No description provided for @tierPlatinum.
  ///
  /// In vi, this message translates to:
  /// **'Bạch kim'**
  String get tierPlatinum;

  /// No description provided for @tierNextPoints.
  ///
  /// In vi, this message translates to:
  /// **'còn {points} điểm lên hạng {tier}'**
  String tierNextPoints(Object points, Object tier);

  /// No description provided for @tierYouHavePoints.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đang có {points} điểm'**
  String tierYouHavePoints(Object points);

  /// No description provided for @tierRank.
  ///
  /// In vi, this message translates to:
  /// **'hạng {tier}'**
  String tierRank(Object tier);

  /// No description provided for @tierHighest.
  ///
  /// In vi, this message translates to:
  /// **'hạng cao nhất'**
  String get tierHighest;

  /// No description provided for @payStatusPaid.
  ///
  /// In vi, this message translates to:
  /// **'Đã thanh toán'**
  String get payStatusPaid;

  /// No description provided for @payStatusPending.
  ///
  /// In vi, this message translates to:
  /// **'Chờ thanh toán'**
  String get payStatusPending;

  /// No description provided for @payStatusFailed.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán lỗi'**
  String get payStatusFailed;

  /// No description provided for @payStatusNone.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có thanh toán'**
  String get payStatusNone;

  /// No description provided for @rulesRentRange.
  ///
  /// In vi, this message translates to:
  /// **'Thuê từ {min} đến {max}.'**
  String rulesRentRange(Object min, Object max);

  /// No description provided for @rulesEvery24h.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi 24 giờ tính {price}.'**
  String rulesEvery24h(Object price);

  /// No description provided for @rulesDailyCapFrom.
  ///
  /// In vi, this message translates to:
  /// **'Thuê từ {hours} giờ trong một ngày chỉ tính giá ngày {price}.'**
  String rulesDailyCapFrom(Object hours, Object price);

  /// No description provided for @rulesRentalOvertime.
  ///
  /// In vi, this message translates to:
  /// **'Quá giờ thuê tính {rate} cho tới khi lấy đồ hoặc gia hạn.'**
  String rulesRentalOvertime(Object rate);

  /// No description provided for @rulesNoOvertimeFee.
  ///
  /// In vi, this message translates to:
  /// **'Không tính phí quá giờ.'**
  String get rulesNoOvertimeFee;

  /// No description provided for @rulesPercentOfOrder.
  ///
  /// In vi, this message translates to:
  /// **'{percent}% giá trị đơn'**
  String rulesPercentOfOrder(Object percent);

  /// No description provided for @rulesCapSuffix.
  ///
  /// In vi, this message translates to:
  /// **' (tối đa {caps})'**
  String rulesCapSuffix(Object caps);

  /// No description provided for @rulesAnd.
  ///
  /// In vi, this message translates to:
  /// **' và '**
  String get rulesAnd;

  /// No description provided for @rulesOvertimeFee.
  ///
  /// In vi, this message translates to:
  /// **'Phí quá giờ {rate}{cap}.'**
  String rulesOvertimeFee(Object rate, Object cap);

  /// No description provided for @rulesSendPickup.
  ///
  /// In vi, this message translates to:
  /// **'Người nhận có {hours} giờ để lấy hàng kể từ lúc bạn bỏ hàng vào ô. {policy}'**
  String rulesSendPickup(Object hours, Object policy);

  /// No description provided for @rulesDronePickup.
  ///
  /// In vi, this message translates to:
  /// **'Đơn hàng được lưu trữ {hours} giờ kể từ lúc drone thả hàng vào ô. Giờ và ngày hết hạn sẽ được báo ngay khi hàng vào ô. {policy}'**
  String rulesDronePickup(Object hours, Object policy);

  /// No description provided for @rulesDroneStoredUntil.
  ///
  /// In vi, this message translates to:
  /// **'Đơn hàng được lưu trữ {hours} giờ, vui lòng lấy trước {deadline}.'**
  String rulesDroneStoredUntil(Object hours, Object deadline);

  /// No description provided for @rulesLoyaltyEarn.
  ///
  /// In vi, this message translates to:
  /// **'Tích {percent}% số tiền bạn thanh toán thành điểm (1 điểm = {value}), cộng khi đơn hoàn tất.'**
  String rulesLoyaltyEarn(Object percent, Object value);

  /// No description provided for @rulesRedeemDisabled.
  ///
  /// In vi, this message translates to:
  /// **'Hiện chưa áp dụng dùng điểm để thanh toán.'**
  String get rulesRedeemDisabled;

  /// No description provided for @rulesRedeemMin.
  ///
  /// In vi, this message translates to:
  /// **' (từ {points} điểm)'**
  String rulesRedeemMin(Object points);

  /// No description provided for @rulesRedeem.
  ///
  /// In vi, this message translates to:
  /// **'1 điểm = {value} khi thanh toán, dùng tối đa {percent}% giá trị đơn{min}.'**
  String rulesRedeem(Object value, Object percent, Object min);

  /// No description provided for @loyaltyRedeemDisabled.
  ///
  /// In vi, this message translates to:
  /// **'Hiện chưa áp dụng dùng điểm để thanh toán'**
  String get loyaltyRedeemDisabled;

  /// No description provided for @loyaltyFullyDiscounted.
  ///
  /// In vi, this message translates to:
  /// **'Đơn đã được giảm hết, không cần dùng điểm'**
  String get loyaltyFullyDiscounted;

  /// No description provided for @loyaltyNoPoints.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa có điểm — điểm được cộng khi đơn hoàn tất'**
  String get loyaltyNoPoints;

  /// No description provided for @loyaltyBelowMin.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có {balance} điểm, cần tối thiểu {min} điểm mỗi lần dùng'**
  String loyaltyBelowMin(Object balance, Object min);

  /// No description provided for @loyaltyOrderTooSmall.
  ///
  /// In vi, this message translates to:
  /// **'Đơn chưa đủ giá trị để dùng tối thiểu {min} điểm'**
  String loyaltyOrderTooSmall(Object min);

  /// No description provided for @loyaltyOffer.
  ///
  /// In vi, this message translates to:
  /// **'Dùng {points} điểm · giảm {amount}'**
  String loyaltyOffer(Object points, Object amount);

  /// No description provided for @loyaltyYouHave.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có {balance} điểm'**
  String loyaltyYouHave(Object balance);

  /// No description provided for @loyaltyRule.
  ///
  /// In vi, this message translates to:
  /// **'1 điểm = {value}, tối đa {percent}% giá trị đơn'**
  String loyaltyRule(Object value, Object percent);

  /// No description provided for @loyaltyPointsDiscount.
  ///
  /// In vi, this message translates to:
  /// **'-{amount} ({points} điểm)'**
  String loyaltyPointsDiscount(Object amount, Object points);

  /// No description provided for @loyaltyCantUseNow.
  ///
  /// In vi, this message translates to:
  /// **'Chưa dùng được điểm thưởng lúc này — đơn được tính đủ giá.'**
  String get loyaltyCantUseNow;

  /// No description provided for @loyaltyPlusPoints.
  ///
  /// In vi, this message translates to:
  /// **'+{points} điểm'**
  String loyaltyPlusPoints(Object points);

  /// No description provided for @loyaltyWillEarn.
  ///
  /// In vi, this message translates to:
  /// **'Điểm sẽ được cộng'**
  String get loyaltyWillEarn;

  /// No description provided for @loyaltyEarned.
  ///
  /// In vi, this message translates to:
  /// **'Điểm được cộng'**
  String get loyaltyEarned;

  /// No description provided for @loyaltyNotRecorded.
  ///
  /// In vi, this message translates to:
  /// **'Chưa ghi nhận'**
  String get loyaltyNotRecorded;

  /// No description provided for @loyaltyReversed.
  ///
  /// In vi, this message translates to:
  /// **'{text} · đã thu hồi {points}'**
  String loyaltyReversed(Object text, Object points);

  /// No description provided for @loyaltyChecking.
  ///
  /// In vi, this message translates to:
  /// **'Đang kiểm tra điểm thưởng...'**
  String get loyaltyChecking;

  /// No description provided for @loyaltyLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tải được điểm thưởng — đơn được tính đủ giá.'**
  String get loyaltyLoadFailed;

  /// No description provided for @loyaltyUsePoints.
  ///
  /// In vi, this message translates to:
  /// **'Dùng điểm thưởng'**
  String get loyaltyUsePoints;

  /// No description provided for @sepayCreateFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tạo được giao dịch thanh toán. Vui lòng thử lại.'**
  String get sepayCreateFailed;

  /// No description provided for @sepayNoQr.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ chưa trả mã VietQR cho giao dịch này. Vui lòng thử lại sau.'**
  String get sepayNoQr;

  /// No description provided for @sepayNoTxForSim.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có mã giao dịch để giả lập. Vui lòng thử lại.'**
  String get sepayNoTxForSim;

  /// No description provided for @sepayReceivedUpdating.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống đã nhận được tiền, đơn hàng đang được cập nhật...'**
  String get sepayReceivedUpdating;

  /// No description provided for @sepayPartial.
  ///
  /// In vi, this message translates to:
  /// **'Đã nhận {received} — còn thiếu {remaining}. Mã QR bên dưới là số còn thiếu.'**
  String sepayPartial(Object received, Object remaining);

  /// No description provided for @sepayScanToPay.
  ///
  /// In vi, this message translates to:
  /// **'Quét mã VietQR để thanh toán'**
  String get sepayScanToPay;

  /// No description provided for @sepayQrLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được mã QR'**
  String get sepayQrLoadFailed;

  /// No description provided for @sepayAccountNumber.
  ///
  /// In vi, this message translates to:
  /// **'Số tài khoản:'**
  String get sepayAccountNumber;

  /// No description provided for @sepayAmountToTransfer.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền cần chuyển:'**
  String get sepayAmountToTransfer;

  /// No description provided for @sepayTransferContent.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung chuyển khoản:'**
  String get sepayTransferContent;

  /// No description provided for @sepayContentCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép nội dung chuyển khoản'**
  String get sepayContentCopied;

  /// No description provided for @sepayWaiting.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ xác nhận thanh toán…'**
  String get sepayWaiting;

  /// No description provided for @sepayAutoUpdate.
  ///
  /// In vi, this message translates to:
  /// **'Tự động cập nhật ngay sau khi nhận được tiền.'**
  String get sepayAutoUpdate;

  /// No description provided for @sepayPayWithBankApp.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán bằng app ngân hàng'**
  String get sepayPayWithBankApp;

  /// No description provided for @sepayTransferExact.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển khoản đúng số tài khoản, số tiền và nội dung bên dưới.'**
  String get sepayTransferExact;

  /// No description provided for @sepayCreatingQr.
  ///
  /// In vi, this message translates to:
  /// **'Đang tạo mã thanh toán…'**
  String get sepayCreatingQr;

  /// No description provided for @apiErrBleTestNotGranted.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản chưa được admin cho thử mở ô qua Bluetooth ở tủ này.'**
  String get apiErrBleTestNotGranted;

  /// No description provided for @apiErrResolutionPhotoRequired.
  ///
  /// In vi, this message translates to:
  /// **'Cần ít nhất 1 ảnh nghiệm thu trước khi hoàn tất phiếu.'**
  String get apiErrResolutionPhotoRequired;

  /// No description provided for @apiErrLandingPadAbsent.
  ///
  /// In vi, this message translates to:
  /// **'Tủ này không có bãi đáp drone.'**
  String get apiErrLandingPadAbsent;

  /// No description provided for @apiErrLandingPadStatusInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái bãi đáp không hợp lệ.'**
  String get apiErrLandingPadStatusInvalid;

  /// No description provided for @apiErrReportNotClaimable.
  ///
  /// In vi, this message translates to:
  /// **'Phiếu không còn ở trạng thái chờ nhận.'**
  String get apiErrReportNotClaimable;

  /// No description provided for @apiErrDroneRouteRequired.
  ///
  /// In vi, this message translates to:
  /// **'Cần chọn cả tủ gửi và tủ nhận.'**
  String get apiErrDroneRouteRequired;

  /// No description provided for @apiErrDroneRouteInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Tủ gửi và tủ nhận phải khác nhau.'**
  String get apiErrDroneRouteInvalid;

  /// No description provided for @apiErrDroneRouteTooFar.
  ///
  /// In vi, this message translates to:
  /// **'Tủ nhận nằm ngoài tầm bay của drone từ khu vực lấy hàng này.'**
  String get apiErrDroneRouteTooFar;

  /// No description provided for @apiErrDroneRouteTooShort.
  ///
  /// In vi, this message translates to:
  /// **'Tủ nhận ở quá gần điểm lấy hàng nên không cần giao bằng drone — hãy gửi thẳng vào tủ nhận.'**
  String get apiErrDroneRouteTooShort;

  /// No description provided for @apiErrDronePickupOutOfRange.
  ///
  /// In vi, this message translates to:
  /// **'Vị trí ghim nằm ngoài bán kính lấy hàng của tủ gửi drone. Khoảng cách này tính từ nhà bạn đến tủ gửi, khác quãng đường bay giữa hai tủ. Hãy kiểm tra ghim trên bản đồ rồi chọn lại vị trí.'**
  String get apiErrDronePickupOutOfRange;

  /// No description provided for @apiErrDroneNoSourceLocker.
  ///
  /// In vi, this message translates to:
  /// **'Hiện chưa có tủ nào gần bạn sẵn sàng phóng drone. Vui lòng thử lại sau.'**
  String get apiErrDroneNoSourceLocker;

  /// No description provided for @apiErrDroneLockerLocationMissing.
  ///
  /// In vi, this message translates to:
  /// **'Tủ nhận chưa có toạ độ nên chưa giao drone tới được.'**
  String get apiErrDroneLockerLocationMissing;

  /// No description provided for @apiErrDronePickupAddressRequired.
  ///
  /// In vi, this message translates to:
  /// **'Cần nhập địa chỉ lấy hàng.'**
  String get apiErrDronePickupAddressRequired;

  /// No description provided for @apiErrDronePickupLocationRequired.
  ///
  /// In vi, this message translates to:
  /// **'Cần chọn vị trí lấy hàng trên bản đồ.'**
  String get apiErrDronePickupLocationRequired;

  /// No description provided for @apiErrDroneSenderNameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Cần nhập tên người gửi.'**
  String get apiErrDroneSenderNameRequired;

  /// No description provided for @apiErrDroneSenderPhoneInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại người gửi không hợp lệ.'**
  String get apiErrDroneSenderPhoneInvalid;

  /// No description provided for @apiErrDroneSenderEmailInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Email người gửi không hợp lệ.'**
  String get apiErrDroneSenderEmailInvalid;

  /// No description provided for @apiErrDroneReceiverNameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Cần nhập tên người nhận.'**
  String get apiErrDroneReceiverNameRequired;

  /// No description provided for @apiErrDroneReceiverEmailInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Email người nhận không hợp lệ.'**
  String get apiErrDroneReceiverEmailInvalid;

  /// No description provided for @apiErrDroneParcelCategoryRequired.
  ///
  /// In vi, this message translates to:
  /// **'Cần chọn loại hàng.'**
  String get apiErrDroneParcelCategoryRequired;

  /// No description provided for @apiErrDronePickupNotOffered.
  ///
  /// In vi, this message translates to:
  /// **'Việc lấy hàng này không còn được mời cho bạn.'**
  String get apiErrDronePickupNotOffered;

  /// No description provided for @apiErrDronePickupOfferExpired.
  ///
  /// In vi, this message translates to:
  /// **'Lời mời lấy hàng đã hết hạn.'**
  String get apiErrDronePickupOfferExpired;

  /// No description provided for @apiErrDronePickupNotAssignedToUser.
  ///
  /// In vi, this message translates to:
  /// **'Việc lấy hàng này không thuộc về bạn.'**
  String get apiErrDronePickupNotAssignedToUser;

  /// No description provided for @apiErrDronePickupNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Đơn chưa có việc lấy hàng (có thể chưa thanh toán).'**
  String get apiErrDronePickupNotFound;

  /// No description provided for @apiErrDronePickupCodeInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Mã lấy hàng không đúng. Nhờ người gửi đọc lại mã trong đơn.'**
  String get apiErrDronePickupCodeInvalid;

  /// No description provided for @apiErrDronePickupParcelNotVerified.
  ///
  /// In vi, this message translates to:
  /// **'Cần xác nhận kiện đúng khai báo, hoặc báo không lấy được hàng.'**
  String get apiErrDronePickupParcelNotVerified;

  /// No description provided for @apiErrDroneParcelNotPickedUp.
  ///
  /// In vi, this message translates to:
  /// **'Kiện chưa được lấy từ người gửi.'**
  String get apiErrDroneParcelNotPickedUp;

  /// No description provided for @apiErrDroneOrderBlocked.
  ///
  /// In vi, this message translates to:
  /// **'Đơn đang tạm dừng vì sự cố, chưa đi lấy hàng lúc này.'**
  String get apiErrDroneOrderBlocked;

  /// No description provided for @apiErrDroneTechnicianLocationRequired.
  ///
  /// In vi, this message translates to:
  /// **'Cần bật định vị để vào ca nhận việc lấy hàng.'**
  String get apiErrDroneTechnicianLocationRequired;

  /// No description provided for @apiErrDroneTechnicianHasActivePickup.
  ///
  /// In vi, this message translates to:
  /// **'Bạn còn việc lấy hàng đã nhận. Hoàn tất hoặc báo không lấy được trước khi ra ca.'**
  String get apiErrDroneTechnicianHasActivePickup;

  /// No description provided for @apiErrDroneTechnicianOffDuty.
  ///
  /// In vi, this message translates to:
  /// **'Kỹ thuật viên này chưa vào ca.'**
  String get apiErrDroneTechnicianOffDuty;

  /// No description provided for @apiErrDroneTechnicianBusy.
  ///
  /// In vi, this message translates to:
  /// **'Kỹ thuật viên này đang bận việc khác.'**
  String get apiErrDroneTechnicianBusy;

  /// No description provided for @apiErrDroneFailureReasonInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Lý do không hợp lệ cho thao tác này.'**
  String get apiErrDroneFailureReasonInvalid;

  /// No description provided for @apiErrDroneUnchanged.
  ///
  /// In vi, this message translates to:
  /// **'Drone này đang được gán cho nhiệm vụ rồi.'**
  String get apiErrDroneUnchanged;

  /// No description provided for @apiErrDroneFlightsSuspended.
  ///
  /// In vi, this message translates to:
  /// **'Dịch vụ giao drone đang tạm dừng (thời tiết hoặc sự cố vận hành).'**
  String get apiErrDroneFlightsSuspended;

  /// No description provided for @apiErrDroneOutsideFlightHours.
  ///
  /// In vi, this message translates to:
  /// **'Ngoài khung giờ được phép phóng drone.'**
  String get apiErrDroneOutsideFlightHours;

  /// No description provided for @apiErrDroneOpenOrderLimit.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đang có quá nhiều đơn drone chưa hoàn tất. Hoàn tất hoặc huỷ bớt rồi đặt tiếp.'**
  String get apiErrDroneOpenOrderLimit;

  /// No description provided for @apiErrDroneProhibitedItemsNotDeclared.
  ///
  /// In vi, this message translates to:
  /// **'Bạn cần cam kết kiện không chứa hàng cấm bay.'**
  String get apiErrDroneProhibitedItemsNotDeclared;

  /// No description provided for @apiErrDroneParcelSizeInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Nhập đủ dài, rộng, cao của kiện hoặc bỏ trống cả ba.'**
  String get apiErrDroneParcelSizeInvalid;

  /// No description provided for @apiErrDroneParcelTooLarge.
  ///
  /// In vi, this message translates to:
  /// **'Kiện không lọt khoang hàng của drone.'**
  String get apiErrDroneParcelTooLarge;

  /// No description provided for @apiErrDroneParcelCategoryInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Loại hàng không hợp lệ.'**
  String get apiErrDroneParcelCategoryInvalid;

  /// No description provided for @apiErrDroneDeclaredValueTooHigh.
  ///
  /// In vi, this message translates to:
  /// **'Giá trị khai báo vượt mức drone được phép chở.'**
  String get apiErrDroneDeclaredValueTooHigh;

  /// No description provided for @apiErrDroneParcelNotDropped.
  ///
  /// In vi, this message translates to:
  /// **'Người gửi chưa xác nhận bỏ kiện vào ô gửi nên chưa thể tiếp nhận.'**
  String get apiErrDroneParcelNotDropped;

  /// No description provided for @apiErrDroneParcelReturnNotPending.
  ///
  /// In vi, this message translates to:
  /// **'Đơn này không có kiện nào chờ trả.'**
  String get apiErrDroneParcelReturnNotPending;

  /// No description provided for @apiErrDroneBatteryUnknown.
  ///
  /// In vi, this message translates to:
  /// **'Chưa biết mức pin của drone, hãy cập nhật pin trước khi bay.'**
  String get apiErrDroneBatteryUnknown;

  /// No description provided for @apiErrDroneSurchargeNotOwed.
  ///
  /// In vi, this message translates to:
  /// **'Đơn không còn nợ phụ thu cân lệch.'**
  String get apiErrDroneSurchargeNotOwed;

  /// No description provided for @apiErrDroneSourceNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy tủ gửi.'**
  String get apiErrDroneSourceNotFound;

  /// No description provided for @apiErrDroneDestinationNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy tủ nhận.'**
  String get apiErrDroneDestinationNotFound;

  /// No description provided for @apiErrDroneLockerInactive.
  ///
  /// In vi, this message translates to:
  /// **'Tủ gửi hoặc tủ nhận đang ngừng hoạt động.'**
  String get apiErrDroneLockerInactive;

  /// No description provided for @apiErrDroneSourceCellUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Ô drone ở tủ gửi đang có đơn khác. Vui lòng chờ đội bay nạp hàng hoặc chọn tủ khác.'**
  String get apiErrDroneSourceCellUnavailable;

  /// No description provided for @apiErrDroneSourceCellMismatch.
  ///
  /// In vi, this message translates to:
  /// **'Ô drone đã chọn không thuộc tủ gửi này.'**
  String get apiErrDroneSourceCellMismatch;

  /// No description provided for @apiErrDroneCellRequired.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ đặt giao drone được ở ô drone.'**
  String get apiErrDroneCellRequired;

  /// No description provided for @apiErrBoxNotAvailable.
  ///
  /// In vi, this message translates to:
  /// **'Ô tủ không còn trống. Vui lòng chọn ô hoặc tủ khác.'**
  String get apiErrBoxNotAvailable;

  /// No description provided for @apiErrDroneDemoNotAllowed.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản chưa được dùng chế độ mô phỏng drone.'**
  String get apiErrDroneDemoNotAllowed;

  /// No description provided for @apiErrDroneOrderUnpaid.
  ///
  /// In vi, this message translates to:
  /// **'Đơn chưa thanh toán nên chưa thể tiếp nhận.'**
  String get apiErrDroneOrderUnpaid;

  /// No description provided for @apiErrDroneOrderStatusInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Đơn không còn ở bước cho phép thao tác này.'**
  String get apiErrDroneOrderStatusInvalid;

  /// No description provided for @apiErrDroneMissionAlreadyExists.
  ///
  /// In vi, this message translates to:
  /// **'Đơn đã có điều phối viên khác tiếp nhận.'**
  String get apiErrDroneMissionAlreadyExists;

  /// No description provided for @apiErrDroneMissionStatusInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Nhiệm vụ không còn ở bước cho phép thao tác này.'**
  String get apiErrDroneMissionStatusInvalid;

  /// No description provided for @apiErrDroneMissionNotAssignedToUser.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ điều phối viên đã tiếp nhận mới thao tác được nhiệm vụ này.'**
  String get apiErrDroneMissionNotAssignedToUser;

  /// No description provided for @apiErrDroneWrongSourceLocker.
  ///
  /// In vi, this message translates to:
  /// **'Drone được chọn không đỗ tại tủ gửi của đơn.'**
  String get apiErrDroneWrongSourceLocker;

  /// No description provided for @apiErrDroneInactive.
  ///
  /// In vi, this message translates to:
  /// **'Drone đã ngừng hoạt động.'**
  String get apiErrDroneInactive;

  /// No description provided for @apiErrDroneNotIdle.
  ///
  /// In vi, this message translates to:
  /// **'Drone không còn sẵn sàng, hãy chọn drone khác.'**
  String get apiErrDroneNotIdle;

  /// No description provided for @apiErrDroneBatteryTooLow.
  ///
  /// In vi, this message translates to:
  /// **'Pin drone quá thấp để bay, cần sạc trước.'**
  String get apiErrDroneBatteryTooLow;

  /// No description provided for @apiErrDroneStatusConflict.
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái drone vừa thay đổi, hãy tải lại và thử lại.'**
  String get apiErrDroneStatusConflict;

  /// No description provided for @apiErrDroneReservationLost.
  ///
  /// In vi, this message translates to:
  /// **'Drone không còn được giữ cho nhiệm vụ này (có thể đã báo lỗi).'**
  String get apiErrDroneReservationLost;

  /// No description provided for @apiErrDronePayloadTooHeavy.
  ///
  /// In vi, this message translates to:
  /// **'Kiện hàng vượt tải trọng cho phép của drone.'**
  String get apiErrDronePayloadTooHeavy;

  /// No description provided for @apiErrDroneLoadingNotConfirmed.
  ///
  /// In vi, this message translates to:
  /// **'Cần xác nhận nạp hàng trước khi phóng.'**
  String get apiErrDroneLoadingNotConfirmed;

  /// No description provided for @apiErrDroneSurchargeUnpaid.
  ///
  /// In vi, this message translates to:
  /// **'Kiện nặng hơn khai báo. Chờ khách trả thêm phần phí chênh rồi mới phóng được.'**
  String get apiErrDroneSurchargeUnpaid;

  /// No description provided for @apiErrDroneParcelWeightInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Khối lượng kiện hàng không hợp lệ.'**
  String get apiErrDroneParcelWeightInvalid;

  /// No description provided for @apiErrDroneAlreadyInFlight.
  ///
  /// In vi, this message translates to:
  /// **'Drone đã cất cánh, không thể huỷ nhiệm vụ.'**
  String get apiErrDroneAlreadyInFlight;

  /// No description provided for @apiErrDroneCancelNoteRequired.
  ///
  /// In vi, this message translates to:
  /// **'Cần nhập ghi chú khi chọn lý do Khác.'**
  String get apiErrDroneCancelNoteRequired;

  /// No description provided for @apiErrDroneStageAutomated.
  ///
  /// In vi, this message translates to:
  /// **'Đơn mô phỏng tự chuyển chặng, không cần xác nhận tay.'**
  String get apiErrDroneStageAutomated;

  /// No description provided for @apiErrDroneReceiverPhoneInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại người nhận không hợp lệ.'**
  String get apiErrDroneReceiverPhoneInvalid;

  /// No description provided for @apiErrLockerInactive.
  ///
  /// In vi, this message translates to:
  /// **'Tủ đang ngừng hoạt động.'**
  String get apiErrLockerInactive;

  /// No description provided for @apiErrLandingPadUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Bãi đáp drone chưa sẵn sàng.'**
  String get apiErrLandingPadUnavailable;

  /// No description provided for @apiErrDroneOwnershipRequired.
  ///
  /// In vi, this message translates to:
  /// **'Bạn cần nhận phụ trách drone này trước.'**
  String get apiErrDroneOwnershipRequired;

  /// No description provided for @apiErrDroneAlreadyAssigned.
  ///
  /// In vi, this message translates to:
  /// **'Drone đã có kỹ thuật viên khác phụ trách.'**
  String get apiErrDroneAlreadyAssigned;

  /// No description provided for @apiErrDroneActiveMission.
  ///
  /// In vi, this message translates to:
  /// **'Drone đang có nhiệm vụ, chỉ được báo lỗi (FAULT).'**
  String get apiErrDroneActiveMission;

  /// No description provided for @apiErrDroneFaultReasonRequired.
  ///
  /// In vi, this message translates to:
  /// **'Cần nhập lý do khi báo drone lỗi.'**
  String get apiErrDroneFaultReasonRequired;

  /// No description provided for @apiErrDronePaymentRequiredBeforePickup.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng thanh toán đơn drone trước khi mở tủ nhận hàng.'**
  String get apiErrDronePaymentRequiredBeforePickup;

  /// No description provided for @apiErrOrderStatusInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Đơn không còn ở trạng thái cho phép thao tác này.'**
  String get apiErrOrderStatusInvalid;

  /// No description provided for @apiErrNotSupportedUpdate.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ chưa hỗ trợ chức năng này. Vui lòng cập nhật hệ thống rồi thử lại.'**
  String get apiErrNotSupportedUpdate;

  /// No description provided for @apiErrForbidden.
  ///
  /// In vi, this message translates to:
  /// **'Bạn không có quyền thực hiện thao tác này'**
  String get apiErrForbidden;

  /// No description provided for @apiErrConnection.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi kết nối máy chủ'**
  String get apiErrConnection;

  /// No description provided for @apiErrGeneric.
  ///
  /// In vi, this message translates to:
  /// **'Đã xảy ra lỗi'**
  String get apiErrGeneric;

  /// No description provided for @commonSending.
  ///
  /// In vi, this message translates to:
  /// **'Đang gửi...'**
  String get commonSending;

  /// No description provided for @commonDescription.
  ///
  /// In vi, this message translates to:
  /// **'Mô tả'**
  String get commonDescription;

  /// No description provided for @commonYes.
  ///
  /// In vi, this message translates to:
  /// **'Có'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In vi, this message translates to:
  /// **'Không'**
  String get commonNo;

  /// No description provided for @commonOrder.
  ///
  /// In vi, this message translates to:
  /// **'Đơn hàng'**
  String get commonOrder;

  /// No description provided for @commonTime.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian'**
  String get commonTime;

  /// No description provided for @commonMessage.
  ///
  /// In vi, this message translates to:
  /// **'Lời nhắn'**
  String get commonMessage;

  /// No description provided for @recvLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không đọc được chi tiết đơn. Vui lòng thử lại.'**
  String get recvLoadFailed;

  /// No description provided for @recvNotInList.
  ///
  /// In vi, this message translates to:
  /// **'Đơn không còn trong danh sách của bạn (có thể đã được ủy quyền cho người khác). Đang hiện thông tin đã lưu.'**
  String get recvNotInList;

  /// No description provided for @recvSummaryOnly.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ chưa hỗ trợ xem chi tiết đầy đủ — đang hiện thông tin tóm tắt.'**
  String get recvSummaryOnly;

  /// No description provided for @recvEmailSent.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi thông tin đơn{withCode} tới {email}.'**
  String recvEmailSent(Object withCode, Object email);

  /// No description provided for @recvWithCode.
  ///
  /// In vi, this message translates to:
  /// **' kèm mã mở tủ'**
  String get recvWithCode;

  /// No description provided for @recvYourEmail.
  ///
  /// In vi, this message translates to:
  /// **'email của bạn'**
  String get recvYourEmail;

  /// No description provided for @recvNoEmail.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có email'**
  String get recvNoEmail;

  /// No description provided for @recvNoEmailBody.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản của bạn chưa có email để nhận thông tin đơn. Bổ sung email trong Hồ sơ rồi gửi lại.'**
  String get recvNoEmailBody;

  /// No description provided for @recvAddEmail.
  ///
  /// In vi, this message translates to:
  /// **'Bổ sung email'**
  String get recvAddEmail;

  /// No description provided for @recvDelegateDetail.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết đơn lấy hộ'**
  String get recvDelegateDetail;

  /// No description provided for @recvDetail.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết đơn nhận'**
  String get recvDetail;

  /// No description provided for @recvDelegator.
  ///
  /// In vi, this message translates to:
  /// **'Người ủy quyền'**
  String get recvDelegator;

  /// No description provided for @recvSender.
  ///
  /// In vi, this message translates to:
  /// **'Người gửi'**
  String get recvSender;

  /// No description provided for @recvPickupCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã lấy hàng'**
  String get recvPickupCode;

  /// No description provided for @recvOpenBoxPickup.
  ///
  /// In vi, this message translates to:
  /// **'Mở {box} lấy hàng'**
  String recvOpenBoxPickup(Object box);

  /// No description provided for @recvTrackDrone.
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi drone'**
  String get recvTrackDrone;

  /// No description provided for @recvSendingEmail.
  ///
  /// In vi, this message translates to:
  /// **'Đang gửi email…'**
  String get recvSendingEmail;

  /// No description provided for @recvResendEmail.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại thông tin qua email'**
  String get recvResendEmail;

  /// No description provided for @recvSenderPhone.
  ///
  /// In vi, this message translates to:
  /// **'SĐT người gửi'**
  String get recvSenderPhone;

  /// No description provided for @recvSenderEmail.
  ///
  /// In vi, this message translates to:
  /// **'Email người gửi'**
  String get recvSenderEmail;

  /// No description provided for @recvRecipientName.
  ///
  /// In vi, this message translates to:
  /// **'Tên người nhận'**
  String get recvRecipientName;

  /// No description provided for @recvRecipientPhone.
  ///
  /// In vi, this message translates to:
  /// **'SĐT người nhận'**
  String get recvRecipientPhone;

  /// No description provided for @recvDelegatePerson.
  ///
  /// In vi, this message translates to:
  /// **'Người lấy hộ'**
  String get recvDelegatePerson;

  /// No description provided for @recvYouSuffix.
  ///
  /// In vi, this message translates to:
  /// **'{name} (bạn)'**
  String recvYouSuffix(Object name);

  /// No description provided for @recvYou.
  ///
  /// In vi, this message translates to:
  /// **'Bạn'**
  String get recvYou;

  /// No description provided for @recvDelegatePhone.
  ///
  /// In vi, this message translates to:
  /// **'SĐT lấy hộ'**
  String get recvDelegatePhone;

  /// No description provided for @recvDelegation.
  ///
  /// In vi, this message translates to:
  /// **'Ủy quyền'**
  String get recvDelegation;

  /// No description provided for @recvOwnerDelegated.
  ///
  /// In vi, this message translates to:
  /// **'Chủ đơn đã ủy quyền người khác lấy hộ'**
  String get recvOwnerDelegated;

  /// No description provided for @recvLockerAndBox.
  ///
  /// In vi, this message translates to:
  /// **'Tủ & ô'**
  String get recvLockerAndBox;

  /// No description provided for @recvReceivingLocker.
  ///
  /// In vi, this message translates to:
  /// **'Tủ nhận'**
  String get recvReceivingLocker;

  /// No description provided for @recvLockerCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã tủ'**
  String get recvLockerCode;

  /// No description provided for @recvBoxSize.
  ///
  /// In vi, this message translates to:
  /// **'Kích cỡ ô'**
  String get recvBoxSize;

  /// No description provided for @recvSourceAddress.
  ///
  /// In vi, this message translates to:
  /// **'Địa chỉ tủ gửi'**
  String get recvSourceAddress;

  /// No description provided for @recvSenderNote.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú người gửi'**
  String get recvSenderNote;

  /// No description provided for @recvPickupDeadline.
  ///
  /// In vi, this message translates to:
  /// **'Hạn lấy'**
  String get recvPickupDeadline;

  /// No description provided for @recvTimeLeft.
  ///
  /// In vi, this message translates to:
  /// **'Còn lại'**
  String get recvTimeLeft;

  /// No description provided for @recvExpectedPickup.
  ///
  /// In vi, this message translates to:
  /// **'Dự kiến lấy'**
  String get recvExpectedPickup;

  /// No description provided for @recvCreatedAt.
  ///
  /// In vi, this message translates to:
  /// **'Tạo đơn lúc'**
  String get recvCreatedAt;

  /// No description provided for @recvCompletedAt.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất lúc'**
  String get recvCompletedAt;

  /// No description provided for @recvUpdatedAt.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật lần cuối'**
  String get recvUpdatedAt;

  /// No description provided for @recvTimeline.
  ///
  /// In vi, this message translates to:
  /// **'Dòng thời gian'**
  String get recvTimeline;

  /// No description provided for @recvDroneJourney.
  ///
  /// In vi, this message translates to:
  /// **'Hành trình drone'**
  String get recvDroneJourney;

  /// No description provided for @recvCurrentStage.
  ///
  /// In vi, this message translates to:
  /// **'Chặng hiện tại'**
  String get recvCurrentStage;

  /// No description provided for @recvEta.
  ///
  /// In vi, this message translates to:
  /// **'Dự kiến tới tủ'**
  String get recvEta;

  /// No description provided for @recvArrived.
  ///
  /// In vi, this message translates to:
  /// **'Đã tới'**
  String get recvArrived;

  /// No description provided for @recvAboutMinutes.
  ///
  /// In vi, this message translates to:
  /// **'Khoảng {minutes} phút'**
  String recvAboutMinutes(Object minutes);

  /// No description provided for @recvIncident.
  ///
  /// In vi, this message translates to:
  /// **'Sự cố'**
  String get recvIncident;

  /// No description provided for @recvParcelReturnedToSender.
  ///
  /// In vi, this message translates to:
  /// **'Đã trả kiện cho người gửi'**
  String get recvParcelReturnedToSender;

  /// No description provided for @recvCodeMovedToDelegate.
  ///
  /// In vi, this message translates to:
  /// **'Chủ đơn đã ủy quyền người khác lấy hộ nên mã lấy hàng không còn hiện ở đây.'**
  String get recvCodeMovedToDelegate;

  /// No description provided for @recvCredCaption.
  ///
  /// In vi, this message translates to:
  /// **'Nhập PIN hoặc quét QR tại tủ, hoặc mở ô ngay trên app'**
  String get recvCredCaption;

  /// No description provided for @recvOverdueMayCharge.
  ///
  /// In vi, this message translates to:
  /// **'Đơn đã quá hạn lấy — có thể phát sinh phí quá giờ.'**
  String get recvOverdueMayCharge;

  /// No description provided for @recvCompleted.
  ///
  /// In vi, this message translates to:
  /// **'Đơn đã hoàn tất — hàng đã được lấy.'**
  String get recvCompleted;

  /// No description provided for @recvCompletedAtTime.
  ///
  /// In vi, this message translates to:
  /// **'Đơn đã hoàn tất — hàng đã được lấy lúc {time}.'**
  String recvCompletedAtTime(Object time);

  /// No description provided for @recvCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Đơn đã hủy nên không còn mã lấy hàng.'**
  String get recvCancelled;

  /// No description provided for @recvExpired.
  ///
  /// In vi, this message translates to:
  /// **'Đơn đã quá hạn lấy, ô đã được thu hồi. Vui lòng liên hệ người gửi hoặc hỗ trợ Lock.R.'**
  String get recvExpired;

  /// No description provided for @recvDroneNotReady.
  ///
  /// In vi, this message translates to:
  /// **'{stage}. Mã lấy hàng sẽ hiện khi drone đã đặt kiện vào ô tủ nhận.'**
  String recvDroneNotReady(Object stage);

  /// No description provided for @recvSenderNotDropped.
  ///
  /// In vi, this message translates to:
  /// **'Người gửi chưa bỏ hàng vào ô. Mã lấy hàng sẽ hiện khi hàng đã nằm trong ô.'**
  String get recvSenderNotDropped;

  /// No description provided for @recvNotReady.
  ///
  /// In vi, this message translates to:
  /// **'Hàng chưa sẵn sàng. Mã lấy hàng sẽ hiện khi hàng đã nằm trong ô.'**
  String get recvNotReady;

  /// No description provided for @recvSenderPaid.
  ///
  /// In vi, this message translates to:
  /// **'Người gửi đã thanh toán'**
  String get recvSenderPaid;

  /// No description provided for @recvRefundingSender.
  ///
  /// In vi, this message translates to:
  /// **'Đang hoàn tiền cho người gửi'**
  String get recvRefundingSender;

  /// No description provided for @recvSenderRefunded.
  ///
  /// In vi, this message translates to:
  /// **'Đã hoàn tiền cho người gửi'**
  String get recvSenderRefunded;

  /// No description provided for @recvSenderUnpaid.
  ///
  /// In vi, this message translates to:
  /// **'Người gửi chưa thanh toán'**
  String get recvSenderUnpaid;

  /// No description provided for @recvOrderCodeCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép mã đơn'**
  String get recvOrderCodeCopied;

  /// No description provided for @recvCopyOrderCode.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép mã đơn'**
  String get recvCopyOrderCode;

  /// No description provided for @recvYouAreDelegate.
  ///
  /// In vi, this message translates to:
  /// **'Bạn được ủy quyền lấy hộ đơn này.'**
  String get recvYouAreDelegate;

  /// No description provided for @recvYouAreRecipient.
  ///
  /// In vi, this message translates to:
  /// **'Bạn là người nhận của đơn này.'**
  String get recvYouAreRecipient;

  /// No description provided for @recvOverdueBy.
  ///
  /// In vi, this message translates to:
  /// **'Đơn đã quá hạn lấy {duration} — lấy hàng sớm để tránh phí quá giờ.'**
  String recvOverdueBy(Object duration);

  /// No description provided for @recvNoCodeYet.
  ///
  /// In vi, this message translates to:
  /// **'Đơn chưa có mã lấy hàng — hàng có thể chưa được bỏ vào ô.'**
  String get recvNoCodeYet;

  /// No description provided for @recvBoxOpenedPickup.
  ///
  /// In vi, this message translates to:
  /// **'Tủ đã mở {box} — lấy hàng rồi đóng cửa tủ lại.'**
  String recvBoxOpenedPickup(Object box);

  /// No description provided for @recvOpenByCodeNotSupported.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ chưa hỗ trợ mở ô bằng mã. Hãy nhập mã tại màn hình tủ.'**
  String get recvOpenByCodeNotSupported;

  /// No description provided for @recvLockerWithCode.
  ///
  /// In vi, this message translates to:
  /// **'Tủ {code}'**
  String recvLockerWithCode(Object code);

  /// No description provided for @recvDelegatorColon.
  ///
  /// In vi, this message translates to:
  /// **'Người ủy quyền:'**
  String get recvDelegatorColon;

  /// No description provided for @recvSenderColon.
  ///
  /// In vi, this message translates to:
  /// **'Người gửi:'**
  String get recvSenderColon;

  /// No description provided for @recvDelegatedPickup.
  ///
  /// In vi, this message translates to:
  /// **'Lấy hộ'**
  String get recvDelegatedPickup;

  /// No description provided for @recvIncomingParcel.
  ///
  /// In vi, this message translates to:
  /// **'Hàng nhận'**
  String get recvIncomingParcel;

  /// No description provided for @recvStorageBox.
  ///
  /// In vi, this message translates to:
  /// **'Ô lưu đồ'**
  String get recvStorageBox;

  /// No description provided for @recvCodeMovedShort.
  ///
  /// In vi, this message translates to:
  /// **'Chủ đơn đã ủy quyền người khác lấy hộ nên mã lấy hàng không còn hiện ở đây.'**
  String get recvCodeMovedShort;

  /// No description provided for @recvCredCaptionShort.
  ///
  /// In vi, this message translates to:
  /// **'Nhập PIN tại tủ hoặc mở ô ngay trên app'**
  String get recvCredCaptionShort;

  /// No description provided for @recvReceived.
  ///
  /// In vi, this message translates to:
  /// **'Đã nhận hàng'**
  String get recvReceived;

  /// No description provided for @recvDelegated.
  ///
  /// In vi, this message translates to:
  /// **'Đã ủy quyền lấy hộ'**
  String get recvDelegated;

  /// No description provided for @recvOverdueHurry.
  ///
  /// In vi, this message translates to:
  /// **'Đơn đã quá hạn lấy — hãy lấy hàng sớm để tránh phát sinh thêm phí.'**
  String get recvOverdueHurry;

  /// No description provided for @recvCodeTransferred.
  ///
  /// In vi, this message translates to:
  /// **'Chủ đơn đã ủy quyền người khác lấy hộ — mã lấy hàng đã chuyển sang người lấy hộ.'**
  String get recvCodeTransferred;

  /// No description provided for @detailCantCall.
  ///
  /// In vi, this message translates to:
  /// **'Máy này không gọi điện được.'**
  String get detailCantCall;

  /// No description provided for @detailCopiedLabel.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép {label}'**
  String detailCopiedLabel(Object label);

  /// No description provided for @detailCallLabel.
  ///
  /// In vi, this message translates to:
  /// **'Gọi {label}'**
  String detailCallLabel(Object label);

  /// No description provided for @detailCopyLabel.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép {label}'**
  String detailCopyLabel(Object label);

  /// No description provided for @parcelCategory.
  ///
  /// In vi, this message translates to:
  /// **'Loại hàng'**
  String get parcelCategory;

  /// No description provided for @parcelWeight.
  ///
  /// In vi, this message translates to:
  /// **'Cân nặng'**
  String get parcelWeight;

  /// No description provided for @parcelSize.
  ///
  /// In vi, this message translates to:
  /// **'Kích thước'**
  String get parcelSize;

  /// No description provided for @parcelFragile.
  ///
  /// In vi, this message translates to:
  /// **'Hàng dễ vỡ'**
  String get parcelFragile;

  /// No description provided for @parcelFragileYes.
  ///
  /// In vi, this message translates to:
  /// **'Có — nhẹ tay'**
  String get parcelFragileYes;

  /// No description provided for @parcelDeclaredValue.
  ///
  /// In vi, this message translates to:
  /// **'Giá trị khai báo'**
  String get parcelDeclaredValue;

  /// No description provided for @parcelNoProhibited.
  ///
  /// In vi, this message translates to:
  /// **'Cam kết không hàng cấm'**
  String get parcelNoProhibited;

  /// No description provided for @delegateTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ủy quyền lấy hộ'**
  String get delegateTitle;

  /// No description provided for @delegateBody.
  ///
  /// In vi, this message translates to:
  /// **'Người được ủy quyền thấy đơn và mã mở ô trong mục \"Đơn ủy quyền\" của app (theo số điện thoại). Mã PIN hiện tại sẽ được đổi mới.'**
  String get delegateBody;

  /// No description provided for @delegatePhone.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại người lấy hộ'**
  String get delegatePhone;

  /// No description provided for @delegateName.
  ///
  /// In vi, this message translates to:
  /// **'Tên người lấy hộ (không bắt buộc)'**
  String get delegateName;

  /// No description provided for @delegateMessage.
  ///
  /// In vi, this message translates to:
  /// **'Lời nhắn (không bắt buộc)'**
  String get delegateMessage;

  /// No description provided for @delegateInvalidPhone.
  ///
  /// In vi, this message translates to:
  /// **'Nhập số điện thoại hợp lệ (9–11 số).'**
  String get delegateInvalidPhone;

  /// No description provided for @delegateNotSupported.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ chưa hỗ trợ ủy quyền lấy hộ.'**
  String get delegateNotSupported;

  /// No description provided for @delegateAction.
  ///
  /// In vi, this message translates to:
  /// **'Ủy quyền'**
  String get delegateAction;

  /// No description provided for @shareCopiedMessage.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép tin nhắn, dán vào Zalo, Messenger hoặc SMS để gửi cho người nhận.'**
  String get shareCopiedMessage;

  /// No description provided for @shareCantOpenSheet.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được bảng chia sẻ'**
  String get shareCantOpenSheet;

  /// No description provided for @shareCantOpenSms.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được ứng dụng tin nhắn'**
  String get shareCantOpenSms;

  /// No description provided for @shareTheRecipient.
  ///
  /// In vi, this message translates to:
  /// **'người nhận'**
  String get shareTheRecipient;

  /// No description provided for @shareTitle.
  ///
  /// In vi, this message translates to:
  /// **'Gửi mã cho người nhận'**
  String get shareTitle;

  /// No description provided for @shareBody.
  ///
  /// In vi, this message translates to:
  /// **'Người nhận nhập mã tại màn hình tủ để mở ô. Gửi tin nhắn soạn sẵn cho {who} qua Zalo, Messenger hoặc SMS.'**
  String shareBody(Object who);

  /// No description provided for @shareButton.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ mã cho người nhận'**
  String get shareButton;

  /// No description provided for @shareSms.
  ///
  /// In vi, this message translates to:
  /// **'Nhắn SMS'**
  String get shareSms;

  /// No description provided for @shareCopyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép tin nhắn'**
  String get shareCopyMessage;

  /// No description provided for @shareMsgLocker.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có kiện hàng gửi tới tủ {where}.'**
  String shareMsgLocker(Object where);

  /// No description provided for @shareMsgDrone.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có kiện hàng giao bằng drone đang chờ tại tủ {where}.'**
  String shareMsgDrone(Object where);

  /// No description provided for @shareMsgBox.
  ///
  /// In vi, this message translates to:
  /// **'Ô số {number}.'**
  String shareMsgBox(Object number);

  /// No description provided for @shareMsgCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã lấy hàng: {code}.'**
  String shareMsgCode(Object code);

  /// No description provided for @shareMsgDeadline.
  ///
  /// In vi, this message translates to:
  /// **'Hạn lấy: {deadline}.'**
  String shareMsgDeadline(Object deadline);

  /// No description provided for @shareMsgHowTo.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã tại màn hình tủ (kiosk) để mở ô.'**
  String get shareMsgHowTo;

  /// No description provided for @timelineTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử trạng thái'**
  String get timelineTitle;

  /// No description provided for @timelineLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được lịch sử trạng thái.'**
  String get timelineLoadFailed;

  /// No description provided for @timelineEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có chuyển trạng thái nào.'**
  String get timelineEmpty;

  /// No description provided for @timelineFrom.
  ///
  /// In vi, this message translates to:
  /// **'Từ {status}'**
  String timelineFrom(Object status);

  /// No description provided for @pickerNoLockers.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có tủ khả dụng'**
  String get pickerNoLockers;

  /// No description provided for @pickerTapToChange.
  ///
  /// In vi, this message translates to:
  /// **'Chạm để chọn tủ khác'**
  String get pickerTapToChange;

  /// No description provided for @pickerUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Tạm không khả dụng: {reason}'**
  String pickerUnavailable(Object reason);

  /// No description provided for @payTransferAmount.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán chuyển khoản · {amount}'**
  String payTransferAmount(Object amount);

  /// No description provided for @payScanAnyBank.
  ///
  /// In vi, this message translates to:
  /// **'Quét mã bằng app ngân hàng bất kỳ hoặc mở thẳng app ngân hàng.'**
  String get payScanAnyBank;

  /// No description provided for @svcRentSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Thuê ô theo giờ, PIN dùng nhiều lần'**
  String get svcRentSubtitle;

  /// No description provided for @svcSendSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ hàng vào ô, gửi PIN cho người nhận'**
  String get svcSendSubtitle;

  /// No description provided for @qrEnterLockerCode.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập mã tủ.'**
  String get qrEnterLockerCode;

  /// No description provided for @qrThisLocker.
  ///
  /// In vi, this message translates to:
  /// **'tủ này'**
  String get qrThisLocker;

  /// No description provided for @qrLockerCodeMismatch.
  ///
  /// In vi, this message translates to:
  /// **'Mã tủ không khớp với {locker}.'**
  String qrLockerCodeMismatch(Object locker);

  /// No description provided for @qrEnterLockerCodeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã tủ'**
  String get qrEnterLockerCodeTitle;

  /// No description provided for @qrLockerCodeHint.
  ///
  /// In vi, this message translates to:
  /// **'Mã in trên thân tủ'**
  String get qrLockerCodeHint;

  /// No description provided for @qrCodeMismatch.
  ///
  /// In vi, this message translates to:
  /// **'Mã QR không khớp với {locker}.\nVui lòng quét đúng mã QR dán trên thân tủ.'**
  String qrCodeMismatch(Object locker);

  /// No description provided for @qrLockerBoxGeneric.
  ///
  /// In vi, this message translates to:
  /// **'ô tủ'**
  String get qrLockerBoxGeneric;

  /// No description provided for @qrScanToOpen.
  ///
  /// In vi, this message translates to:
  /// **'Quét mở {box}'**
  String qrScanToOpen(Object box);

  /// No description provided for @qrLockerCodeValue.
  ///
  /// In vi, this message translates to:
  /// **'Mã tủ: {code}'**
  String qrLockerCodeValue(Object code);

  /// No description provided for @qrPointCamera.
  ///
  /// In vi, this message translates to:
  /// **'Hướng camera về phía tem mã QR dán trên mặt tủ để xác thực bạn đang đứng tại tủ.'**
  String get qrPointCamera;

  /// No description provided for @qrCantScan.
  ///
  /// In vi, this message translates to:
  /// **'Không quét được? Nhập mã tủ'**
  String get qrCantScan;

  /// No description provided for @secondsValue.
  ///
  /// In vi, this message translates to:
  /// **'{seconds} giây'**
  String secondsValue(Object seconds);

  /// No description provided for @durDays.
  ///
  /// In vi, this message translates to:
  /// **'{days} ngày'**
  String durDays(int days);

  /// No description provided for @durDaysHoursLong.
  ///
  /// In vi, this message translates to:
  /// **'{days} ngày {hours} giờ'**
  String durDaysHoursLong(Object days, Object hours);

  /// No description provided for @durHours.
  ///
  /// In vi, this message translates to:
  /// **'{hours} giờ'**
  String durHours(int hours);

  /// No description provided for @durHoursMinutesLong.
  ///
  /// In vi, this message translates to:
  /// **'{hours} giờ {minutes} phút'**
  String durHoursMinutesLong(Object hours, Object minutes);

  /// No description provided for @durMinutesSeconds.
  ///
  /// In vi, this message translates to:
  /// **'{minutes} phút {seconds} giây'**
  String durMinutesSeconds(Object minutes, Object seconds);

  /// No description provided for @incStReported.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi nhận'**
  String get incStReported;

  /// No description provided for @incStEvidencePending.
  ///
  /// In vi, this message translates to:
  /// **'Đang thu thập bằng chứng'**
  String get incStEvidencePending;

  /// No description provided for @incStInvestigating.
  ///
  /// In vi, this message translates to:
  /// **'Đang điều tra'**
  String get incStInvestigating;

  /// No description provided for @incStRecoveryInProgress.
  ///
  /// In vi, this message translates to:
  /// **'Đang thu hồi kiện'**
  String get incStRecoveryInProgress;

  /// No description provided for @incStAwaitingAdmin.
  ///
  /// In vi, this message translates to:
  /// **'Chờ quản trị viên xem xét'**
  String get incStAwaitingAdmin;

  /// No description provided for @incStResolutionProposed.
  ///
  /// In vi, this message translates to:
  /// **'Đã có phương án xử lý'**
  String get incStResolutionProposed;

  /// No description provided for @incStAwaitingCustomer.
  ///
  /// In vi, this message translates to:
  /// **'Chờ bạn phản hồi phương án'**
  String get incStAwaitingCustomer;

  /// No description provided for @incStResolutionInProgress.
  ///
  /// In vi, this message translates to:
  /// **'Đang thực hiện phương án'**
  String get incStResolutionInProgress;

  /// No description provided for @incStDisputed.
  ///
  /// In vi, this message translates to:
  /// **'Đang xem xét lại theo yêu cầu'**
  String get incStDisputed;

  /// No description provided for @incStResolved.
  ///
  /// In vi, this message translates to:
  /// **'Đã xử lý xong'**
  String get incStResolved;

  /// No description provided for @incStClosed.
  ///
  /// In vi, this message translates to:
  /// **'Đã đóng'**
  String get incStClosed;

  /// No description provided for @incStManual.
  ///
  /// In vi, this message translates to:
  /// **'Nhân viên đang xử lý trực tiếp'**
  String get incStManual;

  /// No description provided for @recStOpen.
  ///
  /// In vi, this message translates to:
  /// **'Mới mở'**
  String get recStOpen;

  /// No description provided for @recStAwaitingAssignment.
  ///
  /// In vi, this message translates to:
  /// **'Chờ phân công người thu hồi'**
  String get recStAwaitingAssignment;

  /// No description provided for @recStAssigned.
  ///
  /// In vi, this message translates to:
  /// **'Đã phân công'**
  String get recStAssigned;

  /// No description provided for @recStAccepted.
  ///
  /// In vi, this message translates to:
  /// **'Nhân viên đã nhận việc'**
  String get recStAccepted;

  /// No description provided for @recStSearching.
  ///
  /// In vi, this message translates to:
  /// **'Đang tìm kiện'**
  String get recStSearching;

  /// No description provided for @recStFound.
  ///
  /// In vi, this message translates to:
  /// **'Đã tìm thấy kiện'**
  String get recStFound;

  /// No description provided for @recStNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tìm thấy kiện'**
  String get recStNotFound;

  /// No description provided for @recStRecovered.
  ///
  /// In vi, this message translates to:
  /// **'Đã thu hồi kiện'**
  String get recStRecovered;

  /// No description provided for @recStSubmitted.
  ///
  /// In vi, this message translates to:
  /// **'Đã báo kết quả thu hồi'**
  String get recStSubmitted;

  /// No description provided for @recStVerified.
  ///
  /// In vi, this message translates to:
  /// **'Đã xác minh kết quả'**
  String get recStVerified;

  /// No description provided for @recStClosed.
  ///
  /// In vi, this message translates to:
  /// **'Đã bàn giao kiện về kho'**
  String get recStClosed;

  /// No description provided for @recStCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Đã huỷ'**
  String get recStCancelled;

  /// No description provided for @parStInTransit.
  ///
  /// In vi, this message translates to:
  /// **'Đang vận chuyển'**
  String get parStInTransit;

  /// No description provided for @parStDropReported.
  ///
  /// In vi, this message translates to:
  /// **'Đã báo rơi'**
  String get parStDropReported;

  /// No description provided for @parStRecoveryPending.
  ///
  /// In vi, this message translates to:
  /// **'Chờ thu hồi'**
  String get parStRecoveryPending;

  /// No description provided for @parStFound.
  ///
  /// In vi, this message translates to:
  /// **'Đã tìm thấy'**
  String get parStFound;

  /// No description provided for @parStRecovered.
  ///
  /// In vi, this message translates to:
  /// **'Đã thu hồi'**
  String get parStRecovered;

  /// No description provided for @parStDamaged.
  ///
  /// In vi, this message translates to:
  /// **'Bị hư hỏng'**
  String get parStDamaged;

  /// No description provided for @parStLost.
  ///
  /// In vi, this message translates to:
  /// **'Thất lạc'**
  String get parStLost;

  /// No description provided for @parStReturnedToHub.
  ///
  /// In vi, this message translates to:
  /// **'Đã về kho Lock.R'**
  String get parStReturnedToHub;

  /// No description provided for @parStRedeliveryPending.
  ///
  /// In vi, this message translates to:
  /// **'Chờ giao lại'**
  String get parStRedeliveryPending;

  /// No description provided for @parStRedelivered.
  ///
  /// In vi, this message translates to:
  /// **'Đã giao lại'**
  String get parStRedelivered;

  /// No description provided for @parStCompensated.
  ///
  /// In vi, this message translates to:
  /// **'Đã bồi thường'**
  String get parStCompensated;

  /// No description provided for @incEvReported.
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhận kiện rơi khỏi drone'**
  String get incEvReported;

  /// No description provided for @incEvRecoveryAssigned.
  ///
  /// In vi, this message translates to:
  /// **'Phân công người thu hồi kiện'**
  String get incEvRecoveryAssigned;

  /// No description provided for @incEvRecoveryAccept.
  ///
  /// In vi, this message translates to:
  /// **'Nhân viên nhận việc thu hồi'**
  String get incEvRecoveryAccept;

  /// No description provided for @incEvRecoverySearching.
  ///
  /// In vi, this message translates to:
  /// **'Nhân viên bắt đầu tìm kiện'**
  String get incEvRecoverySearching;

  /// No description provided for @incEvReturnFlightConfirmed.
  ///
  /// In vi, this message translates to:
  /// **'Drone đã về trạm'**
  String get incEvReturnFlightConfirmed;

  /// No description provided for @incEvRecoverySubmitted.
  ///
  /// In vi, this message translates to:
  /// **'Báo kết quả thu hồi'**
  String get incEvRecoverySubmitted;

  /// No description provided for @incEvRecoveryVerified.
  ///
  /// In vi, this message translates to:
  /// **'Xác minh kết quả thu hồi'**
  String get incEvRecoveryVerified;

  /// No description provided for @incEvStationDispatched.
  ///
  /// In vi, this message translates to:
  /// **'Kiện được điều phối về trạm bay để giao lại'**
  String get incEvStationDispatched;

  /// No description provided for @incEvStationUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Đang điều phối trạm nhận kiện'**
  String get incEvStationUnavailable;

  /// No description provided for @incEvReturnedToHub.
  ///
  /// In vi, this message translates to:
  /// **'Kiện đã về kho Lock.R'**
  String get incEvReturnedToHub;

  /// No description provided for @incEvResolutionProposed.
  ///
  /// In vi, this message translates to:
  /// **'Lock.R đề xuất phương án'**
  String get incEvResolutionProposed;

  /// No description provided for @incEvCustomerAccept.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đồng ý phương án'**
  String get incEvCustomerAccept;

  /// No description provided for @incEvCustomerReview.
  ///
  /// In vi, this message translates to:
  /// **'Bạn yêu cầu xem xét lại'**
  String get incEvCustomerReview;

  /// No description provided for @incEvReturnFlightUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật chuyến bay về trạm'**
  String get incEvReturnFlightUpdated;

  /// No description provided for @incEvRedeliveryRequested.
  ///
  /// In vi, this message translates to:
  /// **'Đã tạo đơn giao lại'**
  String get incEvRedeliveryRequested;

  /// No description provided for @incEvRedeliveryUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tạo được đơn giao lại — nhân viên sẽ liên hệ'**
  String get incEvRedeliveryUnavailable;

  /// No description provided for @incEvRedeliveryCompleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã giao lại thành công'**
  String get incEvRedeliveryCompleted;

  /// No description provided for @incEvCompensationSubmitted.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi yêu cầu chi bồi thường'**
  String get incEvCompensationSubmitted;

  /// No description provided for @incEvCompensationPaid.
  ///
  /// In vi, this message translates to:
  /// **'Đã chi bồi thường'**
  String get incEvCompensationPaid;

  /// No description provided for @incEvCompensationFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chi bồi thường chưa thành công'**
  String get incEvCompensationFailed;

  /// No description provided for @incEvResolved.
  ///
  /// In vi, this message translates to:
  /// **'Đã hoàn tất xử lý sự cố'**
  String get incEvResolved;

  /// No description provided for @resFreeRedelivery.
  ///
  /// In vi, this message translates to:
  /// **'Giao lại miễn phí'**
  String get resFreeRedelivery;

  /// No description provided for @resRedeliveryPartial.
  ///
  /// In vi, this message translates to:
  /// **'Giao lại kèm bồi thường một phần'**
  String get resRedeliveryPartial;

  /// No description provided for @resCompensationOnly.
  ///
  /// In vi, this message translates to:
  /// **'Bồi thường'**
  String get resCompensationOnly;

  /// No description provided for @resManual.
  ///
  /// In vi, this message translates to:
  /// **'Thỏa thuận riêng'**
  String get resManual;

  /// No description provided for @condIntact.
  ///
  /// In vi, this message translates to:
  /// **'còn nguyên vẹn'**
  String get condIntact;

  /// No description provided for @condMinor.
  ///
  /// In vi, this message translates to:
  /// **'hư hại nhẹ'**
  String get condMinor;

  /// No description provided for @condMajor.
  ///
  /// In vi, this message translates to:
  /// **'hư hại nặng'**
  String get condMajor;

  /// No description provided for @condUnusable.
  ///
  /// In vi, this message translates to:
  /// **'không thể sử dụng'**
  String get condUnusable;

  /// No description provided for @propAwaiting.
  ///
  /// In vi, this message translates to:
  /// **'Chờ bạn phản hồi'**
  String get propAwaiting;

  /// No description provided for @propAccepted.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã đồng ý'**
  String get propAccepted;

  /// No description provided for @propDisputed.
  ///
  /// In vi, this message translates to:
  /// **'Đã yêu cầu xem xét lại'**
  String get propDisputed;

  /// No description provided for @propSuperseded.
  ///
  /// In vi, this message translates to:
  /// **'Đã thay bằng phương án mới'**
  String get propSuperseded;

  /// No description provided for @incEvRecoveryUpdate.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật thu hồi kiện'**
  String get incEvRecoveryUpdate;

  /// No description provided for @incEvCompensationUpdate.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật bồi thường'**
  String get incEvCompensationUpdate;

  /// No description provided for @incEvRedeliveryUpdate.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật giao lại'**
  String get incEvRedeliveryUpdate;

  /// No description provided for @msNotInit.
  ///
  /// In vi, this message translates to:
  /// **'Chưa khởi tạo'**
  String get msNotInit;

  /// No description provided for @msAwaitingLoading.
  ///
  /// In vi, this message translates to:
  /// **'Chờ nạp hàng'**
  String get msAwaitingLoading;

  /// No description provided for @msReadyToLaunch.
  ///
  /// In vi, this message translates to:
  /// **'Sẵn sàng phóng'**
  String get msReadyToLaunch;

  /// No description provided for @msLaunching.
  ///
  /// In vi, this message translates to:
  /// **'Đang khởi phóng'**
  String get msLaunching;

  /// No description provided for @msDeparted.
  ///
  /// In vi, this message translates to:
  /// **'Đã rời trạm'**
  String get msDeparted;

  /// No description provided for @msEnRoute.
  ///
  /// In vi, this message translates to:
  /// **'Đang bay'**
  String get msEnRoute;

  /// No description provided for @msApproaching.
  ///
  /// In vi, this message translates to:
  /// **'Sắp tới tủ nhận'**
  String get msApproaching;

  /// No description provided for @msArrived.
  ///
  /// In vi, this message translates to:
  /// **'Đã tới tủ nhận'**
  String get msArrived;

  /// No description provided for @msDeposited.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi hàng vào ô'**
  String get msDeposited;

  /// No description provided for @msFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chuyến bay thất bại'**
  String get msFailed;

  /// No description provided for @msDropReported.
  ///
  /// In vi, this message translates to:
  /// **'Dừng do sự cố rơi kiện'**
  String get msDropReported;

  /// No description provided for @dosAwaitingDispatch.
  ///
  /// In vi, this message translates to:
  /// **'Đang giao bằng drone'**
  String get dosAwaitingDispatch;

  /// No description provided for @dosStoring.
  ///
  /// In vi, this message translates to:
  /// **'Hàng đang trong tủ nhận'**
  String get dosStoring;

  /// No description provided for @dosExpired.
  ///
  /// In vi, this message translates to:
  /// **'Quá hạn nhận'**
  String get dosExpired;

  /// No description provided for @cancelWeather.
  ///
  /// In vi, this message translates to:
  /// **'Thời tiết xấu'**
  String get cancelWeather;

  /// No description provided for @cancelDroneFault.
  ///
  /// In vi, this message translates to:
  /// **'Drone lỗi'**
  String get cancelDroneFault;

  /// No description provided for @cancelPadNotReady.
  ///
  /// In vi, this message translates to:
  /// **'Bãi đáp không sẵn sàng'**
  String get cancelPadNotReady;

  /// No description provided for @cancelOperational.
  ///
  /// In vi, this message translates to:
  /// **'Lý do vận hành'**
  String get cancelOperational;

  /// No description provided for @cancelOther.
  ///
  /// In vi, this message translates to:
  /// **'Lý do khác'**
  String get cancelOther;

  /// No description provided for @cancelReasonCode.
  ///
  /// In vi, this message translates to:
  /// **'Lý do #{code}'**
  String cancelReasonCode(Object code);

  /// No description provided for @modeDemo.
  ///
  /// In vi, this message translates to:
  /// **'Mô phỏng (DEMO)'**
  String get modeDemo;

  /// No description provided for @modeStandard.
  ///
  /// In vi, this message translates to:
  /// **'Drone thật'**
  String get modeStandard;

  /// No description provided for @stgTitleAwaitingTech.
  ///
  /// In vi, this message translates to:
  /// **'Chờ kỹ thuật viên nhận lấy hàng'**
  String get stgTitleAwaitingTech;

  /// No description provided for @stgTitleTechOnWay.
  ///
  /// In vi, this message translates to:
  /// **'Kỹ thuật viên đang tới lấy hàng'**
  String get stgTitleTechOnWay;

  /// No description provided for @stgTitlePickedUp.
  ///
  /// In vi, this message translates to:
  /// **'Đã lấy hàng, đang mang tới drone'**
  String get stgTitlePickedUp;

  /// No description provided for @stgTitleLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang nạp hàng lên drone'**
  String get stgTitleLoading;

  /// No description provided for @stgTitleLaunching.
  ///
  /// In vi, this message translates to:
  /// **'Drone đang khởi phóng'**
  String get stgTitleLaunching;

  /// No description provided for @stgTitleDeparted.
  ///
  /// In vi, this message translates to:
  /// **'Drone đã rời trạm'**
  String get stgTitleDeparted;

  /// No description provided for @stgTitleEnRoute.
  ///
  /// In vi, this message translates to:
  /// **'Drone đang trên đường'**
  String get stgTitleEnRoute;

  /// No description provided for @stgTitleApproaching.
  ///
  /// In vi, this message translates to:
  /// **'Drone sắp đến'**
  String get stgTitleApproaching;

  /// No description provided for @stgTitleArrived.
  ///
  /// In vi, this message translates to:
  /// **'Drone đã đến tủ'**
  String get stgTitleArrived;

  /// No description provided for @stgTitleReady.
  ///
  /// In vi, this message translates to:
  /// **'Sẵn sàng nhận hàng'**
  String get stgTitleReady;

  /// No description provided for @stgTitleDelayed.
  ///
  /// In vi, this message translates to:
  /// **'Đơn hàng bị chậm'**
  String get stgTitleDelayed;

  /// No description provided for @stgTitleFailed.
  ///
  /// In vi, this message translates to:
  /// **'Giao không hoàn tất'**
  String get stgTitleFailed;

  /// No description provided for @stgTitleDrop.
  ///
  /// In vi, this message translates to:
  /// **'Kiện hàng gặp sự cố rơi'**
  String get stgTitleDrop;

  /// No description provided for @stgTitleCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Đơn drone đã huỷ'**
  String get stgTitleCancelled;

  /// No description provided for @stgTitleReceived.
  ///
  /// In vi, this message translates to:
  /// **'Đã nhận hàng'**
  String get stgTitleReceived;

  /// No description provided for @stgTitleExpired.
  ///
  /// In vi, this message translates to:
  /// **'Quá hạn nhận hàng'**
  String get stgTitleExpired;

  /// No description provided for @stgTitleUpdate.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật đơn hàng'**
  String get stgTitleUpdate;

  /// No description provided for @stgDescAwaitingTech.
  ///
  /// In vi, this message translates to:
  /// **'Sau khi thanh toán, hệ thống tìm kỹ thuật viên drone rảnh gần bạn nhất'**
  String get stgDescAwaitingTech;

  /// No description provided for @stgDescTechOnWay.
  ///
  /// In vi, this message translates to:
  /// **'Kỹ thuật viên đang tới điểm lấy hàng, chuẩn bị kiện và mã lấy hàng'**
  String get stgDescTechOnWay;

  /// No description provided for @stgDescPickedUp.
  ///
  /// In vi, this message translates to:
  /// **'Kiện đang được mang tới drone để nạp trực tiếp; không bỏ vào ô tủ bay'**
  String get stgDescPickedUp;

  /// No description provided for @stgDescLoading.
  ///
  /// In vi, this message translates to:
  /// **'Drone đã được gán, kỹ thuật viên đang cân và nạp kiện'**
  String get stgDescLoading;

  /// No description provided for @stgDescLaunching.
  ///
  /// In vi, this message translates to:
  /// **'Đội bay đang thực hiện quy trình khởi phóng'**
  String get stgDescLaunching;

  /// No description provided for @stgDescDeparted.
  ///
  /// In vi, this message translates to:
  /// **'Drone đã cất cánh khỏi trạm nguồn'**
  String get stgDescDeparted;

  /// No description provided for @stgDescEnRoute.
  ///
  /// In vi, this message translates to:
  /// **'Drone đang bay tới tủ nhận'**
  String get stgDescEnRoute;

  /// No description provided for @stgDescEnRouteEta.
  ///
  /// In vi, this message translates to:
  /// **'Drone dự kiến đến trong {eta}'**
  String stgDescEnRouteEta(Object eta);

  /// No description provided for @stgDescApproaching.
  ///
  /// In vi, this message translates to:
  /// **'Drone đang tiếp cận tủ nhận của bạn'**
  String get stgDescApproaching;

  /// No description provided for @stgDescArrived.
  ///
  /// In vi, this message translates to:
  /// **'Drone đã đến và đang gửi kiện hàng vào tủ'**
  String get stgDescArrived;

  /// No description provided for @stgDescReady.
  ///
  /// In vi, this message translates to:
  /// **'Kiện hàng đã nằm trong tủ nhận, dùng mã PIN/QR của đơn để mở ô'**
  String get stgDescReady;

  /// No description provided for @stgDescDelayed.
  ///
  /// In vi, this message translates to:
  /// **'Đơn đang bị chậm so với dự kiến'**
  String get stgDescDelayed;

  /// No description provided for @stgDescDelayedEta.
  ///
  /// In vi, this message translates to:
  /// **'Đơn đang bị chậm, dự kiến tới {eta}'**
  String stgDescDelayedEta(Object eta);

  /// No description provided for @stgDescFailed.
  ///
  /// In vi, this message translates to:
  /// **'Đơn giao không hoàn tất'**
  String get stgDescFailed;

  /// No description provided for @stgDescDrop.
  ///
  /// In vi, this message translates to:
  /// **'Kiện được báo rơi khỏi drone trong chuyến bay. Tiến trình thu hồi và phương án xử lý xem ở thẻ sự cố của đơn.'**
  String get stgDescDrop;

  /// No description provided for @stgDescCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Đơn đã dừng trước khi drone cất cánh'**
  String get stgDescCancelled;

  /// No description provided for @stgDescReceived.
  ///
  /// In vi, this message translates to:
  /// **'Người nhận đã lấy kiện hàng khỏi tủ'**
  String get stgDescReceived;

  /// No description provided for @stgDescExpired.
  ///
  /// In vi, this message translates to:
  /// **'Đã quá hạn nhận hàng, vui lòng liên hệ hỗ trợ'**
  String get stgDescExpired;

  /// No description provided for @stgDescUpdate.
  ///
  /// In vi, this message translates to:
  /// **'Đơn hàng của bạn có cập nhật mới'**
  String get stgDescUpdate;

  /// No description provided for @droneNoWeatherData.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có dữ liệu thời tiết.'**
  String get droneNoWeatherData;

  /// No description provided for @failWeather.
  ///
  /// In vi, this message translates to:
  /// **'Tạm dừng bay do thời tiết hoặc lệnh điều hành'**
  String get failWeather;

  /// No description provided for @failWeatherUnsafe.
  ///
  /// In vi, this message translates to:
  /// **'Thời tiết tuyến bay không an toàn'**
  String get failWeatherUnsafe;

  /// No description provided for @failStationSuspended.
  ///
  /// In vi, this message translates to:
  /// **'Trạm bay đang tạm dừng'**
  String get failStationSuspended;

  /// No description provided for @failDroneFault.
  ///
  /// In vi, this message translates to:
  /// **'Drone gặp sự cố'**
  String get failDroneFault;

  /// No description provided for @failNoDrone.
  ///
  /// In vi, this message translates to:
  /// **'Tủ gửi không còn drone sẵn sàng'**
  String get failNoDrone;

  /// No description provided for @failSourceLocker.
  ///
  /// In vi, this message translates to:
  /// **'Tủ gửi gặp sự cố'**
  String get failSourceLocker;

  /// No description provided for @failDestinationLocker.
  ///
  /// In vi, this message translates to:
  /// **'Tủ nhận gặp sự cố'**
  String get failDestinationLocker;

  /// No description provided for @failLandingPad.
  ///
  /// In vi, this message translates to:
  /// **'Bãi đáp drone không sẵn sàng'**
  String get failLandingPad;

  /// No description provided for @failNoTechnician.
  ///
  /// In vi, this message translates to:
  /// **'Không có kỹ thuật viên nhận lấy hàng'**
  String get failNoTechnician;

  /// No description provided for @failLaunchOverdue.
  ///
  /// In vi, this message translates to:
  /// **'Quá hạn phóng drone sau khi lấy hàng'**
  String get failLaunchOverdue;

  /// No description provided for @failCustomerAbsent.
  ///
  /// In vi, this message translates to:
  /// **'Không gặp được người gửi tại điểm lấy hàng'**
  String get failCustomerAbsent;

  /// No description provided for @failParcelRejected.
  ///
  /// In vi, this message translates to:
  /// **'Kiện hàng không đúng khai báo'**
  String get failParcelRejected;

  /// No description provided for @failAddressNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy địa chỉ lấy hàng'**
  String get failAddressNotFound;

  /// No description provided for @failFlightIncident.
  ///
  /// In vi, this message translates to:
  /// **'Sự cố trong lúc bay'**
  String get failFlightIncident;

  /// No description provided for @failShortCustomerAbsent.
  ///
  /// In vi, this message translates to:
  /// **'Không gặp được người gửi'**
  String get failShortCustomerAbsent;

  /// No description provided for @failShortParcelRejected.
  ///
  /// In vi, this message translates to:
  /// **'Kiện không đúng khai báo'**
  String get failShortParcelRejected;

  /// No description provided for @failShortAddressNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy địa chỉ'**
  String get failShortAddressNotFound;

  /// No description provided for @failShortNoDrone.
  ///
  /// In vi, this message translates to:
  /// **'Không còn drone'**
  String get failShortNoDrone;

  /// No description provided for @failShortSourceLocker.
  ///
  /// In vi, this message translates to:
  /// **'Tủ gửi lỗi'**
  String get failShortSourceLocker;

  /// No description provided for @failShortDestinationLocker.
  ///
  /// In vi, this message translates to:
  /// **'Tủ nhận lỗi'**
  String get failShortDestinationLocker;

  /// No description provided for @failShortFlightIncident.
  ///
  /// In vi, this message translates to:
  /// **'Sự cố lúc bay'**
  String get failShortFlightIncident;

  /// No description provided for @catDocument.
  ///
  /// In vi, this message translates to:
  /// **'Tài liệu'**
  String get catDocument;

  /// No description provided for @catFood.
  ///
  /// In vi, this message translates to:
  /// **'Đồ ăn'**
  String get catFood;

  /// No description provided for @catClothing.
  ///
  /// In vi, this message translates to:
  /// **'Quần áo'**
  String get catClothing;

  /// No description provided for @catElectronics.
  ///
  /// In vi, this message translates to:
  /// **'Điện tử'**
  String get catElectronics;

  /// No description provided for @catCosmetics.
  ///
  /// In vi, this message translates to:
  /// **'Mỹ phẩm'**
  String get catCosmetics;

  /// No description provided for @heldSourceBox.
  ///
  /// In vi, this message translates to:
  /// **'Còn trong ô gửi'**
  String get heldSourceBox;

  /// No description provided for @heldFlightTeam.
  ///
  /// In vi, this message translates to:
  /// **'Đội bay đang giữ'**
  String get heldFlightTeam;

  /// No description provided for @blockDisconnected.
  ///
  /// In vi, this message translates to:
  /// **'mất kết nối'**
  String get blockDisconnected;

  /// No description provided for @blockMaintenance.
  ///
  /// In vi, this message translates to:
  /// **'đang bảo trì'**
  String get blockMaintenance;

  /// No description provided for @blockSuspended.
  ///
  /// In vi, this message translates to:
  /// **'tạm ngưng'**
  String get blockSuspended;

  /// No description provided for @blockNoPad.
  ///
  /// In vi, this message translates to:
  /// **'chưa có bãi đáp drone'**
  String get blockNoPad;

  /// No description provided for @blockPadMaintenance.
  ///
  /// In vi, this message translates to:
  /// **'bãi đáp đang bảo trì'**
  String get blockPadMaintenance;

  /// No description provided for @blockPadFault.
  ///
  /// In vi, this message translates to:
  /// **'bãi đáp đang lỗi'**
  String get blockPadFault;

  /// No description provided for @droneErrOwnerOnly.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ người đặt đơn mới thực hiện được thao tác này.'**
  String get droneErrOwnerOnly;

  /// No description provided for @droneErrNotYourIncident.
  ///
  /// In vi, this message translates to:
  /// **'Sự cố này không thuộc đơn của bạn.'**
  String get droneErrNotYourIncident;

  /// No description provided for @droneErrNoReview.
  ///
  /// In vi, this message translates to:
  /// **'Chính sách của đơn không cho yêu cầu xem xét lại phương án.'**
  String get droneErrNoReview;

  /// No description provided for @droneErrAlreadyResponded.
  ///
  /// In vi, this message translates to:
  /// **'Phương án này đã được phản hồi. Vui lòng tải lại.'**
  String get droneErrAlreadyResponded;

  /// No description provided for @droneErrNoProposal.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có phương án nào chờ bạn phản hồi.'**
  String get droneErrNoProposal;

  /// No description provided for @droneErrInvalidChoice.
  ///
  /// In vi, this message translates to:
  /// **'Lựa chọn không hợp lệ.'**
  String get droneErrInvalidChoice;

  /// No description provided for @droneErrRecipientLookup.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tra được thông tin người nhận. Vui lòng thử lại sau.'**
  String get droneErrRecipientLookup;

  /// No description provided for @droneNoPermission.
  ///
  /// In vi, this message translates to:
  /// **'Bạn không có quyền xem đơn drone này. Chỉ người đặt và người nhận theo dõi được đơn.'**
  String get droneNoPermission;

  /// No description provided for @droneStatusLoadFailedRetrying.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được trạng thái giao hàng. Đang thử lại...'**
  String get droneStatusLoadFailedRetrying;

  /// No description provided for @dronePickupCodeNotSupported.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ chưa hỗ trợ tra mã nhận hàng trong ứng dụng. Hãy dùng mã PIN đã gửi qua thông báo, email hoặc SMS.'**
  String get dronePickupCodeNotSupported;

  /// No description provided for @droneTrackingDisabled.
  ///
  /// In vi, this message translates to:
  /// **'Tính năng theo dõi giao drone đang tạm tắt.'**
  String get droneTrackingDisabled;

  /// No description provided for @droneStatusLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được trạng thái giao hàng.'**
  String get droneStatusLoadFailed;

  /// No description provided for @ddTlPayment.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán'**
  String get ddTlPayment;

  /// No description provided for @ddTlParcelDropped.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ kiện vào ô gửi'**
  String get ddTlParcelDropped;

  /// No description provided for @ddTlHomePickup.
  ///
  /// In vi, this message translates to:
  /// **'Lấy hàng tại nhà người gửi'**
  String get ddTlHomePickup;

  /// No description provided for @ddTlLoaded.
  ///
  /// In vi, this message translates to:
  /// **'Nạp hàng lên drone'**
  String get ddTlLoaded;

  /// No description provided for @ddTlReady.
  ///
  /// In vi, this message translates to:
  /// **'Sẵn sàng phóng'**
  String get ddTlReady;

  /// No description provided for @ddTlCodeSent.
  ///
  /// In vi, this message translates to:
  /// **'Gửi mã cho người nhận'**
  String get ddTlCodeSent;

  /// No description provided for @ddTlPickupDeadline.
  ///
  /// In vi, this message translates to:
  /// **'Hạn nhận hàng'**
  String get ddTlPickupDeadline;

  /// No description provided for @ddTlReceived.
  ///
  /// In vi, this message translates to:
  /// **'Người nhận lấy hàng'**
  String get ddTlReceived;

  /// No description provided for @ddProgress.
  ///
  /// In vi, this message translates to:
  /// **'Tiến trình giao hàng'**
  String get ddProgress;

  /// No description provided for @ddClosedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đơn drone đã đóng'**
  String get ddClosedTitle;

  /// No description provided for @ddClosedBody.
  ///
  /// In vi, this message translates to:
  /// **'Chuyến bay không hoàn tất nên đơn này đã đóng; phương án xử lý xem ở phần sự cố của đơn.'**
  String get ddClosedBody;

  /// No description provided for @ddAwaitingPaymentTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chờ thanh toán'**
  String get ddAwaitingPaymentTitle;

  /// No description provided for @ddAwaitingPaymentBody.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán xong hệ thống mới tìm kỹ thuật viên drone tới lấy hàng'**
  String get ddAwaitingPaymentBody;

  /// No description provided for @ddAwaitingTeamTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chờ đội bay tiếp nhận'**
  String get ddAwaitingTeamTitle;

  /// No description provided for @ddAwaitingTeamBody.
  ///
  /// In vi, this message translates to:
  /// **'Kiện đã sẵn sàng tại trạm Lock.R, chờ kỹ thuật viên drone nạp hàng và phóng'**
  String get ddAwaitingTeamBody;

  /// No description provided for @ddReadyBody.
  ///
  /// In vi, this message translates to:
  /// **'Kiện đã được nạp và niêm phong trên drone, chờ đội bay phóng'**
  String get ddReadyBody;

  /// No description provided for @ddAboutMinutesLeft.
  ///
  /// In vi, this message translates to:
  /// **'Còn khoảng {minutes} phút'**
  String ddAboutMinutesLeft(Object minutes);

  /// No description provided for @ddSince.
  ///
  /// In vi, this message translates to:
  /// **'Từ {time}'**
  String ddSince(Object time);

  /// No description provided for @ddOverdueAt.
  ///
  /// In vi, this message translates to:
  /// **'Đơn hàng đã quá hạn lấy lúc {deadline}. {policy}'**
  String ddOverdueAt(Object deadline, Object policy);

  /// No description provided for @ddPickupDeadline.
  ///
  /// In vi, this message translates to:
  /// **'Hạn người nhận lấy hàng: {deadline} (lưu trữ {hours} giờ).'**
  String ddPickupDeadline(Object deadline, Object hours);

  /// No description provided for @ddFlightIncompleteClosed.
  ///
  /// In vi, this message translates to:
  /// **'Chuyến bay không hoàn tất nên đơn này đã đóng. Phương án xử lý (giao lại hoặc bồi thường) xem ở phần sự cố của đơn.'**
  String get ddFlightIncompleteClosed;

  /// No description provided for @ddUnpaidSearch.
  ///
  /// In vi, this message translates to:
  /// **'Đơn chưa thanh toán. Thanh toán xong hệ thống mới bắt đầu tìm kỹ thuật viên drone tới lấy hàng.'**
  String get ddUnpaidSearch;

  /// No description provided for @ddAt.
  ///
  /// In vi, this message translates to:
  /// **'Lúc: {time}'**
  String ddAt(Object time);

  /// No description provided for @ddReason.
  ///
  /// In vi, this message translates to:
  /// **'Lý do: {reason}'**
  String ddReason(Object reason);

  /// No description provided for @ddNoteValue.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú: {note}'**
  String ddNoteValue(Object note);

  /// No description provided for @ddTicket.
  ///
  /// In vi, this message translates to:
  /// **'Phiếu sự cố: #{id}'**
  String ddTicket(Object id);

  /// No description provided for @ddParcelWithSender.
  ///
  /// In vi, this message translates to:
  /// **'Kiện hàng chưa được lấy, vẫn ở chỗ người gửi.'**
  String get ddParcelWithSender;

  /// No description provided for @ddRefundRecorded.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu hoàn tiền đã được ghi nhận. Admin sẽ chuyển khoản về tài khoản ngân hàng của người đặt.'**
  String get ddRefundRecorded;

  /// No description provided for @ddRefundDone.
  ///
  /// In vi, this message translates to:
  /// **'Tiền đã được chuyển khoản hoàn cho người đặt.'**
  String get ddRefundDone;

  /// No description provided for @ddRefundByIncident.
  ///
  /// In vi, this message translates to:
  /// **'Khoản đã trả được xử lý theo phương án sự cố: giao lại miễn phí hoặc bồi thường chuyển khoản về tài khoản ngân hàng đã liên kết.'**
  String get ddRefundByIncident;

  /// No description provided for @ddRefundNotRecorded.
  ///
  /// In vi, this message translates to:
  /// **'Chưa ghi nhận được yêu cầu hoàn tiền — vui lòng liên hệ hỗ trợ.'**
  String get ddRefundNotRecorded;

  /// No description provided for @ddWeightOver.
  ///
  /// In vi, this message translates to:
  /// **'Kiện cân thực tế {actual}, nặng hơn mức {expected} đã khai báo.'**
  String ddWeightOver(Object actual, Object expected);

  /// No description provided for @ddSurchargeOperator.
  ///
  /// In vi, this message translates to:
  /// **'Chờ khách trả thêm {amount} rồi mới phóng được.'**
  String ddSurchargeOperator(Object amount);

  /// No description provided for @ddSurchargeReceiver.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ người gửi trả thêm {amount} để drone cất cánh.'**
  String ddSurchargeReceiver(Object amount);

  /// No description provided for @ddSurchargeSender.
  ///
  /// In vi, this message translates to:
  /// **'Bạn cần trả thêm {amount} để drone cất cánh. Không đồng ý thì bạn có thể huỷ đơn: phần đã trả được hoàn và đội bay trả lại kiện.'**
  String ddSurchargeSender(Object amount);

  /// No description provided for @ddUnpaidOperator.
  ///
  /// In vi, this message translates to:
  /// **'Khách chưa thanh toán. Chỉ tiếp nhận được sau khi đơn đã thanh toán.'**
  String get ddUnpaidOperator;

  /// No description provided for @ddUnpaidReceiver.
  ///
  /// In vi, this message translates to:
  /// **'Người gửi chưa thanh toán đơn. Đội bay tiếp nhận sau khi người gửi thanh toán.'**
  String get ddUnpaidReceiver;

  /// No description provided for @ddUnpaidSender.
  ///
  /// In vi, this message translates to:
  /// **'Đơn chưa thanh toán. Đội bay chỉ tiếp nhận sau khi bạn thanh toán.'**
  String get ddUnpaidSender;

  /// No description provided for @ddPaySurcharge.
  ///
  /// In vi, this message translates to:
  /// **'Trả thêm phí chênh'**
  String get ddPaySurcharge;

  /// No description provided for @ddPayNow.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán ngay'**
  String get ddPayNow;

  /// No description provided for @ddDeclineSurcharge.
  ///
  /// In vi, this message translates to:
  /// **'Không đồng ý · huỷ đơn và nhận hoàn tiền'**
  String get ddDeclineSurcharge;

  /// No description provided for @ddIncidentLabel.
  ///
  /// In vi, this message translates to:
  /// **'Đơn đang gặp sự cố: {label}'**
  String ddIncidentLabel(Object label);

  /// No description provided for @ddFromTime.
  ///
  /// In vi, this message translates to:
  /// **'Từ lúc: {time}'**
  String ddFromTime(Object time);

  /// No description provided for @ddAutoCloseOperator.
  ///
  /// In vi, this message translates to:
  /// **'Chưa khắc phục trước {time} thì đơn tự kết thúc \"giao không hoàn tất\" và hoàn tiền cho khách.'**
  String ddAutoCloseOperator(Object time);

  /// No description provided for @ddAutoCloseCustomer.
  ///
  /// In vi, this message translates to:
  /// **'Nếu chưa khắc phục được trước {time}, đơn sẽ kết thúc và bạn được hoàn tiền.'**
  String ddAutoCloseCustomer(Object time);

  /// No description provided for @ddChangePlan.
  ///
  /// In vi, this message translates to:
  /// **'Đổi phương án hoặc xác nhận giao không hoàn tất.'**
  String get ddChangePlan;

  /// No description provided for @ddTeamHandling.
  ///
  /// In vi, this message translates to:
  /// **'Đội bay đang xử lý.'**
  String get ddTeamHandling;

  /// No description provided for @ddPickedUp.
  ///
  /// In vi, this message translates to:
  /// **'Đã lấy hàng{at}'**
  String ddPickedUp(Object at);

  /// No description provided for @ddPickedUpAt.
  ///
  /// In vi, this message translates to:
  /// **' lúc {time}'**
  String ddPickedUpAt(Object time);

  /// No description provided for @ddTechnician.
  ///
  /// In vi, this message translates to:
  /// **'Kỹ thuật viên'**
  String get ddTechnician;

  /// No description provided for @ddYouHeadingToPickup.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đang tới lấy hàng'**
  String get ddYouHeadingToPickup;

  /// No description provided for @ddTechHeadingToPickup.
  ///
  /// In vi, this message translates to:
  /// **'{who} đang tới lấy hàng'**
  String ddTechHeadingToPickup(Object who);

  /// No description provided for @ddYouAreInvited.
  ///
  /// In vi, this message translates to:
  /// **'Bạn được mời lấy hàng'**
  String get ddYouAreInvited;

  /// No description provided for @ddSearchingTech.
  ///
  /// In vi, this message translates to:
  /// **'Đang tìm kỹ thuật viên drone gần bạn nhất'**
  String get ddSearchingTech;

  /// No description provided for @ddAwaitingDispatchPickup.
  ///
  /// In vi, this message translates to:
  /// **'Chờ điều phối lấy hàng'**
  String get ddAwaitingDispatchPickup;

  /// No description provided for @ddTechAfterPayment.
  ///
  /// In vi, this message translates to:
  /// **'Kỹ thuật viên sẽ tới lấy hàng sau khi đơn được thanh toán'**
  String get ddTechAfterPayment;

  /// No description provided for @ddHomePickup.
  ///
  /// In vi, this message translates to:
  /// **'Lấy hàng tận nhà'**
  String get ddHomePickup;

  /// No description provided for @ddPickupCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã lấy hàng'**
  String get ddPickupCode;

  /// No description provided for @ddPickupCodeHint.
  ///
  /// In vi, this message translates to:
  /// **'Đọc mã này cho kỹ thuật viên khi giao kiện. Không gửi mã cho người khác.'**
  String get ddPickupCodeHint;

  /// No description provided for @ddPickupPoint.
  ///
  /// In vi, this message translates to:
  /// **'Điểm lấy hàng'**
  String get ddPickupPoint;

  /// No description provided for @ddDirections.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ dẫn'**
  String get ddDirections;

  /// No description provided for @ddTechPhone.
  ///
  /// In vi, this message translates to:
  /// **'SĐT kỹ thuật viên'**
  String get ddTechPhone;

  /// No description provided for @ddDistanceAtAccept.
  ///
  /// In vi, this message translates to:
  /// **'Cách điểm lấy lúc nhận việc'**
  String get ddDistanceAtAccept;

  /// No description provided for @ddPickupToSource.
  ///
  /// In vi, this message translates to:
  /// **'Điểm lấy hàng → tủ gửi'**
  String get ddPickupToSource;

  /// No description provided for @ddPickupNote.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú lúc lấy hàng'**
  String get ddPickupNote;

  /// No description provided for @ddPickupPhoto.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh kiện lúc lấy hàng'**
  String get ddPickupPhoto;

  /// No description provided for @ddPhotoTakenAt.
  ///
  /// In vi, this message translates to:
  /// **'Chụp lúc {time}'**
  String ddPhotoTakenAt(Object time);

  /// No description provided for @ddDroneBoxAtSource.
  ///
  /// In vi, this message translates to:
  /// **'ô drone ở tủ gửi'**
  String get ddDroneBoxAtSource;

  /// No description provided for @ddDroneBoxNumberAtSource.
  ///
  /// In vi, this message translates to:
  /// **'ô drone số {box} ở tủ gửi'**
  String ddDroneBoxNumberAtSource(Object box);

  /// No description provided for @ddSenderNotDroppedOperator.
  ///
  /// In vi, this message translates to:
  /// **'Người gửi chưa xác nhận bỏ kiện vào {where}. Chỉ tiếp nhận được sau khi kiện đã nằm trong ô.'**
  String ddSenderNotDroppedOperator(Object where);

  /// No description provided for @ddWaitingSenderDrop.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ người gửi bỏ kiện vào {where}.'**
  String ddWaitingSenderDrop(Object where);

  /// No description provided for @ddDropThenConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ kiện vào {where} rồi xác nhận bên dưới. Đội bay chỉ tiếp nhận đơn sau khi bạn xác nhận.'**
  String ddDropThenConfirm(Object where);

  /// No description provided for @ddIDropped.
  ///
  /// In vi, this message translates to:
  /// **'Tôi đã bỏ kiện vào ô'**
  String get ddIDropped;

  /// No description provided for @ddParcelReturnedAt.
  ///
  /// In vi, this message translates to:
  /// **'Kiện đã được trả lại cho người gửi lúc {time}.'**
  String ddParcelReturnedAt(Object time);

  /// No description provided for @ddParcelInBoxOperator.
  ///
  /// In vi, this message translates to:
  /// **'Kiện còn trong ô gửi. Lấy kiện ra, trả cho người gửi rồi xác nhận đã trả.'**
  String get ddParcelInBoxOperator;

  /// No description provided for @ddParcelWithTeamOperator.
  ///
  /// In vi, this message translates to:
  /// **'Kiện đang do đội bay giữ. Trả cho người gửi rồi xác nhận đã trả.'**
  String get ddParcelWithTeamOperator;

  /// No description provided for @ddParcelInBoxCustomer.
  ///
  /// In vi, this message translates to:
  /// **'Kiện của bạn còn trong ô gửi. Đội bay sẽ liên hệ để trả lại kiện.'**
  String get ddParcelInBoxCustomer;

  /// No description provided for @ddParcelHeldByTech.
  ///
  /// In vi, this message translates to:
  /// **'Kiện đang do kỹ thuật viên giữ và sẽ được mang trả lại{where}.'**
  String ddParcelHeldByTech(Object where);

  /// No description provided for @ddToSender.
  ///
  /// In vi, this message translates to:
  /// **' cho người gửi'**
  String get ddToSender;

  /// No description provided for @ddAtAddress.
  ///
  /// In vi, this message translates to:
  /// **' tại {address}'**
  String ddAtAddress(Object address);

  /// No description provided for @ddCancelOrder.
  ///
  /// In vi, this message translates to:
  /// **'Huỷ đơn'**
  String get ddCancelOrder;

  /// No description provided for @ddCancelAllowed.
  ///
  /// In vi, this message translates to:
  /// **'Bạn huỷ được đơn khi đội bay chưa tiếp nhận.'**
  String get ddCancelAllowed;

  /// No description provided for @ddRoute.
  ///
  /// In vi, this message translates to:
  /// **'Lộ trình giao hàng'**
  String get ddRoute;

  /// No description provided for @ddSystemPickedStation.
  ///
  /// In vi, this message translates to:
  /// **'Tủ bay do hệ thống chọn (KTV nạp kiện trực tiếp lên drone)'**
  String get ddSystemPickedStation;

  /// No description provided for @ddLegacyBox.
  ///
  /// In vi, this message translates to:
  /// **'Đơn cũ: kiện từng được gửi vào ô số {box}'**
  String ddLegacyBox(Object box);

  /// No description provided for @ddSentAt.
  ///
  /// In vi, this message translates to:
  /// **'Gửi đi lúc: {time}'**
  String ddSentAt(Object time);

  /// No description provided for @ddNotSentYet.
  ///
  /// In vi, this message translates to:
  /// **'Chưa gửi'**
  String get ddNotSentYet;

  /// No description provided for @ddDirectionsToDrone.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ đường tới drone tại tủ bay'**
  String get ddDirectionsToDrone;

  /// No description provided for @ddReceiverLockerOperator.
  ///
  /// In vi, this message translates to:
  /// **'Tủ nhận khách đã chọn (người nhận lấy hàng)'**
  String get ddReceiverLockerOperator;

  /// No description provided for @ddReceiverLockerCustomer.
  ///
  /// In vi, this message translates to:
  /// **'Tủ nhận bạn đã chọn (người nhận lấy hàng)'**
  String get ddReceiverLockerCustomer;

  /// No description provided for @ddReceiveBox.
  ///
  /// In vi, this message translates to:
  /// **'Ô nhận số {box}'**
  String ddReceiveBox(Object box);

  /// No description provided for @ddDepositedAt.
  ///
  /// In vi, this message translates to:
  /// **'Hàng vào tủ lúc: {time}'**
  String ddDepositedAt(Object time);

  /// No description provided for @ddNotArrived.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tới'**
  String get ddNotArrived;

  /// No description provided for @ddCodeSentAt.
  ///
  /// In vi, this message translates to:
  /// **'Gửi mã cho người nhận lúc: {time}'**
  String ddCodeSentAt(Object time);

  /// No description provided for @ddReceivedAt.
  ///
  /// In vi, this message translates to:
  /// **'Người nhận lấy hàng lúc: {time}'**
  String ddReceivedAt(Object time);

  /// No description provided for @ddNotReceived.
  ///
  /// In vi, this message translates to:
  /// **'Chưa nhận'**
  String get ddNotReceived;

  /// No description provided for @ddDirectionsToReceiver.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ đường tới tủ nhận'**
  String get ddDirectionsToReceiver;

  /// No description provided for @ddLockerNoAddress.
  ///
  /// In vi, this message translates to:
  /// **'Tủ này chưa có địa chỉ hoặc toạ độ để chỉ đường.'**
  String get ddLockerNoAddress;

  /// No description provided for @ddCantOpenMaps.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được ứng dụng bản đồ trên thiết bị.'**
  String get ddCantOpenMaps;

  /// No description provided for @ddOrderInfo.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin đơn hàng'**
  String get ddOrderInfo;

  /// No description provided for @ddOrderCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã đơn'**
  String get ddOrderCode;

  /// No description provided for @ddOrderStatus.
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái đơn'**
  String get ddOrderStatus;

  /// No description provided for @ddPausedDrop.
  ///
  /// In vi, this message translates to:
  /// **'Tạm dừng do sự cố rơi kiện'**
  String get ddPausedDrop;

  /// No description provided for @ddDroneFee.
  ///
  /// In vi, this message translates to:
  /// **'Phí giao drone'**
  String get ddDroneFee;

  /// No description provided for @ddWeightSurcharge.
  ///
  /// In vi, this message translates to:
  /// **'Trong đó thu thêm do cân lệch'**
  String get ddWeightSurcharge;

  /// No description provided for @ddDiscountCodeValue.
  ///
  /// In vi, this message translates to:
  /// **'Mã giảm giá {code}'**
  String ddDiscountCodeValue(Object code);

  /// No description provided for @ddUsePoints.
  ///
  /// In vi, this message translates to:
  /// **'Dùng {points} điểm'**
  String ddUsePoints(Object points);

  /// No description provided for @ddAmountPaid.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền thanh toán'**
  String get ddAmountPaid;

  /// No description provided for @ddMethod.
  ///
  /// In vi, this message translates to:
  /// **'Phương thức'**
  String get ddMethod;

  /// No description provided for @ddPaymentRef.
  ///
  /// In vi, this message translates to:
  /// **'Mã thanh toán'**
  String get ddPaymentRef;

  /// No description provided for @ddBoxAtLocker.
  ///
  /// In vi, this message translates to:
  /// **'Ô nhận tại tủ'**
  String get ddBoxAtLocker;

  /// No description provided for @ddDeclaredWeight.
  ///
  /// In vi, this message translates to:
  /// **'Khối lượng khai báo'**
  String get ddDeclaredWeight;

  /// No description provided for @ddParcelSize.
  ///
  /// In vi, this message translates to:
  /// **'Kích thước kiện'**
  String get ddParcelSize;

  /// No description provided for @ddCaution.
  ///
  /// In vi, this message translates to:
  /// **'Lưu ý'**
  String get ddCaution;

  /// No description provided for @ddDroppedAtLabel.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ kiện vào ô gửi lúc'**
  String get ddDroppedAtLabel;

  /// No description provided for @ddTechReceivedAt.
  ///
  /// In vi, this message translates to:
  /// **'KTV nhận kiện lúc'**
  String get ddTechReceivedAt;

  /// No description provided for @ddParcelDescription.
  ///
  /// In vi, this message translates to:
  /// **'Mô tả kiện hàng'**
  String get ddParcelDescription;

  /// No description provided for @ddNoDescription.
  ///
  /// In vi, this message translates to:
  /// **'Không có mô tả'**
  String get ddNoDescription;

  /// No description provided for @ddFlightMode.
  ///
  /// In vi, this message translates to:
  /// **'Hình thức bay'**
  String get ddFlightMode;

  /// No description provided for @ddPeople.
  ///
  /// In vi, this message translates to:
  /// **'Người liên quan'**
  String get ddPeople;

  /// No description provided for @ddDroneTech.
  ///
  /// In vi, this message translates to:
  /// **'Kỹ thuật viên drone'**
  String get ddDroneTech;

  /// No description provided for @ddNoTechYet.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có người nhận việc'**
  String get ddNoTechYet;

  /// No description provided for @ddTechAccepted.
  ///
  /// In vi, this message translates to:
  /// **'Đã nhận việc'**
  String get ddTechAccepted;

  /// No description provided for @ddLoader.
  ///
  /// In vi, this message translates to:
  /// **'Người nạp hàng'**
  String get ddLoader;

  /// No description provided for @ddNotLoaded.
  ///
  /// In vi, this message translates to:
  /// **'Chưa nạp hàng'**
  String get ddNotLoaded;

  /// No description provided for @ddLoaded.
  ///
  /// In vi, this message translates to:
  /// **'Đã nạp'**
  String get ddLoaded;

  /// No description provided for @ddNotChecked.
  ///
  /// In vi, this message translates to:
  /// **'Chưa kiểm'**
  String get ddNotChecked;

  /// No description provided for @ddPass.
  ///
  /// In vi, this message translates to:
  /// **'Đạt'**
  String get ddPass;

  /// No description provided for @ddFail.
  ///
  /// In vi, this message translates to:
  /// **'Không đạt'**
  String get ddFail;

  /// No description provided for @ddMissionRecord.
  ///
  /// In vi, this message translates to:
  /// **'Nhiệm vụ bay & hồ sơ nạp hàng'**
  String get ddMissionRecord;

  /// No description provided for @ddMissionCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã nhiệm vụ'**
  String get ddMissionCode;

  /// No description provided for @ddNotAssigned.
  ///
  /// In vi, this message translates to:
  /// **'Chưa phân công'**
  String get ddNotAssigned;

  /// No description provided for @ddMissionStatus.
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái nhiệm vụ'**
  String get ddMissionStatus;

  /// No description provided for @ddDronePosition.
  ///
  /// In vi, this message translates to:
  /// **'Vị trí drone hiện tại'**
  String get ddDronePosition;

  /// No description provided for @ddNoData.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có dữ liệu'**
  String get ddNoData;

  /// No description provided for @ddActualWeight.
  ///
  /// In vi, this message translates to:
  /// **'Khối lượng thực tế'**
  String get ddActualWeight;

  /// No description provided for @ddSealCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã niêm phong'**
  String get ddSealCode;

  /// No description provided for @ddNotSealed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa niêm phong'**
  String get ddNotSealed;

  /// No description provided for @ddParcelMatched.
  ///
  /// In vi, this message translates to:
  /// **'Đúng kiện, đúng đơn'**
  String get ddParcelMatched;

  /// No description provided for @ddPayloadSecured.
  ///
  /// In vi, this message translates to:
  /// **'Kiện đã cố định'**
  String get ddPayloadSecured;

  /// No description provided for @ddCompartmentLocked.
  ///
  /// In vi, this message translates to:
  /// **'Khoang hàng đã khoá'**
  String get ddCompartmentLocked;

  /// No description provided for @ddLoadingNote.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú nạp hàng'**
  String get ddLoadingNote;

  /// No description provided for @ddEvLoaded.
  ///
  /// In vi, this message translates to:
  /// **'Đã nạp hàng lên drone'**
  String get ddEvLoaded;

  /// No description provided for @ddEvCodeSent.
  ///
  /// In vi, this message translates to:
  /// **'Gửi mã nhận hàng cho người nhận'**
  String get ddEvCodeSent;

  /// No description provided for @ddEvCreated.
  ///
  /// In vi, this message translates to:
  /// **'Đơn drone được tạo'**
  String get ddEvCreated;

  /// No description provided for @ddJourneyLog.
  ///
  /// In vi, this message translates to:
  /// **'Nhật ký hành trình · mới nhất trước'**
  String get ddJourneyLog;

  /// No description provided for @ddNoJourney.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có mốc hành trình nào.'**
  String get ddNoJourney;

  /// No description provided for @ddSystem.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống'**
  String get ddSystem;

  /// No description provided for @ddLockrStaff.
  ///
  /// In vi, this message translates to:
  /// **'Nhân viên Lock.R'**
  String get ddLockrStaff;

  /// No description provided for @ddNewest.
  ///
  /// In vi, this message translates to:
  /// **'Mới nhất'**
  String get ddNewest;

  /// No description provided for @dbBoxTaken.
  ///
  /// In vi, this message translates to:
  /// **'{box} vừa được người khác giữ. Hãy chọn ô drone khác.'**
  String dbBoxTaken(Object box);

  /// No description provided for @dbYourBox.
  ///
  /// In vi, this message translates to:
  /// **'Ô bạn chọn'**
  String get dbYourBox;

  /// No description provided for @dbCheckingBoxes.
  ///
  /// In vi, this message translates to:
  /// **'Đang kiểm tra ô drone…'**
  String get dbCheckingBoxes;

  /// No description provided for @dbNoFreeBoxes.
  ///
  /// In vi, this message translates to:
  /// **'Không còn ô drone nhận trống'**
  String get dbNoFreeBoxes;

  /// No description provided for @dbChooseBox.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ô người nhận sẽ lấy hàng'**
  String get dbChooseBox;

  /// No description provided for @dbDistancePrefix.
  ///
  /// In vi, this message translates to:
  /// **'Cách bạn {distance} · '**
  String dbDistancePrefix(Object distance);

  /// No description provided for @dbNoPad.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có bãi đáp drone'**
  String get dbNoPad;

  /// No description provided for @dbNoCoordinates.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có toạ độ tủ'**
  String get dbNoCoordinates;

  /// No description provided for @dbCheckingBoxesShort.
  ///
  /// In vi, this message translates to:
  /// **'Đang kiểm tra ô drone'**
  String get dbCheckingBoxesShort;

  /// No description provided for @dbOutOfBoxes.
  ///
  /// In vi, this message translates to:
  /// **'Hết ô drone trống'**
  String get dbOutOfBoxes;

  /// No description provided for @dbFreeBoxes.
  ///
  /// In vi, this message translates to:
  /// **'{count} ô drone trống'**
  String dbFreeBoxes(Object count);

  /// No description provided for @dbEnterName.
  ///
  /// In vi, this message translates to:
  /// **'Nhập tên {who}'**
  String dbEnterName(Object who);

  /// No description provided for @dbInvalidPhone.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại {who} không hợp lệ'**
  String dbInvalidPhone(Object who);

  /// No description provided for @dbInvalidEmail.
  ///
  /// In vi, this message translates to:
  /// **'Email {who} không hợp lệ'**
  String dbInvalidEmail(Object who);

  /// No description provided for @dbChoosePickup.
  ///
  /// In vi, this message translates to:
  /// **'Chọn điểm lấy hàng'**
  String get dbChoosePickup;

  /// No description provided for @dbWhoSender.
  ///
  /// In vi, this message translates to:
  /// **'người gửi'**
  String get dbWhoSender;

  /// No description provided for @dbWhoReceiver.
  ///
  /// In vi, this message translates to:
  /// **'người nhận'**
  String get dbWhoReceiver;

  /// No description provided for @dbChooseReceiverLocker.
  ///
  /// In vi, this message translates to:
  /// **'Chọn tủ nhận'**
  String get dbChooseReceiverLocker;

  /// No description provided for @dbCheckingReceiverBoxes.
  ///
  /// In vi, this message translates to:
  /// **'Đang kiểm tra ô drone trống của tủ nhận, vui lòng chờ một chút'**
  String get dbCheckingReceiverBoxes;

  /// No description provided for @dbReceiverFull.
  ///
  /// In vi, this message translates to:
  /// **'Tủ nhận này đã hết ô drone trống, hãy chọn tủ khác'**
  String get dbReceiverFull;

  /// No description provided for @dbChooseReceiverBox.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ô drone nhận còn trống tại tủ nhận'**
  String get dbChooseReceiverBox;

  /// No description provided for @dbChooseCategory.
  ///
  /// In vi, this message translates to:
  /// **'Chọn loại hàng'**
  String get dbChooseCategory;

  /// No description provided for @dbSizeAllOrNone.
  ///
  /// In vi, this message translates to:
  /// **'Nhập đủ dài, rộng, cao của kiện (cm) hoặc bỏ trống cả ba'**
  String get dbSizeAllOrNone;

  /// No description provided for @dbTooLarge.
  ///
  /// In vi, this message translates to:
  /// **'Kiện không lọt khoang drone (tối đa {l} × {w} × {h} cm)'**
  String dbTooLarge(Object l, Object w, Object h);

  /// No description provided for @dbMaxValue.
  ///
  /// In vi, this message translates to:
  /// **'Drone chỉ nhận kiện có giá trị tới {amount}'**
  String dbMaxValue(Object amount);

  /// No description provided for @dbConfirmNoProhibited.
  ///
  /// In vi, this message translates to:
  /// **'Bạn cần cam kết kiện không chứa hàng cấm bay'**
  String get dbConfirmNoProhibited;

  /// No description provided for @dbPaidByVoucher.
  ///
  /// In vi, this message translates to:
  /// **'Đơn đã được thanh toán bằng ưu đãi. Đội bay sẽ tiếp nhận đơn của bạn.'**
  String get dbPaidByVoucher;

  /// No description provided for @dbCreatedNotPaid.
  ///
  /// In vi, this message translates to:
  /// **'Đã tạo đơn drone nhưng chưa thanh toán được: {error}'**
  String dbCreatedNotPaid(Object error);

  /// No description provided for @dbTitle.
  ///
  /// In vi, this message translates to:
  /// **'Gửi hàng bằng drone'**
  String get dbTitle;

  /// No description provided for @dbIntro.
  ///
  /// In vi, this message translates to:
  /// **'Đặt và thanh toán xong, kỹ thuật viên drone gần bạn nhất sẽ tới lấy kiện, mang tới drone tại tủ bay để nạp trực tiếp lên drone (không bỏ vào ô tủ), rồi drone bay tới ô nhận bạn đã chọn. Người nhận lấy hàng bằng mã mở ô gửi qua email.'**
  String get dbIntro;

  /// No description provided for @dbSuspended.
  ///
  /// In vi, this message translates to:
  /// **'Dịch vụ giao drone đang tạm dừng (thời tiết hoặc sự cố vận hành). Vui lòng thử lại sau.'**
  String get dbSuspended;

  /// No description provided for @dbPickupAt.
  ///
  /// In vi, this message translates to:
  /// **'Lấy hàng tại'**
  String get dbPickupAt;

  /// No description provided for @dbTechInstructions.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ dẫn cho kỹ thuật viên (tuỳ chọn)'**
  String get dbTechInstructions;

  /// No description provided for @dbTechInstructionsHint.
  ///
  /// In vi, this message translates to:
  /// **'Tầng, cổng, giờ có nhà…'**
  String get dbTechInstructionsHint;

  /// No description provided for @dbSenderName.
  ///
  /// In vi, this message translates to:
  /// **'Họ tên người gửi *'**
  String get dbSenderName;

  /// No description provided for @dbSenderPhone.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại người gửi *'**
  String get dbSenderPhone;

  /// No description provided for @dbSenderEmail.
  ///
  /// In vi, this message translates to:
  /// **'Email người gửi *'**
  String get dbSenderEmail;

  /// No description provided for @dbReceiverName.
  ///
  /// In vi, this message translates to:
  /// **'Họ tên người nhận *'**
  String get dbReceiverName;

  /// No description provided for @dbReceiverPhone.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại người nhận *'**
  String get dbReceiverPhone;

  /// No description provided for @dbReceiverEmail.
  ///
  /// In vi, this message translates to:
  /// **'Email người nhận *'**
  String get dbReceiverEmail;

  /// No description provided for @dbEmailInfo.
  ///
  /// In vi, this message translates to:
  /// **'Khi drone được phóng, người gửi và người nhận đều nhận email báo đơn. Khi hàng vào tủ, mã mở ô được gửi tới email người nhận.'**
  String get dbEmailInfo;

  /// No description provided for @dbReceiverLockerField.
  ///
  /// In vi, this message translates to:
  /// **'Tủ nhận *'**
  String get dbReceiverLockerField;

  /// No description provided for @dbLoadingLockers.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải tủ nhận...'**
  String get dbLoadingLockers;

  /// No description provided for @dbNoLockersInSystem.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống chưa có tủ nào'**
  String get dbNoLockersInSystem;

  /// No description provided for @dbReceiverBoxField.
  ///
  /// In vi, this message translates to:
  /// **'Ô drone nhận *'**
  String get dbReceiverBoxField;

  /// No description provided for @dbFreeReceiverBoxes.
  ///
  /// In vi, this message translates to:
  /// **'Ô nhận drone còn trống: {count}'**
  String dbFreeReceiverBoxes(Object count);

  /// No description provided for @dbChecking.
  ///
  /// In vi, this message translates to:
  /// **'đang kiểm tra…'**
  String get dbChecking;

  /// No description provided for @dbLockerCantReceive.
  ///
  /// In vi, this message translates to:
  /// **'Tủ này chưa nhận được drone: {reason}'**
  String dbLockerCantReceive(Object reason);

  /// No description provided for @dbWeightField.
  ///
  /// In vi, this message translates to:
  /// **'Khối lượng * (tối đa {max} một đơn)'**
  String dbWeightField(Object max);

  /// No description provided for @dbWeightHint.
  ///
  /// In vi, this message translates to:
  /// **'Chọn mức bằng hoặc lớn hơn khối lượng thật. Kỹ thuật viên cân lại khi nạp hàng: nặng hơn mức đã chọn quá {tolerance} g thì bạn trả thêm phần phí chênh trước khi drone bay; nhẹ hơn không hoàn lại.'**
  String dbWeightHint(Object tolerance);

  /// No description provided for @dbCategoryField.
  ///
  /// In vi, this message translates to:
  /// **'Loại hàng *'**
  String get dbCategoryField;

  /// No description provided for @dbDescriptionField.
  ///
  /// In vi, this message translates to:
  /// **'Mô tả hàng hoá (tuỳ chọn)'**
  String get dbDescriptionField;

  /// No description provided for @dbLength.
  ///
  /// In vi, this message translates to:
  /// **'Dài'**
  String get dbLength;

  /// No description provided for @dbWidth.
  ///
  /// In vi, this message translates to:
  /// **'Rộng'**
  String get dbWidth;

  /// No description provided for @dbSizeHint.
  ///
  /// In vi, this message translates to:
  /// **'Kích thước tuỳ chọn. Khoang drone tối đa {size} cm.'**
  String dbSizeHint(Object size);

  /// No description provided for @dbDeclaredValueField.
  ///
  /// In vi, this message translates to:
  /// **'Giá trị khai báo (tuỳ chọn)'**
  String get dbDeclaredValueField;

  /// No description provided for @dbDeclaredValueHint.
  ///
  /// In vi, this message translates to:
  /// **'Căn cứ bồi thường nếu kiện hư hỏng, thất lạc. Tối đa {amount}.'**
  String dbDeclaredValueHint(Object amount);

  /// No description provided for @dbRouteAndFee.
  ///
  /// In vi, this message translates to:
  /// **'Lộ trình và phí'**
  String get dbRouteAndFee;

  /// No description provided for @dbAutoCancel.
  ///
  /// In vi, this message translates to:
  /// **'Đơn chưa thanh toán sau {minutes} phút sẽ tự huỷ.'**
  String dbAutoCancel(Object minutes);

  /// No description provided for @dbNoProhibitedCheckbox.
  ///
  /// In vi, this message translates to:
  /// **'Tôi cam kết kiện không chứa hàng cấm bay: pin rời, chất lỏng, chất dễ cháy nổ, hàng cấm theo pháp luật. *'**
  String get dbNoProhibitedCheckbox;

  /// No description provided for @dbCreateAndPay.
  ///
  /// In vi, this message translates to:
  /// **'Tạo đơn và thanh toán {amount}'**
  String dbCreateAndPay(Object amount);

  /// No description provided for @dbCreateFree.
  ///
  /// In vi, this message translates to:
  /// **'Tạo đơn (ưu đãi đã trừ hết phí)'**
  String get dbCreateFree;

  /// No description provided for @dbLockerCodeOnly.
  ///
  /// In vi, this message translates to:
  /// **'Mã riêng của tủ chỉ dùng được khi drone cất cánh tại {locker}.'**
  String dbLockerCodeOnly(Object locker);

  /// No description provided for @dbChoosePickupHint.
  ///
  /// In vi, this message translates to:
  /// **'Chọn điểm lấy hàng * — dùng vị trí hiện tại hoặc tự nhập/ghim trên bản đồ'**
  String get dbChoosePickupHint;

  /// No description provided for @dbLatLngTap.
  ///
  /// In vi, this message translates to:
  /// **'Vĩ độ {lat} · kinh độ {lng} · chạm để đổi'**
  String dbLatLngTap(Object lat, Object lng);

  /// No description provided for @dbQuoteHint.
  ///
  /// In vi, this message translates to:
  /// **'Chọn điểm lấy hàng và tủ nhận để xem tủ gửi, quãng đường và phí.'**
  String get dbQuoteHint;

  /// No description provided for @dbCalculatingRoute.
  ///
  /// In vi, this message translates to:
  /// **'Đang tính lộ trình…'**
  String get dbCalculatingRoute;

  /// No description provided for @dbSystemStation.
  ///
  /// In vi, this message translates to:
  /// **'Tủ bay do hệ thống chọn: {locker}'**
  String dbSystemStation(Object locker);

  /// No description provided for @dbRouteSummary.
  ///
  /// In vi, this message translates to:
  /// **'Kỹ thuật viên mang kiện {pickup} tới drone ở tủ bay để nạp trực tiếp · drone bay {route} tới ô nhận tại tủ đích'**
  String dbRouteSummary(Object pickup, Object route);

  /// No description provided for @dbFeeValue.
  ///
  /// In vi, this message translates to:
  /// **'Phí giao drone: {amount}'**
  String dbFeeValue(Object amount);

  /// No description provided for @dbWind.
  ///
  /// In vi, this message translates to:
  /// **'gió {speed} km/h'**
  String dbWind(Object speed);

  /// No description provided for @dbGust.
  ///
  /// In vi, this message translates to:
  /// **'giật {speed} km/h'**
  String dbGust(Object speed);

  /// No description provided for @dbRain.
  ///
  /// In vi, this message translates to:
  /// **'mưa {mm} mm'**
  String dbRain(Object mm);

  /// No description provided for @dbUpdatedAt.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật {time}'**
  String dbUpdatedAt(Object time);

  /// No description provided for @dbSource.
  ///
  /// In vi, this message translates to:
  /// **'nguồn {source}'**
  String dbSource(Object source);

  /// No description provided for @dbWeatherOk.
  ///
  /// In vi, this message translates to:
  /// **'Thời tiết tuyến bay: Đủ điều kiện'**
  String get dbWeatherOk;

  /// No description provided for @dbWeatherUnknown.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xác nhận được thời tiết'**
  String get dbWeatherUnknown;

  /// No description provided for @dbWeatherSuspended.
  ///
  /// In vi, this message translates to:
  /// **'Thời tiết tuyến bay: Tạm ngưng bay'**
  String get dbWeatherSuspended;

  /// No description provided for @dbWeatherRefresh.
  ///
  /// In vi, this message translates to:
  /// **'Xem lại thời tiết'**
  String get dbWeatherRefresh;

  /// No description provided for @dbWeatherWindow.
  ///
  /// In vi, this message translates to:
  /// **'Dự báo {minutes} phút tới (thời gian giao dự kiến) từ nơi gửi → {locker} → tủ nhận'**
  String dbWeatherWindow(Object minutes, Object locker);

  /// No description provided for @dbWeatherOnlyWhenSafe.
  ///
  /// In vi, this message translates to:
  /// **'{message} Đơn chỉ đặt được khi trời đủ điều kiện bay.'**
  String dbWeatherOnlyWhenSafe(Object message);

  /// No description provided for @dtTitle.
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi giao drone'**
  String get dtTitle;

  /// No description provided for @dtCheckConnection.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng kiểm tra kết nối và thử lại.'**
  String get dtCheckConnection;

  /// No description provided for @dtConfirmDroppedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận đã bỏ kiện'**
  String get dtConfirmDroppedTitle;

  /// No description provided for @dtConfirmDroppedBody.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã bỏ kiện vào {where} và đóng cửa ô? Đội bay sẽ tới nạp hàng sau khi bạn xác nhận.'**
  String dtConfirmDroppedBody(Object where);

  /// No description provided for @dtDropped.
  ///
  /// In vi, this message translates to:
  /// **'Đã bỏ kiện'**
  String get dtDropped;

  /// No description provided for @dtDroppedDone.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi nhận. Đội bay sẽ tiếp nhận đơn của bạn.'**
  String get dtDroppedDone;

  /// No description provided for @dtCancelSurchargeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Huỷ đơn vì không đồng ý phụ thu'**
  String get dtCancelSurchargeTitle;

  /// No description provided for @dtCancelSurchargeBody.
  ///
  /// In vi, this message translates to:
  /// **'Đơn {code} sẽ bị huỷ. Phần bạn đã trả được ghi yêu cầu hoàn tiền và đội bay sẽ liên hệ để trả lại kiện. Không hoàn tác được.'**
  String dtCancelSurchargeBody(Object code);

  /// No description provided for @dtCancelledReturn.
  ///
  /// In vi, this message translates to:
  /// **'Đã huỷ đơn. Đội bay sẽ trả lại kiện cho bạn.'**
  String get dtCancelledReturn;

  /// No description provided for @dtMapSimulated.
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi trên bản đồ (mô phỏng)'**
  String get dtMapSimulated;

  /// No description provided for @dtMap.
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi trên bản đồ'**
  String get dtMap;

  /// No description provided for @dtInLockerShare.
  ///
  /// In vi, this message translates to:
  /// **'Kiện đã vào tủ nhận. Vào \"Xem chi tiết đơn\" để chia sẻ mã mở ô cho người nhận.'**
  String get dtInLockerShare;

  /// No description provided for @dtInLockerPickup.
  ///
  /// In vi, this message translates to:
  /// **'Kiện đã vào tủ nhận. Mở mã PIN để lấy hàng tại tủ.'**
  String get dtInLockerPickup;

  /// No description provided for @dtViewDetail.
  ///
  /// In vi, this message translates to:
  /// **'Xem chi tiết đơn'**
  String get dtViewDetail;

  /// No description provided for @dtPickup.
  ///
  /// In vi, this message translates to:
  /// **'Nhận hàng'**
  String get dtPickup;

  /// No description provided for @dtOffline.
  ///
  /// In vi, this message translates to:
  /// **'Mất kết nối · đang thử lại, thông tin bên dưới là lần cập nhật gần nhất'**
  String get dtOffline;

  /// No description provided for @dtLive.
  ///
  /// In vi, this message translates to:
  /// **'Đang cập nhật trực tiếp · trạng thái tự làm mới khi có thay đổi'**
  String get dtLive;

  /// No description provided for @dtLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được trạng thái giao hàng'**
  String get dtLoadFailed;

  /// No description provided for @rmNoCoordinates.
  ///
  /// In vi, this message translates to:
  /// **'Tủ gửi hoặc tủ nhận chưa có toạ độ nên chưa vẽ được bản đồ hành trình.'**
  String get rmNoCoordinates;

  /// No description provided for @rmZoomHint.
  ///
  /// In vi, this message translates to:
  /// **'Chụm/mở hai ngón hoặc bấm +/− để phóng to; bấm ⤢ để xem toàn màn hình.'**
  String get rmZoomHint;

  /// No description provided for @rmTotal.
  ///
  /// In vi, this message translates to:
  /// **'Quãng đường {distance}'**
  String rmTotal(Object distance);

  /// No description provided for @rmRemaining.
  ///
  /// In vi, this message translates to:
  /// **'Còn khoảng {distance}'**
  String rmRemaining(Object distance);

  /// No description provided for @rmLiveCoords.
  ///
  /// In vi, this message translates to:
  /// **'Toạ độ cập nhật mỗi khi drone gửi vị trí về. Bấm vào toạ độ để mở Google Maps.'**
  String get rmLiveCoords;

  /// No description provided for @rmEstimatedCamera.
  ///
  /// In vi, this message translates to:
  /// **'Vị trí drone ước theo chặng bay hiện tại. Số đo bay thật (GPS, pin, chế độ bay) xem ở khung camera phía trên.'**
  String get rmEstimatedCamera;

  /// No description provided for @rmEstimatedOpenMap.
  ///
  /// In vi, this message translates to:
  /// **'Vị trí drone ước theo chặng bay hiện tại. Mở \"Theo dõi trên bản đồ\" để xem vị trí {mode}.'**
  String rmEstimatedOpenMap(Object mode);

  /// No description provided for @rmSimulated.
  ///
  /// In vi, this message translates to:
  /// **'mô phỏng'**
  String get rmSimulated;

  /// No description provided for @rmLive.
  ///
  /// In vi, this message translates to:
  /// **'trực tiếp'**
  String get rmLive;

  /// No description provided for @rmEstimated.
  ///
  /// In vi, this message translates to:
  /// **'Vị trí drone ước theo chặng bay hiện tại.'**
  String get rmEstimated;

  /// No description provided for @rmZoomIn.
  ///
  /// In vi, this message translates to:
  /// **'Phóng to'**
  String get rmZoomIn;

  /// No description provided for @rmZoomOut.
  ///
  /// In vi, this message translates to:
  /// **'Thu nhỏ'**
  String get rmZoomOut;

  /// No description provided for @rmFitRoute.
  ///
  /// In vi, this message translates to:
  /// **'Xem cả tuyến'**
  String get rmFitRoute;

  /// No description provided for @rmFullscreen.
  ///
  /// In vi, this message translates to:
  /// **'Toàn màn hình'**
  String get rmFullscreen;

  /// No description provided for @rmRouteMap.
  ///
  /// In vi, this message translates to:
  /// **'Bản đồ hành trình'**
  String get rmRouteMap;

  /// No description provided for @rmDroneSentAt.
  ///
  /// In vi, this message translates to:
  /// **'Drone gửi về lúc {time}{suffix}'**
  String rmDroneSentAt(Object time, Object suffix);

  /// No description provided for @rmSimSuffix.
  ///
  /// In vi, this message translates to:
  /// **' · mô phỏng'**
  String get rmSimSuffix;

  /// No description provided for @rmAtReceiver.
  ///
  /// In vi, this message translates to:
  /// **'Tại tủ nhận'**
  String get rmAtReceiver;

  /// No description provided for @rmSimByStage.
  ///
  /// In vi, this message translates to:
  /// **'Mô phỏng theo chặng bay'**
  String get rmSimByStage;

  /// No description provided for @rmTelemetry.
  ///
  /// In vi, this message translates to:
  /// **'Theo telemetry của drone'**
  String get rmTelemetry;

  /// No description provided for @rmEstimatedByStage.
  ///
  /// In vi, this message translates to:
  /// **'Ước theo chặng bay'**
  String get rmEstimatedByStage;

  /// No description provided for @rmAtSourceNotLaunched.
  ///
  /// In vi, this message translates to:
  /// **'Tại tủ gửi, chưa cất cánh'**
  String get rmAtSourceNotLaunched;

  /// No description provided for @plServiceOff.
  ///
  /// In vi, this message translates to:
  /// **'Dịch vụ vị trí đang tắt. Vui lòng bật GPS.'**
  String get plServiceOff;

  /// No description provided for @plDenied.
  ///
  /// In vi, this message translates to:
  /// **'Quyền truy cập vị trí bị từ chối.'**
  String get plDenied;

  /// No description provided for @plDeniedForever.
  ///
  /// In vi, this message translates to:
  /// **'Quyền vị trí bị từ chối vĩnh viễn. Hãy bật lại trong cài đặt.'**
  String get plDeniedForever;

  /// No description provided for @plNoLocation.
  ///
  /// In vi, this message translates to:
  /// **'Không lấy được vị trí hiện tại.'**
  String get plNoLocation;

  /// No description provided for @plNoLocationHint.
  ///
  /// In vi, this message translates to:
  /// **'Không lấy được vị trí hiện tại. Hãy ra chỗ thoáng hoặc gõ địa chỉ để tìm.'**
  String get plNoLocationHint;

  /// No description provided for @plNoAddressForPoint.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tra được địa chỉ của điểm này. Hãy tự nhập địa chỉ bên dưới.'**
  String get plNoAddressForPoint;

  /// No description provided for @plMin3Chars.
  ///
  /// In vi, this message translates to:
  /// **'Nhập ít nhất 3 ký tự để tìm địa chỉ.'**
  String get plMin3Chars;

  /// No description provided for @plNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy địa chỉ này. Thử gõ rõ hơn hoặc chạm lên bản đồ để ghim.'**
  String get plNotFound;

  /// No description provided for @plNoPoint.
  ///
  /// In vi, this message translates to:
  /// **'Chưa chọn vị trí lấy hàng trên bản đồ.'**
  String get plNoPoint;

  /// No description provided for @plEnterAddress.
  ///
  /// In vi, this message translates to:
  /// **'Nhập địa chỉ lấy hàng (số nhà, đường, phường…).'**
  String get plEnterAddress;

  /// No description provided for @plTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chọn điểm lấy hàng'**
  String get plTitle;

  /// No description provided for @plSearchHint.
  ///
  /// In vi, this message translates to:
  /// **'Gõ địa chỉ (số nhà, đường, phường…)'**
  String get plSearchHint;

  /// No description provided for @plClear.
  ///
  /// In vi, this message translates to:
  /// **'Xoá'**
  String get plClear;

  /// No description provided for @plTapToSeePin.
  ///
  /// In vi, this message translates to:
  /// **'{lng} · chạm để xem ghim'**
  String plTapToSeePin(Object lng);

  /// No description provided for @plCurrentLocation.
  ///
  /// In vi, this message translates to:
  /// **'Vị trí hiện tại'**
  String get plCurrentLocation;

  /// No description provided for @plAddressField.
  ///
  /// In vi, this message translates to:
  /// **'Địa chỉ lấy hàng'**
  String get plAddressField;

  /// No description provided for @plTapMapToPin.
  ///
  /// In vi, this message translates to:
  /// **'Chạm lên bản đồ để ghim điểm lấy hàng'**
  String get plTapMapToPin;

  /// No description provided for @plPinInfo.
  ///
  /// In vi, this message translates to:
  /// **'Vĩ độ {lat} · kinh độ {lng} · vị trí ghim dùng để tính vùng phục vụ; kiểm tra ghim có đúng địa chỉ trước khi xác nhận'**
  String plPinInfo(Object lat, Object lng);

  /// No description provided for @plPickupHere.
  ///
  /// In vi, this message translates to:
  /// **'Lấy hàng tại đây'**
  String get plPickupHere;

  /// No description provided for @psLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được mã nhận hàng. Vui lòng thử lại.'**
  String get psLoadFailed;

  /// No description provided for @psReceivingLocker.
  ///
  /// In vi, this message translates to:
  /// **'Tủ nhận hàng'**
  String get psReceivingLocker;

  /// No description provided for @psNotInQueue.
  ///
  /// In vi, this message translates to:
  /// **'Không thấy đơn này trong hàng chờ nhận của bạn. Có thể đơn đã được lấy, hoặc mã nhận hàng được gửi cho số điện thoại khác.'**
  String get psNotInQueue;

  /// No description provided for @psDelegated.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã ủy quyền cho {name} lấy hộ đơn này nên mã nhận hàng đã chuyển cho người được ủy quyền.'**
  String psDelegated(Object name);

  /// No description provided for @psSomeoneElse.
  ///
  /// In vi, this message translates to:
  /// **'người khác'**
  String get psSomeoneElse;

  /// No description provided for @psNotReady.
  ///
  /// In vi, this message translates to:
  /// **'Mã nhận hàng chưa sẵn sàng. Mã sẽ có khi kiện đã vào ô tủ nhận.'**
  String get psNotReady;

  /// No description provided for @psPin.
  ///
  /// In vi, this message translates to:
  /// **'Mã PIN mở ô'**
  String get psPin;

  /// No description provided for @psEnterAtKiosk.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã này trên màn hình kiosk tại tủ để mở ô.'**
  String get psEnterAtKiosk;

  /// No description provided for @psReceiveBox.
  ///
  /// In vi, this message translates to:
  /// **'Ô nhận'**
  String get psReceiveBox;

  /// No description provided for @psPickupBefore.
  ///
  /// In vi, this message translates to:
  /// **'Lấy trước'**
  String get psPickupBefore;

  /// No description provided for @ocPaidRefund.
  ///
  /// In vi, this message translates to:
  /// **'Đơn đã thanh toán: {amount} sẽ được hoàn bằng chuyển khoản sau khi admin duyệt. Hãy kiểm tra tài khoản ngân hàng nhận tiền trong Hồ sơ.'**
  String ocPaidRefund(Object amount);

  /// No description provided for @ocDroneFee.
  ///
  /// In vi, this message translates to:
  /// **'phí giao drone'**
  String get ocDroneFee;

  /// No description provided for @ocUnpaidNoFee.
  ///
  /// In vi, this message translates to:
  /// **'Đơn chưa thanh toán nên không phát sinh phí.'**
  String get ocUnpaidNoFee;

  /// No description provided for @ocTitle.
  ///
  /// In vi, this message translates to:
  /// **'Huỷ đơn giao drone?'**
  String get ocTitle;

  /// No description provided for @ocBody.
  ///
  /// In vi, this message translates to:
  /// **'Đơn {code} sẽ bị huỷ và ô nhận đã giữ cho đơn được nhả. {refund}'**
  String ocBody(Object code, Object refund);

  /// No description provided for @ocRefundPending.
  ///
  /// In vi, this message translates to:
  /// **'Đã huỷ đơn. Yêu cầu hoàn tiền đã được ghi nhận, admin sẽ chuyển khoản cho bạn.'**
  String get ocRefundPending;

  /// No description provided for @ocRefunded.
  ///
  /// In vi, this message translates to:
  /// **'Đã huỷ đơn. Tiền đã được chuyển khoản hoàn cho bạn.'**
  String get ocRefunded;

  /// No description provided for @ocPaidNoRefund.
  ///
  /// In vi, this message translates to:
  /// **'Đã huỷ đơn. Chưa ghi nhận được yêu cầu hoàn tiền, vui lòng liên hệ hỗ trợ.'**
  String get ocPaidNoRefund;

  /// No description provided for @ocCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Đã huỷ đơn.'**
  String get ocCancelled;

  /// No description provided for @ocAlreadyAccepted.
  ///
  /// In vi, this message translates to:
  /// **'Đội bay đã tiếp nhận nên đơn không còn huỷ được trong ứng dụng.'**
  String get ocAlreadyAccepted;

  /// No description provided for @ocOwnerOnly.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ người đặt đơn mới huỷ được đơn này.'**
  String get ocOwnerOnly;

  /// No description provided for @lmTitleSimulated.
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi drone · mô phỏng'**
  String get lmTitleSimulated;

  /// No description provided for @lmSignalLost.
  ///
  /// In vi, this message translates to:
  /// **'Mất tín hiệu · vị trí lúc {time}'**
  String lmSignalLost(Object time);

  /// No description provided for @lmConnecting.
  ///
  /// In vi, this message translates to:
  /// **'Đang kết nối tới drone...'**
  String get lmConnecting;

  /// No description provided for @lmNoPosition.
  ///
  /// In vi, this message translates to:
  /// **'Chưa nhận được vị trí drone. Đang thử lại...'**
  String get lmNoPosition;

  /// No description provided for @lmOnTheWay.
  ///
  /// In vi, this message translates to:
  /// **'Đang trên đường tới tủ nhận'**
  String get lmOnTheWay;

  /// No description provided for @lmAlmostThere.
  ///
  /// In vi, this message translates to:
  /// **'Sắp tới nơi'**
  String get lmAlmostThere;

  /// No description provided for @lmEta.
  ///
  /// In vi, this message translates to:
  /// **'Dự kiến đến'**
  String get lmEta;

  /// No description provided for @lmSpeed.
  ///
  /// In vi, this message translates to:
  /// **'Tốc độ'**
  String get lmSpeed;

  /// No description provided for @lmLiveSimulated.
  ///
  /// In vi, this message translates to:
  /// **'mô phỏng · cập nhật trực tiếp'**
  String get lmLiveSimulated;

  /// No description provided for @lmLiveUpdates.
  ///
  /// In vi, this message translates to:
  /// **'cập nhật trực tiếp'**
  String get lmLiveUpdates;

  /// No description provided for @clCantOpenMaps.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được Google Maps.'**
  String get clCantOpenMaps;

  /// No description provided for @clCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã copy toạ độ {coords}'**
  String clCopied(Object coords);

  /// No description provided for @clDronePosition.
  ///
  /// In vi, this message translates to:
  /// **'Vị trí drone · {note}'**
  String clDronePosition(Object note);

  /// No description provided for @clCopyCoords.
  ///
  /// In vi, this message translates to:
  /// **'Copy toạ độ'**
  String get clCopyCoords;

  /// No description provided for @clPickupPin.
  ///
  /// In vi, this message translates to:
  /// **'Điểm lấy hàng người gửi ghim'**
  String get clPickupPin;

  /// No description provided for @clTechnician.
  ///
  /// In vi, this message translates to:
  /// **'Vị trí kỹ thuật viên lúc đó'**
  String get clTechnician;

  /// No description provided for @clSourceLocker.
  ///
  /// In vi, this message translates to:
  /// **'Tại trạm/tủ gửi'**
  String get clSourceLocker;

  /// No description provided for @clDroneGps.
  ///
  /// In vi, this message translates to:
  /// **'Vị trí drone (GPS)'**
  String get clDroneGps;

  /// No description provided for @clDroneSim.
  ///
  /// In vi, this message translates to:
  /// **'Vị trí drone (mô phỏng)'**
  String get clDroneSim;

  /// No description provided for @clDestination.
  ///
  /// In vi, this message translates to:
  /// **'Tại tủ nhận'**
  String get clDestination;

  /// No description provided for @clAtEvent.
  ///
  /// In vi, this message translates to:
  /// **'Vị trí lúc ghi mốc'**
  String get clAtEvent;

  /// No description provided for @lpIntro.
  ///
  /// In vi, this message translates to:
  /// **'Chọn tủ nhận hàng (ưu tiên sắp xếp gần bạn nhất). Hệ thống tự chọn tủ bay và KTV đến lấy kiện tại nhà.'**
  String get lpIntro;

  /// No description provided for @lpLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được danh sách tủ: {error}'**
  String lpLoadFailed(Object error);

  /// No description provided for @lpNoLockers.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có tủ nào trên hệ thống.'**
  String get lpNoLockers;

  /// No description provided for @lpDistance.
  ///
  /// In vi, this message translates to:
  /// **'Cách bạn {distance}'**
  String lpDistance(Object distance);

  /// No description provided for @lpChecking.
  ///
  /// In vi, this message translates to:
  /// **'Đang kiểm tra ô drone nhận'**
  String get lpChecking;

  /// No description provided for @lpFreeSlots.
  ///
  /// In vi, this message translates to:
  /// **'Còn {count} ô drone nhận trống'**
  String lpFreeSlots(Object count);

  /// No description provided for @lpUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Tạm không gửi drone: {reason}'**
  String lpUnavailable(Object reason);

  /// No description provided for @asTitle.
  ///
  /// In vi, this message translates to:
  /// **'Drone sắp đến nơi'**
  String get asTitle;

  /// No description provided for @asPrepare.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng chuẩn bị ra nhận hàng.'**
  String get asPrepare;

  /// No description provided for @asDroneCode.
  ///
  /// In vi, this message translates to:
  /// **'\nMã drone: {code}'**
  String asDroneCode(Object code);

  /// No description provided for @asEta.
  ///
  /// In vi, this message translates to:
  /// **'Dự kiến: {eta}'**
  String asEta(Object eta);

  /// No description provided for @opPaid.
  ///
  /// In vi, this message translates to:
  /// **'Đã thanh toán. Đội bay sẽ tiếp nhận đơn của bạn.'**
  String get opPaid;

  /// No description provided for @opPending.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ xác nhận thanh toán, trạng thái sẽ tự cập nhật.'**
  String get opPending;

  /// No description provided for @opFailed.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán chưa thành công. Đơn vẫn được giữ, bạn có thể thanh toán lại.'**
  String get opFailed;

  /// No description provided for @opUnpaid.
  ///
  /// In vi, this message translates to:
  /// **'Đơn drone chưa thanh toán. Thanh toán để đội bay tiếp nhận.'**
  String get opUnpaid;

  /// No description provided for @tlMovedAfter.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển sau {duration}'**
  String tlMovedAfter(Object duration);

  /// No description provided for @tlInStageFor.
  ///
  /// In vi, this message translates to:
  /// **'Đã ở chặng này {duration}'**
  String tlInStageFor(Object duration);

  /// No description provided for @tlNotYet.
  ///
  /// In vi, this message translates to:
  /// **'Chưa diễn ra'**
  String get tlNotYet;
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
