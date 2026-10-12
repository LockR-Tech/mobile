class RegisterEntity {
  final bool success;
  final String? message;
  final String? userId;

  /// Backend cấp luôn cặp token khi đăng ký (`AuthResponse`) ⇒ đăng nhập luôn,
  /// không bắt người dùng nhập lại mật khẩu.
  final String? accessToken;
  final String? refreshToken;

  const RegisterEntity({
    required this.success,
    this.message,
    this.userId,
    this.accessToken,
    this.refreshToken,
  });

  bool get hasTokens =>
      (accessToken ?? '').isNotEmpty && (refreshToken ?? '').isNotEmpty;

  factory RegisterEntity.success({
    String? message,
    String? userId,
    String? accessToken,
    String? refreshToken,
  }) {
    return RegisterEntity(
      success: true,
      message: message,
      userId: userId,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  factory RegisterEntity.failure({String? message}) {
    return RegisterEntity(success: false, message: message);
  }
}
