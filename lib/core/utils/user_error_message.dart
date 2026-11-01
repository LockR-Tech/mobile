import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// Thông báo lỗi hiển thị cho người dùng, không kèm tiền tố kỹ thuật
/// ("ServerException: …", "NotFoundException: …") như khi gọi `e.toString()`.
///
/// 404 thường nghĩa là backend chưa triển khai endpoint (app đi trước backend)
/// ⇒ nói rõ là máy chủ chưa hỗ trợ thay vì hiện message kỹ thuật.
String userErrorMessage(
  Object error, {
  String? notFound,
  String? fallback,
}) {
  fallback ??= L10n.current.errorGenericRetry;
  if (error is NotFoundException || error is NotFoundFailure) {
    return notFound ?? L10n.current.errorNotSupportedYet;
  }
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
