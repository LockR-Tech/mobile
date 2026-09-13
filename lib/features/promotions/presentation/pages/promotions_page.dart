import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Consumer;
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/features/promotions/data/models/promotion_model.dart';
import 'package:smart_laundry_locker/features/promotions/presentation/pages/promotion_detail_page.dart';
import 'package:smart_laundry_locker/features/promotions/presentation/providers/promotion_provider.dart';
import 'package:smart_laundry_locker/features/vouchers/data/repositories/voucher_repository.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

class PromotionsPage extends ConsumerStatefulWidget {
  const PromotionsPage({super.key});

  @override
  ConsumerState<PromotionsPage> createState() => _PromotionsPageState();
}

class _PromotionsPageState extends ConsumerState<PromotionsPage> {
  static const _gradients = [
    [Color(0xFF003D5B), Color(0xFF0077B6)],
    [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
    [Color(0xFF059669), Color(0xFF10B981)],
    [Color(0xFFD97706), Color(0xFFF59E0B)],
    [Color(0xFFE53E3E), Color(0xFFFC8181)],
    [Color(0xFF0F172A), Color(0xFF334155)],
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(promotionNotifierProvider).load();
    });
  }

  List<Color> _gradientFor(int id) {
    return _gradients[id % _gradients.length];
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(promotionNotifierProvider);

    return Scaffold(
      backgroundColor: context.pageBg,
      body: Column(
        children: [
          BrandHeroHeader(
            title: 'Ưu đãi & Flash Sale',
            subtitle: 'Khám phá ưu đãi đang hiệu lực hôm nay',
            onBack: () => context.pop(),
            trailing: BrandCircleIconButton(
              icon: LucideIcons.refreshCw,
              onTap: () => ref.read(promotionNotifierProvider).load(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AislBrand.navy,
              onRefresh: () => ref.read(promotionNotifierProvider).load(),
              child: _buildBody(provider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(PromotionProvider provider) {
    if (provider.isLoading && provider.promotions.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AislBrand.navy));
    }
    if (provider.error != null && provider.promotions.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(LucideIcons.triangleAlert, size: 52, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Text(
            provider.error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      );
    }
    if (provider.promotions.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(LucideIcons.ticketSlash, size: 52, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Chưa có ưu đãi nào đang hiệu lực',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: provider.promotions.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: context.dividerColor),
      itemBuilder: (ctx, index) {
        final promo = provider.promotions[index];
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(ctx).push<void>(
            MaterialPageRoute(
              builder: (_) => PromotionDetailPage(promo: promo),
            ),
          ),
          child: _buildPromoCard(promo, index),
        );
      },
    );
  }

  Widget _buildPromoCard(PromotionModel promo, int index) {
    final colors = _gradientFor(promo.id);
    final String? sub =
        (promo.description != null && promo.description!.isNotEmpty)
            ? promo.description
            : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left: image 110×110 ───────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 110,
              height: 110,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: promo.effectiveImageUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 220,
                    memCacheHeight: 220,
                    placeholder: (_, __) => _gradientPlaceholder(colors),
                    errorWidget: (_, __, ___) => _gradientPlaceholder(colors),
                  ),
                  // Discount badge bottom-left
                  Positioned(
                    bottom: 7,
                    left: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53E3E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        promo.discountLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          // ── Right: content ────────────────────────────────────────────
          Expanded(
            child: SizedBox(
              height: 110,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Flash Sale chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.zap,
                            size: 10, color: Color(0xFFF97316)),
                        SizedBox(width: 4),
                        Text(
                          'Flash Sale',
                          style: TextStyle(
                            color: Color(0xFFF97316),
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Title — 2 lines
                  Text(
                    promo.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: context.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  // Subtitle / description
                  if (sub != null)
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textMuted,
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  // Bottom row: expiry + code chip
                  Row(
                    children: [
                      Icon(
                        LucideIcons.clock,
                        size: 12,
                        color: promo.isExpiringSoon
                            ? const Color(0xFFE53E3E)
                            : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          promo.expiryLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: promo.isExpiringSoon
                                ? const Color(0xFFE53E3E)
                                : const Color(0xFF94A3B8),
                            fontWeight: promo.isExpiringSoon
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _copyCode(context, promo.code),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: AislBrand.navy.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AislBrand.navy.withValues(alpha: 0.18)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                promo.code,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: AislBrand.navy,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Icon(LucideIcons.copy,
                                  size: 12, color: AislBrand.navy),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Lưu vào ví voucher (promotion_claims) — xem lại ở
                      // "Ưu đãi của tôi", mã tự chuyển USED khi áp vào đơn.
                      GestureDetector(
                        onTap: () => _claimPromotion(context, promo),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: AislBrand.blue.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AislBrand.blue.withValues(alpha: 0.35)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.bookmarkPlus,
                                  size: 12, color: AislBrand.blue),
                              SizedBox(width: 4),
                              Text(
                                'Lưu',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AislBrand.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientPlaceholder(List<Color> colors) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(LucideIcons.ticket, size: 32, color: Colors.white24),
      ),
    );
  }

  /// Lưu mã vào ví voucher (idempotent — lưu lại không lỗi).
  Future<void> _claimPromotion(BuildContext context, PromotionModel promo) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await VoucherRepository().claimPromotion(promo.id);
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.bookmarkCheck,
                  color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(
                      'Đã lưu mã ${promo.code} vào "Ưu đãi của tôi"')),
            ],
          ),
          backgroundColor: AislBrand.navy,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Không lưu được mã — kiểm tra đăng nhập và thử lại'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _copyCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.check, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text('Đã sao chép mã: $code'),
          ],
        ),
        backgroundColor: AislBrand.navy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
