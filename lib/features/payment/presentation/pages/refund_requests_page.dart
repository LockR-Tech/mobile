import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/media/media_upload.dart';
import 'package:smart_laundry_locker/core/media/media_upload_service.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/features/payment/data/payment_service.dart';
import 'package:smart_laundry_locker/features/payment/data/user_bank_account.dart';
import 'package:smart_laundry_locker/features/wallet/data/vietnamese_banks.dart';
import 'package:smart_laundry_locker/shared/widgets/app_cached_image.dart';

class RefundRequestsPage extends StatefulWidget {
  const RefundRequestsPage({
    super.key,
    this.initialOrderId,
    this.initialOrder,
  });

  final int? initialOrderId;
  final Map<String, dynamic>? initialOrder;

  @override
  State<RefundRequestsPage> createState() => _RefundRequestsPageState();
}

class _RefundRequestsPageState extends State<RefundRequestsPage> {
  final _paymentService = PaymentService();
  final _lockerService = LockerOpsService();
  final _mediaUploadService = MediaUploadService();
  final _imagePicker = ImagePicker();

  int _selectedTab = 0; // 0: Danh sách, 1: Tạo yêu cầu
  bool _loadingRefunds = true;
  bool _isSubmitting = false;

  List<Map<String, dynamic>> _refunds = [];
  List<Map<String, dynamic>> _myOrders = [];
  Map<String, dynamic>? _selectedOrder;

  // Form controllers
  final _reasonController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountHolderController = TextEditingController();

  VietnameseBank? _selectedBank;
  UserBankAccount? _savedBankAccount;
  bool _saveAsDefault = true;

  XFile? _pickedXFile;
  File? _pickedImageFile;
  String? _base64ImageData;

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialOrderId != null || widget.initialOrder != null) {
      _selectedTab = 1; // Mở thẳng form tạo yêu cầu
    }
    _loadInitialData();
    // Tự động kiểm tra cập nhật mỗi 5 giây
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && _selectedTab == 0 && !_loadingRefunds) {
        _loadRefunds(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _reasonController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await _loadOrdersAndBank();
    await _loadRefunds();
  }

  Future<void> _loadRefunds({bool silent = false}) async {
    if (!silent) setState(() => _loadingRefunds = true);
    try {
      final orderIds = _myOrders
          .map((o) => _asInt(o['id']))
          .whereType<int>()
          .toList();
      final list = await _paymentService.myRefunds(orderIds: orderIds);
      if (mounted) {
        setState(() {
          final fetchedIds = list.map((r) => _asInt(r['id'])).whereType<int>().toSet();
          final localUnsynced = _refunds.where((r) => !fetchedIds.contains(_asInt(r['id']))).toList();
          _refunds = [...localUnsynced, ...list];
          if (!silent) _loadingRefunds = false;
        });
      }
    } catch (_) {
      if (mounted && !silent) setState(() => _loadingRefunds = false);
    }
  }

  int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  Future<void> _loadOrdersAndBank() async {
    try {
      final results = await Future.wait([
        _lockerService.myOrders().catchError((_) => <Map<String, dynamic>>[]),
        _paymentService.getSavedBankAccount().catchError((_) => null),
      ]);

      final orders = results[0] as List<Map<String, dynamic>>;
      final savedBank = results[1] as UserBankAccount?;

      if (mounted) {
        setState(() {
          _myOrders = orders;
          _savedBankAccount = savedBank;

          if (savedBank != null) {
            _accountNumberController.text = savedBank.accountNumber;
            _accountHolderController.text = savedBank.accountHolderName;
            _selectedBank = vietnameseBanks.firstWhere(
              (b) =>
                  b.code.toUpperCase() == savedBank.bankCode.toUpperCase() ||
                  b.shortName.toUpperCase() == savedBank.bankName.toUpperCase(),
              orElse: () => VietnameseBank(
                code: savedBank.bankCode,
                shortName: savedBank.bankName,
                name: savedBank.bankName,
                bin: '',
              ),
            );
          } else {
            _selectedBank = vietnameseBanks.firstWhere(
              (b) => b.code == 'MB',
              orElse: () => vietnameseBanks.first,
            );
          }

          // Pre-select order if initialOrderId provided
          if (widget.initialOrder != null) {
            _selectedOrder = widget.initialOrder;
          } else if (widget.initialOrderId != null) {
            _selectedOrder = orders.firstWhere(
              (o) => o['id'] == widget.initialOrderId,
              orElse: () => {'id': widget.initialOrderId},
            );
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final xfile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 75,
      );
      if (xfile == null) return;

      final file = File(xfile.path);
      final bytes = await file.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      setState(() {
        _pickedXFile = xfile;
        _pickedImageFile = file;
        _base64ImageData = base64String;
      });
    } catch (e) {
      SmartDialog.showToast('Không thể chọn ảnh: $e');
    }
  }

  void _openBankPicker() {
    showModalBottomSheet<VietnameseBank>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _BankPickerSheet(
        selected: _selectedBank,
        onSelect: (bank) {
          setState(() => _selectedBank = bank);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _openOrderPicker() {
    showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _OrderPickerSheet(
        orders: _myOrders,
        selected: _selectedOrder,
        onSelect: (order) {
          setState(() => _selectedOrder = order);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_selectedOrder == null) {
      SmartDialog.showToast('Vui lòng chọn đơn hàng cần hoàn tiền');
      return;
    }
    final orderId = _selectedOrder!['id'];
    if (orderId == null) {
      SmartDialog.showToast('Mã đơn hàng không hợp lệ');
      return;
    }

    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      SmartDialog.showToast('Vui lòng nhập lý do yêu cầu hoàn tiền');
      return;
    }

    final accNum = _accountNumberController.text.trim();
    final accHolder = _accountHolderController.text.trim();
    if (accNum.isEmpty || accHolder.isEmpty || _selectedBank == null) {
      SmartDialog.showToast('Vui lòng điền đầy đủ thông tin tài khoản ngân hàng nhận tiền');
      return;
    }

    // Xác định số tiền hoàn từ đơn
    num refundAmount = 0;
    if (_selectedOrder!['paidAmount'] is num && (_selectedOrder!['paidAmount'] as num) > 0) {
      refundAmount = _selectedOrder!['paidAmount'] as num;
    } else if (_selectedOrder!['totalPrice'] is num) {
      refundAmount = _selectedOrder!['totalPrice'] as num;
    }

    setState(() => _isSubmitting = true);
    SmartDialog.showLoading(msg: 'Đang gửi yêu cầu hoàn tiền...');

    try {
      String? uploadedUrl;
      // 1. Tải ảnh lên Cloudinary nếu có chọn ảnh
      if (_pickedXFile != null) {
        try {
          final uploads = await _mediaUploadService.uploadImages(
            [_pickedXFile!],
            MediaPurpose.reportEvidence,
          );
          if (uploads.isNotEmpty && uploads.first.secureUrl != null) {
            uploadedUrl = uploads.first.secureUrl;
          }
        } catch (uploadErr) {
          developer.log('Upload image error, fallback to data url: $uploadErr', name: 'Refund');
        }
      }
      // Fallback data URL nếu Cloudinary không khả dụng
      uploadedUrl ??= _base64ImageData;

      // Nhúng mã ảnh vào lý do để đảm bảo 100% không bị mất dù backend cũ hay mới
      final submitReason = (uploadedUrl != null && uploadedUrl.isNotEmpty)
          ? '$reason\n[Ảnh minh chứng: $uploadedUrl]'
          : reason;

      final newRefund = await _paymentService.requestRefund(
        orderId: (orderId is num) ? orderId.toInt() : int.parse('$orderId'),
        amount: refundAmount,
        reason: submitReason,
        customerAttachmentUrl: uploadedUrl,
        bankName: _selectedBank!.shortName,
        bankCode: _selectedBank!.code,
        accountNumber: accNum,
        accountHolderName: accHolder.toUpperCase(),
        saveAsDefault: _saveAsDefault,
      );

      SmartDialog.dismiss();
      SmartDialog.showToast('Đã gửi yêu cầu hoàn tiền thành công!');

      // Tạo bản ghi hoàn tiền hiển thị ngay lập tức trên UI
      final optimisticRefund = Map<String, dynamic>.from(newRefund);
      optimisticRefund['orderId'] ??= orderId;
      optimisticRefund['orderCode'] ??= _selectedOrder?['orderCode'];
      optimisticRefund['amount'] ??= refundAmount;
      optimisticRefund['reason'] ??= submitReason;
      optimisticRefund['customerAttachmentUrl'] ??= uploadedUrl;
      optimisticRefund['bankName'] ??= _selectedBank!.shortName;
      optimisticRefund['bankCode'] ??= _selectedBank!.code;
      optimisticRefund['accountNumber'] ??= accNum;
      optimisticRefund['accountHolderName'] ??= accHolder.toUpperCase();
      optimisticRefund['status'] ??= 'PENDING';
      optimisticRefund['requestedAt'] ??= DateTime.now().toIso8601String();

      // Reset form
      _reasonController.clear();
      setState(() {
        _refunds.insert(0, optimisticRefund);
        _pickedImageFile = null;
        _pickedXFile = null;
        _base64ImageData = null;
        _isSubmitting = false;
        _selectedTab = 0; // Chuyển về xem danh sách
      });

      _loadRefunds(silent: true);
    } catch (e) {
      SmartDialog.dismiss();
      setState(() => _isSubmitting = false);
      final msg = e.toString().contains('message:')
          ? e.toString().split('message:').last.replaceAll('}', '').trim()
          : '$e';
      SmartDialog.showToast('Lỗi: $msg');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A)),
          onPressed: () => AppRouter.backOrHome(context),
        ),
        title: const Text(
          'Hoàn tiền',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.helpCircle, color: Color(0xFF64748B), size: 20),
            tooltip: 'Quy định hoàn tiền',
            onPressed: _showRulesDialog,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    index: 0,
                    title: 'Yêu cầu của tôi',
                    count: _refunds.length,
                    icon: LucideIcons.history,
                  ),
                ),
                Expanded(
                  child: _buildTabButton(
                    index: 1,
                    title: 'Tạo yêu cầu mới',
                    icon: LucideIcons.plusCircle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _selectedTab == 0 ? _buildRefundsList() : _buildCreateRequestForm(),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String title,
    required IconData icon,
    int? count,
  }) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: DANH SÁCH YÊU CẦU HOÀN TIỀN CỦA TÔI
  // ---------------------------------------------------------------------------
  Widget _buildRefundsList() {
    if (_loadingRefunds) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_refunds.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadRefunds,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 60),
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(36),
                ),
                child: const Icon(LucideIcons.banknote, size: 36, color: Color(0xFF94A3B8)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có yêu cầu hoàn tiền nào',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Khi gặp sự cố tủ không mở, drone huỷ chuyến hoặc sự cố giặt ủi, bạn có thể tạo yêu cầu hoàn tiền tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _selectedTab = 1),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Tạo yêu cầu hoàn tiền ngay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRefunds,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _refunds.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final rf = _refunds[index];
          return _buildRefundCard(rf);
        },
      ),
    );
  }

  Widget _buildRefundCard(Map<String, dynamic> rf) {
    final status = '${rf['status'] ?? 'PENDING'}'.toUpperCase();
    final isCompleted = status == 'COMPLETED';
    final isRejected = status == 'REJECTED';

    final statusText = isCompleted
        ? 'Đã chuyển tiền'
        : (isRejected ? 'Bị từ chối' : 'Chờ chuyển khoản');
    final statusColor = isCompleted
        ? const Color(0xFF15803D)
        : (isRejected ? const Color(0xFFE11D48) : const Color(0xFFD97706));
    final statusBg = isCompleted
        ? const Color(0xFFDCFCE7)
        : (isRejected ? const Color(0xFFFFE4E6) : const Color(0xFFFEF3C7));

    final customerProof = _getCustomerAttachment(rf);
    final adminProof = _getAdminProof(rf);

    final rawOrderCode = rf['orderCode'] ??
        _myOrders.firstWhere(
          (o) => o['id'] == rf['orderId'],
          orElse: () => const <String, dynamic>{},
        )['orderCode'];
    final orderCode = rawOrderCode?.toString() ?? (rf['orderId'] != null ? '#${rf['orderId']}' : '');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showRefundDetailSheet(context, rf),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Mã phiếu & Trạng thái
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(LucideIcons.rotateCcw, size: 14, color: statusColor),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Phiếu hoàn tiền #${rf['id'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Số tiền & Đơn hàng
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Số tiền hoàn',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                  ),
                  Text(
                    fmtPrice(rf['amount'] ?? 0),
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: isCompleted ? const Color(0xFF15803D) : const Color(0xFFD97706),
                    ),
                  ),
                ],
              ),

              if (orderCode.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(LucideIcons.package, size: 13, color: Color(0xFF64748B)),
                        SizedBox(width: 6),
                        Text(
                          'Đơn hàng',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    Text(
                      orderCode,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ],

              if (rf['requestedAt'] != null) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(LucideIcons.clock, size: 13, color: Color(0xFF64748B)),
                        SizedBox(width: 6),
                        Text(
                          'Thời gian gửi',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    Text(
                      fmtDateTime(rf['requestedAt']),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 8),

              // Footer: Badges đính kèm (nếu có) + "Xem chi tiết >"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Wrap(
                    spacing: 6,
                    children: [
                      if (adminProof != null && adminProof.trim().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.fileCheck, size: 11, color: Color(0xFF15803D)),
                              SizedBox(width: 3.5),
                              Text(
                                'Có UNC',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (customerProof != null && customerProof.trim().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.image, size: 11, color: Color(0xFF0284C7)),
                              SizedBox(width: 3.5),
                              Text(
                                'Có ảnh',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (isRejected && rf['rejectionReason'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE4E6),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.alertCircle, size: 11, color: Color(0xFFE11D48)),
                              SizedBox(width: 3.5),
                              Text(
                                'Bị từ chối',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE11D48),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const Row(
                    children: [
                      Text(
                        'Xem chi tiết',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(LucideIcons.chevronRight, size: 13, color: Color(0xFF0284C7)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRefundDetailSheet(BuildContext context, Map<String, dynamic> rf) {
    final status = '${rf['status'] ?? 'PENDING'}'.toUpperCase();
    final isCompleted = status == 'COMPLETED';
    final isRejected = status == 'REJECTED';

    final statusText = isCompleted
        ? 'Đã chuyển tiền'
        : (isRejected ? 'Bị từ chối' : 'Chờ chuyển khoản');
    final statusColor = isCompleted
        ? const Color(0xFF15803D)
        : (isRejected ? const Color(0xFFE11D48) : const Color(0xFFD97706));
    final statusBg = isCompleted
        ? const Color(0xFFDCFCE7)
        : (isRejected ? const Color(0xFFFFE4E6) : const Color(0xFFFEF3C7));

    final customerProof = _getCustomerAttachment(rf);
    final adminProof = _getAdminProof(rf);

    final rawOrderCode = rf['orderCode'] ??
        _myOrders.firstWhere(
          (o) => o['id'] == rf['orderId'],
          orElse: () => const <String, dynamic>{},
        )['orderCode'];
    final orderCode = rawOrderCode?.toString() ?? (rf['orderId'] != null ? '#${rf['orderId']}' : '');

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.88,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Thanh kéo
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header Sheet
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Phiếu hoàn tiền #${rf['id'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Chi tiết yêu cầu & thông tin chuyển khoản',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),

                // Nội dung cuộn
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Box số tiền nổi bật
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                          decoration: BoxDecoration(
                            color: statusBg.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Số tiền hoàn',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                fmtPrice(rf['amount'] ?? 0),
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: statusColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isCompleted
                                    ? 'Đã hoàn tất chuyển khoản thành công'
                                    : (isRejected
                                        ? 'Yêu cầu hoàn tiền đã bị từ chối'
                                        : 'Đang chờ Admin đối soát và chuyển khoản'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Section 1: Thông tin hoàn tiền
                        const Text(
                          'Thông tin hoàn tiền',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              if (orderCode.isNotEmpty)
                                _buildInfoRow(
                                  icon: LucideIcons.package,
                                  label: 'Đơn hàng',
                                  value: orderCode,
                                  onCopy: () {
                                    Clipboard.setData(ClipboardData(text: orderCode));
                                    SmartDialog.showToast('Đã sao chép mã đơn hàng');
                                  },
                                ),
                              if (rf['bankName'] != null || rf['accountNumber'] != null)
                                _buildInfoRow(
                                  icon: LucideIcons.landmark,
                                  label: 'Tài khoản nhận',
                                  value: '${rf['bankName'] ?? ''} - ${rf['accountNumber'] ?? ''}',
                                ),
                              if (rf['accountHolderName'] != null &&
                                  '${rf['accountHolderName']}'.isNotEmpty)
                                _buildInfoRow(
                                  icon: LucideIcons.user,
                                  label: 'Chủ tài khoản',
                                  value: '${rf['accountHolderName']}'.toUpperCase(),
                                ),
                              if (rf['reason'] != null && _cleanReason(rf['reason']).isNotEmpty)
                                _buildInfoRow(
                                  icon: LucideIcons.messageSquare,
                                  label: 'Lý do hoàn',
                                  value: _cleanReason(rf['reason']),
                                ),
                              if (_cleanTransferRef(rf['bankTransferRef']).isNotEmpty)
                                _buildInfoRow(
                                  icon: LucideIcons.hash,
                                  label: 'Mã GD chuyển tiền',
                                  value: _cleanTransferRef(rf['bankTransferRef']),
                                  valueColor: const Color(0xFF15803D),
                                  onCopy: () {
                                    Clipboard.setData(
                                      ClipboardData(text: _cleanTransferRef(rf['bankTransferRef'])),
                                    );
                                    SmartDialog.showToast('Đã sao chép mã giao dịch');
                                  },
                                ),
                              if (rf['rejectionReason'] != null &&
                                  '${rf['rejectionReason']}'.isNotEmpty)
                                _buildInfoRow(
                                  icon: LucideIcons.alertTriangle,
                                  label: 'Lý do từ chối',
                                  value: '${rf['rejectionReason']}',
                                  valueColor: const Color(0xFFE11D48),
                                ),
                              if (rf['requestedAt'] != null)
                                _buildInfoRow(
                                  icon: LucideIcons.clock,
                                  label: 'Thời gian yêu cầu',
                                  value: fmtDateTime(rf['requestedAt']),
                                ),
                              if (rf['processedAt'] != null)
                                _buildInfoRow(
                                  icon: LucideIcons.calendarCheck,
                                  label: 'Thời gian hoàn tất',
                                  value: fmtDateTime(rf['processedAt']),
                                  valueColor: const Color(0xFF15803D),
                                ),
                            ],
                          ),
                        ),

                        // Section 2: Chứng từ & Hình ảnh
                        if ((customerProof != null && customerProof.trim().isNotEmpty) ||
                            (adminProof != null && adminProof.trim().isNotEmpty)) ...[
                          const SizedBox(height: 18),
                          const Text(
                            'Chứng từ & Hình ảnh minh chứng',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (customerProof != null && customerProof.trim().isNotEmpty)
                            _buildImageAttachmentBox(
                              title: 'Ảnh minh chứng bạn đã gửi:',
                              imageUrl: customerProof,
                              iconColor: const Color(0xFF0284C7),
                            ),
                          if (customerProof != null &&
                              customerProof.trim().isNotEmpty &&
                              adminProof != null &&
                              adminProof.trim().isNotEmpty)
                            const SizedBox(height: 10),
                          if (adminProof != null && adminProof.trim().isNotEmpty)
                            _buildImageAttachmentBox(
                              title: 'Biên lai chuyển khoản từ Admin (UNC):',
                              imageUrl: adminProof,
                              iconColor: const Color(0xFF15803D),
                            ),
                        ],

                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Đóng',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
    VoidCallback? onCopy,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 14, color: const Color(0xFF64748B)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                      color: valueColor ?? const Color(0xFF0F172A),
                    ),
                  ),
                ),
                if (onCopy != null) ...[
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: onCopy,
                    child: const Icon(LucideIcons.copy, size: 12.5, color: Color(0xFF0284C7)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String? _getCustomerAttachment(Map<String, dynamic> rf) {
    final direct = rf['customerAttachmentUrl'] as String?;
    if (direct != null && direct.trim().isNotEmpty) {
      return direct.trim();
    }
    final reason = rf['reason']?.toString() ?? '';
    final match = RegExp(
      r'\[Ảnh minh chứng:\s*(https?://[^\s\]]+|data:image/[^;]+;base64,[^\s\]]+)\]',
      caseSensitive: false,
    ).firstMatch(reason);
    if (match != null && match.group(1) != null) {
      return match.group(1);
    }
    return null;
  }

  static String _cleanReason(dynamic reason) {
    if (reason == null) return '';
    return reason
        .toString()
        .replaceAll(
          RegExp(
            r'\s*\[Ảnh minh chứng:\s*(https?://[^\s\]]+|data:image/[^;]+;base64,[^\s\]]+)\]',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
  }

  static String? _getAdminProof(Map<String, dynamic> rf) {
    final direct = rf['proofImageUrl'] as String?;
    if (direct != null && direct.trim().isNotEmpty) {
      return direct.trim();
    }
    final ref = rf['bankTransferRef']?.toString() ?? '';
    final match = RegExp(r'https?://[^\s|]+').firstMatch(ref);
    if (match != null && match.group(0) != null) {
      return match.group(0);
    }
    return null;
  }

  static String _cleanTransferRef(dynamic ref) {
    if (ref == null) return '';
    return ref
        .toString()
        .replaceAll(RegExp(r'\s*\|\s*https?://[^\s|]+'), '')
        .replaceAll(RegExp(r'https?://[^\s|]+'), '')
        .trim();
  }

  Widget _buildImageAttachmentBox({
    required String title,
    required String imageUrl,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.image, size: 13, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
                ),
              ),
              InkWell(
                onTap: () => _showImageLightbox(imageUrl),
                child: const Row(
                  children: [
                    Text(
                      'Phóng to',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                    ),
                    SizedBox(width: 2),
                    Icon(LucideIcons.externalLink, size: 11, color: Color(0xFF0284C7)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _showImageLightbox(imageUrl),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 120,
                width: double.infinity,
                color: const Color(0xFFE2E8F0),
                child: _buildProofImageWidget(imageUrl, fit: BoxFit.cover),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: TẠO YÊU CẦU HOÀN TIỀN MỚI
  // ---------------------------------------------------------------------------
  Widget _buildCreateRequestForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Chọn đơn hàng
          const Text(
            '1. Chọn đơn hàng cần yêu cầu hoàn tiền',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _openOrderPicker,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedOrder != null ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
                  width: _selectedOrder != null ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.packageCheck, size: 20, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _selectedOrder == null
                        ? const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bấm vào đây để chọn đơn hàng',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                              ),
                              Text(
                                'Chọn đơn đã thanh toán cần hoàn tiền',
                                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Đơn hàng: ${_selectedOrder!['orderCode'] ?? '#${_selectedOrder!['id']}'}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Số tiền: ${fmtPrice(_selectedOrder!['paidAmount'] ?? _selectedOrder!['totalPrice'])}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF15803D)),
                              ),
                            ],
                          ),
                  ),
                  const Icon(LucideIcons.chevronRight, size: 18, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 2. Tài khoản ngân hàng nhận tiền
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '2. Tài khoản nhận hoàn tiền',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              if (_savedBankAccount != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Đã có sẵn',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chọn ngân hàng
                InkWell(
                  onTap: _openBankPicker,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.landmark, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedBank != null
                                ? '${_selectedBank!.shortName} - ${_selectedBank!.name}'
                                : 'Chọn ngân hàng',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(LucideIcons.chevronDown, size: 14, color: Color(0xFF94A3B8)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Nhập số tài khoản
                TextField(
                  controller: _accountNumberController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Số tài khoản nhận tiền',
                    hintText: 'Nhập số tài khoản',
                    prefixIcon: const Icon(LucideIcons.creditCard, size: 16),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 10),

                // Nhập tên chủ tài khoản
                TextField(
                  controller: _accountHolderController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Tên chủ tài khoản (viết hoa không dấu)',
                    hintText: 'NGUYEN VAN A',
                    prefixIcon: const Icon(LucideIcons.user, size: 16),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 6),

                // Checkbox lưu mặc định
                Row(
                  children: [
                    Checkbox(
                      value: _saveAsDefault,
                      onChanged: (v) => setState(() => _saveAsDefault = v ?? true),
                      visualDensity: VisualDensity.compact,
                    ),
                    const Expanded(
                      child: Text(
                        'Lưu làm tài khoản nhận hoàn tiền mặc định',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 3. Lý do hoàn tiền
          const Text(
            '3. Lý do yêu cầu hoàn tiền',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          // Quick reason suggestions
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildQuickReasonChip('Sự cố kẹt ô tủ'),
              _buildQuickReasonChip('Drone huỷ chuyến bay'),
              _buildQuickReasonChip('Trừ tiền trùng cổng thanh toán'),
              _buildQuickReasonChip('Sự cố dịch vụ giặt ủi'),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Mô tả chi tiết lý do và sự cố bạn gặp phải...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 18),

          // 4. Hình ảnh minh chứng đính kèm
          const Text(
            '4. Hình ảnh minh chứng (tuỳ chọn)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: _pickedImageFile == null
                ? Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(LucideIcons.camera, size: 16),
                          label: const Text('Chụp ảnh', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(LucideIcons.image, size: 16),
                          label: const Text('Chọn thư viện', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _pickedImageFile!,
                              width: double.infinity,
                              height: 160,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _pickedImageFile = null;
                                _pickedXFile = null;
                                _base64ImageData = null;
                              }),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black87,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(LucideIcons.refreshCw, size: 13),
                        label: const Text('Đổi ảnh khác', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 24),

          // Nút bấm Gửi yêu cầu
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Gửi yêu cầu hoàn tiền',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildQuickReasonChip(String text) {
    return InkWell(
      onTap: () {
        final current = _reasonController.text.trim();
        if (current.isEmpty) {
          _reasonController.text = text;
        } else {
          _reasonController.text = '$current. $text';
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          '+ $text',
          style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  void _showImageLightbox(String imageUrl) {
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chi tiết hình ảnh minh chứng',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Colors.black,
                  constraints: const BoxConstraints(maxHeight: 520),
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: _buildProofImageWidget(imageUrl, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildProofImageWidget(String url, {required BoxFit fit}) {
    if (url.startsWith('data:')) {
      try {
        final comma = url.indexOf(',');
        final base64Str = comma != -1 ? url.substring(comma + 1) : url;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          fit: fit,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image, color: Colors.grey, size: 32),
          ),
        );
      } catch (_) {
        return const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 32));
      }
    }
    return AppCachedImage(
      imageUrl: url,
      fit: fit,
      errorWidget: (_, __, ___) => const Center(
        child: Icon(Icons.broken_image, color: Colors.grey, size: 32),
      ),
    );
  }

  void _showRulesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.shieldCheck, color: Color(0xFF15803D), size: 20),
            SizedBox(width: 8),
            Text('Quy tắc hoàn tiền', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Lock.R hỗ trợ hoàn tiền cho các trường hợp:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              SizedBox(height: 8),
              Text('• Sự cố kỹ thuật ô tủ không mở được hoặc kẹt cửa > 30 phút.'),
              Text('• Sự cố drone giao trễ vượt thời gian cam kết hoặc huỷ chuyến bay.'),
              Text('• Lỗi cổng thanh toán trừ tiền 2 lần (double billing).'),
              Text('• Hàng hoá/đồ giặt có sự cố từ đối tác giặt ủi.'),
              SizedBox(height: 12),
              Text(
                'Thời gian xử lý:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              SizedBox(height: 4),
              Text('Quản trị viên sẽ đối soát và thực hiện chuyển khoản trong vòng 24 giờ làm việc. Bạn sẽ nhận được thông báo kèm biên lai chuyển khoản (UNC) ngay trên ứng dụng.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SHEET CHỌN ĐƠN HÀNG
// ---------------------------------------------------------------------------
class _OrderPickerSheet extends StatelessWidget {
  const _OrderPickerSheet({
    required this.orders,
    required this.selected,
    required this.onSelect,
  });

  final List<Map<String, dynamic>> orders;
  final Map<String, dynamic>? selected;
  final ValueChanged<Map<String, dynamic>> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chọn đơn hàng cần hoàn tiền',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: orders.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Không có đơn hàng nào',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final o = orders[index];
                      final isCurrent = selected?['id'] == o['id'];
                      final code = '${o['orderCode'] ?? '#${o['id']}'}';
                      final type = '${o['type'] ?? o['serviceCategory'] ?? 'Đơn hàng'}';
                      final amount = o['paidAmount'] ?? o['totalPrice'] ?? 0;

                      return InkWell(
                        onTap: () => onSelect(o),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isCurrent ? const Color(0xFFF1F5F9) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCurrent ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                              width: isCurrent ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isCurrent ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  LucideIcons.package,
                                  size: 18,
                                  color: isCurrent ? Colors.white : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      code,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      type,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    fmtPrice(amount),
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF15803D)),
                                  ),
                                  if (isCurrent)
                                    const Text(
                                      '✓ Đang chọn',
                                      style: TextStyle(fontSize: 10, color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                                    ),
                                ],
                              ),
                            ],
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
}

// ---------------------------------------------------------------------------
// SHEET CHỌN NGÂN HÀNG
// ---------------------------------------------------------------------------
class _BankPickerSheet extends StatefulWidget {
  const _BankPickerSheet({required this.selected, required this.onSelect});

  final VietnameseBank? selected;
  final ValueChanged<VietnameseBank> onSelect;

  @override
  State<_BankPickerSheet> createState() => _BankPickerSheetState();
}

class _BankPickerSheetState extends State<_BankPickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = vietnameseBanks.where((b) {
      if (_search.isEmpty) return true;
      final query = _search.toLowerCase();
      return b.code.toLowerCase().contains(query) ||
          b.shortName.toLowerCase().contains(query) ||
          b.name.toLowerCase().contains(query);
    }).toList();

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chọn ngân hàng thụ hưởng',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              onChanged: (v) => setState(() => _search = v.trim()),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm ngân hàng (mã, tên)...',
                prefixIcon: const Icon(LucideIcons.search, size: 16),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
              itemBuilder: (context, index) {
                final bank = filtered[index];
                final isSelected = widget.selected?.code == bank.code;
                return ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      bank.code.length > 4 ? bank.code.substring(0, 4) : bank.code,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ),
                  title: Text(
                    bank.shortName,
                    style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600, fontSize: 13),
                  ),
                  subtitle: Text(
                    bank.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF15803D), size: 18) : null,
                  onTap: () => widget.onSelect(bank),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
