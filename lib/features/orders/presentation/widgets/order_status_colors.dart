import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/core/utils/enum_translator.dart';

/// Helper class chứa mapping màu sắc cho các status enums
/// Mỗi status có màu riêng biệt để dễ nhận diện.
class OrderStatusColors {
  OrderStatusColors._();

  // ==================== OrderStatus ====================
  // PENDING, AWAITING_COURIER, AWAITING_PICKUP, ACTIVE, COMPLETED, LOCKED_BY_BALANCE, CANCELLED

  static Color orderStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return const Color(0xFFED6C02); // Orange
      case 'AWAITING_COURIER':
        return const Color(0xFF7B1FA2); // Purple
      case 'AWAITING_PICKUP':
        return const Color(0xFF0288D1); // Light Blue
      case 'ACTIVE':
        return const Color(0xFF2E7D32); // Green
      case 'COMPLETED':
        return const Color(0xFF455A64); // Blue Grey
      case 'LOCKED_BY_BALANCE':
        return const Color(0xFFD32F2F); // Red
      case 'CANCELLED':
        return const Color(0xFF757575); // Grey
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  static Color orderStatusBgColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return AISLShadcnTheme.navySurface;
      case 'AWAITING_COURIER':
        return const Color(0xFFF3E5F5);
      case 'AWAITING_PICKUP':
        return const Color(0xFFE1F5FE);
      case 'ACTIVE':
        return const Color(0xFFE8F5E9);
      case 'COMPLETED':
        return const Color(0xFFECEFF1);
      case 'LOCKED_BY_BALANCE':
        return const Color(0xFFFFEBEE);
      case 'CANCELLED':
        return const Color(0xFFF5F5F5);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  static String orderStatusLabel(String status) {
    return EnumTranslator.translateOrderStatus(status);
  }

  // ==================== OrderDetailStatus ====================
  // PENDING, AWAITING_COURIER, AWAITING_PICKUP, IN_TRANSIT, OCCUPIED, COMPLETED, OVERDUE

  static Color detailStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return const Color(0xFFED6C02); // Orange
      case 'AWAITING_COURIER':
        return const Color(0xFF7B1FA2); // Purple
      case 'AWAITING_PICKUP':
        return const Color(0xFF0288D1); // Light Blue
      case 'IN_TRANSIT':
        return const Color(0xFF1565C0); // Blue
      case 'OCCUPIED':
        return const Color(0xFF2E7D32); // Green
      case 'COMPLETED':
        return const Color(0xFF455A64); // Blue Grey
      case 'OVERDUE':
        return const Color(0xFFD32F2F); // Red
      case 'AWAITING_DROP':
        return const Color(0xFFED6C02); // Orange
      case 'COLLECTING':
        return const Color(0xFFF9A825); // Yellow/Amber
      case 'COLLECTED':
        return const Color(0xFF00897B); // Teal
      case 'AWAITING_CONFIRM_DEPOSIT':
        return const Color(0xFF7CB342); // Light Green
      case 'CANCELLED':
        return const Color(0xFF757575); // Grey
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  static Color detailStatusBgColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return AISLShadcnTheme.navySurface;
      case 'AWAITING_COURIER':
        return const Color(0xFFF3E5F5);
      case 'AWAITING_PICKUP':
        return const Color(0xFFE1F5FE);
      case 'IN_TRANSIT':
        return const Color(0xFFE3F2FD);
      case 'OCCUPIED':
        return const Color(0xFFE8F5E9);
      case 'COMPLETED':
        return const Color(0xFFECEFF1);
      case 'OVERDUE':
        return const Color(0xFFFFEBEE);
      case 'AWAITING_DROP':
        return AISLShadcnTheme.navySurface;
      case 'COLLECTING':
        return const Color(0xFFFFFDE7);
      case 'COLLECTED':
        return const Color(0xFFE0F2F1);
      case 'AWAITING_CONFIRM_DEPOSIT':
        return const Color(0xFFF1F8E9);
      case 'CANCELLED':
        return const Color(0xFFF5F5F5);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  static String detailStatusLabel(String status) {
    return EnumTranslator.translateOrderDetailStatus(status);
  }

  // ==================== PaymentStatus ====================
  // PENDING, UNPAID, PAID, PARTIAL_PAID, REFUNDED

  static Color paymentStatusColor(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'PENDING':
        return const Color(0xFFED6C02); // Orange
      case 'UNPAID':
        return const Color(0xFFD32F2F); // Red
      case 'PAID':
        return const Color(0xFF2E7D32); // Green
      case 'PARTIAL_PAID':
        return const Color(0xFFE65100); // Deep Orange
      case 'REFUNDED':
        return const Color(0xFF0288D1); // Light Blue
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  static Color paymentStatusBgColor(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'PENDING':
        return AISLShadcnTheme.navySurface;
      case 'UNPAID':
        return const Color(0xFFFFEBEE);
      case 'PAID':
        return const Color(0xFFE8F5E9);
      case 'PARTIAL_PAID':
        return const Color(0xFFFBE9E7);
      case 'REFUNDED':
        return const Color(0xFFE1F5FE);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  static String paymentStatusLabel(String? status) {
    return EnumTranslator.translatePaymentStatus(status);
  }

  // ==================== Widgets ====================

  /// Widget badge hiển thị status
  static Widget statusBadge({
    required String label,
    required Color textColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Badge cho OrderStatus
  static Widget orderBadge(String status) {
    return statusBadge(
      label: orderStatusLabel(status),
      textColor: orderStatusColor(status),
      bgColor: orderStatusBgColor(status),
    );
  }

  /// Badge cho OrderDetailStatus
  static Widget detailBadge(String status) {
    return statusBadge(
      label: detailStatusLabel(status),
      textColor: detailStatusColor(status),
      bgColor: detailStatusBgColor(status),
    );
  }

  /// Badge cho PaymentStatus
  static Widget paymentBadge(String? status) {
    return statusBadge(
      label: paymentStatusLabel(status),
      textColor: paymentStatusColor(status),
      bgColor: paymentStatusBgColor(status),
    );
  }
}
