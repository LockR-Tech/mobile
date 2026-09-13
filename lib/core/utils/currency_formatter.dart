import 'package:intl/intl.dart';

class CurrencyFormatter {
  const CurrencyFormatter._();

  static String formatVnd(num amount) {
    final formatted = NumberFormat.decimalPattern('vi_VN').format(amount);
    return '$formatted đ';
  }
}
