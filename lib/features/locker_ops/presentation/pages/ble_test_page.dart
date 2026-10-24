import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/services/locker_ble_open_service.dart';
import 'package:smart_laundry_locker/features/locker/domain/utils/locker_layout_helper.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

/// Thử mở ô qua Bluetooth (F3-G11) — chỉ tài khoản admin đã cho thử ở trang chi tiết tủ.
/// Chọn tủ, chọn ô bất kỳ, app xin mã mở ô từ máy chủ rồi ghi thẳng cho Pi của tủ qua BLE.
class BleTestPage extends StatefulWidget {
  const BleTestPage({super.key, this.service, this.opener});

  /// Cho test thay API / BLE.
  final LockerOpsService? service;
  final Future<BleOpenOutcome> Function(BleOpenTicket ticket, void Function(BleOpenStep) onStep)? opener;

  @override
  State<BleTestPage> createState() => _BleTestPageState();
}

class _BleTestPageState extends State<BleTestPage> {
  late final LockerOpsService _service = widget.service ?? LockerOpsService();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _lockers = const [];
  int? _lockerId;

  bool _layoutLoading = false;
  String? _layoutError;
  List<Map<String, dynamic>> _cells = const [];
  int? _boxNumber;

  bool _opening = false;
  String? _stepText;
  BleOpenOutcome? _outcome;

  @override
  void initState() {
    super.initState();
    _loadLockers();
  }

  Future<void> _loadLockers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lockers = await _service.bleTestLockers();
      if (!mounted) return;
      setState(() {
        _lockers = lockers;
        _loading = false;
      });
      if (lockers.isNotEmpty) _selectLocker((lockers.first['lockerId'] as num).toInt());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = LockerOpsService.errorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _selectLocker(int lockerId) async {
    setState(() {
      _lockerId = lockerId;
      _boxNumber = null;
      _outcome = null;
      _layoutLoading = true;
      _layoutError = null;
    });
    try {
      final layout = LockerLayoutHelper.enrichLayout(await _service.layout(lockerId));
      if (!mounted || _lockerId != lockerId) return;
      setState(() {
        _cells = (layout['cells'] as List? ?? const []).cast<Map<String, dynamic>>();
        _layoutLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _layoutError = LockerOpsService.errorMessage(e);
        _layoutLoading = false;
      });
    }
  }

  Map<String, dynamic>? get _selectedCell =>
      _cells.where((c) => (c['boxNumber'] as num?)?.toInt() == _boxNumber).firstOrNull;

  Future<void> _open() async {
    final lockerId = _lockerId;
    final box = _boxNumber;
    if (lockerId == null || box == null || _opening) return;
    final cell = _selectedCell;
    if (cell != null && LockerLayoutHelper.status(cell) == 'OCCUPIED') {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Ô $box đang có hàng'),
          content: const Text(
            'Ô này đang giữ hàng của một đơn. Chỉ mở khi bạn được giao kiểm tra tủ và đóng lại ngay sau khi thử.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Vẫn mở')),
          ],
        ),
      );
      if (go != true || !mounted) return;
    }

    setState(() {
      _opening = true;
      _outcome = null;
      _stepText = 'Đang lấy mã mở ô từ máy chủ…';
    });
    final BleOpenOutcome outcome;
    try {
      final ticket = BleOpenTicket.fromJson(await _service.bleOpenToken(lockerId, box));
      final opener = widget.opener ??
          (t, onStep) => LockerBleOpenService.instance.open(t, onStep: onStep);
      outcome = await opener(ticket, (step) {
        if (mounted) setState(() => _stepText = _stepLabel(step));
      });
    } catch (e) {
      // Không xin được mã (chưa được cấp, mất mạng…): chưa chạm tới tủ.
      if (!mounted) return;
      setState(() {
        _opening = false;
        _stepText = null;
      });
      _showSnack(LockerOpsService.errorMessage(e));
      return;
    }
    if (!mounted) return;
    setState(() {
      _opening = false;
      _stepText = null;
      _outcome = outcome;
    });
  }

  static String _stepLabel(BleOpenStep step) => switch (step) {
        BleOpenStep.scanning => 'Đang tìm tủ qua Bluetooth…',
        BleOpenStep.connecting => 'Đang kết nối với tủ…',
        BleOpenStep.sending => 'Đang gửi lệnh mở ô…',
        BleOpenStep.waiting => 'Chờ tủ mở khoá…',
      };

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: opsSurface,
      body: Column(
        children: [
          const BrandHeroHeader(
            eyebrow: 'LOCK.R • BLUETOOTH',
            title: 'Thử mở ô qua Bluetooth',
            subtitle: 'Đứng cạnh tủ, chọn ô rồi bấm mở',
          ),
          Expanded(child: _body()),
        ],
      ),
      bottomNavigationBar: _lockerId == null || _loading
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: OpsPrimaryButton(
                label: _boxNumber == null ? 'Chọn một ô để mở' : 'Mở ô $_boxNumber qua Bluetooth',
                icon: LucideIcons.bluetooth,
                loading: _opening,
                onPressed: _boxNumber == null || _opening ? null : _open,
              ),
            ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OpsEmptyState(icon: LucideIcons.cloudOff, title: 'Không tải được danh sách tủ', subtitle: _error),
          TextButton.icon(
            onPressed: _loadLockers,
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: const Text('Thử lại'),
          ),
        ],
      );
    }
    if (_lockers.isEmpty) {
      return const OpsEmptyState(
        icon: LucideIcons.bluetoothOff,
        title: 'Chưa được cho thử',
        subtitle: 'Admin chưa cho tài khoản này thử mở ô qua Bluetooth ở tủ nào.',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        if (_lockers.length > 1) ...[
          const OpsSectionLabel('Tủ'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final l in _lockers)
                ChoiceChip(
                  label: Text(_lockerLabel(l)),
                  selected: (l['lockerId'] as num).toInt() == _lockerId,
                  onSelected: (_) => _selectLocker((l['lockerId'] as num).toInt()),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ] else
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _lockerLabel(_lockers.first),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: opsDark),
            ),
          ),
        const OpsBanner(
          icon: LucideIcons.bluetooth,
          text: 'Bật Bluetooth và đứng trong khoảng 2 m trước tủ. Mỗi lần mở đều được ghi vào nhật ký của tủ.',
        ),
        const SizedBox(height: 16),
        const OpsSectionLabel('Chọn ô'),
        if (_layoutLoading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_layoutError != null)
          OpsBanner(tone: OpsBannerTone.danger, text: _layoutError!)
        else
          _BoxGrid(
            cells: _cells,
            selected: _boxNumber,
            onTap: _opening ? null : (n) => setState(() {
                  _boxNumber = n;
                  _outcome = null;
                }),
          ),
        if (_stepText != null) ...[
          const SizedBox(height: 16),
          OpsCard(
            child: Row(
              children: [
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 12),
                Expanded(child: Text(_stepText!, style: const TextStyle(color: opsDark))),
              ],
            ),
          ),
        ],
        if (_outcome != null) ...[
          const SizedBox(height: 16),
          OpsBanner(
            tone: _outcome!.isOk ? OpsBannerTone.success : OpsBannerTone.danger,
            icon: _outcome!.isOk ? LucideIcons.lockOpen : LucideIcons.circleAlert,
            title: _outcome!.isOk ? 'Đã mở ô ${_outcome!.boxNumber ?? _boxNumber}' : 'Chưa mở được',
            text: _outcome!.isOk ? 'Nhớ đóng cửa ô sau khi thử.' : _outcome!.message,
          ),
        ],
      ],
    );
  }

  static String _lockerLabel(Map<String, dynamic> l) {
    final name = l['name'] as String?;
    final code = l['code'] as String?;
    if (name != null && code != null) return '$name ($code)';
    return name ?? code ?? 'Tủ #${l['lockerId']}';
  }
}

/// Sơ đồ ô theo vị trí thật (rowIndex từ 1, colIndex từ 0; ô XL cao 2 hàng). Ô nào cũng chọn được.
class _BoxGrid extends StatelessWidget {
  const _BoxGrid({required this.cells, required this.selected, required this.onTap});

  final List<Map<String, dynamic>> cells;
  final int? selected;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    if (cells.isEmpty) {
      return const OpsBanner(tone: OpsBannerTone.warning, text: 'Tủ chưa có ô nào.');
    }
    final placed = cells.every((c) => c['rowIndex'] is num && c['colIndex'] is num);
    if (!placed) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [for (final c in cells) SizedBox(width: 100, height: 72, child: _tile(c))],
      );
    }
    final cols = cells.map((c) => (c['colIndex'] as num).toInt()).reduce((a, b) => a > b ? a : b) + 1;
    final rows = cells
        .map((c) => (c['rowIndex'] as num).toInt() + (LockerLayoutHelper.isXl(c) ? 1 : 0))
        .reduce((a, b) => a > b ? a : b);
    const gap = 8.0, cellHeight = 76.0;
    return LayoutBuilder(builder: (context, constraints) {
      final cellWidth = (constraints.maxWidth - gap * (cols - 1)) / cols;
      return SizedBox(
        height: rows * cellHeight + (rows - 1) * gap,
        child: Stack(
          children: [
            for (final c in cells)
              Positioned(
                left: (c['colIndex'] as num).toInt() * (cellWidth + gap),
                top: ((c['rowIndex'] as num).toInt() - 1) * (cellHeight + gap),
                width: cellWidth,
                height: LockerLayoutHelper.isXl(c) ? cellHeight * 2 + gap : cellHeight,
                child: _tile(c),
              ),
          ],
        ),
      );
    });
  }

  Widget _tile(Map<String, dynamic> c) {
    final number = (c['boxNumber'] as num?)?.toInt() ?? 0;
    final isSelected = number == selected;
    final statusColor = LockerLayoutHelper.statusColor(LockerLayoutHelper.status(c));
    return Material(
      color: isSelected ? opsPrimary : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: ValueKey('ble-box-$number'),
        borderRadius: BorderRadius.circular(14),
        onTap: onTap == null ? null : () => onTap!(number),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isSelected ? opsPrimary : opsBorder, width: isSelected ? 2 : 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LockerLayoutHelper.cellIcon(c), size: 14, color: isSelected ? Colors.white : opsDark),
                  const SizedBox(width: 4),
                  Text(
                    'Ô $number',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : opsDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                LockerLayoutHelper.statusLabel(c),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: isSelected ? Colors.white70 : statusColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
