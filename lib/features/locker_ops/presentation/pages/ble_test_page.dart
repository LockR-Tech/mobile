import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/services/locker_ble_open_service.dart';
import 'package:smart_laundry_locker/features/locker/domain/utils/locker_layout_helper.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

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
          title: Text(context.l10n.btBoxOccupied(box)),
          content: Text(
            context.l10n.btBoxOccupiedBody,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l10n.commonCancelAlt)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.l10n.btOpenAnyway)),
          ],
        ),
      );
      if (go != true || !mounted) return;
    }

    setState(() {
      _opening = true;
      _outcome = null;
      _stepText = context.l10n.btFetchingCode;
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
        BleOpenStep.scanning => L10n.current.btScanning,
        BleOpenStep.connecting => L10n.current.btConnecting,
        BleOpenStep.sending => L10n.current.btSending,
        BleOpenStep.waiting => L10n.current.btWaiting,
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
          BrandHeroHeader(
            eyebrow: 'LOCK.R • BLUETOOTH',
            title: context.l10n.profileBleTest,
            subtitle: context.l10n.btSubtitle,
          ),
          Expanded(child: _body()),
        ],
      ),
      bottomNavigationBar: _lockerId == null || _loading
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: OpsPrimaryButton(
                label: _boxNumber == null ? context.l10n.btChooseBox : context.l10n.btOpenBox(_boxNumber!),
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
          OpsEmptyState(icon: LucideIcons.cloudOff, title: context.l10n.btLoadFailed, subtitle: _error),
          TextButton.icon(
            onPressed: _loadLockers,
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: Text(context.l10n.commonRetry),
          ),
        ],
      );
    }
    if (_lockers.isEmpty) {
      return OpsEmptyState(
        icon: LucideIcons.bluetoothOff,
        title: context.l10n.btNotAllowed,
        subtitle: context.l10n.btNotAllowedBody,
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        if (_lockers.length > 1) ...[
          OpsSectionLabel(context.l10n.commonLocker),
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
        OpsBanner(
          icon: LucideIcons.bluetooth,
          text: context.l10n.btHint,
        ),
        const SizedBox(height: 16),
        OpsSectionLabel(context.l10n.btChooseBoxLabel),
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
            title: _outcome!.isOk ? context.l10n.btOpened('${_outcome!.boxNumber ?? _boxNumber}') : context.l10n.btNotOpened,
            text: _outcome!.isOk ? context.l10n.btCloseAfter : _outcome!.message,
          ),
        ],
      ],
    );
  }

  static String _lockerLabel(Map<String, dynamic> l) {
    final name = l['name'] as String?;
    final code = l['code'] as String?;
    if (name != null && code != null) return '$name ($code)';
    return name ?? code ?? L10n.current.lockerHash('${l['lockerId']}');
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
      return OpsBanner(tone: OpsBannerTone.warning, text: context.l10n.btNoBoxes);
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
                    L10n.current.btBox(number),
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
