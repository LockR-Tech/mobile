import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';
import '../providers/voucher_provider.dart';
import '../../data/models/voucher_model.dart';
import 'voucher_detail_page.dart';

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
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VoucherProvider>().loadMyVouchers();
    });
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
            title: 'Ưu đãi của tôi',
            subtitle: 'Mã giảm giá & quà tặng của bạn',
            onBack: () => context.pop(),
            trailing: BrandCircleIconButton(
              icon: LucideIcons.refreshCw,
              onTap: () => context.read<VoucherProvider>().loadMyVouchers(),
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
                fontFamily: 'Manrope',
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              tabs: const [
                Tab(text: 'Khả dụng'),
                Tab(text: 'Lịch sử'),
              ],
            ),
          ),
          Expanded(
            child: Consumer<VoucherProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AislBrand.navy),
                  );
                }

                final activeVouchers = provider.vouchers
                    .where((v) => v.status == 'UNUSED')
                    .toList();
                final inactiveVouchers = provider.vouchers
                    .where((v) => v.status != 'UNUSED')
                    .toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildVoucherList(activeVouchers, provider),
                    _buildVoucherList(
                      inactiveVouchers,
                      provider,
                      isInactive: true,
                    ),
                  ],
                );
              },
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
                    'Bạn chưa có ưu đãi nào',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => context.push(AppRouter.promotions),
                    icon: const Icon(LucideIcons.ticket, size: 16),
                    label: const Text('Khám phá ưu đãi và lưu mã'),
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
      rewardText = 'Giảm ${formatCurrency.format(voucher.rewardValue)}';
    } else if (voucher.rewardType == 'DISCOUNT_PERCENT') {
      rewardText = 'Giảm ${voucher.rewardValue.toInt()}%';
    } else {
      rewardText = 'Quà tặng';
    }

    String expireText = 'Không giới hạn';
    if (voucher.expiresAt != null) {
      expireText =
          'HSD: ${DateFormat('dd/MM/yyyy').format(voucher.expiresAt!)}';
    }

    return Container(
      height: 100,
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
                    voucher.rewardType == 'GIFT' ? 'QUÀ TẶNG' : 'GIẢM GIÁ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontFamily: 'Manrope',
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
                        fontFamily: 'Manrope',
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
                        fontFamily: 'Manrope',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                            fontFamily: 'Manrope',
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
                        voucher.status == 'USED' ? 'Đã dùng' : 'Hết hạn',
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
