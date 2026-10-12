import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';

/// Thông báo lỗi hiển thị cho người dùng, không kèm tiền tố kỹ thuật
/// ("ServerException: …", "NotFoundException: …") như khi gọi `e.toString()`.
///
/// 404 thường nghĩa là backend chưa triển khai endpoint (app đi trước backend)
/// ⇒ nói rõ là máy chủ chưa hỗ trợ thay vì hiện message kỹ thuật.
String userErrorMessage(
  Object error, {
  String notFound = 'Máy chủ chưa hỗ trợ chức năng này. Vui lòng thử lại sau.',
  String fallback = 'Đã xảy ra lỗi. Vui lòng thử lại.',
}) {
  if (error is NotFoundException || error is NotFoundFailure) return notFound;
  final message = switch (error) {
    ServerException(:final message) => message,
    NetworkException(:final message) => message,
    ValidationException(:final message) => message,
    AuthenticationException(:final message) => message,
    AuthorizationException(:final message) => message,
    Failure(:final message) => message,
    _ => '',
  };
  final clean = message.trim();
  return clean.isEmpty || clean == 'Đã xảy ra lỗi.' ? fallback : clean;
}
