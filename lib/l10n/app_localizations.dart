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
