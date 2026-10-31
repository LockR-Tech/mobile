import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_parcel.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_coordinates_line.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/order_milestone.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';

/// Khối dựng dùng chung cho hai màn chi tiết đơn: "Đơn của tôi" (người gửi) và
/// "Hàng chờ nhận" / "Đơn ủy quyền" (người nhận, người lấy hộ) — để hai màn
/// cùng nhãn, cùng định dạng, cùng kiểu dòng thời gian.

// ---- Nhãn / định dạng ----

/// Kích cỡ ô theo locker-service.
String boxSizeLabel(String? size) => switch ((size ?? '').toUpperCase()) {
  'SMALL' || 'S' => 'Nhỏ (S)',
  'MEDIUM' || 'M' => 'Vừa (M)',
  'LARGE' || 'L' => 'Lớn (L)',
  '' => '—',
  _ => size!,
};

/// Loại ô theo locker-service.
String boxTypeLabel(String? type) => switch ((type ?? '').toUpperCase()) {
  'STANDARD' => 'Ô thường',
  'XL' => 'Ô vali (XL)',
  'DRONE' => 'Ô drone',
  '' => '—',
  _ => type!,
};

/// `850 g` / `1,2 kg`.
String fmtWeightGrams(int grams) {
  if (grams < 1000) return '$grams g';
  final kg = grams / 1000;
  final text = kg == kg.roundToDouble()
      ? kg.toStringAsFixed(0)
      : kg.toStringAsFixed(kg * 10 == (kg * 10).roundToDouble() ? 1 : 2);
  return '${text.replaceAll('.', ',')} kg';
}

/// `850 m` / `1,2 km`.
String fmtDistanceMeters(int meters) {
  if (meters < 1000) return '$meters m';
  return '${(meters / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
}

String _fmtNumber(num value) {
  final s = value == value.roundToDouble()
      ? value.round().toString()
      : value.toString();
  return s.replaceAll('.', ',');
}

/// Màu chấm của một mốc theo mã.
Color milestoneColor(String? code) => switch (code) {
  'COMPLETED' || 'PAID' || 'PARCEL_RETURNED' => const Color(0xFF16A34A),
  'STORED' || 'READY_FOR_PICKUP' => const Color(0xFF0D9488),
  'DELEGATED' => const Color(0xFF7C3AED),
  'BLOCKED' || 'EXPIRED' || 'DROP_REPORTED' => const Color(0xFFEA580C),
  'FAILED' => const Color(0xFFDC2626),
  'CANCELED' => const Color(0xFF6B7280),
  _ => opsPrimary,
};

// ---- Mục chi tiết ----

/// Một mục của màn chi tiết: tiêu đề + khung các dòng. Không có dòng nào và
/// không có [footer] ⇒ không vẽ gì (không hiện mục rỗng).
class OrderDetailSection extends StatelessWidget {
  const OrderDetailSection({
    super.key,
    required this.title,
    required this.icon,
    this.rows = const [],
    this.footer,
  });

  final String title;
  final IconData icon;
  final List<Widget> rows;

  /// Nội dung đặt dưới khung (nút, dòng thời gian…).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty && footer == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OpsSectionLabel(title, icon: icon),
          if (rows.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: opsSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: opsBorder),
              ),
              child: Column(children: rows),
            ),
          if (footer != null) ...[
            if (rows.isNotEmpty) const SizedBox(height: 10),
            footer!,
          ],
        ],
      ),
    );
  }
}

/// Dòng liên hệ (SĐT / email): như [OpsInfoRow] kèm nút sao chép và — với số
/// điện thoại — nút gọi.
class OrderContactRow extends StatelessWidget {
  const OrderContactRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.phone = false,
    this.launcher,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool phone;

  /// Thay `url_launcher` (test).
  final Future<bool> Function(Uri uri)? launcher;

  Future<void> _call(BuildContext context) async {
    final digits = value.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: digits);
    var opened = false;
    try {
      opened = await (launcher ??
          (u) => launchUrl(u, mode: LaunchMode.externalApplication))(uri);
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Máy này không gọi điện được.')),
        );
    }
  }

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Đã sao chép $label')));
  }

  @override
  Widget build(BuildContext context) {
    Widget action(IconData icon, String tooltip, VoidCallback onTap) =>
        IconButton(
          onPressed: onTap,
          icon: Icon(icon, size: 16),
          color: opsPrimary,
          tooltip: tooltip,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Icon(icon, size: 16, color: opsMutedText),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: opsMutedText),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(width: 4),
          if (phone) action(LucideIcons.phone, 'Gọi $label', () => _call(context)),
          action(LucideIcons.copy, 'Sao chép $label', () => _copy(context)),
        ],
      ),
    );
  }
}

/// Các dòng "Kiện hàng" từ khai báo kiện; rỗng khi đơn không khai.
List<Widget> orderParcelRows(OrderParcel? parcel) {
  if (parcel == null) return const [];
  final size = droneParcelSizeLabel(
    parcel.lengthCm,
    parcel.widthCm,
    parcel.heightCm,
  );
  final weight = parcel.weightGrams != null
      ? fmtWeightGrams(parcel.weightGrams!)
      : parcel.actualWeight != null
      ? '${_fmtNumber(parcel.actualWeight!)} ${parcel.weightUnit ?? 'kg'}'
      : null;
  return [
    if (parcel.description != null)
      OpsInfoRow(
        icon: LucideIcons.package,
        label: 'Mô tả',
        value: parcel.description!,
      ),
    if (parcel.category != null)
      OpsInfoRow(
        icon: LucideIcons.tag,
        label: 'Loại hàng',
        value: droneParcelCategoryLabel(parcel.category),
      ),
    if (weight != null)
      OpsInfoRow(icon: LucideIcons.weight, label: 'Cân nặng', value: weight),
    if (size != null)
      OpsInfoRow(icon: LucideIcons.ruler, label: 'Kích thước', value: size),
    if (parcel.fragile != null)
      OpsInfoRow(
        icon: LucideIcons.wineOff,
        label: 'Hàng dễ vỡ',
        value: parcel.fragile! ? 'Có — nhẹ tay' : 'Không',
        valueColor: parcel.fragile! ? const Color(0xFFB45309) : null,
      ),
    if (parcel.declaredValue != null && parcel.declaredValue! > 0)
      OpsInfoRow(
        icon: LucideIcons.shieldCheck,
        label: 'Giá trị khai báo',
        value: fmtPrice(parcel.declaredValue),
      ),
    if (parcel.prohibitedItemsDeclaredAt != null)
      OpsInfoRow(
        icon: LucideIcons.badgeCheck,
        label: 'Cam kết không hàng cấm',
        value: fmtDateTime(parcel.prohibitedItemsDeclaredAt),
      ),
  ];
}

// ---- Dòng thời gian ----

/// Một nút của dòng thời gian dọc (chấm + đường nối + tiêu đề + giờ). Dùng chung
/// cho "Mốc thời gian", hành trình drone và "Lịch sử trạng thái".
class OrderTimelineTile extends StatelessWidget {
  const OrderTimelineTile({
    super.key,
    required this.title,
    required this.time,
    required this.color,
    required this.isLast,
    required this.isLatest,
    this.subtitle,
    this.note,
    this.footer,
  });

  final String title;
  final String time;
  final Color color;
  final bool isLast;
  final bool isLatest;
  final String? subtitle;
  final String? note;

  /// Dòng phụ dưới cùng (vd toạ độ kiện lúc ghi mốc).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 11,
                height: 11,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: isLatest ? color : color.withValues(alpha: 0.30),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: isLatest ? 0.35 : 0.20),
                    width: 3,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: opsBorder)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: isLatest
                                ? FontWeight.w800
                                : FontWeight.w700,
                            color: isLatest ? opsDark : const Color(0xFF475569),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: opsMutedText,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: opsMutedText,
                        ),
                      ),
                    ),
                  if (note != null && note!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        note!.trim(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF475569),
                          height: 1.35,
                        ),
                      ),
                    ),
                  if (footer != null) footer!,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dòng thời gian dọc của các mốc (cũ → mới, mốc mới nhất tô đậm).
class OrderMilestoneTimeline extends StatelessWidget {
  const OrderMilestoneTimeline({
    super.key,
    required this.milestones,
    this.colorOf = milestoneColor,
  });

  final List<OrderMilestone> milestones;
  final Color Function(String? code) colorOf;

  @override
  Widget build(BuildContext context) {
    if (milestones.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < milestones.length; i++)
          OrderTimelineTile(
            title: milestones[i].label,
            time: milestones[i].occurredAt == null
                ? '—'
                : fmtDateTime(milestones[i].occurredAt),
            color: colorOf(milestones[i].code),
            isLast: i == milestones.length - 1,
            isLatest: i == milestones.length - 1,
            footer:
                milestones[i].latitude != null && milestones[i].longitude != null
                ? JourneyLocationLine(
                    latitude: milestones[i].latitude!,
                    longitude: milestones[i].longitude!,
                    source: milestones[i].locationSource,
                  )
                : null,
          ),
      ],
    );
  }
}
