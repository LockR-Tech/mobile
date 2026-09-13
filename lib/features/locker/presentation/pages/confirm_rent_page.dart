import 'package:smart_laundry_locker/core/constants/app_colors.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/locker/domain/entities/fixed_rent_entity.dart';
import 'package:smart_laundry_locker/features/locker/presentation/bloc/locker_rent_bloc.dart';
import 'package:smart_laundry_locker/features/locker/presentation/bloc/locker_rent_event.dart';
import 'package:smart_laundry_locker/features/locker/presentation/bloc/locker_rent_state.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/features/locker/presentation/providers/locker_injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:intl/intl.dart';
import 'package:smart_laundry_locker/core/utils/enum_translator.dart';
import 'package:smart_laundry_locker/features/vouchers/presentation/providers/voucher_provider.dart';
import 'package:smart_laundry_locker/features/vouchers/data/models/voucher_model.dart';
import 'package:provider/provider.dart';

class ConfirmRentArgs {
  final String cabinetId;
  final String lockerId;
  final String cabinetName;
  final String lockerLabel;
  final String locationName;
  final String blockUnit;
  final int blockDuration;
  final String activePlanName;
  final int price;
  final int discount;
  final int durationMonths;
  final int? durationDays;
  final int walletBalance;
  final String planName;
  final String termLabel;
  final bool isFixed;
  final String itemType;
  final double initialBlocks;
  final int gracePeriod;
  final int unitPrice;

  const ConfirmRentArgs({
    required this.cabinetId,
    required this.lockerId,
    required this.cabinetName,
    required this.lockerLabel,
    required this.locationName,
    required this.blockUnit,
    required this.blockDuration,
    required this.activePlanName,
    required this.price,
    required this.discount,
    required this.walletBalance,
    required this.planName,
    required this.unitPrice,
    this.durationMonths = 1,
    this.durationDays,
    this.termLabel = '01 Tháng',
    this.isFixed = true,
    this.itemType = 'OTHER',
    required this.initialBlocks,
    required this.gracePeriod,
  });

  int get totalPayment => (price - discount).clamp(0, price);
  int get walletAfterPayment => walletBalance - totalPayment;
}

class ConfirmRentPage extends StatelessWidget {
  final ConfirmRentArgs args;

  const ConfirmRentPage({super.key, required this.args});

  String _formatMoney(int amount) {
    return NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    ).format(amount).replaceAll('\u00a0', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final bloc = LockerInjection.provideLockerRentBloc(ApiClient());
    return BlocProvider<LockerRentBloc>(
      create: (_) => bloc,
      child: _ConfirmRentBody(args: args),
    );
  }

  Widget _buildPlanInfoCard() {
    return _cardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi tiết gói thuê',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              letterSpacing: -0.4,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 18),
          _detailRow('Tên dịch vụ', args.planName),
          const SizedBox(height: 14),
          _detailRow('Địa điểm', args.locationName),
          const SizedBox(height: 14),
          _detailRow('Thông tin tủ', args.cabinetName),
          const SizedBox(height: 14),
          _detailRow('Số ô tủ', 'Ô ${args.lockerLabel}'),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildPaymentCard() {
    return _cardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi phí & Thanh toán',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              letterSpacing: -0.4,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 18),
          _detailRow('Gói hội viên', args.activePlanName),
          const SizedBox(height: 14),
          _detailRow(
            args.isFixed ? 'Đơn giá' : 'Đơn giá (Mỗi block)',
            '${_formatMoney(args.unitPrice)} / ${args.blockDuration} ${EnumTranslator.translateFeeBlockUnit(args.blockUnit)}',
          ),
          if (!args.isFixed) ...[
            const SizedBox(height: 14),
            _detailRow(
              'Phí trả trước (${args.initialBlocks % 1 == 0 ? args.initialBlocks.toInt() : args.initialBlocks.toStringAsFixed(2)} block)',
              _formatMoney(args.price),
            ),
          ],
          if (args.isFixed) ...[
            const SizedBox(height: 14),
            _detailRow('Số tháng thuê', '${args.durationMonths} Tháng'),
            const SizedBox(height: 14),
            _detailRow('Phí thuê gốc', _formatMoney(args.price)),
          ],
          const SizedBox(height: 14),
          _detailRow(
            'Giảm giá gói ${args.activePlanName}',
            '- ${_formatMoney(args.discount)}',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Divider(color: Colors.grey.shade200, height: 1),
          ),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tổng thanh toán',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  _formatMoney(args.totalPayment),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 30,
                    color: AppColors.success,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _detailRow(
            'Số dư ví sau thanh toán',
            _formatMoney(args.walletAfterPayment),
          ),
        ],
      ),
    );
  }

  Widget _buildImportantNoteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD8B0)),
      ),
      child: Text(
        'Gói thuê có hiệu lực ngay sau khi thanh toán thành công. '
        'Bạn có quyền đóng/mở tủ không giới hạn trong thời gian thuê.'
        '${args.isFixed ? '' : '\n\nLưu ý: Hệ thống sẽ thu trước phí cho ${args.gracePeriod} ${EnumTranslator.translateFeeBlockUnit(args.blockUnit)} đầu tiên ngay khi bắt đầu thuê.'}',
        style: const TextStyle(
          fontSize: 14,
          height: 1.45,
          color: Color(0xFF9A3412),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _cardWrapper({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
        child: child,
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfirmRentBody extends StatefulWidget {
  final ConfirmRentArgs args;

  const _ConfirmRentBody({required this.args});

  @override
  State<_ConfirmRentBody> createState() => _ConfirmRentBodyState();
}

class _ConfirmRentBodyState extends State<_ConfirmRentBody> {
  VoucherModel? _selectedVoucher;

  @override
  void initState() {
    super.initState();
    // Load vouchers for user on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VoucherProvider>().loadMyVouchers(status: 'UNUSED');
    });
  }

  int get _voucherDiscount {
    if (_selectedVoucher == null) return 0;
    final basePriceAfterActiveDiscount =
        (widget.args.price - widget.args.discount).clamp(0, widget.args.price);
    if (_selectedVoucher!.rewardType == 'DISCOUNT_PERCENT') {
      return (basePriceAfterActiveDiscount *
              (_selectedVoucher!.rewardValue / 100))
          .round();
    } else if (_selectedVoucher!.rewardType == 'DISCOUNT_AMOUNT') {
      return _selectedVoucher!.rewardValue.round();
    }
    return 0;
  }

  int get _totalPayment {
    final priceAfterAll =
        (widget.args.price - widget.args.discount - _voucherDiscount);
    return priceAfterAll.clamp(0, widget.args.price);
  }

  int get _walletAfterPayment {
    return widget.args.walletBalance - _totalPayment;
  }

  String _formatMoney(int amount) {
    return NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    ).format(amount).replaceAll('\u00a0', ' ');
  }

  void _showVoucherSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer<VoucherProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final usableVouchers = provider.vouchers
                .where((v) => v.status == 'UNUSED')
                .toList();

            if (usableVouchers.isEmpty) {
              return Container(
                height: 300,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.ticketX,
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Bạn không có voucher khả dụng nào',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.ticket, color: AppColors.primary),
                      const SizedBox(width: 12),
                      const Text(
                        'Chọn voucher ưu đãi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      if (_selectedVoucher != null)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedVoucher = null;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Bỏ chọn',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    itemCount: usableVouchers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final voucher = usableVouchers[index];
                      final isSelected = _selectedVoucher?.id == voucher.id;

                      String discountText = '';
                      if (voucher.rewardType == 'DISCOUNT_PERCENT') {
                        discountText = 'Giảm ${voucher.rewardValue.toInt()}%';
                      } else {
                        discountText =
                            'Giảm ${_formatMoney(voucher.rewardValue.toInt())}';
                      }

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedVoucher = voucher;
                          });
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFEEF2FF)
                                : Colors.white,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.gift,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      voucher.campaignTitle.isNotEmpty
                                          ? voucher.campaignTitle
                                          : 'Ưu đãi cá nhân',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      discountText,
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 17,
                                      ),
                                    ),
                                    if (voucher.expiresAt != null) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        'HSD: ${DateFormat('dd/MM/yyyy').format(voucher.expiresAt!)}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        );
      },
    );
  }

  void _showOpenOptionDialog(BuildContext context) {
    SmartDialog.show<void>(
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.doorOpen,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Chọn hình thức mở tủ',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bạn muốn mở tủ ngay lúc này hay để sau?',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                SmartDialog.dismiss<void>();
                _dispatchRentEvent(context, skipPhysicalOpen: false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Mở ngay',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                SmartDialog.dismiss<void>();
                _dispatchRentEvent(context, skipPhysicalOpen: true);
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Để sau',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _dispatchRentEvent(
    BuildContext context, {
    required bool skipPhysicalOpen,
  }) {
    final args = widget.args;
    final bloc = context.read<LockerRentBloc>();
    if (args.isFixed) {
      bloc.add(
        OnConfirmFixedRent(
          cabinetId: args.cabinetId,
          lockerId: args.lockerId,
          rentMonths: args.durationMonths,
          rentDays: args.durationDays,
          itemType: args.itemType,
          skipPhysicalOpen: skipPhysicalOpen,
          voucherId: _selectedVoucher?.id,
        ),
      );
    } else {
      bloc.add(
        OnConfirmFlexibleRent(
          cabinetId: args.cabinetId,
          lockerId: args.lockerId,
          itemType: args.itemType,
          skipPhysicalOpen: skipPhysicalOpen,
          voucherId: _selectedVoucher?.id,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    final parentPage = ConfirmRentPage(args: args);

    return BlocListener<LockerRentBloc, LockerRentState>(
      listener: (context, state) {
        if (state.error != null && state.error!.isNotEmpty) {
          SmartDialog.showToast(state.error!);
        }
        if (state.fixedRent != null && !state.isSubmitting) {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => BlocProvider.value(
                value: context.read<LockerRentBloc>(),
                child: RentSuccessPage(
                  fixedRent: state.fixedRent!,
                  rentMonths: args.durationMonths,
                  rentDays: args.durationDays,
                  totalPaid: _totalPayment,
                ),
              ),
            ),
          );
        }
        if (state.flexibleRent != null &&
            !args.isFixed &&
            !state.isSubmitting) {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => BlocProvider.value(
                value: context.read<LockerRentBloc>(),
                child: RentSuccessPage(
                  fixedRent: state.flexibleRent!,
                  rentMonths: 0,
                  isFixed: false,
                  totalPaid: _totalPayment,
                ),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          centerTitle: true,
          title: const Text(
            'XÁC NHẬN THUÊ TỦ',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.35,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            children: [
              parentPage._buildPlanInfoCard(),
              const SizedBox(height: 16),

              // VOUCHER SECTION
              GestureDetector(
                onTap: _showVoucherSelector,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _selectedVoucher != null
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : Colors.grey.shade200,
                      width: _selectedVoucher != null ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.ticketPercent,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedVoucher != null
                                  ? 'Đã áp dụng voucher'
                                  : 'Thêm Voucher khuyến mãi',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedVoucher != null
                                  ? (_selectedVoucher!.campaignTitle.isNotEmpty
                                        ? _selectedVoucher!.campaignTitle
                                        : _selectedVoucher!.code)
                                  : 'Chọn hoặc nhập mã ưu đãi',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _selectedVoucher != null
                                    ? AppColors.primary
                                    : Colors.black54,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // INJECTED REBUILT PAYMENT CARD WITH RECALCULATED STATE
              parentPage._cardWrapper(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chi phí & Thanh toán',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        letterSpacing: -0.4,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 18),
                    parentPage._detailRow('Gói hội viên', args.activePlanName),
                    const SizedBox(height: 14),
                    parentPage._detailRow(
                      args.isFixed ? 'Đơn giá' : 'Đơn giá (Mỗi block)',
                      '${_formatMoney(args.unitPrice)} / ${args.blockDuration} ${EnumTranslator.translateFeeBlockUnit(args.blockUnit)}',
                    ),
                    if (!args.isFixed) ...[
                      const SizedBox(height: 14),
                      parentPage._detailRow(
                        'Phí trả trước (${args.initialBlocks % 1 == 0 ? args.initialBlocks.toInt() : args.initialBlocks.toStringAsFixed(2)} block)',
                        _formatMoney(args.price),
                      ),
                    ],
                    if (args.isFixed) ...[
                      const SizedBox(height: 14),
                      parentPage._detailRow(
                        'Số tháng thuê',
                        '${args.durationMonths} Tháng',
                      ),
                      const SizedBox(height: 14),
                      parentPage._detailRow(
                        'Phí thuê gốc',
                        _formatMoney(args.price),
                      ),
                    ],
                    const SizedBox(height: 14),
                    parentPage._detailRow(
                      'Giảm giá gói ${args.activePlanName}',
                      '- ${_formatMoney(args.discount)}',
                    ),
                    if (_voucherDiscount > 0) ...[
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                            child: Text(
                              'Voucher giảm giá',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              '- ${_formatMoney(_voucherDiscount)}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Divider(color: Colors.grey.shade200, height: 1),
                    ),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Tổng thanh toán',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            _formatMoney(_totalPayment),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 30,
                              color: AppColors.success,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    parentPage._detailRow(
                      'Số dư ví sau thanh toán',
                      _formatMoney(_walletAfterPayment),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              parentPage._buildImportantNoteCard(),
              const SizedBox(height: 90),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: BlocBuilder<LockerRentBloc, LockerRentState>(
              builder: (context, state) {
                return ElevatedButton(
                  onPressed: state.isSubmitting
                      ? null
                      : () {
                          if (args.cabinetId.isEmpty || args.lockerId.isEmpty) {
                            SmartDialog.showToast(
                              'Thiếu thông tin cabinet/locker để thuê.',
                            );
                            return;
                          }
                          _showOpenOptionDialog(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: AppColors.success.withValues(alpha: 0.4),
                    shape: const StadiumBorder(),
                  ),
                  child: state.isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Thanh toán ${_formatMoney(_totalPayment)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class RentSuccessPage extends StatelessWidget {
  final FixedRentEntity fixedRent;
  final int rentMonths;
  final int? rentDays;
  final int totalPaid;
  final bool isFixed;

  const RentSuccessPage({
    super.key,
    required this.fixedRent,
    required this.rentMonths,
    this.rentDays,
    required this.totalPaid,
    this.isFixed = true,
  });

  String _formatMoney(int amount) {
    return NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    ).format(amount).replaceAll('\u00a0', ' ');
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '--/--/----';
    return DateFormat('dd/MM/yyyy').format(value);
  }

  DateTime? _displayEndDate() {
    final start = fixedRent.orderDetail.rentStartDate;
    if (start == null) return null;
    if (rentDays != null && rentDays! > 0) {
      return start.add(Duration(days: rentDays!));
    }
    return DateTime(start.year, start.month + rentMonths, start.day);
  }

  @override
  Widget build(BuildContext context) {
    final total = totalPaid;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE5F7EC),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF16A34A),
                  size: 54,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Thanh toán thành công',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _formatMoney(total),
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông tin thuê',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _info('Gói thuê', fixedRent.pricing.name),
                    _info('Mã đơn', fixedRent.order.orderCode),
                    _info('OTP mở tủ', fixedRent.accessCode.code),
                    _info('Locker', fixedRent.orderDetail.lockerId),
                    _info(
                      'Trạng thái phần cứng',
                      EnumTranslator.translateHwStatus(
                        fixedRent.locker.hwState ?? 'UNKNOWN',
                      ),
                    ),
                    _info(
                      'Bắt đầu',
                      _formatDate(fixedRent.orderDetail.rentStartDate),
                    ),
                    if (isFixed)
                      _info('Kết thúc', _formatDate(_displayEndDate())),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              shape: const StadiumBorder(),
            ),
            child: const Text(
              'Về trang chủ',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
