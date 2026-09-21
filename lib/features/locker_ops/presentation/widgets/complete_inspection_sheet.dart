import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/core/media/media.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';

/// Kết quả 1 mục checklist kiểm tra định kỳ (giá trị `result` gửi server).
enum InspectionResult {
  pass('PASS', 'Đạt', Color(0xFF16A34A)),
  fail('FAIL', 'Không đạt', Color(0xFFDC2626)),
  na('NA', 'Không áp dụng', Color(0xFF64748B));

  const InspectionResult(this.code, this.label, this.color);

  final String code;
  final String label;
  final Color color;
}

/// Các mục checklist của lịch: ưu tiên `checklistItems` server đã tách; response
/// cũ chỉ có `checklist` ⇒ tách theo dòng hoặc ';' giống server (trim, bỏ trùng).
List<String> inspectionChecklistItems(Map<String, dynamic> schedule) {
  final raw = schedule['checklistItems'];
  final Iterable<String> source = raw is List && raw.isNotEmpty
      ? raw.map((e) => '$e')
      : '${schedule['checklist'] ?? ''}'.split(RegExp(r'\r?\n|;'));
  final items = <String>[];
  for (final item in source) {
    final label = item.trim();
    if (label.isNotEmpty && !items.contains(label)) items.add(label);
  }
  return items;
}

/// Sheet hoàn tất 1 lần kiểm tra định kỳ của KTV tủ: đánh giá từng mục checklist
/// (Đạt / Không đạt / Không áp dụng + ghi chú), server tự suy kết quả. Có mục
/// Không đạt ⇒ chọn thêm ô hỏng (tuỳ chọn) + mô tả; server mở phiếu giao cho KTV.
/// Lịch chưa có checklist ⇒ chọn kết quả chung (PASSED/FAILED, hợp đồng cũ).
/// Đóng sheet trả về lịch sau khi cập nhật (`lastResult`, `pendingReportId`).
class CompleteInspectionSheet extends StatefulWidget {
  const CompleteInspectionSheet({
    required this.schedule,
    required this.service,
    this.lockerCells,
    super.key,
  });

  final Map<String, dynamic> schedule;
  final LockerOpsService service;

  /// Ô của tủ nếu trang đã tải sẵn layout đúng tủ này; `null` ⇒ sheet tự tải
  /// khi cần chọn ô hỏng.
  final List<Map<String, dynamic>>? lockerCells;

  @override
  State<CompleteInspectionSheet> createState() =>
      _CompleteInspectionSheetState();
}

class _CompleteInspectionSheetState extends State<CompleteInspectionSheet> {
  static const _accent = Color(0xFF16A34A);

  late final List<String> _items = inspectionChecklistItems(widget.schedule);
  late final List<InspectionResult?> _results =
      List<InspectionResult?>.filled(_items.length, null);
  late final List<TextEditingController> _itemNotes = [
    for (var i = 0; i < _items.length; i++) TextEditingController(),
  ];
  final Set<int> _openNotes = {};

  // Lịch chưa có checklist: kết quả chung (chỉ Đạt / Không đạt).
  InspectionResult? _overall;

  final _noteCtrl = TextEditingController();
  final _faultReasonCtrl = TextEditingController();
  final _photos = PhotoPickerController(maxPhotos: 3);

  List<Map<String, dynamic>>? _cells;
  bool _cellsLoading = false;
  String? _cellsError;
  int? _faultBoxId;

  bool _submitting = false;
  String? _error;

  bool get _hasChecklist => _items.isNotEmpty;

  int get _answered => _results.whereType<InspectionResult>().length;

  bool get _complete => _hasChecklist ? _answered == _items.length : _overall != null;

  bool get _failed => _hasChecklist
      ? _results.contains(InspectionResult.fail)
      : _overall == InspectionResult.fail;

  int? get _lockerId => _asInt(widget.schedule['lockerId']);

  @override
  void dispose() {
    for (final c in _itemNotes) {
      c.dispose();
    }
    _noteCtrl.dispose();
    _faultReasonCtrl.dispose();
    _photos.dispose();
    super.dispose();
  }

  void _setResult(int index, InspectionResult result) {
    setState(() {
      _results[index] = result;
      if (result == InspectionResult.fail) _openNotes.add(index);
    });
    _ensureCells();
  }

  void _setOverall(InspectionResult result) {
    setState(() => _overall = result);
    _ensureCells();
  }

  /// Danh sách ô để chọn ô hỏng — chỉ tải khi lần kiểm tra có mục Không đạt.
  Future<void> _ensureCells() async {
    final lockerId = _lockerId;
    if (!_failed || lockerId == null || _cells != null || _cellsLoading) return;
    final preloaded = widget.lockerCells;
    if (preloaded != null) {
      setState(() => _cells = _sortedCells(preloaded));
      return;
    }
    setState(() {
      _cellsLoading = true;
      _cellsError = null;
    });
    try {
      final layout = await widget.service.layout(lockerId);
      final cells = (layout['cells'] as List?)
              ?.whereType<Map>()
              .map((c) => Map<String, dynamic>.from(c))
              .toList() ??
          const <Map<String, dynamic>>[];
      if (mounted) setState(() => _cells = _sortedCells(cells));
    } catch (e) {
      if (mounted) {
        setState(() => _cellsError = LockerOpsService.errorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _cellsLoading = false);
    }
  }

  List<Map<String, dynamic>> _sortedCells(List<Map<String, dynamic>> cells) =>
      cells.where((c) => _asInt(c['id']) != null).toList()
        ..sort(
          (a, b) => (_asInt(a['boxNumber']) ?? 0)
              .compareTo(_asInt(b['boxNumber']) ?? 0),
        );

  Future<void> _submit() async {
    final id = _asInt(widget.schedule['id']);
    if (id == null) {
      setState(() => _error = 'Mã lịch kiểm tra không hợp lệ.');
      return;
    }
    if (!_complete) return;
    final failed = _failed;

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      // Ảnh minh chứng (tuỳ chọn) — upload trước, lỗi mạng thì lịch chưa đổi gì.
      var photoUrls = const <String>[];
      if (_photos.isNotEmpty) {
        await _photos.uploadAll(caption: 'Ảnh kiểm tra định kỳ');
        photoUrls = _photos.photos
            .map((p) => p.upload?.secureUrl)
            .whereType<String>()
            .toList();
      }

      final result = await widget.service.completeInspection(
        id,
        [
          for (var i = 0; i < _items.length; i++)
            {
              'label': _items[i],
              'result': _results[i]!.code,
              if (_itemNotes[i].text.trim().isNotEmpty)
                'note': _itemNotes[i].text.trim(),
            },
        ],
        status: _hasChecklist ? null : (failed ? 'FAILED' : 'PASSED'),
        note: _noteCtrl.text,
        faultBoxId: failed ? _faultBoxId : null,
        faultReason: failed ? _faultReasonCtrl.text : null,
        photoUrls: photoUrls,
      );
      if (mounted) Navigator.pop(context, result);
    } catch (e) {
      if (mounted) setState(() => _error = LockerOpsService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.schedule;
    final title = s['title'] ?? 'Kiểm tra định kỳ Kiosk';
    final lockerCode = s['lockerCode'];
    final lockerName = s['lockerName'];
    final lockerLabel =
        '${lockerName ?? "Tủ Kiosk"}${lockerCode != null ? " ($lockerCode)" : ""}';
    final intervalDays = s['intervalDays'] ?? 30;
    final address = s['address']?.toString() ?? '';
    final locationNote = s['locationNote']?.toString() ?? '';

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.fact_check_rounded,
                      color: _accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Xác nhận kiểm tra định kỳ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: opsDark,
                          ),
                        ),
                        Text(
                          '$title · $lockerLabel',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: opsMutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Thẻ thông tin tủ và chu kỳ
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 16,
                      color: Color(0xFFB45309),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        lockerLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: opsDark,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Text(
                        'Chu kỳ: $intervalDays ngày',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (address.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 15,
                        color: Color(0xFF16A34A),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '$address${locationNote.isNotEmpty ? " · $locationNote" : ""}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF166534),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),

              if (_hasChecklist) ...[
                Text(
                  'Hạng mục kiểm tra ($_answered/${_items.length})',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: opsDark,
                  ),
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < _items.length; i++) _itemTile(i),
              ] else ...[
                const Text(
                  'Lịch này chưa có checklist — chọn kết quả chung:',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: opsDark,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final r in const [
                      InspectionResult.pass,
                      InspectionResult.fail,
                    ])
                      _resultChip(
                        key: ValueKey('inspection-overall-${r.code}'),
                        result: r,
                        selected: _overall == r,
                        onTap: () => _setOverall(r),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              _verdictBanner(intervalDays),
              if (_failed && _lockerId != null) ...[
                const SizedBox(height: 12),
                _faultSection(),
              ],
              const SizedBox(height: 14),

              // Ghi chú biên bản
              TextField(
                controller: _noteCtrl,
                enabled: !_submitting,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Ghi chú biên bản kiểm tra (tuỳ chọn)',
                  hintText:
                      'Tình trạng chung, vệ sinh ô tủ, linh kiện đã thay nếu có...',
                  isDense: true,
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: opsBorder),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Ảnh minh chứng (tuỳ chọn)
              const Text(
                'Ảnh minh chứng hiện trường (tuỳ chọn):',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: opsDark,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Chụp ảnh toàn cảnh tủ, ổ khóa hoặc linh kiện vừa kiểm tra để lưu hồ sơ đối soát.',
                style: TextStyle(fontSize: 11.5, color: opsMutedText),
              ),
              const SizedBox(height: 8),
              PhotoPickerField(
                controller: _photos,
                enabled: !_submitting,
                thumbSize: 76,
                accentColor: _accent,
                addLabel: 'Chụp ảnh',
                helperText: 'Tối đa ${_photos.maxPhotos} ảnh',
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                OpsBanner(
                  tone: OpsBannerTone.danger,
                  icon: Icons.error_outline,
                  text: _error!,
                ),
              ],
              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      child: const Text(
                        'Đóng',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: opsDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      key: const ValueKey('inspection-submit'),
                      // Chỉ bật khi mọi mục đã có kết quả.
                      onPressed: _submitting || !_complete ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _failed
                            ? const Color(0xFFDC2626)
                            : _accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 18,
                            ),
                      label: Text(
                        _submitting ? 'Đang cập nhật...' : 'Xác nhận hoàn thành',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemTile(int index) {
    final selected = _results[index];
    final tone = selected?.color;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: tone == null ? Colors.white : tone.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tone == null ? opsBorder : tone.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1}. ${_items[index]}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: opsDark,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final r in InspectionResult.values)
                _resultChip(
                  key: ValueKey('inspection-item-$index-${r.code}'),
                  result: r,
                  selected: selected == r,
                  onTap: () => _setResult(index, r),
                ),
            ],
          ),
          if (_openNotes.contains(index)) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _itemNotes[index],
              enabled: !_submitting,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: selected == InspectionResult.fail
                    ? 'Mô tả lỗi phát hiện (tuỳ chọn)'
                    : 'Ghi chú (tuỳ chọn)',
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: opsBorder),
                ),
              ),
            ),
          ] else
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _submitting
                    ? null
                    : () => setState(() => _openNotes.add(index)),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
                icon: const Icon(Icons.edit_note, size: 16),
                label: const Text(
                  'Ghi chú',
                  style: TextStyle(fontSize: 11.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _resultChip({
    required Key key,
    required InspectionResult result,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final color = result.color;
    return InkWell(
      key: key,
      onTap: _submitting ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? color : const Color(0xFFE2E8F0),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check, size: 13, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              result.label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? color : opsDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Kết quả suy ra từ các mục (server suy lại y hệt khi nhận `items`).
  Widget _verdictBanner(Object intervalDays) {
    if (!_complete) {
      return OpsBanner(
        tone: OpsBannerTone.info,
        icon: Icons.pending_actions_outlined,
        text: _hasChecklist
            ? 'Còn ${_items.length - _answered}/${_items.length} hạng mục chưa đánh giá.'
            : 'Chọn Đạt hoặc Không đạt cho lần kiểm tra này.',
      );
    }
    if (_failed) {
      return OpsBanner(
        tone: OpsBannerTone.danger,
        icon: Icons.report_gmailerrorred_outlined,
        text: _lockerId != null
            ? 'Kết quả: KHÔNG ĐẠT — hệ thống sẽ mở phiếu sự cố giao cho bạn. '
                  'Hạn kiểm tra kế tiếp chỉ dời khi phiếu được hoàn tất.'
            : 'Kết quả: KHÔNG ĐẠT.',
      );
    }
    return OpsBanner(
      tone: OpsBannerTone.success,
      icon: Icons.verified_outlined,
      text: 'Kết quả: ĐẠT — hạn kiểm tra kế tiếp dời sang $intervalDays ngày sau.',
    );
  }

  /// Chọn ô hỏng (tuỳ chọn) + mô tả cho phiếu server sẽ mở.
  Widget _faultSection() {
    final cells = _cells;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ô bị hỏng (tuỳ chọn)',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF991B1B),
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Chọn ô ⇒ ô chuyển Hỏng và phiếu gắn với ô đó; không chọn ⇒ phiếu cấp tủ.',
            style: TextStyle(fontSize: 11, color: opsMutedText),
          ),
          const SizedBox(height: 8),
          if (_cellsLoading)
            const LinearProgressIndicator(minHeight: 2, color: opsPrimary)
          else if (_cellsError != null)
            Text(
              _cellsError!,
              style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
            )
          else if (cells != null)
            DropdownButtonFormField<int?>(
              key: const ValueKey('inspection-fault-box'),
              initialValue: _faultBoxId,
              isExpanded: true,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text(
                    'Không gắn ô — sự cố cấp tủ',
                    style: TextStyle(fontSize: 12.5),
                  ),
                ),
                for (final c in cells)
                  DropdownMenuItem<int?>(
                    value: _asInt(c['id']),
                    child: Text(
                      'Ô #${c['boxNumber']} · ${statusLabel(c['status']?.toString())}',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
              ],
              onChanged: _submitting
                  ? null
                  : (value) => setState(() => _faultBoxId = value),
            ),
          const SizedBox(height: 10),
          TextField(
            controller: _faultReasonCtrl,
            enabled: !_submitting,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Mô tả sự cố (tuỳ chọn)',
              hintText: 'Để trống ⇒ phiếu liệt kê các mục không đạt',
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value');
}
