/// Phone-number helpers.
///
/// Firebase phone auth requires E.164 format (`+<country><subscriber>`), but
/// Vietnamese users type local numbers like `0911649183`. This converts common
/// inputs to E.164, defaulting to Vietnam (+84).
String toE164Phone(String input, {String defaultDialCode = '+84'}) {
  // Strip spaces, dashes, dots and parentheses.
  final s = input.trim().replaceAll(RegExp(r'[\s\-().]'), '');
  if (s.isEmpty) return s;

  // Already E.164.
  if (s.startsWith('+')) return s;

  // International prefix typed as 00xx -> +xx.
  if (s.startsWith('00')) return '+${s.substring(2)}';

  final cc = defaultDialCode.replaceAll('+', ''); // e.g. '84'

  // Local number with leading 0 -> drop 0, add dial code (0911... -> +84911...).
  if (s.startsWith('0')) return '$defaultDialCode${s.substring(1)}';

  // Number already starting with the country code but missing '+'.
  if (s.startsWith(cc)) return '+$s';

  // Bare subscriber number -> prepend dial code.
  return '$defaultDialCode$s';
}

/// True when the (post-normalization) value looks like a plausible E.164 number.
bool isLikelyValidPhone(String input) {
  final e164 = toE164Phone(input);
  return RegExp(r'^\+\d{8,15}$').hasMatch(e164);
}
