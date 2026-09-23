/// Backend dùng `LocalDateTime` (Java) nên Jackson trả chuỗi **không có múi
/// giờ**: `2026-09-23T16:37:28`. Container chạy giờ UTC, tức chuỗi đó là UTC.
///
/// `DateTime.parse` coi chuỗi trần là **giờ máy**, nên gọi thẳng
/// `DateTime.parse(s).toLocal()` sẽ hiển thị sớm 7 tiếng ở VN (UTC+7) — và
/// tệ hơn, mọi hạn chót bị lùi 7 tiếng nên đơn vừa tạo đã "quá hạn".
///
/// Dùng hàm này cho **mọi** mốc thời gian lấy từ backend.
library;

/// Đọc mốc thời gian từ backend rồi đổi sang giờ máy.
///
/// Chuỗi đã kèm `Z` hoặc offset (`+07:00`) thì giữ nguyên ý nghĩa; chuỗi trần
/// được coi là UTC.
DateTime? parseServerDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toLocal();

  var raw = '$value'.trim();
  if (raw.isEmpty) return null;

  if (raw.contains('T')) {
    final timePart = raw.split('T').last;
    final hasZone = timePart.endsWith('Z') ||
        timePart.contains('+') ||
        // Offset âm: `-` sau phần giờ, không phải dấu của ngày.
        timePart.contains('-');
    if (!hasZone) raw += 'Z';
  }

  return DateTime.tryParse(raw)?.toLocal();
}

/// Như [parseServerDateTime] nhưng trả [fallback] (mặc định: bây giờ) khi
/// không đọc được — dùng cho field bắt buộc có giá trị.
DateTime parseServerDateTimeOr(dynamic value, [DateTime? fallback]) =>
    parseServerDateTime(value) ?? fallback ?? DateTime.now();
