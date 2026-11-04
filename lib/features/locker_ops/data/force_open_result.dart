import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// Kết quả lệnh mở ô khẩn cấp (`POST /api/locker-technician/boxes/{id}/force-open`).
///
/// Backend trả HTTP 200 cho cả hai trường hợp, nên không thể dựa vào việc
/// request không ném lỗi: phải đọc `data.accepted`.
/// - `accepted: true` + `status` OPENED ⇒ tủ xác nhận ô đã mở.
/// - `accepted: false` + `status` TIMEOUT / FAILED / JAMMED + `message` tiếng
///   Việt ⇒ ô chưa mở (hoặc chưa chắc đã mở), phải báo lỗi cho KTV.
/// Backend cũ không trả `accepted` ⇒ coi như thành công như trước.
class ForceOpenResult {
  const ForceOpenResult({required this.accepted, this.status, this.message});

  /// [data] là phần `data` của ApiResponse (đã bóc envelope).
  factory ForceOpenResult.fromResponse(Map<String, dynamic> data) {
    final raw = data['accepted'];
    final message = data['message']?.toString().trim();
    return ForceOpenResult(
      accepted: raw == null || raw == true || '$raw'.toLowerCase() == 'true',
      status: data['status']?.toString(),
      message: message == null || message.isEmpty ? null : message,
    );
  }

  /// Câu báo lỗi khi backend không gửi kèm `message`.
  static String get fallbackFailureMessage => L10n.current.forceOpenUnconfirmed;

  /// `true` khi tủ xác nhận đã mở ô (hoặc backend cũ không trả `accepted`).
  final bool accepted;

  /// OPENED / TIMEOUT / FAILED / JAMMED; `null` với backend cũ.
  final String? status;

  /// Câu tiếng Việt backend gửi kèm (lý do khi thất bại).
  final String? message;

  /// Câu hiển thị cho KTV khi [accepted] = `false`.
  String get failureMessage => message ?? fallbackFailureMessage;
}
