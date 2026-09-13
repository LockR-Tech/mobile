import 'dart:async';
import 'package:smart_laundry_locker/core/services/app_event_bus.dart';
import 'package:smart_laundry_locker/features/orders/domain/entities/order.dart';
import 'package:smart_laundry_locker/features/orders/domain/entities/order_detail.dart';
import 'package:smart_laundry_locker/features/orders/presentation/providers/order_injection.dart';
import 'package:smart_laundry_locker/features/orders/presentation/providers/order_provider.dart';
import 'package:smart_laundry_locker/features/locker/domain/entities/cabinet.dart';
import 'package:smart_laundry_locker/features/locker/presentation/providers/locker_provider.dart';
import 'package:smart_laundry_locker/features/locker/presentation/providers/locker_injection.dart';
import 'package:smart_laundry_locker/features/delegations/presentation/providers/delegation_provider.dart';
import 'package:smart_laundry_locker/features/delegations/presentation/providers/delegation_injection.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/profile_provider.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/profile_injection.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';

import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:smart_laundry_locker/features/maintenance/presentation/pages/create_report_page.dart';
import 'package:smart_laundry_locker/features/delegations/presentation/pages/search_delegatee_page.dart';
import 'package:smart_laundry_locker/shared/widgets/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/orders/presentation/widgets/pulsing_report_icon.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:smart_laundry_locker/core/utils/enum_translator.dart';
import 'package:smart_laundry_locker/features/orders/presentation/widgets/order_status_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerOrderDetailPage extends StatefulWidget {
  final Order? order;
  final String orderId;

  const CustomerOrderDetailPage({super.key, required this.orderId, this.order});

  @override
  State<CustomerOrderDetailPage> createState() =>
      _CustomerOrderDetailPageState();
}

class _CustomerOrderDetailPageState extends State<CustomerOrderDetailPage> {
  late OrderProvider _provider;
  late LockerProvider _lockerProvider;
  late DelegationProvider _delegationProvider;
  late ProfileProvider _profileProvider;
  String? _fetchedLockerName;
  Cabinet? _originCabinet;
  Cabinet? _destinationCabinet;
  bool _isLoadingCabinets = false;
  StreamSubscription<AppEvent>? _eventSub;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient();
    _provider = OrderInjection.provideOrderProvider(apiClient);

    final currentId = widget.order?.id ?? widget.orderId;
    _eventSub = AppEventBus.instance.events.listen((event) {
      if (!mounted) return;
      if (event is OrderChangedEvent &&
          (event.orderId == null || event.orderId == currentId)) {
        _provider.fetchOrderDetail(currentId);
      }
    });
    _lockerProvider = LockerInjection.provideLockerProvider(apiClient);
    _delegationProvider = DelegationInjection.provideDelegationProvider(
      apiClient,
    );
    _profileProvider = ProfileInjection.provideProfileProvider(apiClient);

    _delegationProvider.fetchDelegationByOrderId(currentId);
    _profileProvider.loadProfile();

    _provider.fetchOrderDetail(currentId).then((_) async {
      final order = _provider.selectedOrder ?? widget.order;
      final details = _getDetails(_provider);

      if (details.isNotEmpty) {
        // Safe check for logistics before fetching rented locker detail
        final bool shouldFetchLocker = !(order?.isLogistics ?? false);

        if (shouldFetchLocker) {
          unawaited(_lockerProvider.getRentedLockerDetail(details.first.id));
          if (details.first.lockerId != null) {
            final locker = await _lockerProvider.getLockerById(
              details.first.lockerId!,
            );
            if (mounted && locker != null) {
              setState(() {
                _fetchedLockerName = locker.displayPosition;
              });
            }
          }
        }
      }

      // Load cabinets if logistics
      if (order != null && order.isLogistics) {
        await _loadCabinets(order);
      }
    });
  }

  Future<void> _loadCabinets(Order order) async {
    if (!mounted) return;
    setState(() => _isLoadingCabinets = true);

    try {
      if (order.originCabinetId != null) {
        _originCabinet = await _lockerProvider.getCabinetById(
          order.originCabinetId!,
        );
      }
      if (order.destinationCabinetId != null) {
        _destinationCabinet = await _lockerProvider.getCabinetById(
          order.destinationCabinetId!,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingCabinets = false);
    }
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _provider.dispose();
    _lockerProvider.dispose();
    _delegationProvider.dispose();
    super.dispose();
  }

  List<OrderDetail> _getDetails(OrderProvider provider) {
    return provider.orderDetails;
  }

  String _formatRentalDuration(int totalMinutes) {
    if (totalMinutes < 60) {
      return '$totalMinutes phút';
    }
    final int hours = totalMinutes ~/ 60;
    final int minutes = totalMinutes % 60;
    if (minutes == 0) {
      return '$hours giờ';
    }
    return '$hours giờ $minutes phút';
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _provider),
        ChangeNotifierProvider.value(value: _delegationProvider),
        ChangeNotifierProvider.value(value: _profileProvider),
      ],
      child: Consumer3<OrderProvider, DelegationProvider, ProfileProvider>(
        builder:
            (
              context,
              orderProvider,
              delegationProvider,
              profileProvider,
              child,
            ) {
              final order = orderProvider.selectedOrder ?? widget.order;
              final details = _getDetails(orderProvider);
              final profile = profileProvider.profile;

              if (order == null) {
                return const Scaffold(
                  appBar: CustomAppBar(
                    title: 'Chi tiết đơn hàng',
                    showBackButton: true,
                  ),
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // Logic to select correct OrderDetail for OTP and info
              OrderDetail? displayDetail;
              if (order.isLogistics && details.isNotEmpty) {
                final currentUserId = profile?.id;
                final currentPhone = profile?.phoneNumber;
                final isSender =
                    currentUserId != null &&
                    currentUserId ==
                        order.userId; // Order creator usually sender

                // Check senderId and receiverId/receiverPhone on order details
                final hasSenderMatch = details.any(
                  (d) => currentUserId != null && d.senderId == currentUserId,
                );
                final hasReceiverMatch = details.any(
                  (d) =>
                      (currentUserId != null &&
                          d.receiverId == currentUserId) ||
                      (currentPhone != null &&
                          currentPhone.isNotEmpty &&
                          d.receiverPhone == currentPhone),
                );

                if (hasReceiverMatch) {
                  // Current user is receiver, show pickup detail (index 1 if exists)
                  displayDetail = details.length > 1
                      ? details[1]
                      : details.first;
                } else if (hasSenderMatch || isSender) {
                  // Current user is sender, show dropoff detail (index 0)
                  displayDetail = details.first;
                } else {
                  displayDetail = details.length > 1
                      ? details[1]
                      : details.first;
                }
              } else {
                displayDetail = details.isNotEmpty ? details.first : null;
              }

              return Scaffold(
                backgroundColor: Colors.grey[50],
                appBar: CustomAppBar(
                  title: 'Chi tiết đơn hàng',
                  showBackButton: true,
                  actions: [
                    IconButton(
                      icon: const Icon(
                        LucideIcons.refreshCw,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onPressed: () async {
                        final String currentId =
                            widget.order?.id ?? widget.orderId;
                        await _provider.fetchOrderDetail(currentId);
                        await _delegationProvider.fetchDelegationByOrderId(
                          currentId,
                        );
                        SmartDialog.showToast('Đã cập nhật thông tin');
                      },
                    ),
                    if (order.status == 'ACTIVE')
                      PulsingReportIcon(
                        onPressed: () => _handleReportIssue(
                          context,
                          order,
                          details,
                          displayDetail,
                        ),
                      ),
                  ],
                ),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(order),
                      _buildRouteInfo(order, details),
                      _buildLogisticsStatusBanner(order, displayDetail),
                      if (displayDetail != null &&
                          order.status != 'LOCKED_BY_BALANCE' &&
                          displayDetail.accessCode != null &&
                          displayDetail.accessCode!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildOTPCard(displayDetail.accessCode!),
                      ],
                      if (order.isLogistics && displayDetail != null) ...[
                        const SizedBox(height: 20),
                        _buildLogisticsReceiverInfo(displayDetail),
                        const SizedBox(height: 20),
                        _buildPhotoEvidence(displayDetail),
                      ],
                      _buildJammedWarningBanner(details),
                      const SizedBox(height: 20),
                      if (!order.isLogistics)
                        _buildLockerInfo(order, displayDetail),

                      const SizedBox(height: 20),
                      if (!order.isLogistics) _buildOrderItems(details),
                      const SizedBox(height: 20),

                      _buildRentingDetails(order, displayDetail),
                      if (order.status == 'ACTIVE') ...[
                        const SizedBox(height: 20),
                        _buildDelegationInfo(
                          context,
                          order,
                          delegationProvider,
                          details,
                        ),
                      ],
                      const SizedBox(height: 20),
                      if (order.status == 'ACTIVE')
                        _buildActionButtons(
                          context,
                          order,
                          details,
                          displayDetail,
                        ),
                      if (order.status == 'LOCKED_BY_BALANCE')
                        _buildLockedActionButtons(context, order),
                    ],
                  ),
                ),
              );
            },
      ),
    );
  }

  Widget _buildHeader(Order order) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đơn hàng #${order.orderCode}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Thời gian tạo đơn: ${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt.toLocal())}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 4,
                child: Align(
                  alignment: Alignment.topRight,
                  child: OrderStatusColors.orderBadge(order.status),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOTPCard(String otp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AISLShadcnTheme.navyPrimary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AISLShadcnTheme.navyPrimary.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AISLShadcnTheme.navyPrimary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.keyRound,
                size: 18,
                color: const Color(0xFF0A2342),
              ),
              SizedBox(width: 8),
              Text(
                'Mã mở tủ (OTP)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF0A2342).withOpacity(0.2),
              ),
            ),
            child: Text(
              otp,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 8,
                color: const Color(0xFF0A2342),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Dùng mã này để mở tủ tại Kiosk',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockerInfo(Order order, OrderDetail? detail) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                LucideIcons.package,
                size: 20,
                color: const Color(0xFF0A2342),
              ),
              SizedBox(width: 10),
              Text(
                'Thông tin tủ locker',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Note: Order entity in domain doesn't have location/cabinet names yet,
          // usually these are fetched or passed from summary page.
          _buildInfoRow('ID Tủ', order.rentalCabinetId ?? 'N/A'),
          const Divider(height: 24),
          _buildInfoRow(
            'Ngăn tủ',
            _fetchedLockerName ?? detail?.formattedLockerLabel ?? 'N/A',
          ),
          if (detail?.hwStatus != null && detail!.hwStatus!.isNotEmpty) ...[
            const Divider(height: 24),
            _buildInfoRow(
              'Trạng thái tủ',
              EnumTranslator.translateHwStatus(detail.hwStatus!),
            ),
          ],
          if (detail?.itemType != null && detail!.itemType!.isNotEmpty) ...[
            const Divider(height: 24),
            _buildInfoRow(
              'Loại mặt hàng',
              detail.itemType == 'FOOD' ? 'Đồ ăn' : 'Hàng hóa khác',
            ),
          ],
          // if (detail?.accessCode != null && detail!.accessCode!.isNotEmpty) ...[
          //   const Divider(height: 24),
          //   _buildInfoRow(
          //     'Mã mở tủ kiosk',
          //     detail.accessCode!,
          //     valueColor: const Color(0xFF0A2342),
          //     valueFontWeight: FontWeight.bold,
          //   ),
          // ],
        ],
      ),
    );
  }

  Widget _buildOrderItems(List<OrderDetail> details) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.list, size: 20, color: const Color(0xFF0A2342)),
              SizedBox(width: 10),
              Text(
                'Danh sách ngăn',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: details.length,
            separatorBuilder: (context, index) => const Divider(height: 20),
            itemBuilder: (context, index) {
              final d = details[index];
              return Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A2342).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (index + 1).toString(),
                        style: const TextStyle(
                          color: const Color(0xFF0A2342),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fetchedLockerName ?? d.formattedLockerLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Mã: ${d.code}',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OrderStatusColors.detailBadge(d.status),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRentingDetails(Order order, OrderDetail? detail) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              Icon(
                order.isLogistics ? LucideIcons.creditCard : LucideIcons.clock,
                size: 20,
                color: const Color(0xFF0A2342),
              ),
              const SizedBox(width: 10),
              Text(
                order.isLogistics ? 'Chi phí & Thanh toán' : 'Chi tiết thuê',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            'Bắt đầu',
            DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt.toLocal()),
          ),
          const Divider(height: 24),
          _buildInfoRow(
            'Kết thúc dự kiến',
            order.plannedEndTime != null
                ? DateFormat(
                    'dd/MM/yyyy HH:mm',
                  ).format(order.plannedEndTime!.toLocal())
                : 'N/A',
          ),
          // const Divider(height: 24),
          // _buildInfoRow(
          //   'Hình thức thuê',
          //   order.isPrepaid ? 'Trả trước' : 'Trả sau',
          // ),
          // const Divider(height: 24),
          _buildInfoRow(
            'Giá thuê hiện tại',
            currencyFormat.format(order.currentRate),
          ),
          const Divider(height: 24),
          _buildInfoRow(
            'Phí tích lũy',
            currencyFormat.format(order.accumulatedFee),
          ),
          const Divider(height: 24),
          _buildInfoRow(
            'Tổng đã thu',
            currencyFormat.format(order.totalCollected),
            valueColor: const Color(0xFF0A2342),
            valueFontWeight: FontWeight.bold,
          ),
          if (order.voucherName != null && order.voucherName!.isNotEmpty) ...[
            const Divider(height: 24),
            _buildInfoRow(
              'Voucher áp dụng',
              order.voucherName!,
              valueColor: Colors.green,
              valueFontWeight: FontWeight.bold,
            ),
          ],
          if (order.isPersonalRental) ...[
            const Divider(height: 24),
            _buildInfoRow(
              'Thời gian đã thuê',
              _formatRentalDuration(order.totalTimeRent),
              valueColor: Colors.blue,
              valueFontWeight: FontWeight.bold,
            ),
          ],
          if (order.accumulatedFee != order.totalCollected) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  unawaited(_handlePayDebt(context, order));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Thanh toán nợ phí'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handlePayDebt(BuildContext context, Order order) async {
    SmartDialog.showLoading<void>(msg: 'Đang xử lý thanh toán...');
    final success = await _provider.payOverdueFee(order.id);
    SmartDialog.dismiss<void>();

    if (success) {
      SmartDialog.showToast('Thanh toán thành công!');
      // Refresh to update status and show regular buttons
      await _provider.fetchOrderDetail(order.id);
    } else {
      SmartDialog.showToast('Lỗi: ${_provider.error ?? "Thanh toán thất bại"}');
    }
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    FontWeight? valueFontWeight,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 14),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor ?? Colors.black87,
              fontWeight: valueFontWeight ?? FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJammedWarningBanner(List<OrderDetail> details) {
    final hasJammed = details.any(
      (d) => d.hwStatus != null && d.hwStatus!.toUpperCase().contains('JAMMED'),
    );

    if (!hasJammed) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.triangleAlert, color: Colors.red.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CẢNH BÁO: Cửa tủ bị kẹt!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.red.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Hệ thống ghi nhận ngăn tủ đang bị kẹt. Vui lòng liên hệ hỗ trợ kỹ thuật ngay hoặc kiểm tra lại ngăn tủ.',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogisticsStatusBanner(Order order, OrderDetail? detail) {
    if (!order.isLogistics || detail == null) return const SizedBox.shrink();

    if (detail.status == 'AWAITING_DROP') {
      return LogisticsTimerBanner(
        startTime: detail.createdAt,
        minutesLimit: 30,
      );
    }

    if (order.logisticsType == 'HOME_TO_LOCKER' &&
        detail.status == 'AWAITING_COURIER') {
      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: const Row(
          children: [
            Icon(LucideIcons.info, color: Colors.blue),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Lưu ý: Hệ thống sẽ tự động hủy đơn hàng nếu tài xế phải chờ quá lâu tại điểm lấy hàng.',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildActionButtons(
    BuildContext context,
    Order order,
    List<OrderDetail> details,
    OrderDetail? displayDetail,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          if (order.isPersonalRental) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      unawaited(_handleTemporaryOpen(context));
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: AISLShadcnTheme.navyPrimary.withOpacity(0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.lockOpen, size: 18),
                        SizedBox(width: 8),
                        Text('Mở tủ tạm thời'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _showReturnConfirmation(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AISLShadcnTheme.navyPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.cornerDownLeft,
                          size: 18,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8),
                        Text('Trả tủ', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  if (displayDetail != null) {
                    unawaited(_handleRecreateAccessCode(displayDetail));
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AISLShadcnTheme.navyPrimary.withOpacity(0.5),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.refreshCcw, size: 18),
                    SizedBox(width: 8),
                    Text('Tạo mã mở tủ mới'),
                  ],
                ),
              ),
            ),
          ],
          if (order.isLogistics &&
              details.isNotEmpty &&
              details.first.status != 'IN_TRANSIT' &&
              details.first.status != 'COMPLETED' &&
              details.first.status != 'COLLECTED') ...[
            if (order.isPersonalRental) const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showCancelConfirmation(context, order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.circleX, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Hủy đơn hàng',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context, Order order) {
    SmartDialog.show<void>(
      builder: (_) => Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.trash2,
                color: Colors.red,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Xác nhận hủy đơn',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Bạn có chắc chắn muốn hủy đơn hàng này không? Hệ thống sẽ thu một khoản phí hủy và hoàn trả lại phần còn lại.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => SmartDialog.dismiss<void>(),
                    child: const Text(
                      'Không',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      SmartDialog.dismiss<void>();
                      await _handleCancelOrder(context, order.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'Xác nhận',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCancelOrder(BuildContext context, String orderId) async {
    // Hủy đơn qua order-service thật (PUT /api/orders/{id}/cancel) — luồng
    // logistics/courier cũ đã gỡ khỏi dự án.
    final id = int.tryParse(orderId);
    if (id == null) {
      SmartDialog.showToast('Mã đơn không hợp lệ');
      return;
    }
    SmartDialog.showLoading<void>(msg: 'Đang hủy đơn hàng...');
    try {
      await LockerOpsService().cancelOrder(id);
      SmartDialog.dismiss<void>();
      SmartDialog.showToast('Đã hủy đơn hàng thành công');
      await _provider.fetchOrderDetail(orderId);
    } catch (e) {
      SmartDialog.dismiss<void>();
      SmartDialog.showToast(LockerOpsService.errorMessage(e));
    }
  }

  Future<void> _handleRecreateAccessCode(OrderDetail detail) async {
    if (detail.id.isEmpty) return;

    SmartDialog.showLoading<void>(msg: 'Đang tạo mã mới...');
    final result = await _provider.recreateAccessCode(detail.id);
    SmartDialog.dismiss<void>();

    if (result) {
      SmartDialog.showToast('Tạo mã thành công!');
      // Refresh order detail to show the new code
      await _provider.fetchOrderDetail(widget.order?.id ?? widget.orderId);
    } else {
      SmartDialog.showToast(
        'Lỗi: ${_provider.error ?? "Không thể tạo mã mới"}',
      );
    }
  }

  Future<void> _handleReportIssue(
    BuildContext context,
    Order order,
    List<OrderDetail> details,
    OrderDetail? displayDetail,
  ) async {
    final activeDetail =
        displayDetail ?? (details.isNotEmpty ? details.first : null);

    if (activeDetail == null || activeDetail.lockerId == null) {
      SmartDialog.showToast('Không tìm thấy thông tin tủ');
      return;
    }

    final cabinetId = order.rentalCabinetId ?? '';
    if (cabinetId.isEmpty) {
      SmartDialog.showToast('Không có thông tin trạm tủ');
      return;
    }

    SmartDialog.showLoading<void>(msg: 'Đang lấy thông tin tủ...');
    final lockerId = activeDetail.lockerId!;
    final cabinet = await _lockerProvider.getCabinetById(cabinetId);
    final locker = await _lockerProvider.getLockerById(lockerId);
    SmartDialog.dismiss<void>();

    if (cabinet == null || locker == null) {
      // Fallback in case fetch fails
      SmartDialog.showToast('Không lấy được thông tin chi tiết tủ, sử dụng ID');
    }

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => CreateReportPage(
          cabinetId: cabinetId,
          lockerId: lockerId,
          cabinetName: cabinet?.name ?? cabinetId,
          lockerName: locker != null
              ? locker.displayPosition
              : _fetchedLockerName ?? activeDetail.lockerLabel,
          locationName: cabinet?.locationName,
        ),
      ),
    );
  }

  Widget _buildLockedActionButtons(BuildContext context, Order order) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.triangleAlert,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tủ đang bị khóa do nợ phí. Vui lòng thanh toán để tiếp tục sử dụng.',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _handlePayDebt(context, order),
              style: ElevatedButton.styleFrom(
                backgroundColor: AISLShadcnTheme.navyPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Thanh toán để mở tủ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showReturnConfirmation(BuildContext context) {
    SmartDialog.show<void>(
      builder: (_) => Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0A2342).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.triangleAlert,
                color: const Color(0xFF0A2342),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Xác nhận trả tủ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Bạn có chắc chắn muốn trả tủ ngay bây giờ? Sau khi xác nhận, ngăn tủ sẽ được mở và phiên thuê sẽ kết thúc.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => SmartDialog.dismiss<void>(),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      SmartDialog.dismiss<void>();
                      await _handleReturnLocker(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AISLShadcnTheme.navyPrimary,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'Xác nhận',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTemporaryOpen(BuildContext context) async {
    final details = _getDetails(_provider);
    if (details.isEmpty || details.first.lockerId == null) {
      SmartDialog.showToast('Không tìm thấy thông tin tủ');
      return;
    }

    final lockerId = details.first.lockerId!;
    SmartDialog.showLoading<void>(msg: 'Đang mở tủ...');

    final result = await _lockerProvider.openLockerTemporarily(lockerId);

    SmartDialog.dismiss<void>();

    result.fold(
      (failure) => SmartDialog.showToast('Lỗi: ${failure.message}'),
      (success) => SmartDialog.showToast('Đã gửi lệnh mở tủ tạm thời!'),
    );
  }

  Future<void> _handleReturnLocker(BuildContext context) async {
    final details = _getDetails(_provider);
    if (details.isEmpty || details.first.lockerId == null) {
      SmartDialog.showToast('Không tìm thấy thông tin tủ');
      return;
    }

    final lockerId = details.first.lockerId!;
    SmartDialog.showLoading<void>(msg: 'Đang xử lý trả tủ...');

    final result = await _lockerProvider.finishRental(lockerId);

    SmartDialog.dismiss<void>();

    result.fold((failure) => SmartDialog.showToast('Lỗi: ${failure.message}'), (
      success,
    ) {
      SmartDialog.showToast('Trả tủ thành công!');
      _provider.fetchOrderDetail(widget.order!.id).then((_) {
        setState(() {});
      });
    });
  }

  Widget _buildDelegationInfo(
    BuildContext context,
    Order order,
    DelegationProvider delegationProvider,
    List<OrderDetail> details,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(LucideIcons.users, size: 20, color: Colors.blue),
                  SizedBox(width: 10),
                  Text(
                    'Ủy quyền lấy hàng',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              if (delegationProvider.isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (delegationProvider.currentDelegation != null &&
              delegationProvider.currentDelegation!.isActive)
            _buildActiveDelegationCard(context, delegationProvider)
          else
            _buildEmptyDelegationCard(
              context,
              order,
              delegationProvider,
              details,
            ),
        ],
      ),
    );
  }

  Widget _buildActiveDelegationCard(
    BuildContext context,
    DelegationProvider delegationProvider,
  ) {
    final delegation = delegationProvider.currentDelegation!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.userCheck,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Đã ủy quyền cho:',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    Text(
                      delegation.delegateeId ??
                          'N/A', // If we don't return email, change later
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // Show Delegation Detail Modal
                    _showDelegationDetailModal(context, delegationProvider);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Thông tin ủy quyền',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDelegationDetailModal(
    BuildContext context,
    DelegationProvider delegationProvider,
  ) {
    final delegation = delegationProvider.currentDelegation!;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thông tin ủy quyền',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              _buildInfoRow(
                'Trạng thái',
                'Đang hoạt động',
                valueColor: Colors.blue,
              ),
              const Divider(height: 24),
              _buildInfoRow(
                'Ngày ủy quyền',
                DateFormat('dd/MM/yyyy HH:mm').format(delegation.createdAt),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close modal
                    _showRevokeConfirmation(
                      context,
                      delegationProvider,
                      delegation.id,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Hủy quyền'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showRevokeConfirmation(
    BuildContext context,
    DelegationProvider delegationProvider,
    String delegationId,
  ) {
    SmartDialog.show<void>(
      builder: (_) => Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.userX, color: Colors.red, size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'Xác nhận hủy ủy quyền',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Bạn có chắc chắn muốn hủy quyền của người này không? Người được ủy quyền sẽ không thể lấy hàng nữa.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => SmartDialog.dismiss<void>(),
                    child: const Text(
                      'Không',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      SmartDialog.dismiss<void>();
                      SmartDialog.showLoading<void>(msg: 'Đang hủy quyền...');
                      final success = await delegationProvider.revokeDelegation(
                        delegationId,
                      );
                      SmartDialog.dismiss<void>();
                      if (success) {
                        SmartDialog.showToast('Hủy quyền thành công');
                        if (mounted)
                          delegationProvider.fetchDelegationByOrderId(
                            widget.order!.id,
                          );
                      } else {
                        SmartDialog.showToast(
                          delegationProvider.error ?? 'Hủy quyền thất bại',
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'Xác nhận',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDelegationCard(
    BuildContext context,
    Order order,
    DelegationProvider delegationProvider,
    List<OrderDetail> details,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.userPlus, size: 32, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            'Chưa có người được ủy quyền',
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to SearchDelegateePage
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (routeContext) =>
                        _buildSearchDelegateeRoute(order, delegationProvider),
                  ),
                ).then((_) {
                  if (context.mounted)
                    delegationProvider.fetchDelegationByOrderId(order.id);
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Ủy quyền',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchDelegateeRoute(Order order, DelegationProvider provider) {
    return ChangeNotifierProvider.value(
      value: provider,
      child: SearchDelegateePage(order: order),
    );
  }

  Widget _buildRouteInfo(Order order, List<OrderDetail> details) {
    if (!order.isLogistics) return const SizedBox.shrink();

    OrderDetail? originDetail;
    OrderDetail? destDetail;

    if (details.isNotEmpty) {
      final sorted = List<OrderDetail>.from(details)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      originDetail = sorted.first;
      if (sorted.length >= 2) {
        destDetail = sorted.last;
      }
    }

    final String originLabel;
    final String originName;
    double? originLat;
    double? originLng;

    if (order.logisticsType == 'HOME_TO_LOCKER') {
      originLabel = 'Địa chỉ lấy hàng';
      originName = order.pickupAddress ?? 'N/A';
      originLat = order.pickupLatitude;
      originLng = order.pickupLongitude;
    } else {
      originLabel = 'Tủ gửi (Origin)';
      final parts = [
        originDetail?.locationSendName ?? _originCabinet?.locationName,
        _originCabinet?.name,
        originDetail?.formattedPosition,
      ].whereType<String>().toList();
      originName = parts.isEmpty
          ? (order.originCabinetId != null ? 'Đang tải...' : 'N/A')
          : parts.join(' - ');
      originLat =
          originDetail?.locationSendLatitude ?? _originCabinet?.latitude;
      originLng =
          originDetail?.locationSendLongitude ?? _originCabinet?.longitude;
    }

    final String destLabel = 'Tủ nhận (Destination)';
    final List<String> destParts = [
      _destinationCabinet?.locationName,
      _destinationCabinet?.name,
      (destDetail ?? originDetail)?.formattedPosition,
    ].whereType<String>().toList();
    final String destName = destParts.isEmpty
        ? (order.destinationCabinetId != null ? 'Đang tải...' : 'N/A')
        : destParts.join(' - ');
    final double? destLat = _destinationCabinet?.latitude;
    final double? destLng = _destinationCabinet?.longitude;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              const Icon(LucideIcons.route, size: 20, color: Colors.blue),
              const SizedBox(width: 10),
              const Text(
                'Thông tin lộ trình',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              if (_isLoadingCabinets) ...[
                const SizedBox(width: 10),
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          _buildRoutePoint(
            icon: LucideIcons.package,
            label: originLabel,
            name: originName,
            color: const Color(0xFF0369A1),
            timestamp: originDetail?.pickedUpAt != null
                ? 'Đã lấy: ${DateFormat('HH:mm dd/MM').format(originDetail!.pickedUpAt!.toLocal())}'
                : 'Đã lấy: Chưa lấy hàng',
            onMapTap: originLat != null && originLng != null
                ? () => _launchMap(originLat!, originLng!, originName)
                : null,
          ),
          const Padding(
            padding: EdgeInsets.only(left: 17),
            child: SizedBox(
              height: 24,
              child: VerticalDivider(
                width: 2,
                thickness: 2,
                color: Color(0xFFE5E7EB),
              ),
            ),
          ),
          _buildRoutePoint(
            icon: LucideIcons.mapPin,
            label: destLabel,
            name: destName,
            color: const Color(0xFFC2410C),
            timestamp: destDetail?.pickedUpAt != null
                ? 'Đã nhận: ${DateFormat('HH:mm dd/MM').format(destDetail!.pickedUpAt!.toLocal())}'
                : 'Đã nhận: Chưa nhận hàng',
            onMapTap: destLat != null && destLng != null
                ? () => _launchMap(destLat, destLng, destName)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildLogisticsReceiverInfo(OrderDetail detail) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.user, size: 20, color: Colors.blue),
              SizedBox(width: 10),
              Text(
                'Thông tin người nhận',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Họ tên', detail.receiverName ?? 'N/A'),
          const Divider(height: 24),
          _buildInfoRow('Số điện thoại', detail.receiverPhone ?? 'N/A'),
          const Divider(height: 24),
          _buildInfoRow('Địa chỉ nhận', detail.receiverAddress ?? 'N/A'),
          if (detail.itemType != null && detail.itemType!.isNotEmpty) ...[
            const Divider(height: 24),
            _buildInfoRow(
              'Loại mặt hàng',
              detail.itemType == 'FOOD' ? 'Đồ ăn' : 'Hàng hóa khác',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoEvidence(OrderDetail detail) {
    if (detail.imageUrls.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.camera, size: 20, color: Colors.blue),
              SizedBox(width: 10),
              Text(
                'Hình ảnh lấy hàng',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: detail.imageUrls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    detail.imageUrls[index],
                    height: 120,
                    width: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 120,
                      width: 120,
                      color: Colors.grey[200],
                      child: const Icon(
                        LucideIcons.image,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutePoint({
    required IconData icon,
    required String label,
    required String name,
    required Color color,
    String? timestamp,
    VoidCallback? onMapTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                  if (onMapTap != null)
                    GestureDetector(
                      onTap: onMapTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.map, size: 14, color: color),
                            const SizedBox(width: 4),
                            Text(
                              'Bản đồ',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              if (timestamp != null) ...[
                const SizedBox(height: 4),
                Text(
                  timestamp,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _launchMap(double lat, double lng, String title) async {
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      SmartDialog.showToast('Không mở được bản đồ.');
    }
  }
}

class LogisticsTimerBanner extends StatefulWidget {
  final DateTime startTime;
  final int minutesLimit;

  const LogisticsTimerBanner({
    super.key,
    required this.startTime,
    this.minutesLimit = 30,
  });

  @override
  State<LogisticsTimerBanner> createState() => _LogisticsTimerBannerState();
}

class _LogisticsTimerBannerState extends State<LogisticsTimerBanner> {
  late Timer _timer;
  late Duration _timeLeft;

  @override
  void initState() {
    super.initState();
    _timeLeft = Duration.zero; // initial stub
    _calculateTimeLeft();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _calculateTimeLeft(),
    );
  }

  void _calculateTimeLeft() {
    final endTime = widget.startTime.add(
      Duration(minutes: widget.minutesLimit),
    );
    final diff = endTime.difference(DateTime.now());
    if (mounted) {
      setState(() {
        _timeLeft = diff.isNegative ? Duration.zero : diff;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timeLeft == Duration.zero) {
      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: const Row(
          children: [
            Icon(LucideIcons.timer, color: Colors.red),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Đơn hàng đang được xử lý tự động hủy do quá hạn.',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final minutesStr = _timeLeft.inMinutes.toString().padLeft(2, '0');
    final secondsStr = (_timeLeft.inSeconds % 60).toString().padLeft(2, '0');
    final isUrgent = _timeLeft.inMinutes < 5;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUrgent ? Colors.red.shade50 : Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUrgent ? Colors.red.shade200 : Colors.amber.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.timer,
            color: isUrgent ? Colors.red : const Color(0xFF12355B),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thời gian chờ cất hàng',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isUrgent ? Colors.red : const Color(0xFF061A30),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Đơn hàng sẽ tự động hủy sau:',
                  style: TextStyle(
                    fontSize: 13,
                    color: isUrgent
                        ? Colors.red.shade700
                        : const Color(0xFF0A2342),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isUrgent ? Colors.red : const Color(0xFF12355B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$minutesStr:$secondsStr',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
