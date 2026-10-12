/// Nội dung mã QR đăng nhập kiosk mà màn hình tủ hiển thị (CONTRACTS §1):
/// `lockr://kiosk-login?sid=<sessionId>&code=<confirmCode>`.
///
/// QR chỉ chứa thứ công khai — app gửi `confirmCode` lên server kèm token của
/// chính người dùng, kiosk tự lấy token bằng bí mật riêng (pollToken) không nằm
/// trong QR.
class KioskQrPayload {
  const KioskQrPayload({required this.sessionId, required this.confirmCode});

  /// Mã phiên do auth-service cấp (UUID).
  final String sessionId;

  /// Mã xác nhận 6–8 ký tự hiện cùng QR trên kiosk.
  final String confirmCode;

  static const String scheme = 'lockr';
  static const String host = 'kiosk-login';

  static final RegExp _sessionPattern = RegExp(r'^[A-Za-z0-9-]{8,64}$');
  static final RegExp _codePattern = RegExp(r'^[A-Za-z0-9]{4,12}$');

  /// Đọc nội dung QR quét được; không phải QR đăng nhập kiosk Lock.R ⇒ `null`.
  static KioskQrPayload? tryParse(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    if (uri == null) return null;
    if (uri.scheme.toLowerCase() != scheme || uri.host.toLowerCase() != host) {
      return null;
    }
    return fromParts(uri.queryParameters['sid'], uri.queryParameters['code']);
  }

  /// Từ hai ô nhập tay. Ô mã phiên cũng nhận nguyên đường dẫn `lockr://...`
  /// (khách dán cả link) — khi đó bỏ qua ô mã xác nhận.
  static KioskQrPayload? fromParts(String? sessionId, String? confirmCode) {
    final sid = sessionId?.trim() ?? '';
    if (sid.toLowerCase().startsWith('$scheme://')) return tryParse(sid);
    final code = (confirmCode ?? '').replaceAll(RegExp(r'\s'), '').toUpperCase();
    if (!_sessionPattern.hasMatch(sid) || !_codePattern.hasMatch(code)) {
      return null;
    }
    return KioskQrPayload(sessionId: sid, confirmCode: code);
  }

  @override
  bool operator ==(Object other) =>
      other is KioskQrPayload &&
      other.sessionId == sessionId &&
      other.confirmCode == confirmCode;

  @override
  int get hashCode => Object.hash(sessionId, confirmCode);
}
