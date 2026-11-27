import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_route_geometry.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_laundry_locker/core/presentation/pages/directions_map_page.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';
import 'package:smart_laundry_locker/core/services/platform_info.dart';

/// Mở bản đồ chỉ đường TRONG APP tới một toạ độ (giống chỉ đường tới tủ của đơn thuê / gửi) —
/// không nhảy sang Google Maps (F3-G16). Trang chỉ đường vẫn có nút mở app bản đồ của máy nếu
/// người dùng muốn dẫn đường từng ngã rẽ.
void openInAppDirections(
  BuildContext context, {
  required double latitude,
  required double longitude,
  required String title,
  String? subtitle,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => DirectionsMapPage(
        destination: LatLng(latitude, longitude),
        title: title,
        subtitle: subtitle,
      ),
    ),
  );
}

/// Một dòng toạ độ: bấm vào số mở bản đồ trong app tại điểm đó, nút bên phải copy nguyên chuỗi.
class DroneCoordinatesLine extends StatelessWidget {
  const DroneCoordinatesLine({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.note,
  });

  final double latitude;
  final double longitude;

  /// Số lấy từ đâu (drone gửi về lúc…, mô phỏng, tại tủ nhận…).
  final String note;

  void _openMap(BuildContext context) {
    openInAppDirections(
      context,
      latitude: latitude,
      longitude: longitude,
      title: droneCoordinateLabel(latitude, longitude),
      subtitle: context.l10n.clDronePosition(note),
    );
  }

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (PlatformInfo.systemShowsCopyConfirmation) return; // Android 13+ đã tự báo "Đã sao chép".
    if (context.mounted) {
      SmartDialog.showToast(context.l10n.clCopied(text));
    }
  }

  @override
  Widget build(BuildContext context) {
    // `vĩ độ, kinh độ` — đúng dạng dán thẳng vào ô tìm kiếm Google Maps.
    final text = droneCoordinateLabel(latitude, longitude);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.locateFixed, size: 18, color: Color(0xFF334155)),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: () => _openMap(context),
              borderRadius: BorderRadius.circular(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    key: const ValueKey('drone-coordinates-text'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AISLShadcnTheme.navyAccent,
                      decoration: TextDecoration.underline,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.clDronePosition(note),
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: context.l10n.clCopyCoords,
            visualDensity: VisualDensity.compact,
            icon: const Icon(LucideIcons.copy, size: 18),
            onPressed: () => _copy(context, text),
          ),
        ],
      ),
    );
  }
}

/// Nhãn nguồn toạ độ của một mốc hành trình (`locationSource` của order-service).
String journeyLocationSourceLabel(String? source) => switch (source) {
  'PICKUP_ADDRESS' => L10n.current.clPickupPin,
  'TECHNICIAN' => L10n.current.clTechnician,
  'SOURCE_LOCKER' => L10n.current.clSourceLocker,
  'DRONE' => L10n.current.clDroneGps,
  'DRONE_SIMULATED' => L10n.current.clDroneSim,
  'DESTINATION_LOCKER' => L10n.current.clDestination,
  'ESTIMATED_ROUTE' => L10n.current.clEstimatedRoute,
  _ => L10n.current.clAtEvent,
};

/// Dòng toạ độ gọn dưới một mốc hành trình: kiện ở đâu lúc mốc xảy ra. Bấm mở bản đồ trong app,
/// giữ lâu để copy `vĩ độ, kinh độ`.
class JourneyLocationLine extends StatelessWidget {
  const JourneyLocationLine({
    super.key,
    required this.latitude,
    required this.longitude,
    this.source,
  });

  final double latitude;
  final double longitude;
  final String? source;

  @override
  Widget build(BuildContext context) {
    final text = droneCoordinateLabel(latitude, longitude);
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: InkWell(
        key: const ValueKey('journey-location'),
        borderRadius: BorderRadius.circular(6),
        onTap: () => openInAppDirections(
          context,
          latitude: latitude,
          longitude: longitude,
          title: journeyLocationSourceLabel(source),
          subtitle: text,
        ),
        onLongPress: () async {
          await Clipboard.setData(ClipboardData(text: text));
          if (PlatformInfo.systemShowsCopyConfirmation) return; // Android 13+ đã tự báo "Đã sao chép".
          if (context.mounted) {
            SmartDialog.showToast(context.l10n.clCopied(text));
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.mapPin, size: 12, color: Color(0xFF64748B)),
            const SizedBox(width: 4),
            Flexible(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: text,
                      style: const TextStyle(
                        color: AISLShadcnTheme.navyAccent,
                        decoration: TextDecoration.underline,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    TextSpan(text: ' · ${journeyLocationSourceLabel(source)}'),
                  ],
                ),
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
