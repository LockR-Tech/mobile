// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get commonRetry => 'Thử lại';

  @override
  String get commonCancel => 'Hủy';

  @override
  String get commonLogout => 'Đăng xuất';

  @override
  String get commonLoggingOut => 'Đang đăng xuất...';

  @override
  String get commonLoggedOut => 'Đã đăng xuất';

  @override
  String get commonLogoutConfirm =>
      'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản?';

  @override
  String get commonNotifications => 'Thông báo';

  @override
  String get commonTransactions => 'Giao dịch';

  @override
  String get commonPayment => 'Thanh toán';

  @override
  String get commonWebsite => 'Website';

  @override
  String get commonTermsOfUse => 'Điều khoản sử dụng';

  @override
  String get commonPrivacyPolicy => 'Chính sách bảo mật';

  @override
  String get languageVietnamese => 'Tiếng Việt';

  @override
  String get languageEnglish => 'English';

  @override
  String get profileTitle => 'Hồ sơ';

  @override
  String get profileSubtitle => 'Quản lý tài khoản của bạn';

  @override
  String get profileLoading => 'Đang tải hồ sơ...';

  @override
  String get profileLoadFailed => 'Không tải được hồ sơ';

  @override
  String get profileLoadFailedDot => 'Không tải được hồ sơ.';

  @override
  String profileRefreshFailed(Object error) {
    return 'Không làm mới được hồ sơ: $error';
  }

  @override
  String get profileSectionAccount => 'Tài khoản';

  @override
  String get profilePersonalInfo => 'Thông tin cá nhân';

  @override
  String get profileRefundAccount => 'Tài khoản nhận hoàn tiền';

  @override
  String get profileLoyalty => 'Điểm thưởng';

  @override
  String get profileLoyaltySubtitle =>
      'Điểm tích lũy, hạng thành viên và lịch sử';

  @override
  String get profileFaceReRegister => 'Đăng ký lại khuôn mặt';

  @override
  String get profileFaceRegister => 'Đăng ký khuôn mặt';

  @override
  String get profileSecurity => 'Bảo mật';

  @override
  String get profileVouchers => 'Ưu đãi & Quà tặng';

  @override
  String get profileSectionManage => 'Quản lý';

  @override
  String get profileDelegations => 'Đơn ủy quyền';

  @override
  String get profileRefunds => 'Hoàn tiền';

  @override
  String get profileMyReports => 'Báo cáo của tôi';

  @override
  String get profileBleTest => 'Thử mở ô qua Bluetooth';

  @override
  String get profileSectionSettings => 'Cài đặt';

  @override
  String get profileLanguage => 'Ngôn ngữ';

  @override
  String get profileLanguageSheetSubtitle =>
      'Chọn ngôn ngữ hiển thị cho ứng dụng';

  @override
  String get profileLanguageViDescription => 'Hiển thị bằng tiếng Việt';

  @override
  String get profileLanguageEnDescription => 'Hiển thị bằng tiếng Anh';

  @override
  String get profileTheme => 'Giao diện';

  @override
  String get profileLocation => 'Vị trí';

  @override
  String get profileLocationSubtitle =>
      'Quyền truy cập vị trí để tìm tủ gần bạn';

  @override
  String get profileSectionSupport => 'Hỗ trợ';

  @override
  String get profileAssistant => 'Trợ lý AI Lock.R';

  @override
  String get profileAssistantSubtitle => 'Hỏi đáp & hỗ trợ thông minh 24/7';

  @override
  String get profileQuickHelp => 'Trợ giúp nhanh';

  @override
  String get profileQuickHelpSubtitle =>
      'Hướng dẫn sử dụng & câu hỏi thường gặp';

  @override
  String get profileContact => 'Liên hệ';

  @override
  String get profileTerms => 'Điều khoản';

  @override
  String get profileHelpSendTitle => 'Gửi hàng';

  @override
  String get profileHelpSendBody =>
      'Chọn cửa hàng → chạm ô trống → Gửi hàng → thanh toán → dùng PIN/nút \"Mở tủ\" để bỏ hàng.';

  @override
  String get profileHelpRentTitle => 'Thuê tủ giữ đồ';

  @override
  String get profileHelpRentBody =>
      'Chọn ô trống → Thuê tủ → chọn số giờ → thanh toán → PIN dùng nhiều lần tới hết hạn.';

  @override
  String get profileHelpCantOpenTitle => 'Không mở được ô?';

  @override
  String get profileHelpCantOpenBody =>
      'Vào Đơn tủ → mở đơn → \"Báo ô lỗi\". Đội bảo trì sẽ xử lý và bạn nhận được thông báo.';

  @override
  String get profileHelpPaymentBody =>
      'Mọi đơn thanh toán bằng chuyển khoản SePay (VietQR): quét mã hoặc bấm \"Thanh toán bằng app ngân hàng\" để mở app ngân hàng điền sẵn. Xem lại các khoản đã trả ở mục Giao dịch.';

  @override
  String get profileContactTitle => 'Liên hệ hỗ trợ';

  @override
  String get profileContactEmail => 'Email hỗ trợ';

  @override
  String get profileContactHours => 'Giờ hỗ trợ';

  @override
  String get profileContactHoursValue => '08:00 – 22:00 hằng ngày';

  @override
  String get profileThemeSheetSubtitle => 'Chọn chủ đề hiển thị cho ứng dụng';

  @override
  String get profileThemeLight => 'Sáng';

  @override
  String get profileThemeLightDescription => 'Giao diện nền trắng';

  @override
  String get profileThemeDark => 'Tối';

  @override
  String get profileThemeDarkDescription => 'Giao diện nền tối';

  @override
  String get profileThemeSystem => 'Theo hệ thống';

  @override
  String get profileThemeSystemDescription => 'Tự động theo cài đặt thiết bị';

  @override
  String get commonConfirm => 'Xác nhận';

  @override
  String get commonContinue => 'Tiếp tục';

  @override
  String get commonSave => 'Lưu';

  @override
  String get commonLater => 'Để sau';

  @override
  String get commonLoading => 'Đang tải...';

  @override
  String get commonFullName => 'Họ và tên';

  @override
  String get commonFullNameHint => 'Nguyễn Văn A';

  @override
  String get commonEmail => 'Email';

  @override
  String get commonPhoneNumber => 'Số điện thoại';

  @override
  String get commonPassword => 'Mật khẩu';

  @override
  String get commonPhoneShort => 'SĐT';

  @override
  String get authLogin => 'Đăng nhập';

  @override
  String get authRegister => 'Đăng ký';

  @override
  String get authCreateAccount => 'Tạo tài khoản';

  @override
  String get authRegisterSuccess => 'Đăng ký thành công!';

  @override
  String get authRegisterSuccessPleaseLogin =>
      'Đăng ký thành công! Vui lòng đăng nhập.';

  @override
  String get authEnterIdentifierAndPassword => 'Nhập email/SĐT và mật khẩu';

  @override
  String get authPleaseAcceptTerms => 'Vui lòng đồng ý với Điều khoản sử dụng';

  @override
  String get authTagline => 'Tủ thông minh • Giao nhận 24/7';

  @override
  String get authEmailOrPhone => 'Email / Số điện thoại';

  @override
  String get authLoginWithOtp => 'Đăng nhập bằng OTP';

  @override
  String get authForgotPasswordQuestion => 'Quên mật khẩu?';

  @override
  String get authEnterFullName => 'Vui lòng nhập họ và tên';

  @override
  String get authEnterEmail => 'Vui lòng nhập email';

  @override
  String get authInvalidEmail => 'Email không hợp lệ';

  @override
  String get authEnterPhone => 'Vui lòng nhập số điện thoại';

  @override
  String get authEnterPassword => 'Vui lòng nhập mật khẩu';

  @override
  String get authPasswordMin6 => 'Mật khẩu phải có ít nhất 6 ký tự';

  @override
  String get authAgreePrefix => 'Tôi đồng ý với ';

  @override
  String get authOrContinueWith => 'Hoặc tiếp tục với';

  @override
  String get authNoAccount => 'Chưa có tài khoản? ';

  @override
  String get authHaveAccount => 'Đã có tài khoản? ';

  @override
  String get authRegisterNow => 'Đăng ký ngay';

  @override
  String get authEnterValidEmailForOtp =>
      'Vui lòng nhập Email hợp lệ để nhận OTP';

  @override
  String get authEnterOtp => 'Nhập mã OTP';

  @override
  String authOtpSentTo(Object email) {
    return 'Mã OTP đã được gửi đến $email';
  }

  @override
  String authOtpSendingTo(Object email) {
    return 'Đang gửi mã OTP đến $email...';
  }

  @override
  String get authOtp6Digits => 'Mã OTP (6 số)';

  @override
  String get authPasswordHint => 'Nhập mật khẩu';

  @override
  String get authFaceLogin => 'Đăng nhập khuôn mặt';

  @override
  String get authRegisterFailedRetry => 'Đăng ký thất bại. Vui lòng thử lại.';

  @override
  String get authFaceMismatch => 'Khuôn mặt không khớp hoặc chưa được đăng ký';

  @override
  String get authFaceAiBusy => 'Hệ thống AI đang bận hoặc ảnh không hợp lệ';

  @override
  String get authLoginFailedRetry => 'Đăng nhập thất bại. Vui lòng thử lại.';

  @override
  String get authNoTokenFromServer =>
      'Không nhận được token xác thực từ server.';

  @override
  String get authFaceRegisterFailed => 'Đăng ký khuôn mặt thất bại';

  @override
  String get authEmailNotRegistered =>
      'Email chưa được đăng ký tài khoản. Vui lòng kiểm tra lại.';

  @override
  String get authOtpInvalidOrExpired => 'Mã OTP không hợp lệ hoặc đã hết hạn.';

  @override
  String get authPasswordsDontMatch => 'Mật khẩu nhập lại không khớp.';

  @override
  String get authResetPasswordFailed =>
      'Không thể đặt lại mật khẩu. Vui lòng thử lại.';

  @override
  String get authEmailTaken =>
      'Email đã được đăng ký. Vui lòng dùng email khác.';

  @override
  String get authPhoneTaken =>
      'Số điện thoại đã được đăng ký. Vui lòng dùng số khác.';

  @override
  String get authEmailOrPhoneTaken =>
      'Email hoặc số điện thoại đã được đăng ký.';

  @override
  String get authRegisterServerError =>
      'Lỗi server khi đăng ký. Vui lòng thử lại.';

  @override
  String get authOtpServerTokenError =>
      'Mã OTP đúng nhưng hệ thống xác thực đang lỗi nội bộ (chưa trả được token). Vui lòng thử lại sau ít phút.';

  @override
  String get authOtpVerifyFailed => 'Không thể xác thực OTP. Vui lòng thử lại.';

  @override
  String get authResetPasswordSuccess =>
      'Đặt lại mật khẩu thành công. Vui lòng đăng nhập bằng mật khẩu mới.';

  @override
  String get authEnterValidEmail => 'Vui lòng nhập email hợp lệ.';

  @override
  String get authOtpMustBe6Digits => 'Mã OTP gồm 6 chữ số.';

  @override
  String get authNewPasswordMin6 => 'Mật khẩu mới phải có ít nhất 6 ký tự.';

  @override
  String get authForgotPasswordTitle => 'Quên mật khẩu';

  @override
  String get authEnterOtpAndNewPassword => 'Nhập mã OTP & mật khẩu mới';

  @override
  String get authResetPassword => 'Đặt lại mật khẩu';

  @override
  String authResetOtpSentTo(Object email) {
    return 'Mã OTP gồm 6 chữ số đã được gửi tới\n$email (hết hạn sau 5 phút).';
  }

  @override
  String get authResetEnterEmail =>
      'Nhập email đã đăng ký tài khoản.\nChúng tôi sẽ gửi mã OTP để đặt lại mật khẩu.';

  @override
  String get authSendOtp => 'Gửi mã OTP';

  @override
  String get authResendOtp => 'Gửi lại mã OTP';

  @override
  String get authOtpCode => 'Mã OTP';

  @override
  String get authNewPassword => 'Mật khẩu mới';

  @override
  String get authConfirmNewPassword => 'Nhập lại mật khẩu mới';

  @override
  String get authPhoneLogin => 'Đăng nhập bằng số điện thoại';

  @override
  String authSmsSentTo(Object phone) {
    return 'Mã 6 số đã được gửi qua SMS tới $phone.';
  }

  @override
  String get authYourNumber => 'số của bạn';

  @override
  String get authPhoneAutoCreateAccount =>
      'Chưa có tài khoản? Hệ thống tự tạo tài khoản khi bạn xác nhận mã.';

  @override
  String get authPhoneFormatHint =>
      'Nhập số nội địa (0xxx) hoặc quốc tế (+84xxx) đều được.';

  @override
  String get authChangePhone => 'Đổi số điện thoại';

  @override
  String authResendCodeIn(Object seconds) {
    return 'Gửi lại mã (${seconds}s)';
  }

  @override
  String get authResendCode => 'Gửi lại mã';

  @override
  String get authProfileSaved => 'Đã lưu thông tin tài khoản';

  @override
  String get authProfileSaveFailed =>
      'Không lưu được thông tin. Vui lòng thử lại.';

  @override
  String get authCompleteRegistration => 'Hoàn tất đăng ký';

  @override
  String get authCompleteRegistrationBody =>
      'Cho chúng tôi biết tên của bạn để hiển thị trên đơn hàng và khi liên hệ hỗ trợ.';

  @override
  String get authEmailOptional => 'Email (không bắt buộc)';

  @override
  String get authBiometricReason => 'Xác thực để mở Lock.R';

  @override
  String get authSplashTagline => 'Hệ thống tủ khóa thông minh 24/7';

  @override
  String get authBiometricRequired => 'Cần xác thực sinh trắc học để tiếp tục';

  @override
  String get authBiometricButton => 'Xác thực vân tay / Face ID';

  @override
  String get authLogoutUsePassword => 'Đăng xuất và dùng mật khẩu';

  @override
  String get authGoogleLoginFailed => 'Đăng nhập Google thất bại';

  @override
  String get authFacebookLoginFailed => 'Đăng nhập Facebook thất bại';

  @override
  String get authOtp6DigitsShort => 'Mã OTP gồm 6 chữ số';

  @override
  String get authOtpConfirmFailed =>
      'Không xác nhận được mã OTP. Vui lòng thử lại.';

  @override
  String get authOtpVerification => 'Xác thực OTP';

  @override
  String get authCaptureFaceFirst => 'Vui lòng lấy mẫu khuôn mặt trước';

  @override
  String get authPhoneLoginDisabled =>
      'Đăng nhập bằng SĐT chưa được bật. Vui lòng dùng email để đăng nhập.';

  @override
  String get authOtpSendFailed => 'Không gửi được mã OTP. Vui lòng thử lại.';

  @override
  String get authInvalidPhone =>
      'Số điện thoại không hợp lệ. Vui lòng kiểm tra lại (VD: 0912345678).';

  @override
  String get authTooManyRequests =>
      'Bạn đã yêu cầu mã quá nhiều lần. Vui lòng thử lại sau ít phút.';

  @override
  String get authSmsQuotaExceeded =>
      'Hệ thống đã hết lượt gửi SMS trong hôm nay. Vui lòng thử lại sau hoặc đăng nhập bằng email.';

  @override
  String get authOtpWrong => 'Mã OTP không đúng. Vui lòng kiểm tra lại.';

  @override
  String get authEnterOtpCode => 'Vui lòng nhập mã OTP.';

  @override
  String get authOtpExpired =>
      'Mã OTP đã hết hạn. Vui lòng bấm \"Gửi lại mã\".';

  @override
  String get authAppNotVerified =>
      'Ứng dụng chưa được xác minh để gửi mã OTP. Vui lòng cập nhật ứng dụng hoặc dùng email để đăng nhập.';

  @override
  String get authRecaptchaFailed =>
      'Xác minh reCAPTCHA không thành công. Vui lòng thử lại.';

  @override
  String get authSitePhoneNotAllowed =>
      'Trang web này chưa được phép đăng nhập bằng SĐT. Vui lòng dùng email để đăng nhập.';

  @override
  String get authNoNetwork =>
      'Không có kết nối mạng. Vui lòng kiểm tra Internet rồi thử lại.';

  @override
  String get authAccountDisabled =>
      'Tài khoản này đã bị khoá. Vui lòng liên hệ hỗ trợ.';

  @override
  String get authVerificationCancelled => 'Đã huỷ xác minh. Vui lòng thử lại.';

  @override
  String get authGooglePopupBlocked =>
      'Trình duyệt đã chặn cửa sổ đăng nhập Google. Hãy cho phép cửa sổ bật lên rồi thử lại.';

  @override
  String get authGoogleLoginDisabled =>
      'Đăng nhập bằng Google chưa được bật. Vui lòng dùng email để đăng nhập.';

  @override
  String get authSiteGoogleNotAllowed =>
      'Trang web này chưa được phép đăng nhập bằng Google. Vui lòng dùng email để đăng nhập.';

  @override
  String get authGoogleEmailOtherProvider =>
      'Email Google này đã gắn với cách đăng nhập khác. Vui lòng đăng nhập bằng cách bạn đã dùng trước đó.';

  @override
  String get authSessionVerifyFailed =>
      'Không xác thực được phiên đăng nhập. Vui lòng thử lại.';
}
