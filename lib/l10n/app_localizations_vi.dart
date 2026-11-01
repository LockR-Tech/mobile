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
}
