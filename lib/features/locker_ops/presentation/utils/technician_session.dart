import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_laundry_locker/core/media/media.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/services/session_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/profile_provider.dart';

/// Ảnh hiện trường KTV vừa gắn vào phiếu (theo reportId) để sheet "Kiểm tra ô"
/// và sheet "Nghiệm thu" thấy ngay mà không chờ tải lại. Thuộc phiên đăng nhập
/// hiện tại — xoá khi đăng xuất.
final Map<int, List<ReportAttachment>> technicianInspectionCache = {};

/// Khoá SharedPreferences của bản cũ (lưu gia hạn SLA trên máy) — không còn
/// dùng, chỉ dọn khi đăng xuất.
const _legacySlaExtensionsKey = 'locker_sla_extensions_v1';

/// Hộp đăng xuất nói "kết thúc ca trực" ⇒ tắt ca trên server trước khi xoá phiên: ca KTV (locker-service)
/// và ca nhận việc lấy hàng drone (order-service). Trước đây chỉ xoá phiên, KTV đã đăng xuất vẫn được mời
/// lấy hàng, lời mời hết hạn rồi khoá mời lại người đó 10 phút (test 2026-10-29). Lỗi mạng không chặn đăng
/// xuất.
Future<void> endTechnicianShiftQuietly({
  LockerOpsService? service,
  required bool drone,
}) async {
  final ops = service ?? LockerOpsService();
  try {
    await ops.updateTechnicianPresence(onDuty: false);
  } catch (_) {}
  if (!drone) return;
  try {
    await ops.updateDroneTechnicianPresence(onDuty: false);
  } catch (_) {}
}

/// Đăng xuất KTV (tủ hoặc drone): thu hồi phiên + gỡ push qua
/// [SessionService.logout], xoá dữ liệu tạm của phiên, reset hồ sơ rồi về màn
/// đăng nhập.
Future<void> logoutTechnician(BuildContext context, {bool drone = false}) async {
  ProfileProvider? profile;
  try {
    profile = context.read<ProfileProvider>();
  } catch (_) {
    // Màn được mở ngoài cây Provider (vd. test) ⇒ không có hồ sơ để reset.
  }
  await endTechnicianShiftQuietly(drone: drone);
  await SessionService.logout();
  technicianInspectionCache.clear();
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacySlaExtensionsKey);
  } catch (_) {
    // Không dọn được khoá cũ thì thôi — app không còn đọc khoá này.
  }
  profile?.reset();
  if (context.mounted) context.go(AppRouter.onboarding);
}
