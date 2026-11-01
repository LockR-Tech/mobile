import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/features/promotions/presentation/widgets/promotion_scope_tag.dart';
import 'package:smart_laundry_locker/shared/widgets/unauthenticated_placeholder.dart';
import 'package:smart_laundry_locker/shared/shared.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';
import '../providers/voucher_provider.dart';
import '../widgets/points_exchange_tab.dart';
import '../../data/models/voucher_model.dart';
import 'voucher_detail_page.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

class MyVouchersPage extends StatefulWidget {
  const MyVouchersPage({super.key});

  @override
  State<MyVouchersPage> createState() => _MyVouchersPageState();
}

class _MyVouchersPageState extends State<MyVouchersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (TokenService.authState.value) {
        _reload();
      }
    });
  }

  /// Kho voucher + danh sách đổi điểm (kèm số điểm hiện có).
  Future<void> _reload() {
    final provider = context.read<VoucherProvider>();
    return Future.wait([provider.loadMyVouchers(), provider.loadExchange()]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          BrandHeroHeader(
            title: context.l10n.voucherMine,
            subtitle: context.l10n.voucherMineSubtitle,
            onBack: () => AppRouter.backOrHome(context),
            trailing: BrandCircleIconButton(
              icon: LucideIcons.refreshCw,
              onTap: _reload,
            ),
          ),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AislBrand.blue,
              labelColor: AislBrand.navy,
              unselectedLabelColor: Colors.grey.shade500,
              labelStyle: const TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              tabs: [
                Tab(text: context.l10n.commonAvailable),
                Tab(text: context.l10n.voucherExchangeTab),
                Tab(text: context.l10n.commonHistory),
              ],
            ),
          ),
          Expanded(
            child: Consumer<VoucherProvider>(
              builder: (context, provider, child) {
                // Kho voucher gắn với tài khoản: chưa đăng nhập thì mời đăng
                // nhập thay vì gọi API rồi hiện lỗi 401.
                if (!TokenService.authState.value) {
                  return UnauthenticatedPlaceholder(
                    message: context.l10n.voucherLoginToSee,
                    onAuthSuccess: _reload,
                  );
                }
                // Tab Đổi điểm tự hiện trạng thái tải/lỗi của nó, không bị
                // che khi kho voucher đang tải hoặc lỗi.
                final Widget walletState;
                if (provider.isLoading) {
                  walletState = Center(
                    child: AppLoadingIndicator(message: context.l10n.voucherLoading),
                  );
                } else if (provider.error != null) {
                  walletState = _buildErrorState(provider);
                } else {
                  walletState = const SizedBox.shrink();
                }
                final walletReady =
                    !provider.isLoading && provider.error == null;

                final activeVouchers = provider.vouchers
                    .where((v) => v.status == 'UNUSED')
                    .toList();
                final inactiveVouchers = provider.vouchers
                    .where((v) => v.status != 'UNUSED')
                    .toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    walletReady
                        ? _buildVoucherList(activeVouchers, provider)
                        : walletState,
                    PointsExchangeTab(
                      onExchanged: () => _tabController.animateTo(0),
                    ),
                    walletReady
                        ? _buildVoucherList(
                            inactiveVouchers,
                            provider,
                            isInactive: true,
                          )
                        : walletState,
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(VoucherProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.loadMyVouchers(),
      child: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 60),
          Icon(LucideIcons.cloudOff, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            provider.error!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: () => provider.loadMyVouchers(),
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: Text(context.l10n.commonRetry),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherList(
    List<VoucherModel> vouchers,
    VoucherProvider provider, {
    bool isInactive = false,
  }) {
    if (vouchers.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => provider.loadMyVouchers(),
        child: Stack(
          children: [
            ListView(),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.ticket,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.voucherNone,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => context.push(AppRouter.promotions),
                    icon: const Icon(LucideIcons.ticket, size: 16),
                    label: Text(context.l10n.voucherExploreAndSave),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadMyVouchers(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: vouchers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final voucher = vouchers[index];
          return GestureDetector(
            onTap: () => Navigator.of(context, rootNavigator: true).push<void>(
              MaterialPageRoute(
                builder: (_) => VoucherDetailPage(voucher: voucher),
              ),
            ),
            child: _buildVoucherCard(voucher, isInactive),
          );
        },
      ),
    );
  }

  Widget _buildVoucherCard(VoucherModel voucher, bool isInactive) {
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final color = isInactive ? Colors.grey.shade400 : AislBrand.navy;

    String rewardText = '';
    if (voucher.rewardType == 'DISCOUNT_FIXED') {
      rewardText = context.l10n.promoDiscountAmount(formatCurrency.format(voucher.rewardValue));
    } else if (voucher.rewardType == 'DISCOUNT_PERCENT') {
      rewardText = context.l10n.promoDiscountPercent(voucher.rewardValue.toInt());
    } else {
      rewardText = context.l10n.voucherGift;
    }

    String expireText = context.l10n.promoUnlimited;
    if (voucher.expiresAt != null) {
      expireText =
          'HSD: ${DateFormat('dd/MM/yyyy').format(voucher.expiresAt!)}';
    }

    return Container(
      // Cao theo cỡ chữ hệ thống: chữ to hơn 1× thì 4 dòng nội dung vẫn vừa.
      height: MediaQuery.textScalerOf(context).scale(118),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Left stub
            Container(
              width: 100,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isInactive ? 0.3 : 0.1),
                border: Border(
                  right: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                    style: BorderStyle.solid,
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    voucher.rewardType == 'GIFT'
                        ? LucideIcons.gift
                        : LucideIcons.ticketPercent,
                    color: color,
                    size: 32,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    voucher.rewardType == 'GIFT' ? context.l10n.voucherGiftUpper : context.l10n.voucherDiscountUpper,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
            ),
            // Main Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      rewardText,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: isInactive ? Colors.grey : Colors.black87,
                        fontFamily: 'Roboto',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      voucher.campaignTitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontFamily: 'Roboto',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    PromotionScopeTag(
                      label: voucher.scopeLabel,
                      lockerScoped: voucher.lockerId != null,
                      fontSize: 10.5,
                      muted: isInactive,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.clock,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          expireText,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Dashed divider visual spacer (optional, could use CustomPainter)
            // Right Action / Code
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isInactive
                          ? Colors.transparent
                          : Colors.blue.withValues(alpha: 0.1),
                      border: Border.all(
                        color: isInactive
                            ? Colors.grey.shade300
                            : Colors.blue.shade200,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      voucher.code,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isInactive ? Colors.grey : Colors.blue.shade800,
                      ),
                    ),
                  ),
                  if (isInactive)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        voucher.status == 'USED' ? context.l10n.voucherUsed : context.l10n.commonExpired,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
