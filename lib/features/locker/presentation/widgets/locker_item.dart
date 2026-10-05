import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smart_laundry_locker/features/locker/domain/entities/locker_location.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

/// Widget hiển thị một location item trong danh sách tủ.
class LockerItem extends StatelessWidget {
  final LockerLocation location;
  final VoidCallback onTap;
  final bool isMostUsed;
  final Position? userPosition;
  final double? distanceKm;

  const LockerItem({
    super.key,
    required this.location,
    required this.onTap,
    this.isMostUsed = false,
    this.userPosition,
    this.distanceKm,
  });

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

  bool get _hasValidCoordinate =>
      location.hasValidCoordinate &&
      (location.latitude.abs() > 0.0001 || location.longitude.abs() > 0.0001);

  double? _calculateDistance() {
    if (distanceKm != null) return distanceKm;
    if (userPosition == null) return null;
    if (!_hasValidCoordinate) return null;
    if (userPosition!.latitude.abs() <= 0.0001 &&
        userPosition!.longitude.abs() <= 0.0001) {
      return null;
    }
    try {
      final dist = location.distanceToCoordinate(
        userPosition!.latitude,
        userPosition!.longitude,
      );
      if (dist.isNaN || dist.isInfinite || dist < 0) return null;
      return dist;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _gradient();
    final calculatedDistance = _calculateDistance();
    final itemContent = Padding(
      padding: EdgeInsets.symmetric(
        vertical: isMostUsed ? 10 : 14,
        horizontal: isMostUsed ? 10 : 0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail 110×110 có badge trạng thái đè lên
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 110,
              height: 110,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  (location.imageUrl != null &&
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
                  // Badge trạng thái mờ trong suốt (Glassmorphism)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: _StatusChip(active: location.isActive),
                  ),
                ],
              ),
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
                  // Distance chip & Most used badge
                  if (calculatedDistance != null || isMostUsed)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          if (calculatedDistance != null)
                            _DistanceChip(distanceKm: calculatedDistance),
                          if (calculatedDistance != null && isMostUsed)
                            const SizedBox(width: 8),
                          if (isMostUsed) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFFDE68A),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.sparkles,
                                    size: 10,
                                    color: Color(0xFFB45309),
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'Hay dùng nhất',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
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
    );

    final cardWidget = isMostUsed
        ? Container(
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: itemContent,
          )
        : itemContent;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: cardWidget,
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
    final dotColor = active ? const Color(0xFF22C55E) : const Color(0xFF94A3B8);
    final text = active ? 'Mở cửa' : 'Đóng';

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: active
                ? Colors.black.withValues(alpha: 0.42)
                : Colors.black.withValues(alpha: 0.52),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active
                  ? const Color(0xFF22C55E).withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.22),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: const Color(0xFF22C55E).withValues(alpha: 0.9),
                            blurRadius: 4,
                            spreadRadius: 0.8,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 4.5),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DistanceChip extends StatelessWidget {
  const _DistanceChip({required this.distanceKm});

  final double distanceKm;

  String get _formattedDistance {
    if (distanceKm < 1.0) {
      final meters = (distanceKm * 1000).round();
      return '$meters m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E3A8A).withValues(alpha: 0.35)
            : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? const Color(0xFF3B82F6).withValues(alpha: 0.4)
              : const Color(0xFFBFDBFE),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.navigation,
            size: 10,
            color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
          ),
          const SizedBox(width: 3.5),
          Text(
            _formattedDistance,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
            ),
          ),
        ],
      ),
    );
  }
}

