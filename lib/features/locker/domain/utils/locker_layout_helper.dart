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

  /// Chuẩn hoá danh sách ô tủ. Loại ô lấy NGUYÊN từ `cellType` của backend
  /// (STANDARD / DRONE / XL — `CellType` ở locker-service); không suy ra từ vị
  /// trí cột hay số ô. Thiếu `cellType` (dữ liệu cũ) thì chỉ ô `size == XL` là
  /// ô vali, còn lại là ô thường — không bao giờ tự coi là ô drone.
  static List<Map<String, dynamic>> enrichCells(List rawCells) {
    final enrichedCells = rawCells.map((c) {
      if (c is! Map) return <String, dynamic>{};
      final map = Map<String, dynamic>.from(c);
      final type = cellType(map);
      map['cellType'] = type;
      map['isDrone'] = type == 'DRONE';
      return map;
    }).toList();

    // Sắp xếp theo boxNumber tăng dần theo mặc định
    enrichedCells.sort((a, b) =>
        ((a['boxNumber'] as num?) ?? 0).compareTo((b['boxNumber'] as num?) ?? 0));

    return enrichedCells;
  }

  /// Loại ô đã chuẩn hoá: `cellType` của backend, thiếu thì suy từ `size`.
  static String cellType(Map<String, dynamic> cell) {
    final raw = (cell['cellType'] as String?)?.trim().toUpperCase() ?? '';
    if (raw.isNotEmpty) return raw;
    final size = (cell['size'] as String?)?.trim().toUpperCase();
    return size == 'XL' ? 'XL' : 'STANDARD';
  }

  /// Ô vali lớn XL — chỉ theo loại ô backend trả.
  static bool isXl(Map<String, dynamic> cell) => cellType(cell) == 'XL';

  /// Ô nhận hàng drone — chỉ theo loại ô backend trả.
  static bool isDrone(Map<String, dynamic> cell) => cellType(cell) == 'DRONE';

  /// Lý do không cho đặt ô ở tủ này; `null` = đặt được.
  ///
  /// [online] là cờ `online` của `GET /api/lockers` hoặc của layout (`null` khi
  /// server cũ chưa trả — không tự đoán là mất kết nối).
  static String? bookingBlockReason({String? status, bool? online}) {
    final st = (status ?? 'ACTIVE').trim().toUpperCase();
    if (online == false || st == 'DISCONNECTED') {
      return 'Tủ đang mất kết nối nên chưa đặt được ô. Vui lòng chọn tủ khác hoặc thử lại sau.';
    }
    if (st == 'MAINTENANCE') {
      return 'Tủ đang bảo trì nên tạm ngưng nhận đơn. Vui lòng chọn tủ khác.';
    }
    if (st != 'ACTIVE') {
      return 'Tủ đang tạm ngưng hoạt động nên chưa đặt được ô.';
    }
    return null;
  }

  /// Đếm ô theo loại cho thẻ thông tin tủ (bản đồ): ô thường theo kích cỡ, ô
  /// vali XL, ô drone. Thứ tự: S, M, L, XL, Drone, khác.
  static List<LockerCellGroupCount> summarizeCells(List rawCells) {
    final groups = <String, LockerCellGroupCount>{};
    for (final c in rawCells) {
      if (c is! Map) continue;
      final cell = Map<String, dynamic>.from(c);
      final type = cellType(cell);
      final size = (cell['size'] as String?)?.trim().toUpperCase() ?? '';
      final key = switch (type) {
        'DRONE' => 'DRONE',
        'XL' => 'XL',
        _ => switch (size) {
          'SMALL' || 'S' => 'SMALL',
          'MEDIUM' || 'M' => 'MEDIUM',
          'LARGE' || 'L' => 'LARGE',
          _ => 'STANDARD',
        },
      };
      final available = status(cell) == 'AVAILABLE' ? 1 : 0;
      final prev = groups[key];
      groups[key] = LockerCellGroupCount(
        key: key,
        label: _groupLabels[key] ?? key,
        available: (prev?.available ?? 0) + available,
        total: (prev?.total ?? 0) + 1,
      );
    }
    final order = _groupLabels.keys.toList();
    final result = groups.values.toList()
      ..sort((a, b) => order.indexOf(a.key).compareTo(order.indexOf(b.key)));
    return result;
  }

  static const _groupLabels = <String, String>{
    'SMALL': 'Ô nhỏ (S)',
    'MEDIUM': 'Ô vừa (M)',
    'LARGE': 'Ô lớn (L)',
    'STANDARD': 'Ô thường',
    'XL': 'Ô vali (XL)',
    'DRONE': 'Ô drone',
  };

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
    if (isXl(cell)) return 'Vali (XL)';
    return 'Tiêu chuẩn';
  }

  /// Nhãn trạng thái hiển thị
  static String statusLabel(Map<String, dynamic> cell) {
    final st = status(cell);
    return switch (st) {
      'AVAILABLE' => isDrone(cell) ? 'Nhận Drone' : 'Sẵn sàng',
      'OCCUPIED' || 'IN_USE' => 'Đang dùng',
      'RESERVED' => 'Đã đặt',
      'FAULT' => 'Hỏng',
      // Khách báo sự cố: tạm ngưng nhận đơn mới, chờ KTV kiểm tra.
      'PENDING_CHECK' => 'Chờ kiểm tra',
      'CLEANING' => 'Bảo trì',
      'OUT_OF_SERVICE' => 'Ngưng dùng',
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
      'PENDING_CHECK' => const Color(0xFFEA580C),
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
      'PENDING_CHECK' => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFDBA74), Color(0xFFEA580C)],
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

/// Số ô (trống / tổng) của một nhóm loại ô trong tủ.
class LockerCellGroupCount {
  const LockerCellGroupCount({
    required this.key,
    required this.label,
    required this.available,
    required this.total,
  });

  final String key;
  final String label;
  final int available;
  final int total;
}
