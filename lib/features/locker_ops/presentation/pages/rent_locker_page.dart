import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/config/business_config_provider.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/utils/business_rules_text.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/locker_picker.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/order_extras.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/order_payment_sheet.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

/// RENTAL flow: chọn tủ + loại ô + thời lượng, trả tiền theo giờ, PIN dùng
/// nhiều lần tới hết hạn thuê (khớp `order-service` createRental/extend/end).
class RentLockerPage extends StatefulWidget {
  RentLockerPage({
    super.key,
    this.initialLockerId,
    this.initialLockerName,
    this.locationName,
    this.initialCellType,
    this.initialBoxId,
    this.initialBoxNumber,
    LockerOpsService? service,
  }) : service = service ?? LockerOpsService();

  /// Pre-selected locker (cabinet) id — set when opened from the cell grid.
  /// When non-null the locker picker is hidden and the API load is skipped.
  final int? initialLockerId;

  /// Display name of the cabinet (e.g. "Tu demo capstone 3x3 + vali").
  /// Shown in the read-only locker card when [initialLockerId] is set.
  final String? initialLockerName;

  /// Display name of the store/location (shown as a location hint row).
  final String? locationName;

  /// Pre-selected cell type ('STANDARD' or 'XL') when opened from a specific
  /// cell in the locker grid. When set, the "Loại ô" selector is hidden.
  final String? initialCellType;

  /// Pre-selected box id when opened from a specific cell.
  final int? initialBoxId;

  /// Human box number for the selected cell.
  final int? initialBoxNumber;

  final LockerOpsService service;

  @override
  State<RentLockerPage> createState() => _RentLockerPageState();
}

class _RentLockerPageState extends State<RentLockerPage>
    with BusinessConfigStateMixin, WidgetsBindingObserver {
  final _noteCtrl = TextEditingController();

  List<Map<String, dynamic>> _lockers = [];
  int? _lockerId;
  String _cellType = 'STANDARD';
  late double _hours;

  /// Người dùng đã tự chọn số giờ — khi cấu hình đổi thì chỉ kéo về trong
  /// giới hạn mới, không ghi đè bằng số giờ mặc định.
  bool _hoursTouched = false;
  bool _loadingLockers = true;
  bool _loading = false;
  Map<String, dynamic>? _order;
  int _discount = 0;
  String? _promoCode;
  Map<String, int>? _availableCounts;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _hours = businessConfig.rentalDefaultHours.toDouble();
    if (widget.initialCellType != null) _cellType = widget.initialCellType!;
    if (widget.initialLockerId != null) {
      // Đến từ lưới ô — tủ đã xác định, bỏ qua gọi API load danh sách tủ.
      _lockerId = widget.initialLockerId;
      _loadingLockers = false;
      _loadLayout(_lockerId!);
    } else {
      _loadLockers();
    }
  }

  @override
  void onBusinessConfigChanged(BusinessConfig config) {
    _hours = (_hoursTouched
            ? config.clampRentalHours(_hours)
            : config.rentalDefaultHours)
        .toDouble();
  }

  void _setHours(num hours) {
    setState(() {
      _hoursTouched = true;
      _hours = businessConfig.clampRentalHours(hours).toDouble();
    });
  }

  // Khách có thể thanh toán qua cổng ngoài hoặc xác nhận bỏ đồ ngay tại kiosk —
  // quay lại app thì tải lại đơn để thấy trạng thái mới.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _order != null) {
      _refreshOrder();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLockers() async {
    try {
      final lockers = await _service.lockers();
      if (!mounted) return;
      setState(() {
        _lockers = lockers.where((l) => l['status'] == 'ACTIVE').toList();
        final preset = widget.initialLockerId;
        if (preset != null && _lockers.any((l) => l['id'] == preset)) {
          _lockerId = preset;
        } else if (_lockers.isNotEmpty) {
          _lockerId = _lockers.first['id'] as int?;
        }
        _loadingLockers = false;
      });
      if (_lockerId != null) _loadLayout(_lockerId!);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingLockers = false);
      _snack(LockerOpsService.errorMessage(e));
    }
  }

  Future<void> _loadLayout(int id) async {
    try {
      final res = await _service.layout(id);
      if (!mounted) return;
      final cells = res['cells'] as List?;
      if (cells != null) {
        int std = 0, xl = 0;
        for (final c in cells) {
          if (c['status'] == 'AVAILABLE') {
            if (c['cellType'] == 'STANDARD') {
              std++;
            } else if (c['cellType'] == 'XL') {
              xl++;
            }
          }
        }
        setState(() {
          _availableCounts = {'STANDARD': std, 'XL': xl};
          // Tự động chuyển loại ô nếu ô đang chọn đã hết
          if (widget.initialBoxId == null && (_availableCounts?[_cellType] ?? 0) == 0) {
            if (std > 0) {
              _cellType = 'STANDARD';
            } else if (xl > 0) {
              _cellType = 'XL';
            }
          }
        });
      }
    } catch (e) {
      // ignore
    }
  }

  /// Tạm tính hiển thị theo giá admin cấu hình — server tự tính tiền thật.
  int get _price => businessConfig.rentalRateFor(_cellType) * _hours.round();

  int get _netPrice => (_price - _discount).clamp(0, _price);

  Future<void> _create() async {
    if (_lockerId == null) return;
    setState(() => _loading = true);
    try {
      final order = await _service.createRental(
        lockerId: _lockerId!,
        boxId: widget.initialBoxId,
        cellType: _cellType,
        hours: _hours.round(),
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        promotionCode: _promoCode,
      );
      if (!mounted) return;
      setState(() => _order = order);
    } catch (e) {
      _snack(LockerOpsService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshOrder() async {
    final id = _order?['id'] as int?;
    if (id == null) return;
    try {
      final fresh = await _service.order(id);
      if (!mounted || fresh.isEmpty) return;
      setState(() => _order = fresh);
    } catch (_) {
      // Giữ bản đang hiển thị; lần sau quay lại app sẽ thử tải lại.
    }
  }

  Future<void> _pay() async {
    final id = _order?['id'] as int?;
    if (id == null) return;
    setState(() => _loading = true);
    try {
      final total = _order?['totalPrice'];
      final outcome = await payOrderAndAwaitPaid(
        context,
        service: _service,
        orderId: id,
        total: total is num ? total.toDouble() : _netPrice.toDouble(),
        enabledMethods: businessConfig.enabledPaymentMethods,
      );
      if (!mounted || outcome == OrderPaymentOutcome.cancelled) return;
      if (outcome == OrderPaymentOutcome.paid) {
        // Thanh toán xong → chuyển sang danh sách đơn để user xem trạng thái.
        context.go(AppRouter.myLockerOrders);
      } else {
        // pending — webhook chưa về, nhắc user làm mới sau.
        await _refreshOrder();
        _snack('Đang chờ xác nhận thanh toán, vui lòng đợi giây lát');
      }
    } catch (e) {
      _snack(LockerOpsService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openBox() async {
    final order = _order;
    final lockerId = order?['lockerId'] as int?;
    final boxId = order?['sendBoxId'] as int?;
    final pin = order?['pinCode'] as String?;
    if (lockerId == null || boxId == null || pin == null || pin.isEmpty) {
      _snack('Đơn chưa có thông tin ô/PIN để mở tủ.');
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await _service.unlock(lockerId, boxId, pin);
      final message = res['message']?.toString();
      _snack(
        res['accepted'] == true
            ? 'Ô đã mở — đặt đồ vào, đóng cửa rồi bấm xác nhận.'
            : (message == null || message.isEmpty ? 'Không mở được ô' : message),
      );
    } catch (e) {
      _snack(LockerOpsService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmDrop() async {
    final id = _order?['id'] as int?;
    if (id == null) return;
    setState(() => _loading = true);
    try {
      final updated = await _service.confirmDrop(id);
      if (!mounted) return;
      setState(() {
        final wasPaid = (_order?['paymentStatus'] as String?) == 'PAID';
        _order = {
          ...updated,
          if (wasPaid) 'paymentStatus': 'PAID',
          if (wasPaid && _order?['paidAt'] != null) 'paidAt': _order?['paidAt'],
        };
      });
      _snack('Bắt đầu kỳ thuê — PIN dùng nhiều lần');
    } catch (e) {
      _snack(LockerOpsService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  LockerOpsService get _service => widget.service;

  String _resultBoxLabel(Map<String, dynamic> order) {
    final boxNumber = widget.initialBoxNumber;
    if (boxNumber != null) return '$boxNumber';
    return '${order['sendBoxId'] ?? '-'}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AISLShadcnTheme.navySurface,
      body: Column(
        children: [
          BrandHeroHeader(
            title: 'Thuê tủ giữ đồ',
            subtitle: 'Chọn điểm tủ & thời gian sử dụng',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: _order == null ? _buildForm() : _buildResult(),
          ),
        ],
      ),
      bottomNavigationBar: _order == null ? Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _priceCard(),
            const SizedBox(height: 16),
            OpsPrimaryButton(
              label: 'Thuê ngay',
              icon: LucideIcons.lockKeyhole,
              loading: _loading,
              onPressed: (_availableCounts?[_cellType] == 0) ? null : _create,
            ),
          ],
        ),
      ) : null,
    );
  }

  Widget _buildForm() {
    if (_loadingLockers) {
      return const Center(child: CircularProgressIndicator());
    }
    final config = businessConfig;
    final minHours = config.rentalMinHours;
    final maxHours = config.rentalMaxHours;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const OpsBanner(
          text: 'Thuê ô để giữ đồ cá nhân theo giờ. PIN mở ô được dùng nhiều '
              'lần trong suốt kỳ thuê.',
          icon: LucideIcons.lockKeyhole,
        ),
        if (widget.locationName != null) ...[
          const SizedBox(height: 12),
          LocationHint(name: widget.locationName!),
        ],
        const SizedBox(height: 20),
        const OpsSectionLabel('Chọn tủ', icon: LucideIcons.warehouse),
        if (widget.initialLockerId != null)
          _lockedLockerCard()
        else
          LockerPickerField(
            lockers: _lockers,
            selectedId: _lockerId,
            onSelected: (l) {
              final newId = l['id'] as int?;
              setState(() {
                _lockerId = newId;
                _availableCounts = null;
              });
              if (newId != null) _loadLayout(newId);
            },
          ),
        const SizedBox(height: 20),
        const OpsSectionLabel('Loại ô', icon: LucideIcons.boxes),
        if (widget.initialCellType != null)
          _lockedCellTypeCard(_cellType)
        else
          Row(
            children: [
              _cellCard(
                value: 'STANDARD',
                icon: LucideIcons.box,
                title: 'Ô thường',
                size: config.cellDimensionsFor('STANDARD'),
                rate: hourlyRateLabel(config.rentalRateFor('STANDARD')),
              ),
              const SizedBox(width: 12),
              _cellCard(
                value: 'XL',
                icon: LucideIcons.luggage,
                title: 'Ô vali (XL)',
                size: config.cellDimensionsFor('XL'),
                rate: hourlyRateLabel(config.rentalRateFor('XL')),
              ),
            ],
          ),
        const SizedBox(height: 20),
        const OpsSectionLabel('Thời gian thuê', icon: LucideIcons.timer),
        Wrap(
          spacing: 8,
          children: [
            for (final h in config.rentalQuickHours) _quickChip(h),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              // min == max thì không có gì để kéo — chỉ hiện số giờ cố định.
              child: maxHours > minHours
                  ? Slider(
                      value: _hours.clamp(
                        minHours.toDouble(),
                        maxHours.toDouble(),
                      ),
                      min: minHours.toDouble(),
                      max: maxHours.toDouble(),
                      divisions: maxHours - minHours,
                      activeColor: opsPrimary,
                      label: '${_hours.round()}h',
                      onChanged: _setHours,
                    )
                  : const SizedBox.shrink(),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: opsPrimary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_hours.round()} giờ',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: opsPrimary,
                ),
              ),
            ),
          ],
        ),
        Text(
          'Thuê từ $minHours đến $maxHours giờ. ${overtimePolicyText(config)}',
          style: const TextStyle(fontSize: 12, color: opsMutedText, height: 1.4),
        ),
        const SizedBox(height: 16),
        const OpsSectionLabel('Ghi chú', icon: LucideIcons.stickyNote),
        TextField(
          controller: _noteCtrl,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Tùy chọn...',
            prefixIcon: const Icon(LucideIcons.pencil, size: 18, color: opsMutedText),
            filled: true,
            fillColor: Colors.white,
            border: _border(opsBorder),
            enabledBorder: _border(opsBorder),
            focusedBorder: _border(opsPrimary, width: 1.6),
          ),
        ),
        const SizedBox(height: 16),
        const OpsSectionLabel('Mã giảm giá', icon: LucideIcons.ticket),
        PromoCodeField(
          orderTotal: _price,
          lockerId: _lockerId,
          onChanged: (discount, code) => setState(() {
            _discount = discount;
            _promoCode = code;
          }),
        ),
        const SizedBox(height: 10),
        const LoyaltyPointsHint(),
      ].animate(interval: 40.ms).fadeIn(duration: 250.ms).slideY(begin: 0.06),
    );
  }

  Widget _priceCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [opsDark, AISLShadcnTheme.navySecondary],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.wallet, color: Colors.white70, size: 22),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tạm tính',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                '${typeLabel('RENTAL')} · ${_hours.round()} giờ',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              if (_discount > 0)
                Text(
                  'Giảm: -${fmtPrice(_discount)}',
                  style: const TextStyle(
                    color: Color(0xFF86EFAC),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_discount > 0)
                Text(
                  fmtPrice(_price),
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              Text(
                fmtPrice(_netPrice),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickChip(int h) {
    final selected = _hours.round() == h;
    return ChoiceChip(
      label: Text('${h}h'),
      selected: selected,
      showCheckmark: false,
      backgroundColor: Colors.white,
      selectedColor: opsPrimary,
      side: BorderSide(color: selected ? opsPrimary : opsBorder),
      labelStyle: TextStyle(
        color: selected ? Colors.white : opsDark,
        fontWeight: FontWeight.w700,
      ),
      onSelected: (_) => _setHours(h),
    );
  }

  Widget _cellCard({
    required String value,
    required IconData icon,
    required String title,
    required String size,
    required String rate,
  }) {
    final selected = _cellType == value;
    final available = _availableCounts?[value] ?? -1;
    final disabled = available == 0;
    
    return Expanded(
      child: GestureDetector(
        onTap: disabled ? null : () => setState(() => _cellType = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? opsPrimary.withValues(alpha: 0.06) : (disabled ? Colors.grey.shade100 : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? opsPrimary : (disabled ? Colors.grey.shade300 : opsBorder),
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: disabled ? Colors.grey.shade400 : (selected ? opsPrimary : opsMutedText), size: 22),
                  const Spacer(),
                  if (selected)
                    const Icon(LucideIcons.circleCheck, color: opsPrimary, size: 18),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: disabled ? Colors.grey.shade400 : (selected ? opsPrimary : opsDark),
                ),
              ),
              const SizedBox(height: 4),
              Text(size, style: TextStyle(fontSize: 11, color: disabled ? Colors.grey.shade400 : opsMutedText)),
              const SizedBox(height: 2),
              Text(
                rate,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: disabled ? Colors.grey.shade400 : opsDark,
                ),
              ),
              const SizedBox(height: 6),
              if (available == 0)
                const Text('Hết ô', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent))
              else if (available > 0)
                Text('Còn $available ô trống', style: const TextStyle(fontSize: 11, color: Colors.green)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lockedLockerCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: opsBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: opsPrimary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.warehouse, color: opsPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.initialLockerName ?? widget.locationName ?? 'Tủ đã chọn',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: opsDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.locationName != null)
                  Text(
                    widget.locationName!,
                    style: const TextStyle(fontSize: 12, color: opsMutedText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const Icon(LucideIcons.lockKeyhole, size: 18, color: opsMutedText),
        ],
      ),
    );
  }

  Widget _lockedCellTypeCard(String cellType) {
    final isXl = cellType == 'XL';
    final icon = isXl ? LucideIcons.luggage : LucideIcons.box;
    final title = isXl ? 'Ô vali (XL)' : 'Ô thường';
    final size = businessConfig.cellDimensionsFor(cellType);
    final rate = hourlyRateLabel(businessConfig.rentalRateFor(cellType));
    
    final available = _availableCounts?[cellType] ?? -1;
    final disabled = available == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: disabled ? Colors.grey.shade100 : opsPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: disabled ? opsBorder : opsPrimary, width: 1.8),
      ),
      child: Row(
        children: [
          Icon(icon, color: disabled ? opsMutedText : opsPrimary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: disabled ? opsMutedText : opsDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(size, style: const TextStyle(fontSize: 11, color: opsMutedText)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      rate,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: disabled ? opsMutedText : opsDark),
                    ),
                    if (available >= 0) ...[
                      const SizedBox(width: 8),
                      if (available == 0)
                        const Text('Hết ô', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent))
                      else
                        Text('Còn $available ô trống', style: const TextStyle(fontSize: 11, color: Colors.green)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.lockKeyhole, size: 16, color: opsMutedText),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final order = _order!;
    final status = order['status'] as String?;
    final started = status == 'STORING';
    final total = order['totalPrice'];
    final hasFee = total is num ? total > 0 : _netPrice > 0;
    final unpaid = hasFee && (order['paymentStatus'] as String?) != 'PAID';
    final config = businessConfig;
    final payLabel = 'Thanh toán ${fmtPrice(total is num ? total : _netPrice)}';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        OpsCard(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Đơn ${order['orderCode'] ?? ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: opsDark,
                      ),
                    ),
                  ),
                  StatusChip(status),
                ],
              ),
              const Divider(height: 24, color: opsBorder),
              if (order['id'] is int) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: PaymentStatusChip(
                    key: ValueKey(
                      'payment-${order['id']}-${order['paymentStatus']}-${order['paidAt']}',
                    ),
                    orderId: order['id'] as int,
                    service: widget.service,
                  ),
                ),
                const SizedBox(height: 14),
              ],
                _ResultHeadline(
                  icon: started ? LucideIcons.lockKeyhole : LucideIcons.packageOpen,
                  title: started ? 'Kỳ thuê đang chạy' : 'Đã giữ ô — bỏ đồ vào',
                  subtitle: started
                      ? 'PIN mở ô nhiều lần tới ${fmtDateTime(order['pickupDeadline'])}.'
                    : 'Nhập PIN để mở ô số ${_resultBoxLabel(order)} và đặt đồ vào.',
                ),
              const SizedBox(height: 16),
              AccessCredentials(
                pin: order['pinCode'] as String?,
                qrToken: order['qrToken'] as String?,
                caption: 'PIN dùng nhiều lần trong kỳ thuê',
              ),
              if (order['pickupDeadline'] != null) ...[
                const SizedBox(height: 16),
                OpsBanner(
                  tone: OpsBannerTone.info,
                  icon: LucideIcons.clock,
                  text: 'Hết hạn thuê: ${fmtDateTime(order['pickupDeadline'])} '
                      '(${fmtRemaining(order['pickupDeadline'])}). '
                      'Trả ô trễ: ${overtimePolicyText(config)}',
                ),
              ],
            ],
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05),
        const SizedBox(height: 16),
        if (!started && unpaid && config.requirePaymentBeforeDrop) ...[
          const OpsBanner(
            tone: OpsBannerTone.warning,
            icon: LucideIcons.badgeAlert,
            text: 'Cần thanh toán đơn trước khi mở ô bỏ đồ.',
          ),
          const SizedBox(height: 12),
          OpsPrimaryButton(
            label: payLabel,
            icon: LucideIcons.wallet,
            loading: _loading,
            onPressed: _pay,
          ),
        ] else if (!started) ...[
          const OpsBanner(
            tone: OpsBannerTone.info,
            icon: LucideIcons.lockKeyholeOpen,
            text: 'Mở ô bằng nút bên dưới hoặc nhập PIN tại tủ, đặt đồ vào, '
                'đóng cửa rồi xác nhận để bắt đầu tính giờ thuê.',
          ),
          const SizedBox(height: 12),
          OpsPrimaryButton(
            label: 'Mở ô để bỏ đồ',
            icon: LucideIcons.lockKeyholeOpen,
            color: opsPrimary,
            loading: _loading,
            onPressed: _openBox,
          ),
          const SizedBox(height: 12),
          OpsPrimaryButton(
            label: 'Tôi đã bỏ đồ — bắt đầu kỳ thuê',
            icon: LucideIcons.check,
            loading: _loading,
            onPressed: _confirmDrop,
          ),
        ] else ...[
          if (unpaid) ...[
            const OpsBanner(
              tone: OpsBannerTone.warning,
              icon: LucideIcons.badgeAlert,
              text:
                  'Còn phí gia hạn chưa thanh toán — cần trả trước khi kết thúc thuê.',
            ),
            const SizedBox(height: 12),
            OpsPrimaryButton(
              label: payLabel,
              icon: LucideIcons.wallet,
              loading: _loading,
              onPressed: _pay,
            ),
            const SizedBox(height: 12),
          ],
          OpsPrimaryButton(
            label: 'Xong — xem trong Đơn của tôi',
            icon: LucideIcons.house,
            onPressed: () {
              final router = GoRouter.of(context);
              Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
              Future.microtask(() {
                router.go(AppRouter.orders);
              });
            },
          ),
        ],
      ],
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );
}

class _ResultHeadline extends StatelessWidget {
  const _ResultHeadline({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 30, color: opsPrimary),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: opsDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: opsMutedText, height: 1.4),
        ),
      ],
    );
  }
}
