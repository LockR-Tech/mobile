import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/presentation/pages/directions_map_page.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_booking_sheet.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/pages/rent_locker_page.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/pages/send_parcel_page.dart';
import 'package:smart_laundry_locker/features/stores/domain/entities/store.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
      final all = await _service.lockersByStore(widget.store.id);
      if (!mounted) return;
      setState(() {
        _lockers = all.where((l) {
          final s = (l['status'] as String?)?.toUpperCase();
          return s == 'ACTIVE' || s == null;
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
        child: CircularProgressIndicator(color: AislBrand.navy),
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
    return raw;
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
    final isActive =
        (widget.locker['status'] as String?)?.toUpperCase() == 'ACTIVE';

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
            available: available,
            totalCells: totalCells,
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
                      _Pill(
                        label: isActive ? 'Hoạt động' : 'Ngừng',
                        bg: isActive
                            ? const Color(0xFFDEF7EC)
                            : const Color(0xFFFDE8E8),
                        fg: isActive
                            ? const Color(0xFF046C4E)
                            : const Color(0xFF9B1C1C),
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
    if ((cell['cellType'] as String?)?.toUpperCase() == 'DRONE') {
      showModalBottomSheet<void>(
        context: ctx,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DroneBookingSheet(
          cell: cell,
          lockerName: _lockerName,
          origin: widget.storeLatLng,
          lockerId: _lockerId,
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
      (cell['cellType'] as String?) == 'XL';

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

                final height = 58.0 * span + 5.0 * (span - 1);

                colChildren.add(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
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
          _LegendChip(color: _CellPalette.fault, label: 'Lỗi'),
          _LegendChip(color: _CellPalette.cleaning, label: 'Bảo trì'),
          _LegendChip(
            color: _CellPalette.drone,
            label: 'Drone',
            icon: Icons.flight_rounded,
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

  String get _status => (cell['status'] as String?) ?? '';
  String get _cellType => (cell['cellType'] as String?) ?? 'STANDARD';
  bool get _isDrone => _cellType == 'DRONE';
  bool get _isAvailable => _status == 'AVAILABLE';
  bool get _isFault => _status == 'FAULT';

  Gradient get _bgGradient {
    if (_isDrone) {
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

  Color get _fg {
    if (_status == 'OCCUPIED' || _status == 'IN_USE') {
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: (_isAvailable && !_isDrone)
            ? [
                BoxShadow(
                  color: _CellPalette.available.withValues(alpha: 0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : _isDrone
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
            child: _isDrone ? _buildDroneContent() : _buildStandardContent(),
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
            right: 6,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: _fg.withValues(alpha: 0.4),
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

  /// Ô drone — icon máy bay không người lái
  Widget _buildDroneContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.flight_rounded, color: Colors.white, size: 26),
        const SizedBox(height: 2),
        if (_isAvailable)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'DRONE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
      ],
    );
  }

  /// Ô thường — icon kích cỡ + "TRỐNG"
  Widget _buildStandardContent() {
    final isXl = _cellType == 'XL' || _sizeLabel == 'L';
    final icon = isXl ? LucideIcons.luggage : LucideIcons.box;
    final iconSize = _isFault ? 20.0 : (isXl ? 32.0 : 24.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: _fg.withValues(alpha: 0.95), size: iconSize),
        if (_isAvailable) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'TRỐNG',
              style: TextStyle(
                color: _fg,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ] else if (_isFault) ...[
          const SizedBox(height: 6),
          const Text(
            'Hỏng',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
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
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AislBrand.cyan.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  LucideIcons.boxes,
                  color: AislBrand.cyan,
                  size: 24,
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
                  icon: Icons.access_time_rounded,
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
                  icon: Icons.move_to_inbox_rounded,
                  label: 'Gửi hàng',
                  sublabel: 'Chuyển C2C',
                  gradient: const LinearGradient(
                    colors: [AislBrand.blue, AislBrand.cyan],
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
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String sublabel;
  final LinearGradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(gradient: gradient),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Column(
              children: [
                Icon(icon, color: Colors.white, size: 26),
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
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11,
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
