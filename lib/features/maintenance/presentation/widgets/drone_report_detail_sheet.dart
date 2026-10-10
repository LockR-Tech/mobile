import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/core/config/business_config_service.dart';
import 'package:smart_laundry_locker/core/media/media.dart';
import 'package:smart_laundry_locker/core/utils/app_date_time.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';

/// Hồ sơ xử lý sự cố dành riêng cho KTV Drone.
///
/// Bố cục và quy trình bám theo hồ sơ sự cố của KTV tủ: thông tin phiếu,
/// ảnh theo từng giai đoạn, nhật ký có ảnh, nhận việc và nghiệm thu.
class DroneReportDetailSheet extends StatefulWidget {
  const DroneReportDetailSheet({
    super.key,
    required this.initialReport,
    required this.service,
    required this.currentUserId,
    required this.onChanged,
  });

  final Map<String, dynamic> initialReport;
  final LockerOpsService service;
  final String? currentUserId;
  final Future<void> Function() onChanged;

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> report,
    required LockerOpsService service,
    required String? currentUserId,
    required Future<void> Function() onChanged,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DroneReportDetailSheet(
        initialReport: report,
        service: service,
        currentUserId: currentUserId,
        onChanged: onChanged,
      ),
    );
  }

  @override
  State<DroneReportDetailSheet> createState() => _DroneReportDetailSheetState();
}

class _DroneReportDetailSheetState extends State<DroneReportDetailSheet> {
  static const _accent = Color(0xFF0284C7);
  static const _dark = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);

  final _noteController = TextEditingController();
  late final PhotoPickerController _logPhotos = PhotoPickerController(
    maxPhotos:
        BusinessConfigService.instance.current.reportPhotosPerRequestStaff,
  );

  late Map<String, dynamic> _report = Map<String, dynamic>.from(
    widget.initialReport,
  );
  List<ReportAttachment> _attachments = const [];
  List<Map<String, dynamic>> _logs = const [];
  bool _loading = true;
  bool _saving = false;
  bool _showLogEditor = false;
  String? _loadError;

  int? get _reportId => _asInt(_report['id']);
  String get _status => '${_report['status'] ?? 'OPEN'}';
  bool get _assignedToMe =>
      widget.currentUserId != null &&
      '${_report['assignedToUserId']}' == widget.currentUserId;

  bool get _canClaim {
    if (_status != 'OPEN') return false;
    final routedTo = _report['routedToUserId']?.toString();
    return routedTo == null ||
        routedTo.isEmpty ||
        routedTo == widget.currentUserId;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _logPhotos.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final id = _reportId;
    if (id == null) return;
    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      final values = await Future.wait<Object>([
        widget.service.getDroneReport(id),
        widget.service.droneReportAttachments(id),
        widget.service.droneReportLogs(id),
      ]);
      final detail = Map<String, dynamic>.from(values[0] as Map);
      final attachmentMaps = (values[1] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);
      final logs = (values[2] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);
      if (!mounted) return;
      setState(() {
        _report = detail;
        _attachments = _mergeAttachments(detail, attachmentMaps);
        _logs = logs;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _attachments = _mergeAttachments(_report, const []);
        _loading = false;
        _loadError = LockerOpsService.errorMessage(error);
      });
    }
  }

  Future<void> _claim() async {
    final id = _reportId;
    if (id == null || _saving) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nhận xử lý sự cố Drone?'),
        content: Text(
          'Xác nhận nhận phiếu RPT-$id và chịu trách nhiệm cập nhật nhật ký xử lý.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Nhận việc'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      final claimed = await widget.service.claimDroneReport(id);
      if (!mounted) return;
      setState(() => _report = claimed);
      _showMessage('Đã nhận xử lý phiếu Drone RPT-$id');
      await widget.onChanged();
      await _load();
    } catch (error) {
      if (mounted) _showMessage(LockerOpsService.errorMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addLog() async {
    final id = _reportId;
    final note = _noteController.text.trim();
    if (id == null || _saving || (note.isEmpty && _logPhotos.isEmpty)) return;
    setState(() => _saving = true);
    try {
      final photos = await _logPhotos.uploadAll(caption: note);
      await widget.service.addDroneReportLog(
        id,
        note.isEmpty ? 'Cập nhật ảnh tiến độ sửa chữa Drone' : note,
        attachments: photos,
      );
      _noteController.clear();
      _logPhotos.clear();
      if (!mounted) return;
      setState(() => _showLogEditor = false);
      _showMessage('Đã cập nhật nhật ký xử lý');
      await widget.onChanged();
      await _load();
    } catch (error) {
      if (mounted) _showMessage(LockerOpsService.errorMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _resolve() async {
    final id = _reportId;
    if (id == null) return;
    final resolved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _DroneResolveSheet(
        reportId: id,
        service: widget.service,
        existingAttachments: _attachments,
      ),
    );
    if (resolved != true || !mounted) return;
    _showMessage('Đã nghiệm thu và hoàn tất sự cố Drone');
    await widget.onChanged();
    await _load();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final id = _reportId;
    final createdAt = _formatDate(_report['createdAt']);
    final assignedName = _text(
      _report['assignedToTechnicianName'] ?? _report['technicianName'],
    );
    final reporterName = _text(_report['reporterName']);
    final droneCode = _text(_report['droneCode']);
    final description = _cleanDescription(_report['description']);
    final overdue = _report['overdue'] == true;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .9,
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 8, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'RPT-${id ?? '—'} · ${_report['title'] ?? 'Sự cố Drone'}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: _dark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusChip(_status),
                          ],
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Hồ sơ chi tiết phiếu sự cố kỹ thuật Drone',
                          style: TextStyle(fontSize: 12, color: _muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  key: const ValueKey('drone-report-detail-scroll'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(18),
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _Badge(
                          icon: Icons.flight_outlined,
                          label: droneCode.isNotEmpty
                              ? droneCode
                              : 'Drone #${_report['droneUnitId'] ?? '—'}',
                          color: _accent,
                        ),
                        if (createdAt.isNotEmpty)
                          _Badge(
                            icon: Icons.schedule_outlined,
                            label: createdAt,
                          ),
                        if (overdue)
                          const _Badge(
                            icon: Icons.timer_off_outlined,
                            label: 'Quá hạn SLA',
                            color: Color(0xFFDC2626),
                          ),
                      ],
                    ),
                    if (_loadError != null) ...[
                      const SizedBox(height: 12),
                      _InfoBox(
                        icon: Icons.cloud_off_outlined,
                        text: 'Không tải đủ hồ sơ: $_loadError',
                        color: const Color(0xFFDC2626),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _Section(
                      icon: Icons.info_outline,
                      title: 'Thông tin sự cố',
                      child: Column(
                        children: [
                          _DetailRow(
                            label: 'Drone',
                            value: droneCode.isNotEmpty
                                ? droneCode
                                : '#${_report['droneUnitId'] ?? '—'}',
                          ),
                          _DetailRow(
                            label: 'Trạm/Kiosk',
                            value: _text(_report['lockerName']).isNotEmpty
                                ? _text(_report['lockerName'])
                                : '#${_report['lockerId'] ?? '—'}',
                          ),
                          _DetailRow(
                            label: 'Người báo',
                            value: reporterName.isEmpty
                                ? 'Người dùng #${_report['userId'] ?? '—'}'
                                : reporterName,
                          ),
                          _DetailRow(
                            label: 'KTV phụ trách',
                            value: assignedName.isNotEmpty
                                ? assignedName
                                : _report['assignedToUserId'] == null
                                ? 'Chưa có KTV nhận việc'
                                : 'KTV #${_report['assignedToUserId']}',
                          ),
                          _DetailRow(
                            label: 'Tạo lúc',
                            value: createdAt.isEmpty ? '—' : createdAt,
                            last: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Section(
                      icon: Icons.description_outlined,
                      title: 'Mô tả hiện trường',
                      child: Text(
                        description.isEmpty
                            ? 'Chưa có mô tả chi tiết.'
                            : description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _dark,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Section(
                      icon: Icons.photo_library_outlined,
                      title: 'Ảnh hồ sơ theo giai đoạn',
                      count: _attachments.length,
                      child: _loading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : AttachmentStageGallery(
                              attachments: _attachments,
                              showEmptyStages: true,
                              thumbSize: 60,
                              accentColor: _accent,
                            ),
                    ),
                    const SizedBox(height: 12),
                    _Section(
                      icon: Icons.history_edu_outlined,
                      title: 'Nhật ký & lịch sử xử lý của KTV',
                      count: _logs.length,
                      child: _buildLogs(),
                    ),
                    if (_status == 'IN_PROGRESS' && _assignedToMe) ...[
                      const SizedBox(height: 10),
                      _buildLogEditor(),
                    ],
                    const SizedBox(height: 18),
                    if (_canClaim)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _claim,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.assignment_turned_in_outlined),
                          label: const Text('Nhận xử lý'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _accent,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                        ),
                      ),
                    if (_status == 'IN_PROGRESS' && _assignedToMe)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _resolve,
                          icon: const Icon(Icons.verified_outlined),
                          label: const Text('Nghiệm thu & hoàn tất sự cố'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            padding: const EdgeInsets.symmetric(vertical: 13),
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
  }

  Widget _buildLogs() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_logs.isEmpty) {
      return const _InfoBox(
        icon: Icons.info_outline,
        text:
            'Chưa có ghi chú xử lý. Mỗi bước kiểm tra hoặc sửa chữa sẽ được lưu tại đây.',
      );
    }
    return Column(
      children: [
        for (final log in _logs) ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Builder(
              builder: (_) {
                final photos = ReportAttachment.listFrom(log['attachments']);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _Badge(
                          icon: Icons.engineering_outlined,
                          label: log['actorUserId'] == null
                              ? 'Kỹ thuật viên'
                              : 'KTV #${log['actorUserId']}',
                          color: _accent,
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(log['createdAt']),
                          style: const TextStyle(fontSize: 11, color: _muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${log['note'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: _dark,
                        height: 1.4,
                      ),
                    ),
                    if (photos.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      AttachmentStrip(
                        attachments: photos,
                        size: 58,
                        viewerTitle:
                            'Nhật ký Drone · ${_formatDate(log['createdAt'])}',
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLogEditor() {
    if (!_showLogEditor) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(() => _showLogEditor = true),
          icon: const Icon(Icons.add_comment_outlined),
          label: const Text('Thêm bước xử lý / ảnh tiến độ'),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withValues(alpha: .35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PhotoPickerField(
            controller: _logPhotos,
            enabled: !_saving,
            thumbSize: 58,
            accentColor: _accent,
            addLabel: 'Thêm ảnh',
            helperText: 'Ảnh kiểm tra hoặc tiến độ sửa chữa',
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            minLines: 2,
            maxLines: 4,
            enabled: !_saving,
            decoration: const InputDecoration(
              hintText: 'Nhập việc đã kiểm tra hoặc sửa chữa...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _saving
                    ? null
                    : () => setState(() => _showLogEditor = false),
                child: const Text('Hủy'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _saving ? null : _addLog,
                icon: const Icon(Icons.send, size: 17),
                label: const Text('Lưu nhật ký'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DroneResolveSheet extends StatefulWidget {
  const _DroneResolveSheet({
    required this.reportId,
    required this.service,
    required this.existingAttachments,
  });

  final int reportId;
  final LockerOpsService service;
  final List<ReportAttachment> existingAttachments;

  @override
  State<_DroneResolveSheet> createState() => _DroneResolveSheetState();
}

class _DroneResolveSheetState extends State<_DroneResolveSheet> {
  final _noteController = TextEditingController();
  late final PhotoPickerController _progressPhotos = PhotoPickerController(
    maxPhotos:
        BusinessConfigService.instance.current.reportPhotosPerRequestStaff,
  );
  late final PhotoPickerController _resolutionPhotos = PhotoPickerController(
    maxPhotos:
        BusinessConfigService.instance.current.reportPhotosPerRequestStaff,
  );
  bool _submitting = false;
  String? _error;

  bool get _hasResolution =>
      _resolutionPhotos.isNotEmpty ||
      widget.existingAttachments.any(
        (attachment) => attachment.stage == ReportStage.resolution,
      );

  @override
  void dispose() {
    _noteController.dispose();
    _progressPhotos.dispose();
    _resolutionPhotos.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_hasResolution) {
      setState(
        () => _error =
            'Vui lòng chụp ít nhất 1 ảnh sau khi sửa xong để nghiệm thu.',
      );
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final note = _noteController.text.trim();
      final progress = await _progressPhotos.uploadAll(caption: note);
      if (progress.isNotEmpty) {
        await widget.service.addDroneReportAttachments(
          widget.reportId,
          ReportStage.progress,
          progress,
          note: note,
        );
      }
      final resolution = await _resolutionPhotos.uploadAll(caption: note);
      final formattedNote = note.isEmpty
          ? '[NGHIỆM THU THÀNH CÔNG] Đã khắc phục và kiểm tra Drone hoạt động bình thường.'
          : note.startsWith('[')
          ? note
          : '[NGHIỆM THU THÀNH CÔNG] $note';
      await widget.service.resolveDroneReport(
        widget.reportId,
        note: formattedNote,
        attachments: resolution,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() => _error = LockerOpsService.errorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          10,
          18,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Nghiệm thu sự cố Drone',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Lưu ảnh tiến độ và ảnh sau khi khắc phục giống quy trình nghiệm thu sự cố tủ.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                minLines: 3,
                maxLines: 5,
                enabled: !_submitting,
                decoration: const InputDecoration(
                  labelText: 'Kết quả khắc phục',
                  hintText: 'Mô tả linh kiện hoặc thao tác đã xử lý...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              _PhotoStageBox(
                title: 'Ảnh trong quá trình sửa',
                subtitle: 'Không bắt buộc, dùng để ghi nhận thao tác kỹ thuật.',
                controller: _progressPhotos,
                enabled: !_submitting,
                color: const Color(0xFF2563EB),
              ),
              const SizedBox(height: 12),
              _PhotoStageBox(
                title: 'Ảnh sau khi sửa xong *',
                subtitle: 'Bắt buộc ít nhất 1 ảnh để nghiệm thu.',
                controller: _resolutionPhotos,
                enabled: !_submitting,
                color: const Color(0xFF16A34A),
                satisfied: _hasResolution,
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.pop(context, false),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.verified_outlined),
                      label: const Text('Xác nhận hoàn tất'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
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
}

class _PhotoStageBox extends StatelessWidget {
  const _PhotoStageBox({
    required this.title,
    required this.subtitle,
    required this.controller,
    required this.enabled,
    required this.color,
    this.satisfied = false,
  });

  final String title;
  final String subtitle;
  final PhotoPickerController controller;
  final bool enabled;
  final Color color;
  final bool satisfied;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: satisfied ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
          width: satisfied ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 8),
          PhotoPickerField(
            controller: controller,
            enabled: enabled,
            thumbSize: 62,
            accentColor: color,
            addLabel: 'Thêm ảnh',
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
    this.count,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: const Color(0xFF0284C7)),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              if (count != null)
                _Badge(
                  icon: Icons.numbers,
                  label: '$count',
                  color: const Color(0xFF0284C7),
                ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.last = false,
  });

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? const Color(0xFF64748B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: effectiveColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: effectiveColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? const Color(0xFF64748B);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: effectiveColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: effectiveColor),
            ),
          ),
        ],
      ),
    );
  }
}

List<ReportAttachment> _mergeAttachments(
  Map<String, dynamic> report,
  List<Map<String, dynamic>> serverAttachments,
) {
  final result = <ReportAttachment>[
    ...ReportAttachment.listFrom(report['attachments']),
    ...ReportAttachment.listFrom(serverAttachments),
  ];
  final createdAt = parseServerDateTime(report['createdAt']);
  for (final url in _legacyPhotoUrls(report)) {
    result.add(
      ReportAttachment(
        stage: ReportStage.report,
        url: url,
        createdAt: createdAt,
      ),
    );
  }
  return {
    for (final attachment in result) attachment.url: attachment,
  }.values.toList(growable: false);
}

List<String> _legacyPhotoUrls(Map<String, dynamic> report) {
  final urls = <String>{};
  final raw = report['photoUrls'] ?? report['photos'];
  if (raw is List) {
    for (final value in raw) {
      final url = '${value ?? ''}'.trim();
      if (url.startsWith('http')) urls.add(url);
    }
  }
  final description = '${report['description'] ?? ''}';
  for (final match in RegExp(r'https?://[^\s)\]"]+').allMatches(description)) {
    urls.add(match.group(0)!.replaceAll(RegExp(r'[,.;:]$'), ''));
  }
  return urls.toList(growable: false);
}

String _cleanDescription(dynamic value) {
  final raw = '${value ?? ''}';
  return raw
      .replaceAll(RegExp(r'https?://[^\s)\]"]+'), '')
      .replaceAll(RegExp(r'\n*Ảnh minh chứng.*$', caseSensitive: false), '')
      .trim();
}

String _formatDate(dynamic value) {
  final date = parseServerDateTime(value);
  if (date == null) return '';
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(date.hour)}:${two(date.minute)} ${two(date.day)}/${two(date.month)}/${date.year}';
}

String _text(dynamic value) => '${value ?? ''}'.trim();

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('${value ?? ''}');
}
