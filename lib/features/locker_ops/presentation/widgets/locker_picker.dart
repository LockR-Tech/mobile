import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';

/// Tappable "select a cabinet" field shared by the SEND and RENTAL forms.
/// Shows the currently selected locker (name + address) and opens a bottom
/// sheet to pick another. Keeps both forms visually consistent.
class LockerPickerField extends StatelessWidget {
  const LockerPickerField({
    required this.lockers,
    required this.selectedId,
    required this.onSelected,
    super.key,
  });

  final List<Map<String, dynamic>> lockers;
  final int? selectedId;
  final ValueChanged<Map<String, dynamic>> onSelected;

  Map<String, dynamic>? get _selected {
    for (final l in lockers) {
      if (l['id'] == selectedId) return l;
    }
    return lockers.isNotEmpty ? lockers.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: lockers.isEmpty ? null : () => _openSheet(context),
      child: Container(
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
                    selected == null
                        ? 'Chưa có tủ khả dụng'
                        : '${selected['name'] ?? selected['code'] ?? 'Tủ'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      color: opsDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selected?['address']?.toString().isNotEmpty == true
                        ? selected!['address'] as String
                        : 'Chạm để chọn tủ khác',
                    style: const TextStyle(fontSize: 12, color: opsMutedText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronDown, color: opsMutedText, size: 20),
          ],
        ),
      ),
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Chọn tủ',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
            for (final l in lockers)
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: CircleAvatar(
                  backgroundColor: opsPrimary.withValues(alpha: 0.10),
                  child: const Icon(LucideIcons.warehouse, color: opsPrimary, size: 18),
                ),
                title: Text(
                  '${l['name'] ?? l['code'] ?? 'Tủ'}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: l['address'] != null
                    ? Text('${l['address']}', maxLines: 1, overflow: TextOverflow.ellipsis)
                    : null,
                trailing: l['id'] == selectedId
                    ? const Icon(LucideIcons.check, color: opsPrimary)
                    : null,
                onTap: () {
                  onSelected(l);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }
}
