import 'package:flutter/material.dart';
import 'transaction.dart';

/// Phân loại một dòng `GET /api/wallet/transactions`.
///
/// Backend (payment-service) ghi `source` cho mọi biến động ví: `TOPUP`,
/// `ORDER_PAYMENT`, `REFUND`, `ADJUST`, `WITHDRAW`; còn các dòng thanh toán đơn
/// trực tiếp qua cổng (không trừ ví) có `source` = phương thức (`SEPAY`,
/// `VNPAY`, `MOMO`, `CASH`) và `id` âm. Phân loại theo `source` trước, chỉ đoán
/// theo mô tả khi thiếu — trước đây mọi khoản CREDIT đều bị gọi là "nạp tiền"
/// (kể cả hoàn tiền, admin điều chỉnh).
extension TransactionClassification on Transaction {
  String get _src => source.trim().toUpperCase();
  String get _ref => (referenceId ?? '').trim().toUpperCase();
  String get _desc => description.toUpperCase();

  /// Tiền vào ví (CREDIT/TOP_UP) hay tiền ra.
  bool get isCredit {
    final t = type.trim().toUpperCase();
    return t == 'CREDIT' || t == 'TOP_UP';
  }

  /// Dòng ghi sổ ví thật (id dương). Dòng thanh toán đơn trực tiếp qua cổng
  /// (id âm) không đổi số dư ví nên "số dư sau GD" của nó vô nghĩa.
  bool get affectsWalletBalance => !(int.tryParse(id) ?? 0).isNegative;

  /// Hình thức: 'WALLET', 'SEPAY', 'VNPAY', 'MOMO', 'CASH', 'WITHDRAW'.
  String get detectedMethod {
    final src = _src;
    final ref = _ref;
    final desc = _desc;

    // Hoàn tiền (kể cả hoàn yêu cầu rút bị từ chối, ref `RF-WDR-…`) đi vào ví.
    if (src == 'REFUND' || src == 'ADJUST') return 'WALLET';
    if (src.contains('SEPAY') ||
        ref.contains('SEPAY') ||
        desc.contains('SEPAY') ||
        ref.startsWith('FT')) {
      return 'SEPAY';
    }
    if (src.contains('VNPAY') || ref.contains('VNPAY') || desc.contains('VNPAY')) {
      return 'VNPAY';
    }
    if (src.contains('MOMO') || ref.contains('MOMO') || desc.contains('MOMO')) {
      return 'MOMO';
    }
    if (src == 'CASH' || desc.contains('TIỀN MẶT')) return 'CASH';
    if (src == 'WITHDRAW' || ref.startsWith('WDR')) return 'WITHDRAW';
    // Nạp ví mặc định qua SePay (VNPay đã có chữ VNPAY trong mô tả).
    if (src == 'TOPUP') return 'SEPAY';
    return 'WALLET';
  }

  String get detectedMethodLabel {
    switch (detectedMethod) {
      case 'SEPAY':
        return 'Cổng SePay QR';
      case 'VNPAY':
        return 'Cổng VNPay';
      case 'MOMO':
        return 'Ví MoMo';
      case 'CASH':
        return 'Tiền mặt';
      case 'WITHDRAW':
        return 'Rút tiền';
      case 'WALLET':
      default:
        return 'Ví Lock.R';
    }
  }

  IconData get detectedMethodIcon {
    switch (detectedMethod) {
      case 'SEPAY':
        return Icons.qr_code_2_rounded;
      case 'VNPAY':
        return Icons.credit_card_rounded;
      case 'MOMO':
        return Icons.account_balance_wallet_outlined;
      case 'CASH':
        return Icons.payments_outlined;
      case 'WITHDRAW':
        return Icons.outbox_rounded;
      case 'WALLET':
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  Color get detectedMethodColor {
    switch (detectedMethod) {
      case 'SEPAY':
        return const Color(0xFF0284C7); // Cyan / Blue
      case 'VNPAY':
        return const Color(0xFFE11D48); // Red
      case 'MOMO':
        return const Color(0xFFC026D3); // Purple
      case 'CASH':
        return const Color(0xFF15803D); // Green
      case 'WITHDRAW':
        return const Color(0xFFEA580C); // Orange
      case 'WALLET':
      default:
        return const Color(0xFF1E293B); // Navy
    }
  }

  bool get _isOrderRelated =>
      _src == 'ORDER_PAYMENT' ||
      relatedOrderId != null ||
      (orderCode ?? '').isNotEmpty ||
      !affectsWalletBalance;

  /// Loại: 'TOPUP', 'WITHDRAW', 'REFUND', 'ADJUST', 'RENTAL', 'SEND',
  /// 'LAUNDRY', 'ORDER' (thanh toán đơn chưa rõ loại), 'OTHER'.
  String get detectedService {
    final src = _src;
    final desc = _desc;
    final t = type.trim().toUpperCase();

    if (src == 'TOPUP' || t == 'TOP_UP') return 'TOPUP';
    if (src == 'WITHDRAW') return 'WITHDRAW';
    if (src == 'REFUND') return 'REFUND';
    if (src == 'ADJUST') return 'ADJUST';

    if (_isOrderRelated) {
      final oc = (orderCode ?? '').toUpperCase();
      if (oc.contains('SND') ||
          oc.contains('DRN') ||
          desc.contains('GỬI HÀNG') ||
          desc.contains('DRONE')) {
        return 'SEND';
      }
      if (oc.contains('LND') || desc.contains('GIẶT') || desc.contains('SẤY')) {
        return 'LAUNDRY';
      }
      if (oc.contains('STG') ||
          desc.contains('THUÊ') ||
          desc.contains('LƯU TRỮ') ||
          desc.contains('RENTAL')) {
        return 'RENTAL';
      }
      return 'ORDER';
    }

    // Không có source (dữ liệu cũ): đoán theo mô tả, KHÔNG coi mọi CREDIT là nạp.
    if (desc.contains('RÚT TIỀN') || desc.contains('RUT TIEN')) return 'WITHDRAW';
    if (desc.contains('HOÀN')) return 'REFUND';
    if (desc.contains('NẠP')) return 'TOPUP';
    return 'OTHER';
  }

  String get detectedServiceLabel => transactionServiceLabel(detectedService);

  IconData get detectedServiceIcon {
    switch (detectedService) {
      case 'RENTAL':
        return Icons.inventory_2_rounded;
      case 'SEND':
        return Icons.local_shipping_rounded;
      case 'LAUNDRY':
        return Icons.local_laundry_service_rounded;
      case 'ORDER':
        return Icons.shopping_bag_outlined;
      case 'TOPUP':
        return Icons.add_circle_outline_rounded;
      case 'WITHDRAW':
        return Icons.account_balance_rounded;
      case 'REFUND':
        return Icons.replay_rounded;
      case 'ADJUST':
        return Icons.tune_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  Color get detectedServiceColor {
    switch (detectedService) {
      case 'RENTAL':
        return const Color(0xFF2563EB); // Blue
      case 'SEND':
        return const Color(0xFF7C3AED); // Purple
      case 'LAUNDRY':
        return const Color(0xFF0D9488); // Teal
      case 'ORDER':
        return const Color(0xFF0369A1);
      case 'TOPUP':
        return const Color(0xFF16A34A); // Green
      case 'WITHDRAW':
        return const Color(0xFFEA580C); // Orange
      case 'REFUND':
        return const Color(0xFF0891B2);
      case 'ADJUST':
        return const Color(0xFF7C2D12);
      default:
        return const Color(0xFF64748B); // Slate
    }
  }

  /// Tiêu đề hiển thị trong danh sách giao dịch.
  String get displayTitle {
    switch (detectedService) {
      case 'TOPUP':
        return 'Nạp tiền vào ví';
      case 'WITHDRAW':
        return isCredit ? 'Hoàn tiền rút' : 'Rút tiền về tài khoản ngân hàng';
      case 'REFUND':
        return 'Hoàn tiền vào ví';
      case 'ADJUST':
        return isCredit ? 'Điều chỉnh số dư (cộng)' : 'Điều chỉnh số dư (trừ)';
      case 'RENTAL':
      case 'SEND':
      case 'LAUNDRY':
      case 'ORDER':
        return detectedMethod == 'WALLET'
            ? 'Thanh toán đơn bằng ví'
            : 'Thanh toán đơn qua $detectedMethodLabel';
      default:
        return isCredit ? 'Tiền vào ví' : 'Tiền ra khỏi ví';
    }
  }

  /// Mô tả backend bỏ phần trạng thái ghi cứng lúc tạo (vd. "[Chờ duyệt]" của
  /// giao dịch rút — sau khi duyệt mô tả vẫn giữ chữ này). Trạng thái thật của
  /// yêu cầu rút lấy từ `GET /api/wallet/withdrawals`.
  String get displayDescription => description
      .replaceAll(RegExp(r'\s*\[(Chờ duyệt|Cho duyet|PENDING)\]\s*', caseSensitive: false), ' ')
      .trim();
}

String transactionServiceLabel(String service) {
  switch (service) {
    case 'RENTAL':
      return 'Thuê tủ';
    case 'SEND':
      return 'Gửi hàng';
    case 'LAUNDRY':
      return 'Giặt sấy';
    case 'ORDER':
      return 'Thanh toán đơn';
    case 'TOPUP':
      return 'Nạp tiền ví';
    case 'WITHDRAW':
      return 'Rút tiền';
    case 'REFUND':
      return 'Hoàn tiền';
    case 'ADJUST':
      return 'Điều chỉnh số dư';
    default:
      return 'Khác';
  }
}

/// Tổng tiền vào / tiền ra của một danh sách giao dịch — hiện riêng hai số
/// thay vì cộng gộp (cộng gộp tiền vào + tiền ra ra một con số vô nghĩa).
({double income, double expense}) sumIncomeExpense(Iterable<Transaction> list) {
  var income = 0.0;
  var expense = 0.0;
  for (final tx in list) {
    if (tx.isCredit) {
      income += tx.amount;
    } else {
      expense += tx.amount;
    }
  }
  return (income: income, expense: expense);
}
