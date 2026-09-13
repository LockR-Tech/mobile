import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

/// Read-only view of the customer's own locker fault reports
/// (`GET /api/lockers/my-reports`), so they can see claim/resolve progress
/// without having to ask maintenance directly.
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
                      itemBuilder: (ctx, i) => _ReportCard(report: _reports[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatefulWidget {
  const _ReportCard({required this.report});
  final Map<String, dynamic> report;

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

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final status = report['status'] as String?;
    final description = report['description'] as String?;
    final lockerLabel =
        report['lockerName'] ?? report['lockerCode'] ?? report['lockerId'];

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
