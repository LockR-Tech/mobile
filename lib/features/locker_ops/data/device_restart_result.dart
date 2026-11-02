import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// Kết quả lệnh khởi động lại bộ điều khiển tủ
/// (`POST /api/locker-technician/devices/{id}/restart`).
///
/// Backend trả HTTP 200 cho mọi trường hợp, nên phải đọc `data`:
/// - `accepted: true` + `status` ACCEPTED ⇒ tủ đã nhận lệnh và đang khởi động lại.
/// - `accepted: false` + `status` TIMEOUT / FAILED + `message` ⇒ tủ không phản
///   hồi hoặc từ chối, phải báo lỗi cho KTV.
/// - Không có `accepted` (máy chủ chưa cập nhật) ⇒ chỉ biết lệnh đã được gửi,
///   KHÔNG được báo là tủ đã khởi động lại.
class DeviceRestartResult {
  const DeviceRestartResult({this.accepted, this.status, this.message});

  /// [data] là phần `data` của ApiResponse (đã bóc envelope).
  factory DeviceRestartResult.fromResponse(Map<String, dynamic> data) {
    final raw = data['accepted'];
    final message = data['message']?.toString().trim();
    final status = data['status']?.toString().trim().toUpperCase();
    return DeviceRestartResult(
      accepted: raw == null ? null : (raw == true || '$raw'.toLowerCase() == 'true'),
      status: status == null || status.isEmpty ? null : status,
      message: message == null || message.isEmpty ? null : message,
    );
  }

  /// `null` khi máy chủ không trả kết quả xác nhận (bản cũ).
  final bool? accepted;

  /// ACCEPTED / TIMEOUT / FAILED; `null` với máy chủ cũ.
  final String? status;

  /// Câu tiếng Việt server gửi kèm.
  final String? message;

  /// Máy chủ chưa hỗ trợ trả kết quả — chỉ biết lệnh đã gửi đi.
  bool get isUnconfirmed => accepted == null;

  bool get isAccepted => accepted == true;

  /// Câu hiển thị cho KTV theo kết quả.
  String get displayMessage {
    if (isUnconfirmed) return L10n.current.techUiRestartUnconfirmed;
    if (message != null) return message!;
    return switch (status) {
      'ACCEPTED' => L10n.current.techUiRestartAccepted,
      'TIMEOUT' => L10n.current.techUiRestartTimeout,
      _ => L10n.current.techUiRestartFailed,
    };
  }
}
