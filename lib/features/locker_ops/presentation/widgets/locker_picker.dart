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
    this.placeholder,
    this.onlyActive = false,
    super.key,
  });

  final List<Map<String, dynamic>> lockers;
  final int? selectedId;
  final ValueChanged<Map<String, dynamic>> onSelected;

  /// Có giá trị ⇒ chưa chọn thì hiện câu này thay vì tự lấy tủ đầu danh sách
  /// (màn cần khách chọn tủ rõ ràng, vd. báo sự cố).
  final String? placeholder;

  /// Chỉ cho chọn tủ đang hoạt động (`status == 'ACTIVE'` và `online != false`),
  /// nhưng vẫn hiện đầy đủ mọi tủ kèm lý do tạm khoá để đồng bộ danh sách 20 tủ với Admin.
  final bool onlyActive;

  static String? _inactiveReason(Map<String, dynamic> locker) {
    if (locker['online'] == false) return 'Mất kết nối';
    final status = '${locker['status'] ?? 'ACTIVE'}'.trim().toUpperCase();
    if (status == 'ACTIVE') return null;
    return status == 'MAINTENANCE' ? 'Đang bảo trì' : 'Tạm ngưng';
  }

  Map<String, dynamic>? get _selected {
    for (final l in lockers) {
      if (l['id'] == selectedId) return l;
    }
    if (placeholder != null) return null;
    if (onlyActive) {
      for (final l in lockers) {
        if (_inactiveReason(l) == null) return l;
      }
      return null;
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
                        ? (lockers.isNotEmpty && placeholder != null
                              ? placeholder!
                              : 'Chưa có tủ khả dụng')
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
              Builder(
                builder: (_) {
                  final reason = onlyActive ? _inactiveReason(l) : null;
                  final enabled = reason == null;
                  final address = l['address']?.toString().trim() ?? '';
                  return ListTile(
                    enabled: enabled,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: enabled
                          ? opsPrimary.withValues(alpha: 0.10)
                          : const Color(0xFFF1F5F9),
                      child: Icon(
                        LucideIcons.warehouse,
                        color: enabled ? opsPrimary : const Color(0xFF94A3B8),
                        size: 18,
                      ),
                    ),
                    title: Text(
                      '${l['name'] ?? l['code'] ?? 'Tủ'}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: enabled ? opsDark : const Color(0xFF94A3B8),
                      ),
                    ),
                    subtitle: (address.isNotEmpty || reason != null)
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (address.isNotEmpty)
                                Text(
                                  address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (reason != null)
                                Text(
                                  'Tạm không khả dụng: $reason',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFB91C1C),
                                  ),
                                ),
                            ],
                          )
                        : null,
                    trailing: l['id'] == selectedId && enabled
                        ? const Icon(LucideIcons.check, color: opsPrimary)
                        : null,
                    onTap: enabled
                        ? () {
                            onSelected(l);
                            Navigator.pop(ctx);
                          }
                        : null,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
