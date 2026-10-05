import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/presentation/pages/directions_map_page.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_booking_sheet.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/pages/rent_locker_page.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/pages/send_parcel_page.dart';
import 'package:smart_laundry_locker/features/stores/domain/entities/store.dart';
import 'package:smart_laundry_locker/features/maintenance/presentation/pages/create_report_page.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_laundry_locker/shared/shared.dart';
import 'dart:async';
import 'package:smart_laundry_locker/core/services/app_event_bus.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

/// Hiển thị lưới ô tủ locker tại một cửa hàng cụ thể.
/// Load danh sách tủ (cabinets) qua GET /api/lockers?storeId=X,
/// sau đó lazy-load layout từng tủ khi user mở rộng thẻ tủ.
class StoreLockerGridPage extends StatefulWidget {
  const StoreLockerGridPage({super.key, required this.store, this.service});

  final Store store;
  final LockerOpsService? service;

  @override
  State<StoreLockerGridPage> createState() => _StoreLockerGridPageState();
}

class _StoreLockerGridPageState extends State<StoreLockerGridPage> {
  late final LockerOpsService _service = widget.service ?? LockerOpsService();
  List<Map<String, dynamic>> _lockers = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      List<Map<String, dynamic>> lockers = [];
      // 1. Thử lấy danh sách tủ theo storeId
      if (widget.store.id > 0) {
        try {
          lockers = await _service.lockersByStore(widget.store.id);
        } catch (_) {}
      }

      // 2. Nếu không tìm thấy tủ nào, có thể widget.store.id chính là lockerId
      if (lockers.isEmpty && widget.store.id > 0) {
        try {
          final direct = await _service.locker(widget.store.id);
          if (direct.isNotEmpty && direct['id'] != null) {
            lockers = [direct];
          }
        } catch (_) {}
      }

      // 3. Nếu vẫn không thấy, lấy danh sách tất cả tủ trên hệ thống và tìm theo id, storeId hoặc tên/mã
      if (lockers.isEmpty) {
        try {
          final allGlobal = await _service.lockers();
          final targetId = widget.store.id.toString();
          lockers = allGlobal.where((l) {
            final lId = l['id']?.toString();
            final sId = l['storeId']?.toString();
            return (targetId != '0' && (lId == targetId || sId == targetId));
          }).toList();

          if (lockers.isEmpty && widget.store.name.isNotEmpty) {
            final targetName = widget.store.name.trim().toLowerCase();
            lockers = allGlobal.where((l) {
              final name = (l['name'] ?? '').toString().trim().toLowerCase();
              final code = (l['code'] ?? '').toString().trim().toLowerCase();
              return name.contains(targetName) ||
                  targetName.contains(name) ||
                  code.contains(targetName) ||
                  targetName.contains(code);
            }).toList();
          }
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        // Đồng bộ với Admin: Hiển thị đầy đủ mọi tủ (kể cả bảo trì, mất kết nối, tạm đóng)
        _lockers = lockers.map((l) {
          final lId = (l['id'] as num?)?.toInt();
          final code = (l['code'] ?? '').toString();
          final name = (l['name'] ?? '').toString();
          final isCabinetTU01 = lId == 7 ||
              code == 'CAB-TU01' ||
              name.contains('TU01') ||
              name.contains('Tủ thật');
          final isOnline = l['online'] as bool?;
          if (isOnline == false || (isCabinetTU01 && isOnline != true)) {
            final copy = Map<String, dynamic>.from(l);
            copy['status'] = 'DISCONNECTED';
            copy['online'] = false;
            return copy;
          }
          return l;
        }).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = LockerOpsService.errorMessage(e);
        _loading = false;
      });
    }
  }

  void _openDirections() {
    Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        builder: (_) => DirectionsMapPage(
          destination: LatLng(widget.store.latitude!, widget.store.longitude!),
          title: widget.store.name,
          subtitle: widget.store.address,
        ),
      ),
    );
  }

  void _openReportLocker([Map<String, dynamic>? locker]) {
    final target = locker ?? (_lockers.isNotEmpty ? _lockers.first : null);
    final lockerId = target != null ? (target['id']?.toString() ?? '') : '';
    final lockerName = target != null
        ? (target['name'] as String? ?? target['code'] as String? ?? 'Tủ Kiosk')
        : 'Tủ Kiosk';

    Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        builder: (_) => CreateReportPage(
          cabinetId: lockerId,
          lockerId: lockerId,
          cabinetName: lockerName,
          lockerName: lockerName,
          locationName: widget.store.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      body: Column(
        children: [
          BrandHeroHeader(
            title: 'Tủ locker',
            subtitle: widget.store.name,
            onBack: () => Navigator.pop(context),
            trailing: BrandCircleIconButton(
              child: const AppLottie(
                AppLottieAssets.baoSuCo,
                width: 22,
                height: 22,
              ),
              onTap: () => _openReportLocker(),
            ),
          ),
          if (widget.store.hasLocation)
            _AddressBar(
              address: widget.store.address,
              onDirections: _openDirections,
            ),
          if (!_loading && _error == null && _lockers.isNotEmpty)
            _SummaryBanner(count: _lockers.length),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: AppLoadingIndicator(message: 'Đang tải danh sách tủ...'),
      );
    }
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _load);
    }
    if (_lockers.isEmpty) {
      return const _EmptyView();
    }
    return RefreshIndicator(
      color: AislBrand.navy,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _lockers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _LockerCard(
          locker: _lockers[i],
          storeName: widget.store.name,
          service: _service,
          initiallyExpanded: _lockers.length == 1,
          storeLatLng: widget.store.hasLocation
              ? LatLng(widget.store.latitude!, widget.store.longitude!)
              : const LatLng(10.762622, 106.660172),
        ),
      ),
    );
  }
}

// ── Address + directions bar ──────────────────────────────────────────────────

class _AddressBar extends StatelessWidget {
  const _AddressBar({this.address, required this.onDirections});
  final String? address;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AislBrand.navy.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.mapPin, color: AislBrand.navy, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              address ?? 'Xem vị trí trên bản đồ',
              style: const TextStyle(
                color: AislBrand.navy,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDirections,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AislBrand.navy,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.directions_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Chỉ đường',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary banner ────────────────────────────────────────────────────────────

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AislBrand.navy.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.server, color: AislBrand.navy, size: 16),
          const SizedBox(width: 8),
          Text(
            '$count tủ locker',
            style: const TextStyle(
              color: AislBrand.navy,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AislBrand.cyan.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Chạm vào tủ để xem ô trống',
              style: TextStyle(
                color: AislBrand.blue,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Locker Card ───────────────────────────────────────────────────────────────

class _LockerCard extends StatefulWidget {
  const _LockerCard({
    required this.locker,
    required this.storeName,
    required this.service,
    required this.storeLatLng,
    this.initiallyExpanded = false,
  });

  final Map<String, dynamic> locker;
  final String storeName;
  final LockerOpsService service;
  final LatLng storeLatLng;
  final bool initiallyExpanded;

  @override
  State<_LockerCard> createState() => _LockerCardState();
}

class _LockerCardState extends State<_LockerCard> {
  bool _expanded = false;
  Map<String, dynamic>? _layout;
  bool _loadingLayout = false;
  String? _layoutError;
  StreamSubscription<AppEvent>? _busSub;

  int get _lockerId => (widget.locker['id'] as num?)?.toInt() ?? 0;

  String get _lockerName {
    final n = widget.locker['name'] as String?;
    final c = widget.locker['code'] as String?;
    return (n?.isNotEmpty == true) ? n! : (c ?? 'Tủ');
  }

  @override
  void initState() {
    super.initState();
    if (widget.initiallyExpanded) {
      _expanded = true;
      _loadLayout();
    }
    _busSub = AppEventBus.instance.events.listen((event) {
      if (!mounted) return;
      if (event is LockerLayoutUpdatedEvent) {
        if (event.lockerId == null ||
            event.lockerId == _lockerId.toString()) {
          setState(() {
            _layout = null;
          });
          if (_expanded) {
            _loadLayout();
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _busSub?.cancel();
    super.dispose();
  }

  Future<void> _loadLayout() async {
    if (_layout != null || _loadingLayout) return;
    setState(() {
      _loadingLayout = true;
      _layoutError = null;
    });
    try {
      final layout = await widget.service.layout(_lockerId);
      if (mounted) {
        setState(() {
          _layout = _enrichLayout(layout);
          _loadingLayout = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // API failed — still show demo grid so UI is never empty
        setState(() {
          _layout = _enrichLayout({});
          _loadingLayout = false;
        });
      }
    }
  }

  static Map<String, dynamic> _enrichLayout(Map<String, dynamic> raw) {
    if (raw.isEmpty) return raw;
    final Map<String, dynamic> enriched = Map<String, dynamic>.from(raw);
    final rawCells = raw['cells'] as List?;
    if (rawCells != null) {
      final enrichedCells = rawCells.map((c) {
        if (c is! Map<String, dynamic>) return c;
        final map = Map<String, dynamic>.from(c);
        final boxNum = (map['boxNumber'] as num?)?.toInt();
        final cellType = (map['cellType'] as String?)?.toUpperCase();
        // Giống Admin (layout-view.tsx): Ô #1, Ô #2 và các ô có cellType DRONE là ô tiếp nhận Drone
        if (boxNum == 1 || boxNum == 2 || cellType == 'DRONE') {
          map['isDrone'] = true;
        }
        return map;
      }).toList();
      enriched['cells'] = enrichedCells;
    }
    return enriched;
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) _loadLayout();
  }

  @override
  Widget build(BuildContext context) {
    final cells =
        (_layout?['cells'] as List?)?.cast<Map<String, dynamic>>() ??
        const <Map<String, dynamic>>[];
    final totalCells =
        (_layout?['totalCells'] as num?)?.toInt() ?? cells.length;
    final available = cells.where((c) => c['status'] == 'AVAILABLE').length;

    final statusStr = ((_layout?['status'] ?? widget.locker['status']) as String?)?.toUpperCase() ?? 'ACTIVE';
    final bool? onlineField = _layout?['online'] as bool?;
    final bool isCabinetTU01 = _lockerId == 7 ||
        widget.locker['code'] == 'CAB-TU01' ||
        _lockerName.contains('TU01') ||
        _lockerName.contains('Tủ thật');
    final bool isDisconnected = onlineField == false ||
        statusStr == 'DISCONNECTED' ||
        (isCabinetTU01 && onlineField != true);
    final bool isMaintenance = statusStr == 'MAINTENANCE';
    final bool isActive = statusStr == 'ACTIVE' && !isDisconnected;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(
            isActive: isActive,
            isMaintenance: isMaintenance,
            isDisconnected: isDisconnected,
            available: available,
            totalCells: totalCells,
          ),
          if (isDisconnected)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.wifiOff, size: 16, color: Color(0xFFDC2626)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bộ điều khiển Kiosk mất kết nối (Offline).',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (isMaintenance)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.wrench, size: 16, color: Color(0xFFD97706)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tủ đang trong chế độ bảo trì kỹ thuật.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _expanded
                ? _buildExpandedContent(cells)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader({
    required bool isActive,
    required bool isMaintenance,
    required bool isDisconnected,
    required int available,
    required int totalCells,
  }) {
    return InkWell(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      onTap: _toggle,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Cabinet icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AislBrand.brandGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                LucideIcons.server,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Name + badges
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _lockerName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AislBrand.textTitle,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (_layout != null) ...[
                        _Pill(
                          label: '$available/$totalCells ô trống',
                          bg: available > 0
                              ? AislBrand.cyan
                              : const Color(0xFFE2E8F0),
                          fg: available > 0 ? Colors.white : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (isDisconnected)
                        const _Pill(
                          label: 'Mất kết nối',
                          bg: Color(0xFFFDE8E8),
                          fg: Color(0xFF9B1C1C),
                        )
                      else if (isMaintenance)
                        const _Pill(
                          label: 'Bảo trì',
                          bg: Color(0xFFFEF3C7),
                          fg: Color(0xFFD97706),
                        )
                      else if (isActive)
                        const _Pill(
                          label: 'Hoạt động',
                          bg: Color(0xFFDEF7EC),
                          fg: Color(0xFF046C4E),
                        )
                      else
                        const _Pill(
                          label: 'Tạm ngưng',
                          bg: Color(0xFFF1F5F9),
                          fg: Color(0xFF64748B),
                        ),
                      const SizedBox(width: 6),
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Navigator.of(context, rootNavigator: true).push<void>(
                            MaterialPageRoute(
                              builder: (_) => CreateReportPage(
                                cabinetId: '$_lockerId',
                                lockerId: '$_lockerId',
                                cabinetName: _lockerName,
                                lockerName: _lockerName,
                                locationName: widget.storeName,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFECDD3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppLottie(
                                AppLottieAssets.baoSuCo,
                                width: 14,
                                height: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Báo sự cố',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE11D48),
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
            // Chevron
            AnimatedRotation(
              turns: _expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: const Icon(
                LucideIcons.chevronDown,
                color: AislBrand.navy,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent(List<Map<String, dynamic>> cells) {
    return Column(
      children: [
        const Divider(height: 1, color: Color(0xFFF0F4F8)),
        if (_loadingLayout)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: CircularProgressIndicator(
                color: AislBrand.navy,
                strokeWidth: 2.5,
              ),
            ),
          )
        else if (_layoutError != null)
          _LayoutErrorRow(
            message: _layoutError!,
            onRetry: () {
              _layout = null;
              _loadLayout();
            },
          )
        else if (cells.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: Text(
                'Không có dữ liệu ô tủ',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          _CellGrid(
            cells: cells,
            onCellTap: (cell) => _showBookingSheet(context, cell),
            onFaultTap: (cell) => _showFaultHint(context, cell),
          ),
      ],
    );
  }

  void _showFaultHint(BuildContext ctx, Map<String, dynamic> cell) {
    final boxLabel = _boxLabel(cell);
    final reason = (cell['faultReason'] as String?)?.trim();
    final message = reason == null || reason.isEmpty
        ? '$boxLabel đang hỏng. Hãy chọn ô khác.'
        : '$boxLabel đang hỏng: $reason. Hãy chọn ô khác.';

    ScaffoldMessenger.of(ctx)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _cellTypeForBooking(Map<String, dynamic> cell) {
    final explicit = (cell['cellType'] as String?)?.toUpperCase();
    if (explicit == 'XL') return 'XL';
    final size = (cell['size'] as String?)?.toUpperCase() ?? '';
    if (size == 'LARGE') return 'XL';
    return 'STANDARD';
  }

  String _boxLabel(Map<String, dynamic> cell) {
    final boxNum = (cell['boxNumber'] as num?)?.toInt();
    if (boxNum != null) return 'Ô số $boxNum';
    final r = (cell['rowIndex'] as num?)?.toInt() ?? 0;
    final c = (cell['colIndex'] as num?)?.toInt() ?? 0;
    return 'Ô hàng ${r + 1}, cột ${c + 1}';
  }

  void _showBookingSheet(BuildContext ctx, Map<String, dynamic> cell) {
    // DRONE cells use a dedicated booking flow
    final boxNum = (cell['boxNumber'] as num?)?.toInt();
    final isDrone = cell['isDrone'] == true ||
        (cell['cellType'] as String?)?.toUpperCase() == 'DRONE' ||
        boxNum == 1 ||
        boxNum == 2;

    if (isDrone) {
      showModalBottomSheet<void>(
        context: ctx,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DroneBookingSheet(
          cell: cell,
          lockerName: _lockerName,
          origin: widget.storeLatLng,
          lockerId: _lockerId,
          onBooked: (orderId) {
            // Đơn vừa giữ ô drone này: nạp lại sơ đồ để ô chuyển xám ngay, rồi
            // đưa khách tới màn theo dõi — nơi có nhắc thanh toán để đội bay
            // tiếp nhận.
            if (!mounted) return;
            setState(() => _layout = null);
            _loadLayout();
            context.push(AppRouter.droneDeliveryTracking, extra: '$orderId');
          },
        ),
      );
      return;
    }

    final cellType = _cellTypeForBooking(cell);
    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingSheet(
        cell: cell,
        lockerId: _lockerId,
        lockerName: _lockerName,
        storeName: widget.storeName,
        onRent: () {
          Navigator.pop(ctx);
          Navigator.push<void>(
            ctx,
            MaterialPageRoute(
                builder: (_) => RentLockerPage(
                  initialLockerId: _lockerId,
                  initialLockerName: _lockerName,
                  locationName: widget.storeName,
                  initialCellType: cellType,
                  initialBoxId: (cell['id'] as num?)?.toInt(),
                  initialBoxNumber: (cell['boxNumber'] as num?)?.toInt(),
                ),
              ),
            );
        },
        onSend: () {
          Navigator.pop(ctx);
          Navigator.push<void>(
            ctx,
            MaterialPageRoute(
              builder: (_) => SendParcelPage(
                initialLockerId: _lockerId,
                initialLockerName: _lockerName,
                locationName: widget.storeName,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CellGrid extends StatelessWidget {
  const _CellGrid({
    required this.cells,
    required this.onCellTap,
    required this.onFaultTap,
  });
  final List<Map<String, dynamic>> cells;
  final ValueChanged<Map<String, dynamic>> onCellTap;
  final ValueChanged<Map<String, dynamic>> onFaultTap;

  bool _isXl(Map<String, dynamic> cell) =>
      (cell['cellType'] as String?) == 'XL' ||
      (cell['size'] as String?) == 'XL' ||
      (cell['colIndex'] == 0 &&
          (cell['rowIndex'] == null ||
              cell['rowIndex'] == 1 ||
              cell['rowIndex'] == 2));

  @override
  Widget build(BuildContext context) {
    // Compute grid dimensions
    int maxRow = 0, maxCol = 0;
    for (final c in cells) {
      final r = (c['rowIndex'] as num?)?.toInt() ?? 0;
      final col = (c['colIndex'] as num?)?.toInt() ?? 0;
      if (r > maxRow) maxRow = r;
      if (col > maxCol) maxCol = col;
    }
    final numRows = maxRow + 1;
    final numCols = maxCol + 1;

    // Build 2-D grid map
    final grid = List.generate(
      numRows,
      (_) => List<Map<String, dynamic>?>.filled(numCols, null),
    );
    for (final c in cells) {
      final r = (c['rowIndex'] as num?)?.toInt() ?? 0;
      final col = (c['colIndex'] as num?)?.toInt() ?? 0;
      if (r < numRows && col < numCols) grid[r][col] = c;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _GridLegend(),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(numCols, (col) {
              final colChildren = <Widget>[];
              int skipRows = 0;

              for (int row = 0; row < numRows; row++) {
                if (skipRows > 0) {
                  skipRows--;
                  continue;
                }

                final cell = grid[row][col];
                final span = cell != null ? (_isXl(cell) ? 2 : 1) : 1;
                skipRows = span - 1;

                final height = 80.0 * span + 6.0 * (span - 1);

                colChildren.add(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: SizedBox(
                      height: height,
                      child: cell != null
                          ? _CellTile(
                              cell: cell,
                              onTap: switch ((cell['status'] as String?)
                                  ?.toUpperCase()) {
                                'AVAILABLE' => () => onCellTap(cell),
                                'FAULT' => () => onFaultTap(cell),
                                _ => null,
                              },
                            )
                          : null,
                    ),
                  ),
                );
              }

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(children: colChildren),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _GridLegend extends StatelessWidget {
  const _GridLegend();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: const [
          _LegendChip(color: _CellPalette.available, label: 'Trống'),
          _LegendChip(color: _CellPalette.occupied, label: 'Đang dùng'),
          _LegendChip(color: _CellPalette.reserved, label: 'Đã đặt'),
          _LegendChip(color: _CellPalette.fault, label: 'Lỗi / Hỏng'),
          _LegendChip(color: _CellPalette.cleaning, label: 'Bảo trì'),
          _LegendChip(
            color: _CellPalette.drone,
            label: 'Drone',
            icon: Icons.flight_rounded,
          ),
          _LegendChip(
            color: Color(0xFFD97706),
            label: 'Cửa mở',
            icon: LucideIcons.doorOpen,
          ),
          _LegendChip(
            color: Color(0xFF64748B),
            label: 'Cửa đóng',
            icon: LucideIcons.doorClosed,
          ),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label, this.icon});
  final Color color;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon != null
              ? Icon(icon, color: color, size: 12)
              : Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cell Tile ─────────────────────────────────────────────────────────────────

abstract class _CellPalette {
  static const Color available = AislBrand.cyan;
  static const Color occupied = Color(0xFFCBD5E1);
  static const Color reserved = Color(0xFFFBBF24);
  static const Color fault = Color(0xFFEF4444);
  static const Color cleaning = Color(0xFF60A5FA);
  // Ô drone: tím indigo — phân biệt rõ với ô thường dù status AVAILABLE
  static const Color drone = Color(0xFF6366F1);
}

class _CellTile extends StatelessWidget {
  const _CellTile({required this.cell, this.onTap});
  final Map<String, dynamic> cell;
  final VoidCallback? onTap;

  String get _status => ((cell['status'] as String?) ?? '').toUpperCase();
  String get _cellType => ((cell['cellType'] as String?) ?? 'STANDARD').toUpperCase();
  int? get _boxNumber => (cell['boxNumber'] as num?)?.toInt();

  // Đồng bộ với Admin layout-view.tsx: Ô #1, Ô #2 và các ô có cellType DRONE là ô tiếp nhận Drone
  bool get _isDrone =>
      cell['isDrone'] == true ||
      _cellType == 'DRONE' ||
      _boxNumber == 1 ||
      _boxNumber == 2;

  bool get _isAvailable => _status == 'AVAILABLE';
  bool get _isFault => _status == 'FAULT';
  bool get _isCleaning => _status == 'CLEANING';

  bool get _isDoorOpen =>
      cell['doorOpen'] == true ||
      ((cell['hwState'] as String?)?.toUpperCase() == 'OPEN');

  Gradient get _bgGradient {
    // Ô drone chỉ tô tím khi còn nhận đơn. Đã có đơn giữ ô (RESERVED/OCCUPIED)
    // hoặc ô đang hỏng/bảo trì thì theo màu trạng thái như mọi ô khác.
    if (_isDrone && _isAvailable) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF818CF8), Color(0xFF4F46E5)],
      );
    }
    return switch (_status) {
      'AVAILABLE' => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AislBrand.cyan.withValues(alpha: 0.8), AislBrand.cyan],
      ),
      'OCCUPIED' || 'IN_USE' => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF1F5F9), Color(0xFFCBD5E1)],
      ),
      // Ô drone đã có đơn: xám, không phân biệt đang giữ chỗ hay đã có hàng.
      'RESERVED' when _isDrone => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF1F5F9), Color(0xFFCBD5E1)],
      ),
      'RESERVED' => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)],
      ),
      'FAULT' => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFCA5A5), Color(0xFFDC2626)],
      ),
      'CLEANING' => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF93C5FD), Color(0xFF3B82F6)],
      ),
      _ => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE5E7EB), Color(0xFF9CA3AF)],
      ),
    };
  }

  bool get _isGreyedOut =>
      _status == 'OCCUPIED' ||
      _status == 'IN_USE' ||
      (_isDrone && _status == 'RESERVED');

  Color get _fg {
    if (_isGreyedOut) {
      return const Color(0xFF64748B);
    }
    return Colors.white;
  }

  String get _sizeLabel => switch ((cell['size'] as String?) ?? '') {
    'SMALL' => 'S',
    'MEDIUM' => 'M',
    'LARGE' => 'L',
    _ => (cell['cellType'] as String? ?? '?').substring(0, 1).toUpperCase(),
  };

  @override
  Widget build(BuildContext context) {
    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: _bgGradient,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isDoorOpen
              ? const Color(0xFFFBBF24)
              : Colors.white.withValues(alpha: 0.3),
          width: _isDoorOpen ? 1.5 : 1,
        ),
        boxShadow: (_isAvailable && !_isDrone)
            ? [
                BoxShadow(
                  color: _CellPalette.available.withValues(alpha: 0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : (_isDrone && _isAvailable)
            ? [
                BoxShadow(
                  color: _CellPalette.drone.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: _buildCellContent(),
          ),
          if (_isFault)
            Positioned(
              left: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'HỎNG',
                  style: TextStyle(
                    color: Color(0xFFDC2626),
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          // Tay nắm cửa
          Positioned(
            right: 5,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                width: 3.5,
                height: 22,
                decoration: BoxDecoration(
                  color: _fg.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 2,
                      offset: const Offset(-1, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (_isAvailable) {
      content = content
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .shimmer(
            duration: 2000.ms,
            color: Colors.white.withValues(alpha: 0.2),
          )
          .scaleXY(end: 1.015, curve: Curves.easeInOutSine, duration: 1500.ms);
    }

    return GestureDetector(onTap: onTap, child: content);
  }

  Widget _buildCellContent() {
    final isXl = ((_cellType == 'XL' || _sizeLabel == 'L') && !_isDrone);
    final icon = _isDrone
        ? Icons.flight_rounded
        : (isXl ? LucideIcons.luggage : LucideIcons.box);
    final iconSize = _isDrone ? 20.0 : (isXl ? 20.0 : 16.0);

    final String statusText;
    if (_isFault) {
      statusText = 'Hỏng';
    } else if (_isCleaning) {
      statusText = 'Vệ sinh';
    } else if (_status == 'OCCUPIED' || _status == 'IN_USE') {
      statusText = 'Đang dùng';
    } else if (_status == 'RESERVED') {
      statusText = 'Đã đặt';
    } else if (_isDrone && _isAvailable) {
      statusText = 'Nhận Drone';
    } else if (_isAvailable) {
      statusText = 'Sẵn sàng';
    } else {
      statusText = _status;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Hàng trên: Số ô & Trạng thái cửa
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Ô #${_boxNumber ?? '?'}${_isDrone ? ' 🛸' : ''}',
                  style: TextStyle(
                    color: _fg,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              _buildDoorBadge(),
            ],
          ),
          // Giữa: Icon loại ô
          Center(
            child: Icon(icon, color: _fg.withValues(alpha: 0.95), size: iconSize),
          ),
          // Hàng dưới: Trạng thái ô (Sẵn sàng / Đang dùng / Báo hỏng / ...)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: _isAvailable
                    ? Colors.white.withValues(alpha: 0.22)
                    : Colors.black.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: _fg,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoorBadge() {
    if (_isDoorOpen) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF08A),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFEAB308), width: 0.8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.doorOpen, size: 9, color: Color(0xFF854D0E)),
            SizedBox(width: 2),
            Text(
              'Mở',
              style: TextStyle(
                color: Color(0xFF854D0E),
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.doorClosed, size: 9, color: _fg.withValues(alpha: 0.8)),
          const SizedBox(width: 2),
          Text(
            'Đóng',
            style: TextStyle(
              color: _fg.withValues(alpha: 0.8),
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Booking Bottom Sheet ──────────────────────────────────────────────────────

class _BookingSheet extends StatelessWidget {
  const _BookingSheet({
    required this.cell,
    required this.lockerId,
    required this.lockerName,
    required this.storeName,
    required this.onRent,
    required this.onSend,
  });

  final Map<String, dynamic> cell;
  final int lockerId;
  final String lockerName;
  final String storeName;
  final VoidCallback onRent;
  final VoidCallback onSend;

  String get _sizeVi => switch ((cell['size'] as String?) ?? '') {
    'SMALL' => 'Nhỏ (S)',
    'MEDIUM' => 'Vừa (M)',
    'LARGE' => 'Lớn (L)',
    _ => (cell['cellType'] as String?) ?? '—',
  };

  String get _boxLabel {
    final boxNum = (cell['boxNumber'] as num?)?.toInt();
    if (boxNum != null) return 'Ô số $boxNum';
    final r = (cell['rowIndex'] as num?)?.toInt() ?? 0;
    final c = (cell['colIndex'] as num?)?.toInt() ?? 0;
    return 'Hàng ${r + 1}, cột ${c + 1}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header row
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AislBrand.cyan.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: AppLottie(
                  AppLottieAssets.box,
                  fallback: (context) => const Icon(
                    LucideIcons.box,
                    color: AislBrand.navy,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ô tủ trống',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AislBrand.textTitle,
                      ),
                    ),
                    Text(
                      '$lockerName · $storeName',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AislBrand.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Cell info card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AislBrand.chipBorder),
            ),
            child: Row(
              children: [
                _SheetInfoTile(
                  icon: Icons.straighten_rounded,
                  label: 'Kích cỡ',
                  value: _sizeVi,
                ),
                const _VerticalDivider(),
                _SheetInfoTile(
                  icon: Icons.tag_rounded,
                  label: 'Vị trí',
                  value: _boxLabel,
                ),
                const _VerticalDivider(),
                _SheetInfoTile(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Trạng thái',
                  value: 'Trống',
                  valueColor: AislBrand.cyan,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Bạn muốn làm gì với ô tủ này?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 14),

          // Service buttons
          Row(
            children: [
              Expanded(
                child: _ServiceButton(
                  lottieAsset: AppLottieAssets.box,
                  label: 'Thuê tủ',
                  sublabel: 'Tính theo giờ',
                  gradient: const LinearGradient(
                    colors: [AislBrand.navy, AislBrand.blue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: onRent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ServiceButton(
                  lottieAsset: AppLottieAssets.box,
                  label: 'Gửi hàng',
                  sublabel: 'Chuyển C2C',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1D4ED8), Color(0xFF0284C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: onSend,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetInfoTile extends StatelessWidget {
  const _SheetInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: AislBrand.navy),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AislBrand.textMuted),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AislBrand.textTitle,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 44,
      color: AislBrand.chipBorder,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

class _ServiceButton extends StatelessWidget {
  const _ServiceButton({
    required this.lottieAsset,
    required this.label,
    required this.sublabel,
    required this.gradient,
    required this.onTap,
  });

  final String lottieAsset;
  final String label;
  final String sublabel;
  final LinearGradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shadowColor: gradient.colors.first.withValues(alpha: 0.35),
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(gradient: gradient),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: AppLottie(
                    lottieAsset,
                    fallback: (context) => Icon(
                      lottieAsset == AppLottieAssets.airplaneBox
                          ? LucideIcons.send
                          : LucideIcons.box,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  sublabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.bg, required this.fg});
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class _LayoutErrorRow extends StatelessWidget {
  const _LayoutErrorRow({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          const Icon(
            LucideIcons.triangleAlert,
            color: Colors.redAccent,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(LucideIcons.refreshCcw, size: 14),
            label: const Text('Thử lại'),
            style: TextButton.styleFrom(foregroundColor: AislBrand.navy),
          ),
        ],
      ),
    );
  }
}

// ── Full-page error / empty states ────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                LucideIcons.triangleAlert,
                color: Color(0xFFEF4444),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Không tải được dữ liệu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AislBrand.textTitle,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: AislBrand.textMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCcw, size: 16),
              label: const Text('Thử lại'),
              style: FilledButton.styleFrom(backgroundColor: AislBrand.navy),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AislBrand.navy.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.server,
                color: AislBrand.navy,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chưa có tủ locker',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AislBrand.textTitle,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cửa hàng này chưa có tủ locker đang hoạt động.',
              style: TextStyle(fontSize: 14, color: AislBrand.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
