import '../enums/app_enums.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

class EnumTranslator {
  static String translateLogisticsType(dynamic type) {
    if (type == 0 || type == '0') return L10n.current.enumLockerToLocker;
    if (type == 1 || type == '1') return L10n.current.enumHomeToLocker;
    final value = _getValue(type);
    switch (value) {
      case 'LOCKER_TO_LOCKER':
        return L10n.current.enumLockerToLocker;
      case 'HOME_TO_LOCKER':
        return L10n.current.enumHomeToLocker;
      default:
        return value;
    }
  }

  static String translateOrderStatus(dynamic status) {
    final value = _getValue(status);
    switch (value) {
      case 'PENDING':
        return L10n.current.enumPendingProcessing;
      case 'AWAITING_COURIER':
        return L10n.current.enumAwaitingCourier;
      case 'AWAITING_PICKUP':
        return L10n.current.enumAwaitingPickup;
      case 'ACTIVE':
        return L10n.current.enumActive;
      case 'COMPLETED':
        return L10n.current.enumCompleted;
      case 'LOCKED_BY_BALANCE':
        return L10n.current.enumLockedByBalance;
      case 'CANCELLED':
        return L10n.current.enumCancelled;
      default:
        return value;
    }
  }

  static String translateOrderDetailStatus(dynamic status) {
    final value = _getValue(status);
    switch (value) {
      case 'PENDING':
        return L10n.current.enumPending;
      case 'AWAITING_COURIER':
        return L10n.current.enumAwaitingCourier;
      case 'AWAITING_PICKUP':
        return L10n.current.enumAwaitingPickup;
      case 'AWAITING_CONFIRM_DEPOSIT':
        return L10n.current.enumAwaitingDropoffConfirm;
      case 'IN_TRANSIT':
        return L10n.current.enumInTransit;
      case 'OCCUPIED':
        return L10n.current.enumInUse;
      case 'COMPLETED':
        return L10n.current.commonDone;
      case 'OVERDUE':
        return L10n.current.enumOverdue;
      case 'COLLECTING':
        return L10n.current.enumConsolidating;
      case 'COLLECTED':
        return L10n.current.enumPickedUp;
      case 'AWAITING_DROP':
        return L10n.current.enumAwaitingDropoff;
      case 'CANCELLED':
        return L10n.current.enumCancelled;
      default:
        return value;
    }
  }

  static String translatePaymentStatus(dynamic status) {
    final value = _getValue(status);
    switch (value) {
      case 'PENDING':
        return L10n.current.enumAwaitingPayment;
      case 'UNPAID':
        return L10n.current.enumUnpaid;
      case 'PAID':
        return L10n.current.enumPaid;
      case 'PARTIAL_PAID':
        return L10n.current.enumPartiallyPaid;
      case 'REFUND_PENDING':
        return L10n.current.enumAwaitingRefund;
      case 'REFUNDED':
        return L10n.current.enumRefunded;
      default:
        return value.isEmpty ? L10n.current.commonUndetermined : value;
    }
  }

  static String translateTransactionType(dynamic type) {
    final value = _getValue(type);
    switch (value) {
      case 'DEPOSIT':
        return L10n.current.enumTopUp;
      case 'RENTAL_DEDUCTION':
        return L10n.current.enumRentalFee;
      case 'LOGISTICS_DEDUCTION':
        return L10n.current.enumShippingFee;
      case 'OVERDUE_PENALTY':
        return L10n.current.enumOverdueFee;
      case 'REFUND':
        return L10n.current.enumRefund;
      case 'TOP_UP':
        return L10n.current.enumWalletTopUp;
      case 'WITHDRAW':
        return L10n.current.enumWithdraw;
      default:
        return value;
    }
  }

  static String translateTransactionStatus(dynamic status) {
    final value = _getValue(status);
    switch (value) {
      case 'SUCCESS':
        return L10n.current.commonSuccess;
      case 'FAILED':
        return L10n.current.commonFailed;
      case 'PENDING':
        return L10n.current.commonPending;
      case 'CANCELLED':
        return L10n.current.enumCancelled;
      default:
        return value;
    }
  }

  static String translateOrderType(dynamic type) {
    final value = _getValue(type);
    switch (value) {
      case 'LOGISTICS':
        return L10n.current.enumShippingService;
      case 'PERSONAL_RENTAL':
        return L10n.current.enumPersonalRental;
      default:
        return value;
    }
  }

  static String translateLockerStatus(dynamic status) {
    final value = _getValue(status);
    switch (value) {
      case 'AVAILABLE':
        return L10n.current.enumReady;
      case 'OCCUPIED':
        return L10n.current.enumInUse;
      case 'RESERVED':
        return L10n.current.enumReserved;
      case 'LOCKED_BY_BALANCE':
        return L10n.current.enumLockedBalanceShort;
      case 'FAULT':
        return L10n.current.enumFaulty;
      case 'PENDING_CHECK':
        return L10n.current.enumPendingCheck;
      case 'MAINTENANCE':
        return L10n.current.enumMaintenance;
      case 'INITIALIZING':
        return L10n.current.enumInitializing;
      default:
        return value;
    }
  }

  static String translateHwStatus(dynamic status) {
    final value = _getValue(status).toLowerCase();
    switch (value) {
      case 'locked':
        return L10n.current.enumLocked;
      case 'unlocked':
        return L10n.current.enumUnlocked;
      case 'open':
        return L10n.current.enumOpen;
      case 'closed':
        return L10n.current.enumClosed;
      case 'unknown':
        return L10n.current.commonUnknown;
      case 'error':
        return L10n.current.commonError;
      case 'opening':
        return L10n.current.enumOpening;
      case 'closing':
        return L10n.current.enumClosing;
      case 'offline':
        return L10n.current.enumOffline;
      default:
        return value;
    }
  }

  static String translateItemType(dynamic type) {
    final value = _getValue(type).toUpperCase();
    switch (value) {
      case 'FOOD':
        return L10n.current.enumFood;
      case 'OTHER':
        return L10n.current.enumOther;
      default:
        return value;
    }
  }

  static String translateFeeBlockUnit(dynamic unit) {
    final value = _getValue(unit).toUpperCase();
    switch (value) {
      case 'MINUTE':
        return L10n.current.unitMinute;
      case 'HOUR':
        return L10n.current.unitHour;
      case 'DAY':
        return L10n.current.unitDay;
      case 'WEEK':
        return L10n.current.unitWeek;
      case 'MONTH':
        return L10n.current.unitMonth;
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
