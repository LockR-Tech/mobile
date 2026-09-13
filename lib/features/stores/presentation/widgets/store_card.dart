import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/features/stores/domain/entities/store.dart';

/// Compact card used in the stores list and on the home preview row.
class StoreCard extends StatelessWidget {
  const StoreCard({
    required this.store,
    required this.onTap,
    this.isFavorite,
    this.onToggleFavorite,
    super.key,
  });

  final Store store;
  final VoidCallback onTap;
  final bool? isFavorite;
  final VoidCallback? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            _StoreThumb(image: store.image),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          store.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      _StatusChip(active: store.isActive),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.mapPin,
                        size: 13,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          store.address ?? 'Chưa có địa chỉ',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (store.distanceKm != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Cách bạn ${store.distanceKm!.toStringAsFixed(1)} km',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AISLShadcnTheme.navyAccent,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isFavorite != null)
              IconButton(
                icon: Icon(
                  isFavorite! ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite! ? Colors.red : Colors.grey,
                  size: 22,
                ),
                onPressed: onToggleFavorite,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            else
              const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _StoreThumb extends StatelessWidget {
  const _StoreThumb({this.image});

  final String? image;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 64,
        height: 64,
        child: (image != null && image!.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: image!,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const ColoredBox(color: Color(0xFFEFF4F8)),
                errorWidget: (context, url, error) => const _ThumbFallback(),
              )
            : const _ThumbFallback(),
      ),
    );
  }
}

class _ThumbFallback extends StatelessWidget {
  const _ThumbFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEFF4F8),
      alignment: Alignment.center,
      child: const Icon(LucideIcons.store, color: Color(0xFF94A3B8)),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF16A34A) : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        active ? 'Mở cửa' : 'Đóng',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
