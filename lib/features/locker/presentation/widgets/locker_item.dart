import 'package:cached_network_image/cached_network_image.dart';
import 'package:smart_laundry_locker/features/locker/domain/entities/locker_location.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

/// Widget hiển thị một location item trong danh sách tủ.
class LockerItem extends StatelessWidget {
  final LockerLocation location;
  final VoidCallback onTap;

  const LockerItem({super.key, required this.location, required this.onTap});

  // 6 gradient pairs — deterministic per location id
  static const _gradients = [
    [Color(0xFF003D5B), Color(0xFF0077B6)],
    [Color(0xFF0077B6), Color(0xFF00B4D8)],
    [Color(0xFF059669), Color(0xFF10B981)],
    [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
    [Color(0xFFD97706), Color(0xFFF59E0B)],
    [Color(0xFF0F172A), Color(0xFF334155)],
  ];

  List<Color> _gradient() {
    final hash = location.id.codeUnits.fold(0, (a, b) => a + b);
    return _gradients[hash % _gradients.length];
  }

  String _initials() {
    final parts = location.name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    final name = parts.first;
    return name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _gradient();
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail 110×110
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 110,
                height: 110,
                child: (location.imageUrl != null &&
                        location.imageUrl!.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: location.imageUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: 220,
                        memCacheHeight: 220,
                        placeholder: (_, __) =>
                            _GradientThumb(colors: colors, initials: _initials()),
                        errorWidget: (_, __, ___) =>
                            _GradientThumb(colors: colors, initials: _initials()),
                      )
                    : _GradientThumb(colors: colors, initials: _initials()),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: SizedBox(
                height: 110,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status chip
                    _StatusChip(active: location.isActive),
                    // Name — 2 lines
                    Text(
                      location.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: context.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    // Address
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Icon(LucideIcons.mapPin,
                              size: 12, color: context.textMuted),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location.address.isNotEmpty
                                ? location.address
                                : 'Chưa có địa chỉ',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textMuted,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 44),
              child: Icon(Icons.chevron_right,
                  color: Color(0xFFCBD5E1), size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientThumb extends StatelessWidget {
  const _GradientThumb({required this.colors, required this.initials});

  final List<Color> colors;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          const Icon(LucideIcons.lockKeyhole, color: Colors.white54, size: 12),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF16A34A) : Colors.grey;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          active ? 'Mở cửa' : 'Đóng',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
