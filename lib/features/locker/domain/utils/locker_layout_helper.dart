import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

/// Helper chuẩn hoá và đồng bộ sơ đồ tủ vật lý, phân loại ô và trạng thái cửa/hệ thống
/// giữa trang hiển thị Tủ Kiosk (StoreLockersPage) và trang Báo cáo sự cố (CreateReportPage).
class LockerLayoutHelper {
  LockerLayoutHelper._();

  /// Chuẩn hoá toàn bộ layout Map nhận được từ API hoặc event bus
  static Map<String, dynamic> enrichLayout(Map<String, dynamic> raw) {
    if (raw.isEmpty) return raw;
    final enriched = Map<String, dynamic>.from(raw);
    final rawCells = raw['cells'] as List?;
    if (rawCells != null) {
      enriched['cells'] = enrichCells(rawCells);
    }
    return enriched;
  }

  /// Chuẩn hoá danh sách ô tủ
  static List<Map<String, dynamic>> enrichCells(List rawCells) {
    final enrichedCells = rawCells.map((c) {
      if (c is! Map) return <String, dynamic>{};
      final map = Map<String, dynamic>.from(c);
      final boxNum = (map['boxNumber'] as num?)?.toInt();
      final col = (map['colIndex'] as num?)?.toInt();
      final cellType = (map['cellType'] as String?)?.toUpperCase();

      // Ô vali (XL, ô #1, cột 0): là ô thường (thuê tủ lưu đồ lớn, KHÔNG PHẢI drone)
      if (cellType == 'XL' || boxNum == 1 || col == 0) {
        map['cellType'] = 'XL';
        map['isDrone'] = false;
      } else if (cellType == 'DRONE' ||
          (cellType == null && (boxNum == 2 || boxNum == 3))) {
        map['cellType'] = 'DRONE';
        map['isDrone'] = true;
      } else {
        map['isDrone'] = false;
      }
      return map;
    }).toList();

    // Sắp xếp theo boxNumber tăng dần theo mặc định
    enrichedCells.sort((a, b) =>
        ((a['boxNumber'] as num?) ?? 0).compareTo((b['boxNumber'] as num?) ?? 0));

    return enrichedCells;
  }

  /// Kiểm tra ô vali lớn XL
  static bool isXl(Map<String, dynamic> cell) {
    final cellType = (cell['cellType'] as String?)?.toUpperCase();
    final boxNum = (cell['boxNumber'] as num?)?.toInt();
    final col = (cell['colIndex'] as num?)?.toInt();
    return cellType == 'XL' || boxNum == 1 || col == 0;
  }

  /// Kiểm tra ô Drone nóc tủ
  static bool isDrone(Map<String, dynamic> cell) {
    if (isXl(cell)) return false;
    final cellType = (cell['cellType'] as String?)?.toUpperCase();
    final boxNum = (cell['boxNumber'] as num?)?.toInt();
    return cell['isDrone'] == true ||
        cellType == 'DRONE' ||
        ((cellType == null || cellType.isEmpty) && (boxNum == 2 || boxNum == 3));
  }

  /// Trạng thái mở cửa
  static bool isDoorOpen(Map<String, dynamic> cell) {
    return cell['doorOpen'] == true ||
        ((cell['hwState'] as String?)?.toUpperCase() == 'OPEN');
  }

  /// Trạng thái hoạt động của ô
  static String status(Map<String, dynamic> cell) {
    return ((cell['status'] as String?) ?? 'AVAILABLE').toUpperCase();
  }

  /// Nhãn loại ô cho người dùng
  static String typeLabel(Map<String, dynamic> cell) {
    if (isDrone(cell)) return 'Drone (Nóc tủ)';
    if (isXl(cell)) return 'Vali (XL - Cột 1)';
    return 'Tiêu chuẩn (Vừa)';
  }

  /// Nhãn trạng thái hiển thị
  static String statusLabel(Map<String, dynamic> cell) {
    final st = status(cell);
    return switch (st) {
      'AVAILABLE' => isDrone(cell) ? 'Nhận Drone' : 'Sẵn sàng',
      'OCCUPIED' || 'IN_USE' => 'Đang dùng',
      'RESERVED' => 'Đã đặt',
      'FAULT' => 'Hỏng',
      'CLEANING' => 'Bảo trì',
      _ => st,
    };
  }

  /// Icon nhận diện cho ô
  static IconData cellIcon(Map<String, dynamic> cell) {
    if (isDrone(cell)) return Icons.flight_rounded;
    if (isXl(cell)) return LucideIcons.luggage;
    return LucideIcons.box;
  }

  /// Màu trạng thái chính
  static Color statusColor(String? statusStr) {
    return switch (statusStr?.toUpperCase()) {
      'AVAILABLE' => AislBrand.cyan,
      'OCCUPIED' || 'IN_USE' => const Color(0xFF64748B),
      'RESERVED' => const Color(0xFFD97706),
      'FAULT' => const Color(0xFFDC2626),
      'CLEANING' => const Color(0xFF3B82F6),
      _ => const Color(0xFF94A3B8),
    };
  }

  /// Gradient nền đồng bộ 100% với sơ đồ tủ vật lý
  static LinearGradient bgGradient(Map<String, dynamic> cell) {
    final st = status(cell);
    final drone = isDrone(cell);
    final xl = isXl(cell);

    if (drone && st == 'AVAILABLE') {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF818CF8), Color(0xFF4F46E5)],
      );
    }
    return switch (st) {
      'AVAILABLE' when xl => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF06B6D4), Color(0xFF0284C7)],
        ),
      'AVAILABLE' => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
        ),
      'OCCUPIED' || 'IN_USE' => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF1F5F9), Color(0xFFCBD5E1)],
        ),
      'RESERVED' when drone => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF1F5F9), Color(0xFFCBD5E1)],
        ),
      'RESERVED' => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)],
        ),
      'FAULT' => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFCA5A5), Color(0xFFDC2626)],
        ),
      'CLEANING' => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF93C5FD), Color(0xFF3B82F6)],
        ),
      _ => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE5E7EB), Color(0xFF9CA3AF)],
        ),
    };
  }
}
