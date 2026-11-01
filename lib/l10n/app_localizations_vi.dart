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
  String get commonYes => 'Có';

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
}
