import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/utils/user_error_message.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/promotions/data/models/promotion_model.dart';
import 'package:smart_laundry_locker/features/promotions/presentation/pages/promotion_detail_page.dart';
import 'package:smart_laundry_locker/features/vouchers/data/repositories/voucher_repository.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

/// Mã riêng của tủ [lockerId] đang chạy: hỏi `GET /api/promotions/active?lockerId=`
/// rồi chỉ giữ mã gắn đúng tủ này (mã toàn hệ thống đã có ở Trang chủ / Ưu đãi).
Future<List<PromotionModel>> loadLockerOnlyPromotions(
  LockerOpsService service,
  int lockerId,
) async {
  final raw = await service.activePromotions(lockerId: lockerId);
  return raw
      .map(PromotionModel.fromJson)
      .where((p) => p.lockerId == lockerId && p.code.trim().isNotEmpty)
      .toList(growable: false);
}

/// Mục "Ưu đãi tại tủ này" ở chi tiết tủ: liệt kê mã giảm giá chỉ dùng được ở
/// tủ này, chạm để xem chi tiết, "Lưu" để cất vào "Ưu đãi của tôi". Không có
/// mã nào hoặc tải lỗi ⇒ ẩn hẳn.
class LockerOffersSection extends StatefulWidget {
  const LockerOffersSection({
    super.key,
    required this.lockerId,
    this.service,
    this.claimPromotion,
    this.padding = EdgeInsets.zero,
  });

  final int lockerId;
  final LockerOpsService? service;

  /// Lưu mã vào ví; mặc định `POST /api/promotions/{id}/claim`.
  final Future<void> Function(int promotionId)? claimPromotion;
  final EdgeInsetsGeometry padding;

  @override
  State<LockerOffersSection> createState() => _LockerOffersSectionState();
}

class _LockerOffersSectionState extends State<LockerOffersSection> {
  List<PromotionModel> _offers = const [];
  final Set<int> _claimed = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant LockerOffersSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lockerId != widget.lockerId) _load();
  }

  Future<void> _load() async {
    final lockerId = widget.lockerId;
    try {
      final service = widget.service ?? LockerOpsService();
      final offers = await loadLockerOnlyPromotions(service, lockerId);
      if (!mounted || lockerId != widget.lockerId) return;
      setState(() => _offers = offers);
    } catch (_) {
      // Ưu đãi là phần phụ của chi tiết tủ — lỗi thì ẩn mục này.
      if (mounted) setState(() => _offers = const []);
    }
  }

  Future<void> _claim(PromotionModel promo) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final claim =
          widget.claimPromotion ??
          (int id) => VoucherRepository().claimPromotion(id);
      await claim(promo.id);
      if (!mounted) return;
      setState(() => _claimed.add(promo.id));
      messenger.showSnackBar(
        SnackBar(
          content: Text('Đã lưu mã ${promo.code} vào "Ưu đãi của tôi"'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            userErrorMessage(
              e,
              notFound: 'Máy chủ chưa hỗ trợ lưu mã. Vui lòng thử lại sau.',
              fallback: 'Không lưu được mã — kiểm tra đăng nhập và thử lại',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openDetail(PromotionModel promo) {
    Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(builder: (_) => PromotionDetailPage(promo: promo)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_offers.isEmpty) return const SizedBox.shrink();
    return Padding(
      key: const ValueKey('locker-offers'),
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.ticketPercent, size: 18, color: AislBrand.navy),
              SizedBox(width: 8),
              Text(
                'Ưu đãi tại tủ này',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final promo in _offers) ...[
            _OfferTile(
              promo: promo,
              claimed: _claimed.contains(promo.id),
              onTap: () => _openDetail(promo),
              onClaim: () => _claim(promo),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _OfferTile extends StatelessWidget {
  const _OfferTile({
    required this.promo,
    required this.claimed,
    required this.onTap,
    required this.onClaim,
  });

  final PromotionModel promo;
  final bool claimed;
  final VoidCallback onTap;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final details = [
      promo.discountLabel,
      if (promo.minOrderLabel != null) promo.minOrderLabel!,
      promo.expiryLabel,
    ].join(' · ');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFACC15).withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.ticket, color: Color(0xFFCA8A04)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    promo.code,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AislBrand.navy,
                    ),
                  ),
                  if (promo.name.trim().isNotEmpty)
                    Text(
                      promo.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Colors.black87,
                      ),
                    ),
                  Text(
                    details,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: claimed ? null : onClaim,
              icon: Icon(
                claimed ? LucideIcons.bookmarkCheck : LucideIcons.bookmarkPlus,
                size: 15,
              ),
              label: Text(claimed ? 'Đã lưu' : 'Lưu'),
              style: TextButton.styleFrom(
                foregroundColor: AislBrand.blue,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
