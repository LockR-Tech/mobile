import 'dart:async';

import 'package:smart_laundry_locker/core/constants/app_colors.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/subscription/domain/entities/plan_entity.dart';
import 'package:smart_laundry_locker/features/subscription/domain/entities/subscription_entity.dart';
import 'package:smart_laundry_locker/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:smart_laundry_locker/features/subscription/presentation/bloc/subscription_event.dart';
import 'package:smart_laundry_locker/features/subscription/presentation/bloc/subscription_state.dart';
import 'package:smart_laundry_locker/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:smart_laundry_locker/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:intl/intl.dart';

class PlansPage extends StatefulWidget {
  const PlansPage({super.key});

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  late final SubscriptionBloc _subscriptionBloc;

  @override
  void initState() {
    super.initState();
    _subscriptionBloc = InjectionContainer.provideSubscriptionBloc(ApiClient())
      ..add(const FetchPlansCustomerEvent())
      ..add(const FetchActiveSubscriptionEvent());
  }

  @override
  void dispose() {
    unawaited(_subscriptionBloc.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _subscriptionBloc,
      child: BlocListener<SubscriptionBloc, SubscriptionState>(
        listener: (context, state) async {
          if (state is SubscriptionFailure) {
            SmartDialog.showToast(state.message);
          }
          if (state is SubscriptionSuccess) {
            await showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Chúc mừng'),
                content: Text(state.message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Đóng'),
                  ),
                ],
              ),
            );
            if (context.mounted) {
              context.read<SubscriptionBloc>().add(
                const FetchActiveSubscriptionEvent(),
              );
            }
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFFFFAF7),
          appBar: AppBar(
            title: const Text('Gói cước & Ưu đãi'),
            backgroundColor: const Color(0xFFFFFAF7),
            foregroundColor: AppColors.onBackground,
            elevation: 0,
            actions: [
              Builder(
                builder: (ctx) {
                  return IconButton(
                    icon: const Icon(Icons.refresh, size: 22),
                    onPressed: () {
                      ctx.read<SubscriptionBloc>().add(
                        const FetchPlansCustomerEvent(),
                      );
                      ctx.read<SubscriptionBloc>().add(
                        const FetchActiveSubscriptionEvent(),
                      );
                    },
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: BlocBuilder<SubscriptionBloc, SubscriptionState>(
            builder: (context, state) {
              final plans = state.plans;
              if (state is SubscriptionLoading && plans.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (plans.isEmpty) {
                return const Center(child: Text('Không có dữ liệu gói cước.'));
              }

              return Column(
                children: [
                  if (state.activeSubscription != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.success, Color(0xFF059669)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.success.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.verified,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'GÓI ĐANG HOẠT ĐỘNG',
                                    style: TextStyle(
                                      fontSize: 12,
                                      letterSpacing: 1,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              state.activeSubscription?.plan?.name ?? '-',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            if (state.activeSubscription?.endDate != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Hạn sử dụng: ${DateFormat('dd/MM/yyyy HH:mm').format(state.activeSubscription!.endDate!.toLocal())}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.85),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  const Text(
                    'CHỌN GÓI CỦA BẠN',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Vuốt để khám phá các ưu đãi độc quyền',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.grey600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Expanded(child: _PlansCarousel()),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PlansCarousel extends StatefulWidget {
  const _PlansCarousel();

  @override
  State<_PlansCarousel> createState() => _PlansCarouselState();
}

class _PlansCarouselState extends State<_PlansCarousel> {
  late final PageController _pageController;
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.8)
      ..addListener(() {
        if (mounted) {
          setState(() {
            _currentPage = _pageController.page ?? 0;
          });
        }
      });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _formatVnd(int amount) {
    return NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubscriptionBloc, SubscriptionState>(
      builder: (context, state) {
        final plans = state.plans.toList()
          ..sort((a, b) => a.price.compareTo(b.price));
        final activeSub = state.activeSubscription;
        final hasPaidSub =
            activeSub != null && !(activeSub.plan?.isFreeDefault ?? true);
        final walletBalance = context.watch<WalletProvider>().balance.round();

        return PageView.builder(
          controller: _pageController,
          itemCount: plans.length,
          itemBuilder: (context, index) {
            final plan = plans[index];
            final double relativePosition = index - _currentPage;

            // 3D Effects
            final double scale = (1 - (relativePosition.abs() * 0.15)).clamp(
              0.8,
              1.0,
            );
            final double opacity = (1 - (relativePosition.abs() * 0.3)).clamp(
              0.5,
              1.0,
            );
            final double rotationY = (relativePosition * 0.2).clamp(-0.4, 0.4);

            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..scale(scale)
                ..rotateY(rotationY),
              alignment: Alignment.center,
              child: Opacity(
                opacity: opacity,
                child: _buildPlanCard(
                  context,
                  plan,
                  activeSub,
                  hasPaidSub,
                  walletBalance,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    PlanEntity plan,
    SubscriptionEntity? activeSub,
    bool hasPaidSub,
    int walletBalance,
  ) {
    final isCurrent = activeSub?.plan?.id == plan.id;
    final isFree = plan.isFreeDefault;
    final shouldBlockButton = isCurrent || (hasPaidSub && isFree);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isCurrent)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: const Text(
                'GÓI HIỆN TẠI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _formatVnd(plan.price),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '/tháng',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.grey200),
                  const SizedBox(height: 20),
                  _featureItem('Tối đa ${plan.maxLockers} ô tủ', true),
                  _featureItem(
                    'Giảm ${plan.discountLockerRental}% phí thuê tủ',
                    true,
                  ),
                  _featureItem('${plan.fixedLocker} ô cố định', true),
                  _featureItem(
                    'Giảm ${plan.discountFixedLockerRental}% phí cố định',
                    true,
                  ),
                  if (isCurrent && activeSub?.endDate != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.event_available,
                            size: 16,
                            color: const Color(0xFF0A2342),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Hạn dùng: ${DateFormat('dd/MM/yyyy HH:mm').format(activeSub!.endDate!.toLocal())}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0A2342),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.grey200),
                  const SizedBox(height: 12),
                  const Text(
                    'BẢNG GIÁ CHI TIẾT',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (plan.pricings.isEmpty)
                    const Text(
                      'Không có thông tin bảng giá.',
                      style: TextStyle(
                        color: AppColors.grey500,
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                      ),
                    )
                  else
                    ...plan.pricings.map((p) => _pricingItem(p)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: shouldBlockButton
                    ? null
                    : () => _showPurchaseBottomSheet(
                        context,
                        plan: plan,
                        activeSubscription: activeSub,
                        walletBalanceVnd: walletBalance,
                        formatVnd: _formatVnd,
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCurrent
                      ? AppColors.grey200
                      : AppColors.success,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.grey200,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isCurrent
                      ? 'Đang sử dụng'
                      : (hasPaidSub && isFree)
                      ? 'Đã nâng cấp'
                      : 'Chọn gói này',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPurchaseBottomSheet(
    BuildContext context, {
    required PlanEntity plan,
    required SubscriptionEntity? activeSubscription,
    required int walletBalanceVnd,
    required String Function(int) formatVnd,
  }) {
    final totalCost = _estimateTotalCost(activeSubscription, plan);
    final isDowngrade = _isDowngrade(activeSubscription, plan);
    final isUpgrade = _isUpgrade(activeSubscription, plan);
    final canPurchase = !isDowngrade && walletBalanceVnd >= totalCost;
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        builder: (innerContext) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            plan.name,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Text(
                          '${formatVnd(plan.price)}/tháng',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      plan.description ?? '',
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.grey700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (isUpgrade)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3EE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFDECF)),
                        ),
                        child: const Text(
                          'Bạn sẽ được khấu trừ giá trị gói cũ còn lại vào hóa đơn này.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.grey700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (isDowngrade)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3EE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFDECF)),
                        ),
                        child: const Text(
                          'Hệ thống sẽ expire gói cũ và tạo gói mới. Hiện chưa hỗ trợ hạ cấp gói cước.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFB45309),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    const Text(
                      'Quyền lợi gói',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _featureItem('Tối đa ${plan.maxLockers} ô tủ', true),
                    _featureItem(
                      'Giảm ${plan.discountLockerRental}% phí thuê tủ',
                      true,
                    ),
                    _featureItem('${plan.fixedLocker} ô cố định', true),
                    if (plan.pricings.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Bảng giá chi tiết',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...plan.pricings.map((p) => _pricingItem(p)),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _line('Giá gốc', '${formatVnd(plan.price)}/tháng'),
                          const SizedBox(height: 8),
                          _line('Giá cần trả', '${formatVnd(totalCost)}/tháng'),
                          const SizedBox(height: 8),
                          _line('Số dư ví', formatVnd(walletBalanceVnd)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: canPurchase
                            ? () {
                                Navigator.of(innerContext).pop();
                                context.read<SubscriptionBloc>().add(
                                  PurchasePlanEvent(
                                    planId: plan.id,
                                    walletBalance: walletBalanceVnd,
                                    expectedTotalCost: totalCost,
                                  ),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: AppColors.white,
                          disabledBackgroundColor: AppColors.grey300,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          isDowngrade
                              ? 'Không hỗ trợ hạ cấp'
                              : canPurchase
                              ? 'Mua gói này'
                              : 'Số dư không đủ',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _line(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.grey700),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  bool _isUpgrade(SubscriptionEntity? active, PlanEntity selected) {
    final currentPlan = active?.plan;
    if (currentPlan == null || currentPlan.isFreeDefault) return false;
    return selected.price > currentPlan.price;
  }

  bool _isDowngrade(SubscriptionEntity? active, PlanEntity selected) {
    final currentPlan = active?.plan;
    if (currentPlan == null || currentPlan.isFreeDefault) return false;
    return selected.price <= currentPlan.price;
  }

  int _estimateTotalCost(SubscriptionEntity? active, PlanEntity selected) {
    final currentPlan = active?.plan;
    if (currentPlan == null || currentPlan.isFreeDefault) {
      return selected.price;
    }

    if (selected.price <= currentPlan.price) {
      return selected.price;
    }

    final start = active?.startDate;
    final end = active?.endDate;
    if (start == null || end == null) return selected.price;

    final now = DateTime.now();
    final totalDurationMs =
        end.millisecondsSinceEpoch - start.millisecondsSinceEpoch;
    final remainingMs = end.millisecondsSinceEpoch - now.millisecondsSinceEpoch;
    if (totalDurationMs <= 0 || remainingMs <= 0) return selected.price;

    final remainingValue = (currentPlan.price * remainingMs) / totalDurationMs;
    final totalCost = selected.price - remainingValue;
    return totalCost <= 0 ? 0 : totalCost.round();
  }

  Widget _pricingItem(PricingEntity pricing) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.label_outline_rounded,
                size: 16,
                color: AppColors.success,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  pricing.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _pricingDetailRow(
            'Phí gốc',
            '${_formatVnd(pricing.feePerBlock)} / ${pricing.blockDuration} ${pricing.blockUnit.toLowerCase()}',
          ),
          _pricingDetailRow(
            'Phí trễ hạn',
            '${_formatVnd(pricing.lateFeePerBlock)} / ${pricing.blockDuration} ${pricing.blockUnit.toLowerCase()}',
          ),
          _pricingDetailRow('Ân hạn', '${pricing.gracePeriod} phút'),
        ],
      ),
    );
  }

  Widget _pricingDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.grey600),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureItem(String text, bool enabled) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.cancel_outlined,
            size: 20,
            color: enabled ? AppColors.success : AppColors.grey500,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 17,
                color: enabled ? AppColors.onBackground : AppColors.grey500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
