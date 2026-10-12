import 'package:flutter/material.dart';

import 'package:smart_laundry_locker/features/locker_ops/presentation/pages/my_reports_page.dart';

/// "Báo cáo của tôi" — mọi lối vào (`/maintenance/my-reports` từ trang chủ, hồ
/// sơ và `/locker/my-reports` từ đơn/thông báo) dùng CHUNG một màn
/// [MyReportsPage]: danh sách phiếu từ `GET /api/lockers/my-reports`, mở chi tiết
/// bằng token của chính khách, và nút báo sự cố mới.
class ReportListPage extends StatelessWidget {
  const ReportListPage({super.key, this.initialReportId});

  /// Deep link `?reportId=`: mở chi tiết phiếu này sau khi tải.
  final int? initialReportId;

  @override
  Widget build(BuildContext context) =>
      MyReportsPage(initialReportId: initialReportId);
}
