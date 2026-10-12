/// Phone-number helpers.
///
/// Firebase phone auth requires E.164 format (`+<country><subscriber>`), but
/// Vietnamese users type local numbers like `0911649183`. This converts common
/// inputs to E.164, defaulting to Vietnam (+84).
String toE164Phone(String input, {String defaultDialCode = '+84'}) {
  // Strip spaces, dashes, dots and parentheses.
  final s = input.trim().replaceAll(RegExp(r'[\s\-().]'), '');
  if (s.isEmpty) return s;

  final cc = defaultDialCode.replaceAll('+', ''); // e.g. '84'

  // Already E.164 — but users often keep the trunk 0 after the dial code
  // ("+84 0911…"), which Firebase rejects: drop it.
  if (s.startsWith('+')) {
    if (s.startsWith('${defaultDialCode}0')) {
      return '$defaultDialCode${s.substring(defaultDialCode.length + 1)}';
    }
    return s;
  }

  // International prefix typed as 00xx -> +xx.
  if (s.startsWith('00')) {
    return toE164Phone('+${s.substring(2)}', defaultDialCode: defaultDialCode);
  }

  // Local number with leading 0 -> drop 0, add dial code (0911... -> +84911...).
  if (s.startsWith('0')) return '$defaultDialCode${s.substring(1)}';

  // Number already starting with the country code but missing '+'. A VN
  // subscriber number is 9 digits and may itself start with 84 (Vinaphone
  // 084…), so only treat "84" as the country code when the rest is long
  // enough to be a full subscriber number.
  if (s.startsWith(cc) && s.length >= cc.length + 9) return '+$s';

  // Bare subscriber number -> prepend dial code.
  return '$defaultDialCode$s';
}

/// Di động Việt Nam ở dạng E.164: +84 rồi 9 số, đầu số 3/5/7/8/9
/// (03x, 05x, 07x, 08x, 09x). Số bàn không nhận được SMS OTP.
final RegExp _vnMobileE164 = RegExp(r'^\+84[35789]\d{8}$');

/// True when the (post-normalization) value looks like a plausible E.164 number.
///
/// Số +84 phải là số di động Việt Nam hợp lệ; số nước khác chỉ kiểm dạng E.164.
bool isLikelyValidPhone(String input) {
  final e164 = toE164Phone(input);
  if (e164.startsWith('+84')) return _vnMobileE164.hasMatch(e164);
  return RegExp(r'^\+\d{8,15}$').hasMatch(e164);
}

/// Số E.164 hiển thị cho người dùng Việt ("+84912345678" → "0912 345 678").
String displayPhone(String e164) {
  if (!_vnMobileE164.hasMatch(e164)) return e164;
  final local = '0${e164.substring(3)}';
  return '${local.substring(0, 4)} ${local.substring(4, 7)} ${local.substring(7)}';
}
