import 'package:flutter/material.dart';
import 'transaction.dart';

extension TransactionClassification on Transaction {
  /// Xác định hình thức giao dịch: 'WALLET', 'SEPAY', 'VNPAY', 'MOMO', 'WITHDRAW'
  String get detectedMethod {
    final ref = (referenceId ?? '').toUpperCase();
    final desc = description.toUpperCase();
    final src = source.toUpperCase();

    if (src.contains('SEPAY') || ref.contains('SEPAY') || desc.contains('SEPAY') || ref.startsWith('FT')) {
      return 'SEPAY';
    }
    if (src.contains('VNPAY') || ref.contains('VNPAY') || desc.contains('VNPAY')) {
      return 'VNPAY';
    }
    if (src.contains('MOMO') || ref.contains('MOMO') || desc.contains('MOMO')) {
      return 'MOMO';
    }
    if (src == 'WITHDRAW' || ref.contains('WDR') || desc.contains('RÚT TIỀN') || desc.contains('RUT TIEN')) {
      return 'WITHDRAW';
    }
    if (src == 'ORDER_PAYMENT') return 'WALLET';
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
      case 'WITHDRAW':
        return const Color(0xFFEA580C); // Orange
      case 'WALLET':
      default:
        return const Color(0xFF1E293B); // Navy
    }
  }

  /// Xác định loại dịch vụ: 'RENTAL', 'SEND', 'LAUNDRY', 'TOPUP', 'WITHDRAW', 'OTHER'
  String get detectedService {
    final src = source.toUpperCase();
    final desc = description.toUpperCase();
    final oc = (orderCode ?? '').toUpperCase();

    if (src == 'WITHDRAW' || desc.contains('RÚT TIỀN') || desc.contains('RUT TIEN')) {
      return 'WITHDRAW';
    }
    if (src == 'TOPUP' || type == 'TOP_UP' || (type == 'CREDIT' && !desc.contains('HOÀN'))) {
      return 'TOPUP';
    }
    if (oc.contains('SND') || oc.contains('DRN') || desc.contains('GỬI') || desc.contains('SEND') || desc.contains('HÀNG') || desc.contains('DRONE')) {
      return 'SEND';
    }
    if (oc.contains('LND') || desc.contains('GIẶT') || desc.contains('SẤY')) {
      return 'LAUNDRY';
    }
    if (oc.contains('STG') || desc.contains('THUÊ') || desc.contains('LƯU TRỮ') || desc.contains('RENTAL')) {
      return 'RENTAL';
    }
    if (src == 'ORDER_PAYMENT') return 'RENTAL';
    return 'OTHER';
  }

  String get detectedServiceLabel {
    switch (detectedService) {
      case 'RENTAL':
        return 'Thuê tủ';
      case 'SEND':
        return 'Gửi hàng';
      case 'LAUNDRY':
        return 'Giặt sấy';
      case 'TOPUP':
        return 'Nạp tiền ví';
      case 'WITHDRAW':
        return 'Rút tiền';
      default:
        return 'Khác';
    }
  }

  IconData get detectedServiceIcon {
    switch (detectedService) {
      case 'RENTAL':
        return Icons.inventory_2_rounded;
      case 'SEND':
        return Icons.local_shipping_rounded;
      case 'LAUNDRY':
        return Icons.local_laundry_service_rounded;
      case 'TOPUP':
        return Icons.add_circle_outline_rounded;
      case 'WITHDRAW':
        return Icons.account_balance_rounded;
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
      case 'TOPUP':
        return const Color(0xFF16A34A); // Green
      case 'WITHDRAW':
        return const Color(0xFFEA580C); // Orange
      default:
        return const Color(0xFF64748B); // Slate
    }
  }
}
