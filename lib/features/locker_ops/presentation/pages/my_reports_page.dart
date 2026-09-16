import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:smart_laundry_locker/core/config/business_config_service.dart';
import 'package:smart_laundry_locker/core/media/media.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

/// Tối đa ảnh REPORT trên 1 phiếu (hợp đồng media-storage). Backend không công
/// khai quy tắc này qua `/api/settings/locker/public` nên app giữ mặc định;
/// server vẫn chặn nếu admin đổi.
const _maxReportPhotosPerReport = 10;

/// Tối đa ảnh mỗi lần bổ sung — admin cấu hình
/// (`app.maintenance.report-photos-per-request-reporter`).
int get _maxReportPhotosPerRequest =>
    BusinessConfigService.instance.current.reportPhotosPerRequestReporter;

/// View of the customer's own locker fault reports
/// (`GET /api/lockers/my-reports`), so they can see claim/resolve progress
/// without having to ask maintenance directly. Shows the report photos by
/// stage and lets the owner add more REPORT photos while not RESOLVED.
class MyReportsPage extends StatefulWidget {
  const MyReportsPage({super.key});

  @override
  State<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> {
  final _service = LockerOpsService();
  List<Map<String, dynamic>> _reports = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final reports = await _service.myReports();
      if (!mounted) return;
      setState(() => _reports = reports);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(LockerOpsService.errorMessage(e))),
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F5),
      body: Column(
        children: [
          BrandHeroHeader(
            title: 'Báo cáo của tôi',
            subtitle: 'Theo dõi các báo lỗi ô tủ bạn đã gửi',
            onBack: () => Navigator.of(context).maybePop(),
            trailing: BrandCircleIconButton(
              icon: LucideIcons.refreshCw,
              onTap: _load,
              iconSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AislBrand.navy),
                  )
                : _reports.isEmpty
                ? const OpsEmptyState(
                    icon: LucideIcons.clipboardCheck,
                    title: 'Chưa có báo cáo nào',
                    subtitle: 'Báo lỗi ô tủ từ chi tiết đơn sẽ hiện ở đây.',
                  )
                : RefreshIndicator(
                    color: AislBrand.navy,
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: _reports.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) =>
                          _ReportCard(report: _reports[i], onChanged: _load),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatefulWidget {
  const _ReportCard({required this.report, required this.onChanged});
  final Map<String, dynamic> report;
  final Future<void> Function() onChanged;

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  final _service = LockerOpsService();
  Map<String, dynamic>? _rating;
  bool _loadingRating = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.report['status'] == 'RESOLVED') {
      _loadRating();
    }
  }

  Future<void> _loadRating() async {
    setState(() => _loadingRating = true);
    try {
      final rating = await _service.getReportRating(widget.report['id'] as int);
      if (mounted) setState(() => _rating = rating);
    } finally {
      if (mounted) setState(() => _loadingRating = false);
    }
  }

  Future<void> _submitRating(int stars) async {
    setState(() => _submitting = true);
    try {
      final result = await _service.rateReport(widget.report['id'] as int, stars, null);
      if (mounted) setState(() => _rating = result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LockerOpsService.errorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _addPhotos(int reportId, int existingReportPhotos) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => _AddReportPhotosSheet(
        reportId: reportId,
        service: _service,
        maxPhotos: math.min(
          _maxReportPhotosPerRequest,
          _maxReportPhotosPerReport - existingReportPhotos,
        ),
      ),
    );
    if (added == true && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Đã bổ sung ảnh cho báo cáo')),
        );
      await widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final status = report['status'] as String?;
    final description = report['description'] as String?;
    final lockerLabel =
        report['lockerName'] ?? report['lockerCode'] ?? report['lockerId'];
    final reportId = report['id'] is int ? report['id'] as int : null;
    final attachments = ReportAttachment.listFrom(report['attachments']);
    final reportPhotoCount = attachments
        .where((a) => a.stage == ReportStage.report)
        .length;
    final canAddPhotos =
        reportId != null &&
        status != 'RESOLVED' &&
        reportPhotoCount < _maxReportPhotosPerReport;

    return OpsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  report['title']?.toString() ?? 'Báo cáo ô tủ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: opsDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(status),
            ],
          ),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(fontSize: 13, color: opsMutedText),
            ),
          ],
          const SizedBox(height: 12),
          OpsInfoRow(
            icon: LucideIcons.warehouse,
            label: 'Tủ',
            value: '${lockerLabel ?? '-'}',
          ),
          if (report['boxNumber'] != null)
            OpsInfoRow(
              icon: LucideIcons.grid3x3,
              label: 'Ô',
              value: '${report['boxNumber']}',
            ),
          OpsInfoRow(
            icon: LucideIcons.calendar,
            label: 'Gửi lúc',
            value: fmtDateTime(report['createdAt']),
          ),
          if (attachments.isNotEmpty)
            AttachmentStageGallery(
              attachments: attachments,
              stages: const [
                ReportStage.report,
                ReportStage.inspection,
                ReportStage.resolution,
              ],
              labels: const {
                ReportStage.report: 'Ảnh bạn gửi',
                ReportStage.inspection: 'Ảnh kỹ thuật viên kiểm tra',
                ReportStage.resolution: 'Ảnh nghiệm thu',
              },
              accentColor: AislBrand.navy,
            ),
          if (canAddPhotos)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _addPhotos(reportId, reportPhotoCount),
                icon: const Icon(LucideIcons.imagePlus, size: 16),
                label: Text(
                  reportPhotoCount == 0 ? 'Thêm ảnh sự cố' : 'Bổ sung ảnh',
                ),
                style: TextButton.styleFrom(foregroundColor: AislBrand.navy),
              ),
            ),
          if (status == 'IN_PROGRESS')
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: OpsBanner(
                tone: OpsBannerTone.info,
                icon: LucideIcons.userCheck,
                text: 'Đội bảo trì đang xử lý báo cáo này.',
              ),
            )
          else if (status == 'RESOLVED') ...[
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: OpsBanner(
                tone: OpsBannerTone.success,
                icon: LucideIcons.circleCheck,
                text: 'Báo cáo đã được xử lý xong.',
              ),
            ),
            const SizedBox(height: 10),
            if (_loadingRating)
              const SizedBox(
                height: 20,
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (_rating != null)
              Row(
                children: [
                  ...List.generate(
                    5,
                    (i) => Icon(
                      i < (_rating!['rating'] as int)
                          ? LucideIcons.star
                          : LucideIcons.star,
                      size: 16,
                      color: i < (_rating!['rating'] as int)
                          ? const Color(0xFFF59E0B)
                          : opsBorder,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Bạn đã đánh giá',
                    style: TextStyle(fontSize: 12, color: opsMutedText),
                  ),
                ],
              )
            else
              Row(
                children: [
                  const Text(
                    'Đánh giá xử lý: ',
                    style: TextStyle(fontSize: 12, color: opsMutedText),
                  ),
                  ...List.generate(
                    5,
                    (i) => IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      icon: const Icon(LucideIcons.star, size: 18, color: Color(0xFFF59E0B)),
                      onPressed: _submitting ? null : () => _submitRating(i + 1),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

/// Sheet chọn ảnh → upload Cloudinary → `POST /api/lockers/reports/{id}/attachments`.
class _AddReportPhotosSheet extends StatefulWidget {
  const _AddReportPhotosSheet({
    required this.reportId,
    required this.service,
    required this.maxPhotos,
  });

  final int reportId;
  final LockerOpsService service;
  final int maxPhotos;

  @override
  State<_AddReportPhotosSheet> createState() => _AddReportPhotosSheetState();
}

class _AddReportPhotosSheetState extends State<_AddReportPhotosSheet> {
  late final PhotoPickerController _photos = PhotoPickerController(
    maxPhotos: widget.maxPhotos,
  );
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _photos.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_photos.isEmpty) {
      setState(() => _error = 'Vui lòng chọn ít nhất 1 ảnh.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final attachments = await _photos.uploadAll();
      await widget.service.addMyReportAttachments(widget.reportId, attachments);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _error = LockerOpsService.errorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bổ sung ảnh sự cố',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: opsDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tối đa ${widget.maxPhotos} ảnh mỗi lần. Ảnh giúp đội bảo trì '
                'chuẩn bị đúng linh kiện trước khi tới.',
                style: const TextStyle(fontSize: 12.5, color: opsMutedText),
              ),
              const SizedBox(height: 14),
              PhotoPickerField(
                controller: _photos,
                enabled: !_submitting,
                thumbSize: 80,
                accentColor: AislBrand.navy,
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                OpsBanner(
                  tone: OpsBannerTone.danger,
                  icon: LucideIcons.circleAlert,
                  text: _error!,
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AislBrand.navy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
                      : const Icon(LucideIcons.upload, size: 18),
                  label: Text(_submitting ? 'Đang tải ảnh...' : 'Gửi ảnh'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
