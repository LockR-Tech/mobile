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

  @override
  String get commonCancelAlt => 'Huỷ';

  @override
  String get commonClose => 'Đóng';

  @override
  String get commonDone => 'Hoàn tất';

  @override
  String get commonGotIt => 'Đã hiểu';

  @override
  String get commonOpenSettings => 'Mở Cài đặt';

  @override
  String get commonSearchHint => 'Tìm kiếm...';

  @override
  String get commonSeeAll => 'XEM TẤT CẢ';

  @override
  String get commonLoginRequiredFeature =>
      'Bạn cần đăng nhập để sử dụng tính năng này';

  @override
  String get commonLoginTitleCase => 'Đăng Nhập';

  @override
  String get commonRegisterTitleCase => 'Đăng Ký';

  @override
  String get commonBrandEyebrow => 'LOCK.R • HỆ THỐNG TỦ THÔNG MINH';

  @override
  String get commonUnknown => 'Không xác định';

  @override
  String get commonUndetermined => 'Chưa xác định';

  @override
  String get commonError => 'Lỗi';

  @override
  String get commonSuccess => 'Thành công';

  @override
  String get commonFailed => 'Thất bại';

  @override
  String get commonPending => 'Đang chờ';

  @override
  String deadlineAt(Object time, Object date) {
    return '$time ngày $date';
  }

  @override
  String get navHome => 'Trang chủ';

  @override
  String get navLockers => 'Tủ';

  @override
  String get navAssistant => 'Trợ lý AI';

  @override
  String get navOrders => 'Đơn hàng';

  @override
  String get navProfile => 'Hồ sơ';

  @override
  String get routerPolicy => 'Chính sách';

  @override
  String get routerMissingDestination => 'Thiếu toạ độ điểm đến.';

  @override
  String get routerDestination => 'Điểm đến';

  @override
  String get backPressAgainToExit => 'Bấm quay lại lần nữa để thoát';

  @override
  String get paymentMethodUnsupported =>
      'Phương thức thanh toán này không còn được hỗ trợ. Vui lòng thanh toán bằng chuyển khoản SePay (VietQR).';

  @override
  String get qrExpired => 'Mã QR hết hạn hoặc phiên đã hết hạn.';

  @override
  String get qrAlreadyUsed => 'Mã QR đã được sử dụng.';

  @override
  String get errorTimeout => 'Kết nối timeout. Vui lòng thử lại.';

  @override
  String get errorCannotConnect =>
      'Không thể kết nối đến server. Kiểm tra kết nối mạng.';

  @override
  String get errorRequestCancelled => 'Request đã bị hủy.';

  @override
  String get errorUnknown => 'Đã xảy ra lỗi không xác định.';

  @override
  String get errorNoResponse => 'Không có response từ server.';

  @override
  String get errorSessionExpired =>
      'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';

  @override
  String get errorForbidden => 'Bạn không có quyền thực hiện hành động này.';

  @override
  String get errorSystemBusy =>
      'Hệ thống đang bận hoặc đang bảo trì. Vui lòng thử lại sau ít phút.';

  @override
  String get errorServer => 'Lỗi server. Vui lòng thử lại sau.';

  @override
  String get errorNotSupportedYet =>
      'Máy chủ chưa hỗ trợ chức năng này. Vui lòng thử lại sau.';

  @override
  String get errorGenericRetry => 'Đã xảy ra lỗi. Vui lòng thử lại.';

  @override
  String bleOpenedBox(Object box) {
    return 'Đã mở ô $box';
  }

  @override
  String get bleNotFound =>
      'Không thấy tủ qua Bluetooth. Hãy đứng sát tủ (dưới 2 m) rồi thử lại.';

  @override
  String get bleConnectFailed =>
      'Không kết nối được Bluetooth với tủ. Thử lại sau vài giây.';

  @override
  String get bleNoService =>
      'Tủ chưa bật chức năng mở ô qua Bluetooth (bộ điều khiển cần cập nhật).';

  @override
  String get bleTimeout =>
      'Tủ không trả lời. Kiểm tra ô đã mở chưa rồi thử lại.';

  @override
  String get bleOff => 'Bluetooth của điện thoại đang tắt.';

  @override
  String get blePermissionDenied => 'App chưa được cấp quyền Bluetooth.';

  @override
  String get bleUnsupported =>
      'Thiết bị này không hỗ trợ Bluetooth (chỉ dùng được trên app Android/iOS).';

  @override
  String get bleBadCode => 'Tủ không chấp nhận mã mở ô.';

  @override
  String get bleExpired => 'Mã mở ô đã hết hạn. Bấm mở lại để lấy mã mới.';

  @override
  String get bleReplayed => 'Mã này đã dùng rồi. Bấm mở lại để lấy mã mới.';

  @override
  String get bleWrongLocker => 'Bạn đang kết nối nhầm tủ.';

  @override
  String get bleNoKey =>
      'Tủ chưa tải được khoá kiểm mã từ máy chủ (cần có mạng một lần).';

  @override
  String get bleNotConfigured => 'Tủ chưa được gán trên hệ thống.';

  @override
  String get bleInvalidSlot =>
      'Ô này không có khoá điện nối vào bộ điều khiển.';

  @override
  String bleOpenFailed(Object suffix) {
    return 'Mở ô không thành công$suffix.';
  }

  @override
  String bleVeryClose(Object distance) {
    return 'Rất gần (~${distance}m)';
  }

  @override
  String bleNear(Object distance) {
    return 'Gần tủ (~${distance}m)';
  }

  @override
  String bleAway(Object distance) {
    return 'Cách tủ ~${distance}m';
  }

  @override
  String get notifEnableTitle => 'Bật thông báo';

  @override
  String get notifEnableBody =>
      'Bạn đã tắt quyền thông báo nên sẽ không nhận được cập nhật trạng thái giao hàng. Hãy vào Cài đặt để bật lại thông báo cho ứng dụng.';

  @override
  String get notifNew => 'Thông báo mới';

  @override
  String get biometricOpenApp => 'Xác thực để mở ứng dụng';

  @override
  String get enumLockerToLocker => 'Giao từ tủ qua tủ';

  @override
  String get enumHomeToLocker => 'Giao từ nhà tới tủ';

  @override
  String get enumPendingProcessing => 'Đang chờ xử lý';

  @override
  String get enumAwaitingCourier => 'Chờ người giao hàng';

  @override
  String get enumAwaitingPickup => 'Chờ lấy hàng';

  @override
  String get enumActive => 'Đang hoạt động';

  @override
  String get enumCompleted => 'Đã hoàn tất';

  @override
  String get enumLockedByBalance => 'Bị khóa do số dư';

  @override
  String get enumCancelled => 'Đã hủy';

  @override
  String get enumPending => 'Chờ xử lý';

  @override
  String get enumAwaitingDropoffConfirm => 'Chờ xác nhận gửi hàng';

  @override
  String get enumInTransit => 'Đang vận chuyển';

  @override
  String get enumInUse => 'Đang sử dụng';

  @override
  String get enumOverdue => 'Quá hạn';

  @override
  String get enumConsolidating => 'Đang gom hàng';

  @override
  String get enumPickedUp => 'Đã lấy hàng';

  @override
  String get enumAwaitingDropoff => 'Chờ gửi hàng';

  @override
  String get enumAwaitingPayment => 'Chờ thanh toán';

  @override
  String get enumUnpaid => 'Chưa thanh toán';

  @override
  String get enumPaid => 'Đã thanh toán';

  @override
  String get enumPartiallyPaid => 'Thanh toán một phần';

  @override
  String get enumAwaitingRefund => 'Chờ hoàn tiền';

  @override
  String get enumRefunded => 'Đã hoàn tiền';

  @override
  String get enumTopUp => 'Nạp tiền';

  @override
  String get enumRentalFee => 'Phí thuê tủ';

  @override
  String get enumShippingFee => 'Phí vận chuyển';

  @override
  String get enumOverdueFee => 'Phí quá hạn';

  @override
  String get enumRefund => 'Hoàn tiền';

  @override
  String get enumWalletTopUp => 'Nạp tiền vào ví';

  @override
  String get enumWithdraw => 'Rút tiền';

  @override
  String get enumShippingService => 'Dịch vụ vận chuyển';

  @override
  String get enumPersonalRental => 'Thuê tủ cá nhân';

  @override
  String get enumReady => 'Sẵn sàng';

  @override
  String get enumReserved => 'Đã đặt trước';

  @override
  String get enumLockedBalanceShort => 'Khóa do số dư';

  @override
  String get enumFaulty => 'Bị lỗi';

  @override
  String get enumPendingCheck => 'Chờ kiểm tra';

  @override
  String get enumMaintenance => 'Bảo trì';

  @override
  String get enumInitializing => 'Đang khởi tạo';

  @override
  String get enumLocked => 'Đã khóa';

  @override
  String get enumUnlocked => 'Đã mở khóa';

  @override
  String get enumOpen => 'Đang mở';

  @override
  String get enumClosed => 'Đã đóng';

  @override
  String get enumOpening => 'Đang mở...';

  @override
  String get enumClosing => 'Đang đóng...';

  @override
  String get enumOffline => 'Ngoại tuyến';

  @override
  String get enumFood => 'Thực phẩm';

  @override
  String get enumOther => 'Khác';

  @override
  String get unitMinute => 'phút';

  @override
  String get unitHour => 'giờ';

  @override
  String get unitDay => 'ngày';

  @override
  String get unitWeek => 'tuần';

  @override
  String get unitMonth => 'tháng';

  @override
  String minutesShort(Object minutes) {
    return '$minutes phút';
  }

  @override
  String get qrSendingOpen => 'Đang gửi lệnh mở ô...';

  @override
  String get qrOpenedTest => 'Đã mở ô (thử tủ)';

  @override
  String get qrNotOpened => 'Chưa mở được ô';

  @override
  String qrLockerBox(Object locker, Object box) {
    return 'Tủ #$locker · ô #$box';
  }

  @override
  String get qrNotLockrCode =>
      'Đây không phải mã đăng nhập kiosk hay mã mở ô Lock.R. Hãy quét mã QR đang hiện trên màn hình tủ.';

  @override
  String get qrConfirmingKiosk => 'Đang xác nhận đăng nhập kiosk...';

  @override
  String qrAtLocker(Object name) {
    return ' tại $name';
  }

  @override
  String qrKioskLoggedIn(Object where) {
    return 'Đã đăng nhập trên kiosk$where';
  }

  @override
  String get qrKioskLoginFailedTitle => 'Chưa đăng nhập được kiosk';

  @override
  String get qrKioskLoginFailed =>
      'Không xác nhận được đăng nhập kiosk. Vui lòng thử lại.';

  @override
  String get qrScan => 'Quét mã QR';

  @override
  String get qrLoginToScan => 'Bạn cần đăng nhập để quét mã QR';

  @override
  String get qrKioskLoginByQr => 'Đăng nhập kiosk bằng QR';

  @override
  String get qrAimHint =>
      'Đưa khung vào mã QR trên màn hình kiosk. Bạn sẽ được hỏi lại trước khi đăng nhập.';

  @override
  String get qrEnterManually => 'Nhập mã thủ công';

  @override
  String get qrCameraPermission =>
      'Ứng dụng chưa được cấp quyền camera. Hãy cấp quyền trong cài đặt máy hoặc nhập mã thủ công.';

  @override
  String get qrCameraUnsupported =>
      'Thiết bị không hỗ trợ quét mã bằng camera. Hãy nhập mã thủ công.';

  @override
  String get qrCameraFailed =>
      'Không mở được camera. Hãy thử lại hoặc nhập mã thủ công.';

  @override
  String get qrKioskLoginQuestion => 'Đăng nhập kiosk?';

  @override
  String get qrKioskLoginBody =>
      'Tài khoản Lock.R của bạn sẽ được đăng nhập trên kiosk vừa hiện mã. Chỉ xác nhận khi bạn đang đứng trước kiosk đó.';

  @override
  String get qrKioskConfirmCode => 'Mã xác nhận trên kiosk';

  @override
  String get qrKioskLogin => 'Đăng nhập kiosk';

  @override
  String get qrWrongCode =>
      'Mã chưa đúng. Kiểm tra lại mã phiên và mã xác nhận đang hiện trên kiosk.';

  @override
  String get qrEnterKioskCode => 'Nhập mã đăng nhập kiosk';

  @override
  String get qrEnterKioskCodeHint =>
      'Nhập mã phiên và mã xác nhận đang hiện dưới mã QR trên màn hình kiosk.';

  @override
  String get qrSessionCode => 'Mã phiên';

  @override
  String get qrConfirmCode => 'Mã xác nhận';

  @override
  String get mapNoLocation =>
      'Không lấy được vị trí của bạn — chỉ hiển thị tủ.';

  @override
  String get mapCantOpenMaps => 'Không mở được ứng dụng bản đồ.';

  @override
  String get mapFindingRoute => 'Đang tìm đường...';

  @override
  String mapRemaining(Object distance) {
    return '$distance còn lại';
  }

  @override
  String get mapStopNavigation => 'Dừng dẫn đường';

  @override
  String get mapStartNavigation => 'Bắt đầu dẫn đường';

  @override
  String get mapGetMyLocation => 'Lấy vị trí của bạn';

  @override
  String get mapOpenGoogleMaps => 'Mở trên Google Maps';

  @override
  String get mediaBadResponse =>
      'Máy chủ ảnh trả về dữ liệu không hợp lệ, vui lòng thử lại';

  @override
  String get mediaUploadCancelled => 'Đã huỷ tải ảnh';

  @override
  String get mediaCannotConnect =>
      'Không kết nối được máy chủ, kiểm tra mạng rồi thử lại';

  @override
  String get mediaPurposeForbidden => 'Bạn không có quyền tải loại ảnh này';

  @override
  String get mediaNoUploadPermission =>
      'Không lấy được quyền tải ảnh, vui lòng thử lại';

  @override
  String get mediaUploadNetwork =>
      'Không tải được ảnh lên, kiểm tra kết nối mạng rồi thử lại';

  @override
  String get mediaSessionExpired =>
      'Phiên tải ảnh đã hết hạn, vui lòng thử lại';

  @override
  String get mediaTooLarge => 'Ảnh quá lớn, vui lòng chọn ảnh khác';

  @override
  String get mediaFormatUnsupported =>
      'Định dạng ảnh không được hỗ trợ (dùng JPG, PNG, WEBP, HEIC)';

  @override
  String get mediaServerOverloaded =>
      'Máy chủ ảnh đang quá tải, vui lòng thử lại sau ít phút';

  @override
  String get mediaUploadFailedRetry => 'Tải ảnh lên thất bại, vui lòng thử lại';

  @override
  String get mediaStorageDisabled =>
      'Hệ thống lưu ảnh đang tạm tắt. Vui lòng gửi không kèm ảnh hoặc thử lại sau.';

  @override
  String get mediaPurposeInvalid => 'Loại ảnh tải lên không hợp lệ';

  @override
  String get mediaSignatureInvalid =>
      'Ảnh tải lên không hợp lệ, vui lòng chụp lại';

  @override
  String get mediaOwnerMismatch =>
      'Ảnh không thuộc tài khoản của bạn, vui lòng tải lại';

  @override
  String get mediaAttachmentLimit => 'Phiếu đã đạt số ảnh tối đa cho phép';

  @override
  String get mediaAttachmentStageInvalid =>
      'Loại ảnh không hợp lệ cho phiếu này';

  @override
  String get mediaReportNotInProgress => 'Phiếu chưa ở trạng thái đang xử lý';

  @override
  String get mediaReportResolved => 'Phiếu đã hoàn tất, không thể thêm ảnh';

  @override
  String get mediaReportNotAssigned =>
      'Bạn không phải kỹ thuật viên được giao phiếu này';

  @override
  String get mediaReportNotOwned => 'Bạn không phải người gửi phiếu này';

  @override
  String get mediaDeleteForbidden => 'Bạn không có quyền xoá ảnh này';

  @override
  String get mediaResolutionPhotoRequired =>
      'Cần ít nhất 1 ảnh nghiệm thu trước khi hoàn tất phiếu';

  @override
  String get mediaAlreadyAttached => 'Ảnh này đã được gắn vào phiếu';

  @override
  String mediaTooLargeMax(Object mb) {
    return 'Ảnh quá lớn (tối đa $mb MB), vui lòng chọn ảnh khác';
  }

  @override
  String get photoAdd => 'Thêm ảnh';

  @override
  String photoMax(Object count) {
    return 'Tối đa $count ảnh';
  }

  @override
  String get photoTakeCamera => 'Chụp ảnh từ máy ảnh';

  @override
  String photoPickGalleryMax(Object count) {
    return 'Chọn ảnh từ thư viện (tối đa $count)';
  }

  @override
  String get photoPickGallery => 'Chọn ảnh từ thư viện';

  @override
  String get photoCameraDenied =>
      'Không mở được máy ảnh. Hãy cấp quyền camera trong cài đặt.';

  @override
  String get photoGalleryDenied =>
      'Không mở được thư viện ảnh. Hãy cấp quyền ảnh trong cài đặt.';

  @override
  String get photoUploadFailed => 'Tải ảnh thất bại';

  @override
  String photoNumber(Object number) {
    return 'Ảnh $number';
  }

  @override
  String get attachmentReport => 'Ảnh hiện trường (người báo)';

  @override
  String get attachmentInspection => 'Ảnh xác nhận của KTV';

  @override
  String get attachmentProgress => 'Ảnh trong quá trình sửa';

  @override
  String get attachmentResolution => 'Ảnh nghiệm thu';

  @override
  String get attachmentPhoto => 'Ảnh';

  @override
  String attachmentCount(Object count) {
    return '($count ảnh):';
  }

  @override
  String get attachmentNone => 'Chưa có ảnh';

  @override
  String attachmentLocation(Object lat, Object lng) {
    return 'Vị trí $lat, $lng';
  }

  @override
  String get attachmentLoadFailed => 'Không tải được ảnh';

  @override
  String get paymentSuccess => 'Thanh toán thành công';

  @override
  String get paymentFailed => 'Thanh toán thất bại';

  @override
  String get paymentSuccessExclaim => 'Thanh toán thành công!';

  @override
  String get paymentPreparingPin => 'Đang chuẩn bị mã PIN mở ô tủ...';

  @override
  String get paymentTapToContinue => 'Chạm để tiếp tục';

  @override
  String get locationPick => 'Chọn vị trí';

  @override
  String get locationSearchAddress => 'Tìm kiếm địa chỉ...';

  @override
  String get locationConfirm => 'Xác nhận vị trí';

  @override
  String get commonYou => 'Bạn';

  @override
  String get commonSeeAllLower => 'Xem tất cả';

  @override
  String get commonDirections => 'Chỉ đường';

  @override
  String get commonAddress => 'Địa chỉ';

  @override
  String get commonDistance => 'Khoảng cách';

  @override
  String get commonStatus => 'Trạng thái';

  @override
  String get commonLocation => 'Vị trí';

  @override
  String get commonSize => 'Kích cỡ';

  @override
  String get commonBack => 'Quay lại';

  @override
  String get commonNoAddress => 'Chưa có địa chỉ';

  @override
  String get commonFavorites => 'Yêu thích';

  @override
  String get commonOffers => 'Ưu đãi';

  @override
  String get commonReportIssue => 'Báo sự cố';

  @override
  String get commonReports => 'Báo cáo';

  @override
  String get commonStatusActive => 'Hoạt động';

  @override
  String get commonStatusSuspended => 'Tạm ngưng';

  @override
  String get commonDisconnected => 'Mất kết nối';

  @override
  String get commonOnline => 'Trực tuyến';

  @override
  String get commonInUseShort => 'Đang dùng';

  @override
  String get commonReservedShort => 'Đã đặt';

  @override
  String get commonBroken => 'Hỏng';

  @override
  String get commonEmpty => 'Trống';

  @override
  String get commonExpired => 'Hết hạn';

  @override
  String get commonHistory => 'Lịch sử';

  @override
  String get commonAvailable => 'Khả dụng';

  @override
  String commonCopiedValue(Object value) {
    return 'Đã sao chép: $value';
  }

  @override
  String get commonStartDate => 'Bắt đầu';

  @override
  String get commonEndDate => 'Kết thúc';

  @override
  String get commonHowToUse => 'Cách sử dụng';

  @override
  String get commonTapToCopy => 'Chạm để sao chép mã';

  @override
  String get commonUnlimitedTime => 'Không giới hạn thời gian';

  @override
  String get commonExchange => 'Đổi';

  @override
  String get commonSaved => 'Đã lưu';

  @override
  String get commonLoadFailedData => 'Không tải được dữ liệu';

  @override
  String boxNumberLabel(Object number) {
    return 'Ô số $number';
  }

  @override
  String boxRowCol(Object row, Object col) {
    return 'Ô hàng $row, cột $col';
  }

  @override
  String rowCol(Object row, Object col) {
    return 'Hàng $row, cột $col';
  }

  @override
  String boxHash(Object number) {
    return 'Ô #$number';
  }

  @override
  String orderHash(Object id) {
    return 'Đơn #$id';
  }

  @override
  String get homeSendByDrone => 'Gửi hàng bằng drone';

  @override
  String get homeDropPoints => 'Điểm gửi';

  @override
  String get homeRentLocker => 'Thuê tủ';

  @override
  String get homeLockerOrders => 'Đơn tủ';

  @override
  String get homeUtilities => 'Tiện ích';

  @override
  String get homeDroneDelivery => 'Giao bằng drone';

  @override
  String get homeActiveOrders => 'Đơn đang xử lý';

  @override
  String get homePickupDeadline => 'Hạn lấy đồ';

  @override
  String get stepCreateOrder => 'Tạo đơn';

  @override
  String get stepFlightTeamAccepted => 'Đội bay nhận';

  @override
  String get stepFlying => 'Đang bay';

  @override
  String get stepDropReported => 'Báo rơi kiện';

  @override
  String get stepIntoLocker => 'Vào tủ nhận';

  @override
  String get stepDropIntoLocker => 'Bỏ vào tủ';

  @override
  String get stepStoring => 'Đang lưu tủ';

  @override
  String get stepInLocker => 'Đã vào tủ';

  @override
  String get stepTransit => 'Vận chuyển';

  @override
  String get stepAwaitingPickup => 'Chờ nhận';

  @override
  String get homeUtilitiesServices => 'Tiện ích & Dịch vụ';

  @override
  String get homeSendDrone => 'Gửi drone';

  @override
  String get homeKioskLocations => 'Các nơi đặt kiosk';

  @override
  String get homeNoLockerLocations => 'Chưa có nơi đặt locker nào';

  @override
  String get homeOngoingOffers => 'Ưu đãi đang diễn ra';

  @override
  String get storeDefaultName => 'Cửa hàng';

  @override
  String get storeFavoritesLoadFailed => 'Không tải được danh sách yêu thích.';

  @override
  String get storeFavoritesSubtitle => 'Điểm gửi bạn đã lưu';

  @override
  String get storeFavoritesLoading => 'Đang tải danh sách yêu thích...';

  @override
  String get storeNoFavorites => 'Chưa có cửa hàng yêu thích';

  @override
  String get storeNoFavoritesHint =>
      'Nhấn vào biểu tượng trái tim ở một cửa hàng để lưu lại đây.';

  @override
  String get storeExplore => 'Khám phá cửa hàng';

  @override
  String get storeAddedFavorite => 'Đã thêm vào yêu thích';

  @override
  String get storeRemovedFavorite => 'Đã bỏ khỏi yêu thích';

  @override
  String get storeFavoriteSaveFailed => 'Không lưu được danh sách yêu thích.';

  @override
  String get storeEnableLocation => 'Vui lòng bật dịch vụ định vị.';

  @override
  String get storeNeedLocation => 'Cần quyền vị trí để tìm cửa hàng gần bạn.';

  @override
  String get storeNoCurrentLocation => 'Không lấy được vị trí hiện tại.';

  @override
  String get storeListLoadFailed => 'Không tải được danh sách cửa hàng.';

  @override
  String get storeListSubtitle => 'Khám phá điểm tủ & đối tác liên kết';

  @override
  String get storeSearchHint => 'Tìm theo tên hoặc địa chỉ';

  @override
  String get storeListLoading => 'Đang tải danh sách điểm tủ...';

  @override
  String get storeNone => 'Không có cửa hàng nào';

  @override
  String get storeRatingsLoadFailed => 'Không tải được đánh giá.';

  @override
  String get storeInfoLoadFailed => 'Không tải được thông tin cửa hàng.';

  @override
  String get storeNoLocation => 'Cửa hàng chưa có vị trí.';

  @override
  String get storeCantOpenMap => 'Không mở được bản đồ.';

  @override
  String get storeDetailTitle => 'Chi tiết điểm gửi';

  @override
  String get storeDetailSubtitle => 'Điểm tủ & đối tác liên kết';

  @override
  String get storeInfoLoading => 'Đang tải thông tin...';

  @override
  String storeRatingCount(Object count) {
    return '  ·  $count đánh giá';
  }

  @override
  String get storeViewLockers => 'Xem tủ';

  @override
  String get storeCustomerReviews => 'Đánh giá từ khách hàng';

  @override
  String get storeNoReviews => 'Chưa có đánh giá nào';

  @override
  String get storeTemporarilyClosed => 'Tạm đóng';

  @override
  String get storeCustomer => 'Khách hàng';

  @override
  String get storeOpen => 'Mở cửa';

  @override
  String storeDistanceFromYou(Object km) {
    return 'Cách bạn $km km';
  }

  @override
  String lockerHash(Object id) {
    return 'Tủ #$id';
  }

  @override
  String get lockerLockerTitle => 'Tủ locker';

  @override
  String get lockerPhysicalLocation => 'Vị trí tủ vật lý';

  @override
  String get lockerListLoading => 'Đang tải danh sách tủ...';

  @override
  String get lockerDroneCellHint =>
      'Chạm vào ô drone còn trống (màu tím) để gửi hàng bằng drone tới tủ khác.';

  @override
  String get lockerViewOnMap => 'Xem vị trí trên bản đồ';

  @override
  String get lockerKioskPoint => 'ĐIỂM ĐẶT KIOSK';

  @override
  String lockerCount(Object count) {
    return '$count tủ locker';
  }

  @override
  String get lockerTapToSeeFree => 'Chạm vào tủ để xem ô trống';

  @override
  String get lockerDefaultName => 'Tủ';

  @override
  String get lockerOfflineCantBook =>
      'Tủ đang mất kết nối với máy chủ nên tạm thời chưa đặt được ô.';

  @override
  String get lockerUnderMaintenance =>
      'Tủ đang bảo trì kỹ thuật, tạm ngưng nhận đơn.';

  @override
  String get lockerSuspended => 'Tủ đang tạm ngưng hoạt động.';

  @override
  String lockerFreeOfTotal(Object available, Object total) {
    return '$available/$total ô trống';
  }

  @override
  String get lockerNoCellsConfigured => 'Tủ chưa có ô nào được cấu hình';

  @override
  String get lockerBoxPendingCheck => 'đang chờ kỹ thuật viên kiểm tra sự cố';

  @override
  String get lockerBoxBroken => 'đang hỏng';

  @override
  String lockerBoxUnavailable(Object box, Object state) {
    return '$box $state. Hãy chọn ô khác.';
  }

  @override
  String lockerBoxUnavailableReason(Object box, Object state, Object reason) {
    return '$box $state: $reason. Hãy chọn ô khác.';
  }

  @override
  String get lockerScreen7 => 'Màn hình 7\"';

  @override
  String get lockerFaultBroken => 'Lỗi / Hỏng';

  @override
  String get lockerDoorOpen => 'Cửa mở';

  @override
  String get lockerDoorClosed => 'Cửa đóng';

  @override
  String get lockerScreen => 'Màn hình';

  @override
  String get lockerKioskScreen => 'Màn hình kiosk';

  @override
  String get lockerKioskHelp =>
      'Tại màn hình kiosk, bạn có thể nhập mã PIN của đơn để mở ô, hoặc đăng nhập bằng cách quét mã QR trên kiosk với nút quét ở trang chủ ứng dụng.';

  @override
  String get lockerKioskOffline =>
      'Tủ đang mất kết nối với máy chủ: màn hình có thể không phản hồi và chưa đặt được ô mới.';

  @override
  String get lockerReportKioskIssue => 'Báo sự cố màn hình kiosk';

  @override
  String get lockerBrokenUpper => 'HỎNG';

  @override
  String get lockerPendingCheckUpper => 'CHỜ KIỂM TRA';

  @override
  String get lockerPendingCheck => 'Chờ kiểm tra';

  @override
  String get lockerCleaning => 'Vệ sinh';

  @override
  String get lockerDroneReceive => 'Nhận Drone';

  @override
  String get lockerReady => 'Sẵn sàng';

  @override
  String get sizeSmall => 'Nhỏ (S)';

  @override
  String get sizeMedium => 'Vừa (M)';

  @override
  String get sizeLarge => 'Lớn (L)';

  @override
  String get sizeXlSuitcase => 'Vali cỡ lớn (XL)';

  @override
  String get lockerEmptySuitcaseBox => 'Ô tủ vali trống';

  @override
  String get lockerEmptyBox => 'Ô tủ trống';

  @override
  String get lockerWhatToDo => 'Bạn muốn làm gì với ô tủ này?';

  @override
  String get lockerRentSubtitle => 'Theo giờ hoặc ngày';

  @override
  String get lockerSendParcel => 'Gửi hàng';

  @override
  String get lockerSendSubtitle => 'Chuyển C2C';

  @override
  String get lockerSuitcaseRentOnly =>
      'Ô vali chỉ dùng để thuê giữ đồ, không nhận gửi hàng.';

  @override
  String get lockerReportBoxIssue => 'Gặp sự cố với ô này? Báo cáo ngay';

  @override
  String get lockerNoLockers => 'Chưa có tủ locker';

  @override
  String get lockerStoreNoActiveLockers =>
      'Cửa hàng này chưa có tủ locker đang hoạt động.';

  @override
  String get lockerCabinetIdRequired => 'Cabinet ID không được để trống';

  @override
  String get lockerLocationIdRequired => 'Location ID không được để trống';

  @override
  String get lockerOfflinePickOther =>
      'Tủ đang mất kết nối nên chưa đặt được ô. Vui lòng chọn tủ khác hoặc thử lại sau.';

  @override
  String get lockerMaintenancePickOther =>
      'Tủ đang bảo trì nên tạm ngưng nhận đơn. Vui lòng chọn tủ khác.';

  @override
  String get lockerSuspendedCantBook =>
      'Tủ đang tạm ngưng hoạt động nên chưa đặt được ô.';

  @override
  String get groupSmall => 'Ô nhỏ (S)';

  @override
  String get groupMedium => 'Ô vừa (M)';

  @override
  String get groupLarge => 'Ô lớn (L)';

  @override
  String get groupStandard => 'Ô thường';

  @override
  String get groupXl => 'Ô vali (XL)';

  @override
  String get groupDrone => 'Ô drone';

  @override
  String get cellTypeDroneRoof => 'Drone (Nóc tủ)';

  @override
  String get cellTypeSuitcase => 'Vali (XL)';

  @override
  String get cellTypeStandard => 'Tiêu chuẩn';

  @override
  String get cellOutOfService => 'Ngưng dùng';

  @override
  String get lockerSizeSmallDesc => 'Kích thước nhỏ, phù hợp cho túi xách, ví';

  @override
  String get lockerSizeMediumDesc => 'Kích thước trung bình, phù hợp cho ba lô';

  @override
  String get lockerSizeLargeDesc => 'Kích thước lớn, phù hợp cho vali';

  @override
  String get lockerStatusAvailable => 'Có sẵn';

  @override
  String get lockerStatusInUse => 'Đang sử dụng';

  @override
  String get lockerStatusReserved => 'Đã đặt trước';

  @override
  String get lockerStatusMaintenance => 'Đang bảo trì';

  @override
  String get lockerStatusOutOfService => 'Ngừng hoạt động';

  @override
  String get lockerAlreadyRented => 'Tủ này đang được thuê.';

  @override
  String get lockerInsufficientBalance => 'Số dư không đủ.';

  @override
  String get lockerFixedRentFailed => 'Thuê tủ cố định thất bại.';

  @override
  String get lockerOpenCommandSent => 'Đã gửi lệnh mở tủ.';

  @override
  String get lockerCloseCommandSent => 'Đã gửi lệnh đóng tủ.';

  @override
  String get lockerDetailSubtitle => 'Chi tiết vị trí tủ Lock.R';

  @override
  String get lockerNoCoordinates =>
      'Tủ chưa có toạ độ nên chưa hiển thị được bản đồ và chỉ đường.';

  @override
  String get lockerBookService => 'Đặt dịch vụ';

  @override
  String get lockerViewLayout => 'Xem sơ đồ ô tủ';

  @override
  String get lockerMapTitle => 'Bản đồ tủ khóa';

  @override
  String get lockerMapSubtitle => 'Tìm điểm tủ Lock.R gần bạn nhất';

  @override
  String get lockerMapLoading => 'Đang tải bản đồ...';

  @override
  String get lockerNoneYet => 'Hiện tại chưa có tủ nào!';

  @override
  String get lockerGettingLocation => 'Đang lấy vị trí...';

  @override
  String get lockerUseMyLocation => 'Sử dụng vị trí của bạn';

  @override
  String get lockerMapLoadFailed =>
      'Không thể tải bản đồ. Toạ độ có thể không hợp lệ.';

  @override
  String lockerInvalidCoordsHidden(Object count) {
    return '$count địa điểm có toạ độ không hợp lệ đã được ẩn.';
  }

  @override
  String get lockerLocating => 'Đang xác định vị trí...';

  @override
  String get lockerAddressFailed =>
      'Không thể xác định địa chỉ, vui lòng thử lại';

  @override
  String lockerAddressFailedError(Object error) {
    return 'Không thể xác định địa chỉ, vui lòng thử lại: $error';
  }

  @override
  String get lockerLocationServiceOff =>
      'Dịch vụ vị trí đang tắt. Vui lòng bật GPS.';

  @override
  String get lockerLocationDenied => 'Quyền truy cập vị trí bị từ chối.';

  @override
  String get lockerLocationDeniedForever =>
      'Quyền vị trí bị từ chối vĩnh viễn. Hãy bật lại trong cài đặt.';

  @override
  String get lockerOtherKiosk => 'Kiosk khác';

  @override
  String lockerCountShort(Object count) {
    return '$count tủ';
  }

  @override
  String get commonAll => 'Tất cả';

  @override
  String get lockerLocationList => 'Danh sách địa điểm';

  @override
  String get lockerLoginToSeeLocations =>
      'Đăng nhập để xem các địa điểm khả dụng';

  @override
  String get lockerLoginRequiredLocations =>
      'Bạn cần đăng nhập để xem danh sách địa điểm';

  @override
  String get lockerPickLocation => 'Chọn địa điểm để xem chi tiết';

  @override
  String get lockerSearchLocation => 'Tìm kiếm địa điểm...';

  @override
  String get lockerNoLocations => 'Hiện tại chưa có địa điểm nào!';

  @override
  String get lockerNotFoundHere => 'Không tìm thấy tủ tại địa điểm này';

  @override
  String get lockerTryOtherLocation =>
      'Thử chọn địa điểm khác hoặc xem tất cả địa điểm khả dụng.';

  @override
  String get lockerViewAllLocations => 'Xem tất cả địa điểm';

  @override
  String get lockerLoadingFreeCells => 'Đang tải số ô trống...';

  @override
  String lockerCellsLoadFailed(Object error) {
    return 'Chưa tải được số ô: $error';
  }

  @override
  String get lockerFreeCells => 'Ô trống';

  @override
  String get lockerConnectionUnknown => 'Chưa rõ kết nối';

  @override
  String get lockerMostUsed => 'Hay dùng nhất';

  @override
  String get promoUnlimited => 'Không giới hạn';

  @override
  String get promoExpired => 'Đã hết hạn';

  @override
  String promoDaysLeft(Object days) {
    return 'Còn $days ngày';
  }

  @override
  String promoHoursLeft(Object hours) {
    return 'Còn $hours giờ';
  }

  @override
  String promoMinutesLeft(Object minutes) {
    return 'Còn $minutes phút';
  }

  @override
  String promoMinOrder(Object amount) {
    return 'Đơn tối thiểu $amount';
  }

  @override
  String get promoSystemWide => 'Toàn hệ thống';

  @override
  String promoAppliesAt(Object name) {
    return 'Áp dụng tại: $name';
  }

  @override
  String get promoSubtitle => 'Khám phá ưu đãi đang hiệu lực hôm nay';

  @override
  String get promoLoading => 'Đang tải khuyến mãi...';

  @override
  String get promoNoneActive => 'Chưa có ưu đãi nào đang hiệu lực';

  @override
  String get promoExpiringSoon => 'Sắp hết hạn';

  @override
  String promoSavedToMine(Object code) {
    return 'Đã lưu mã $code vào \"Ưu đãi của tôi\"';
  }

  @override
  String get promoSaveNotSupported =>
      'Máy chủ chưa hỗ trợ lưu mã. Vui lòng thử lại sau.';

  @override
  String get promoSaveFailed =>
      'Không lưu được mã — kiểm tra đăng nhập và thử lại';

  @override
  String promoCopiedCode(Object code) {
    return 'Đã sao chép mã: $code';
  }

  @override
  String promoDiscountPercent(Object percent) {
    return 'Giảm $percent%';
  }

  @override
  String promoDiscountAmount(Object amount) {
    return 'Giảm $amount';
  }

  @override
  String get promoDetailTitle => 'Chi tiết ưu đãi';

  @override
  String get promoOfferExpired => 'Ưu đãi đã hết hạn';

  @override
  String get promoCodeLabel => 'Mã khuyến mãi';

  @override
  String get promoDiscountLevel => 'Mức giảm';

  @override
  String get promoScope => 'Phạm vi';

  @override
  String get promoMaxDiscount => 'Giảm tối đa';

  @override
  String get promoMinOrderLabel => 'Đơn tối thiểu';

  @override
  String get promoActive => 'Đang hiệu lực';

  @override
  String get promoExpiredCantUse =>
      'Ưu đãi này đã hết hạn và không thể sử dụng.';

  @override
  String get promoStep1Any =>
      'Vào trang Thuê tủ, Gửi hàng hoặc Gửi drone và chọn tủ';

  @override
  String promoStep1At(Object locker) {
    return 'Vào trang Thuê tủ, Gửi hàng hoặc Gửi drone tại $locker (đơn drone: tủ drone cất cánh)';
  }

  @override
  String get promoStep2 =>
      'Ở mục \"Mã giảm giá\", chạm \"Chọn mã giảm giá\" rồi chọn mã này trong danh sách';

  @override
  String get promoStep3 =>
      'Mức giảm được trừ vào tổng tiền nếu đơn đủ điều kiện (đơn tối thiểu, tủ áp dụng)';

  @override
  String get promoLoadFailed => 'Không tải được ưu đãi';

  @override
  String get promoAtThisLocker => 'Ưu đãi tại tủ này';

  @override
  String get voucherMine => 'Ưu đãi của tôi';

  @override
  String get voucherMineSubtitle => 'Mã giảm giá & quà tặng của bạn';

  @override
  String get voucherExchangeTab => 'Đổi điểm';

  @override
  String get voucherLoginToSee => 'Bạn cần đăng nhập để xem ưu đãi đã lưu';

  @override
  String get voucherLoading => 'Đang tải ưu đãi...';

  @override
  String get voucherNone => 'Bạn chưa có ưu đãi nào';

  @override
  String get voucherExploreAndSave => 'Khám phá ưu đãi và lưu mã';

  @override
  String get voucherGift => 'Quà tặng';

  @override
  String get voucherGiftUpper => 'QUÀ TẶNG';

  @override
  String get voucherDiscountUpper => 'GIẢM GIÁ';

  @override
  String get voucherUsed => 'Đã dùng';

  @override
  String get voucherUsedLong => 'Đã sử dụng';

  @override
  String get voucherCopied => 'Đã sao chép mã voucher';

  @override
  String get voucherCode => 'Mã voucher';

  @override
  String get voucherOffer => 'Ưu đãi';

  @override
  String get voucherCampaign => 'Chiến dịch';

  @override
  String get voucherValidUntil => 'Hạn sử dụng';

  @override
  String get voucherExpiredCantUse =>
      'Voucher này đã hết hạn và không thể sử dụng.';

  @override
  String get voucherAlreadyUsed => 'Voucher này đã được sử dụng.';

  @override
  String get voucherStepCopy => 'Sao chép mã voucher ở trên';

  @override
  String get voucherStepBookAny =>
      'Vào trang đặt dịch vụ (Thuê tủ / Gửi hàng / Gửi drone)';

  @override
  String voucherStepBookAt(Object locker) {
    return 'Đặt dịch vụ tại $locker (đơn drone: tủ drone cất cánh)';
  }

  @override
  String get voucherStepEnter =>
      'Nhập mã vào ô \"Mã giảm giá\" và nhấn Áp dụng';

  @override
  String get voucherStepDeducted =>
      'Mức giảm sẽ được trừ vào tổng tiền thanh toán';

  @override
  String get voucherExchangeNotSupported =>
      'Máy chủ chưa hỗ trợ đổi điểm. Vui lòng thử lại sau.';

  @override
  String get voucherExchangeLoadFailed =>
      'Không tải được danh sách đổi điểm. Vui lòng thử lại.';

  @override
  String get voucherExchangeFailed =>
      'Chưa đổi được voucher. Vui lòng thử lại.';

  @override
  String get voucherWalletNotSupported =>
      'Máy chủ chưa hỗ trợ kho ưu đãi. Vui lòng thử lại sau.';

  @override
  String get voucherMineLoadFailed =>
      'Không tải được ưu đãi của bạn. Vui lòng thử lại.';

  @override
  String pointsCount(Object points) {
    return '$points điểm';
  }

  @override
  String voucherMaxSuffix(Object amount) {
    return ' (tối đa $amount)';
  }

  @override
  String get voucherExchangeLoading => 'Đang tải voucher đổi điểm...';

  @override
  String get voucherExchangeNone => 'Hiện chưa có voucher nào để đổi điểm';

  @override
  String get voucherExchangeQuestion => 'Đổi voucher?';

  @override
  String voucherExchangeConfirm(Object points, Object reward, Object code) {
    return 'Dùng $points đổi voucher \"$reward\". Voucher sẽ nằm trong mục Khả dụng, dùng bằng mã $code khi đặt đơn.';
  }

  @override
  String voucherExchanged(Object code) {
    return 'Đã đổi voucher $code — xem ở mục Khả dụng';
  }

  @override
  String get voucherYourPoints => 'Điểm của bạn';

  @override
  String voucherPointRate(Object amount) {
    return '1 điểm = $amount · đổi lấy voucher giảm giá cho đơn';
  }

  @override
  String get voucherOwned => 'Đã có';

  @override
  String voucherMissingPoints(Object points) {
    return 'Thiếu $points';
  }

  @override
  String voucherOrderFrom(Object amount) {
    return 'Đơn từ $amount';
  }

  @override
  String get commonDetails => 'Chi tiết';

  @override
  String get commonNotYet => 'Chưa';

  @override
  String get commonNote => 'Ghi chú';

  @override
  String get commonReload => 'Tải lại';

  @override
  String get commonService => 'Dịch vụ';

  @override
  String get commonDiscount => 'Giảm giá';

  @override
  String get commonVoucher => 'Voucher';

  @override
  String get commonAmount => 'Số tiền';

  @override
  String get commonLocker => 'Tủ';

  @override
  String get commonBox => 'Ô';

  @override
  String get commonToday => 'Hôm nay';

  @override
  String get commonYesterday => 'Hôm qua';

  @override
  String get commonUnknownDate => 'Không rõ ngày';

  @override
  String dateDayMonthYear(Object day, Object month, Object year) {
    return '$day tháng $month, $year';
  }

  @override
  String hoursValue(int hours) {
    return '$hours giờ';
  }

  @override
  String pricePerHour(Object price) {
    return '$price/giờ';
  }

  @override
  String photosMore(Object count) {
    return '+$count ảnh';
  }

  @override
  String get boxThisLower => 'ô này';

  @override
  String boxNumberLower(Object number) {
    return 'ô số $number';
  }

  @override
  String get boxThis => 'Ô này';

  @override
  String get ordIncomingNotSupported =>
      'Máy chủ chưa hỗ trợ mục Hàng chờ nhận. Vui lòng thử lại sau.';

  @override
  String get ordNotFoundInList => 'Không tìm thấy đơn trong danh sách của bạn.';

  @override
  String get ordEmptyRecent => 'Không có đơn hàng nào trong 7 ngày gần đây.';

  @override
  String get ordEmptyActive =>
      'Hiện không có đơn hàng nào đang trong quá trình sử dụng.';

  @override
  String get ordEmptyCompleted => 'Chưa có đơn hàng nào đã hoàn tất.';

  @override
  String get ordEmptyRental => 'Chưa có đơn thuê tủ nào.';

  @override
  String get ordEmptySend => 'Chưa có đơn gửi hàng nào.';

  @override
  String get ordEmptyCanceled => 'Không có đơn nào đã hủy.';

  @override
  String get ordEmptyHint => 'Tạo đơn Gửi hàng hoặc Thuê tủ từ màn hình chính.';

  @override
  String get ordCancelQuestion => 'Huỷ đơn?';

  @override
  String ordCancelBody(Object code) {
    return 'Đơn $code sẽ bị huỷ, mã mở ô hết hiệu lực và ô đang giữ được nhả.';
  }

  @override
  String get ordCancelPaidNote =>
      ' Tiền đã thanh toán không tự hoàn — sau khi huỷ, mở lại đơn và chọn \"Yêu cầu hoàn tiền\".';

  @override
  String get ordKeepOrder => 'Giữ đơn';

  @override
  String get ordCancelOrderAlt => 'Huỷ đơn';

  @override
  String get ordExtendRental => 'Gia hạn thuê';

  @override
  String ordAddHours(int hours) {
    return 'Thêm $hours giờ';
  }

  @override
  String ordMaxHoursPerExtension(Object hours) {
    return 'Tối đa $hours giờ mỗi lần gia hạn';
  }

  @override
  String get ordExtend => 'Gia hạn';

  @override
  String ordExtended(int hours) {
    return 'Đã gia hạn $hours giờ';
  }

  @override
  String get ordReportFaultyBox => 'Báo ô lỗi';

  @override
  String get ordDescribeIssueHint => 'Mô tả sự cố (ô không mở, kẹt cửa...)';

  @override
  String ordOnsitePhotosOptional(Object max) {
    return 'Ảnh hiện trường (không bắt buộc, tối đa $max)';
  }

  @override
  String get ordPhotosHelp => 'Ảnh giúp đội bảo trì xử lý nhanh hơn.';

  @override
  String get ordDescribeOrAttach => 'Vui lòng mô tả sự cố hoặc đính kèm ảnh.';

  @override
  String get ordUploadingPhotos => 'Đang tải ảnh...';

  @override
  String get ordSendReport => 'Gửi báo lỗi';

  @override
  String get ordBoxFaultDefault => 'Ô tủ gặp sự cố (xem ảnh đính kèm)';

  @override
  String ordReportSentFor(Object box) {
    return 'Đã gửi báo lỗi cho $box — đội bảo trì sẽ xử lý';
  }

  @override
  String get ordPickupAtKiosk => 'Lấy đồ tại kiosk';

  @override
  String get ordPickupAtKioskBody =>
      'Dùng mã này tại kiosk để mở ô, lấy đồ ra, rồi đóng cửa tủ lại trước khi xác nhận kết thúc thuê. Bạn cũng có thể bấm mở trực tiếp trên app nếu đang ở gần tủ.';

  @override
  String ordOpenBoxOnPhone(Object box) {
    return 'Mở $box trên điện thoại (GPS/QR)';
  }

  @override
  String get ordPickedUpAndClosed => 'Đã lấy đồ và đóng tủ';

  @override
  String get ordRentalEnded => 'Đã kết thúc kỳ thuê';

  @override
  String get ordNoLockerInfo => 'Đơn chưa có thông tin tủ.';

  @override
  String get ordLockerNoLocation => 'Tủ chưa có vị trí để chỉ đường.';

  @override
  String get ordCantOpenMapsApp =>
      'Không mở được ứng dụng bản đồ trên máy này.';

  @override
  String ordExtensionPaymentFor(Object id) {
    return 'Thanh toán gia hạn thời gian đơn #$id';
  }

  @override
  String get ordPaidSuccessfully =>
      'Đơn hàng của bạn đã được thanh toán thành công.';

  @override
  String get ordPaymentNotCompleted =>
      'Giao dịch chưa hoàn tất hoặc đã bị hủy. Vui lòng thử lại.';

  @override
  String get ordAwaitingPaymentPull =>
      'Đang chờ xác nhận thanh toán — kéo xuống để làm mới sau ít phút.';

  @override
  String get ordAwaitingPaymentConfirmPickup =>
      'Đang chờ xác nhận thanh toán — bấm lại \"Xác nhận lấy đồ\" sau khi đơn hiện Đã thanh toán.';

  @override
  String get ordConfirmPickup => 'Xác nhận lấy đồ';

  @override
  String get ordConfirmPickupBody =>
      'Bạn xác nhận đã nhận lại đầy đủ đồ đạc của đơn hàng này? Thao tác này sẽ đóng và hoàn tất đơn hàng.';

  @override
  String get ordPickedUpComplete => 'Đã lấy đồ — Hoàn tất';

  @override
  String get ordCompletedTitle => 'Hoàn tất đơn hàng!';

  @override
  String get ordPaidAndPickedUp =>
      'Bạn đã thanh toán và lấy đồ thành công. Đơn hàng đã hoàn tất.';

  @override
  String get ordReceivedComplete => 'Đã nhận đồ — đơn hoàn tất';

  @override
  String get ordPaidNotCompletedTitle => 'Đã thanh toán — chưa hoàn tất đơn';

  @override
  String ordPaidNotCompletedBody(Object reason) {
    return 'Hệ thống đã ghi nhận thanh toán nhưng chưa hoàn tất được đơn: $reason\nBạn có thể thử lại \"Xác nhận lấy đồ\" hoặc gửi khiếu nại trong chi tiết đơn.';
  }

  @override
  String get ordNoOvertimeFeeDue =>
      'Đơn hàng không có phí quá giờ cần thanh toán';

  @override
  String get ordLockrLocker => 'Tủ Lock.R';

  @override
  String get ordOverdue => 'Đã quá hạn';

  @override
  String get ordOverdueFee => 'Phí quá hạn';

  @override
  String get ordAwaitingPaymentOpenBox =>
      'Đang chờ xác nhận thanh toán — mở ô sau khi đơn hiện Đã thanh toán.';

  @override
  String get ordOvertimePaidOpening =>
      'Đã thanh toán phí quá giờ — chuẩn bị mở ô';

  @override
  String ordSendingOpenCommand(Object box) {
    return 'Đang gửi lệnh mở $box tới tủ...';
  }

  @override
  String ordBoxOpened(Object box) {
    return 'Tủ đã mở $box — mời bạn thao tác rồi đóng cửa.';
  }

  @override
  String ordBoxOpenFailed(Object box, Object detail) {
    return 'Không mở được $box$detail';
  }

  @override
  String get ordNoBoxPinInfo => 'Đơn chưa có thông tin ô/PIN để mở tủ.';

  @override
  String get ordOverdueRentalNotice =>
      'Đơn thuê đã quá hạn. Đã ghi nhận xử lý phí quá giờ — mời bạn mở ô lấy đồ và đóng tủ để hoàn tất.';

  @override
  String ordDelegatedTo(Object to) {
    return 'Đã ủy quyền lấy hộ$to. Mã PIN cũ đã hết hiệu lực.';
  }

  @override
  String ordDelegatedToPhone(Object phone) {
    return ' cho $phone';
  }

  @override
  String get ordChangePinQuestion => 'Đổi mã PIN?';

  @override
  String get ordChangePinReceiver =>
      'Mã PIN hiện tại sẽ hết hiệu lực. Người nhận cần mã mới để lấy hàng — hãy gửi lại mã mới cho họ.';

  @override
  String get ordChangePinNow =>
      'Mã PIN hiện tại sẽ hết hiệu lực ngay và được thay bằng mã mới.';

  @override
  String get ordChangeCode => 'Đổi mã';

  @override
  String get ordPinChangedSeeDetail =>
      'Đã đổi mã PIN — xem mã mới trong chi tiết đơn.';

  @override
  String ordPinChangedNew(Object pin) {
    return 'Đã đổi mã PIN mới: $pin';
  }

  @override
  String get ordPinChangeNotSupported => 'Máy chủ chưa hỗ trợ đổi mã PIN.';

  @override
  String ordReceiverEmailSaved(Object email) {
    return 'Đã lưu email người nhận $email. Lock.R báo người nhận khi đơn được thanh toán.';
  }

  @override
  String ordPickupCodeSentTo(Object email) {
    return 'Đã gửi mã mở tủ tới $email.';
  }

  @override
  String ordOrderInfoResentTo(Object email) {
    return 'Đã gửi lại thông tin đơn tới $email.';
  }

  @override
  String get ordEmailCodeNotSupported =>
      'Máy chủ chưa hỗ trợ gửi mã qua email.';

  @override
  String get ordNewOrderCreated => 'Đã tạo đơn mới — xem trong danh sách';

  @override
  String get ordDropoffConfirmed => 'Đã xác nhận bỏ đồ';

  @override
  String get ordConfirmPickedUpQuestion => 'Xác nhận đã lấy đồ?';

  @override
  String get ordConfirmPickedUpBody =>
      'Đơn sẽ hoàn tất và ô tủ được giải phóng. Chỉ xác nhận khi bạn đã lấy đồ ra khỏi ô.';

  @override
  String get ordPickedUp => 'Đã lấy đồ';

  @override
  String ordBoxHasTicket(Object id) {
    return 'Ô này đã có phiếu RPT-$id đang được KTV xử lý.';
  }

  @override
  String get ordCancelled => 'Đã hủy đơn';

  @override
  String get ordMyOrdersSubtitle => 'Quản lý các đơn hàng của bạn';

  @override
  String get ordTabRecent => 'Gần đây';

  @override
  String get ordTabInUse => 'Đang dùng';

  @override
  String get ordTabCompleted => 'Hoàn thành';

  @override
  String get ordTabCancelled => 'Đã hủy';

  @override
  String get ordTabAwaitingPickup => 'Chờ lấy';

  @override
  String get ordListLoading => 'Đang tải danh sách đơn...';

  @override
  String get ordNoOrdersYet => 'Chưa có đơn nào';

  @override
  String get ordNoMatchingOrders => 'Không có đơn phù hợp';

  @override
  String get ordIncomingLoading => 'Đang tải hàng chờ nhận...';

  @override
  String get ordNoIncoming => 'Chưa có hàng chờ nhận';

  @override
  String get ordNoIncomingHint =>
      'Khi có người gửi hàng tới số điện thoại của bạn, đơn sẽ hiện ở đây.';

  @override
  String get ordNoIncomingMatch =>
      'Không tìm thấy đơn hàng chờ nhận nào theo bộ lọc đã chọn.';

  @override
  String get ordMyOrders => 'Đơn của tôi';

  @override
  String get ordIncoming => 'Hàng chờ nhận';

  @override
  String ordPickupDeadlineValue(Object time) {
    return 'Hạn lấy: $time';
  }

  @override
  String get ordLockerNameUnknown => 'Chưa tra được tên tủ';

  @override
  String get ordPayAndPickup => 'Thanh toán & lấy đồ';

  @override
  String get ordAwaitingTechnician => 'Chờ KTV xử lý';

  @override
  String get ordReview => 'Xem lại';

  @override
  String get ordDropIntoLocker => 'Bỏ đồ vào tủ';

  @override
  String get ordPickupNow => 'Lấy đồ ngay';

  @override
  String get ordOvertimePausedNoTime =>
      'Phí quá giờ tạm dừng — chờ KTV xử lý ô, chưa cần thanh toán';

  @override
  String ordOvertimePausedSince(Object time) {
    return 'Phí quá giờ tạm dừng từ $time — chưa cần thanh toán';
  }

  @override
  String ordStorageExpiredTapPay(Object hours) {
    return 'Đơn đã hết hạn lưu tủ $hours — Bấm để thanh toán & lấy đồ';
  }

  @override
  String get ordOverdueMayCharge => 'Đơn đã quá hạn — có thể phát sinh phí';

  @override
  String ordRelocatedTitle(Object box) {
    return 'Đã điều chuyển sang Ô số $box an toàn';
  }

  @override
  String ordRelocatedSubtitle(Object oldBox) {
    return 'KTV đã chuyển đồ từ ô cũ (#$oldBox) sang ô mới do sự cố. Mã PIN mới đã sẵn sàng.';
  }

  @override
  String ordCheckedNoIssueTitle(Object box) {
    return 'KTV đã kiểm tra: $box không có sự cố';
  }

  @override
  String get ordCheckedNoIssueSubtitle =>
      'Ô hoạt động bình thường, bạn lấy đồ bằng mã PIN như thường lệ. Xem phản hồi của KTV trong phiếu.';

  @override
  String ordResolvedTitle(Object box) {
    return '$box đã được KTV kiểm tra & xử lý xong';
  }

  @override
  String get ordResolvedSubtitle => 'Tài sản trong ô được bảo vệ an toàn.';

  @override
  String ordReportedTitle(Object box) {
    return '$box đã được báo sự cố';
  }

  @override
  String get ordReportedCancelHint =>
      'Hãy hủy đơn này và đặt ô khác (hoặc liên hệ KTV).';

  @override
  String get ordReportedBlocked =>
      'Đồ của bạn vẫn được giữ an toàn trong ô. KTV đang xử lý — phí quá giờ tạm dừng, bạn chưa cần thanh toán.';

  @override
  String get ordReportedCanOpen =>
      'KTV sẽ tới kiểm tra ô. Bạn vẫn mở ô bằng mã PIN để lấy đồ được — phí quá giờ tạm dừng từ lúc báo.';

  @override
  String ordReasonValue(Object reason) {
    return 'Lý do: $reason';
  }

  @override
  String get ordViewRelocation => 'Xem chi tiết điều chuyển & ảnh KTV';

  @override
  String get ordViewRecord => 'Xem biên bản & ảnh minh chứng';

  @override
  String get ordPayOvertimeFee => 'Thanh toán phí quá giờ';

  @override
  String get ordOriginalDeadline => 'Hạn trả ban đầu';

  @override
  String get ordOverdueDuration => 'Thời gian quá hạn';

  @override
  String get ordOvertimeRate => 'Đơn giá quá giờ';

  @override
  String get ordCapRule => 'Quy định mức trần';

  @override
  String ordCapMax(Object amount) {
    return 'Tối đa $amount';
  }

  @override
  String ordCapPercent(Object percent) {
    return '$percent% đơn';
  }

  @override
  String get ordOvertimeFee => 'Phí quá giờ';

  @override
  String get ordAmountDue => 'Cần thanh toán:';

  @override
  String ordPayAmount(Object amount) {
    return 'Thanh toán $amount';
  }

  @override
  String get ordOpenBoxPickup => 'Mở ô lấy đồ';

  @override
  String get ordBoxReleased => 'Đã giải phóng ô';

  @override
  String get ordBoxNotAssigned => 'Chưa gán ô';

  @override
  String get ordPinCancelledSecurity => '•••••• (Đã hủy để bảo mật)';

  @override
  String get ordTechInCharge => 'KTV phụ trách';

  @override
  String get ordRelocationRecordUpper => 'HỒ SƠ ĐIỀU CHUYỂN Ô AN TOÀN';

  @override
  String get ordRelocationRecordSubtitle =>
      'Hàng đã được chuyển sang ô mới do ô cũ gặp sự cố kỹ thuật';

  @override
  String get ordOriginalBoxUpper => 'Ô BAN ĐẦU';

  @override
  String ordBoxNumberHash(Object number) {
    return 'Ô số #$number';
  }

  @override
  String get ordTechnicalIssue => 'Gặp sự cố kỹ thuật';

  @override
  String get ordNewBoxUpper => 'Ô TIẾP NHẬN MỚI';

  @override
  String get ordHoldingSafely => 'Đang chứa hàng an toàn';

  @override
  String get ordOldBoxCheckedAt => 'Thời gian mở ô cũ kiểm tra';

  @override
  String get ordMovedAt => 'Thời gian chuyển qua ô mới';

  @override
  String get ordOriginalBoxPin => 'Mã PIN ô ban đầu';

  @override
  String get ordPinDisabled => 'Đã vô hiệu hoá (Mã cũ hết hạn)';

  @override
  String ordNewBoxPin(Object box) {
    return 'Mã PIN mở ô mới (#$box)';
  }

  @override
  String ordPinActive(Object pin) {
    return '$pin (Đang kích hoạt)';
  }

  @override
  String ordTechPhotos(Object count) {
    return 'Ảnh KTV chụp quá trình kiểm tra & chuyển ô ($count ảnh):';
  }

  @override
  String get ordViewFullRecord => 'Xem toàn bộ biên bản sự cố KTV & nhật ký ➔';

  @override
  String ordOrderDetailHash(Object id) {
    return 'Chi tiết đơn #$id';
  }

  @override
  String ordServiceHash(Object id) {
    return 'Dịch vụ #$id';
  }

  @override
  String get ordReviewDroneJourney => 'Xem lại hành trình drone';

  @override
  String get ordTrackDrone => 'Theo dõi giao drone';

  @override
  String ordPayAndCompletePickup(Object amount) {
    return 'Thanh toán ($amount) & Lấy đồ hoàn tất';
  }

  @override
  String get ordIPickedUpCompleteOrder => 'Tôi đã lấy đồ — Hoàn tất đơn';

  @override
  String ordOpenBoxToPickup(Object box) {
    return 'Mở $box để lấy đồ';
  }

  @override
  String get ordReorder => 'Đặt lại đơn';

  @override
  String ordOpenBoxToDrop(Object box) {
    return 'Mở $box để bỏ đồ';
  }

  @override
  String get ordIDroppedOff => 'Tôi đã bỏ đồ vào ô';

  @override
  String ordPayOvertimeAndOpen(Object amount) {
    return 'Thanh toán phí quá giờ ($amount) & Mở ô';
  }

  @override
  String get ordIPickedUpComplete => 'Tôi đã lấy đồ — hoàn tất';

  @override
  String ordOpenBoxToReturn(Object box) {
    return 'Mở $box để trả tủ & lấy đồ';
  }

  @override
  String get ordEndRentalPickup => 'Kết thúc thuê & lấy đồ';

  @override
  String get ordDelegatePickup => 'Ủy quyền lấy hộ';

  @override
  String get ordChangePin => 'Đổi mã PIN';

  @override
  String get ordAddReceiverEmail => 'Thêm email người nhận';

  @override
  String get ordChangeReceiverEmail => 'Đổi email người nhận';

  @override
  String get ordResendToReceiver => 'Gửi lại thông tin cho người nhận';

  @override
  String get ordCancelOrder => 'Hủy đơn';

  @override
  String get ordDirectionsToLocker => 'Chỉ đường tới tủ';

  @override
  String get ordRequestRefund => 'Yêu cầu hoàn tiền';

  @override
  String ordStorageExpiredPay(Object hours) {
    return 'Đơn đã quá hạn lưu tủ $hours. Ô tủ đã được giải phóng và đồ đã chuyển về bảo quản an toàn. Quý khách vui lòng thanh toán phí còn lại và bấm \"Thanh toán & lấy đồ\" để hoàn tất.';
  }

  @override
  String ordStorageExpiredCheck(Object hours) {
    return 'Đơn đã quá hạn lưu tủ $hours. Ô tủ đã được giải phóng và đồ đã chuyển về bảo quản an toàn. Quý khách vui lòng kiểm tra nhận đồ và bấm \"Tôi đã lấy đồ — Hoàn tất đơn\" để hoàn tất.';
  }

  @override
  String get ordOverduePaidOpen =>
      'Đơn quá hạn đã thanh toán phí quá giờ. Mời bạn mở ô để lấy đồ và hoàn tất trả tủ.';

  @override
  String ordOverdueNeedPay(Object policy) {
    return 'Đơn đã quá hạn lấy — cần thanh toán phí quá giờ để mở tủ. $policy';
  }

  @override
  String ordUnpaidHold(Object minutes) {
    return 'Đơn hàng chưa thanh toán. Vui lòng thanh toán trong vòng $minutes phút để giữ chỗ tủ, hoặc bấm \"Hủy đơn\" bên dưới để giải phóng ô tủ ngay.';
  }

  @override
  String get ordPlace => 'Địa điểm';

  @override
  String get ordNewBox => 'Ô mới tiếp nhận';

  @override
  String ordNewBoxValue(Object box) {
    return 'Ô số $box (Đang an toàn)';
  }

  @override
  String get ordOriginalBox => 'Ô ban đầu';

  @override
  String ordOriginalBoxValue(Object box) {
    return 'Ô số $box (Gặp sự cố)';
  }

  @override
  String get ordOldBoxOpenedAt => 'Thời gian mở ô cũ';

  @override
  String get ordBoxMovedAt => 'Thời gian chuyển ô';

  @override
  String get ordOriginalPin => 'Mã PIN ban đầu';

  @override
  String get ordOrderDate => 'Ngày đặt';

  @override
  String get ordRentalDuration => 'Thời gian thuê';

  @override
  String get ordOriginalDeadlineShort => 'Hạn ban đầu';

  @override
  String get ordCapRuleShort => 'Quy định trần';

  @override
  String get ordOvertimeFeeEstimate => 'Phí quá giờ tạm tính';

  @override
  String get ordPenaltyStatus => 'Trạng thái phạt';

  @override
  String get ordDueToOpen => 'Cần nộp để mở ô';

  @override
  String get ordRecipient => 'Người nhận';

  @override
  String get ordRecipientEmail => 'Email người nhận';

  @override
  String get ordDelegatedToLabel => 'Ủy quyền lấy hộ cho';

  @override
  String get ordDelegatee => 'Người được ủy quyền';

  @override
  String get ordDelegationMessage => 'Lời nhắn ủy quyền';

  @override
  String get ordDelegatedAt => 'Ủy quyền lúc';

  @override
  String get ordExpectedPickup => 'Dự kiến người nhận lấy';

  @override
  String get ordDeliveryAddress => 'Địa chỉ giao';

  @override
  String get ordFromLocker => 'Gửi từ tủ';

  @override
  String get ordFlightDistance => 'Quãng đường bay';

  @override
  String get ordBasePrice => 'Giá gốc';

  @override
  String get ordExtraFees => 'Phí phát sinh';

  @override
  String get ordPointsUsed => 'Điểm đã dùng';

  @override
  String get ordTotal => 'Tổng tiền';

  @override
  String get ordRemaining => 'Còn phải trả';

  @override
  String get ordPaidAt => 'Thanh toán lúc';

  @override
  String get ordParcel => 'Kiện hàng';

  @override
  String get ordDeliveryIncident => 'Sự cố giao hàng';

  @override
  String get ordPaused => 'Đang tạm dừng';

  @override
  String get ordPausedAt => 'Tạm dừng lúc';

  @override
  String get ordDeliveryIncomplete => 'Giao không hoàn tất';

  @override
  String get ordRecordedAt => 'Ghi nhận lúc';

  @override
  String get ordParcelReturned => 'Đã trả kiện cho bạn';

  @override
  String ordNewBoxPinUpper(Object box) {
    return 'Mã PIN mở Ô MỚI (#$box):';
  }

  @override
  String get ordOldPinDisabledNote =>
      '🔒 Mã PIN ô cũ đã bị vô hiệu hoá. Chỉ sử dụng mã trên để mở ô mới an toàn.';

  @override
  String get ordPickupCodeForTech =>
      'Mã lấy hàng — đọc cho kỹ thuật viên khi tới lấy';

  @override
  String get ordTimeline => 'Mốc thời gian';

  @override
  String get payMethodWallet => 'Ví Lock.R';

  @override
  String get payMethodSepay => 'Chuyển khoản (SePay)';

  @override
  String get payMethodCash => 'Tiền mặt';

  @override
  String get ordPaymentMethod => 'Hình thức thanh toán';

  @override
  String get ordTransactionId => 'Mã giao dịch';

  @override
  String get ordPaymentTime => 'Thời gian thanh toán';

  @override
  String get ordTransferred => 'Đã chuyển tiền';

  @override
  String get ordRejected => 'Bị từ chối';

  @override
  String get ordAwaitingTransfer => 'Chờ chuyển khoản';

  @override
  String ordRefundHash(Object id) {
    return 'Hoàn tiền #$id';
  }

  @override
  String get ordRefundAmount => 'Số tiền hoàn';

  @override
  String get ordReceivingAccount => 'Tài khoản nhận';

  @override
  String get ordCompletedAt => 'Thời gian hoàn tất';

  @override
  String get ordRequestedAt => 'Thời gian yêu cầu';

  @override
  String get ordSeeRefunds => 'Xem chi tiết ở mục Hoàn tiền';

  @override
  String get ordExtensionPayment => 'Thanh toán gia hạn thời gian';

  @override
  String ordAttemptN(Object n) {
    return 'Lần $n';
  }

  @override
  String get ordInterventionRecord => 'Biên bản can thiệp & bảo vệ tài sản:';

  @override
  String ordBoxIncidentTitle(Object code) {
    return 'Sự cố ô tủ - Đơn hàng #$code';
  }

  @override
  String get ordViewTechEvidence => 'Xem chi tiết & ảnh minh chứng KTV';

  @override
  String get ordInfoRelocated =>
      'ℹ️ Hàng của bạn đã được chuyển sang ô mới. Vui lòng kiểm tra mã mở ô mới trong app.';

  @override
  String get ordInfoSealedHub =>
      'ℹ️ Hàng được niêm phong an toàn và đưa về Hub. Nhân viên sẽ liên hệ bạn để thu xếp lại.';

  @override
  String get ordInfoHandedOver =>
      'ℹ️ Hàng đã được bàn giao trực tiếp. Nếu có thắc mắc vui lòng liên hệ bộ phận CSKH.';

  @override
  String get ordEmailWithCode =>
      'Lock.R gửi lại mã mở tủ, nơi lấy và hạn lấy hàng tới email này. Sửa email nếu người nhận chưa nhận được thư.';

  @override
  String get ordEmailOrderInfo =>
      'Hàng chưa vào tủ: Lock.R gửi lại thư báo có đơn sắp tới (chưa kèm mã). Mã mở tủ được gửi khi bạn bỏ hàng vào ô.';

  @override
  String get ordEmailSaveOnly =>
      'Đơn chưa thanh toán. Lock.R báo người nhận qua email này khi đơn được thanh toán, và gửi mã mở tủ khi bạn bỏ hàng vào ô.';

  @override
  String get ordEnterRecipientEmail => 'Nhập email người nhận';

  @override
  String get ordSaveEmail => 'Lưu email';

  @override
  String get ordSendEmail => 'Gửi email';

  @override
  String get commonCopy => 'Sao chép';

  @override
  String get commonCopyTapHint => 'Chạm để sao chép';

  @override
  String get commonRemove => 'Bỏ';

  @override
  String get commonFullNameShort => 'Họ tên';

  @override
  String get commonSubtotal => 'Tạm tính';

  @override
  String get commonDiscountCode => 'Mã giảm giá';

  @override
  String get commonRewardPoints => 'Điểm thưởng';

  @override
  String get commonChooseLocker => 'Chọn tủ';

  @override
  String get commonBoxType => 'Loại ô';

  @override
  String get commonSelectedLocker => 'Tủ đã chọn';

  @override
  String get commonNoFreeBoxes => 'Hết ô';

  @override
  String commonFreeBoxes(Object count) {
    return 'Còn $count ô trống';
  }

  @override
  String get commonStayToPay => 'Ở lại thanh toán';

  @override
  String get commonCancelAndExit => 'Hủy đơn & Thoát';

  @override
  String get commonPaymentEyebrow => 'LOCK.R • THANH TOÁN';

  @override
  String commonOrderCode(Object code) {
    return 'Đơn $code';
  }

  @override
  String commonScanQrPayHold(Object minutes) {
    return 'Quét mã QR trên và chuyển khoản trong $minutes phút để giữ ô — mã bỏ hàng sẽ tự hiện sau khi thanh toán.';
  }

  @override
  String commonScanQrPayHoldRent(Object minutes) {
    return 'Quét mã QR trên và chuyển khoản trong $minutes phút để giữ ô — mã mở ô sẽ tự hiện sau khi thanh toán.';
  }

  @override
  String get commonPaySuccessPinReady =>
      'Thanh toán thành công! Mã PIN mở ô tủ đã sẵn sàng.';

  @override
  String daysValue(int days) {
    return '$days ngày';
  }

  @override
  String pricePerDay(Object price) {
    return '$price/ngày';
  }

  @override
  String get sizeSmallShort => 'Nhỏ';

  @override
  String get sizeMediumShort => 'Vừa';

  @override
  String get sizeLargeShort => 'Lớn';

  @override
  String get boxOfOrder => 'ô của đơn';

  @override
  String get sendBoxOpened =>
      'Ô đã mở — đặt hàng vào, đóng cửa rồi bấm xác nhận.';

  @override
  String get sendBoxOpenFailed => 'Không mở được ô';

  @override
  String get sendDroppedShare =>
      'Đã bỏ hàng. Gửi mã lấy hàng cho người nhận bằng nút Chia sẻ bên dưới.';

  @override
  String get sendEnterRecipientEmail =>
      'Nhập email người nhận để Lock.R gửi mã mở tủ';

  @override
  String get sendEnterRecipientPhone => 'Nhập số điện thoại người nhận';

  @override
  String get sendPhone10Digits => 'Số điện thoại gồm 10 số, bắt đầu bằng 0';

  @override
  String get sendCancelCreateQuestion => 'Hủy tạo đơn hàng?';

  @override
  String sendCancelCreateBody(Object minutes) {
    return 'Đơn hàng chưa được thanh toán. Nếu bạn thoát bây giờ hoặc không hoàn tất thanh toán trong vòng $minutes phút, đơn hàng sẽ bị hủy và ô tủ sẽ được giải phóng.';
  }

  @override
  String get sendCancelledReleased => 'Đã hủy đơn hàng và giải phóng ô tủ.';

  @override
  String get sendTitle => 'Gửi hàng qua tủ';

  @override
  String get sendSubtitle => 'Gửi đồ nhanh chóng & tiện lợi';

  @override
  String get sendCreateAndGetPin => 'Tạo đơn & lấy PIN bỏ hàng';

  @override
  String get sendLoadingLockers => 'Đang tải danh sách tủ...';

  @override
  String get sendIntro =>
      'Gửi hàng cho người khác qua tủ: bạn bỏ hàng vào ô bằng PIN, hệ thống sinh PIN mới gửi người nhận để họ tới lấy.';

  @override
  String get sendStandardOnly =>
      'Gửi hàng dùng ô thường; ô vali (XL) chỉ để thuê giữ đồ. Hãy chắc kiện hàng vừa ô trước khi tạo đơn.';

  @override
  String get sendRecipientPhoneHint => 'Số điện thoại người nhận';

  @override
  String get sendRecipientNameHint => 'Tên người nhận (tùy chọn)';

  @override
  String get sendRecipientEmailHint => 'Email người nhận';

  @override
  String get sendEmailInfo =>
      'Lock.R gửi email cho người nhận ngay khi đơn được thanh toán (báo có hàng sắp tới) và gửi mã lấy hàng khi bạn bỏ hàng vào ô. Gửi lại được trong chi tiết đơn; bấm \"Chia sẻ mã cho người nhận\" để gửi thêm qua Zalo/SMS.';

  @override
  String get sendRecipientMessage => 'Lời nhắn cho người nhận';

  @override
  String get sendMessageHint => 'VD: Hàng dễ vỡ, mở nhẹ tay (tùy chọn)';

  @override
  String sendBoxSize(Object size) {
    return 'Ô $size';
  }

  @override
  String get sendSelectedBox => 'Ô đã chọn';

  @override
  String sendFeePerParcel(Object price) {
    return '$price/lượt gửi';
  }

  @override
  String get sendBoxTaken => 'Ô vừa được đặt — chọn ô khác';

  @override
  String get sendStep1Title => 'Bước 1 — Bỏ hàng vào ô';

  @override
  String sendStep1Body(Object box) {
    return 'Đến tủ, nhập PIN bên dưới để mở $box, đặt hàng vào rồi đóng cửa.';
  }

  @override
  String get sendStep2Title => 'Bước 2 — Đã bỏ hàng xong';

  @override
  String get sendPinSentToRecipient =>
      'PIN nhận hàng đã được gửi tới tài khoản người nhận.';

  @override
  String get sendSharePinWithRecipient =>
      'Hãy chuyển mã PIN nhận hàng bên dưới cho người nhận.';

  @override
  String get sendRecipientEntersPin => 'Người nhận nhập PIN tại tủ để lấy hàng';

  @override
  String get sendEnterPinToDrop => 'Nhập PIN tại tủ để mở ô và bỏ hàng';

  @override
  String get sendLockrAccount => 'Tài khoản Lock.R';

  @override
  String get sendHasAccount => 'Đã có — PIN gửi thẳng vào app';

  @override
  String get sendNoAccount => 'Chưa có — bạn cần chuyển PIN cho người nhận';

  @override
  String sendPickupBefore(Object deadline, Object remaining, Object policy) {
    return 'Người nhận cần lấy hàng trước $deadline ($remaining). $policy';
  }

  @override
  String get sendDropInstructions =>
      'Mở ô bằng nút bên dưới hoặc nhập PIN tại tủ, đặt hàng vào, đóng cửa rồi xác nhận. Xác nhận ngay trên màn hình tủ cũng được.';

  @override
  String get sendOpenToDrop => 'Mở ô để bỏ hàng';

  @override
  String get sendIDropped => 'Tôi đã bỏ hàng vào ô';

  @override
  String get sendStepDrop => 'Bỏ hàng';

  @override
  String get sendStepRecipientPicks => 'Người nhận lấy';

  @override
  String get rentPaymentWaiting =>
      'Đang chờ xác nhận thanh toán, vui lòng đợi giây lát';

  @override
  String get rentOpenedStart => 'Ô đã mở thành công — bắt đầu kỳ thuê!';

  @override
  String get rentOpenSimulated =>
      'Không mở được ô thật (giả lập: đã xác nhận bỏ đồ & bắt đầu kỳ thuê)';

  @override
  String get rentCancelQuestion => 'Hủy tạo đơn thuê tủ?';

  @override
  String rentCancelBody(Object minutes) {
    return 'Đơn thuê tủ chưa được thanh toán. Nếu bạn thoát bây giờ hoặc không hoàn tất thanh toán trong vòng $minutes phút, đơn sẽ bị hủy và ô tủ sẽ được giải phóng.';
  }

  @override
  String get rentCancelledReleased => 'Đã hủy đơn thuê tủ và giải phóng ô tủ.';

  @override
  String get rentTitle => 'Thuê tủ giữ đồ';

  @override
  String get rentSubtitle => 'Chọn điểm tủ & thời gian sử dụng';

  @override
  String get rentNow => 'Thuê ngay';

  @override
  String get rentLoadingInfo => 'Đang tải thông tin điểm tủ...';

  @override
  String get rentIntro =>
      'Thuê ô để giữ đồ cá nhân theo giờ hoặc theo ngày. PIN mở ô được dùng nhiều lần trong suốt kỳ thuê.';

  @override
  String get rentDuration => 'Thời gian thuê';

  @override
  String get rentOptionalHint => 'Tùy chọn...';

  @override
  String rentDiscountValue(Object amount) {
    return 'Giảm: -$amount';
  }

  @override
  String rentPointsValue(Object value) {
    return 'Điểm thưởng: $value';
  }

  @override
  String get rentByHour => 'Theo giờ';

  @override
  String get rentByDay => 'Theo ngày';

  @override
  String get rentMinusDay => 'Bớt 1 ngày';

  @override
  String rentDaysHours(Object days, Object hours) {
    return '$days ngày · $hours giờ';
  }

  @override
  String get rentPlusDay => 'Thêm 1 ngày';

  @override
  String get rentRunning => 'Kỳ thuê đang chạy';

  @override
  String rentPinUntil(Object time) {
    return 'PIN mở ô nhiều lần tới $time.';
  }

  @override
  String get rentPinMultiUse => 'PIN dùng nhiều lần trong kỳ thuê';

  @override
  String rentExpiresAt(Object deadline, Object remaining, Object policy) {
    return 'Hết hạn thuê: $deadline ($remaining). $policy';
  }

  @override
  String get rentHeldDropOff => 'Đã giữ ô — bỏ đồ vào';

  @override
  String rentEnterPinToOpen(Object box) {
    return 'Nhập PIN để mở $box hoặc mở bằng nút bên dưới để bắt đầu kỳ thuê.';
  }

  @override
  String get rentOpenToDrop => 'Mở ô để bỏ đồ';

  @override
  String get rentExtensionUnpaid =>
      'Còn phí gia hạn chưa thanh toán — cần trả trước khi kết thúc thuê.';

  @override
  String get rentDoneSeeOrders => 'Xong — xem trong Đơn của tôi';

  @override
  String get cellAvailable => 'Trống';

  @override
  String get cellReservedHeld => 'Đã giữ chỗ';

  @override
  String get cellOccupied => 'Có đồ';

  @override
  String get cellAwaitingTechCheck => 'Chờ KTV kiểm tra';

  @override
  String get cellCleaning => 'Đang vệ sinh';

  @override
  String get stAwaitingDropoff => 'Chờ bỏ đồ';

  @override
  String get stAwaitingDispatch => 'Chờ điều phối';

  @override
  String get stAccepted => 'Đã tiếp nhận';

  @override
  String get stLaunching => 'Đang khởi phóng';

  @override
  String get stDropReported => 'Đã báo rơi kiện';

  @override
  String get stPickupAssigned => 'KTV đang tới lấy hàng';

  @override
  String get stPickedUpByTech => 'KTV đã lấy hàng';

  @override
  String get stFailed => 'Giao không thành công';

  @override
  String get stDeparted => 'Drone đã rời trạm';

  @override
  String get stEnRoute => 'Drone đang bay';

  @override
  String get stApproaching => 'Drone sắp đến';

  @override
  String get stArrived => 'Drone đã đến tủ';

  @override
  String get stReadyForPickup => 'Chờ nhận hàng';

  @override
  String get stStoring => 'Đang trong tủ';

  @override
  String get stCollected => 'Đã thu gom';

  @override
  String get stProcessing => 'Đang xử lý';

  @override
  String get stReadyToReturn => 'Sẵn sàng trả';

  @override
  String get stNew => 'Mới';

  @override
  String get stDone => 'Đã xong';

  @override
  String get stNotConfirmed => 'Không xác nhận';

  @override
  String get typeLaundry => 'Giặt ủi';

  @override
  String get typeStorage => 'Gửi đồ';

  @override
  String get typeParcel => 'Nhận hàng';

  @override
  String incidentSince(Object time) {
    return ' từ $time';
  }

  @override
  String incidentReportedCanOpen(Object since) {
    return 'Bạn đã báo sự cố ô — kỹ thuật viên sẽ tới kiểm tra. Bạn vẫn có thể mở ô bằng mã PIN để lấy đồ; phí quá giờ tạm dừng$since.';
  }

  @override
  String incidentBlocked(Object since) {
    return 'Ô đang chờ kỹ thuật viên xử lý sự cố. Đồ của bạn vẫn được giữ an toàn trong ô, phí quá giờ tạm dừng$since — bạn chưa cần thanh toán hay gia hạn. Lock.R sẽ báo khi lấy được đồ.';
  }

  @override
  String durDaysHours(Object days, Object hours) {
    return '$days ngày $hours giờ';
  }

  @override
  String durHoursMinutes(Object hours, Object minutes) {
    return '$hours giờ $minutes phút';
  }

  @override
  String get durUnderMinute => 'dưới 1 phút';

  @override
  String timeRemaining(Object time) {
    return 'Còn $time';
  }

  @override
  String timeOverdueBy(Object time) {
    return 'Quá hạn $time';
  }

  @override
  String get credEnterPinAtLocker => 'Nhập PIN tại màn hình tủ để mở ô';

  @override
  String get credPinCopied => 'Đã sao chép mã PIN';

  @override
  String credAt(Object name) {
    return 'Tại: $name';
  }

  @override
  String get unlockBlePermissionBlocked =>
      'Quyền Bluetooth (Thiết bị lân cận) đang bị chặn. Mở Cài đặt để cho phép rồi quét lại.';

  @override
  String get unlockBlePermissionDenied =>
      'App cần quyền Bluetooth để dò tủ. Bấm Quét lại và chọn Cho phép.';

  @override
  String get unlockBleOff =>
      'Bluetooth của điện thoại đang tắt. Bật Bluetooth rồi bấm Quét lại.';

  @override
  String get unlockBleUnsupported =>
      'Thiết bị này không hỗ trợ Bluetooth. Dùng Quét mã QR hoặc mã PIN.';

  @override
  String get unlockNoSignal => 'Chưa phát hiện sóng Bluetooth của tủ gần đây.';

  @override
  String unlockOpenBox(Object box) {
    return 'Mở $box';
  }

  @override
  String get unlockOverdueRental =>
      'Đơn thuê đã quá hạn. Đã ghi nhận xử lý phí quá giờ — mời bạn lấy đồ và đóng tủ để hoàn tất trả tủ.';

  @override
  String get unlockEndsRental =>
      'Mở ô sẽ kết thúc kỳ thuê và giải phóng ô tủ. Vui lòng lấy hết đồ.';

  @override
  String get unlockScanQr => 'Quét QR';

  @override
  String get unlockPin => 'Mã PIN';

  @override
  String get unlockScanning => 'Đang quét sóng Bluetooth của tủ...';

  @override
  String unlockStandClose(Object locker) {
    return 'Vui lòng đứng cách tủ $locker dưới 2m';
  }

  @override
  String get unlockConnected => 'Đã kết nối Bluetooth tủ';

  @override
  String get unlockSimulateRpi => 'Mô phỏng RPi';

  @override
  String unlockDistanceSignal(Object distance, Object rssi) {
    return 'Khoảng cách: $distance • Tín hiệu $rssi dBm';
  }

  @override
  String unlockOpenAndReturn(Object box) {
    return 'Mở $box & Trả tủ';
  }

  @override
  String unlockOpenNow(Object box) {
    return 'Mở $box ngay (1-chạm)';
  }

  @override
  String get unlockNotFound => 'Không tìm thấy sóng Bluetooth của tủ';

  @override
  String get unlockEnsureBluetooth =>
      'Đảm bảo điện thoại đã bật Bluetooth hoặc dùng Quét mã QR thay thế.';

  @override
  String get unlockScanAgain => 'Quét lại';

  @override
  String get unlockRescan => 'Dò sóng lại';

  @override
  String get unlockQrTitle => 'Xác thực qua tem QR trên tủ';

  @override
  String unlockQrBody(Object locker, Object box) {
    return 'Dùng camera điện thoại quét mã QR dán trên thân tủ $locker để mở $box.';
  }

  @override
  String get unlockStartCamera => 'Bật Camera quét tem QR';

  @override
  String get unlockKioskPinUpper => 'MÃ PIN MỞ TRÊN MÀN HÌNH KIOSK';

  @override
  String get unlockCodeCopied => 'Đã sao chép mã';

  @override
  String get unlockCopyPin => 'Sao chép mã PIN';

  @override
  String get unlockKioskGuide => 'Hướng dẫn mở tại màn hình Kiosk:';

  @override
  String unlockKioskStep1(Object locker) {
    return 'Đến trước màn hình cảm ứng của $locker.';
  }

  @override
  String get unlockKioskStep2 => 'Chọn nút \"Mở tủ\" hoặc \"Nhận đồ\".';

  @override
  String unlockKioskStep3(Object pin, Object box) {
    return 'Nhập mã PIN $pin để cửa $box bung chốt.';
  }

  @override
  String get extrasNotEligible => 'Đơn chưa đủ điều kiện áp mã này';

  @override
  String get extrasCodeInvalid => 'Mã không hợp lệ hoặc đã hết hạn';

  @override
  String extrasCodeApplied(Object code) {
    return 'Đã áp mã \"$code\"';
  }

  @override
  String get extrasChooseCode => 'Chọn mã giảm giá';

  @override
  String get extrasNoCodes => 'Chưa có mã giảm giá nào.';

  @override
  String get extrasNoCodesHere => 'Chưa có mã giảm giá dùng được ở tủ này.';

  @override
  String get tierBronze => 'Đồng';

  @override
  String get tierSilver => 'Bạc';

  @override
  String get tierGold => 'Vàng';

  @override
  String get tierPlatinum => 'Bạch kim';

  @override
  String tierNextPoints(Object points, Object tier) {
    return 'còn $points điểm lên hạng $tier';
  }

  @override
  String tierYouHavePoints(Object points) {
    return 'Bạn đang có $points điểm';
  }

  @override
  String tierRank(Object tier) {
    return 'hạng $tier';
  }

  @override
  String get tierHighest => 'hạng cao nhất';

  @override
  String get payStatusPaid => 'Đã thanh toán';

  @override
  String get payStatusPending => 'Chờ thanh toán';

  @override
  String get payStatusFailed => 'Thanh toán lỗi';

  @override
  String get payStatusNone => 'Chưa có thanh toán';

  @override
  String rulesRentRange(Object min, Object max) {
    return 'Thuê từ $min đến $max.';
  }

  @override
  String rulesEvery24h(Object price) {
    return 'Mỗi 24 giờ tính $price.';
  }

  @override
  String rulesDailyCapFrom(Object hours, Object price) {
    return 'Thuê từ $hours giờ trong một ngày chỉ tính giá ngày $price.';
  }

  @override
  String rulesRentalOvertime(Object rate) {
    return 'Quá giờ thuê tính $rate cho tới khi lấy đồ hoặc gia hạn.';
  }

  @override
  String get rulesNoOvertimeFee => 'Không tính phí quá giờ.';

  @override
  String rulesPercentOfOrder(Object percent) {
    return '$percent% giá trị đơn';
  }

  @override
  String rulesCapSuffix(Object caps) {
    return ' (tối đa $caps)';
  }

  @override
  String get rulesAnd => ' và ';

  @override
  String rulesOvertimeFee(Object rate, Object cap) {
    return 'Phí quá giờ $rate$cap.';
  }

  @override
  String rulesSendPickup(Object hours, Object policy) {
    return 'Người nhận có $hours giờ để lấy hàng kể từ lúc bạn bỏ hàng vào ô. $policy';
  }

  @override
  String rulesDronePickup(Object hours, Object policy) {
    return 'Đơn hàng được lưu trữ $hours giờ kể từ lúc drone thả hàng vào ô. Giờ và ngày hết hạn sẽ được báo ngay khi hàng vào ô. $policy';
  }

  @override
  String rulesDroneStoredUntil(Object hours, Object deadline) {
    return 'Đơn hàng được lưu trữ $hours giờ, vui lòng lấy trước $deadline.';
  }

  @override
  String rulesLoyaltyEarn(Object percent, Object value) {
    return 'Tích $percent% số tiền bạn thanh toán thành điểm (1 điểm = $value), cộng khi đơn hoàn tất.';
  }

  @override
  String get rulesRedeemDisabled =>
      'Hiện chưa áp dụng dùng điểm để thanh toán.';

  @override
  String rulesRedeemMin(Object points) {
    return ' (từ $points điểm)';
  }

  @override
  String rulesRedeem(Object value, Object percent, Object min) {
    return '1 điểm = $value khi thanh toán, dùng tối đa $percent% giá trị đơn$min.';
  }

  @override
  String get loyaltyRedeemDisabled =>
      'Hiện chưa áp dụng dùng điểm để thanh toán';

  @override
  String get loyaltyFullyDiscounted =>
      'Đơn đã được giảm hết, không cần dùng điểm';

  @override
  String get loyaltyNoPoints =>
      'Bạn chưa có điểm — điểm được cộng khi đơn hoàn tất';

  @override
  String loyaltyBelowMin(Object balance, Object min) {
    return 'Bạn có $balance điểm, cần tối thiểu $min điểm mỗi lần dùng';
  }

  @override
  String loyaltyOrderTooSmall(Object min) {
    return 'Đơn chưa đủ giá trị để dùng tối thiểu $min điểm';
  }

  @override
  String loyaltyOffer(Object points, Object amount) {
    return 'Dùng $points điểm · giảm $amount';
  }

  @override
  String loyaltyYouHave(Object balance) {
    return 'Bạn có $balance điểm';
  }

  @override
  String loyaltyRule(Object value, Object percent) {
    return '1 điểm = $value, tối đa $percent% giá trị đơn';
  }

  @override
  String loyaltyPointsDiscount(Object amount, Object points) {
    return '-$amount ($points điểm)';
  }

  @override
  String get loyaltyCantUseNow =>
      'Chưa dùng được điểm thưởng lúc này — đơn được tính đủ giá.';

  @override
  String loyaltyPlusPoints(Object points) {
    return '+$points điểm';
  }

  @override
  String get loyaltyWillEarn => 'Điểm sẽ được cộng';

  @override
  String get loyaltyEarned => 'Điểm được cộng';

  @override
  String get loyaltyNotRecorded => 'Chưa ghi nhận';

  @override
  String loyaltyReversed(Object text, Object points) {
    return '$text · đã thu hồi $points';
  }

  @override
  String get loyaltyChecking => 'Đang kiểm tra điểm thưởng...';

  @override
  String get loyaltyLoadFailed =>
      'Chưa tải được điểm thưởng — đơn được tính đủ giá.';

  @override
  String get loyaltyUsePoints => 'Dùng điểm thưởng';

  @override
  String get sepayCreateFailed =>
      'Không tạo được giao dịch thanh toán. Vui lòng thử lại.';

  @override
  String get sepayNoQr =>
      'Máy chủ chưa trả mã VietQR cho giao dịch này. Vui lòng thử lại sau.';

  @override
  String get sepayNoTxForSim =>
      'Chưa có mã giao dịch để giả lập. Vui lòng thử lại.';

  @override
  String get sepayReceivedUpdating =>
      'Hệ thống đã nhận được tiền, đơn hàng đang được cập nhật...';

  @override
  String sepayPartial(Object received, Object remaining) {
    return 'Đã nhận $received — còn thiếu $remaining. Mã QR bên dưới là số còn thiếu.';
  }

  @override
  String get sepayScanToPay => 'Quét mã VietQR để thanh toán';

  @override
  String get sepayQrLoadFailed => 'Không tải được mã QR';

  @override
  String get sepayAccountNumber => 'Số tài khoản:';

  @override
  String get sepayAmountToTransfer => 'Số tiền cần chuyển:';

  @override
  String get sepayTransferContent => 'Nội dung chuyển khoản:';

  @override
  String get sepayContentCopied => 'Đã sao chép nội dung chuyển khoản';

  @override
  String get sepayWaiting => 'Đang chờ xác nhận thanh toán…';

  @override
  String get sepayAutoUpdate => 'Tự động cập nhật ngay sau khi nhận được tiền.';

  @override
  String get sepayPayWithBankApp => 'Thanh toán bằng app ngân hàng';

  @override
  String get sepayTransferExact =>
      'Chuyển khoản đúng số tài khoản, số tiền và nội dung bên dưới.';

  @override
  String get sepayCreatingQr => 'Đang tạo mã thanh toán…';

  @override
  String get apiErrBleTestNotGranted =>
      'Tài khoản chưa được admin cho thử mở ô qua Bluetooth ở tủ này.';

  @override
  String get apiErrResolutionPhotoRequired =>
      'Cần ít nhất 1 ảnh nghiệm thu trước khi hoàn tất phiếu.';

  @override
  String get apiErrLandingPadAbsent => 'Tủ này không có bãi đáp drone.';

  @override
  String get apiErrLandingPadStatusInvalid =>
      'Trạng thái bãi đáp không hợp lệ.';

  @override
  String get apiErrReportNotClaimable =>
      'Phiếu không còn ở trạng thái chờ nhận.';

  @override
  String get apiErrDroneRouteRequired => 'Cần chọn cả tủ gửi và tủ nhận.';

  @override
  String get apiErrDroneRouteInvalid => 'Tủ gửi và tủ nhận phải khác nhau.';

  @override
  String get apiErrDroneRouteTooFar =>
      'Tủ nhận nằm ngoài tầm bay của drone từ khu vực lấy hàng này.';

  @override
  String get apiErrDroneRouteTooShort =>
      'Tủ nhận ở quá gần điểm lấy hàng nên không cần giao bằng drone — hãy gửi thẳng vào tủ nhận.';

  @override
  String get apiErrDronePickupOutOfRange =>
      'Vị trí ghim nằm ngoài bán kính lấy hàng của tủ gửi drone. Khoảng cách này tính từ nhà bạn đến tủ gửi, khác quãng đường bay giữa hai tủ. Hãy kiểm tra ghim trên bản đồ rồi chọn lại vị trí.';

  @override
  String get apiErrDroneNoSourceLocker =>
      'Hiện chưa có tủ nào gần bạn sẵn sàng phóng drone. Vui lòng thử lại sau.';

  @override
  String get apiErrDroneLockerLocationMissing =>
      'Tủ nhận chưa có toạ độ nên chưa giao drone tới được.';

  @override
  String get apiErrDronePickupAddressRequired => 'Cần nhập địa chỉ lấy hàng.';

  @override
  String get apiErrDronePickupLocationRequired =>
      'Cần chọn vị trí lấy hàng trên bản đồ.';

  @override
  String get apiErrDroneSenderNameRequired => 'Cần nhập tên người gửi.';

  @override
  String get apiErrDroneSenderPhoneInvalid =>
      'Số điện thoại người gửi không hợp lệ.';

  @override
  String get apiErrDroneSenderEmailInvalid => 'Email người gửi không hợp lệ.';

  @override
  String get apiErrDroneReceiverNameRequired => 'Cần nhập tên người nhận.';

  @override
  String get apiErrDroneReceiverEmailInvalid =>
      'Email người nhận không hợp lệ.';

  @override
  String get apiErrDroneParcelCategoryRequired => 'Cần chọn loại hàng.';

  @override
  String get apiErrDronePickupNotOffered =>
      'Việc lấy hàng này không còn được mời cho bạn.';

  @override
  String get apiErrDronePickupOfferExpired => 'Lời mời lấy hàng đã hết hạn.';

  @override
  String get apiErrDronePickupNotAssignedToUser =>
      'Việc lấy hàng này không thuộc về bạn.';

  @override
  String get apiErrDronePickupNotFound =>
      'Đơn chưa có việc lấy hàng (có thể chưa thanh toán).';

  @override
  String get apiErrDronePickupCodeInvalid =>
      'Mã lấy hàng không đúng. Nhờ người gửi đọc lại mã trong đơn.';

  @override
  String get apiErrDronePickupParcelNotVerified =>
      'Cần xác nhận kiện đúng khai báo, hoặc báo không lấy được hàng.';

  @override
  String get apiErrDroneParcelNotPickedUp => 'Kiện chưa được lấy từ người gửi.';

  @override
  String get apiErrDroneOrderBlocked =>
      'Đơn đang tạm dừng vì sự cố, chưa đi lấy hàng lúc này.';

  @override
  String get apiErrDroneTechnicianLocationRequired =>
      'Cần bật định vị để vào ca nhận việc lấy hàng.';

  @override
  String get apiErrDroneTechnicianHasActivePickup =>
      'Bạn còn việc lấy hàng đã nhận. Hoàn tất hoặc báo không lấy được trước khi ra ca.';

  @override
  String get apiErrDroneTechnicianOffDuty => 'Kỹ thuật viên này chưa vào ca.';

  @override
  String get apiErrDroneTechnicianBusy =>
      'Kỹ thuật viên này đang bận việc khác.';

  @override
  String get apiErrDroneFailureReasonInvalid =>
      'Lý do không hợp lệ cho thao tác này.';

  @override
  String get apiErrDroneUnchanged =>
      'Drone này đang được gán cho nhiệm vụ rồi.';

  @override
  String get apiErrDroneFlightsSuspended =>
      'Dịch vụ giao drone đang tạm dừng (thời tiết hoặc sự cố vận hành).';

  @override
  String get apiErrDroneOutsideFlightHours =>
      'Ngoài khung giờ được phép phóng drone.';

  @override
  String get apiErrDroneOpenOrderLimit =>
      'Bạn đang có quá nhiều đơn drone chưa hoàn tất. Hoàn tất hoặc huỷ bớt rồi đặt tiếp.';

  @override
  String get apiErrDroneProhibitedItemsNotDeclared =>
      'Bạn cần cam kết kiện không chứa hàng cấm bay.';

  @override
  String get apiErrDroneParcelSizeInvalid =>
      'Nhập đủ dài, rộng, cao của kiện hoặc bỏ trống cả ba.';

  @override
  String get apiErrDroneParcelTooLarge =>
      'Kiện không lọt khoang hàng của drone.';

  @override
  String get apiErrDroneParcelCategoryInvalid => 'Loại hàng không hợp lệ.';

  @override
  String get apiErrDroneDeclaredValueTooHigh =>
      'Giá trị khai báo vượt mức drone được phép chở.';

  @override
  String get apiErrDroneParcelNotDropped =>
      'Người gửi chưa xác nhận bỏ kiện vào ô gửi nên chưa thể tiếp nhận.';

  @override
  String get apiErrDroneParcelReturnNotPending =>
      'Đơn này không có kiện nào chờ trả.';

  @override
  String get apiErrDroneBatteryUnknown =>
      'Chưa biết mức pin của drone, hãy cập nhật pin trước khi bay.';

  @override
  String get apiErrDroneSurchargeNotOwed =>
      'Đơn không còn nợ phụ thu cân lệch.';

  @override
  String get apiErrDroneSourceNotFound => 'Không tìm thấy tủ gửi.';

  @override
  String get apiErrDroneDestinationNotFound => 'Không tìm thấy tủ nhận.';

  @override
  String get apiErrDroneLockerInactive =>
      'Tủ gửi hoặc tủ nhận đang ngừng hoạt động.';

  @override
  String get apiErrDroneSourceCellUnavailable =>
      'Ô drone ở tủ gửi đang có đơn khác. Vui lòng chờ đội bay nạp hàng hoặc chọn tủ khác.';

  @override
  String get apiErrDroneSourceCellMismatch =>
      'Ô drone đã chọn không thuộc tủ gửi này.';

  @override
  String get apiErrDroneCellRequired => 'Chỉ đặt giao drone được ở ô drone.';

  @override
  String get apiErrBoxNotAvailable =>
      'Ô tủ không còn trống. Vui lòng chọn ô hoặc tủ khác.';

  @override
  String get apiErrDroneDemoNotAllowed =>
      'Tài khoản chưa được dùng chế độ mô phỏng drone.';

  @override
  String get apiErrDroneOrderUnpaid =>
      'Đơn chưa thanh toán nên chưa thể tiếp nhận.';

  @override
  String get apiErrDroneOrderStatusInvalid =>
      'Đơn không còn ở bước cho phép thao tác này.';

  @override
  String get apiErrDroneMissionAlreadyExists =>
      'Đơn đã có điều phối viên khác tiếp nhận.';

  @override
  String get apiErrDroneMissionStatusInvalid =>
      'Nhiệm vụ không còn ở bước cho phép thao tác này.';

  @override
  String get apiErrDroneMissionNotAssignedToUser =>
      'Chỉ điều phối viên đã tiếp nhận mới thao tác được nhiệm vụ này.';

  @override
  String get apiErrDroneWrongSourceLocker =>
      'Drone được chọn không đỗ tại tủ gửi của đơn.';

  @override
  String get apiErrDroneInactive => 'Drone đã ngừng hoạt động.';

  @override
  String get apiErrDroneNotIdle =>
      'Drone không còn sẵn sàng, hãy chọn drone khác.';

  @override
  String get apiErrDroneBatteryTooLow =>
      'Pin drone quá thấp để bay, cần sạc trước.';

  @override
  String get apiErrDroneStatusConflict =>
      'Trạng thái drone vừa thay đổi, hãy tải lại và thử lại.';

  @override
  String get apiErrDroneReservationLost =>
      'Drone không còn được giữ cho nhiệm vụ này (có thể đã báo lỗi).';

  @override
  String get apiErrDronePayloadTooHeavy =>
      'Kiện hàng vượt tải trọng cho phép của drone.';

  @override
  String get apiErrDroneLoadingNotConfirmed =>
      'Cần xác nhận nạp hàng trước khi phóng.';

  @override
  String get apiErrDroneSurchargeUnpaid =>
      'Kiện nặng hơn khai báo. Chờ khách trả thêm phần phí chênh rồi mới phóng được.';

  @override
  String get apiErrDroneParcelWeightInvalid =>
      'Khối lượng kiện hàng không hợp lệ.';

  @override
  String get apiErrDroneAlreadyInFlight =>
      'Drone đã cất cánh, không thể huỷ nhiệm vụ.';

  @override
  String get apiErrDroneCancelNoteRequired =>
      'Cần nhập ghi chú khi chọn lý do Khác.';

  @override
  String get apiErrDroneStageAutomated =>
      'Đơn mô phỏng tự chuyển chặng, không cần xác nhận tay.';

  @override
  String get apiErrDroneReceiverPhoneInvalid =>
      'Số điện thoại người nhận không hợp lệ.';

  @override
  String get apiErrLockerInactive => 'Tủ đang ngừng hoạt động.';

  @override
  String get apiErrLandingPadUnavailable => 'Bãi đáp drone chưa sẵn sàng.';

  @override
  String get apiErrDroneOwnershipRequired =>
      'Bạn cần nhận phụ trách drone này trước.';

  @override
  String get apiErrDroneAlreadyAssigned =>
      'Drone đã có kỹ thuật viên khác phụ trách.';

  @override
  String get apiErrDroneActiveMission =>
      'Drone đang có nhiệm vụ, chỉ được báo lỗi (FAULT).';

  @override
  String get apiErrDroneFaultReasonRequired =>
      'Cần nhập lý do khi báo drone lỗi.';

  @override
  String get apiErrDronePaymentRequiredBeforePickup =>
      'Vui lòng thanh toán đơn drone trước khi mở tủ nhận hàng.';

  @override
  String get apiErrOrderStatusInvalid =>
      'Đơn không còn ở trạng thái cho phép thao tác này.';

  @override
  String get apiErrNotSupportedUpdate =>
      'Máy chủ chưa hỗ trợ chức năng này. Vui lòng cập nhật hệ thống rồi thử lại.';

  @override
  String get apiErrForbidden => 'Bạn không có quyền thực hiện thao tác này';

  @override
  String get apiErrConnection => 'Lỗi kết nối máy chủ';

  @override
  String get apiErrGeneric => 'Đã xảy ra lỗi';

  @override
  String get commonSending => 'Đang gửi...';

  @override
  String get commonDescription => 'Mô tả';

  @override
  String get commonNo => 'Không';

  @override
  String get commonOrder => 'Đơn hàng';

  @override
  String get commonTime => 'Thời gian';

  @override
  String get commonMessage => 'Lời nhắn';

  @override
  String get recvLoadFailed => 'Không đọc được chi tiết đơn. Vui lòng thử lại.';

  @override
  String get recvNotInList =>
      'Đơn không còn trong danh sách của bạn (có thể đã được ủy quyền cho người khác). Đang hiện thông tin đã lưu.';

  @override
  String get recvSummaryOnly =>
      'Máy chủ chưa hỗ trợ xem chi tiết đầy đủ — đang hiện thông tin tóm tắt.';

  @override
  String recvEmailSent(Object withCode, Object email) {
    return 'Đã gửi thông tin đơn$withCode tới $email.';
  }

  @override
  String get recvWithCode => ' kèm mã mở tủ';

  @override
  String get recvYourEmail => 'email của bạn';

  @override
  String get recvNoEmail => 'Chưa có email';

  @override
  String get recvNoEmailBody =>
      'Tài khoản của bạn chưa có email để nhận thông tin đơn. Bổ sung email trong Hồ sơ rồi gửi lại.';

  @override
  String get recvAddEmail => 'Bổ sung email';

  @override
  String get recvDelegateDetail => 'Chi tiết đơn lấy hộ';

  @override
  String get recvDetail => 'Chi tiết đơn nhận';

  @override
  String get recvDelegator => 'Người ủy quyền';

  @override
  String get recvSender => 'Người gửi';

  @override
  String get recvPickupCode => 'Mã lấy hàng';

  @override
  String recvOpenBoxPickup(Object box) {
    return 'Mở $box lấy hàng';
  }

  @override
  String get recvTrackDrone => 'Theo dõi drone';

  @override
  String get recvSendingEmail => 'Đang gửi email…';

  @override
  String get recvResendEmail => 'Gửi lại thông tin qua email';

  @override
  String get recvSenderPhone => 'SĐT người gửi';

  @override
  String get recvSenderEmail => 'Email người gửi';

  @override
  String get recvRecipientName => 'Tên người nhận';

  @override
  String get recvRecipientPhone => 'SĐT người nhận';

  @override
  String get recvDelegatePerson => 'Người lấy hộ';

  @override
  String recvYouSuffix(Object name) {
    return '$name (bạn)';
  }

  @override
  String get recvYou => 'Bạn';

  @override
  String get recvDelegatePhone => 'SĐT lấy hộ';

  @override
  String get recvDelegation => 'Ủy quyền';

  @override
  String get recvOwnerDelegated => 'Chủ đơn đã ủy quyền người khác lấy hộ';

  @override
  String get recvLockerAndBox => 'Tủ & ô';

  @override
  String get recvReceivingLocker => 'Tủ nhận';

  @override
  String get recvLockerCode => 'Mã tủ';

  @override
  String get recvBoxSize => 'Kích cỡ ô';

  @override
  String get recvSourceAddress => 'Địa chỉ tủ gửi';

  @override
  String get recvSenderNote => 'Ghi chú người gửi';

  @override
  String get recvPickupDeadline => 'Hạn lấy';

  @override
  String get recvTimeLeft => 'Còn lại';

  @override
  String get recvExpectedPickup => 'Dự kiến lấy';

  @override
  String get recvCreatedAt => 'Tạo đơn lúc';

  @override
  String get recvCompletedAt => 'Hoàn tất lúc';

  @override
  String get recvUpdatedAt => 'Cập nhật lần cuối';

  @override
  String get recvTimeline => 'Dòng thời gian';

  @override
  String get recvDroneJourney => 'Hành trình drone';

  @override
  String get recvCurrentStage => 'Chặng hiện tại';

  @override
  String get recvEta => 'Dự kiến tới tủ';

  @override
  String get recvArrived => 'Đã tới';

  @override
  String recvAboutMinutes(Object minutes) {
    return 'Khoảng $minutes phút';
  }

  @override
  String get recvIncident => 'Sự cố';

  @override
  String get recvParcelReturnedToSender => 'Đã trả kiện cho người gửi';

  @override
  String get recvCodeMovedToDelegate =>
      'Chủ đơn đã ủy quyền người khác lấy hộ nên mã lấy hàng không còn hiện ở đây.';

  @override
  String get recvCredCaption =>
      'Nhập PIN hoặc quét QR tại tủ, hoặc mở ô ngay trên app';

  @override
  String get recvOverdueMayCharge =>
      'Đơn đã quá hạn lấy — có thể phát sinh phí quá giờ.';

  @override
  String get recvCompleted => 'Đơn đã hoàn tất — hàng đã được lấy.';

  @override
  String recvCompletedAtTime(Object time) {
    return 'Đơn đã hoàn tất — hàng đã được lấy lúc $time.';
  }

  @override
  String get recvCancelled => 'Đơn đã hủy nên không còn mã lấy hàng.';

  @override
  String get recvExpired =>
      'Đơn đã quá hạn lấy, ô đã được thu hồi. Vui lòng liên hệ người gửi hoặc hỗ trợ Lock.R.';

  @override
  String recvDroneNotReady(Object stage) {
    return '$stage. Mã lấy hàng sẽ hiện khi drone đã đặt kiện vào ô tủ nhận.';
  }

  @override
  String get recvSenderNotDropped =>
      'Người gửi chưa bỏ hàng vào ô. Mã lấy hàng sẽ hiện khi hàng đã nằm trong ô.';

  @override
  String get recvNotReady =>
      'Hàng chưa sẵn sàng. Mã lấy hàng sẽ hiện khi hàng đã nằm trong ô.';

  @override
  String get recvSenderPaid => 'Người gửi đã thanh toán';

  @override
  String get recvRefundingSender => 'Đang hoàn tiền cho người gửi';

  @override
  String get recvSenderRefunded => 'Đã hoàn tiền cho người gửi';

  @override
  String get recvSenderUnpaid => 'Người gửi chưa thanh toán';

  @override
  String get recvOrderCodeCopied => 'Đã sao chép mã đơn';

  @override
  String get recvCopyOrderCode => 'Sao chép mã đơn';

  @override
  String get recvYouAreDelegate => 'Bạn được ủy quyền lấy hộ đơn này.';

  @override
  String get recvYouAreRecipient => 'Bạn là người nhận của đơn này.';

  @override
  String recvOverdueBy(Object duration) {
    return 'Đơn đã quá hạn lấy $duration — lấy hàng sớm để tránh phí quá giờ.';
  }

  @override
  String get recvNoCodeYet =>
      'Đơn chưa có mã lấy hàng — hàng có thể chưa được bỏ vào ô.';

  @override
  String recvBoxOpenedPickup(Object box) {
    return 'Tủ đã mở $box — lấy hàng rồi đóng cửa tủ lại.';
  }

  @override
  String get recvOpenByCodeNotSupported =>
      'Máy chủ chưa hỗ trợ mở ô bằng mã. Hãy nhập mã tại màn hình tủ.';

  @override
  String recvLockerWithCode(Object code) {
    return 'Tủ $code';
  }

  @override
  String get recvDelegatorColon => 'Người ủy quyền:';

  @override
  String get recvSenderColon => 'Người gửi:';

  @override
  String get recvDelegatedPickup => 'Lấy hộ';

  @override
  String get recvIncomingParcel => 'Hàng nhận';

  @override
  String get recvStorageBox => 'Ô lưu đồ';

  @override
  String get recvCodeMovedShort =>
      'Chủ đơn đã ủy quyền người khác lấy hộ nên mã lấy hàng không còn hiện ở đây.';

  @override
  String get recvCredCaptionShort => 'Nhập PIN tại tủ hoặc mở ô ngay trên app';

  @override
  String get recvReceived => 'Đã nhận hàng';

  @override
  String get recvDelegated => 'Đã ủy quyền lấy hộ';

  @override
  String get recvOverdueHurry =>
      'Đơn đã quá hạn lấy — hãy lấy hàng sớm để tránh phát sinh thêm phí.';

  @override
  String get recvCodeTransferred =>
      'Chủ đơn đã ủy quyền người khác lấy hộ — mã lấy hàng đã chuyển sang người lấy hộ.';

  @override
  String get detailCantCall => 'Máy này không gọi điện được.';

  @override
  String detailCopiedLabel(Object label) {
    return 'Đã sao chép $label';
  }

  @override
  String detailCallLabel(Object label) {
    return 'Gọi $label';
  }

  @override
  String detailCopyLabel(Object label) {
    return 'Sao chép $label';
  }

  @override
  String get parcelCategory => 'Loại hàng';

  @override
  String get parcelWeight => 'Cân nặng';

  @override
  String get parcelSize => 'Kích thước';

  @override
  String get parcelFragile => 'Hàng dễ vỡ';

  @override
  String get parcelFragileYes => 'Có — nhẹ tay';

  @override
  String get parcelDeclaredValue => 'Giá trị khai báo';

  @override
  String get parcelNoProhibited => 'Cam kết không hàng cấm';

  @override
  String get delegateTitle => 'Ủy quyền lấy hộ';

  @override
  String get delegateBody =>
      'Người được ủy quyền thấy đơn và mã mở ô trong mục \"Đơn ủy quyền\" của app (theo số điện thoại). Mã PIN hiện tại sẽ được đổi mới.';

  @override
  String get delegatePhone => 'Số điện thoại người lấy hộ';

  @override
  String get delegateName => 'Tên người lấy hộ (không bắt buộc)';

  @override
  String get delegateMessage => 'Lời nhắn (không bắt buộc)';

  @override
  String get delegateInvalidPhone => 'Nhập số điện thoại hợp lệ (9–11 số).';

  @override
  String get delegateNotSupported => 'Máy chủ chưa hỗ trợ ủy quyền lấy hộ.';

  @override
  String get delegateAction => 'Ủy quyền';

  @override
  String get shareCopiedMessage =>
      'Đã sao chép tin nhắn, dán vào Zalo, Messenger hoặc SMS để gửi cho người nhận.';

  @override
  String get shareCantOpenSheet => 'Không mở được bảng chia sẻ';

  @override
  String get shareCantOpenSms => 'Không mở được ứng dụng tin nhắn';

  @override
  String get shareTheRecipient => 'người nhận';

  @override
  String get shareTitle => 'Gửi mã cho người nhận';

  @override
  String shareBody(Object who) {
    return 'Người nhận nhập mã tại màn hình tủ để mở ô. Gửi tin nhắn soạn sẵn cho $who qua Zalo, Messenger hoặc SMS.';
  }

  @override
  String get shareButton => 'Chia sẻ mã cho người nhận';

  @override
  String get shareSms => 'Nhắn SMS';

  @override
  String get shareCopyMessage => 'Sao chép tin nhắn';

  @override
  String shareMsgLocker(Object where) {
    return 'Bạn có kiện hàng gửi tới tủ $where.';
  }

  @override
  String shareMsgDrone(Object where) {
    return 'Bạn có kiện hàng giao bằng drone đang chờ tại tủ $where.';
  }

  @override
  String shareMsgBox(Object number) {
    return 'Ô số $number.';
  }

  @override
  String shareMsgCode(Object code) {
    return 'Mã lấy hàng: $code.';
  }

  @override
  String shareMsgDeadline(Object deadline) {
    return 'Hạn lấy: $deadline.';
  }

  @override
  String get shareMsgHowTo => 'Nhập mã tại màn hình tủ (kiosk) để mở ô.';

  @override
  String get timelineTitle => 'Lịch sử trạng thái';

  @override
  String get timelineLoadFailed => 'Không tải được lịch sử trạng thái.';

  @override
  String get timelineEmpty => 'Chưa có chuyển trạng thái nào.';

  @override
  String timelineFrom(Object status) {
    return 'Từ $status';
  }

  @override
  String get pickerNoLockers => 'Chưa có tủ khả dụng';

  @override
  String get pickerTapToChange => 'Chạm để chọn tủ khác';

  @override
  String pickerUnavailable(Object reason) {
    return 'Tạm không khả dụng: $reason';
  }

  @override
  String payTransferAmount(Object amount) {
    return 'Thanh toán chuyển khoản · $amount';
  }

  @override
  String get payScanAnyBank =>
      'Quét mã bằng app ngân hàng bất kỳ hoặc mở thẳng app ngân hàng.';

  @override
  String get svcRentSubtitle => 'Thuê ô theo giờ, PIN dùng nhiều lần';

  @override
  String get svcSendSubtitle => 'Bỏ hàng vào ô, gửi PIN cho người nhận';

  @override
  String get qrEnterLockerCode => 'Vui lòng nhập mã tủ.';

  @override
  String get qrThisLocker => 'tủ này';

  @override
  String qrLockerCodeMismatch(Object locker) {
    return 'Mã tủ không khớp với $locker.';
  }

  @override
  String get qrEnterLockerCodeTitle => 'Nhập mã tủ';

  @override
  String get qrLockerCodeHint => 'Mã in trên thân tủ';

  @override
  String qrCodeMismatch(Object locker) {
    return 'Mã QR không khớp với $locker.\nVui lòng quét đúng mã QR dán trên thân tủ.';
  }

  @override
  String get qrLockerBoxGeneric => 'ô tủ';

  @override
  String qrScanToOpen(Object box) {
    return 'Quét mở $box';
  }

  @override
  String qrLockerCodeValue(Object code) {
    return 'Mã tủ: $code';
  }

  @override
  String get qrPointCamera =>
      'Hướng camera về phía tem mã QR dán trên mặt tủ để xác thực bạn đang đứng tại tủ.';

  @override
  String get qrCantScan => 'Không quét được? Nhập mã tủ';

  @override
  String secondsValue(Object seconds) {
    return '$seconds giây';
  }

  @override
  String durDays(int days) {
    return '$days ngày';
  }

  @override
  String durDaysHoursLong(Object days, Object hours) {
    return '$days ngày $hours giờ';
  }

  @override
  String durHours(int hours) {
    return '$hours giờ';
  }

  @override
  String durHoursMinutesLong(Object hours, Object minutes) {
    return '$hours giờ $minutes phút';
  }

  @override
  String durMinutesSeconds(Object minutes, Object seconds) {
    return '$minutes phút $seconds giây';
  }

  @override
  String get incStReported => 'Đã ghi nhận';

  @override
  String get incStEvidencePending => 'Đang thu thập bằng chứng';

  @override
  String get incStInvestigating => 'Đang điều tra';

  @override
  String get incStRecoveryInProgress => 'Đang thu hồi kiện';

  @override
  String get incStAwaitingAdmin => 'Chờ quản trị viên xem xét';

  @override
  String get incStResolutionProposed => 'Đã có phương án xử lý';

  @override
  String get incStAwaitingCustomer => 'Chờ bạn phản hồi phương án';

  @override
  String get incStResolutionInProgress => 'Đang thực hiện phương án';

  @override
  String get incStDisputed => 'Đang xem xét lại theo yêu cầu';

  @override
  String get incStResolved => 'Đã xử lý xong';

  @override
  String get incStClosed => 'Đã đóng';

  @override
  String get incStManual => 'Nhân viên đang xử lý trực tiếp';

  @override
  String get recStOpen => 'Mới mở';

  @override
  String get recStAwaitingAssignment => 'Chờ phân công người thu hồi';

  @override
  String get recStAssigned => 'Đã phân công';

  @override
  String get recStAccepted => 'Nhân viên đã nhận việc';

  @override
  String get recStSearching => 'Đang tìm kiện';

  @override
  String get recStFound => 'Đã tìm thấy kiện';

  @override
  String get recStNotFound => 'Chưa tìm thấy kiện';

  @override
  String get recStRecovered => 'Đã thu hồi kiện';

  @override
  String get recStSubmitted => 'Đã báo kết quả thu hồi';

  @override
  String get recStVerified => 'Đã xác minh kết quả';

  @override
  String get recStClosed => 'Đã bàn giao kiện về kho';

  @override
  String get recStCancelled => 'Đã huỷ';

  @override
  String get parStInTransit => 'Đang vận chuyển';

  @override
  String get parStDropReported => 'Đã báo rơi';

  @override
  String get parStRecoveryPending => 'Chờ thu hồi';

  @override
  String get parStFound => 'Đã tìm thấy';

  @override
  String get parStRecovered => 'Đã thu hồi';

  @override
  String get parStDamaged => 'Bị hư hỏng';

  @override
  String get parStLost => 'Thất lạc';

  @override
  String get parStReturnedToHub => 'Đã về kho Lock.R';

  @override
  String get parStRedeliveryPending => 'Chờ giao lại';

  @override
  String get parStRedelivered => 'Đã giao lại';

  @override
  String get parStCompensated => 'Đã bồi thường';

  @override
  String get incEvReported => 'Ghi nhận kiện rơi khỏi drone';

  @override
  String get incEvRecoveryAssigned => 'Phân công người thu hồi kiện';

  @override
  String get incEvRecoveryAccept => 'Nhân viên nhận việc thu hồi';

  @override
  String get incEvRecoverySearching => 'Nhân viên bắt đầu tìm kiện';

  @override
  String get incEvReturnFlightConfirmed => 'Drone đã về trạm';

  @override
  String get incEvRecoverySubmitted => 'Báo kết quả thu hồi';

  @override
  String get incEvRecoveryVerified => 'Xác minh kết quả thu hồi';

  @override
  String get incEvStationDispatched =>
      'Kiện được điều phối về trạm bay để giao lại';

  @override
  String get incEvStationUnavailable => 'Đang điều phối trạm nhận kiện';

  @override
  String get incEvReturnedToHub => 'Kiện đã về kho Lock.R';

  @override
  String get incEvResolutionProposed => 'Lock.R đề xuất phương án';

  @override
  String get incEvCustomerAccept => 'Bạn đồng ý phương án';

  @override
  String get incEvCustomerReview => 'Bạn yêu cầu xem xét lại';

  @override
  String get incEvReturnFlightUpdated => 'Cập nhật chuyến bay về trạm';

  @override
  String get incEvRedeliveryRequested => 'Đã tạo đơn giao lại';

  @override
  String get incEvRedeliveryUnavailable =>
      'Chưa tạo được đơn giao lại — nhân viên sẽ liên hệ';

  @override
  String get incEvRedeliveryCompleted => 'Đã giao lại thành công';

  @override
  String get incEvCompensationSubmitted => 'Đã gửi yêu cầu chi bồi thường';

  @override
  String get incEvCompensationPaid => 'Đã chi bồi thường';

  @override
  String get incEvCompensationFailed => 'Chi bồi thường chưa thành công';

  @override
  String get incEvResolved => 'Đã hoàn tất xử lý sự cố';

  @override
  String get resFreeRedelivery => 'Giao lại miễn phí';

  @override
  String get resRedeliveryPartial => 'Giao lại kèm bồi thường một phần';

  @override
  String get resCompensationOnly => 'Bồi thường';

  @override
  String get resManual => 'Thỏa thuận riêng';

  @override
  String get condIntact => 'còn nguyên vẹn';

  @override
  String get condMinor => 'hư hại nhẹ';

  @override
  String get condMajor => 'hư hại nặng';

  @override
  String get condUnusable => 'không thể sử dụng';

  @override
  String get propAwaiting => 'Chờ bạn phản hồi';

  @override
  String get propAccepted => 'Bạn đã đồng ý';

  @override
  String get propDisputed => 'Đã yêu cầu xem xét lại';

  @override
  String get propSuperseded => 'Đã thay bằng phương án mới';

  @override
  String get incEvRecoveryUpdate => 'Cập nhật thu hồi kiện';

  @override
  String get incEvCompensationUpdate => 'Cập nhật bồi thường';

  @override
  String get incEvRedeliveryUpdate => 'Cập nhật giao lại';

  @override
  String get msNotInit => 'Chưa khởi tạo';

  @override
  String get msAwaitingLoading => 'Chờ nạp hàng';

  @override
  String get msReadyToLaunch => 'Sẵn sàng phóng';

  @override
  String get msLaunching => 'Đang khởi phóng';

  @override
  String get msDeparted => 'Đã rời trạm';

  @override
  String get msEnRoute => 'Đang bay';

  @override
  String get msApproaching => 'Sắp tới tủ nhận';

  @override
  String get msArrived => 'Đã tới tủ nhận';

  @override
  String get msDeposited => 'Đã gửi hàng vào ô';

  @override
  String get msFailed => 'Chuyến bay thất bại';

  @override
  String get msDropReported => 'Dừng do sự cố rơi kiện';

  @override
  String get dosAwaitingDispatch => 'Đang giao bằng drone';

  @override
  String get dosStoring => 'Hàng đang trong tủ nhận';

  @override
  String get dosExpired => 'Quá hạn nhận';

  @override
  String get cancelWeather => 'Thời tiết xấu';

  @override
  String get cancelDroneFault => 'Drone lỗi';

  @override
  String get cancelPadNotReady => 'Bãi đáp không sẵn sàng';

  @override
  String get cancelOperational => 'Lý do vận hành';

  @override
  String get cancelOther => 'Lý do khác';

  @override
  String cancelReasonCode(Object code) {
    return 'Lý do #$code';
  }

  @override
  String get modeDemo => 'Mô phỏng (DEMO)';

  @override
  String get modeStandard => 'Drone thật';

  @override
  String get stgTitleAwaitingTech => 'Chờ kỹ thuật viên nhận lấy hàng';

  @override
  String get stgTitleTechOnWay => 'Kỹ thuật viên đang tới lấy hàng';

  @override
  String get stgTitlePickedUp => 'Đã lấy hàng, đang mang tới drone';

  @override
  String get stgTitleLoading => 'Đang nạp hàng lên drone';

  @override
  String get stgTitleLaunching => 'Drone đang khởi phóng';

  @override
  String get stgTitleDeparted => 'Drone đã rời trạm';

  @override
  String get stgTitleEnRoute => 'Drone đang trên đường';

  @override
  String get stgTitleApproaching => 'Drone sắp đến';

  @override
  String get stgTitleArrived => 'Drone đã đến tủ';

  @override
  String get stgTitleReady => 'Sẵn sàng nhận hàng';

  @override
  String get stgTitleDelayed => 'Đơn hàng bị chậm';

  @override
  String get stgTitleFailed => 'Giao không hoàn tất';

  @override
  String get stgTitleDrop => 'Kiện hàng gặp sự cố rơi';

  @override
  String get stgTitleCancelled => 'Đơn drone đã huỷ';

  @override
  String get stgTitleReceived => 'Đã nhận hàng';

  @override
  String get stgTitleExpired => 'Quá hạn nhận hàng';

  @override
  String get stgTitleUpdate => 'Cập nhật đơn hàng';

  @override
  String get stgDescAwaitingTech =>
      'Sau khi thanh toán, hệ thống tìm kỹ thuật viên drone rảnh gần bạn nhất';

  @override
  String get stgDescTechOnWay =>
      'Kỹ thuật viên đang tới điểm lấy hàng, chuẩn bị kiện và mã lấy hàng';

  @override
  String get stgDescPickedUp =>
      'Kiện đang được mang tới drone để nạp trực tiếp; không bỏ vào ô tủ bay';

  @override
  String get stgDescLoading =>
      'Drone đã được gán, kỹ thuật viên đang cân và nạp kiện';

  @override
  String get stgDescLaunching => 'Đội bay đang thực hiện quy trình khởi phóng';

  @override
  String get stgDescDeparted => 'Drone đã cất cánh khỏi trạm nguồn';

  @override
  String get stgDescEnRoute => 'Drone đang bay tới tủ nhận';

  @override
  String stgDescEnRouteEta(Object eta) {
    return 'Drone dự kiến đến trong $eta';
  }

  @override
  String get stgDescApproaching => 'Drone đang tiếp cận tủ nhận của bạn';

  @override
  String get stgDescArrived => 'Drone đã đến và đang gửi kiện hàng vào tủ';

  @override
  String get stgDescReady =>
      'Kiện hàng đã nằm trong tủ nhận, dùng mã PIN/QR của đơn để mở ô';

  @override
  String get stgDescDelayed => 'Đơn đang bị chậm so với dự kiến';

  @override
  String stgDescDelayedEta(Object eta) {
    return 'Đơn đang bị chậm, dự kiến tới $eta';
  }

  @override
  String get stgDescFailed => 'Đơn giao không hoàn tất';

  @override
  String get stgDescDrop =>
      'Kiện được báo rơi khỏi drone trong chuyến bay. Tiến trình thu hồi và phương án xử lý xem ở thẻ sự cố của đơn.';

  @override
  String get stgDescCancelled => 'Đơn đã dừng trước khi drone cất cánh';

  @override
  String get stgDescReceived => 'Người nhận đã lấy kiện hàng khỏi tủ';

  @override
  String get stgDescExpired => 'Đã quá hạn nhận hàng, vui lòng liên hệ hỗ trợ';

  @override
  String get stgDescUpdate => 'Đơn hàng của bạn có cập nhật mới';

  @override
  String get droneNoWeatherData => 'Chưa có dữ liệu thời tiết.';

  @override
  String get failWeather => 'Tạm dừng bay do thời tiết hoặc lệnh điều hành';

  @override
  String get failWeatherUnsafe => 'Thời tiết tuyến bay không an toàn';

  @override
  String get failStationSuspended => 'Trạm bay đang tạm dừng';

  @override
  String get failDroneFault => 'Drone gặp sự cố';

  @override
  String get failNoDrone => 'Tủ gửi không còn drone sẵn sàng';

  @override
  String get failSourceLocker => 'Tủ gửi gặp sự cố';

  @override
  String get failDestinationLocker => 'Tủ nhận gặp sự cố';

  @override
  String get failLandingPad => 'Bãi đáp drone không sẵn sàng';

  @override
  String get failNoTechnician => 'Không có kỹ thuật viên nhận lấy hàng';

  @override
  String get failLaunchOverdue => 'Quá hạn phóng drone sau khi lấy hàng';

  @override
  String get failCustomerAbsent => 'Không gặp được người gửi tại điểm lấy hàng';

  @override
  String get failParcelRejected => 'Kiện hàng không đúng khai báo';

  @override
  String get failAddressNotFound => 'Không tìm thấy địa chỉ lấy hàng';

  @override
  String get failFlightIncident => 'Sự cố trong lúc bay';

  @override
  String get failShortCustomerAbsent => 'Không gặp được người gửi';

  @override
  String get failShortParcelRejected => 'Kiện không đúng khai báo';

  @override
  String get failShortAddressNotFound => 'Không tìm thấy địa chỉ';

  @override
  String get failShortNoDrone => 'Không còn drone';

  @override
  String get failShortSourceLocker => 'Tủ gửi lỗi';

  @override
  String get failShortDestinationLocker => 'Tủ nhận lỗi';

  @override
  String get failShortFlightIncident => 'Sự cố lúc bay';

  @override
  String get catDocument => 'Tài liệu';

  @override
  String get catFood => 'Đồ ăn';

  @override
  String get catClothing => 'Quần áo';

  @override
  String get catElectronics => 'Điện tử';

  @override
  String get catCosmetics => 'Mỹ phẩm';

  @override
  String get heldSourceBox => 'Còn trong ô gửi';

  @override
  String get heldFlightTeam => 'Đội bay đang giữ';

  @override
  String get blockDisconnected => 'mất kết nối';

  @override
  String get blockMaintenance => 'đang bảo trì';

  @override
  String get blockSuspended => 'tạm ngưng';

  @override
  String get blockNoPad => 'chưa có bãi đáp drone';

  @override
  String get blockPadMaintenance => 'bãi đáp đang bảo trì';

  @override
  String get blockPadFault => 'bãi đáp đang lỗi';

  @override
  String get droneErrOwnerOnly =>
      'Chỉ người đặt đơn mới thực hiện được thao tác này.';

  @override
  String get droneErrNotYourIncident => 'Sự cố này không thuộc đơn của bạn.';

  @override
  String get droneErrNoReview =>
      'Chính sách của đơn không cho yêu cầu xem xét lại phương án.';

  @override
  String get droneErrAlreadyResponded =>
      'Phương án này đã được phản hồi. Vui lòng tải lại.';

  @override
  String get droneErrNoProposal => 'Chưa có phương án nào chờ bạn phản hồi.';

  @override
  String get droneErrInvalidChoice => 'Lựa chọn không hợp lệ.';

  @override
  String get droneErrRecipientLookup =>
      'Chưa tra được thông tin người nhận. Vui lòng thử lại sau.';

  @override
  String get droneNoPermission =>
      'Bạn không có quyền xem đơn drone này. Chỉ người đặt và người nhận theo dõi được đơn.';

  @override
  String get droneStatusLoadFailedRetrying =>
      'Không tải được trạng thái giao hàng. Đang thử lại...';

  @override
  String get dronePickupCodeNotSupported =>
      'Máy chủ chưa hỗ trợ tra mã nhận hàng trong ứng dụng. Hãy dùng mã PIN đã gửi qua thông báo, email hoặc SMS.';

  @override
  String get droneTrackingDisabled =>
      'Tính năng theo dõi giao drone đang tạm tắt.';

  @override
  String get droneStatusLoadFailed => 'Không tải được trạng thái giao hàng.';

  @override
  String get ddTlPayment => 'Thanh toán';

  @override
  String get ddTlParcelDropped => 'Bỏ kiện vào ô gửi';

  @override
  String get ddTlHomePickup => 'Lấy hàng tại nhà người gửi';

  @override
  String get ddTlLoaded => 'Nạp hàng lên drone';

  @override
  String get ddTlReady => 'Sẵn sàng phóng';

  @override
  String get ddTlCodeSent => 'Gửi mã cho người nhận';

  @override
  String get ddTlPickupDeadline => 'Hạn nhận hàng';

  @override
  String get ddTlReceived => 'Người nhận lấy hàng';

  @override
  String get ddProgress => 'Tiến trình giao hàng';

  @override
  String get ddClosedTitle => 'Đơn drone đã đóng';

  @override
  String get ddClosedBody =>
      'Chuyến bay không hoàn tất nên đơn này đã đóng; phương án xử lý xem ở phần sự cố của đơn.';

  @override
  String get ddAwaitingPaymentTitle => 'Chờ thanh toán';

  @override
  String get ddAwaitingPaymentBody =>
      'Thanh toán xong hệ thống mới tìm kỹ thuật viên drone tới lấy hàng';

  @override
  String get ddAwaitingTeamTitle => 'Chờ đội bay tiếp nhận';

  @override
  String get ddAwaitingTeamBody =>
      'Kiện đã sẵn sàng tại trạm Lock.R, chờ kỹ thuật viên drone nạp hàng và phóng';

  @override
  String get ddReadyBody =>
      'Kiện đã được nạp và niêm phong trên drone, chờ đội bay phóng';

  @override
  String ddAboutMinutesLeft(Object minutes) {
    return 'Còn khoảng $minutes phút';
  }

  @override
  String ddSince(Object time) {
    return 'Từ $time';
  }

  @override
  String ddOverdueAt(Object deadline, Object policy) {
    return 'Đơn hàng đã quá hạn lấy lúc $deadline. $policy';
  }

  @override
  String ddPickupDeadline(Object deadline, Object hours) {
    return 'Hạn người nhận lấy hàng: $deadline (lưu trữ $hours giờ).';
  }

  @override
  String get ddFlightIncompleteClosed =>
      'Chuyến bay không hoàn tất nên đơn này đã đóng. Phương án xử lý (giao lại hoặc bồi thường) xem ở phần sự cố của đơn.';

  @override
  String get ddUnpaidSearch =>
      'Đơn chưa thanh toán. Thanh toán xong hệ thống mới bắt đầu tìm kỹ thuật viên drone tới lấy hàng.';

  @override
  String ddAt(Object time) {
    return 'Lúc: $time';
  }

  @override
  String ddReason(Object reason) {
    return 'Lý do: $reason';
  }

  @override
  String ddNoteValue(Object note) {
    return 'Ghi chú: $note';
  }

  @override
  String ddTicket(Object id) {
    return 'Phiếu sự cố: #$id';
  }

  @override
  String get ddParcelWithSender =>
      'Kiện hàng chưa được lấy, vẫn ở chỗ người gửi.';

  @override
  String get ddRefundRecorded =>
      'Yêu cầu hoàn tiền đã được ghi nhận. Admin sẽ chuyển khoản về tài khoản ngân hàng của người đặt.';

  @override
  String get ddRefundDone => 'Tiền đã được chuyển khoản hoàn cho người đặt.';

  @override
  String get ddRefundByIncident =>
      'Khoản đã trả được xử lý theo phương án sự cố: giao lại miễn phí hoặc bồi thường chuyển khoản về tài khoản ngân hàng đã liên kết.';

  @override
  String get ddRefundNotRecorded =>
      'Chưa ghi nhận được yêu cầu hoàn tiền — vui lòng liên hệ hỗ trợ.';

  @override
  String ddWeightOver(Object actual, Object expected) {
    return 'Kiện cân thực tế $actual, nặng hơn mức $expected đã khai báo.';
  }

  @override
  String ddSurchargeOperator(Object amount) {
    return 'Chờ khách trả thêm $amount rồi mới phóng được.';
  }

  @override
  String ddSurchargeReceiver(Object amount) {
    return 'Đang chờ người gửi trả thêm $amount để drone cất cánh.';
  }

  @override
  String ddSurchargeSender(Object amount) {
    return 'Bạn cần trả thêm $amount để drone cất cánh. Không đồng ý thì bạn có thể huỷ đơn: phần đã trả được hoàn và đội bay trả lại kiện.';
  }

  @override
  String get ddUnpaidOperator =>
      'Khách chưa thanh toán. Chỉ tiếp nhận được sau khi đơn đã thanh toán.';

  @override
  String get ddUnpaidReceiver =>
      'Người gửi chưa thanh toán đơn. Đội bay tiếp nhận sau khi người gửi thanh toán.';

  @override
  String get ddUnpaidSender =>
      'Đơn chưa thanh toán. Đội bay chỉ tiếp nhận sau khi bạn thanh toán.';

  @override
  String get ddPaySurcharge => 'Trả thêm phí chênh';

  @override
  String get ddPayNow => 'Thanh toán ngay';

  @override
  String get ddDeclineSurcharge => 'Không đồng ý · huỷ đơn và nhận hoàn tiền';

  @override
  String ddIncidentLabel(Object label) {
    return 'Đơn đang gặp sự cố: $label';
  }

  @override
  String ddFromTime(Object time) {
    return 'Từ lúc: $time';
  }

  @override
  String ddAutoCloseOperator(Object time) {
    return 'Chưa khắc phục trước $time thì đơn tự kết thúc \"giao không hoàn tất\" và hoàn tiền cho khách.';
  }

  @override
  String ddAutoCloseCustomer(Object time) {
    return 'Nếu chưa khắc phục được trước $time, đơn sẽ kết thúc và bạn được hoàn tiền.';
  }

  @override
  String get ddChangePlan => 'Đổi phương án hoặc xác nhận giao không hoàn tất.';

  @override
  String get ddTeamHandling => 'Đội bay đang xử lý.';

  @override
  String ddPickedUp(Object at) {
    return 'Đã lấy hàng$at';
  }

  @override
  String ddPickedUpAt(Object time) {
    return ' lúc $time';
  }

  @override
  String get ddTechnician => 'Kỹ thuật viên';

  @override
  String get ddYouHeadingToPickup => 'Bạn đang tới lấy hàng';

  @override
  String ddTechHeadingToPickup(Object who) {
    return '$who đang tới lấy hàng';
  }

  @override
  String get ddYouAreInvited => 'Bạn được mời lấy hàng';

  @override
  String get ddSearchingTech => 'Đang tìm kỹ thuật viên drone gần bạn nhất';

  @override
  String get ddAwaitingDispatchPickup => 'Chờ điều phối lấy hàng';

  @override
  String get ddTechAfterPayment =>
      'Kỹ thuật viên sẽ tới lấy hàng sau khi đơn được thanh toán';

  @override
  String get ddHomePickup => 'Lấy hàng tận nhà';

  @override
  String get ddPickupCode => 'Mã lấy hàng';

  @override
  String get ddPickupCodeHint =>
      'Đọc mã này cho kỹ thuật viên khi giao kiện. Không gửi mã cho người khác.';

  @override
  String get ddPickupPoint => 'Điểm lấy hàng';

  @override
  String get ddDirections => 'Chỉ dẫn';

  @override
  String get ddTechPhone => 'SĐT kỹ thuật viên';

  @override
  String get ddDistanceAtAccept => 'Cách điểm lấy lúc nhận việc';

  @override
  String get ddPickupToSource => 'Điểm lấy hàng → tủ gửi';

  @override
  String get ddPickupNote => 'Ghi chú lúc lấy hàng';

  @override
  String get ddPickupPhoto => 'Ảnh kiện lúc lấy hàng';

  @override
  String ddPhotoTakenAt(Object time) {
    return 'Chụp lúc $time';
  }

  @override
  String get ddDroneBoxAtSource => 'ô drone ở tủ gửi';

  @override
  String ddDroneBoxNumberAtSource(Object box) {
    return 'ô drone số $box ở tủ gửi';
  }

  @override
  String ddSenderNotDroppedOperator(Object where) {
    return 'Người gửi chưa xác nhận bỏ kiện vào $where. Chỉ tiếp nhận được sau khi kiện đã nằm trong ô.';
  }

  @override
  String ddWaitingSenderDrop(Object where) {
    return 'Đang chờ người gửi bỏ kiện vào $where.';
  }

  @override
  String ddDropThenConfirm(Object where) {
    return 'Bỏ kiện vào $where rồi xác nhận bên dưới. Đội bay chỉ tiếp nhận đơn sau khi bạn xác nhận.';
  }

  @override
  String get ddIDropped => 'Tôi đã bỏ kiện vào ô';

  @override
  String ddParcelReturnedAt(Object time) {
    return 'Kiện đã được trả lại cho người gửi lúc $time.';
  }

  @override
  String get ddParcelInBoxOperator =>
      'Kiện còn trong ô gửi. Lấy kiện ra, trả cho người gửi rồi xác nhận đã trả.';

  @override
  String get ddParcelWithTeamOperator =>
      'Kiện đang do đội bay giữ. Trả cho người gửi rồi xác nhận đã trả.';

  @override
  String get ddParcelInBoxCustomer =>
      'Kiện của bạn còn trong ô gửi. Đội bay sẽ liên hệ để trả lại kiện.';

  @override
  String ddParcelHeldByTech(Object where) {
    return 'Kiện đang do kỹ thuật viên giữ và sẽ được mang trả lại$where.';
  }

  @override
  String get ddToSender => ' cho người gửi';

  @override
  String ddAtAddress(Object address) {
    return ' tại $address';
  }

  @override
  String get ddCancelOrder => 'Huỷ đơn';

  @override
  String get ddCancelAllowed => 'Bạn huỷ được đơn khi đội bay chưa tiếp nhận.';

  @override
  String get ddRoute => 'Lộ trình giao hàng';

  @override
  String get ddSystemPickedStation =>
      'Tủ bay do hệ thống chọn (KTV nạp kiện trực tiếp lên drone)';

  @override
  String ddLegacyBox(Object box) {
    return 'Đơn cũ: kiện từng được gửi vào ô số $box';
  }

  @override
  String ddSentAt(Object time) {
    return 'Gửi đi lúc: $time';
  }

  @override
  String get ddNotSentYet => 'Chưa gửi';

  @override
  String get ddDirectionsToDrone => 'Chỉ đường tới drone tại tủ bay';

  @override
  String get ddReceiverLockerOperator =>
      'Tủ nhận khách đã chọn (người nhận lấy hàng)';

  @override
  String get ddReceiverLockerCustomer =>
      'Tủ nhận bạn đã chọn (người nhận lấy hàng)';

  @override
  String ddReceiveBox(Object box) {
    return 'Ô nhận số $box';
  }

  @override
  String ddDepositedAt(Object time) {
    return 'Hàng vào tủ lúc: $time';
  }

  @override
  String get ddNotArrived => 'Chưa tới';

  @override
  String ddCodeSentAt(Object time) {
    return 'Gửi mã cho người nhận lúc: $time';
  }

  @override
  String ddReceivedAt(Object time) {
    return 'Người nhận lấy hàng lúc: $time';
  }

  @override
  String get ddNotReceived => 'Chưa nhận';

  @override
  String get ddDirectionsToReceiver => 'Chỉ đường tới tủ nhận';

  @override
  String get ddLockerNoAddress =>
      'Tủ này chưa có địa chỉ hoặc toạ độ để chỉ đường.';

  @override
  String get ddCantOpenMaps => 'Không mở được ứng dụng bản đồ trên thiết bị.';

  @override
  String get ddOrderInfo => 'Thông tin đơn hàng';

  @override
  String get ddOrderCode => 'Mã đơn';

  @override
  String get ddOrderStatus => 'Trạng thái đơn';

  @override
  String get ddPausedDrop => 'Tạm dừng do sự cố rơi kiện';

  @override
  String get ddDroneFee => 'Phí giao drone';

  @override
  String get ddWeightSurcharge => 'Trong đó thu thêm do cân lệch';

  @override
  String ddDiscountCodeValue(Object code) {
    return 'Mã giảm giá $code';
  }

  @override
  String ddUsePoints(Object points) {
    return 'Dùng $points điểm';
  }

  @override
  String get ddAmountPaid => 'Số tiền thanh toán';

  @override
  String get ddMethod => 'Phương thức';

  @override
  String get ddPaymentRef => 'Mã thanh toán';

  @override
  String get ddBoxAtLocker => 'Ô nhận tại tủ';

  @override
  String get ddDeclaredWeight => 'Khối lượng khai báo';

  @override
  String get ddParcelSize => 'Kích thước kiện';

  @override
  String get ddCaution => 'Lưu ý';

  @override
  String get ddDroppedAtLabel => 'Bỏ kiện vào ô gửi lúc';

  @override
  String get ddTechReceivedAt => 'KTV nhận kiện lúc';

  @override
  String get ddParcelDescription => 'Mô tả kiện hàng';

  @override
  String get ddNoDescription => 'Không có mô tả';

  @override
  String get ddFlightMode => 'Hình thức bay';

  @override
  String get ddPeople => 'Người liên quan';

  @override
  String get ddDroneTech => 'Kỹ thuật viên drone';

  @override
  String get ddNoTechYet => 'Chưa có người nhận việc';

  @override
  String get ddTechAccepted => 'Đã nhận việc';

  @override
  String get ddLoader => 'Người nạp hàng';

  @override
  String get ddNotLoaded => 'Chưa nạp hàng';

  @override
  String get ddLoaded => 'Đã nạp';

  @override
  String get ddNotChecked => 'Chưa kiểm';

  @override
  String get ddPass => 'Đạt';

  @override
  String get ddFail => 'Không đạt';

  @override
  String get ddMissionRecord => 'Nhiệm vụ bay & hồ sơ nạp hàng';

  @override
  String get ddMissionCode => 'Mã nhiệm vụ';

  @override
  String get ddNotAssigned => 'Chưa phân công';

  @override
  String get ddMissionStatus => 'Trạng thái nhiệm vụ';

  @override
  String get ddDronePosition => 'Vị trí drone hiện tại';

  @override
  String get ddNoData => 'Chưa có dữ liệu';

  @override
  String get ddActualWeight => 'Khối lượng thực tế';

  @override
  String get ddSealCode => 'Mã niêm phong';

  @override
  String get ddNotSealed => 'Chưa niêm phong';

  @override
  String get ddParcelMatched => 'Đúng kiện, đúng đơn';

  @override
  String get ddPayloadSecured => 'Kiện đã cố định';

  @override
  String get ddCompartmentLocked => 'Khoang hàng đã khoá';

  @override
  String get ddLoadingNote => 'Ghi chú nạp hàng';

  @override
  String get ddEvLoaded => 'Đã nạp hàng lên drone';

  @override
  String get ddEvCodeSent => 'Gửi mã nhận hàng cho người nhận';

  @override
  String get ddEvCreated => 'Đơn drone được tạo';

  @override
  String get ddJourneyLog => 'Nhật ký hành trình · mới nhất trước';

  @override
  String get ddNoJourney => 'Chưa có mốc hành trình nào.';

  @override
  String get ddSystem => 'Hệ thống';

  @override
  String get ddLockrStaff => 'Nhân viên Lock.R';

  @override
  String get ddNewest => 'Mới nhất';

  @override
  String dbBoxTaken(Object box) {
    return '$box vừa được người khác giữ. Hãy chọn ô drone khác.';
  }

  @override
  String get dbYourBox => 'Ô bạn chọn';

  @override
  String get dbCheckingBoxes => 'Đang kiểm tra ô drone…';

  @override
  String get dbNoFreeBoxes => 'Không còn ô drone nhận trống';

  @override
  String get dbChooseBox => 'Chọn ô người nhận sẽ lấy hàng';

  @override
  String dbDistancePrefix(Object distance) {
    return 'Cách bạn $distance · ';
  }

  @override
  String get dbNoPad => 'Chưa có bãi đáp drone';

  @override
  String get dbNoCoordinates => 'Chưa có toạ độ tủ';

  @override
  String get dbCheckingBoxesShort => 'Đang kiểm tra ô drone';

  @override
  String get dbOutOfBoxes => 'Hết ô drone trống';

  @override
  String dbFreeBoxes(Object count) {
    return '$count ô drone trống';
  }

  @override
  String dbEnterName(Object who) {
    return 'Nhập tên $who';
  }

  @override
  String dbInvalidPhone(Object who) {
    return 'Số điện thoại $who không hợp lệ';
  }

  @override
  String dbInvalidEmail(Object who) {
    return 'Email $who không hợp lệ';
  }

  @override
  String get dbChoosePickup => 'Chọn điểm lấy hàng';

  @override
  String get dbWhoSender => 'người gửi';

  @override
  String get dbWhoReceiver => 'người nhận';

  @override
  String get dbChooseReceiverLocker => 'Chọn tủ nhận';

  @override
  String get dbCheckingReceiverBoxes =>
      'Đang kiểm tra ô drone trống của tủ nhận, vui lòng chờ một chút';

  @override
  String get dbReceiverFull =>
      'Tủ nhận này đã hết ô drone trống, hãy chọn tủ khác';

  @override
  String get dbChooseReceiverBox => 'Chọn ô drone nhận còn trống tại tủ nhận';

  @override
  String get dbChooseCategory => 'Chọn loại hàng';

  @override
  String get dbSizeAllOrNone =>
      'Nhập đủ dài, rộng, cao của kiện (cm) hoặc bỏ trống cả ba';

  @override
  String dbTooLarge(Object l, Object w, Object h) {
    return 'Kiện không lọt khoang drone (tối đa $l × $w × $h cm)';
  }

  @override
  String dbMaxValue(Object amount) {
    return 'Drone chỉ nhận kiện có giá trị tới $amount';
  }

  @override
  String get dbConfirmNoProhibited =>
      'Bạn cần cam kết kiện không chứa hàng cấm bay';

  @override
  String get dbPaidByVoucher =>
      'Đơn đã được thanh toán bằng ưu đãi. Đội bay sẽ tiếp nhận đơn của bạn.';

  @override
  String dbCreatedNotPaid(Object error) {
    return 'Đã tạo đơn drone nhưng chưa thanh toán được: $error';
  }

  @override
  String get dbTitle => 'Gửi hàng bằng drone';

  @override
  String get dbIntro =>
      'Đặt và thanh toán xong, kỹ thuật viên drone gần bạn nhất sẽ tới lấy kiện, mang tới drone tại tủ bay để nạp trực tiếp lên drone (không bỏ vào ô tủ), rồi drone bay tới ô nhận bạn đã chọn. Người nhận lấy hàng bằng mã mở ô gửi qua email.';

  @override
  String get dbSuspended =>
      'Dịch vụ giao drone đang tạm dừng (thời tiết hoặc sự cố vận hành). Vui lòng thử lại sau.';

  @override
  String get dbPickupAt => 'Lấy hàng tại';

  @override
  String get dbTechInstructions => 'Chỉ dẫn cho kỹ thuật viên (tuỳ chọn)';

  @override
  String get dbTechInstructionsHint => 'Tầng, cổng, giờ có nhà…';

  @override
  String get dbSenderName => 'Họ tên người gửi *';

  @override
  String get dbSenderPhone => 'Số điện thoại người gửi *';

  @override
  String get dbSenderEmail => 'Email người gửi *';

  @override
  String get dbReceiverName => 'Họ tên người nhận *';

  @override
  String get dbReceiverPhone => 'Số điện thoại người nhận *';

  @override
  String get dbReceiverEmail => 'Email người nhận *';

  @override
  String get dbEmailInfo =>
      'Khi drone được phóng, người gửi và người nhận đều nhận email báo đơn. Khi hàng vào tủ, mã mở ô được gửi tới email người nhận.';

  @override
  String get dbReceiverLockerField => 'Tủ nhận *';

  @override
  String get dbLoadingLockers => 'Đang tải tủ nhận...';

  @override
  String get dbNoLockersInSystem => 'Hệ thống chưa có tủ nào';

  @override
  String get dbReceiverBoxField => 'Ô drone nhận *';

  @override
  String dbFreeReceiverBoxes(Object count) {
    return 'Ô nhận drone còn trống: $count';
  }

  @override
  String get dbChecking => 'đang kiểm tra…';

  @override
  String dbLockerCantReceive(Object reason) {
    return 'Tủ này chưa nhận được drone: $reason';
  }

  @override
  String dbWeightField(Object max) {
    return 'Khối lượng * (tối đa $max một đơn)';
  }

  @override
  String dbWeightHint(Object tolerance) {
    return 'Chọn mức bằng hoặc lớn hơn khối lượng thật. Kỹ thuật viên cân lại khi nạp hàng: nặng hơn mức đã chọn quá $tolerance g thì bạn trả thêm phần phí chênh trước khi drone bay; nhẹ hơn không hoàn lại.';
  }

  @override
  String get dbCategoryField => 'Loại hàng *';

  @override
  String get dbDescriptionField => 'Mô tả hàng hoá (tuỳ chọn)';

  @override
  String get dbLength => 'Dài';

  @override
  String get dbWidth => 'Rộng';

  @override
  String dbSizeHint(Object size) {
    return 'Kích thước tuỳ chọn. Khoang drone tối đa $size cm.';
  }

  @override
  String get dbDeclaredValueField => 'Giá trị khai báo (tuỳ chọn)';

  @override
  String dbDeclaredValueHint(Object amount) {
    return 'Căn cứ bồi thường nếu kiện hư hỏng, thất lạc. Tối đa $amount.';
  }

  @override
  String get dbRouteAndFee => 'Lộ trình và phí';

  @override
  String dbAutoCancel(Object minutes) {
    return 'Đơn chưa thanh toán sau $minutes phút sẽ tự huỷ.';
  }

  @override
  String get dbNoProhibitedCheckbox =>
      'Tôi cam kết kiện không chứa hàng cấm bay: pin rời, chất lỏng, chất dễ cháy nổ, hàng cấm theo pháp luật. *';

  @override
  String dbCreateAndPay(Object amount) {
    return 'Tạo đơn và thanh toán $amount';
  }

  @override
  String get dbCreateFree => 'Tạo đơn (ưu đãi đã trừ hết phí)';

  @override
  String dbLockerCodeOnly(Object locker) {
    return 'Mã riêng của tủ chỉ dùng được khi drone cất cánh tại $locker.';
  }

  @override
  String get dbChoosePickupHint =>
      'Chọn điểm lấy hàng * — dùng vị trí hiện tại hoặc tự nhập/ghim trên bản đồ';

  @override
  String dbLatLngTap(Object lat, Object lng) {
    return 'Vĩ độ $lat · kinh độ $lng · chạm để đổi';
  }

  @override
  String get dbQuoteHint =>
      'Chọn điểm lấy hàng và tủ nhận để xem tủ gửi, quãng đường và phí.';

  @override
  String get dbCalculatingRoute => 'Đang tính lộ trình…';

  @override
  String dbSystemStation(Object locker) {
    return 'Tủ bay do hệ thống chọn: $locker';
  }

  @override
  String dbRouteSummary(Object pickup, Object route) {
    return 'Kỹ thuật viên mang kiện $pickup tới drone ở tủ bay để nạp trực tiếp · drone bay $route tới ô nhận tại tủ đích';
  }

  @override
  String dbFeeValue(Object amount) {
    return 'Phí giao drone: $amount';
  }

  @override
  String dbWind(Object speed) {
    return 'gió $speed km/h';
  }

  @override
  String dbGust(Object speed) {
    return 'giật $speed km/h';
  }

  @override
  String dbRain(Object mm) {
    return 'mưa $mm mm';
  }

  @override
  String dbUpdatedAt(Object time) {
    return 'Cập nhật $time';
  }

  @override
  String dbSource(Object source) {
    return 'nguồn $source';
  }

  @override
  String get dbWeatherOk => 'Thời tiết tuyến bay: Đủ điều kiện';

  @override
  String get dbWeatherUnknown => 'Chưa xác nhận được thời tiết';

  @override
  String get dbWeatherSuspended => 'Thời tiết tuyến bay: Tạm ngưng bay';

  @override
  String get dbWeatherRefresh => 'Xem lại thời tiết';

  @override
  String dbWeatherWindow(Object minutes, Object locker) {
    return 'Dự báo $minutes phút tới (thời gian giao dự kiến) từ nơi gửi → $locker → tủ nhận';
  }

  @override
  String dbWeatherOnlyWhenSafe(Object message) {
    return '$message Đơn chỉ đặt được khi trời đủ điều kiện bay.';
  }

  @override
  String get dtTitle => 'Theo dõi giao drone';

  @override
  String get dtCheckConnection => 'Vui lòng kiểm tra kết nối và thử lại.';

  @override
  String get dtConfirmDroppedTitle => 'Xác nhận đã bỏ kiện';

  @override
  String dtConfirmDroppedBody(Object where) {
    return 'Bạn đã bỏ kiện vào $where và đóng cửa ô? Đội bay sẽ tới nạp hàng sau khi bạn xác nhận.';
  }

  @override
  String get dtDropped => 'Đã bỏ kiện';

  @override
  String get dtDroppedDone => 'Đã ghi nhận. Đội bay sẽ tiếp nhận đơn của bạn.';

  @override
  String get dtCancelSurchargeTitle => 'Huỷ đơn vì không đồng ý phụ thu';

  @override
  String dtCancelSurchargeBody(Object code) {
    return 'Đơn $code sẽ bị huỷ. Phần bạn đã trả được ghi yêu cầu hoàn tiền và đội bay sẽ liên hệ để trả lại kiện. Không hoàn tác được.';
  }

  @override
  String get dtCancelledReturn =>
      'Đã huỷ đơn. Đội bay sẽ trả lại kiện cho bạn.';

  @override
  String get dtMapSimulated => 'Theo dõi trên bản đồ (mô phỏng)';

  @override
  String get dtMap => 'Theo dõi trên bản đồ';

  @override
  String get dtInLockerShare =>
      'Kiện đã vào tủ nhận. Vào \"Xem chi tiết đơn\" để chia sẻ mã mở ô cho người nhận.';

  @override
  String get dtInLockerPickup =>
      'Kiện đã vào tủ nhận. Mở mã PIN để lấy hàng tại tủ.';

  @override
  String get dtViewDetail => 'Xem chi tiết đơn';

  @override
  String get dtPickup => 'Nhận hàng';

  @override
  String get dtOffline =>
      'Mất kết nối · đang thử lại, thông tin bên dưới là lần cập nhật gần nhất';

  @override
  String get dtLive =>
      'Đang cập nhật trực tiếp · trạng thái tự làm mới khi có thay đổi';

  @override
  String get dtLoadFailed => 'Không tải được trạng thái giao hàng';

  @override
  String get rmNoCoordinates =>
      'Tủ gửi hoặc tủ nhận chưa có toạ độ nên chưa vẽ được bản đồ hành trình.';

  @override
  String get rmZoomHint =>
      'Chụm/mở hai ngón hoặc bấm +/− để phóng to; bấm ⤢ để xem toàn màn hình.';

  @override
  String rmTotal(Object distance) {
    return 'Quãng đường $distance';
  }

  @override
  String rmRemaining(Object distance) {
    return 'Còn khoảng $distance';
  }

  @override
  String get rmLiveCoords =>
      'Toạ độ cập nhật mỗi khi drone gửi vị trí về. Bấm vào toạ độ để mở Google Maps.';

  @override
  String get rmEstimatedCamera =>
      'Vị trí drone ước theo chặng bay hiện tại. Số đo bay thật (GPS, pin, chế độ bay) xem ở khung camera phía trên.';

  @override
  String rmEstimatedOpenMap(Object mode) {
    return 'Vị trí drone ước theo chặng bay hiện tại. Mở \"Theo dõi trên bản đồ\" để xem vị trí $mode.';
  }

  @override
  String get rmSimulated => 'mô phỏng';

  @override
  String get rmLive => 'trực tiếp';

  @override
  String get rmEstimated => 'Vị trí drone ước theo chặng bay hiện tại.';

  @override
  String get rmZoomIn => 'Phóng to';

  @override
  String get rmZoomOut => 'Thu nhỏ';

  @override
  String get rmFitRoute => 'Xem cả tuyến';

  @override
  String get rmFullscreen => 'Toàn màn hình';

  @override
  String get rmRouteMap => 'Bản đồ hành trình';

  @override
  String rmDroneSentAt(Object time, Object suffix) {
    return 'Drone gửi về lúc $time$suffix';
  }

  @override
  String get rmSimSuffix => ' · mô phỏng';

  @override
  String get rmAtReceiver => 'Tại tủ nhận';

  @override
  String get rmSimByStage => 'Mô phỏng theo chặng bay';

  @override
  String get rmTelemetry => 'Theo telemetry của drone';

  @override
  String get rmEstimatedByStage => 'Ước theo chặng bay';

  @override
  String get rmAtSourceNotLaunched => 'Tại tủ gửi, chưa cất cánh';

  @override
  String get plServiceOff => 'Dịch vụ vị trí đang tắt. Vui lòng bật GPS.';

  @override
  String get plDenied => 'Quyền truy cập vị trí bị từ chối.';

  @override
  String get plDeniedForever =>
      'Quyền vị trí bị từ chối vĩnh viễn. Hãy bật lại trong cài đặt.';

  @override
  String get plNoLocation => 'Không lấy được vị trí hiện tại.';

  @override
  String get plNoLocationHint =>
      'Không lấy được vị trí hiện tại. Hãy ra chỗ thoáng hoặc gõ địa chỉ để tìm.';

  @override
  String get plNoAddressForPoint =>
      'Chưa tra được địa chỉ của điểm này. Hãy tự nhập địa chỉ bên dưới.';

  @override
  String get plMin3Chars => 'Nhập ít nhất 3 ký tự để tìm địa chỉ.';

  @override
  String get plNotFound =>
      'Không tìm thấy địa chỉ này. Thử gõ rõ hơn hoặc chạm lên bản đồ để ghim.';

  @override
  String get plNoPoint => 'Chưa chọn vị trí lấy hàng trên bản đồ.';

  @override
  String get plEnterAddress =>
      'Nhập địa chỉ lấy hàng (số nhà, đường, phường…).';

  @override
  String get plTitle => 'Chọn điểm lấy hàng';

  @override
  String get plSearchHint => 'Gõ địa chỉ (số nhà, đường, phường…)';

  @override
  String get plClear => 'Xoá';

  @override
  String plTapToSeePin(Object lng) {
    return '$lng · chạm để xem ghim';
  }

  @override
  String get plCurrentLocation => 'Vị trí hiện tại';

  @override
  String get plAddressField => 'Địa chỉ lấy hàng';

  @override
  String get plTapMapToPin => 'Chạm lên bản đồ để ghim điểm lấy hàng';

  @override
  String plPinInfo(Object lat, Object lng) {
    return 'Vĩ độ $lat · kinh độ $lng · vị trí ghim dùng để tính vùng phục vụ; kiểm tra ghim có đúng địa chỉ trước khi xác nhận';
  }

  @override
  String get plPickupHere => 'Lấy hàng tại đây';

  @override
  String get psLoadFailed => 'Không tải được mã nhận hàng. Vui lòng thử lại.';

  @override
  String get psReceivingLocker => 'Tủ nhận hàng';

  @override
  String get psNotInQueue =>
      'Không thấy đơn này trong hàng chờ nhận của bạn. Có thể đơn đã được lấy, hoặc mã nhận hàng được gửi cho số điện thoại khác.';

  @override
  String psDelegated(Object name) {
    return 'Bạn đã ủy quyền cho $name lấy hộ đơn này nên mã nhận hàng đã chuyển cho người được ủy quyền.';
  }

  @override
  String get psSomeoneElse => 'người khác';

  @override
  String get psNotReady =>
      'Mã nhận hàng chưa sẵn sàng. Mã sẽ có khi kiện đã vào ô tủ nhận.';

  @override
  String get psPin => 'Mã PIN mở ô';

  @override
  String get psEnterAtKiosk =>
      'Nhập mã này trên màn hình kiosk tại tủ để mở ô.';

  @override
  String get psReceiveBox => 'Ô nhận';

  @override
  String get psPickupBefore => 'Lấy trước';

  @override
  String ocPaidRefund(Object amount) {
    return 'Đơn đã thanh toán: $amount sẽ được hoàn bằng chuyển khoản sau khi admin duyệt. Hãy kiểm tra tài khoản ngân hàng nhận tiền trong Hồ sơ.';
  }

  @override
  String get ocDroneFee => 'phí giao drone';

  @override
  String get ocUnpaidNoFee => 'Đơn chưa thanh toán nên không phát sinh phí.';

  @override
  String get ocTitle => 'Huỷ đơn giao drone?';

  @override
  String ocBody(Object code, Object refund) {
    return 'Đơn $code sẽ bị huỷ và ô nhận đã giữ cho đơn được nhả. $refund';
  }

  @override
  String get ocRefundPending =>
      'Đã huỷ đơn. Yêu cầu hoàn tiền đã được ghi nhận, admin sẽ chuyển khoản cho bạn.';

  @override
  String get ocRefunded =>
      'Đã huỷ đơn. Tiền đã được chuyển khoản hoàn cho bạn.';

  @override
  String get ocPaidNoRefund =>
      'Đã huỷ đơn. Chưa ghi nhận được yêu cầu hoàn tiền, vui lòng liên hệ hỗ trợ.';

  @override
  String get ocCancelled => 'Đã huỷ đơn.';

  @override
  String get ocAlreadyAccepted =>
      'Đội bay đã tiếp nhận nên đơn không còn huỷ được trong ứng dụng.';

  @override
  String get ocOwnerOnly => 'Chỉ người đặt đơn mới huỷ được đơn này.';

  @override
  String get lmTitleSimulated => 'Theo dõi drone · mô phỏng';

  @override
  String lmSignalLost(Object time) {
    return 'Mất tín hiệu · vị trí lúc $time';
  }

  @override
  String get lmConnecting => 'Đang kết nối tới drone...';

  @override
  String get lmNoPosition => 'Chưa nhận được vị trí drone. Đang thử lại...';

  @override
  String get lmOnTheWay => 'Đang trên đường tới tủ nhận';

  @override
  String get lmAlmostThere => 'Sắp tới nơi';

  @override
  String get lmEta => 'Dự kiến đến';

  @override
  String get lmSpeed => 'Tốc độ';

  @override
  String get lmLiveSimulated => 'mô phỏng · cập nhật trực tiếp';

  @override
  String get lmLiveUpdates => 'cập nhật trực tiếp';

  @override
  String get clCantOpenMaps => 'Không mở được Google Maps.';

  @override
  String clCopied(Object coords) {
    return 'Đã copy toạ độ $coords';
  }

  @override
  String clDronePosition(Object note) {
    return 'Vị trí drone · $note';
  }

  @override
  String get clCopyCoords => 'Copy toạ độ';

  @override
  String get clPickupPin => 'Điểm lấy hàng người gửi ghim';

  @override
  String get clTechnician => 'Vị trí kỹ thuật viên lúc đó';

  @override
  String get clSourceLocker => 'Tại trạm/tủ gửi';

  @override
  String get clDroneGps => 'Vị trí drone (GPS)';

  @override
  String get clDroneSim => 'Vị trí drone (mô phỏng)';

  @override
  String get clDestination => 'Tại tủ nhận';

  @override
  String get clAtEvent => 'Vị trí lúc ghi mốc';

  @override
  String get lpIntro =>
      'Chọn tủ nhận hàng (ưu tiên sắp xếp gần bạn nhất). Hệ thống tự chọn tủ bay và KTV đến lấy kiện tại nhà.';

  @override
  String lpLoadFailed(Object error) {
    return 'Không tải được danh sách tủ: $error';
  }

  @override
  String get lpNoLockers => 'Chưa có tủ nào trên hệ thống.';

  @override
  String lpDistance(Object distance) {
    return 'Cách bạn $distance';
  }

  @override
  String get lpChecking => 'Đang kiểm tra ô drone nhận';

  @override
  String lpFreeSlots(Object count) {
    return 'Còn $count ô drone nhận trống';
  }

  @override
  String lpUnavailable(Object reason) {
    return 'Tạm không gửi drone: $reason';
  }

  @override
  String get asTitle => 'Drone sắp đến nơi';

  @override
  String get asPrepare => 'Vui lòng chuẩn bị ra nhận hàng.';

  @override
  String asDroneCode(Object code) {
    return '\nMã drone: $code';
  }

  @override
  String asEta(Object eta) {
    return 'Dự kiến: $eta';
  }

  @override
  String get opPaid => 'Đã thanh toán. Đội bay sẽ tiếp nhận đơn của bạn.';

  @override
  String get opPending =>
      'Đang chờ xác nhận thanh toán, trạng thái sẽ tự cập nhật.';

  @override
  String get opFailed =>
      'Thanh toán chưa thành công. Đơn vẫn được giữ, bạn có thể thanh toán lại.';

  @override
  String get opUnpaid =>
      'Đơn drone chưa thanh toán. Thanh toán để đội bay tiếp nhận.';

  @override
  String tlMovedAfter(Object duration) {
    return 'Chuyển sau $duration';
  }

  @override
  String tlInStageFor(Object duration) {
    return 'Đã ở chặng này $duration';
  }

  @override
  String get tlNotYet => 'Chưa diễn ra';

  @override
  String get rbChooseBank => 'Vui lòng chọn ngân hàng';

  @override
  String get rbSaved => 'Đã lưu thông tin tài khoản nhận hoàn tiền thành công';

  @override
  String get rbSaveFailed => 'Không thể lưu thông tin. Vui lòng kiểm tra lại';

  @override
  String get rbOneTimeSetup => 'Cài đặt 1 lần duy nhất';

  @override
  String get rbIntro =>
      'Hệ thống sẽ chuyển khoản hoàn tiền trực tiếp vào tài khoản này khi đơn hàng gặp sự cố (tủ kẹt, drone hủy, đơn giặt lỗi...). Bạn không cần phải nhập lại nhiều lần.';

  @override
  String get rbBeneficiaryBank => 'Ngân hàng thụ hưởng';

  @override
  String get rbChooseBankShort => 'Chọn ngân hàng';

  @override
  String get rbAccountNumber => 'Số tài khoản ngân hàng';

  @override
  String get rbAccountNumberHint => 'Nhập số tài khoản của bạn';

  @override
  String get rbEnterAccountNumber => 'Vui lòng nhập số tài khoản';

  @override
  String get rbInvalidAccountNumber => 'Số tài khoản không hợp lệ';

  @override
  String get rbHolderName => 'Họ và tên chủ tài khoản';

  @override
  String get rbHolderHint => 'Ví dụ: NGUYEN VAN A';

  @override
  String get rbEnterHolder => 'Vui lòng nhập tên chủ tài khoản';

  @override
  String get rbUpdate => 'Cập nhật tài khoản';

  @override
  String get rbSave => 'Lưu tài khoản hoàn tiền';

  @override
  String get rbSearchHint => 'Tìm theo tên hoặc mã ngân hàng...';

  @override
  String rfCantPickImage(Object error) {
    return 'Không thể chọn ảnh: $error';
  }

  @override
  String get rfChooseOrder => 'Vui lòng chọn đơn hàng cần hoàn tiền';

  @override
  String get rfInvalidOrder => 'Mã đơn hàng không hợp lệ';

  @override
  String get rfEnterReason => 'Vui lòng nhập lý do yêu cầu hoàn tiền';

  @override
  String get rfEnterBank =>
      'Vui lòng điền đầy đủ thông tin tài khoản ngân hàng nhận tiền';

  @override
  String get rfSending => 'Đang gửi yêu cầu hoàn tiền...';

  @override
  String get rfSent => 'Đã gửi yêu cầu hoàn tiền thành công!';

  @override
  String rfError(Object message) {
    return 'Lỗi: $message';
  }

  @override
  String get rfSubtitle => 'Quản lý và tạo yêu cầu hoàn tiền cho đơn hàng';

  @override
  String get rfMyRequests => 'Yêu cầu của tôi';

  @override
  String get rfNewRequest => 'Tạo yêu cầu mới';

  @override
  String get rfEmptyRecent =>
      'Không có yêu cầu hoàn tiền nào trong 7 ngày gần đây.';

  @override
  String get rfEmptyPending => 'Không có yêu cầu hoàn tiền nào đang chờ xử lý.';

  @override
  String get rfEmptyCompleted =>
      'Chưa có yêu cầu hoàn tiền nào đã được chuyển khoản thành công.';

  @override
  String get rfEmptyRejected => 'Không có yêu cầu hoàn tiền nào bị từ chối.';

  @override
  String get rfEmptyCanceled => 'Không có yêu cầu hoàn tiền nào đã hủy.';

  @override
  String get rfEmptyHint =>
      'Bạn có thể tạo yêu cầu hoàn tiền mới từ tab bên cạnh.';

  @override
  String get rfNone => 'Chưa có yêu cầu hoàn tiền nào';

  @override
  String get rfNoneHint =>
      'Khi gặp sự cố tủ không mở, drone huỷ chuyến hoặc sự cố giặt ủi, bạn có thể tạo yêu cầu hoàn tiền tại đây.';

  @override
  String get rfCreateNow => 'Tạo yêu cầu hoàn tiền ngay';

  @override
  String get rfNoneShort => 'Chưa có yêu cầu hoàn tiền';

  @override
  String get rfNoMatch => 'Không có yêu cầu phù hợp';

  @override
  String rfTicketHash(Object id) {
    return 'Phiếu hoàn tiền #$id';
  }

  @override
  String get rfSentAt => 'Thời gian gửi';

  @override
  String get rfHasTransferSlip => 'Có UNC';

  @override
  String get rfHasPhoto => 'Có ảnh';

  @override
  String get rfViewDetail => 'Xem chi tiết';

  @override
  String get rfDetailSubtitle => 'Chi tiết yêu cầu & thông tin chuyển khoản';

  @override
  String get rfTransferDone => 'Đã hoàn tất chuyển khoản thành công';

  @override
  String get rfRejectedTitle => 'Yêu cầu hoàn tiền đã bị từ chối';

  @override
  String get rfAwaitingAdmin => 'Đang chờ Admin đối soát và chuyển khoản';

  @override
  String get rfInfo => 'Thông tin hoàn tiền';

  @override
  String get rfOrderCodeCopied => 'Đã sao chép mã đơn hàng';

  @override
  String get rfAccountHolder => 'Chủ tài khoản';

  @override
  String get rfReason => 'Lý do hoàn';

  @override
  String get rfTransferId => 'Mã GD chuyển tiền';

  @override
  String get rfTransferIdCopied => 'Đã sao chép mã giao dịch';

  @override
  String get rfRejectReason => 'Lý do từ chối';

  @override
  String get rfEvidence => 'Chứng từ & Hình ảnh minh chứng';

  @override
  String get rfYourPhotos => 'Ảnh minh chứng bạn đã gửi:';

  @override
  String get rfAdminSlip => 'Biên lai chuyển khoản từ Admin (UNC):';

  @override
  String get rfChooseOrderTitle => 'Chọn đơn hàng cần hoàn tiền';

  @override
  String get rfTapToChooseOrder => 'Bấm vào đây để chọn đơn hàng';

  @override
  String get rfChoosePaidOrder =>
      'Chọn đơn đã thanh toán bạn cần yêu cầu hoàn tiền';

  @override
  String rfOrderValue(Object code) {
    return 'Đơn: $code';
  }

  @override
  String get rfAmountLabel => 'Số tiền: ';

  @override
  String get rfChange => 'Đổi';

  @override
  String get rfChoose => 'Chọn';

  @override
  String get rfSavedDefault => 'Đã lưu mặc định';

  @override
  String get rfChooseReceivingBank => 'Chọn ngân hàng nhận tiền';

  @override
  String get rfAccountNumberField => 'Số tài khoản nhận tiền';

  @override
  String get rfAccountNumberHint => 'Nhập số tài khoản';

  @override
  String get rfHolderField => 'Tên chủ tài khoản (viết hoa không dấu)';

  @override
  String get rfSaveAsDefault => 'Lưu làm tài khoản nhận hoàn tiền mặc định';

  @override
  String get rfReasonTitle => 'Lý do yêu cầu hoàn tiền';

  @override
  String get rfQuickStuck => 'Sự cố kẹt ô tủ';

  @override
  String get rfQuickDroneCancel => 'Drone huỷ chuyến bay';

  @override
  String get rfQuickDoubleCharge => 'Trừ tiền trùng cổng thanh toán';

  @override
  String get rfQuickLaundry => 'Sự cố dịch vụ giặt ủi';

  @override
  String get rfReasonHint => 'Mô tả chi tiết lý do và sự cố bạn gặp phải...';

  @override
  String get rfEvidenceOptional => 'Hình ảnh minh chứng (tuỳ chọn)';

  @override
  String get rfTakePhoto => 'Chụp ảnh';

  @override
  String get rfPickGallery => 'Chọn thư viện';

  @override
  String get rfChangePhoto => 'Đổi ảnh khác';

  @override
  String get rfExpectedAmount => 'Số tiền hoàn dự kiến:';

  @override
  String get rfSubmit => 'Gửi yêu cầu hoàn tiền';

  @override
  String get rfEvidenceDetail => 'Chi tiết hình ảnh minh chứng';

  @override
  String get rfRules => 'Quy tắc hoàn tiền';

  @override
  String get rfRulesIntro => 'Lock.R hỗ trợ hoàn tiền cho các trường hợp:';

  @override
  String get rfRule1 =>
      '• Sự cố kỹ thuật ô tủ không mở được hoặc kẹt cửa > 30 phút.';

  @override
  String get rfRule2 =>
      '• Sự cố drone giao trễ vượt thời gian cam kết hoặc huỷ chuyến bay.';

  @override
  String get rfRule3 =>
      '• Lỗi cổng thanh toán trừ tiền 2 lần (double billing).';

  @override
  String get rfRule4 => '• Hàng hoá/đồ giặt có sự cố từ đối tác giặt ủi.';

  @override
  String get rfProcessingTime => 'Thời gian xử lý:';

  @override
  String get rfProcessingBody =>
      'Quản trị viên sẽ đối soát và thực hiện chuyển khoản trong vòng 24 giờ làm việc. Bạn sẽ nhận được thông báo kèm biên lai chuyển khoản (UNC) ngay trên ứng dụng.';

  @override
  String get rfNoOrders => 'Không có đơn hàng nào';

  @override
  String get rfSelected => '✓ Đang chọn';

  @override
  String get rfChooseBeneficiary => 'Chọn ngân hàng thụ hưởng';

  @override
  String get rfSearchBank => 'Tìm kiếm ngân hàng (mã, tên)...';

  @override
  String get bankUnknown =>
      'Không xác định được ngân hàng nhận tiền. Vui lòng quét mã QR bằng app ngân hàng.';

  @override
  String bankCantOpen(Object app) {
    return 'Không mở được $app. Có thể máy chưa cài app — hãy quét mã QR bằng app ngân hàng của bạn.';
  }

  @override
  String get bankTitle => 'Thanh toán bằng app ngân hàng';

  @override
  String get bankIntro =>
      'Chọn app ngân hàng của bạn — số tài khoản, số tiền và nội dung chuyển khoản được điền sẵn, bạn chỉ cần xác nhận.';

  @override
  String get bankSearch => 'Tìm ngân hàng';

  @override
  String get bankLoadFailed =>
      'Không tải được danh sách app ngân hàng.\nBạn có thể quét mã QR bằng app ngân hàng.';

  @override
  String get bankNoMatch => 'Không tìm thấy ngân hàng phù hợp';

  @override
  String get simBusy => 'Đang giả lập…';

  @override
  String get simButton => 'Giả lập thanh toán (test)';

  @override
  String get simFailed => 'Không giả lập được';

  @override
  String get simTitle => 'Giả lập đã chuyển khoản';

  @override
  String get simBody =>
      'Chỉ dùng để test — không có tiền thật. Nhập ít hơn số cần trả để thử trường hợp chuyển thiếu.';

  @override
  String get simReceived => 'Số tiền đã nhận';

  @override
  String get simAction => 'Giả lập';

  @override
  String get txSepay => 'Cổng SePay QR';

  @override
  String get txVnpay => 'Cổng VNPay';

  @override
  String get txMomo => 'Ví MoMo';

  @override
  String get txWithdraw => 'Rút tiền';

  @override
  String get txTitleTopup => 'Nạp tiền vào ví';

  @override
  String get txTitleWithdrawRefund => 'Hoàn tiền rút';

  @override
  String get txTitleWithdraw => 'Rút tiền về tài khoản ngân hàng';

  @override
  String get txTitleRefund => 'Hoàn tiền vào ví';

  @override
  String get txTitleAdjustPlus => 'Điều chỉnh số dư (cộng)';

  @override
  String get txTitleAdjustMinus => 'Điều chỉnh số dư (trừ)';

  @override
  String get txTitleOrderWallet => 'Thanh toán đơn bằng ví';

  @override
  String txTitleOrderVia(Object method) {
    return 'Thanh toán đơn qua $method';
  }

  @override
  String get txTitleIn => 'Tiền vào ví';

  @override
  String get txTitleOut => 'Tiền ra khỏi ví';

  @override
  String get txSvcLaundry => 'Giặt sấy';

  @override
  String get txSvcOrder => 'Thanh toán đơn';

  @override
  String get txSvcTopup => 'Nạp tiền ví';

  @override
  String get txSvcAdjust => 'Điều chỉnh số dư';

  @override
  String get txLoadFailed => 'Không tải được lịch sử giao dịch.';

  @override
  String get txHistory => 'Lịch sử giao dịch';

  @override
  String get txSubtitle => 'Các khoản thanh toán & chi tiêu của bạn';

  @override
  String get txStats => 'Thống kê chi tiêu';

  @override
  String get txThisMonth => 'Tháng này';

  @override
  String get txThisYear => 'Năm nay';

  @override
  String get txTotalSpent => 'Tổng chi tiêu';

  @override
  String get txTotalIn => 'Tổng tiền vào';

  @override
  String get txNet => 'Biến động ròng:';

  @override
  String get txByMethod => 'Tổng tiền theo hình thức';

  @override
  String get txByService => 'Chi tiết theo từng dịch vụ';

  @override
  String get txMethod => 'Hình thức';

  @override
  String get txSvcSmartRental => 'Thuê tủ thông minh';

  @override
  String get txSvcSend => 'Gửi đồ / Giao nhận';

  @override
  String get txSvcLaundryLocker => 'Giặt sấy tủ';

  @override
  String get txSvcWithdrawBank => 'Rút tiền về STK';

  @override
  String get txSvcOtherOrder => 'Thanh toán đơn khác';

  @override
  String txCount(int count) {
    return '$count giao dịch';
  }

  @override
  String get txAllMethods => 'Tất cả hình thức';

  @override
  String get txSepayShort => 'Cổng SePay';

  @override
  String get txFilterByMethod => 'Lọc theo hình thức giao dịch';

  @override
  String txAllCount(Object count) {
    return 'Tất cả ($count GD):';
  }

  @override
  String txFilterCount(Object label, Object count) {
    return '$label ($count GD):';
  }

  @override
  String get txLoading => 'Đang tải lịch sử giao dịch...';

  @override
  String get txNone => 'Không có giao dịch nào';

  @override
  String get txNoMatch => 'Không tìm thấy giao dịch theo bộ lọc đã chọn';

  @override
  String get txWithdrawRequest => 'Yêu cầu rút tiền';

  @override
  String get txMethodLabel => 'Hình thức GD';

  @override
  String get txType => 'Loại';

  @override
  String get txDirection => 'Chiều tiền';

  @override
  String get txCredit => 'Cộng vào ví';

  @override
  String get txDebit => 'Trừ từ ví';

  @override
  String get txDirect => 'Trả trực tiếp qua cổng';

  @override
  String get txId => 'Mã GD';

  @override
  String get txBalanceAfter => 'Số dư ví sau GD';

  @override
  String get commonUser => 'Người dùng';

  @override
  String get commonDelete => 'Xoá';

  @override
  String get commonUpdateNow => 'Cập nhật ngay';

  @override
  String get reminderFieldEmail => 'email';

  @override
  String get reminderFieldPhone => 'số điện thoại';

  @override
  String reminderMissing(Object fields) {
    return 'Tài khoản của bạn chưa có $fields.';
  }

  @override
  String get reminderTitle => 'Bổ sung thông tin tài khoản';

  @override
  String reminderBody(Object missing) {
    return '$missing Thêm vào để nhận mã mở tủ, thông báo đơn hàng và khôi phục tài khoản khi cần.';
  }

  @override
  String reminderLater(Object days) {
    return 'Để sau (nhắc lại sau $days ngày)';
  }

  @override
  String loyEarn(Object order) {
    return 'Tích điểm đơn hàng$order';
  }

  @override
  String loyRedeem(Object order) {
    return 'Dùng điểm thanh toán đơn$order';
  }

  @override
  String loyRedeemRefund(Object order) {
    return 'Hoàn điểm đơn huỷ$order';
  }

  @override
  String loyEarnReversal(Object order) {
    return 'Thu hồi điểm đơn được hoàn tiền$order';
  }

  @override
  String get loyVoucherExchange => 'Đổi điểm lấy voucher';

  @override
  String get loyVoucherRefund => 'Hoàn điểm đổi voucher';

  @override
  String get loyExchange => 'Đổi điểm';

  @override
  String get loyAdjustment => 'Điều chỉnh điểm';

  @override
  String get loyChange => 'Biến động điểm';

  @override
  String get pwEnterCurrent => 'Vui lòng nhập mật khẩu hiện tại';

  @override
  String get pwEnterNew => 'Vui lòng nhập mật khẩu mới';

  @override
  String pwMinLength(Object min) {
    return 'Mật khẩu mới phải có ít nhất $min ký tự';
  }

  @override
  String get pwSameAsCurrent =>
      'Mật khẩu mới không được trùng mật khẩu hiện tại';

  @override
  String get pwConfirmMismatch => 'Mật khẩu xác nhận chưa khớp';

  @override
  String get pwCurrentWrong => 'Mật khẩu hiện tại không đúng';

  @override
  String get pwChangeFailed => 'Đổi mật khẩu thất bại. Vui lòng thử lại.';

  @override
  String nameMin(Object min) {
    return 'Họ và tên phải có ít nhất $min ký tự';
  }

  @override
  String nameMax(Object max) {
    return 'Họ và tên không được quá $max ký tự';
  }

  @override
  String get nameLettersOnly => 'Họ và tên chỉ gồm chữ cái và khoảng trắng';

  @override
  String get nameRealName => 'Vui lòng nhập tên thật của bạn';

  @override
  String get profErrPhoneUsed =>
      'Số điện thoại này đã được dùng cho tài khoản khác';

  @override
  String get profErrEmailUsed => 'Email này đã được dùng cho tài khoản khác';

  @override
  String get profErrLoginUpdate =>
      'Không cập nhật được tài khoản đăng nhập, vui lòng thử lại';

  @override
  String get profErrUpdateFailed =>
      'Cập nhật hồ sơ thất bại. Vui lòng thử lại.';

  @override
  String avTooLarge(Object size) {
    return 'Ảnh không được vượt quá 5MB (kích thước hiện tại: ${size}MB)';
  }

  @override
  String avTooSmall(Object min, Object width, Object height) {
    return 'Ảnh phải có kích thước tối thiểu ${min}x${min}px (kích thước hiện tại: ${width}x${height}px)';
  }

  @override
  String avTooBig(Object max, Object width, Object height) {
    return 'Ảnh không được vượt quá ${max}x${max}px (kích thước hiện tại: ${width}x${height}px)';
  }

  @override
  String get avUnknownFormat => 'Không thể xác định định dạng file';

  @override
  String get avFormats => 'Chỉ hỗ trợ định dạng JPG, PNG, WebP';

  @override
  String get avNotFound => 'File không tồn tại';

  @override
  String avCantCheck(Object error) {
    return 'Không thể kiểm tra file: $error';
  }

  @override
  String get pwStrengthEnter => 'Nhập mật khẩu';

  @override
  String get pwStrengthWeak => 'Mật khẩu yếu';

  @override
  String get pwStrengthMedium => 'Mật khẩu trung bình';

  @override
  String get pwStrengthStrong => 'Mật khẩu mạnh';

  @override
  String get pwStrengthVeryStrong => 'Mật khẩu rất mạnh';

  @override
  String get pwMin8 => 'Mật khẩu phải có ít nhất 8 ký tự';

  @override
  String get pwNeedUpper => 'Mật khẩu phải có ít nhất 1 chữ cái viết hoa';

  @override
  String get pwNeedLower => 'Mật khẩu phải có ít nhất 1 chữ cái viết thường';

  @override
  String get pwNeedNumber => 'Mật khẩu phải có ít nhất 1 số';

  @override
  String get pwNeedSpecial => 'Mật khẩu phải có ít nhất 1 ký tự đặc biệt';

  @override
  String get pwConfirmNew => 'Vui lòng xác nhận mật khẩu mới';

  @override
  String get pwConfirmNotMatch => 'Mật khẩu xác nhận không khớp';

  @override
  String get pwReq8 => 'Ít nhất 8 ký tự';

  @override
  String get pwReqUpper => 'Ít nhất 1 chữ viết hoa';

  @override
  String get pwReqLower => 'Ít nhất 1 chữ viết thường';

  @override
  String get pwReqNumber => 'Ít nhất 1 số';

  @override
  String get pwReqSpecial => 'Ít nhất 1 ký tự đặc biệt';

  @override
  String get loyInvalidData => 'Dữ liệu điểm thưởng không hợp lệ';

  @override
  String get pwChangeNotSupported =>
      'Máy chủ chưa hỗ trợ đổi mật khẩu từ ứng dụng. Vui lòng thử lại sau.';

  @override
  String get avWaitSync => 'Vui lòng đợi quá trình đồng bộ hoàn tất';

  @override
  String get avChooseAvatar => 'Chọn ảnh đại diện';

  @override
  String get avEditAvatar => 'Chỉnh sửa ảnh đại diện';

  @override
  String get avCamera => 'camera';

  @override
  String get avGallery => 'thư viện ảnh';

  @override
  String avCantAccess(Object source) {
    return 'Không thể truy cập $source. Vui lòng cấp quyền trong cài đặt.';
  }

  @override
  String get avSelected =>
      'Ảnh đã được chọn. Nhấn \"Lưu ảnh đại diện\" để cập nhật.';

  @override
  String get avNothingToUpload => 'Không có ảnh nào để tải lên';

  @override
  String get avNoAccount =>
      'Không xác định được tài khoản để cập nhật ảnh đại diện';

  @override
  String get avInvalid => 'Ảnh không hợp lệ';

  @override
  String get avUpdated => 'Cập nhật ảnh đại diện thành công!';

  @override
  String get avCancelled => 'Đã hủy thay đổi ảnh đại diện';

  @override
  String get avChooseSource => 'Chọn nguồn ảnh';

  @override
  String get avLibrary => 'Thư viện';

  @override
  String get avUploading => 'Đang tải lên';

  @override
  String avProgress(Object percent) {
    return 'Hoàn thành $percent';
  }

  @override
  String get avPleaseWait => 'Vui lòng đợi trong giây lát';

  @override
  String get epUpdated => 'Cập nhật thành công!';

  @override
  String get epSaveFailed => 'Không lưu được hồ sơ';

  @override
  String get epTakePhoto => 'Chụp ảnh';

  @override
  String get epFromGallery => 'Chọn từ thư viện';

  @override
  String get epRemoveAvatar => 'Xoá ảnh đại diện';

  @override
  String get epNoAccountPhoto =>
      'Không xác định được tài khoản để cập nhật ảnh';

  @override
  String get epUpdatingAvatar => 'Đang cập nhật ảnh đại diện...';

  @override
  String get epAvatarUpdated => 'Cập nhật ảnh đại diện thành công';

  @override
  String get epRemoveQuestion => 'Xoá ảnh đại diện?';

  @override
  String get epRemoveBody => 'Ảnh đại diện hiện tại sẽ bị gỡ khỏi tài khoản.';

  @override
  String get epRemoving => 'Đang xoá ảnh đại diện...';

  @override
  String get epRemoved => 'Đã xoá ảnh đại diện';

  @override
  String get epTitle => 'Chỉnh sửa hồ sơ';

  @override
  String get epSubtitle => 'Cập nhật thông tin tài khoản';

  @override
  String get epNameHint => 'Nhập họ và tên';

  @override
  String get epPhoneHint => 'Nhập số điện thoại';

  @override
  String get epInvalidPhone => 'Số điện thoại không hợp lệ';

  @override
  String get epEmailHint => 'Nhập email';

  @override
  String get epLoginInfoNote =>
      'Đổi số điện thoại hoặc email cũng đổi thông tin dùng để đăng nhập.';

  @override
  String get frSuccess => 'Đăng ký khuôn mặt thành công';

  @override
  String get frFailed => 'Đăng ký thất bại';

  @override
  String get frNoCamera => 'Không tìm thấy camera trên thiết bị.';

  @override
  String get frCantOpenCamera =>
      'Không thể mở camera. Vui lòng kiểm tra quyền truy cập.';

  @override
  String get frNoUser => 'Không tìm thấy thông tin người dùng';

  @override
  String frCaptureError(Object error) {
    return 'Lỗi trong quá trình chụp ảnh và đăng ký: $error';
  }

  @override
  String get frSample => 'Lấy mẫu khuôn mặt';

  @override
  String get frHoldPhone =>
      'Giữ điện thoại thẳng trước mặt và nhấn nút bên dưới để bắt đầu đăng ký.';

  @override
  String frCapturing(Object count, Object total) {
    return 'Đang chụp ảnh: $count/$total';
  }

  @override
  String get frProcessing => 'Đang xử lý đăng ký...';

  @override
  String get frStartScan => 'Bắt đầu quét';

  @override
  String get fvSuccess => 'Xác thực FaceID thành công';

  @override
  String fvMatched(Object id) {
    return 'Nhận diện thành công ID: $id';
  }

  @override
  String get fvFailedRetry => 'Không thể xác thực FaceID. Vui lòng thử lại.';

  @override
  String get fvCameraError => 'Không thể mở camera hoặc chụp ảnh xác thực.';

  @override
  String get fvFailed => 'Xác thực thất bại';

  @override
  String get fvUsePassword => 'Dùng mật khẩu';

  @override
  String get fvVerifying => 'Đang xác thực...';

  @override
  String get fvLookStraight =>
      'Vui lòng nhìn thẳng vào camera và giữ yên điện thoại để hệ thống nhận diện khuôn mặt của bạn.';

  @override
  String get fvNotSupported =>
      'Đăng nhập bằng khuôn mặt hiện chưa được hỗ trợ.';

  @override
  String get locChecking => 'Đang kiểm tra...';

  @override
  String get locServiceOff => 'Định vị trên máy đang tắt';

  @override
  String get locGranted => 'Đã cấp quyền vị trí';

  @override
  String get locNotGranted => 'Chưa cấp quyền vị trí';

  @override
  String get locDenied => 'Đã từ chối quyền vị trí';

  @override
  String get locCantOpenSettings =>
      'Không mở được cài đặt. Vào Cài đặt của máy → Ứng dụng → Lock.R → Quyền để bật Vị trí.';

  @override
  String get locCantOpenLocationSettings =>
      'Không mở được cài đặt định vị của máy.';

  @override
  String get locSubtitle => 'Quyền truy cập vị trí của ứng dụng';

  @override
  String get locAlways => 'Ứng dụng được dùng vị trí mọi lúc.';

  @override
  String get locWhileInUse => 'Ứng dụng được dùng vị trí khi đang mở.';

  @override
  String get locTurnOnGps =>
      'Bật Định vị (GPS) trong cài đặt của máy để ứng dụng lấy được vị trí.';

  @override
  String get locGrantToFind =>
      'Cấp quyền để tìm tủ gần bạn và chỉ đường tới tủ.';

  @override
  String get locBlocked =>
      'Bạn đã chặn quyền vị trí. Mở cài đặt ứng dụng để bật lại.';

  @override
  String get locRecheck => 'Kiểm tra lại';

  @override
  String get locGrant => 'Cấp quyền vị trí';

  @override
  String get locOpenAppSettings => 'Mở cài đặt ứng dụng';

  @override
  String get locTurnOn => 'Bật định vị';

  @override
  String get locChangeInSettings => 'Thay đổi trong cài đặt hệ thống';

  @override
  String get locUsesFor => 'Lock.R dùng vị trí để';

  @override
  String get locUseFind => 'Tìm cửa hàng / tủ gần bạn';

  @override
  String get locUseDirections => 'Chỉ đường tới tủ';

  @override
  String get locUsePhotos => 'Gắn toạ độ vào ảnh khi báo sự cố';

  @override
  String get loyHistoryNotSupported => 'Máy chủ chưa hỗ trợ xem lịch sử điểm.';

  @override
  String get loyNotSupported =>
      'Máy chủ chưa hỗ trợ điểm thưởng. Vui lòng thử lại sau.';

  @override
  String get loySubtitle => 'Tích điểm khi đơn hàng hoàn tất';

  @override
  String get loyLoading => 'Đang tải điểm thưởng...';

  @override
  String get loyHistory => 'Lịch sử điểm';

  @override
  String get loyEmpty =>
      'Chưa có biến động điểm. Điểm được cộng tự động khi đơn hàng của bạn hoàn tất.';

  @override
  String get loyCurrent => 'Điểm hiện có';

  @override
  String loyTier(Object tier) {
    return 'Hạng $tier';
  }

  @override
  String get loyTopTier => 'Bạn đang ở hạng cao nhất.';

  @override
  String loyToNext(Object points, Object tier) {
    return 'Còn $points điểm để lên hạng $tier.';
  }

  @override
  String loyLifetime(Object points) {
    return 'Tổng điểm đã tích: $points điểm (dùng để xếp hạng, tiêu điểm không tụt hạng)';
  }

  @override
  String get polLoadFailed => 'Không thể tải nội dung';

  @override
  String get polAgree => 'Tôi đồng ý với điều khoản sử dụng';

  @override
  String get pdTitle => 'Thông tin cá nhân';

  @override
  String get pdSubtitle => 'Chi tiết tài khoản của bạn';

  @override
  String get pdNoData => 'Không có dữ liệu';

  @override
  String get pdStatusActive => 'Trạng thái tài khoản: Đang hoạt động';

  @override
  String get pdStatusInactive => 'Trạng thái tài khoản: Chưa kích hoạt';

  @override
  String get pdStatusLocked => 'Trạng thái tài khoản: Đang bị khóa';

  @override
  String get pdDisabled =>
      'Tài khoản của bạn hiện đang bị vô hiệu hóa kỹ thuật. Vui lòng liên hệ hỗ trợ.';

  @override
  String get pdYourEmail => 'Email của bạn';

  @override
  String get pdNotUpdated => 'Chưa cập nhật';

  @override
  String get pdPasswordNotSet => 'Mật khẩu (chưa đặt — chạm để đặt)';

  @override
  String get pdNotSet => 'Chưa đặt';

  @override
  String get secNoBiometric =>
      'Thiết bị chưa đăng ký vân tay/khuôn mặt trong cài đặt hệ thống.';

  @override
  String get secEnableReason => 'Xác thực để bật khóa ứng dụng';

  @override
  String get secAuthFailed => 'Xác thực không thành công';

  @override
  String get secLockOn => 'Đã bật khóa ứng dụng bằng sinh trắc học';

  @override
  String get secLockOff => 'Đã tắt khóa ứng dụng bằng sinh trắc học';

  @override
  String get secPasswordSet => 'Đã đặt mật khẩu';

  @override
  String get secPasswordChanged => 'Đổi mật khẩu thành công';

  @override
  String get secSubtitle => 'Bảo vệ tài khoản và thiết bị của bạn';

  @override
  String get secBiometricLock => 'Khóa ứng dụng bằng sinh trắc học';

  @override
  String get secBiometricOn => 'Yêu cầu vân tay/khuôn mặt mỗi khi mở app.';

  @override
  String get secBiometricUnavailable => 'Thiết bị chưa đăng ký sinh trắc học.';

  @override
  String secLoadFailed(Object error) {
    return 'Không tải được thông tin tài khoản: $error';
  }

  @override
  String get secChangePassword => 'Đổi mật khẩu';

  @override
  String get secSetPassword => 'Đặt mật khẩu';

  @override
  String get secChangeHint =>
      'Nhập mật khẩu hiện tại và mật khẩu mới. Các thiết bị khác sẽ phải đăng nhập lại.';

  @override
  String get secSetHint =>
      'Tài khoản của bạn đăng nhập bằng Google hoặc mã OTP nên chưa có mật khẩu. Đặt mật khẩu để có thể đăng nhập bằng email/số điện thoại và mật khẩu.';

  @override
  String get secCurrentPassword => 'Mật khẩu hiện tại';

  @override
  String secMinChars(Object min) {
    return 'Ít nhất $min ký tự';
  }

  @override
  String get secConfirmNew => 'Xác nhận mật khẩu mới';

  @override
  String get profSaveFailedNetwork =>
      'Chưa lưu được. Kiểm tra mạng rồi thử lại.';

  @override
  String get phSyncing => 'Đang đồng bộ...';

  @override
  String get phSaveAvatar => 'Lưu ảnh đại diện';

  @override
  String get tcTitle => 'Điều khoản dịch vụ';

  @override
  String get tcBody =>
      'Trước khi dùng Lock.R, vui lòng đọc và đồng ý với Điều khoản dịch vụ và Chính sách bảo mật. Điều khoản quy định việc thuê tủ, gửi và nhận hàng, giao hàng bằng drone, phí, hoàn tiền và bồi thường khi có sự cố.';

  @override
  String get tcReadTerms => 'Đọc Điều khoản dịch vụ';

  @override
  String get tcReadPrivacy => 'Đọc Chính sách bảo mật';

  @override
  String get tcAgreeCheckbox =>
      'Tôi đã đọc và đồng ý với Điều khoản dịch vụ và Chính sách bảo mật của Lock.R.';

  @override
  String get tcAgreeContinue => 'Đồng ý và tiếp tục';

  @override
  String get qlNotConfirmed =>
      'Máy chủ chưa xác nhận đăng nhập kiosk. Vui lòng quét lại mã trên kiosk.';

  @override
  String get qlExpired =>
      'Mã đăng nhập đã hết hạn. Hãy tạo mã mới trên kiosk rồi quét lại.';

  @override
  String get qlUsed =>
      'Mã đăng nhập này đã được dùng. Hãy tạo mã mới trên kiosk.';

  @override
  String get qlInvalid =>
      'Mã đăng nhập kiosk không hợp lệ hoặc đã hết hiệu lực.';

  @override
  String get qlInactive =>
      'Tài khoản của bạn đang bị khoá hoặc chưa kích hoạt nên không đăng nhập kiosk được.';

  @override
  String get qlSessionExpired =>
      'Phiên đăng nhập trên app đã hết. Vui lòng đăng nhập lại rồi quét mã.';

  @override
  String get qlTooFast => 'Thao tác quá nhanh. Vui lòng thử lại sau ít phút.';

  @override
  String get qlNoConnection =>
      'Không kết nối được máy chủ. Kiểm tra mạng rồi thử lại.';

  @override
  String get qlNotSupported =>
      'Máy chủ chưa hỗ trợ đăng nhập kiosk bằng mã QR. Vui lòng đăng nhập bằng số điện thoại trên kiosk.';

  @override
  String get aoChooseLocker => 'Vui lòng chọn tủ.';

  @override
  String get aoEnterCode => 'Vui lòng nhập mã lấy hàng.';

  @override
  String get aoPickupBox => 'ô lấy hàng';

  @override
  String get aoOpened => 'Tủ đã mở ô — lấy hàng rồi đóng cửa tủ lại.';

  @override
  String aoOpenFailed(Object detail) {
    return 'Không mở được ô$detail';
  }

  @override
  String get aoTitle => 'Mở tủ ủy quyền';

  @override
  String get aoSubtitle => 'Lấy hàng bằng mã được gửi cho bạn';

  @override
  String get aoIntro =>
      'Nhập mã lấy hàng (PIN) bạn nhận được — mã có trong mục \"Đơn ủy quyền\" hoặc do người gửi chuyển cho bạn. Bạn cần đứng tại tủ để mở ô.';

  @override
  String get aoOrder => 'Đơn';

  @override
  String get aoTapToChoose => 'Chạm để chọn tủ lấy hàng';

  @override
  String get aoOpenBox => 'Mở ô lấy hàng';

  @override
  String get mdSubtitle => 'Đơn người khác nhờ bạn lấy hộ';

  @override
  String get mdEmpty => 'Chưa có đơn ủy quyền';

  @override
  String get mdEmptyHint =>
      'Khi ai đó ủy quyền bạn lấy hộ (theo số điện thoại của bạn), đơn sẽ hiện ở đây.';

  @override
  String get mdNotSupported =>
      'Máy chủ chưa hỗ trợ mục Đơn ủy quyền. Vui lòng thử lại sau.';

  @override
  String get dnTitleEnRoute => 'Drone đang giao hàng';

  @override
  String get dnTitleApproaching => 'Drone sắp đến';

  @override
  String get dnTitleArrived => 'Drone đã đến nơi';

  @override
  String get dnTitleDelivered => 'Giao hàng thành công';

  @override
  String get dnTitleDelayed => 'Đơn hàng bị chậm';

  @override
  String get dnTitleFailed => 'Giao hàng không thành công';

  @override
  String get dnTitleUpdate => 'Cập nhật đơn hàng';

  @override
  String get dnBodyEnRoute => 'Drone đang trên đường giao hàng của bạn';

  @override
  String get dnBodyApproaching =>
      'Drone sắp đến nơi, vui lòng chuẩn bị ra nhận';

  @override
  String get dnBodyArrived => 'Drone đã đến nơi, vui lòng ra nhận hàng';

  @override
  String get dnBodyDelivered => 'Đã giao hàng thành công. Cảm ơn bạn!';

  @override
  String dnBodyDelayedEta(Object eta) {
    return 'Đơn của bạn đang bị chậm, dự kiến tới $eta';
  }

  @override
  String get dnBodyDelayed => 'Đơn của bạn đang bị chậm so với dự kiến';

  @override
  String get dnBodyFailed => 'Giao không thành công, drone đang quay về';

  @override
  String get dnBodyUpdate => 'Đơn hàng của bạn có cập nhật mới';

  @override
  String get nlSubtitle => 'Cập nhật mới nhất từ Lock.R';

  @override
  String get nlLoginRequired => 'Bạn cần đăng nhập để xem thông báo';

  @override
  String get nlReadAll => 'Đọc tất cả';

  @override
  String get nlLoading => 'Đang tải thông báo...';

  @override
  String get nlAllSeen => 'Đã xem hết thông báo';

  @override
  String get nlEmpty => 'Chưa có thông báo nào';

  @override
  String get nlEmptyHint => 'Khi có thông báo mới, chúng sẽ xuất hiện ở đây';

  @override
  String get nlLoadFailed => 'Không tải được thông báo';

  @override
  String get nlDeleteAllQuestion => 'Xoá tất cả thông báo?';

  @override
  String get nlDeleteAllBody =>
      'Toàn bộ thông báo của tài khoản sẽ bị xoá và không khôi phục được.';

  @override
  String get nlDeleteAll => 'Xoá tất cả';

  @override
  String get nlDeletedAll => 'Đã xoá tất cả thông báo';

  @override
  String get nlJustNow => 'Vừa xong';

  @override
  String nlMinutesAgo(int minutes) {
    return '$minutes phút trước';
  }

  @override
  String nlHoursAgo(int hours) {
    return '$hours giờ trước';
  }

  @override
  String nlDaysAgo(int days) {
    return '$days ngày trước';
  }

  @override
  String get npLoadFailed => 'Không tải được thông báo. Vui lòng thử lại.';

  @override
  String get npLoadMoreFailed =>
      'Không tải thêm được thông báo. Vui lòng thử lại.';

  @override
  String get npDeleteNotFound =>
      'Không tìm thấy thông báo hoặc máy chủ chưa hỗ trợ xoá.';

  @override
  String get npDeleteFailed => 'Không xoá được thông báo. Vui lòng thử lại.';

  @override
  String get npDeleteNotSupported =>
      'Máy chủ chưa hỗ trợ xoá thông báo. Vui lòng thử lại sau.';

  @override
  String get crNoLockers => 'Không tìm thấy tủ nào để báo sự cố.';

  @override
  String get crNetworkError => 'Lỗi kết nối mạng';

  @override
  String get crSessionExpired =>
      'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại.';

  @override
  String get crEnterTitle => 'Vui lòng nhập tiêu đề';

  @override
  String get crEnterDescription => 'Vui lòng nhập mô tả chi tiết';

  @override
  String get crChooseLocker => 'Vui lòng chọn tủ gặp sự cố';

  @override
  String get crAttachPhoto => 'Vui lòng đính kèm ít nhất 1 ảnh sự cố';

  @override
  String get crSending => 'Đang gửi báo cáo...';

  @override
  String get crSent => 'Gửi báo cáo thành công';

  @override
  String crSendFailed(Object error) {
    return 'Gửi báo cáo thất bại: $error';
  }

  @override
  String crFirstPhotosOnly(Object count, Object max) {
    return 'Chỉ lấy $count ảnh đầu (tối đa $max)';
  }

  @override
  String get crTitle => 'Báo cáo sự cố';

  @override
  String get crTitleField => 'Tiêu đề';

  @override
  String get crTitleHint => 'Nhập tiêu đề sự cố';

  @override
  String get crDescriptionField => 'Mô tả chi tiết';

  @override
  String get crDescriptionHint => 'Mô tả rõ vấn đề bạn gặp phải';

  @override
  String get crCancelOrList => 'Hủy / Danh sách';

  @override
  String get crBack => 'Trở về';

  @override
  String get crSubmit => 'Gửi báo cáo';

  @override
  String get crFaultyLocker => 'Tủ đồ bị lỗi';

  @override
  String get crTapToChoose => 'Chạm để chọn tủ gặp sự cố';

  @override
  String get crChooseBox => 'Chọn ô gặp sự cố ';

  @override
  String get crOptional => '(Tuỳ chọn)';

  @override
  String get crLayout => 'Sơ đồ';

  @override
  String get crCards => 'Thẻ';

  @override
  String get crDeselect => 'Bỏ chọn';

  @override
  String get crNoBoxes =>
      'Không tìm thấy danh sách ô hoặc sự cố xảy ra chung toàn trạm.';

  @override
  String crSelectedBox(Object number, Object type, Object status) {
    return 'Đang chọn: Ô #$number • $type • $status';
  }

  @override
  String get crDoorOpenWarning => '⚠️ Cửa ô này hiện đang MỞ trên hệ thống.';

  @override
  String get crSelectedKiosk =>
      'Đang chọn: Màn hình cảm ứng 7\" Kiosk (Sự cố toàn trạm)';

  @override
  String get crKioskHint =>
      'Báo cáo lỗi màn hình đơ/tắt, lỗi cảm ứng hoặc sự cố không thuộc ô cụ thể.';

  @override
  String get crKioskTitle => 'Sự cố màn hình cảm ứng Kiosk 7 inch';

  @override
  String get crKioskScreen => 'Màn hình Kiosk';

  @override
  String get crTapToReport => 'Chạm báo lỗi';

  @override
  String get crSuitcaseBayUpper => 'KHOANG VALI LỚN';

  @override
  String get crOpen => 'Mở';

  @override
  String get crPhotos => 'Ảnh hiện trường sự cố';

  @override
  String crPhotoCount(Object count) {
    return '$count ảnh';
  }

  @override
  String crPhotosHint(Object max) {
    return 'Có thể thêm nhiều ảnh cùng lúc từ thư viện hoặc dùng camera chụp từng ảnh (tối đa $max ảnh)';
  }

  @override
  String get crPickMany => 'Chọn nhiều ảnh';

  @override
  String get cdiLoadFailed => 'Chưa tải được thông tin sự cố của đơn';

  @override
  String get cdiInProgress => 'Sự cố rơi kiện đang được xử lý';

  @override
  String get cdiResolved => 'Sự cố rơi kiện đã xử lý xong';

  @override
  String get cdiCode => 'Mã sự cố';

  @override
  String get cdiRecovery => 'Thu hồi kiện';

  @override
  String get cdiParcelState => 'Tình trạng kiện';

  @override
  String get cdiFieldNote => 'Ghi chú hiện trường';

  @override
  String get cdiRecoveryPhotos => 'Ảnh kiện khi thu hồi';

  @override
  String get cdiLastUpdate => 'Cập nhật gần nhất';

  @override
  String get cdiProposal => 'Phương án xử lý';

  @override
  String cdiProposalVersion(Object version) {
    return ' (lần $version)';
  }

  @override
  String cdiContent(Object note) {
    return 'Nội dung: $note';
  }

  @override
  String get cdiPolicy => 'Áp dụng chính sách sự cố tại thời điểm bạn đặt đơn';

  @override
  String get cdiNoBank => 'Chưa có tài khoản ngân hàng nhận bồi thường';

  @override
  String get cdiNoBankBody =>
      'Phương án giải quyết có khoản hoàn tiền/bồi thường. Bạn cần liên kết tài khoản ngân hàng để hệ thống thực hiện chuyển khoản.';

  @override
  String get cdiUpdateBank => 'Cập nhật tài khoản ngân hàng';

  @override
  String get cdiSenderDecides =>
      'Người gửi đơn sẽ đồng ý hoặc yêu cầu xem xét phương án này.';

  @override
  String get cdiRequestReview => 'Yêu cầu xem xét';

  @override
  String get cdiAccept => 'Đồng ý';

  @override
  String get cdiAcceptQuestion => 'Đồng ý phương án?';

  @override
  String get cdiReviewQuestion => 'Yêu cầu Lock.R xem xét lại?';

  @override
  String get cdiNoteOptional => 'Ghi chú (không bắt buộc)';

  @override
  String get cdiReviewReason => 'Lý do cần xem xét *';

  @override
  String get cdiEnterReason => 'Vui lòng nhập lý do cần xem xét.';

  @override
  String get cdiAccepted => 'Đã ghi nhận phương án bạn chọn.';

  @override
  String get cdiReviewSent => 'Đã gửi yêu cầu xem xét lại.';

  @override
  String cdiCompensation(Object amount) {
    return 'Bồi thường $amount';
  }

  @override
  String get cdiFreeRedelivery => 'giao lại miễn phí';

  @override
  String get cdiRefundShipping => 'hoàn phí giao';

  @override
  String get crSelectLocker => 'Vui lòng chọn tủ gặp sự cố.';

  @override
  String aiErrLength(Object max) {
    return 'Câu hỏi cần từ 1 đến $max ký tự.';
  }

  @override
  String get aiErrBadResponse => 'Phản hồi từ máy chủ không hợp lệ.';

  @override
  String get aiErrGeneric => 'Đã xảy ra lỗi, vui lòng thử lại.';

  @override
  String get aiErrNotFound =>
      'Không tìm thấy cuộc hội thoại này, có thể nó đã bị xoá.';

  @override
  String get aiErrLength2000 => 'Câu hỏi cần từ 1 đến 2000 ký tự.';

  @override
  String get aiErrServer => 'Máy chủ gặp lỗi, vui lòng thử lại sau.';

  @override
  String get aiErrConnectTimeout =>
      'Kết nối tới máy chủ quá lâu, vui lòng thử lại.';

  @override
  String get aiErrReplyTimeout => 'Trợ lý phản hồi quá lâu, vui lòng thử lại.';

  @override
  String get aiErrNoConnection =>
      'Không thể kết nối máy chủ. Kiểm tra kết nối mạng.';

  @override
  String get aiErrCancelled => 'Đã huỷ yêu cầu.';

  @override
  String get aiErrSession => 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';

  @override
  String get aiErrForbidden => 'Bạn không có quyền dùng trợ lý hỏi đáp.';

  @override
  String get aiErrRateLimit =>
      'Bạn đã hỏi quá nhiều câu, vui lòng thử lại sau.';

  @override
  String get aiErrBusy =>
      'Trợ lý đang bận hoặc gặp sự cố, vui lòng thử lại sau.';

  @override
  String get aiDocument => 'Tài liệu';

  @override
  String get aiConversation => 'Cuộc hội thoại';

  @override
  String get aiEyebrow => 'LOCK.R • TRỢ LÝ';

  @override
  String get aiTitle => 'Trợ lý hỏi đáp';

  @override
  String get aiSubtitle => 'Trả lời từ tài liệu chính thức, có trích nguồn';

  @override
  String get aiHistory => 'Lịch sử hỏi đáp';

  @override
  String get aiNewConversation => 'Cuộc hội thoại mới';

  @override
  String get aiDisabledTitle => 'Trợ lý đang tạm tắt';

  @override
  String get aiDisabledBody =>
      'Tính năng hỏi đáp đang được tạm tắt. Bạn vui lòng quay lại sau.';

  @override
  String get aiNotReadyTitle => 'Trợ lý chưa sẵn sàng';

  @override
  String get aiNotReadyBody =>
      'Trợ lý hỏi đáp chưa được cấu hình xong. Bạn vui lòng quay lại sau hoặc liên hệ bộ phận hỗ trợ Lock.R.';

  @override
  String get aiWaiting => 'Đang chờ trợ lý trả lời…';

  @override
  String get aiInputHint => 'Nhập câu hỏi của bạn…';

  @override
  String get aiSend => 'Gửi câu hỏi';

  @override
  String get aiDeleteQuestion => 'Xoá cuộc hội thoại?';

  @override
  String aiDeleteBody(Object title) {
    return 'Cuộc hội thoại “$title” sẽ bị xoá vĩnh viễn và không khôi phục được.';
  }

  @override
  String get aiDeleted => 'Đã xoá cuộc hội thoại';

  @override
  String get aiHistorySubtitle => 'Các cuộc hội thoại của bạn với trợ lý';

  @override
  String get aiNoConversations => 'Chưa có cuộc hội thoại nào';

  @override
  String get aiNoConversationsBody =>
      'Các câu bạn hỏi trợ lý sẽ được lưu ở đây để xem lại.';

  @override
  String get aiAsk => 'Đặt câu hỏi';

  @override
  String aiMessageCount(int count) {
    return '$count tin nhắn';
  }

  @override
  String aiTodayAt(Object time) {
    return 'Hôm nay, $time';
  }

  @override
  String aiYesterdayAt(Object time) {
    return 'Hôm qua, $time';
  }

  @override
  String get aiQTechInspection =>
      'Kiểm tra định kỳ không đạt thì xử lý thế nào?';

  @override
  String get aiQTechDoor => 'Ô tủ báo lỗi cửa thì cần kiểm tra những gì?';

  @override
  String get aiQTechTicket => 'Quy trình xử lý phiếu sự cố ra sao?';

  @override
  String get aiQTechIot => 'Thiết bị IoT của tủ mất kết nối thì làm gì?';

  @override
  String get aiQDroneLaunch => 'Quy trình tiếp nhận và phóng đơn drone ra sao?';

  @override
  String get aiQDroneCancel => 'Khi nào được huỷ nhiệm vụ trước khi bay?';

  @override
  String get aiQDronePad => 'Bãi đáp drone báo lỗi thì làm gì?';

  @override
  String get aiQSend => 'Làm sao để gửi hàng qua tủ?';

  @override
  String get aiQPay => 'Tôi thanh toán bằng những cách nào?';

  @override
  String get aiQRentEnd => 'Hết giờ thuê ô thì làm sao?';

  @override
  String get aiQCantOpen => 'Không mở được ô tủ thì phải làm gì?';

  @override
  String get aiDocsStaff =>
      'quy trình vận hành, hướng dẫn kỹ thuật, chính sách';

  @override
  String get aiDocsCustomer =>
      'hướng dẫn sử dụng, chính sách, câu hỏi thường gặp';

  @override
  String get aiHello => 'Xin chào! Mình là trợ lý Lock.R';

  @override
  String aiIntro(Object docs) {
    return 'Mình trả lời dựa trên tài liệu chính thức của Lock.R ($docs) và luôn ghi rõ nguồn trích dẫn. Nếu tài liệu chưa đề cập, mình sẽ nói rõ để bạn liên hệ bộ phận hỗ trợ.';
  }

  @override
  String get aiOfficialDocs => 'Tài liệu chính thức';

  @override
  String get aiWithSources => 'Có trích nguồn';

  @override
  String get aiYouCanAsk => 'Bạn có thể hỏi';

  @override
  String get aiNotSent => 'Chưa gửi được';

  @override
  String get aiNotInDocs => 'Chưa có trong tài liệu';

  @override
  String get aiTyping => 'Trợ lý đang trả lời';

  @override
  String aiSources(Object count) {
    return 'Nguồn ($count)';
  }

  @override
  String get aiCitationsUpper => 'TRÍCH DẪN NGUỒN';

  @override
  String get aiNoExcerpt => 'Không có đoạn trích.';

  @override
  String get aiVerbatim =>
      'Trích nguyên văn từ tài liệu chính thức của Lock.R.';

  @override
  String get tagAccepted => '[NGHIỆM THU THÀNH CÔNG]';

  @override
  String get tagFieldNote => '[GHI CHÚ HIỆN TRƯỜNG]';

  @override
  String get tagSlaExtended => '[GIA HẠN SLA]';

  @override
  String get tagRepairProgress => '[TIẾN ĐỘ SỬA CHỮA]';

  @override
  String get urdInspectionPhotos => 'KTV đã chụp ảnh kiểm tra hiện trường.';

  @override
  String get urdProgressPhotos => 'KTV cập nhật ảnh tiến độ xử lý.';

  @override
  String urdSlaExtended(Object hours) {
    return 'Phiếu được gia hạn thêm $hours giờ.';
  }

  @override
  String urdNewDeadline(Object time) {
    return '- Hạn hoàn tất mới: $time';
  }

  @override
  String urdReason(Object reason) {
    return '- Lý do: $reason';
  }

  @override
  String get urdTechResolved => 'KTV đã hoàn tất phiếu.';

  @override
  String get urdTechSentAcceptance => 'KTV đã gửi ảnh nghiệm thu.';

  @override
  String get urdKioskNoLocation => 'Trạm Kiosk chưa có dữ liệu vị trí bản đồ.';

  @override
  String get urdPhotosAdded => 'Đã bổ sung ảnh thành công!';

  @override
  String get urdKioskStation => 'Trạm Kiosk';

  @override
  String get urdRecordTitle => 'Hồ sơ chi tiết phiếu sự cố kỹ thuật';

  @override
  String urdCreatedAt(Object time) {
    return 'Tạo lúc: $time';
  }

  @override
  String urdTechInCharge(Object name) {
    return 'KTV phụ trách: $name';
  }

  @override
  String get urdDispatching => 'Đang điều phối KTV';

  @override
  String urdResolvedAt(Object time) {
    return 'Hoàn tất lúc: $time';
  }

  @override
  String urdDeadline(Object time) {
    return 'Hạn xử lý: $time';
  }

  @override
  String urdBoxIncident(Object box) {
    return 'Sự cố Ô tủ #$box';
  }

  @override
  String get urdKioskIncident => 'Sự cố Trạm Kiosk';

  @override
  String urdOrder(Object code) {
    return 'Đơn hàng: $code';
  }

  @override
  String get urdDirectionsKiosk => 'Chỉ đường tới Kiosk';

  @override
  String get urdCopyPhone => 'Sao chép SĐT';

  @override
  String get urdPhoneCopied => 'Đã sao chép số điện thoại';

  @override
  String get urdReportContent => 'Nội dung phản ánh sự cố:';

  @override
  String get urdMorePhotos => 'Bổ sung ảnh';

  @override
  String get urdYourPhotos => 'Ảnh hiện trường sự cố bạn đã gửi';

  @override
  String get urdProgressTitle => 'Tiến trình xử lý sự cố:';

  @override
  String get urdTeamResponse => 'Phản hồi từ đội ngũ kỹ thuật:';

  @override
  String urdTechId(Object id) {
    return 'KTV #$id';
  }

  @override
  String get urdDispatchingAccept => 'Đang điều phối KTV tiếp nhận';

  @override
  String urdTechAcceptedAt(Object tech, Object time) {
    return '$tech · Tiếp nhận: $time';
  }

  @override
  String urdTechAccepted(Object tech) {
    return '$tech đã tiếp nhận điều phối';
  }

  @override
  String get urdTechInspected => 'KTV đã kiểm tra & xử lý hiện trường';

  @override
  String urdHandledAt(Object time, Object desc) {
    return 'Đã xử lý lúc $time$desc';
  }

  @override
  String get urdCheckedHandled => 'Đã kiểm tra & xử lý';

  @override
  String urdFixedAt(Object time) {
    return 'Đã hoàn tất xử lý lúc $time';
  }

  @override
  String get urdFixed => 'Đã khắc phục hoàn tất';

  @override
  String get urdTechInspecting => 'KTV đang kiểm tra hiện trường & xử lý';

  @override
  String get urdWaitingTech => 'Chờ KTV tới trạm Kiosk kiểm tra';

  @override
  String urdClosedAt(Object time, Object feedback) {
    return 'Đóng lúc $time$feedback';
  }

  @override
  String urdFeedback(Object text) {
    return 'Phản hồi: $text';
  }

  @override
  String get urdCheckedNormal => 'KTV đã kiểm tra, ô hoạt động bình thường';

  @override
  String urdAcceptedAt(Object time, Object note) {
    return 'Nghiệm thu lúc: $time$note';
  }

  @override
  String urdAcceptedDone(Object note) {
    return 'Đã nghiệm thu hoàn tất$note';
  }

  @override
  String urdExpectedBy(Object time) {
    return 'Dự kiến hoàn tất trước: $time';
  }

  @override
  String get urdAwaitingAcceptance => 'Chờ nghiệm thu & đóng phiếu';

  @override
  String urdSentAt(Object time) {
    return 'Đã gửi: $time';
  }

  @override
  String get urdRecorded => 'Hệ thống đã ghi nhận sự cố';

  @override
  String get urdStepTechAccepts => 'Kỹ thuật viên tiếp nhận';

  @override
  String get urdStepInspect => 'Kiểm tra & Xử lý tại Kiosk';

  @override
  String get urdStepRejected => 'KTV không xác nhận sự cố';

  @override
  String get urdStepAccept => 'Nghiệm thu & Đóng phiếu';

  @override
  String get urdTechProgress => 'Tiến độ xử lý của KTV:';

  @override
  String get urdAcceptingTech => 'Kỹ thuật viên nghiệm thu';

  @override
  String get urdNoTechNotes =>
      'KTV chưa ghi chú bước xử lý nào. Các thao tác của KTV sẽ hiển thị ở đây.';

  @override
  String get urdSlaApproval => 'Phê duyệt gia hạn SLA';

  @override
  String urdRepairPhotos(Object count) {
    return 'Ảnh trong quá trình sửa ($count ảnh):';
  }

  @override
  String get urdKioskTech => 'Kỹ thuật viên kiosk';

  @override
  String get urdCustomerView =>
      'Chế độ xem khách hàng · KTV cập nhật nhật ký & minh chứng qua Mobile App';

  @override
  String urdSteps(int count) {
    return '$count bước xử lý';
  }

  @override
  String get urdThanksRating => 'Cảm ơn bạn đã gửi đánh giá!';

  @override
  String urdRatingError(Object error) {
    return 'Lỗi gửi đánh giá: $error';
  }

  @override
  String get urdYourRating => 'Đánh giá của bạn về KTV';

  @override
  String get urdRateTech => 'Đánh giá chất lượng phục vụ của KTV';

  @override
  String urdComment(Object text) {
    return 'Nhận xét: \"$text\"';
  }

  @override
  String get urdRatePrompt =>
      'Phiếu sự cố đã được xử lý xong. Hãy đánh giá sự hài lòng của bạn:';

  @override
  String get urdRateHint =>
      'Nhận xét thêm về thái độ hoặc tốc độ xử lý của KTV (tuỳ chọn)...';

  @override
  String get urdSendRating => 'Gửi đánh giá';

  @override
  String get urdChoosePhoto => 'Vui lòng chọn ít nhất 1 ảnh.';

  @override
  String get urdAddPhotosTitle => 'Bổ sung ảnh sự cố';

  @override
  String urdAddPhotosHint(Object max) {
    return 'Tối đa $max ảnh mỗi lần. Ảnh giúp đội bảo trì chuẩn bị đúng linh kiện trước khi tới.';
  }

  @override
  String get urdSendPhotos => 'Gửi ảnh';

  @override
  String get mrUnknownTime => 'Không rõ thời gian';

  @override
  String get mrAwaiting => 'Chờ tiếp nhận';

  @override
  String get mrNone => 'Chưa có báo cáo nào';

  @override
  String get mrNoneHint =>
      'Báo lỗi từ chi tiết đơn hoặc tab \"Báo sự cố mới\" sẽ hiện ở đây.';

  @override
  String get mrReportNow => 'Báo sự cố ngay';

  @override
  String get mrNoMatch => 'Không có báo cáo phù hợp';

  @override
  String mrNoMatchFilter(Object filter) {
    return 'Không có phiếu sự cố nào thuộc bộ lọc \"$filter\".';
  }

  @override
  String get mrViewAll => 'Xem tất cả báo cáo';

  @override
  String get mrEyebrow => 'LOCK.R • BÁO CÁO';

  @override
  String get mrSubtitle => 'Theo dõi tiến độ xử lý và gửi báo cáo sự cố ô tủ';

  @override
  String get mrNewReport => 'Báo sự cố mới';

  @override
  String mrTicketHash(Object id) {
    return 'Phiếu sự cố #$id';
  }

  @override
  String get mrLockerPoint => 'Điểm tủ';

  @override
  String get mrBox => 'Ô tủ';

  @override
  String get fbDamaged => 'Hàng bị hư hỏng';

  @override
  String get fbMissing => 'Thiếu / mất hàng';

  @override
  String get fbLocker => 'Tủ / ô gặp sự cố';

  @override
  String get fbPayment => 'Thanh toán / phí';

  @override
  String get fbService => 'Chất lượng dịch vụ';

  @override
  String get fbStPending => 'Đang chờ xử lý';

  @override
  String get fbStProcessing => 'Đang xử lý';

  @override
  String get fbStResolved => 'Đã xử lý';

  @override
  String get fbStRejected => 'Đã từ chối';

  @override
  String get fbStRecorded => 'Đã ghi nhận';

  @override
  String get fbRateOrder => 'Đánh giá đơn hàng';

  @override
  String get fbRateHint => 'Chia sẻ trải nghiệm của bạn (không bắt buộc)';

  @override
  String get fbRateNotSupported => 'Máy chủ chưa hỗ trợ đánh giá đơn.';

  @override
  String get fbThanks => 'Cảm ơn bạn đã đánh giá đơn hàng.';

  @override
  String get fbComplain => 'Gửi khiếu nại';

  @override
  String get fbIssue => 'Vấn đề';

  @override
  String get fbIssueHint => 'Mô tả chi tiết vấn đề bạn gặp phải';

  @override
  String get fbDescribe => 'Vui lòng mô tả vấn đề.';

  @override
  String get fbComplainNotSupported => 'Máy chủ chưa hỗ trợ khiếu nại đơn.';

  @override
  String get fbComplaintSent =>
      'Đã gửi khiếu nại — bộ phận hỗ trợ sẽ phản hồi qua thông báo.';

  @override
  String get fbRateAndComplain => 'Đánh giá & khiếu nại';

  @override
  String get fbComplaint => 'Khiếu nại';

  @override
  String get fbEditRating => 'Sửa đánh giá';

  @override
  String fbSentAt(Object time) {
    return 'Gửi lúc $time';
  }

  @override
  String get fbNotSupported =>
      'Máy chủ chưa hỗ trợ đánh giá / khiếu nại đơn. Vui lòng thử lại sau.';

  @override
  String btBoxOccupied(Object box) {
    return 'Ô $box đang có hàng';
  }

  @override
  String get btBoxOccupiedBody =>
      'Ô này đang giữ hàng của một đơn. Chỉ mở khi bạn được giao kiểm tra tủ và đóng lại ngay sau khi thử.';

  @override
  String get btOpenAnyway => 'Vẫn mở';

  @override
  String get btFetchingCode => 'Đang lấy mã mở ô từ máy chủ…';

  @override
  String get btScanning => 'Đang tìm tủ qua Bluetooth…';

  @override
  String get btConnecting => 'Đang kết nối với tủ…';

  @override
  String get btSending => 'Đang gửi lệnh mở ô…';

  @override
  String get btWaiting => 'Chờ tủ mở khoá…';

  @override
  String get btSubtitle => 'Đứng cạnh tủ, chọn ô rồi bấm mở';

  @override
  String get btChooseBox => 'Chọn một ô để mở';

  @override
  String btOpenBox(Object box) {
    return 'Mở ô $box qua Bluetooth';
  }

  @override
  String get btLoadFailed => 'Không tải được danh sách tủ';

  @override
  String get btNotAllowed => 'Chưa được cho thử';

  @override
  String get btNotAllowedBody =>
      'Admin chưa cho tài khoản này thử mở ô qua Bluetooth ở tủ nào.';

  @override
  String get btHint =>
      'Bật Bluetooth và đứng trong khoảng 2 m trước tủ. Mỗi lần mở đều được ghi vào nhật ký của tủ.';

  @override
  String get btChooseBoxLabel => 'Chọn ô';

  @override
  String btOpened(Object box) {
    return 'Đã mở ô $box';
  }

  @override
  String get btNotOpened => 'Chưa mở được';

  @override
  String get btCloseAfter => 'Nhớ đóng cửa ô sau khi thử.';

  @override
  String get btNoBoxes => 'Tủ chưa có ô nào.';

  @override
  String btBox(Object number) {
    return 'Ô $number';
  }

  @override
  String get apiErrValidation =>
      'Dữ liệu gửi lên không hợp lệ, vui lòng kiểm tra lại.';

  @override
  String get apiErrInternal =>
      'Máy chủ gặp lỗi hoặc chưa hỗ trợ thao tác này. Vui lòng thử lại sau.';

  @override
  String get apiErrNotFound =>
      'Không tìm thấy dữ liệu (có thể đã bị xoá hoặc thay đổi).';

  @override
  String get apiErrLockerServiceUnavailable =>
      'Dịch vụ tủ đang tạm gián đoạn, vui lòng thử lại sau.';

  @override
  String get dbHeight => 'Cao';

  @override
  String get commonView => 'Xem';

  @override
  String get ordFilterDrone => 'Giao drone';

  @override
  String get recvDroneDelivery => 'Giao Drone';

  @override
  String get holderNameHint => 'NGUYEN VAN A';

  @override
  String techHomeScheduleNotFound(Object id) {
    return 'Không tìm thấy lịch kiểm tra #$id (có thể đã bị xoá hoặc không thuộc tủ bạn xem được).';
  }

  @override
  String techHomeLoadPartialFailed(Object details) {
    return 'Không tải được đầy đủ dữ liệu: $details';
  }

  @override
  String get techHomeLogoutShiftTitle => 'Đăng xuất ca trực';

  @override
  String get techHomeLogoutShiftConfirm =>
      'Bạn có chắc chắn muốn kết thúc ca trực và đăng xuất khỏi tài khoản KTV tủ không?';

  @override
  String get techHomeLockerTechnician => 'Kỹ thuật viên tủ';

  @override
  String get techHomePhoneNotSet => 'Chưa cập nhật SĐT';

  @override
  String get techHomeLockerTechnicianRole =>
      'Kỹ thuật viên tủ (ô tủ & phần cứng)';

  @override
  String get techHomeStatReceived => 'Phiếu đã nhận';

  @override
  String get techHomeStatInProgress => 'Đang làm';

  @override
  String get techHomeQualityRatingLabel => 'Đánh giá chất lượng: ';

  @override
  String get techHomeNoRatingYet => 'Chưa có đánh giá';

  @override
  String get techHomeSlaPolicyLabel => 'Quy chế SLA: ';

  @override
  String get techHomeTechPhoneLabel => 'SĐT kỹ thuật: ';

  @override
  String get techHomeViewEditProfile => 'Xem & Chỉnh sửa hồ sơ';

  @override
  String get techHomeSlaRestrictedTitle => 'Hạn chế nhận việc mới';

  @override
  String get techHomeSlaRestrictedBody =>
      'Quy chế SLA: khi số phiếu quá hạn vượt ngưỡng do quản trị cấu hình, KTV tạm thời không nhận được việc mới. Vui lòng chuyển sang tab \"Việc của tôi\" và hoàn tất các công việc tồn đọng.';

  @override
  String get techHomeViewMyWork => 'Xem việc của tôi';

  @override
  String get techHomeOpenTicket => 'Mở phiếu';

  @override
  String get techHomeBoxBackOnline => 'Ô đã hoạt động lại';

  @override
  String techHomeTicketLoadFailed(Object id) {
    return 'Không tải được phiếu RPT-$id';
  }

  @override
  String techHomeTicketAlreadyClosed(Object id) {
    return 'Phiếu RPT-$id đã được đóng.';
  }

  @override
  String techHomeTicketHandledByOther(Object id, Object assignee) {
    return 'Phiếu RPT-$id đang do $assignee xử lý — chỉ người được giao mới hoàn tất được.';
  }

  @override
  String techHomeTicketUnassignedTitle(Object id) {
    return 'Phiếu RPT-$id chưa có người nhận';
  }

  @override
  String get techHomeTicketUnassignedBody =>
      'Ô/bãi đáp này đang có phiếu sự cố mở. Nhận phiếu rồi nghiệm thu (chụp ảnh sau khi sửa) để đưa về hoạt động.';

  @override
  String get techHomeClaimAndAccept => 'Nhận & nghiệm thu';

  @override
  String get techHomeLockerNoLocation => 'Tủ này chưa có vị trí để chỉ đường.';

  @override
  String get techHomeGreetingMorning => '☀️ Chào buổi sáng';

  @override
  String get techHomeGreetingNoon => '🌤️ Chào buổi trưa';

  @override
  String get techHomeGreetingAfternoon => '🌅 Chào buổi chiều';

  @override
  String get techHomeGreetingEvening => '🌙 Chào ca tối';

  @override
  String techHomeSlaSuspended(Object count) {
    return 'SLA: Đình chỉ ($count phiếu trễ hạn)';
  }

  @override
  String techHomeSlaRestricted(Object count) {
    return 'SLA: Hạn chế nhận việc ($count phiếu trễ hạn)';
  }

  @override
  String techHomeSlaWarning(Object count) {
    return 'SLA: Cảnh báo ($count phiếu trễ hạn)';
  }

  @override
  String techHomeSlaNormalWithCount(Object count) {
    return 'SLA: Bình thường ($count phiếu đang xử lý)';
  }

  @override
  String get techHomeSlaNormal => 'SLA: Bình thường';

  @override
  String techHomeSlaUnknownWithOverdue(Object count) {
    return 'SLA: $count phiếu trễ hạn · chưa tải được mức chế tài';
  }

  @override
  String get techHomeSlaUnknown => 'SLA: chưa tải được trạng thái';

  @override
  String get techHomeProfileAndEdit => 'Hồ sơ & Chỉnh sửa';

  @override
  String get techHomeHudRoutine => 'Định kỳ';

  @override
  String get techHomeHudStations => 'Trạm tủ';

  @override
  String get techHomeTabInspect => 'Kiểm tra tủ';

  @override
  String techHomeTabIncidents(Object count) {
    return 'Sự cố ($count)';
  }

  @override
  String techHomeTabMyWork(Object count) {
    return 'Việc của tôi ($count)';
  }

  @override
  String techHomeTabRoutine(Object count) {
    return 'Định kỳ ($count)';
  }

  @override
  String techHomeTabIotDevices(Object count) {
    return 'Thiết bị IoT ($count)';
  }

  @override
  String techHomeTabParcelRecovery(Object count) {
    return 'Thu hồi kiện ($count)';
  }

  @override
  String techHomeRecoveryBannerTitle(int count) {
    return 'Có $count nhiệm vụ thu hồi kiện rơi';
  }

  @override
  String get techHomeRecoveryBannerHint => 'Chạm để mở tab \"Thu hồi kiện\".';

  @override
  String get techHomePickLockerToInspect => 'Chọn tủ để kiểm tra';

  @override
  String get techHomeLockersLoadFailed => 'Chưa tải được danh sách tủ';

  @override
  String get techHomeNoLockers => 'Chưa có tủ nào';

  @override
  String techHomeLayoutLoadFailed(Object error) {
    return 'Không tải được sơ đồ tủ: $error';
  }

  @override
  String get techHomeKioskPhysicalLayout => 'Sơ đồ vật lý trạm Kiosk';

  @override
  String get techHomeTapBoxHint =>
      'Chạm vào một ô để báo hỏng, mở khẩn cấp hoặc mở lại ô sau khi sửa.';

  @override
  String get techHomeWorkingWell => 'Hoạt động tốt';

  @override
  String get techHomeDroneLandingPad => 'Bãi đáp drone';

  @override
  String techHomeTicketOpenPill(Object id) {
    return 'Phiếu RPT-$id đang mở';
  }

  @override
  String get techHomeLandingPadHint =>
      'Báo Hỏng/Bảo trì ⇒ mở phiếu bãi đáp giao cho bạn. Về \"Hoạt động tốt\" khi còn phiếu ⇒ nghiệm thu phiếu (ảnh sau khi sửa).';

  @override
  String get techHomeLandingPadBackOnline => 'Bãi đáp đã hoạt động lại';

  @override
  String techHomeLandingPadStatus(Object status) {
    return 'Bãi đáp: $status';
  }

  @override
  String techHomeLandingPadStatusTicketOpened(Object status) {
    return 'Bãi đáp: $status — đã mở phiếu sự cố giao cho bạn';
  }

  @override
  String get techHomeReasonLabel => 'Lý do';

  @override
  String get techHomeLandingPadFaultHint =>
      'VD: Marker bong tróc, mặt đáp nứt...';

  @override
  String get techHomeLandingPadMaintenanceHint =>
      'VD: Vệ sinh, sơn lại marker...';

  @override
  String get techHomeReasonRequired => 'Vui lòng nhập lý do.';

  @override
  String get techHomeNoBoxesConfigured => 'Chưa có ô tủ nào được cấu hình.';

  @override
  String get techHomeXlColumn => 'Cột vali XL';

  @override
  String techHomeRowLabel(Object row) {
    return 'Hàng $row';
  }

  @override
  String get techHomeBoxHardwareTitle => 'Tình trạng phần cứng ô';

  @override
  String techHomeNeedsAttentionCount(Object count) {
    return '$count cần chú ý';
  }

  @override
  String get techHomeNoDoorSensorData =>
      'Chưa có dữ liệu cảm biến cửa cho tủ này (cabinet chưa báo hoặc dịch vụ IoT chưa bật).';

  @override
  String techHomeDoorOpenNotOccupied(int count) {
    return '$count ô có cửa đang MỞ nhưng không ở trạng thái \"có đồ\" — nên kiểm tra (cửa kẹt/quên đóng).';
  }

  @override
  String get techHomeNoDoorSignal => 'Chưa có tín hiệu cửa';

  @override
  String get techHomeDoorOpenCaps => 'Cửa đang MỞ';

  @override
  String techHomeReportedAt(Object time) {
    return 'Báo lúc $time';
  }

  @override
  String get techHomeControllerOnline => 'Bộ điều khiển: trực tuyến';

  @override
  String get techHomeControllerOffline => 'Bộ điều khiển: mất kết nối';

  @override
  String techHomeReservedCount(Object count) {
    return 'Đã giữ chỗ: $count';
  }

  @override
  String techHomeOccupiedCount(Object count) {
    return 'Có đồ: $count';
  }

  @override
  String get techHomeYourLocker => 'Tủ bạn phụ trách';

  @override
  String get techHomeVisualCheckHint =>
      'Kiểm tra trực quan từng ô rồi chỉ báo hỏng khi xác nhận lỗi vật lý tại tủ.';

  @override
  String get techHomeReportWholeLocker => 'Báo sự cố cả tủ';

  @override
  String get techHomeLockerIncidentTitleHint =>
      'VD: Màn hình kiosk không lên, mất nguồn...';

  @override
  String techHomeScenePhotosOptional(Object max) {
    return 'Ảnh hiện trường (tuỳ chọn, tối đa $max)';
  }

  @override
  String get techHomeBlockWholeLocker => 'Chặn cả tủ (ngưng nhận đơn)';

  @override
  String get techHomeBlockWholeLockerHint =>
      'Tủ chuyển sang bảo trì cho tới khi phiếu được hoàn tất.';

  @override
  String get techHomeTitleAndDescRequired => 'Vui lòng nhập tiêu đề và mô tả.';

  @override
  String techHomeLockerTicketCreated(Object id, Object locker) {
    return 'Đã tạo phiếu RPT-$id cho $locker.';
  }

  @override
  String techHomeLockerTicketCreatedBlocked(Object id, Object locker) {
    return 'Đã tạo phiếu RPT-$id cho $locker — tủ tạm ngưng nhận đơn.';
  }

  @override
  String techHomeLockerIncidentSent(Object locker) {
    return 'Đã gửi báo sự cố cho $locker.';
  }

  @override
  String get techHomeTotalBoxes => 'Tổng ô';

  @override
  String get techHomeFaultyBoxes => 'Ô lỗi';

  @override
  String get techHomeXlTallBay => 'Khoang đứng XL';

  @override
  String techHomeFixedAcceptTicket(Object id) {
    return 'Đã sửa xong — nghiệm thu phiếu RPT-$id';
  }

  @override
  String get techHomeFixedReopenBox => 'Đã sửa xong — mở lại ô';

  @override
  String get techHomeConfirmBoxFaulty => 'Xác nhận ô hỏng (khoá ô)';

  @override
  String techHomeViewTicketToCheck(Object id) {
    return 'Xem phiếu RPT-$id để kiểm tra';
  }

  @override
  String get techHomeFinishCleaning => 'Hoàn tất vệ sinh';

  @override
  String get techHomeRestoreBox => 'Khôi phục ô';

  @override
  String get techHomeReportBoxFault => 'Báo hỏng ô';

  @override
  String get techHomeTakeBoxOutOfService => 'Ngưng dùng ô';

  @override
  String get techHomeMarkCleaning => 'Đánh dấu đang vệ sinh';

  @override
  String get techHomeBoxCleaning => 'Ô đang vệ sinh';

  @override
  String get techHomeEmergencyOpen => 'Mở tủ khẩn cấp';

  @override
  String techHomeBoxNumberWithType(Object number, Object type) {
    return 'Ô #$number · $type';
  }

  @override
  String techHomeStatusLine(Object status) {
    return 'Trạng thái: $status';
  }

  @override
  String get techHomeDefaultFaultReason => 'Hỏng khóa';

  @override
  String techHomeReportBoxFaultTitle(Object number) {
    return 'Báo hỏng ô #$number';
  }

  @override
  String get techHomeFaultReasonLabel => 'Lý do hỏng';

  @override
  String get techHomeFaultReasonRequired => 'Vui lòng nhập lý do hỏng.';

  @override
  String get techHomeReportFaultAction => 'Báo hỏng';

  @override
  String get techHomeBoxFaultReported => 'Đã báo hỏng ô';

  @override
  String techHomeBoxFaultReportedWithPhotos(int count) {
    return 'Đã báo hỏng ô kèm $count ảnh';
  }

  @override
  String techHomeOutOfServiceTitle(Object number) {
    return 'Ngưng dùng ô #$number';
  }

  @override
  String get techHomeOutOfServiceHint =>
      'Ô sẽ bị loại khỏi phân phối cho khách tới khi được khôi phục.';

  @override
  String get techHomeReasonOptionalLabel => 'Lý do (tùy chọn)';

  @override
  String get techHomeBoxOutOfServiceDone => 'Đã ngưng dùng ô';

  @override
  String get techHomeHardwareAlertsTitle =>
      'Cảnh báo phần cứng (cửa mở bất thường)';

  @override
  String techHomeDoorOpenEmpty(int count) {
    return '$count ô có cửa đang MỞ nhưng không có đồ — nên kiểm tra (cửa kẹt/quên đóng).';
  }

  @override
  String techHomeAnomalyBoxTitle(Object locker, Object number, Object type) {
    return '$locker · Ô #$number ($type)';
  }

  @override
  String techHomeDoorOpenReportedAt(Object time) {
    return 'Cửa MỞ · báo lúc $time';
  }

  @override
  String get techHomeDoorOpenShort => 'Cửa MỞ';

  @override
  String techHomeAllWithCount(Object count) {
    return 'Tất cả ($count)';
  }

  @override
  String techHomeMyLockersWithCount(Object count) {
    return 'Tủ tôi phụ trách ($count)';
  }

  @override
  String get techHomeFilterAllStatuses => 'Mọi trạng thái';

  @override
  String get techHomeFilterUnclaimed => 'Chờ nhận';

  @override
  String get techHomeFilterInProgress => 'Đang xử lý';

  @override
  String get techHomeNoAssignedLockers =>
      'Bạn chưa được giao phụ trách tủ nào — phiếu mới được báo tới mọi KTV tủ.';

  @override
  String techHomeAssignedLockersBanner(int count, Object names) {
    return 'Bạn phụ trách $count tủ: $names. Phiếu mới ở các tủ này được chuyển thẳng cho bạn.';
  }

  @override
  String get techHomePhysicalFaultsTitle => 'Ô đang lỗi vật lý tại trạm';

  @override
  String techHomeLockerBoxTitle(Object locker, Object number) {
    return '$locker · Ô #$number';
  }

  @override
  String get techHomeUnknownReason => 'Không rõ lý do';

  @override
  String techHomeFixedWithTicket(Object id) {
    return 'Đã sửa · phiếu RPT-$id';
  }

  @override
  String get techHomeFixed => 'Đã sửa';

  @override
  String techHomeRoutedTicketsTitle(Object count) {
    return 'Phiếu chờ bạn nhận ($count)';
  }

  @override
  String get techHomeNoRoutedTickets => 'Không có phiếu nào chờ bạn';

  @override
  String get techHomeNoRoutedTicketsHint =>
      'Các tủ bạn phụ trách chưa có sự cố mới.';

  @override
  String techHomeSystemWideTickets(int count) {
    return 'TOÀN HỆ THỐNG: $count PHIẾU SỰ CỐ KIOSK';
  }

  @override
  String techHomeCountUnclaimed(Object count) {
    return '$count chờ nhận';
  }

  @override
  String techHomeCountInProgress(Object count) {
    return '$count đang xử lý';
  }

  @override
  String techHomeCountDone(Object count) {
    return '$count hoàn tất';
  }

  @override
  String techHomeIncidentsAwaitingTech(int count) {
    return '$count sự cố đang chờ KTV tiếp nhận xử lý';
  }

  @override
  String get techHomeIncidentsAwaitingTitle => 'Sự cố chờ tiếp nhận';

  @override
  String get techHomeBeingHandledTitle => 'Đang được xử lý';

  @override
  String get techHomeRecentlyDoneTitle => 'Đã hoàn tất gần đây';

  @override
  String get techHomeNoIncidents => 'Không có sự cố nào';

  @override
  String get techHomeNoIncidentsHint =>
      'Chưa có phiếu sự cố hay ô lỗi nào trên hệ thống.';

  @override
  String get techHomeShiftOverview => 'Tổng quan ca trực';

  @override
  String get techHomeMetricReceived => 'Phiếu\nđã nhận';

  @override
  String get techHomeMetricInProgress => 'Đang\nxử lý';

  @override
  String get techHomeMetricDone => 'Đã\nhoàn tất';

  @override
  String get techHomeMetricSlaOverdue => 'Trễ hạn\nSLA';

  @override
  String techHomeYourRating(Object rating) {
    return 'Điểm đánh giá của bạn: $rating';
  }

  @override
  String get techHomeNoCustomerRatings =>
      'Chưa có đánh giá nào từ khách cho các phiếu bạn xử lý.';

  @override
  String get techHomeStandardProcedure =>
      'Quy trình chuẩn: kiểm tra vị trí tủ, nhận phiếu, tới đúng ô, chụp ảnh nghiệm thu rồi hoàn tất để clear fault.';

  @override
  String get techHomeSlaCardRestricted => 'Đang bị hạn chế nhận việc mới';

  @override
  String get techHomeSlaCardWarning => 'Cảnh báo vi phạm thời gian SLA';

  @override
  String get techHomeSlaCardSuspended => 'Tài khoản trong diện đình chỉ';

  @override
  String get techHomeSlaCardNormal => 'Hồ sơ kỹ thuật viên tốt';

  @override
  String get techHomeSlaCardUnknown => 'Chưa tải được trạng thái SLA';

  @override
  String get techHomeSlaPullToReload =>
      'Kéo xuống để tải lại trạng thái chế tài từ máy chủ.';

  @override
  String techHomeCompletedCount(Object count) {
    return 'Đã hoàn thành: $count';
  }

  @override
  String techHomeInProgressCount(Object count) {
    return 'Đang làm: $count';
  }

  @override
  String techHomeSlaOverdueCount(Object count) {
    return 'Quá hạn SLA: $count';
  }

  @override
  String get techHomeNoWorkYet => 'Bạn chưa nhận việc nào';

  @override
  String get techHomeNoWorkYetHint =>
      'Chuyển sang tab \"Sự cố\" để duyệt và nhận việc mới.';

  @override
  String techHomeActiveIncidentsTitle(Object count) {
    return 'Sự cố đang xử lý ($count)';
  }

  @override
  String techHomeCompletedHistoryTitle(Object count) {
    return 'Lịch sử đã hoàn thành ($count)';
  }

  @override
  String get techHomeScheduleIntro =>
      'Lịch kiểm tra định kỳ Kiosk do quản trị tạo và giao KTV phụ trách. Khi đến hạn, bấm \"Kiểm tra\" và đánh giá từng hạng mục: tất cả đạt ⇒ dời sang chu kỳ kế tiếp; có mục không đạt ⇒ hệ thống mở phiếu giao cho bạn, hạn chỉ dời khi phiếu được hoàn tất.';

  @override
  String techHomeMineWithCount(Object count) {
    return 'Của tôi ($count)';
  }

  @override
  String techHomeAnyDueWithCount(Object count) {
    return 'Mọi hạn ($count)';
  }

  @override
  String techHomeDueWithCount(Object count) {
    return 'Đến hạn ($count)';
  }

  @override
  String techHomeUpcomingWithCount(Object count) {
    return 'Sắp tới ($count)';
  }

  @override
  String get techHomeNoDueSchedules =>
      'Không có lịch kiểm tra Kiosk nào đến hạn';

  @override
  String get techHomeNoUpcomingSchedules =>
      'Không có lịch kiểm tra Kiosk nào sắp tới';

  @override
  String get techHomeNoAssignedSchedules =>
      'Bạn chưa được giao lịch kiểm tra nào';

  @override
  String get techHomeNoSchedulesAtAll =>
      'Chưa có kế hoạch kiểm tra định kỳ Kiosk nào';

  @override
  String get techHomeNoAssignedSchedulesHint =>
      'Chọn \"Tất cả\" để xem lịch của các KTV khác.';

  @override
  String get techHomeNoSchedulesHint =>
      'Mọi thiết bị Kiosk đều đang trong chu kỳ bảo trì bình thường.';

  @override
  String techHomeOverdueByDays(int days) {
    return 'Quá hạn $days ngày';
  }

  @override
  String get techHomeDueToday => 'Đến hạn hôm nay';

  @override
  String techHomeDueInDays(int days) {
    return 'Còn $days ngày nữa đến hạn';
  }

  @override
  String techHomeLastFailedCompleteTicket(Object id) {
    return 'Lần trước không đạt — hoàn tất phiếu RPT-$id trước khi kiểm tra lại.';
  }

  @override
  String get techHomeScheduleOwnedByOther => 'Lịch do KTV khác phụ trách.';

  @override
  String get techHomeRoutineScheduleDefault => 'Lịch kiểm tra định kỳ';

  @override
  String get techHomeDueBadge => 'Đến hạn';

  @override
  String techHomeDueAt(Object date) {
    return 'Hạn: $date';
  }

  @override
  String techHomeCycleEveryDays(Object days) {
    return 'Chu kỳ: Mỗi $days ngày';
  }

  @override
  String get techHomeAssignedBadge => 'Phụ trách';

  @override
  String techHomeLastFailedBanner(Object id) {
    return 'Lần trước KHÔNG ĐẠT · Chờ hoàn tất phiếu RPT-$id trước khi kiểm tra lại';
  }

  @override
  String techHomeHandleTicket(Object id) {
    return 'Xử lý phiếu RPT-$id';
  }

  @override
  String get techHomeInspectAction => 'Kiểm tra';

  @override
  String techHomeInspectionFailedTicket(Object id) {
    return 'Kiểm tra KHÔNG ĐẠT — đã mở phiếu RPT-$id giao cho bạn. Hạn kế tiếp chỉ dời khi phiếu được hoàn tất.';
  }

  @override
  String get techHomeKioskLocker => 'Tủ Kiosk';

  @override
  String techHomeInspectionFailedRecorded(Object title) {
    return 'Đã ghi nhận KHÔNG ĐẠT cho \"$title\".';
  }

  @override
  String techHomeInspectionPassedRecorded(Object title) {
    return 'Đã ghi nhận ĐẠT cho \"$title\".';
  }

  @override
  String techHomeInspectionPassedNextDue(Object title, Object date) {
    return 'Đã ghi nhận ĐẠT cho \"$title\" — hạn kế tiếp $date.';
  }

  @override
  String get techHomeViewWork => 'Xem việc';

  @override
  String get techHomeSlaExtendAssigneeOnly =>
      'Chỉ KTV đang được giao phiếu mới gia hạn được SLA.';

  @override
  String techHomeSlaExtendLimitReached(Object id, Object used, Object max) {
    return 'Phiếu RPT-$id đã gia hạn $used/$max lần — liên hệ admin nếu cần thêm thời gian.';
  }

  @override
  String techHomeSlaExtended(Object id) {
    return 'Đã gia hạn SLA phiếu RPT-$id';
  }

  @override
  String techHomeSlaExtendedNewDue(Object id, Object due) {
    return 'Đã gia hạn SLA phiếu RPT-$id — hạn mới $due';
  }

  @override
  String techHomeReleaseTicketTitle(Object id) {
    return 'Trả lại phiếu RPT-$id';
  }

  @override
  String get techHomeReleaseTicketHint =>
      'Phiếu về lại hàng chờ để KTV khác nhận; lý do được ghi vào nhật ký phiếu.';

  @override
  String get techHomeReleaseReasonLabel => 'Lý do trả phiếu (bắt buộc)';

  @override
  String get techHomeReleaseReasonHint =>
      'VD: Cần linh kiện không có sẵn, đổi ca trực...';

  @override
  String get techHomeReleaseReasonRequired => 'Vui lòng nhập lý do trả phiếu.';

  @override
  String get techHomeReleaseTicketAction => 'Trả lại phiếu';

  @override
  String techHomeTicketReleased(Object id) {
    return 'Đã trả phiếu RPT-$id về hàng chờ.';
  }

  @override
  String techHomeRejectIncidentTitle(Object id) {
    return 'Không xác nhận sự cố RPT-$id';
  }

  @override
  String get techHomeRejectIncidentHint =>
      'Dùng khi đã kiểm tra tại tủ và ô hoạt động bình thường. Phiếu được đóng, ô trở lại hoạt động và phản hồi dưới đây được gửi cho người báo.';

  @override
  String get techHomeReporterFeedbackLabel =>
      'Phản hồi cho người báo (bắt buộc)';

  @override
  String get techHomeReporterFeedbackHint =>
      'VD: Đã thử đóng/mở ô 3 lần, cửa và khoá hoạt động bình thường.';

  @override
  String get techHomeReporterFeedbackRequired =>
      'Vui lòng ghi phản hồi cho người báo.';

  @override
  String get techHomeCloseAndReply => 'Đóng phiếu & phản hồi';

  @override
  String techHomeTicketRejectedDone(Object id) {
    return 'Đã đóng phiếu RPT-$id và gửi phản hồi cho người báo.';
  }

  @override
  String techHomeDevicesLoadFailed(Object error) {
    return 'Không tải được danh sách thiết bị: $error';
  }

  @override
  String get techHomeIotDevices => 'Thiết bị IoT';

  @override
  String get techHomeNoDevices => 'Không có thiết bị nào';

  @override
  String get techHomeNoDevicesHint =>
      'Chưa có bộ điều khiển nào gắn với tủ bạn phụ trách.';

  @override
  String techHomeDeviceNumber(Object id) {
    return 'Thiết bị #$id';
  }

  @override
  String techHomeLastSignal(Object time) {
    return 'Tín hiệu cuối: $time';
  }

  @override
  String get techHomeNoSignalYet => 'Chưa nhận tín hiệu nào';

  @override
  String get techHomeDevicesHint =>
      'Trạng thái do máy chủ tính theo tín hiệu gần nhất của thiết bị. Chạm vào thiết bị để xem nhật ký hoặc khởi động lại bộ điều khiển.';

  @override
  String get techHomeLandingPadPill => 'Bãi đáp';

  @override
  String get techHomeLockerLevelPill => 'Cấp tủ';

  @override
  String get techHomeBlocksLockerPill => 'Ngưng cả tủ';

  @override
  String techHomeFromRoutineInspection(Object id) {
    return 'Từ kiểm tra định kỳ #$id';
  }

  @override
  String get techHomeNewBadge => 'MỚI';

  @override
  String techHomeLockerBoxShort(Object locker, Object box) {
    return '$locker · Ô $box';
  }

  @override
  String get techHomeClaimSuccess => 'Đã nhận việc thành công';

  @override
  String get techHomeClaimAction => 'Nhận việc';

  @override
  String get techHomeNoExtensionsLeft => 'Hết lượt gia hạn';

  @override
  String get techHomeAddPhotosShort => 'Ảnh (+)';

  @override
  String get techHomeAcceptanceAction => 'Nghiệm thu';

  @override
  String techHomeTicketJustUpdated(Object id) {
    return 'Phiếu RPT-$id vừa được cập nhật.';
  }

  @override
  String techHomeSlaExtendedHours(Object hours) {
    return 'Đã gia hạn SLA (+$hours h)';
  }

  @override
  String techHomeOverdueAfterExtension(Object hours) {
    return 'Quá hạn (sau gia hạn +$hours h)';
  }

  @override
  String get techHomeSlaOverdueBadge => 'Quá hạn SLA';

  @override
  String techHomeAssigneeYou(Object name) {
    return '$name (bạn)';
  }

  @override
  String techHomeSlaDueAt(Object time) {
    return 'Hạn SLA: $time';
  }

  @override
  String techHomeExtensionReason(Object reason) {
    return 'Lý do gia hạn: $reason';
  }

  @override
  String get techHomeCustomerComplaint => 'Nội dung khách phản ánh:';

  @override
  String get techHomeCustomerScenePhotos => 'Ảnh hiện trường do khách gửi';

  @override
  String get techHomeClaimNow => 'Nhận việc ngay';

  @override
  String get techHomeInspectAndLockBox => 'Kiểm tra ô & Khóa sự cố tại Kiosk';

  @override
  String get techHomeAcceptAndComplete => 'Nghiệm thu & Hoàn tất xử lý';

  @override
  String get techHomeNotAsDescribed =>
      'Không đúng mô tả — đóng phiếu & phản hồi';

  @override
  String get techHomeReleaseToQueue => 'Trả lại phiếu về hàng chờ';

  @override
  String techHomeTicketHandledByName(Object assignee) {
    return 'Phiếu đang do $assignee xử lý — chỉ người được giao mới hoàn tất được.';
  }

  @override
  String get techHomeTicketBeingHandled => 'Phiếu đang được xử lý.';

  @override
  String get techHomeTicketNoKiosk =>
      'Phiếu sự cố không gắn với trạm Kiosk nào.';

  @override
  String get techHomeBoxIncidentResolved =>
      'Đã cập nhật trạng thái ô tủ và xử lý sự cố thành công!';

  @override
  String get techHomeScenePhotosSaved => 'Đã lưu ảnh xác nhận hiện trường';

  @override
  String techHomeOpenForDays(Object count) {
    return 'Mở $count ngày';
  }

  @override
  String techHomeOpenForHours(Object count) {
    return 'Mở $count giờ';
  }

  @override
  String techHomeOpenForMinutes(Object count) {
    return 'Mở $count phút';
  }

  @override
  String get techHomeJustOpened => 'Vừa mở';

  @override
  String get techHomeMarkDeviceErrorTitle => 'Đánh dấu thiết bị lỗi';

  @override
  String get techHomeMarkDeviceOfflineTitle => 'Đánh dấu thiết bị mất kết nối';

  @override
  String techHomeMarkDeviceErrorBody(Object device) {
    return 'Thiết bị \"$device\" sẽ được đánh dấu lỗi cho tới khi bộ điều khiển gửi tín hiệu trở lại. Tiếp tục?';
  }

  @override
  String techHomeMarkDeviceOfflineBody(Object device) {
    return 'Thiết bị \"$device\" sẽ được đánh dấu mất kết nối cho tới khi bộ điều khiển gửi tín hiệu trở lại. Tiếp tục?';
  }

  @override
  String get techHomeMarkAction => 'Đánh dấu';

  @override
  String get techHomeDeviceMarkedError => 'Đã đánh dấu thiết bị lỗi.';

  @override
  String get techHomeDeviceMarkedOffline => 'Đã đánh dấu thiết bị mất kết nối.';

  @override
  String get techHomeRestartControllerTitle => 'Khởi động lại bộ điều khiển';

  @override
  String techHomeRestartControllerBody(Object device) {
    return 'Bộ điều khiển \"$device\" sẽ khởi động lại tiến trình điều khiển tủ (không khởi động lại máy). Trong lúc đó tủ tạm không mở ô được. Tiếp tục?';
  }

  @override
  String get techHomeRestartAction => 'Khởi động lại';

  @override
  String get techHomeDeviceIdLabel => 'Mã thiết bị';

  @override
  String get techHomeLastSignalLabel => 'Tín hiệu cuối';

  @override
  String get techHomeNoSignalShort => 'Chưa nhận tín hiệu';

  @override
  String get techHomeConnectionLabel => 'Kết nối';

  @override
  String techHomeDeviceLoadFailed(Object error) {
    return 'Không tải được thiết bị: $error';
  }

  @override
  String get techHomeDeviceStatusHint =>
      'Trạng thái do máy chủ tính theo tín hiệu gần nhất; chỉ đánh dấu tay khi biết chắc thiết bị đã mất kết nối hoặc hỏng.';

  @override
  String get techHomeWaitingForLocker => 'Đang chờ tủ phản hồi...';

  @override
  String get techHomeMarkOffline => 'Đánh dấu mất kết nối';

  @override
  String get techHomeMarkError => 'Đánh dấu lỗi';

  @override
  String get techHomeActivityLog => 'Nhật ký hoạt động';

  @override
  String techHomeLogLoadFailed(Object error) {
    return 'Không tải được nhật ký: $error';
  }

  @override
  String get techHomeNoLogsYet => 'Chưa có nhật ký.';

  @override
  String get techHomeQuickChipInspectScene => '📸 Kiểm tra hiện trường';

  @override
  String get techHomeQuickChipReplacePart => '🔧 Thay thế linh kiện';

  @override
  String get techHomeQuickChipCheckPowerBoard => '⚡ Kiểm tra bo mạch nguồn';

  @override
  String get techHomeQuickChipCleanBox => '🧹 Vệ sinh ô tủ sạch sẽ';

  @override
  String get techHomeQuickChipAdjustLatch => '🚪 Cân chỉnh chốt & then';

  @override
  String get techHomeTechLogTitle => 'Nhật ký & Lịch sử xử lý của KTV:';

  @override
  String techHomeTechLogLoadFailed(Object error) {
    return 'Không tải được nhật ký xử lý: $error';
  }

  @override
  String get techHomeNoTechLogsHint =>
      'Chưa có ghi chú xử lý nào. Thao tác \"Kiểm tra ô & Khóa sự cố\" hoặc \"Nghiệm thu\" sẽ tự động lưu lại đầy đủ tại đây.';

  @override
  String techHomeTechNumber(Object id) {
    return 'KTV #$id';
  }

  @override
  String techHomeLogViewerTitle(Object time) {
    return 'Nhật ký · $time';
  }

  @override
  String get techHomeAddLogStep => 'Thêm bước xử lý / ghi chú nhanh...';

  @override
  String get techHomeLogNoteHint => 'Nhập ghi chú xử lý...';

  @override
  String get techHomeQuickNoteReplacedLock =>
      'Đã thay thế linh kiện khóa điện tử';

  @override
  String get techHomeQuickNoteAdjustedHinge =>
      'Đã cân chỉnh then & bản lề cửa ô tủ';

  @override
  String get techHomeQuickNoteCheckedBoard =>
      'Đã kiểm tra bo mạch điều khiển & nguồn';

  @override
  String get techHomeQuickNoteCleanedTested =>
      'Đã vệ sinh sạch sẽ, test đóng mở 3 lần';

  @override
  String get techHomeBoxNotInLayout => 'Không tìm thấy ô trong sơ đồ tủ.';

  @override
  String get techHomeBoxHoldsOrderNoTest =>
      'Ô đang giữ đồ/đơn của khách — không mở thử.';

  @override
  String techHomeBoxCheckFailed(Object error) {
    return 'Không kiểm tra được ô ($error).';
  }

  @override
  String get techHomeAfterPhotoRequired =>
      'Vui lòng chụp ít nhất 1 ảnh sau khi sửa xong để nghiệm thu.';

  @override
  String techHomeBoxLabelLower(Object number) {
    return 'ô #$number';
  }

  @override
  String get techHomeLandingPadRestored => 'Bãi đáp đã hoạt động lại.';

  @override
  String get techHomeLockerRestored => 'Tủ đã hoạt động lại.';

  @override
  String techHomeBoxRestoredTestOpened(Object box) {
    return 'Ô đã hoạt động lại, đã gửi lệnh mở thử $box.';
  }

  @override
  String get techHomeBoxRestored => 'Ô tủ đã hoạt động lại.';

  @override
  String techHomeResolvedWithRestored(Object restored) {
    return 'Đã nghiệm thu và hoàn tất sự cố! $restored';
  }

  @override
  String techHomeResolvedTestOpenFailed(Object box, Object error) {
    return 'Đã nghiệm thu và hoàn tất sự cố, nhưng chưa mở thử được $box: $error';
  }

  @override
  String get techHomeRequiredBadge => 'Bắt buộc';

  @override
  String techHomeIncidentRpt(Object id) {
    return 'Sự cố RPT-$id';
  }

  @override
  String get techHomeResolveSheetTitle => 'Nghiệm thu hoàn tất sửa chữa';

  @override
  String techHomeResolveSheetSubtitleWithBox(
    Object locker,
    Object box,
    Object id,
    Object title,
  ) {
    return '$locker · Ô $box · RPT-$id · $title';
  }

  @override
  String get techHomeScenePhotosBeforeAfter =>
      'Hình ảnh hiện trường (Trước & Sau khi sửa)';

  @override
  String get techHomeBeforeRepair => 'Trước khi sửa';

  @override
  String techHomeExistingScenePhotos(int count) {
    return 'Đã có $count ảnh hiện trường / người báo đối chứng';
  }

  @override
  String get techHomeBeforeRepairOptional =>
      'Tuỳ chọn · lưu thành ảnh xác nhận hiện trường';

  @override
  String get techHomeScenePhotosBeforeRepair => 'Ảnh hiện trường trước khi sửa';

  @override
  String get techHomeTakeMorePhotos => 'Chụp thêm ảnh';

  @override
  String get techHomeDuringRepair => 'Trong quá trình sửa';

  @override
  String get techHomeDuringRepairHint =>
      'Ảnh thao tác kỹ thuật, thay thế linh kiện (tuỳ chọn)';

  @override
  String get techHomeTakeRepairPhotos => 'Chụp ảnh quá trình sửa';

  @override
  String get techHomeAfterRepair => 'Sau khi xong';

  @override
  String get techHomeAcceptancePhotoRequired =>
      'Ảnh nghiệm thu — cần ít nhất 1 ảnh';

  @override
  String get techHomeAcceptancePhotoOptional => 'Ảnh nghiệm thu (tuỳ chọn)';

  @override
  String get techHomeTechNotesTitle => 'Ghi chú kỹ thuật & linh kiện';

  @override
  String get techHomeTechNotesHint =>
      'Mô tả chi tiết linh kiện thay thế, các bước xử lý...';

  @override
  String get techHomeCheckingTestOpen =>
      'Đang kiểm tra ô trước khi cho phép mở thử...';

  @override
  String get techHomeTestOpenAfterRepair => 'Mở thử ô sau sửa';

  @override
  String techHomeTestOpenHintWithBox(Object box) {
    return 'Sau khi hoàn tất phiếu, gửi lệnh mở ô #$box để kiểm tra chốt khoá.';
  }

  @override
  String get techHomeTestOpenHint =>
      'Sau khi hoàn tất phiếu, gửi lệnh mở ô để kiểm tra chốt khoá.';

  @override
  String techHomeTestOpenNotSuggested(Object reason) {
    return 'Không đề nghị mở thử ô: $reason';
  }

  @override
  String get techHomeSavingAcceptance => 'Đang lưu nghiệm thu...';

  @override
  String get techHomeConfirmAndCompleteRepair => 'Xác nhận & Hoàn tất sửa chữa';

  @override
  String get techHomeScenePhotoRequired =>
      'Vui lòng chụp ít nhất 1 ảnh hiện trường.';

  @override
  String get techHomeSceneConfirmTitle => 'Xác nhận hiện trường';

  @override
  String get techHomeSceneConfirmHint =>
      'Chụp hiện trạng ô tủ ngay khi tới nơi (cửa, khoá, bo mạch...). Ảnh được lưu vào phiếu làm bằng chứng trước khi sửa.';

  @override
  String get techHomeSceneNoteHint => 'Ghi chú hiện trạng (tuỳ chọn)...';

  @override
  String get techHomeSaveScenePhotos => 'Lưu ảnh hiện trường';

  @override
  String get techHomeCustomerShort => 'Khách';

  @override
  String techHomeOpenBoxError(Object error) {
    return 'Lỗi mở ô: $error';
  }

  @override
  String get techHomeInvalidTicket => 'Phiếu không hợp lệ.';

  @override
  String get techHomeBoxIncidentSheetTitle => 'Kiểm tra ô & Xử lý sự cố';

  @override
  String get techHomeStep1PickBox => '1. Chọn ô gặp sự cố tại Kiosk:';

  @override
  String get techHomeKioskNoBoxes => 'Kiosk này chưa có danh sách ô.';

  @override
  String techHomeOrderLookupFailed(Object error) {
    return 'Không tra được đơn trong ô ($error). Kiểm tra thực tế (mở khẩn cấp) trước khi chọn phương án — tạm thời chỉ khoá ô.';
  }

  @override
  String get techHomeEmergencyOpenShort => 'Mở khẩn cấp';

  @override
  String get techHomeBoxHasCustomerItems => 'Ô ĐANG CHỨA ĐỒ CỦA KHÁCH!';

  @override
  String techHomeActiveOrderLine(Object code, Object customer) {
    return 'Đơn hàng: $code · Khách: $customer';
  }

  @override
  String get techHomeBoxNoActiveOrder => 'Ô KHÔNG CÓ ĐƠN HÀNG HOẠT ĐỘNG';

  @override
  String get techHomeBoxNoActiveOrderHint =>
      'Hệ thống không tìm thấy đơn hàng trong ô này. Có thể khách đã lấy đồ, kẹt cảm biến hoặc báo nhầm ô. KTV hãy mở khẩn cấp để kiểm tra thực tế.';

  @override
  String get techHomeBoxCurrentlyEmpty =>
      'Ô hiện tại đang trống (Không có đồ bên trong)';

  @override
  String get techHomeStep2PickGoodsOption =>
      '2. Chọn phương án xử lý hàng trong ô:';

  @override
  String get techHomeStep2PickOption => '2. Chọn phương án xử lý:';

  @override
  String get techHomeOptionRelocateTitle =>
      'Điều chuyển sang ô trống mới (Khuyến nghị)';

  @override
  String get techHomeOptionRelocateHint =>
      'Dọn đồ sang ô trống khác cùng Kiosk, cấp mã PIN mới cho khách & Khóa ô cũ.';

  @override
  String get techHomeNoFreeBoxes =>
      '⚠️ Trạm Kiosk không còn ô trống nào! Hãy chọn phương án giao trực tiếp hoặc niêm phong.';

  @override
  String get techHomePickTargetBox => 'Chọn ô trống đích';

  @override
  String techHomeTargetBoxOption(Object number, Object type) {
    return 'Ô #$number ($type)';
  }

  @override
  String get techHomeOptionHandoverTitle =>
      'Khách hàng có mặt - Bàn giao trực tiếp';

  @override
  String get techHomeOptionHandoverHint =>
      'Khách đang ở tại trạm nhận đồ trực tiếp, hoàn tất đơn & Khóa ô cũ.';

  @override
  String get techHomeHandoverCodeLabel =>
      'Mã PIN 6 số hoặc mã QR của đơn (bắt buộc)';

  @override
  String get techHomeHandoverCodeHint =>
      'Khách đọc/đưa mã lấy hàng để xác nhận bàn giao';

  @override
  String get techHomeOptionHubTitle =>
      'Kiosk hết ô trống - Niêm phong đưa về Hub';

  @override
  String get techHomeOptionHubHint =>
      'Đóng túi niêm phong an toàn, quét mã Seal đưa về Hub lưu trữ & Khóa ô cũ.';

  @override
  String get techHomeSealCodeLabel => 'Mã Seal niêm phong (bắt buộc)';

  @override
  String get techHomeSealCodeHint => 'Nhập đúng mã in trên túi niêm phong';

  @override
  String get techHomeOptionQuickFixKeepTitle =>
      'Kiểm tra & Xử lý tại chỗ (Không chuyển dọn đồ)';

  @override
  String get techHomeOptionQuickFixKeepHint =>
      'Kiểm tra cảm biến, đóng chặt cửa hoặc hỗ trợ khách tại chỗ mà không cần dọn đồ.';

  @override
  String get techHomeOptionQuickFixTitle =>
      'Kiểm tra & Xử lý tại chỗ (Khuyến nghị)';

  @override
  String get techHomeOptionQuickFixHint =>
      'Kiểm tra vật lý (cảm biến, chốt khóa, vệ sinh). Nếu user báo nhầm hoặc lỗi nhẹ đã khắc phục xong, không cần khóa ô.';

  @override
  String get techHomeOptionLockFaultTitle =>
      'Xác nhận lỗi phần cứng & Khóa ô bảo trì (FAULT)';

  @override
  String get techHomeOptionLockFaultHint =>
      'Cần linh kiện thay thế hoặc bảo dưỡng sâu. Tạm ngưng hoạt động ô tủ để kỹ thuật viên sửa chữa.';

  @override
  String get techHomeLockForMaintenance =>
      'Khóa ô tủ để bảo trì (Trạng thái: FAULT)';

  @override
  String get techHomeKeepActiveWithGoods =>
      'Giữ ô tủ hoạt động (Đang giữ hàng của khách)';

  @override
  String get techHomeKeepActiveNormal =>
      'Giữ ô tủ hoạt động bình thường (AVAILABLE)';

  @override
  String get techHomeLockOnlyHint =>
      'Kịch bản Khóa ô bảo trì (FAULT) luôn khóa ô để bảo dưỡng. Nếu không cần khóa ô, vui lòng chọn kịch bản \"Kiểm tra & Xử lý tại chỗ\".';

  @override
  String get techHomeLockedHint =>
      'Ô tủ sẽ bị tạm ngưng và không nhận đơn mới cho đến khi hoàn tất sửa chữa.';

  @override
  String get techHomeNotLockedWithGoodsHint =>
      'Không khóa ô tủ. Đồ của khách vẫn được giữ an toàn trong ô và không bị trả về ô trống.';

  @override
  String get techHomeNotLockedHint =>
      'Không khóa ô tủ. Phù hợp khi khách hàng báo nhầm hoặc sự cố đã được xử lý ngay tại chỗ.';

  @override
  String get techHomeStep3ReasonNotes => '3. Lý do & Ghi chú xử lý:';

  @override
  String get techHomeSystemRecordedIncident =>
      'Sự cố ô tủ ghi nhận từ hệ thống';

  @override
  String get techHomeFailedInspectionContent =>
      'Nội dung kiểm tra định kỳ không đạt:';

  @override
  String get techHomeCustomerReportedReason => 'Lý do khách hàng phản ánh:';

  @override
  String get techHomeTechFieldNotesLabel =>
      'Ghi chú hiện trường của KTV (Ghi riêng):';

  @override
  String get techHomeTechFieldNotesHint =>
      'Nhập hiện trạng kiểm tra, nhận định của KTV...';

  @override
  String get techHomeStep4ScenePhotos =>
      '4. Ảnh hiện trường / Đối chứng (KTV kiểm tra):';

  @override
  String techHomeExistingScenePhotosColon(int count) {
    return 'Đã có $count ảnh hiện trường / người báo đối chứng:';
  }

  @override
  String get techHomeComparisonScenePhotos => 'Ảnh hiện trường đối chứng';

  @override
  String get techHomeTakeMoreScenePhotos =>
      'Chụp thêm ảnh hiện trường mới (tuỳ chọn):';

  @override
  String get techHomeStep5RepairPhotos => '5. Ảnh trong quá trình sửa:';

  @override
  String get techHomeStep5RepairPhotosHint =>
      'Chụp ảnh tháo lắp linh kiện, thao tác kỹ thuật, kiểm tra cảm biến hoặc xử lý đồ:';

  @override
  String techHomeExistingRepairPhotos(int count) {
    return 'Đã có $count ảnh trong quá trình sửa:';
  }

  @override
  String get techHomeTakeMoreRepairPhotos =>
      'Chụp thêm ảnh quá trình sửa mới (tuỳ chọn):';

  @override
  String get techHomeUpdating => 'Đang cập nhật...';

  @override
  String get techHomeConfirmAndUpdate => 'Xác nhận & Cập nhật hệ thống';

  @override
  String get techHomeCellTypeStandard => 'Chuẩn';

  @override
  String get techHomeForceOpenReasonForgotPin =>
      'Khách quên mã PIN / không liên lạc được';

  @override
  String get techHomeForceOpenReasonJammed =>
      'Cửa ô bị kẹt cơ học / lỗi chốt từ';

  @override
  String get techHomeForceOpenReasonTicketCheck =>
      'Kiểm tra ô khi xử lý phiếu sự cố';

  @override
  String get techHomeForceOpenReasonManagement =>
      'Kiểm tra theo yêu cầu ban quản lý';

  @override
  String get techHomeForceOpenReasonEmergency =>
      'Sự cố khẩn cấp / nghi rò rỉ hoặc dị vật';

  @override
  String get techHomeForceOpenReasonOther => 'Lý do khác…';

  @override
  String techHomeForceOpenSent(Object box) {
    return 'Đã gửi lệnh mở khẩn cấp $box.';
  }

  @override
  String techHomeForceOpenConfirmed(Object box) {
    return 'Tủ xác nhận đã mở $box.';
  }

  @override
  String techHomeForceOpenTitle(Object box) {
    return 'Mở khẩn cấp $box';
  }

  @override
  String techHomeForceOpenHintWithTicket(Object id) {
    return 'Ô được mở bằng lệnh Master và ghi vào nhật ký truy cập. Lý do, ghi chú và ảnh được lưu vào nhật ký phiếu RPT-$id.';
  }

  @override
  String get techHomeForceOpenHint =>
      'Ô được mở bằng lệnh Master và ghi vào nhật ký truy cập kèm lý do.';

  @override
  String get techHomeForceOpenReasonLabel => 'Lý do can thiệp (bắt buộc):';

  @override
  String get techHomeEnterReason => 'Nhập lý do';

  @override
  String get techHomeNoteOptional => 'Ghi chú (tuỳ chọn)';

  @override
  String get techHomeForceOpenReasonRequired =>
      'Vui lòng nhập lý do mở khẩn cấp.';

  @override
  String get techHomeConfirmOpen => 'Xác nhận mở';

  @override
  String get techHomeSlaReasonWaitingParts => 'Chờ linh kiện thay thế';

  @override
  String get techHomeSlaReasonDeepCircuitCheck => 'Cần kiểm tra sâu mạch điện';

  @override
  String get techHomeSlaReasonHardToReach => 'Tủ khó tiếp cận';

  @override
  String get techHomeSlaReasonBuildingOps => 'Phối hợp bên vận hành tòa nhà';

  @override
  String get techHomeSlaReasonRequired => 'Vui lòng nhập lý do gia hạn SLA.';

  @override
  String techHomeMaxExtensionsPerTicket(Object count) {
    return 'Tối đa $count lần mỗi phiếu';
  }

  @override
  String techHomeExtendSlaTitle(Object id) {
    return 'Gia hạn SLA phiếu RPT-$id';
  }

  @override
  String get techHomeCurrentDueLabel => 'Hạn hiện tại:';

  @override
  String get techHomeNewDueLabel => 'Hạn mới (dự kiến):';

  @override
  String get techHomePickExtensionHours => 'Chọn thời gian gia hạn:';

  @override
  String techHomePickExtensionHoursCapped(Object hours) {
    return 'Chọn thời gian gia hạn (tối đa $hours giờ/lần):';
  }

  @override
  String techHomePlusHours(Object hours) {
    return '+$hours giờ';
  }

  @override
  String get techHomeExtensionReasonLabel => 'Lý do gia hạn (bắt buộc):';

  @override
  String get techHomeExtensionReasonHint =>
      'Nhập lý do cần thêm thời gian xử lý...';

  @override
  String get techHomeConfirmExtendSla => 'Xác nhận gia hạn SLA';

  @override
  String get techHomeDeletePhotoTitle => 'Xoá ảnh này?';

  @override
  String techHomeDeletePhotoBody(Object stage, Object id) {
    return '$stage sẽ bị gỡ khỏi phiếu RPT-$id.';
  }

  @override
  String get techHomePhotoDeleted => 'Đã xoá ảnh khỏi phiếu.';

  @override
  String techHomeTicketPhotosLoadFailed(Object error) {
    return 'Không tải được ảnh của phiếu: $error';
  }

  @override
  String techHomeYourAttachedPhotos(Object count) {
    return 'Ảnh bạn đã gắn ($count) — chạm ✕ để xoá ảnh tải nhầm';
  }

  @override
  String get techHomeStageOnSite => 'Hiện trường';

  @override
  String get techHomeStageRepairing => 'Đang sửa';

  @override
  String techHomeSlaRemainingExtended(Object time, Object hours) {
    return 'Còn $time (+${hours}h)';
  }

  @override
  String techHomeSlaRemaining(Object time) {
    return 'Còn $time';
  }

  @override
  String techHomeSlaOverdueByExtended(Object time, Object hours) {
    return 'Quá hạn $time (+${hours}h)';
  }

  @override
  String techHomeSlaOverdueBy(Object time) {
    return 'Quá hạn $time';
  }

  @override
  String techHomeTechName(Object name) {
    return 'KTV $name';
  }

  @override
  String get techUiRestartUnconfirmed =>
      'Đã gửi lệnh khởi động lại nhưng máy chủ chưa trả kết quả xác nhận — kiểm tra trạng thái thiết bị sau ít phút.';

  @override
  String get techUiRestartAccepted =>
      'Bộ điều khiển tủ đã nhận lệnh và đang khởi động lại.';

  @override
  String get techUiRestartTimeout =>
      'Tủ không phản hồi lệnh khởi động lại — kiểm tra kết nối của tủ.';

  @override
  String get techUiRestartFailed =>
      'Khởi động lại thất bại — vui lòng thử lại.';

  @override
  String get techUiAdminAccountTitle => 'Tài khoản quản trị';

  @override
  String get techUiAdminWebOnly =>
      'Trang quản trị (dashboard, thống kê, quản lý người dùng, đơn hàng, khuyến mãi...) chỉ có trên bản web.\nVui lòng đăng nhập bằng trình duyệt để tiếp tục.';

  @override
  String get techUiRoleDrone => 'KTV drone';

  @override
  String get techUiRoleLocker => 'KTV tủ';

  @override
  String techUiSlaExtensionUsage(int used, int max) {
    return 'Đã gia hạn $used/$max';
  }

  @override
  String techUiSlaExtensionLimit(int used, int max) {
    return 'Hết lượt gia hạn ($used/$max)';
  }

  @override
  String get techUiExtendSla => 'Gia hạn SLA';

  @override
  String get techUiSlaSuspended => 'Đình chỉ';

  @override
  String get techUiSlaRestricted => 'Hạn chế nhận việc';

  @override
  String get techUiSlaWarning => 'Cảnh báo';

  @override
  String get techUiSlaNormal => 'Bình thường';

  @override
  String get techUiSlaNotLoaded => 'Chưa tải được';

  @override
  String techUiRatingSummary(String average, int count) {
    return '$average/5 ($count lượt)';
  }

  @override
  String get techUiSelectIncidentBox => 'Vui lòng chọn ô sự cố.';

  @override
  String get techUiSelectTargetBox =>
      'Vui lòng chọn ô trống để chuyển hàng sang.';

  @override
  String get techUiEnterHandoverCode =>
      'Nhập mã PIN 6 số hoặc mã QR của đơn để xác nhận bàn giao.';

  @override
  String get techUiPinSixDigits => 'Mã PIN lấy hàng gồm đúng 6 chữ số.';

  @override
  String get techUiEnterSealCode => 'Nhập mã Seal in trên túi niêm phong.';

  @override
  String get techUiLocationDeniedForever =>
      'Quyền vị trí bị từ chối vĩnh viễn. Vui lòng mở Cài đặt để bật vị trí.';

  @override
  String get techUiLocationAccessTitle => 'Quyền truy cập vị trí';

  @override
  String get techUiForTechnicianAccounts => 'Dành cho tài khoản Kỹ thuật viên';

  @override
  String get techUiLocationRationale =>
      'Để hệ thống điều phối chính xác sự cố trạm tủ và nhiệm vụ drone gần bạn nhất, ứng dụng cần truy cập vị trí thiết bị khi bạn đang trong ca làm việc.';

  @override
  String get techUiBenefitDispatchTitle => 'Điều phối & Phân công theo vị trí';

  @override
  String get techUiBenefitDispatchBody =>
      'Tự động gán phiếu xử lý, kiểm tra định kỳ và cứu hộ drone tại các tủ quanh bạn.';

  @override
  String get techUiBenefitAutoOffTitle => 'Tự động tắt khi hết ca trực';

  @override
  String get techUiBenefitAutoOffBody =>
      'Vị trí chỉ được truy cập khi bạn bật Vào ca. Khi Hết ca, định vị tự động tắt hoàn toàn để bảo vệ quyền riêng tư.';

  @override
  String get techUiBenefitBatteryTitle => 'Tối ưu pin & dữ liệu nền';

  @override
  String get techUiBenefitBatteryBody =>
      'Tần suất định vị tự động tối ưu theo khoảng cách di chuyển để không hao pin điện thoại.';

  @override
  String get techUiAllowLocation => 'Cho phép truy cập vị trí';

  @override
  String get techUiGpsServiceOff =>
      'Dịch vụ định vị GPS đang tắt. Vui lòng bật GPS trên thiết bị.';

  @override
  String get techUiLocationBlockedForever =>
      'Quyền truy cập vị trí bị chặn vĩnh viễn. Vui lòng mở Cài đặt để cấp quyền.';

  @override
  String get techUiGpsUpdated => 'Đã cập nhật vị trí GPS thành công.';

  @override
  String techUiLocationUpdateFailed(String error) {
    return 'Không thể cập nhật vị trí: $error';
  }

  @override
  String get techUiEndShiftQuestion => 'Kết thúc ca trực?';

  @override
  String get techUiEndShiftBody =>
      'Hệ thống sẽ ngừng điều phối sự cố mới và ngắt hoàn toàn quyền truy cập vị trí của bạn.';

  @override
  String get techUiEndShift => 'Kết thúc ca';

  @override
  String get techUiShiftStarted =>
      'Đã vào ca làm việc và kích hoạt định vị GPS.';

  @override
  String get techUiShiftEnded => 'Đã kết thúc ca và tắt định vị GPS.';

  @override
  String techUiShiftUpdateFailed(String error) {
    return 'Lỗi cập nhật ca trực: $error';
  }

  @override
  String get techUiNoLocationYet => 'Chưa có vị trí';

  @override
  String get techUiOnShift => 'Đang trong ca làm việc';

  @override
  String get techUiOffShift => 'Ngoài ca làm việc';

  @override
  String get techUiOnShiftLocationNote =>
      'Vị trí được truy cập để điều phối công việc gần bạn nhất';

  @override
  String get techUiOffShiftLocationNote =>
      'Định vị GPS đã ngắt kết nối hoàn toàn';

  @override
  String get techUiDeviceGpsInfo => 'THÔNG TIN GPS THIẾT BỊ';

  @override
  String get techUiGpsCoordinates => 'Tọa độ GPS';

  @override
  String get techUiGpsAccuracy => 'Độ chính xác GPS';

  @override
  String techUiAccuracyMeters(String meters) {
    return '±$meters mét';
  }

  @override
  String get techUiNotYet => 'Chưa có';

  @override
  String get techUiOpenGoogleMaps => 'Mở Google Maps';

  @override
  String get techUiUpdateGps => 'Cập nhật GPS';

  @override
  String get techUiNoGpsYet =>
      'Chưa ghi nhận tọa độ GPS. Hãy bật ca trực hoặc nhấn Cập nhật vị trí.';

  @override
  String get techUiGetCurrentLocation => 'Lấy vị trí hiện tại';

  @override
  String get techUiPrivacyCommitment =>
      'Cam kết quyền riêng tư: Hệ thống chỉ truy cập vị trí khi bạn trong ca. Khi hết ca, định vị tự động tắt hoàn toàn.';

  @override
  String get techUiLoadingShift => 'Đang tải trạng thái ca trực...';

  @override
  String get techUiOnShiftBadge => 'ĐANG TRONG CA';

  @override
  String get techUiOffShiftBadge => 'NGOÀI CA';

  @override
  String techUiGpsActive(String accuracy, String time) {
    return 'GPS: Hoạt động$accuracy · $time';
  }

  @override
  String get techUiGpsSearching => 'Đang dò tìm tín hiệu GPS...';

  @override
  String get techUiGpsOffHint => 'GPS đã tắt · Vào ca để kích hoạt vị trí';

  @override
  String get techUiRefreshGps => 'Cập nhật lại GPS';

  @override
  String get techUiEndShiftShort => 'Hết ca';

  @override
  String get techUiStartShift => 'Vào ca';

  @override
  String get techUiNotApplicable => 'Không áp dụng';

  @override
  String get techUiInvalidScheduleId => 'Mã lịch kiểm tra không hợp lệ.';

  @override
  String get techUiDroneRoutineMaintenance => 'Bảo trì định kỳ Drone';

  @override
  String get techUiKioskRoutineInspection => 'Kiểm tra định kỳ Kiosk';

  @override
  String get techUiKioskLocker => 'Tủ Kiosk';

  @override
  String get techUiConfirmRoutineInspection => 'Xác nhận kiểm tra định kỳ';

  @override
  String techUiCycleDays(int days) {
    return 'Chu kỳ: $days ngày';
  }

  @override
  String techUiChecklistProgress(int answered, int total) {
    return 'Hạng mục kiểm tra ($answered/$total)';
  }

  @override
  String get techUiNoChecklistPickOverall =>
      'Lịch này chưa có checklist — chọn kết quả chung:';

  @override
  String get techUiInspectionNoteLabel =>
      'Ghi chú biên bản kiểm tra (tuỳ chọn)';

  @override
  String get techUiInspectionNoteHintDrone =>
      'Tình trạng pin, động cơ, cánh quạt, cảm biến hoặc linh kiện đã thay...';

  @override
  String get techUiInspectionNoteHintKiosk =>
      'Tình trạng chung, vệ sinh ô tủ, linh kiện đã thay nếu có...';

  @override
  String get techUiFieldPhotosOptional =>
      'Ảnh minh chứng hiện trường (tuỳ chọn):';

  @override
  String get techUiFieldPhotosHintDrone =>
      'Chụp ảnh Drone, pin hoặc linh kiện vừa kiểm tra để lưu hồ sơ đối soát.';

  @override
  String get techUiFieldPhotosHintKiosk =>
      'Chụp ảnh toàn cảnh tủ, ổ khóa hoặc linh kiện vừa kiểm tra để lưu hồ sơ đối soát.';

  @override
  String get techUiUpdating => 'Đang cập nhật...';

  @override
  String get techUiConfirmComplete => 'Xác nhận hoàn thành';

  @override
  String get techUiFaultDescOptional => 'Mô tả lỗi phát hiện (tuỳ chọn)';

  @override
  String get techUiNoteOptional => 'Ghi chú (tuỳ chọn)';

  @override
  String techUiItemsRemaining(int remaining, int total) {
    return 'Còn $remaining/$total hạng mục chưa đánh giá.';
  }

  @override
  String get techUiPickPassOrFail =>
      'Chọn Đạt hoặc Không đạt cho lần kiểm tra này.';

  @override
  String get techUiResultFailWithTicket =>
      'Kết quả: KHÔNG ĐẠT — hệ thống sẽ mở phiếu sự cố giao cho bạn. Hạn kiểm tra kế tiếp chỉ dời khi phiếu được hoàn tất.';

  @override
  String get techUiResultFail => 'Kết quả: KHÔNG ĐẠT.';

  @override
  String techUiResultPass(int days) {
    return 'Kết quả: ĐẠT — hạn kiểm tra kế tiếp dời sang $days ngày sau.';
  }

  @override
  String get techUiFaultyBoxOptional => 'Ô bị hỏng (tuỳ chọn)';

  @override
  String get techUiFaultyBoxHint =>
      'Chọn ô ⇒ ô chuyển Hỏng và phiếu gắn với ô đó; không chọn ⇒ phiếu cấp tủ.';

  @override
  String get techUiNoBoxLockerLevel => 'Không gắn ô — sự cố cấp tủ';

  @override
  String techUiBoxWithStatus(String number, String status) {
    return 'Ô #$number · $status';
  }

  @override
  String get techUiIncidentDescOptional => 'Mô tả sự cố (tuỳ chọn)';

  @override
  String get techUiIncidentDescHint =>
      'Để trống ⇒ phiếu liệt kê các mục không đạt';

  @override
  String techUiOverdueDays(int days) {
    return 'Quá hạn $days ngày';
  }

  @override
  String get techUiDueToday => 'Đến hạn hôm nay';

  @override
  String techUiDueInDays(int days) {
    return 'Còn $days ngày nữa đến hạn';
  }

  @override
  String techUiPrevFailedFinishTicket(Object id) {
    return 'Lần trước không đạt — hoàn tất phiếu RPT-$id trước khi kiểm tra lại.';
  }

  @override
  String get techUiScheduleOtherTech => 'Lịch do KTV khác phụ trách.';

  @override
  String get techUiPriorityUrgent => 'Khẩn cấp';

  @override
  String get techUiPriorityHigh => 'Cao';

  @override
  String get techUiPriorityLow => 'Thấp';

  @override
  String get techUiPriorityNormalDrone => 'Bình thường (Drone tiêu chuẩn)';

  @override
  String get techUiPriorityNormalStation => 'Bình thường (Trạm tiêu chuẩn)';

  @override
  String get techUiRoutineSchedule => 'Lịch kiểm tra định kỳ';

  @override
  String get techUiDroneRoutine => 'Định kỳ Drone';

  @override
  String get techUiKioskRoutine => 'Định kỳ Kiosk';

  @override
  String get techUiSchedulePlanRecord =>
      'Hồ sơ chi tiết kế hoạch kiểm tra bảo trì định kỳ';

  @override
  String get techUiDroneMaintenancePlan => 'Kế hoạch bảo trì định kỳ Drone';

  @override
  String get techUiKioskInspectionPlan =>
      'Kế hoạch kiểm tra bảo trì định kỳ Kiosk';

  @override
  String get techUiDronePlanNote =>
      'Đây là lịch bảo trì Drone theo chu kỳ do Quản trị viên thiết lập; kết quả checklist được lưu vào hồ sơ vận hành.';

  @override
  String get techUiKioskPlanNote =>
      'Đây là lịch kiểm tra bảo dưỡng định kỳ tự động theo chu kỳ cho trạm Kiosk do Quản trị viên thiết lập (không phải là phiếu báo hỏng sự cố).';

  @override
  String get techUiInspectionDue => 'Đến hạn kiểm tra';

  @override
  String techUiPriorityLabel(String priority) {
    return 'Ưu tiên: $priority';
  }

  @override
  String techUiCycleEveryDays(String days) {
    return 'Chu kỳ: Mỗi $days ngày';
  }

  @override
  String techUiShiftSlot(String slot) {
    return 'Ca: $slot';
  }

  @override
  String get techUiNoTechAssigned => 'Chưa giao KTV';

  @override
  String get techUiTechInChargeYou => 'KTV phụ trách: Bạn';

  @override
  String techUiPlacementInBuilding(String note) {
    return 'Vị trí đặt trong toà nhà: $note';
  }

  @override
  String get techUiDirectionsDroneStation => 'Chỉ đường tới trạm Drone';

  @override
  String get techUiPlanAndDeadline => 'Kế hoạch & Thời hạn kiểm tra:';

  @override
  String get techUiDueDateLabel => 'Hạn kiểm tra tới (Ngày hẹn):';

  @override
  String get techUiStartTimeLabel => 'Giờ hẹn bắt đầu cụ thể:';

  @override
  String get techUiTimeSlotLabel => 'Khung giờ / Ca kiểm tra:';

  @override
  String get techUiFlexibleSlot => 'Khung giờ linh hoạt';

  @override
  String get techUiRepeatCycleLabel => 'Chu kỳ lặp lại:';

  @override
  String techUiEveryDaysOnce(String days) {
    return 'Mỗi $days ngày thực hiện 1 lần';
  }

  @override
  String get techUiPriorityLevelLabel => 'Mức độ ưu tiên:';

  @override
  String get techUiTechnicianLabel => 'Kỹ thuật viên phụ trách:';

  @override
  String get techUiUnassignedWaiting => 'Chưa phân công (Chờ nhận)';

  @override
  String get techUiYouAssigned => 'Bạn (Được giao cho tôi)';

  @override
  String get techUiLastInspectionLabel => 'Lần kiểm tra trước:';

  @override
  String get techUiNoInspectionHistory => 'Chưa có lịch sử kiểm tra';

  @override
  String techUiChecklistCriteria(int count) {
    return 'Bộ tiêu chí kiểm định ($count mục KTV cần thực hiện):';
  }

  @override
  String get techUiDroneFullCheck =>
      'Kiểm tra toàn diện tình trạng vận hành của Drone.';

  @override
  String get techUiKioskFullCheck =>
      'Kiểm tra toàn diện hoạt động của trạm tủ Kiosk.';

  @override
  String get techUiSopGuide =>
      'Hướng dẫn nghiệp vụ (Ghi chú SOP từ Quản trị viên):';

  @override
  String get techUiPrevResultLabel => 'Kết quả kiểm tra lần trước:';

  @override
  String techUiInspectionLogsFailed(String error) {
    return 'Không tải được nhật ký kiểm tra: $error';
  }

  @override
  String get techUiCheckedNoOverall =>
      'Đã kiểm tra — không có kết quả chung trong nhật ký';

  @override
  String get techUiPassedAllCriteria => 'ĐẠT — Toàn bộ tiêu chí đạt yêu cầu';

  @override
  String get techUiFailedHasIssues =>
      'KHÔNG ĐẠT — Có hạng mục bị lỗi cần xử lý';

  @override
  String techUiLogTime(String time) {
    return 'Thời gian: $time';
  }

  @override
  String techUiLogTimeWithTech(String time, String name) {
    return 'Thời gian: $time · KTV: $name';
  }

  @override
  String techUiItemDetails(int count) {
    return 'Chi tiết đánh giá từng hạng mục ($count mục):';
  }

  @override
  String techUiTechNote(String note) {
    return 'Ghi chú KTV: $note';
  }

  @override
  String get techUiNoItemResultsInLog =>
      'Nhật ký lần trước không lưu kết quả từng hạng mục — chỉ có kết quả chung ở trên.';

  @override
  String techUiTechNoteQuoted(String note) {
    return 'Ghi chú KTV: \"$note\"';
  }

  @override
  String techUiFieldPhotosCount(int count) {
    return 'Ảnh hiện trường KTV đã chụp ($count ảnh):';
  }

  @override
  String get techUiPrevInspectionPhotos => 'Ảnh kiểm tra định kỳ lần trước';

  @override
  String techUiRelatedTicket(Object id) {
    return 'Phiếu sự cố kỹ thuật liên quan: RPT-$id';
  }

  @override
  String get techUiFailedTicketOpenedNote =>
      'Do lần kiểm tra trước không đạt, hệ thống đã mở phiếu sự cố kỹ thuật. Bạn cần xử lý và nghiệm thu hoàn tất phiếu này để lịch định kỳ mở lại cho lần kiểm tra tiếp theo.';

  @override
  String techUiOpenTicketToHandle(Object id) {
    return 'Mở phiếu sự cố RPT-$id để xử lý';
  }

  @override
  String get techUiNoPrevInspection =>
      'Chưa có dữ liệu kiểm tra lần trước (Lịch kiểm tra mới được thiết lập).';

  @override
  String techUiHandleTicket(Object id) {
    return 'Xử lý phiếu sự cố RPT-$id';
  }

  @override
  String get techUiScheduleOtherTechShort => 'Lịch do KTV khác phụ trách';

  @override
  String get techUiStartInspectionDue => 'Bắt đầu kiểm tra ngay (Đến hạn)';

  @override
  String get techUiInspectNow => 'Kiểm tra ngay';

  @override
  String get techUiIncidentReport => 'Báo cáo sự cố';

  @override
  String get techUiSavingChanges => 'Đang lưu thay đổi...';

  @override
  String get techUiProfileUpdated => 'Cập nhật thông tin hồ sơ thành công!';

  @override
  String get techUiAvatar => 'Ảnh đại diện';

  @override
  String get techUiTakeNewPhoto => 'Chụp ảnh mới';

  @override
  String get techUiChooseFromGallery => 'Chọn từ bộ sưu tập';

  @override
  String get techUiDeleteAvatar => 'Xóa ảnh đại diện';

  @override
  String get techUiUploadingAvatar => 'Đang tải lên ảnh đại diện...';

  @override
  String get techUiAccountIdUnknown => 'Không xác định được ID tài khoản';

  @override
  String techUiPhotoUploadFailed(String error) {
    return 'Tải ảnh thất bại: $error';
  }

  @override
  String get techUiAvatarUpdated => 'Đã cập nhật ảnh đại diện thành công';

  @override
  String techUiPhotoUploadError(String error) {
    return 'Lỗi tải ảnh: $error';
  }

  @override
  String get techUiDeleteAvatarQuestion => 'Xóa ảnh đại diện?';

  @override
  String get techUiDeleteAvatarBody =>
      'Bạn có chắc chắn muốn gỡ ảnh đại diện hiện tại?';

  @override
  String get techUiDelete => 'Xóa';

  @override
  String get techUiDeletingPhoto => 'Đang xóa ảnh...';

  @override
  String techUiPhotoDeleteFailed(String error) {
    return 'Xóa ảnh thất bại: $error';
  }

  @override
  String get techUiAvatarDeleted => 'Đã xóa ảnh đại diện';

  @override
  String techUiPhotoDeleteError(String error) {
    return 'Lỗi xóa ảnh: $error';
  }

  @override
  String get techUiLogoutShift => 'Đăng xuất ca trực';

  @override
  String techUiLogoutConfirm(String role) {
    return 'Bạn có chắc chắn muốn kết thúc ca trực và đăng xuất khỏi tài khoản $role không?';
  }

  @override
  String get techUiLockerTechnician => 'Kỹ thuật viên tủ';

  @override
  String get techUiSaving => 'Đang lưu...';

  @override
  String get techUiSaveProfileChanges => 'Lưu thay đổi thông tin';

  @override
  String get techUiLogoutAccount => 'Đăng xuất tài khoản';

  @override
  String get techUiTechnicianProfile => 'Hồ sơ kỹ thuật viên';

  @override
  String get techUiRoleBadgeDrone => 'DRONE · Kỹ thuật viên drone';

  @override
  String get techUiRoleBadgeLocker => 'KIOSK · Kỹ thuật viên tủ';

  @override
  String techUiStatsLoadFailed(String error) {
    return 'Không tải được đầy đủ chỉ số: $error';
  }

  @override
  String get techUiShiftMetrics => 'Chỉ số vận hành ca trực';

  @override
  String get techUiMetricReceived => 'Phiếu đã nhận';

  @override
  String get techUiMetricInProgress => 'Đang làm';

  @override
  String get techUiQualityRating => 'Đánh giá chất lượng: ';

  @override
  String get techUiNoRatingYet => 'Chưa có đánh giá';

  @override
  String get techUiEditPersonalInfo => 'Chỉnh sửa thông tin cá nhân';

  @override
  String get techUiFullNameLabel => 'Họ và tên kỹ thuật viên *';

  @override
  String get techUiFullNameHint => 'Nhập họ và tên đầy đủ';

  @override
  String get techUiFullNameMin => 'Họ và tên phải có ít nhất 2 ký tự';

  @override
  String get techUiContactPhone => 'Số điện thoại liên hệ';

  @override
  String get techUiPhoneHint => 'Ví dụ: 0912345678';

  @override
  String get techUiPhoneMin => 'Số điện thoại phải có ít nhất 9 chữ số';

  @override
  String get techUiAccountEmailFixed => 'Email tài khoản (Cố định)';

  @override
  String get techUiIdentity => 'Định danh';

  @override
  String get techUiRoleDroneLong => 'Kỹ thuật viên drone (đội bay)';

  @override
  String get techUiRoleLockerLong => 'Kỹ thuật viên tủ (ô tủ & phần cứng)';

  @override
  String get techUiRoleDroneDesc =>
      'Điều phối, bảo trì drone và xử lý phiếu sự cố drone.';

  @override
  String get techUiRoleLockerDesc =>
      'Bảo trì ô tủ, thiết bị IoT và xử lý phiếu sự cố tại tủ.';

  @override
  String techRecLoadError(Object error) {
    return 'Không tải được nhiệm vụ thu hồi: $error';
  }

  @override
  String get techRecEmptyTitle => 'Chưa có nhiệm vụ thu hồi kiện';

  @override
  String get techRecEmptyHint =>
      'Nhiệm vụ được phân công sẽ xuất hiện tại đây.';

  @override
  String get techRecBanner =>
      'Thu hồi kiện theo vị trí rơi đã xác minh. Phải chụp ảnh thật, ghi GPS và tình trạng kiện trước khi gửi Admin duyệt.';

  @override
  String get techRecUrgentTag => 'Nhiệm vụ tìm kiếm khẩn cấp · Drone rơi';

  @override
  String techRecIncidentHash(Object id) {
    return 'Sự cố #$id';
  }

  @override
  String get techRecNoGps => 'Không có GPS · kiểm tra bằng chứng trước khi đi';

  @override
  String get techRecSituation => 'Tình huống';

  @override
  String get techRecDataAccuracy => 'Độ chính xác dữ liệu';

  @override
  String techRecAccuracyLine(Object source, Object accuracy, Object telemetry) {
    return 'Nguồn vị trí: $source · sai số $accuracy · telemetry $telemetry';
  }

  @override
  String get techRecUnknown => 'không rõ';

  @override
  String get techRecTelemetryStale => 'đã cũ';

  @override
  String get techRecTelemetryLive => 'trực tuyến';

  @override
  String get techRecGpsSourceDrone => 'GPS drone';

  @override
  String get techRecGpsSourceFlightPath => 'ước theo tuyến bay';

  @override
  String get techRecGpsSourceNone => 'chưa có';

  @override
  String get techRecDirectionsToDrop => 'Mở chỉ đường tới vị trí rơi';

  @override
  String get techRecEvidence => 'Bằng chứng hiện có';

  @override
  String get techRecImageLoadError => 'Lỗi tải ảnh';

  @override
  String get techRecAccept => 'Nhận nhiệm vụ';

  @override
  String get techRecStartSearch => 'Bắt đầu tìm kiếm';

  @override
  String get techRecRecordResult => 'Ghi nhận kết quả tìm kiếm';

  @override
  String get techRecConfirmHubHandover => 'Xác nhận bàn giao kiện về Hub / kho';

  @override
  String techRecConfirmStationHandover(Object station) {
    return 'Xác nhận đã giao kiện tại trạm $station';
  }

  @override
  String get techRecSubmittedTitle => 'Kết quả đã gửi';

  @override
  String get techRecSubmittedBody =>
      'Admin sẽ xác minh bằng chứng và quyết định bước tiếp theo.';

  @override
  String get techRecClosedTitle => 'Đã hoàn tất thu hồi';

  @override
  String get techRecClosedHubBody =>
      'Admin đã xác minh và kiện đã về Hub / kho. Bạn không cần làm gì thêm.';

  @override
  String techRecClosedStationBody(Object station) {
    return 'Kiện đã giao tại trạm $station. Bạn không cần làm gì thêm.';
  }

  @override
  String get techRecNoGpsTitle => 'Không lấy được vị trí GPS';

  @override
  String get techRecNoGpsBody =>
      'Kết quả thu hồi cần toạ độ nơi chụp để Admin đối chiếu. Hãy bật định vị và cấp quyền vị trí rồi thử lại. Chỉ gửi không kèm GPS khi thật sự không thể định vị — Admin sẽ thấy bằng chứng thiếu toạ độ.';

  @override
  String get techRecRetryLater => 'Thử lại sau';

  @override
  String get techRecSendWithoutGps => 'Vẫn gửi không kèm GPS';

  @override
  String techRecStationTitle(Object station) {
    return 'Trạm $station';
  }

  @override
  String get techRecHandoverHubTitle => 'Bàn giao kiện về Hub / kho?';

  @override
  String techRecHandoverStationTitle(Object station) {
    return 'Đã giao kiện tại trạm $station?';
  }

  @override
  String get techRecHandoverHubBody =>
      'Chỉ xác nhận khi kiện đã nằm ở Hub / kho và đã có người nhận bàn giao. Sau bước này kiện thuộc trách nhiệm của Hub.';

  @override
  String techRecHandoverStationBody(Object station) {
    return 'Chỉ xác nhận khi kiện đã nằm ở trạm $station và đã có người nhận bàn giao. Sau bước này kiện chờ drone bay giao lại cho khách.';
  }

  @override
  String get techRecHandedOver => 'Đã bàn giao';

  @override
  String get techRecHubHandoverDone => 'Đã xác nhận kiện về Hub / kho.';

  @override
  String techRecStationHandoverDone(Object station) {
    return 'Đã xác nhận giao kiện tại trạm $station.';
  }

  @override
  String get techRecTagIntact => 'Kiện còn nguyên vẹn, niêm phong tốt';

  @override
  String get techRecTagPackagingDamaged => 'Bao bì rách/móp nhẹ do va đập';

  @override
  String get techRecTagDroneStuck => 'Drone gãy cánh, kẹt cành cây';

  @override
  String get techRecTagNotFound => 'Đã tìm khắp khu vực không thấy kiện';

  @override
  String get techRecTagUnsafe => 'Khu vực không an toàn, không tiếp cận được';

  @override
  String get techRecSheetTitle => 'Báo cáo hiện trường & Kết quả thu hồi';

  @override
  String get techRecSheetHint =>
      'KTV kiosk phải bấm xác nhận tọa độ thực tế tại điểm tìm kiếm, nhập ghi chú tình trạng và chụp ảnh bằng chứng.';

  @override
  String get techRecGpsConfirmed => 'Đã xác nhận tọa độ hiện trường';

  @override
  String get techRecConfirmGpsTitle => 'Xác nhận tọa độ GPS tại hiện trường';

  @override
  String get techRecConfirmGpsHint =>
      'Bấm nút bên dưới để lấy toạ độ GPS chính xác nơi bạn đang đứng đối chiếu với điểm drone rơi.';

  @override
  String get techRecGpsUnavailable =>
      'Không lấy được toạ độ GPS. Vui lòng bật định vị và cấp quyền vị trí.';

  @override
  String get techRecReadingGps => 'Đang đọc tín hiệu GPS...';

  @override
  String get techRecConfirmGpsButton => 'Bấm xác nhận tọa độ hiện trường';

  @override
  String techRecCoordinates(Object lat, Object lng, Object accuracy) {
    return 'Tọa độ: $lat, $lng (Sai số: ±$accuracy m)';
  }

  @override
  String techRecWithinRange(Object meters) {
    return '✓ Trong phạm vi hiện trường (~$meters m từ điểm rơi)';
  }

  @override
  String techRecOutOfRange(Object meters) {
    return '⚠️ Cách điểm rơi ~$meters m (Tiến lại gần hơn nếu có thể)';
  }

  @override
  String get techRecRefreshGps => 'Cập nhật lại GPS';

  @override
  String get techRecSearchResult => 'Kết quả tìm kiếm';

  @override
  String get techRecOutcomeFound => 'Đã tìm thấy kiện hàng';

  @override
  String get techRecOutcomeNotFound => 'Không tìm thấy kiện hàng';

  @override
  String get techRecOutcomeUnsafe => 'Khu vực không an toàn để tìm';

  @override
  String get techRecCondIntact => 'Nguyên vẹn';

  @override
  String get techRecCondMinor => 'Hư hại nhẹ';

  @override
  String get techRecCondMajor => 'Hư hại nặng';

  @override
  String get techRecCondUnusable => 'Không thể sử dụng';

  @override
  String get techRecNoteLabel => 'Ghi chú hiện trường (Bắt buộc nhập mô tả)';

  @override
  String get techRecNoteHint =>
      'Mô tả vị trí phát hiện, hiện trạng drone, tình trạng kiện, nơi lưu trữ tạm...';

  @override
  String get techRecPhotoHelper =>
      'Bắt buộc ít nhất 1 ảnh chụp trực tiếp tại hiện trường (kèm toạ độ).';

  @override
  String get techRecPhotoRequired => 'Vui lòng chụp ít nhất 1 ảnh hiện trường.';

  @override
  String get techRecNoteRequired => 'Vui lòng nhập ghi chú hiện trường.';

  @override
  String get techRecSubmit => 'Gửi Admin xác minh';

  @override
  String techRecBringToStation(Object name) {
    return 'Mang kiện tới trạm $name';
  }

  @override
  String techRecDistanceFromFound(Object km) {
    return 'Cách nơi tìm thấy ~$km km';
  }

  @override
  String get techRecStationNoDrone =>
      'Trạm đang hết drone — kiện chờ drone tại trạm';

  @override
  String get techRecStationHasDrone => 'Trạm còn drone sẵn sàng giao lại';

  @override
  String get techRecDirectionsToStation => 'Chỉ đường tới trạm';

  @override
  String get techRecErrHandoverFailed =>
      'Bàn giao trực tiếp thất bại — kiểm tra lại mã PIN 6 số hoặc mã QR của đơn rồi thử lại.';

  @override
  String get techRecErrInvalidOtp => 'Mã PIN/QR của đơn không đúng.';

  @override
  String get techRecErrRelocateFailed =>
      'Không chuyển được đơn sang ô mới. Hàng vẫn ở ô cũ — thử lại hoặc chọn phương án khác.';

  @override
  String get techRecErrSlaNotAssignee =>
      'Chỉ KTV đang được giao phiếu mới gia hạn được SLA.';

  @override
  String get techRecErrSlaLimitReached =>
      'Phiếu đã hết lượt tự gia hạn SLA — liên hệ admin nếu cần thêm thời gian.';

  @override
  String get techRecErrSlaHoursExceeded =>
      'Số giờ gia hạn vượt mức cho phép mỗi lần.';

  @override
  String get techRecErrSlaReasonRequired => 'Cần nêu lý do gia hạn SLA.';

  @override
  String get techRecErrInvalidExtensionHours =>
      'Thời gian gia hạn phải từ 1 giờ trở lên.';

  @override
  String get techRecErrSlaRestricted =>
      'Bạn đang có quá nhiều phiếu trễ hạn SLA nên tạm thời không nhận được việc mới.';

  @override
  String get techRecErrReleaseReasonRequired =>
      'Cần nêu lý do trả phiếu về hàng chờ.';

  @override
  String get techRecErrReportNotClaimed =>
      'Phiếu đang ở hàng chờ, chưa có KTV nhận.';

  @override
  String get techRecErrReportResolved => 'Phiếu đã được hoàn tất.';

  @override
  String get techRecErrReportOpen =>
      'Ô/bãi đáp đang có phiếu sự cố mở — hoàn tất phiếu đó trước.';

  @override
  String get techRecErrTargetBoxRequired =>
      'Cần chọn ô trống đích để điều chuyển hàng.';

  @override
  String get techRecErrTargetBoxUnavailable =>
      'Ô đích không còn trống — tải lại sơ đồ và chọn ô khác.';

  @override
  String get techRecErrBoxNotFault => 'Ô không còn ở trạng thái lỗi.';

  @override
  String get techRecErrHandoverOtpRequired =>
      'Cần mã PIN 6 số hoặc mã QR của đơn để bàn giao.';

  @override
  String get techRecErrHandoverOtpUnavailable =>
      'Đơn chưa có mã lấy hàng nên chưa bàn giao trực tiếp được.';

  @override
  String get techRecErrSealRequired => 'Nhập mã Seal in trên túi niêm phong.';

  @override
  String get techRecErrIncidentActionInvalid => 'Phương án xử lý không hợp lệ.';

  @override
  String get techRecErrIncidentBoxNotInLocker =>
      'Ô đã chọn không thuộc tủ của phiếu.';

  @override
  String get techRecErrForceOpenReportRequired =>
      'Ảnh khi mở khẩn cấp chỉ lưu được khi mở từ một phiếu sự cố.';

  @override
  String get techRecErrForceOpenReportMismatch =>
      'Phiếu sự cố không thuộc tủ của ô này.';

  @override
  String get techRecErrDroneReportRequired =>
      'Phiếu này không phải phiếu drone.';

  @override
  String get techRecErrDeviceNotPaired => 'Thiết bị chưa được gắn với tủ nào.';

  @override
  String get techRecErrDeviceNotInScope =>
      'Thiết bị không thuộc tủ bạn phụ trách.';

  @override
  String get techRecErrDeviceOnlineNotAllowed =>
      'Trạng thái trực tuyến do máy chủ tự tính, không đặt tay được.';
}
