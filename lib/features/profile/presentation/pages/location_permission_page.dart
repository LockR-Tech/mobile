import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

/// Trạng thái truy cập vị trí của app, gộp từ dịch vụ định vị + quyền.
enum LocationAccess {
  /// Đang kiểm tra.
  unknown,

  /// Máy tắt định vị (GPS) — có quyền cũng không lấy được vị trí.
  serviceDisabled,

  /// Đã cấp quyền (khi dùng app hoặc luôn luôn).
  granted,

  /// Chưa cấp / đã từ chối — app còn hỏi lại được.
  denied,

  /// Từ chối vĩnh viễn — chỉ bật lại được trong cài đặt hệ thống.
  deniedForever,
}

LocationAccess resolveLocationAccess({
  required bool serviceEnabled,
  required LocationPermission permission,
}) {
  switch (permission) {
    case LocationPermission.deniedForever:
      return LocationAccess.deniedForever;
    case LocationPermission.denied:
    case LocationPermission.unableToDetermine:
      return LocationAccess.denied;
    case LocationPermission.whileInUse:
    case LocationPermission.always:
      return serviceEnabled
          ? LocationAccess.granted
          : LocationAccess.serviceDisabled;
  }
}

String locationAccessLabel(LocationAccess access) {
  switch (access) {
    case LocationAccess.unknown:
      return 'Đang kiểm tra...';
    case LocationAccess.serviceDisabled:
      return 'Định vị trên máy đang tắt';
    case LocationAccess.granted:
      return 'Đã cấp quyền vị trí';
    case LocationAccess.denied:
      return 'Chưa cấp quyền vị trí';
    case LocationAccess.deniedForever:
      return 'Đã từ chối quyền vị trí';
  }
}

/// "Cài đặt → Vị trí": cho biết app đã có quyền vị trí chưa và đưa người dùng
/// tới đúng chỗ bật (hộp thoại xin quyền hoặc cài đặt hệ thống). Vị trí dùng
/// để tìm tủ gần, chỉ đường tới tủ và gắn toạ độ vào ảnh báo sự cố.
class LocationPermissionPage extends StatefulWidget {
  const LocationPermissionPage({super.key});

  @override
  State<LocationPermissionPage> createState() => _LocationPermissionPageState();
}

class _LocationPermissionPageState extends State<LocationPermissionPage>
    with WidgetsBindingObserver {
  LocationAccess _access = LocationAccess.unknown;
  LocationPermission? _permission;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Quay lại từ cài đặt hệ thống ⇒ đọc lại trạng thái.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      final permission = await Geolocator.checkPermission();
      if (!mounted) return;
      setState(() {
        _permission = permission;
        _access = resolveLocationAccess(
          serviceEnabled: serviceEnabled,
          permission: permission,
        );
      });
    } catch (e) {
      debugPrint('LocationPermissionPage: không đọc được quyền vị trí: $e');
      if (!mounted) return;
      setState(() => _access = LocationAccess.denied);
    }
  }

  Future<void> _requestPermission() async {
    setState(() => _busy = true);
    try {
      await Geolocator.requestPermission();
    } catch (e) {
      debugPrint('LocationPermissionPage: requestPermission lỗi: $e');
    }
    await _refresh();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _openAppSettings() async {
    final opened = await _safeOpen(Geolocator.openAppSettings);
    if (!opened) {
      SmartDialog.showToast(
        'Không mở được cài đặt. Vào Cài đặt của máy → Ứng dụng → Lock.R → Quyền để bật Vị trí.',
      );
    }
  }

  Future<void> _openLocationSettings() async {
    final opened = await _safeOpen(Geolocator.openLocationSettings);
    if (!opened) {
      SmartDialog.showToast('Không mở được cài đặt định vị của máy.');
    }
  }

  Future<bool> _safeOpen(Future<bool> Function() open) async {
    if (kIsWeb) return false;
    try {
      return await open();
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pageBg,
      body: Column(
        children: [
          BrandHeroHeader(
            title: 'Vị trí',
            subtitle: 'Quyền truy cập vị trí của ứng dụng',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                _buildStatusCard(),
                const SizedBox(height: 16),
                _buildUsageCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final granted = _access == LocationAccess.granted;
    final color = switch (_access) {
      LocationAccess.granted => const Color(0xFF16A34A),
      LocationAccess.unknown => const Color(0xFF64748B),
      _ => const Color(0xFFDC2626),
    };
    final detail = switch (_access) {
      LocationAccess.unknown => '',
      LocationAccess.granted => _permission == LocationPermission.always
          ? 'Ứng dụng được dùng vị trí mọi lúc.'
          : 'Ứng dụng được dùng vị trí khi đang mở.',
      LocationAccess.serviceDisabled =>
        'Bật Định vị (GPS) trong cài đặt của máy để ứng dụng lấy được vị trí.',
      LocationAccess.denied =>
        'Cấp quyền để tìm tủ gần bạn và chỉ đường tới tủ.',
      LocationAccess.deniedForever =>
        'Bạn đã chặn quyền vị trí. Mở cài đặt ứng dụng để bật lại.',
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  granted ? LucideIcons.mapPinCheck : LucideIcons.mapPinOff,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  locationAccessLabel(_access),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Kiểm tra lại',
                onPressed: _refresh,
                icon: const Icon(LucideIcons.refreshCw, size: 18),
              ),
            ],
          ),
          if (detail.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              detail,
              style: TextStyle(fontSize: 13.5, color: context.textMuted),
            ),
          ],
          if (_access == LocationAccess.denied) ...[
            const SizedBox(height: 14),
            _actionButton('Cấp quyền vị trí', _busy ? null : _requestPermission),
          ],
          if (_access == LocationAccess.deniedForever) ...[
            const SizedBox(height: 14),
            _actionButton('Mở cài đặt ứng dụng', _openAppSettings),
          ],
          if (_access == LocationAccess.serviceDisabled) ...[
            const SizedBox(height: 14),
            _actionButton('Bật định vị', _openLocationSettings),
          ],
          if (granted) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: _openAppSettings,
              child: const Text('Thay đổi trong cài đặt hệ thống'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionButton(String label, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AISLShadcnTheme.navyPrimary,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildUsageCard() {
    Widget row(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AISLShadcnTheme.navyPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13.5, color: context.textMuted),
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lock.R dùng vị trí để',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          row(LucideIcons.locateFixed, 'Tìm cửa hàng / tủ gần bạn'),
          row(LucideIcons.navigation, 'Chỉ đường tới tủ'),
          row(LucideIcons.camera, 'Gắn toạ độ vào ảnh khi báo sự cố'),
        ],
      ),
    );
  }
}
