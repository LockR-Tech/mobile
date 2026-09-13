import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/shadcn_theme.dart';
import '../../../locker_ops/presentation/widgets/ops_widgets.dart';
import '../../domain/mav_command.dart';
import '../../domain/mission_item.dart';

/// Result of editing a waypoint via [WaypointEditSheet].
enum WaypointEditAction { save, delete, move }

class WaypointEditResult {
  const WaypointEditResult(this.action, [this.item]);
  final WaypointEditAction action;
  final MissionItem? item;
}

/// Bottom sheet for editing one mission item: pick the MAVLink command, set
/// altitude and the command-specific parameter, or delete / move it.
///
/// Returns a [WaypointEditResult] via `Navigator.pop`, or `null` if dismissed.
class WaypointEditSheet extends StatefulWidget {
  const WaypointEditSheet({
    required this.item,
    required this.index,
    required this.total,
    super.key,
  });

  final MissionItem item;

  /// 1-based position shown in the title.
  final int index;
  final int total;

  static Future<WaypointEditResult?> show(
    BuildContext context, {
    required MissionItem item,
    required int index,
    required int total,
  }) {
    return showModalBottomSheet<WaypointEditResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => WaypointEditSheet(item: item, index: index, total: total),
    );
  }

  @override
  State<WaypointEditSheet> createState() => _WaypointEditSheetState();
}

class _WaypointEditSheetState extends State<WaypointEditSheet> {
  late MavCommand _command = widget.item.command;
  late final TextEditingController _altCtrl =
      TextEditingController(text: _trim(widget.item.altitude));
  late final TextEditingController _extraCtrl =
      TextEditingController(text: _trim(widget.item.extraValue ?? 0));

  @override
  void dispose() {
    _altCtrl.dispose();
    _extraCtrl.dispose();
    super.dispose();
  }

  String _trim(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toString();
  }

  MissionItem _buildItem() {
    var item = widget.item.copyWith(
      command: _command,
      altitude: _command.hasAltitude
          ? (double.tryParse(_altCtrl.text.trim()) ?? widget.item.altitude)
          : widget.item.altitude,
    );
    if (_command.hasExtraParam) {
      item = item.withExtraValue(double.tryParse(_extraCtrl.text.trim()) ?? 0);
    }
    return item;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 14, 16, 16 + bottomInset + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD7DEE8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AISLShadcnTheme.navyPrimary,
                child: Text(
                  '${widget.index}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Điểm bay ${widget.index}/${widget.total}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AISLShadcnTheme.navyPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Lệnh (MAVLink)',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<MavCommand>(
            initialValue: _command,
            isExpanded: true,
            decoration: _fieldDecoration(),
            items: [
              for (final c in MavCommand.values)
                DropdownMenuItem(
                  value: c,
                  child: Text('${c.label}  ·  ${c.shortLabel}'),
                ),
            ],
            onChanged: (v) => setState(() => _command = v ?? _command),
          ),
          if (_command.hasAltitude) ...[
            const SizedBox(height: 14),
            _numberField(
              label: 'Độ cao (m, so với điểm xuất phát)',
              controller: _altCtrl,
              icon: LucideIcons.arrowUp,
            ),
          ],
          if (_command.hasExtraParam) ...[
            const SizedBox(height: 14),
            _numberField(
              label: '${_command.extraLabel} (${_command.extraUnit})',
              controller: _extraCtrl,
              icon: LucideIcons.settings2,
            ),
          ],
          if (!_command.hasPosition) ...[
            const SizedBox(height: 14),
            const OpsBanner(
              tone: OpsBannerTone.info,
              icon: Icons.info_outline,
              text: 'Lệnh này không gắn toạ độ — nó áp dụng tại vị trí của điểm '
                  'bay liền trước trong danh sách.',
            ),
          ],
          const SizedBox(height: 18),
          if (_command.hasPosition)
            OpsSheetAction(
              label: 'Di chuyển điểm này trên bản đồ',
              icon: LucideIcons.move,
              onTap: () => Navigator.pop(
                context,
                const WaypointEditResult(WaypointEditAction.move),
              ),
            ),
          const SizedBox(height: 6),
          OpsSheetAction(
            label: 'Xoá điểm bay',
            icon: LucideIcons.trash2,
            danger: true,
            onTap: () => Navigator.pop(
              context,
              const WaypointEditResult(WaypointEditAction.delete),
            ),
          ),
          const SizedBox(height: 10),
          OpsPrimaryButton(
            label: 'Lưu thay đổi',
            icon: LucideIcons.check,
            onPressed: () => Navigator.pop(
              context,
              WaypointEditResult(WaypointEditAction.save, _buildItem()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
          ],
          decoration: _fieldDecoration(prefixIcon: icon),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration({IconData? prefixIcon}) {
    return InputDecoration(
      isDense: true,
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, size: 18, color: AISLShadcnTheme.navyAccent),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AISLShadcnTheme.navyAccent, width: 1.5),
      ),
    );
  }
}
