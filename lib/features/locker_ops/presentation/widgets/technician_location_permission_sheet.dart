import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hộp thoại giải thích (Pre-permission Rationale) xuất hiện khi Kỹ thuật viên
/// mở app lần đầu hoặc chuẩn bị vào ca trực.
///
/// Tuân thủ quy định Google Play & Apple App Store:
/// - Giải thích rõ mục đích: điều phối sự cố/drone gần nhất khi vào ca.
/// - Cam kết: chỉ truy cập vị trí khi đang trong ca, hết ca sẽ ngắt hoàn toàn.
/// - Không quản lý chấm công ca trực.
class TechnicianLocationPermissionSheet extends StatefulWidget {
  const TechnicianLocationPermissionSheet({super.key});

  /// Kiểm tra và hiển thị hộp thoại nếu KTV mở app lần đầu và chưa cấp quyền vị trí.
  static Future<void> checkAndPrompt(BuildContext context) async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final prompted =
          prefs.getBool('technician_location_permission_prompted') ?? false;
      if (prompted) return;

      if (!context.mounted) return;
      await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => const TechnicianLocationPermissionSheet(),
      );

      await prefs.setBool('technician_location_permission_prompted', true);
    } catch (_) {}
  }

  @override
  State<TechnicianLocationPermissionSheet> createState() =>
      _TechnicianLocationPermissionSheetState();
}

class _TechnicianLocationPermissionSheetState
    extends State<TechnicianLocationPermissionSheet> {
  bool _requesting = false;

  Future<void> _handleRequestPermission() async {
    setState(() => _requesting = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Quyền vị trí bị từ chối vĩnh viễn. Vui lòng mở Cài đặt để bật vị trí.',
              ),
              backgroundColor: Color(0xFFDC2626),
            ),
          );
          await Geolocator.openAppSettings();
        }
      }

      if (mounted) {
        Navigator.of(context).pop(
          permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always,
        );
      }
    } catch (_) {
      if (mounted) Navigator.of(context).pop(false);
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Header with Icon
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0077B6).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF0077B6),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quyền truy cập vị trí',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Dành cho tài khoản Kỹ thuật viên',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Text(
                'Để hệ thống điều phối chính xác sự cố trạm tủ và nhiệm vụ drone gần bạn nhất, ứng dụng cần truy cập vị trí thiết bị khi bạn đang trong ca làm việc.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: Color(0xFF334155),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _benefitRow(
              icon: Icons.near_me_rounded,
              color: const Color(0xFF10B981),
              title: 'Điều phối & Phân công theo vị trí',
              subtitle:
                  'Tự động gán phiếu xử lý, kiểm tra định kỳ và cứu hộ drone tại các tủ quanh bạn.',
            ),
            const SizedBox(height: 12),
            _benefitRow(
              icon: Icons.shield_outlined,
              color: const Color(0xFF0077B6),
              title: 'Tự động tắt khi hết ca trực',
              subtitle:
                  'Vị trí chỉ được truy cập khi bạn bật Vào ca. Khi Hết ca, định vị tự động tắt hoàn toàn để bảo vệ quyền riêng tư.',
            ),
            const SizedBox(height: 12),
            _benefitRow(
              icon: Icons.battery_charging_full_rounded,
              color: const Color(0xFFF59E0B),
              title: 'Tối ưu pin & dữ liệu nền',
              subtitle:
                  'Tần suất định vị tự động tối ưu theo khoảng cách di chuyển để không hao pin điện thoại.',
            ),
            const SizedBox(height: 24),
            // Actions
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0077B6),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _requesting ? null : _handleRequestPermission,
                child: _requesting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Cho phép truy cập vị trí',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _requesting ? null : () => Navigator.pop(context, false),
                child: const Text(
                  'Để sau',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _benefitRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

