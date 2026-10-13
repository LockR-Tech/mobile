import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:smart_laundry_locker/core/media/media.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/user_report_detail_sheet.dart';
import 'package:smart_laundry_locker/features/maintenance/presentation/pages/create_report_page.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

/// View of the customer's own locker fault reports
/// (`GET /api/lockers/my-reports`), so they can see claim/resolve progress
/// without having to ask maintenance directly. Shows the report photos by
/// stage and lets the owner add more REPORT photos while not RESOLVED.
class MyReportsPage extends StatefulWidget {
  const MyReportsPage({super.key, this.initialReportId});

  /// Deep link `/locker/my-reports?reportId=<id>`: mở chi tiết phiếu sau khi tải.
  final int? initialReportId;

  @override
  State<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> {
  final _service = LockerOpsService();
  List<Map<String, dynamic>> _reports = [];
  bool _loading = true;
  bool _openedInitial = false;

  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _openInitialReportOnce() {
    final id = widget.initialReportId;
    if (id == null || _openedInitial || !mounted) return;
    _openedInitial = true;
    final report = _reports
        .where((r) => '${r['id']}' == '$id')
        .firstOrNull;
    // Phiếu chưa có trong danh sách (vừa tạo / danh sách lỗi) vẫn mở được: sheet
    // tự tải chi tiết bằng id.
    UserReportDetailSheet.show(
      context,
      report: report ?? {'id': id},
      onChanged: _load,
    );
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
    _openInitialReportOnce();
  }

  Widget _buildTabButton({
    required int index,
    required String title,
    required IconData icon,
    int? count,
  }) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReportsList() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AislBrand.navy),
      );
    }
    if (_reports.isEmpty) {
      return RefreshIndicator(
        color: AislBrand.navy,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          children: [
            const OpsEmptyState(
              icon: LucideIcons.clipboardCheck,
              title: 'Chưa có báo cáo nào',
              subtitle:
                  'Báo lỗi từ chi tiết đơn hoặc tab "Báo sự cố mới" sẽ hiện ở đây.',
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _selectedTab = 1),
                icon: const Icon(LucideIcons.plusCircle, size: 16),
                label: const Text('Báo sự cố ngay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: AislBrand.navy,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: _reports.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) => _ReportCard(report: _reports[i], onChanged: _load),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          BrandHeroHeader(
            eyebrow: 'LOCK.R • BÁO CÁO',
            title: 'Báo cáo của tôi',
            subtitle: 'Theo dõi tiến độ xử lý và gửi báo cáo sự cố ô tủ',
            onBack: () => Navigator.of(context).maybePop(),
            trailing: BrandCircleIconButton(
              icon: LucideIcons.refreshCw,
              iconSize: 18,
              onTap: _load,
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    index: 0,
                    title: 'Báo cáo của tôi',
                    count: _reports.length,
                    icon: LucideIcons.history,
                  ),
                ),
                Expanded(
                  child: _buildTabButton(
                    index: 1,
                    title: 'Báo sự cố mới',
                    icon: LucideIcons.plusCircle,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedTab == 0
                ? _buildReportsList()
                : CreateReportPage(
                    lockerId: '',
                    cabinetId: '',
                    isEmbedded: true,
                    onSuccess: () {
                      _load();
                      setState(() => _selectedTab = 0);
                    },
                    onCancel: () {
                      setState(() => _selectedTab = 0);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.onChanged});
  final Map<String, dynamic> report;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    final status = (report['status'] as String? ?? 'OPEN').toUpperCase();
    final isResolved = status == 'RESOLVED' || status == 'CLOSED';
    final isInProgress = status == 'IN_PROGRESS';

    final statusText = isResolved
        ? 'Đã xong'
        : (isInProgress ? 'Đang xử lý' : 'Chờ tiếp nhận');
    final statusColor = isResolved
        ? const Color(0xFF15803D)
        : (isInProgress ? const Color(0xFFD97706) : const Color(0xFF0284C7));
    final statusBg = isResolved
        ? const Color(0xFFDCFCE7)
        : (isInProgress ? const Color(0xFFFEF3C7) : const Color(0xFFE0F2FE));

    final title = report['title']?.toString().trim();
    final description = report['description']?.toString().trim();
    final lockerLabel =
        report['lockerName'] ?? report['lockerCode'] ?? report['lockerId'];
    final attachments = ReportAttachment.listFrom(report['attachments']);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => UserReportDetailSheet.show(
          context,
          report: report,
          onChanged: onChanged,
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Mã phiếu & Trạng thái
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isResolved
                              ? LucideIcons.circleCheck
                              : (isInProgress ? LucideIcons.wrench : LucideIcons.alertTriangle),
                          size: 14,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Phiếu sự cố #${report['id'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Tiêu đề sự cố & Mô tả ngắn
              if (title != null && title.isNotEmpty) ...[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
              ] else if (description != null && description.isNotEmpty) ...[
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],

              // Điểm tủ
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(LucideIcons.warehouse, size: 13, color: Color(0xFF64748B)),
                      SizedBox(width: 6),
                      Text(
                        'Điểm tủ',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  Flexible(
                    child: Text(
                      '${lockerLabel ?? '-'}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),

              // Ô tủ (nếu có)
              if (report['boxNumber'] != null) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(LucideIcons.grid3x3, size: 13, color: Color(0xFF64748B)),
                        SizedBox(width: 6),
                        Text(
                          'Ô tủ',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    Text(
                      'Ô số ${report['boxNumber']}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ],

              // Thời gian gửi
              if (report['createdAt'] != null) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(LucideIcons.clock, size: 13, color: Color(0xFF64748B)),
                        SizedBox(width: 6),
                        Text(
                          'Thời gian gửi',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    Text(
                      fmtDateTime(report['createdAt']),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 8),

              // Footer: Badges đính kèm + Xem chi tiết >
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Wrap(
                    spacing: 6,
                    children: [
                      if (attachments.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.image, size: 11, color: Color(0xFF0284C7)),
                              SizedBox(width: 3.5),
                              Text(
                                '${attachments.length} ảnh',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (isResolved)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.circleCheck, size: 11, color: Color(0xFF15803D)),
                              SizedBox(width: 3.5),
                              Text(
                                'Đã hoàn tất',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Xem chi tiết',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(LucideIcons.chevronRight, size: 13, color: Color(0xFF0284C7)),
                    ],
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
