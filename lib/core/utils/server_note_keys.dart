/// Ghi chú server tự soạn (mốc đơn, nhật ký xử lý sự cố của KTV) về tiếng Anh
/// khi app gửi `X-App-Language: en`. Code nhận dạng loại ghi chú theo tag/cụm
/// tiếng Việt (`[ĐIỀU CHUYỂN Ô]`, "sang ô #5"…) dùng các hàm dưới đây để hiểu
/// được cả bản tiếng Anh — câu tiếng Anh lấy đúng từ bảng dịch của backend
/// (`common-lib/src/main/resources/i18n/server-text-en.json`).
library;

/// Cụm tiếng Anh (chữ HOA) → từ khoá tiếng Việt tương ứng mà code đang dò.
const _englishToVietnamese = <String, String>{
  '[BOX RELOCATED]': '[ĐIỀU CHUYỂN Ô]',
  '[SEALED TO HUB]': '[NIÊM PHONG VỀ HUB]',
  '[HANDED OVER IN PERSON]': '[BÀN GIAO TRỰC TIẾP]',
  '[CONFIRMED & BOX LOCKED]': '[XÁC NHẬN & KHÓA Ô]',
  '[INSPECTION PASSED]': '[NGHIỆM THU THÀNH CÔNG]',
  '[ON-SITE NOTE]': '[GHI CHÚ HIỆN TRƯỜNG]',
  '[ON-SITE CHECK]': '[KIỂM TRA HIỆN TRƯỜNG]',
  '[ISSUE NOT CONFIRMED]': '[KHÔNG XÁC NHẬN SỰ CỐ]',
  '[EMERGENCY OPEN]': '[MỞ KHẨN CẤP]',
  '[ISSUE RESOLVED]': '[ĐÃ XỬ LÝ SỰ CỐ]',
  'MOVED THE PARCEL TO BOX': 'ĐIỀU CHUYỂN HÀNG SANG Ô',
  'MOVED THE ITEMS TO BOX': 'ĐIỀU CHUYỂN',
  'HANDED THE PARCEL DIRECTLY': 'BÀN GIAO HÀNG TRỰC TIẾP',
  'HANDED OVER': 'BÀN GIAO',
  'SEALED': 'NIÊM PHONG',
  'LOCKED FOR MAINTENANCE': 'KHÓA BẢO TRÌ',
  'MAINTENANCE LOCK': 'KHÓA BẢO TRÌ',
  'REPAIRED ON SITE': 'SỬA TẠI CHỖ',
  'FIXED ON SITE': 'XỬ LÝ TẠI CHỖ',
  'BOX ISSUE RESOLVED': 'ĐÃ XỬ LÝ SỰ CỐ Ô',
  'ON SITE': 'HIỆN TRƯỜNG',
  'SUCCESS': 'THÀNH CÔNG',
  'CHECK': 'KIỂM TRA',
  'ISSUE': 'SỰ CỐ',
  'MAINTENANCE': 'BẢO TRÌ',
  'STORAGE': 'LƯU KHO',
};

/// Chữ HOA của [note], nối thêm từ khoá tiếng Việt cho mỗi cụm tiếng Anh tìm
/// thấy — dùng thay `note.toUpperCase()` ở chỗ dò tag/từ khoá tiếng Việt.
String serverNoteKeys(String note) {
  final upper = note.toUpperCase();
  final extra = StringBuffer();
  _englishToVietnamese.forEach((english, vietnamese) {
    if (upper.contains(english)) extra.write(' $vietnamese');
  });
  return extra.isEmpty ? upper : '$upper |$extra';
}

/// Ô mới trong ghi chú điều chuyển: "sang ô #5" / "to box #5".
String? relocatedBoxNumber(String note) => RegExp(
  r'(?:sang ô|to box) #?(\d+)',
  caseSensitive: false,
).firstMatch(note)?.group(1);

/// Ô cũ bị khoá bảo trì: "khóa bảo trì ô #3" / "locked box #3" /
/// "Box #3 locked for maintenance"; không có thì ô đầu tiên được nhắc tới.
String? lockedOrFirstBoxNumber(String note) =>
    RegExp(
      r'(?:khóa bảo trì ô|locked box) #?(\d+)',
      caseSensitive: false,
    ).firstMatch(note)?.group(1) ??
    RegExp(
      r'box #?(\d+) locked',
      caseSensitive: false,
    ).firstMatch(note)?.group(1) ??
    firstBoxNumber(note);

/// Ô đầu tiên được nhắc tới: "ô #3" / "box #3".
String? firstBoxNumber(String note) => RegExp(
  r'(?:ô|box) #?(\d+)',
  caseSensitive: false,
).firstMatch(note)?.group(1);
