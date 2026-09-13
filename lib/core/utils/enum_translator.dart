import '../enums/app_enums.dart';

class EnumTranslator {
  static String translateLogisticsType(dynamic type) {
    if (type == 0 || type == '0') return 'Giao từ tủ qua tủ';
    if (type == 1 || type == '1') return 'Giao từ nhà tới tủ';
    final value = _getValue(type);
    switch (value) {
      case 'LOCKER_TO_LOCKER':
        return 'Giao từ tủ qua tủ';
      case 'HOME_TO_LOCKER':
        return 'Giao từ nhà tới tủ';
      default:
        return value;
    }
  }

  static String translateOrderStatus(dynamic status) {
    final value = _getValue(status);
    switch (value) {
      case 'PENDING':
        return 'Đang chờ xử lý';
      case 'AWAITING_COURIER':
        return 'Chờ người giao hàng';
      case 'AWAITING_PICKUP':
        return 'Chờ lấy hàng';
      case 'ACTIVE':
        return 'Đang hoạt động';
      case 'COMPLETED':
        return 'Đã hoàn tất';
      case 'LOCKED_BY_BALANCE':
        return 'Bị khóa do số dư';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return value;
    }
  }

  static String translateOrderDetailStatus(dynamic status) {
    final value = _getValue(status);
    switch (value) {
      case 'PENDING':
        return 'Chờ xử lý';
      case 'AWAITING_COURIER':
        return 'Chờ người giao hàng';
      case 'AWAITING_PICKUP':
        return 'Chờ lấy hàng';
      case 'AWAITING_CONFIRM_DEPOSIT':
        return 'Chờ xác nhận gửi hàng';
      case 'IN_TRANSIT':
        return 'Đang vận chuyển';
      case 'OCCUPIED':
        return 'Đang sử dụng';
      case 'COMPLETED':
        return 'Hoàn tất';
      case 'OVERDUE':
        return 'Quá hạn';
      case 'COLLECTING':
        return 'Đang gom hàng';
      case 'COLLECTED':
        return 'Đã lấy hàng';
      case 'AWAITING_DROP':
        return 'Chờ gửi hàng';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return value;
    }
  }

  static String translatePaymentStatus(dynamic status) {
    final value = _getValue(status);
    switch (value) {
      case 'PENDING':
        return 'Chờ thanh toán';
      case 'UNPAID':
        return 'Chưa thanh toán';
      case 'PAID':
        return 'Đã thanh toán';
      case 'PARTIAL_PAID':
        return 'Thanh toán một phần';
      case 'REFUNDED':
        return 'Đã hoàn tiền';
      default:
        return value.isEmpty ? 'Chưa xác định' : value;
    }
  }

  static String translateTransactionType(dynamic type) {
    final value = _getValue(type);
    switch (value) {
      case 'DEPOSIT':
        return 'Nạp tiền';
      case 'RENTAL_DEDUCTION':
        return 'Phí thuê tủ';
      case 'LOGISTICS_DEDUCTION':
        return 'Phí vận chuyển';
      case 'OVERDUE_PENALTY':
        return 'Phí quá hạn';
      case 'REFUND':
        return 'Hoàn tiền';
      case 'TOP_UP':
        return 'Nạp tiền vào ví';
      case 'WITHDRAW':
        return 'Rút tiền';
      default:
        return value;
    }
  }

  static String translateTransactionStatus(dynamic status) {
    final value = _getValue(status);
    switch (value) {
      case 'SUCCESS':
        return 'Thành công';
      case 'FAILED':
        return 'Thất bại';
      case 'PENDING':
        return 'Đang chờ';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return value;
    }
  }

  static String translateOrderType(dynamic type) {
    final value = _getValue(type);
    switch (value) {
      case 'LOGISTICS':
        return 'Dịch vụ vận chuyển';
      case 'PERSONAL_RENTAL':
        return 'Thuê tủ cá nhân';
      default:
        return value;
    }
  }

  static String translateLockerStatus(dynamic status) {
    final value = _getValue(status);
    switch (value) {
      case 'AVAILABLE':
        return 'Sẵn sàng';
      case 'OCCUPIED':
        return 'Đang sử dụng';
      case 'RESERVED':
        return 'Đã đặt trước';
      case 'LOCKED_BY_BALANCE':
        return 'Khóa do số dư';
      case 'FAULT':
        return 'Bị lỗi';
      case 'MAINTENANCE':
        return 'Bảo trì';
      case 'INITIALIZING':
        return 'Đang khởi tạo';
      default:
        return value;
    }
  }

  static String translateHwStatus(dynamic status) {
    final value = _getValue(status).toLowerCase();
    switch (value) {
      case 'locked':
        return 'Đã khóa';
      case 'unlocked':
        return 'Đã mở khóa';
      case 'open':
        return 'Đang mở';
      case 'closed':
        return 'Đã đóng';
      case 'unknown':
        return 'Không xác định';
      case 'error':
        return 'Lỗi';
      case 'opening':
        return 'Đang mở...';
      case 'closing':
        return 'Đang đóng...';
      case 'offline':
        return 'Ngoại tuyến';
      default:
        return value;
    }
  }

  static String translateItemType(dynamic type) {
    final value = _getValue(type).toUpperCase();
    switch (value) {
      case 'FOOD':
        return 'Thực phẩm';
      case 'OTHER':
        return 'Khác';
      default:
        return value;
    }
  }

  static String translateFeeBlockUnit(dynamic unit) {
    final value = _getValue(unit).toUpperCase();
    switch (value) {
      case 'MINUTE':
        return 'phút';
      case 'HOUR':
        return 'giờ';
      case 'DAY':
        return 'ngày';
      case 'WEEK':
        return 'tuần';
      case 'MONTH':
        return 'tháng';
      default:
        return value.toLowerCase();
    }
  }

  static String _getValue(dynamic input) {
    if (input == null) return '';
    if (input is Enum) return input.name;
    return input.toString();
  }
}

extension EnumTranslationExtension on Enum {
  String get vi {
    if (this is LogisticsType)
      return EnumTranslator.translateLogisticsType(this);
    if (this is OrderStatus) return EnumTranslator.translateOrderStatus(this);
    if (this is OrderDetailStatus)
      return EnumTranslator.translateOrderDetailStatus(this);
    if (this is PaymentStatus)
      return EnumTranslator.translatePaymentStatus(this);
    if (this is TransactionType)
      return EnumTranslator.translateTransactionType(this);
    if (this is TransactionStatus)
      return EnumTranslator.translateTransactionStatus(this);
    if (this is OrderType) return EnumTranslator.translateOrderType(this);
    if (this is ItemType) return EnumTranslator.translateItemType(this);
    if (this is FeeBlockUnit) return EnumTranslator.translateFeeBlockUnit(this);
    return name;
  }
}
