/// Base class cho tất cả Failures trong ứng dụng.
/// Dùng để represent lỗi theo functional programming pattern.
abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => 'Failure: $message';
}

/// Server Failure: Lỗi từ server (5xx)
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

/// Network Failure: Lỗi kết nối mạng
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

/// Validation Failure: Lỗi validate dữ liệu
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

/// Authentication Failure: Lỗi xác thực
class AuthenticationFailure extends Failure {
  const AuthenticationFailure(super.message, {super.code});
}

/// Authorization Failure: Lỗi phân quyền
class AuthorizationFailure extends Failure {
  const AuthorizationFailure(super.message, {super.code});
}

/// NotFound Failure: Không tìm thấy resource
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.code});
}

/// Cache Failure: Lỗi cache
class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code});
}

/// Unknown Failure: Lỗi không xác định
class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.code});
}

/// Phiên QR đăng nhập web đã hết hạn (backend: "QR session expired").
class QrExpiredFailure extends Failure {
  const QrExpiredFailure([
    String message = 'Mã QR hết hạn hoặc phiên đã hết hạn.',
  ]) : super(message);
}

/// Mã QR đã được xác nhận trước đó (backend: "QR session already used").
class QrAlreadyUsedFailure extends Failure {
  const QrAlreadyUsedFailure([String message = 'Mã QR đã được sử dụng.'])
    : super(message);
}
