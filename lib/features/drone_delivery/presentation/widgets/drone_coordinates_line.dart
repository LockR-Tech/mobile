import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_route_geometry.dart';
import 'package:url_launcher/url_launcher.dart';

/// Google Maps ghim đúng điểm toạ độ (có địa chỉ thực tế bên dưới).
Uri droneGoogleMapsUri(double latitude, double longitude) => Uri.parse(
  'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
);

/// Một dòng toạ độ: bấm vào số mở Google Maps tại điểm đó, nút bên phải copy nguyên chuỗi.
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

  Future<void> _openMap(BuildContext context) async {
    final opened = await launchUrl(
      droneGoogleMapsUri(latitude, longitude),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được Google Maps.')),
      );
    }
  }

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã copy toạ độ $text')),
      );
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
                    'Vị trí drone · $note',
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Copy toạ độ',
            visualDensity: VisualDensity.compact,
            icon: const Icon(LucideIcons.copy, size: 18),
            onPressed: () => _copy(context, text),
          ),
        ],
      ),
    );
  }
}
