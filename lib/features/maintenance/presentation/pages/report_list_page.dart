import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/maintenance/domain/entities/maintenance_report.dart';
import 'package:smart_laundry_locker/features/maintenance/presentation/pages/create_report_page.dart';
import 'package:smart_laundry_locker/features/maintenance/presentation/providers/maintenance_injection.dart';
import 'package:smart_laundry_locker/features/maintenance/presentation/providers/maintenance_provider.dart';
import 'package:smart_laundry_locker/features/maintenance/presentation/widgets/report_skeleton_loading.dart';
import 'package:smart_laundry_locker/shared/widgets/app_bar.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

class ReportListPage extends StatefulWidget {
  const ReportListPage({Key? key}) : super(key: key);

  @override
  State<ReportListPage> createState() => _ReportListPageState();
}

class _ReportListPageState extends State<ReportListPage> {
  late MaintenanceProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = MaintenanceInjection.provideMaintenanceProvider(ApiClient());
    _provider.fetchMyReports();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      DateFormat('dd/MM/yyyy HH:mm').format(d.toLocal());

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
        appBar: const CustomAppBar(
          title: 'Báo cáo của tôi',
          centerTitle: true,
          showBackButton: true,
        ),
        body: Consumer<MaintenanceProvider>(
          builder: (context, provider, child) {
            final reports = provider.myReports;

            if (provider.isLoading && reports.isEmpty) {
              return const MaintenanceReportSkeleton();
            }

            if (provider.error != null && reports.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        LucideIcons.cloudOff,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Không thể tải dữ liệu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vui lòng kiểm tra kết nối mạng và thử lại.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: 150,
                        child: ElevatedButton(
                          onPressed: () => provider.fetchMyReports(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AISLShadcnTheme.navyPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Thử lại'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (reports.isEmpty) {
              return RefreshIndicator(
                onRefresh: () => provider.fetchMyReports(),
                backgroundColor: Colors.white,
                color: AISLShadcnTheme.navyPrimary,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 28,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            LucideIcons.clipboardX,
                            size: 56,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Chưa có báo cáo nào',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Nhấn "Báo cáo sự cố" để gửi sự cố cho hệ thống.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => provider.fetchMyReports(),
              backgroundColor: Colors.white,
              color: AISLShadcnTheme.navyPrimary,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: reports.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final report = reports[index];
                  return _buildReportItem(report);
                },
              ),
            );
          },
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () async {
                await Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        const CreateReportPage(lockerId: '', cabinetId: ''),
                  ),
                );
                if (mounted) {
                  await _provider.fetchMyReports();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AISLShadcnTheme.navyPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Báo cáo sự cố',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportItem(MaintenanceReport report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  report.code,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey.shade900,
                  ),
                ),
                _buildStatusBadge(report.status),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              report.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              report.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  LucideIcons.calendar,
                  size: 14,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
                Text(
                  _fmtDate(report.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const Spacer(),
                if (report.photoUrls.isNotEmpty) ...[
                  Icon(
                    LucideIcons.image,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${report.photoUrls.length} ảnh',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ],
            ),
            if (report.staffNote != null && report.staffNote!.isNotEmpty) ...[
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F0F8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      LucideIcons.messageSquare,
                      size: 14,
                      color: const Color(0xFF0A2342),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Phản hồi: ${report.staffNote}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF0A2342),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status.toUpperCase()) {
      case 'PENDING':
        color = const Color(0xFF0A2342);
        text = 'Chờ xử lý';
        break;
      case 'ASSIGNED':
        color = Colors.indigo;
        text = 'Đã phân công';
        break;
      case 'IN_PROGRESS':
        color = Colors.blue;
        text = 'Đang xử lý';
        break;
      case 'RESOLVED':
        color = Colors.green;
        text = 'Đã giải quyết';
        break;
      case 'CLOSED':
        color = Colors.grey.shade700;
        text = 'Đã đóng';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
