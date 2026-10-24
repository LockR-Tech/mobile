/// Mã QR trên tờ "QR mở ô (thử tủ)" của admin web: link
/// `http(s)://…/admin/lockers/{lockerId}/open/{boxId}`. App khách quét ở trang chủ
/// để mở thử đúng ô đó, không cần đơn — server quyết định có cho mở hay không.
class BoxTestOpenQr {
  const BoxTestOpenQr({required this.lockerId, required this.boxId});

  final int lockerId;
  final int boxId;

  static BoxTestOpenQr? tryParse(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null) return null;
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return null;
    final segments = uri.pathSegments;
    for (var i = 0; i + 3 < segments.length; i++) {
      if (segments[i] != 'lockers' || segments[i + 2] != 'open') continue;
      final lockerId = int.tryParse(segments[i + 1]);
      final boxId = int.tryParse(segments[i + 3]);
      if (lockerId != null && lockerId > 0 && boxId != null && boxId > 0) {
        return BoxTestOpenQr(lockerId: lockerId, boxId: boxId);
      }
    }
    return null;
  }
}
