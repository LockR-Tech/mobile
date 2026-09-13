import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/features/stores/domain/entities/store.dart';
import 'package:smart_laundry_locker/features/stores/infrastructure/services/store_service.dart';
import 'package:smart_laundry_locker/features/stores/presentation/pages/store_lockers_page.dart';
import 'package:url_launcher/url_launcher.dart';

/// Store detail screen: store info + customer ratings.
///
/// Either pass a preloaded [store] (from the list) or a [storeId] to fetch.
class StoreDetailPage extends StatefulWidget {
  const StoreDetailPage({super.key, this.store, this.storeId})
    : assert(store != null || storeId != null, 'store or storeId is required');

  final Store? store;
  final int? storeId;

  @override
  State<StoreDetailPage> createState() => _StoreDetailPageState();
}

class _StoreDetailPageState extends State<StoreDetailPage> {
  final StoreService _service = StoreService(ApiClient());

  Store? _store;
  List<StoreRating> _ratings = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _store = widget.store;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final store = _store ?? await _service.getStore(widget.storeId!);
      List<StoreRating> ratings = const [];
      try {
        ratings = await _service.getRatings(store.id);
      } catch (_) {
        // Ratings are best-effort; store detail still renders without them.
      }
      if (!mounted) return;
      setState(() {
        _store = store;
        _ratings = ratings;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không tải được thông tin cửa hàng.';
        _loading = false;
      });
    }
  }

  Future<void> _openDirections() async {
    final store = _store;
    if (store == null) return;
    if (store.hasLocation) {
      // In-app directions map (route drawn from current location).
      context.push(
        AppRouter.directions,
        extra: {
          'lat': store.latitude,
          'lng': store.longitude,
          'title': store.name,
          'subtitle': store.address,
        },
      );
      return;
    }
    // No coordinates: fall back to an address search in the maps app.
    if ((store.address ?? '').isEmpty) {
      _toast('Cửa hàng chưa có vị trí.');
      return;
    }
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=${Uri.encodeComponent(store.address!)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _toast('Không mở được bản đồ.');
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AISLShadcnTheme.navySurface,
      appBar: AppBar(
        title: const Text('Chi tiết cửa hàng'),
        backgroundColor: AISLShadcnTheme.navyPrimary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : _buildContent(_store!),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.triangleAlert,
            color: Colors.redAccent,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 16),
          FilledButton(onPressed: _load, child: const Text('Thử lại')),
        ],
      ),
    );
  }

  Widget _buildContent(Store store) {
    final summary = StoreRatingsSummary.fromRatings(_ratings);
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildHeaderImage(store),
        Transform.translate(
          offset: const Offset(0, -24),
          child: Column(
            children: [
              _buildInfoCard(store, summary),
              const SizedBox(height: 16),
              _buildRatingsSection(summary),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderImage(Store store) {
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: (store.image != null && store.image!.isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: store.image!,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  const ColoredBox(color: Color(0xFFEFF4F8)),
              errorWidget: (context, url, error) => const _HeaderFallback(),
            )
          : const _HeaderFallback(),
    );
  }

  Widget _buildInfoCard(Store store, StoreRatingsSummary summary) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  store.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A202C),
                  ),
                ),
              ),
              _StatusPill(active: store.isActive),
            ],
          ),
          if (summary.hasRatings) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, color: Color(0xFFF59E0B), size: 18),
                const SizedBox(width: 4),
                Text(
                  summary.average.toStringAsFixed(1),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '  ·  ${summary.count} đánh giá',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if ((store.address ?? '').isNotEmpty)
            _InfoRow(
              icon: LucideIcons.mapPin,
              label: 'Địa chỉ',
              value: store.address!,
            ),
          if ((store.contactPhone ?? '').isNotEmpty)
            _InfoRow(
              icon: LucideIcons.phone,
              label: 'Số điện thoại',
              value: store.contactPhone!,
            ),
          if (store.distanceKm != null)
            _InfoRow(
              icon: LucideIcons.navigation,
              label: 'Khoảng cách',
              value: '${store.distanceKm!.toStringAsFixed(1)} km',
            ),
          if ((store.description ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              store.description!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF475569),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _openDirections,
                  style: FilledButton.styleFrom(
                    backgroundColor: AISLShadcnTheme.navyPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(LucideIcons.map, size: 18),
                  label: const Text('Chỉ đường'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StoreLockerGridPage(store: store),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AISLShadcnTheme.navyPrimary,
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(LucideIcons.boxes, size: 18),
                  label: const Text('Xem tủ'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingsSection(StoreRatingsSummary summary) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đánh giá từ khách hàng',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 12),
          if (!summary.hasRatings)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Chưa có đánh giá nào',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            for (final rating in _ratings) _RatingTile(rating: rating),
        ],
      ),
    );
  }
}

class _HeaderFallback extends StatelessWidget {
  const _HeaderFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE7F0F8),
      alignment: Alignment.center,
      child: const Icon(LucideIcons.store, size: 56, color: Color(0xFF94A3B8)),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF16A34A) : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        active ? 'Đang hoạt động' : 'Tạm đóng',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEBF2FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: AISLShadcnTheme.navyPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingTile extends StatelessWidget {
  const _RatingTile({required this.rating});

  final StoreRating rating;

  @override
  Widget build(BuildContext context) {
    final stars = rating.rating.round().clamp(0, 5);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                rating.userName ?? 'Khách hàng',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              for (var i = 0; i < 5; i++)
                Icon(
                  i < stars ? Icons.star : Icons.star_border,
                  size: 14,
                  color: const Color(0xFFF59E0B),
                ),
            ],
          ),
          if ((rating.comment ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              rating.comment!,
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
          ],
          if (rating.createdAt != null) ...[
            const SizedBox(height: 2),
            Text(
              DateFormat('dd/MM/yyyy').format(rating.createdAt!),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
          const Divider(height: 16),
        ],
      ),
    );
  }
}
