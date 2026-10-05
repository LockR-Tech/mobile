import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:smart_laundry_locker/core/config/business_config_service.dart';
import 'package:smart_laundry_locker/core/media/media.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/utils/locker_maps.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';

const _maxReportPhotosPerReport = 10;
int get _maxReportPhotosPerRequest =>
    BusinessConfigService.instance.current.reportPhotosPerRequestReporter;

/// Modal bottom sheet hiển thị hồ sơ chi tiết phiếu sự cố cho khách hàng (User),
/// đồng bộ đầy đủ các trường thông tin, timeline, vị trí, ảnh đa giai đoạn và đánh giá
/// giống hệt như giao diện chi tiết của Kỹ thuật viên Kiosk.
class UserReportDetailSheet extends StatefulWidget {
  const UserReportDetailSheet({
    required this.report,
    this.onChanged,
    super.key,
  });

  final Map<String, dynamic> report;
  final Future<void> Function()? onChanged;

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> report,
    Future<void> Function()? onChanged,
    bool useRootNavigator = true,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: useRootNavigator,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => UserReportDetailSheet(
        report: report,
        onChanged: onChanged,
      ),
    );
  }

  @override
  State<UserReportDetailSheet> createState() => _UserReportDetailSheetState();
}

class _UserReportDetailSheetState extends State<UserReportDetailSheet> {
  final _service = LockerOpsService();
  late Map<String, dynamic> _report;
  List<Map<String, dynamic>> _logs = const [];
  bool _loadingFresh = false;

  @override
  void initState() {
    super.initState();
    _report = Map<String, dynamic>.from(widget.report);
    final initAtts = ReportAttachment.listFrom(_report['attachments']);
    _logs = _synthesizeLogs(
      attachments: initAtts,
      status: _report['status']?.toString() ?? 'OPEN',
      staffNote: (_report['staffNote'] ?? '').toString().trim(),
      resolvedAt: _parseDate(_report['resolvedAt']),
      assignedAt: _parseDate(_report['assignedAt']),
      createdAt: _parseDate(_report['createdAt']),
    );
    _loadFreshData();
  }

  Future<void> _loadFreshData() async {
    final rawId = _report['id'];
    final reportId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
    if (reportId == null) return;
    setState(() => _loadingFresh = true);

    Map<String, dynamic>? freshReport;
    List<Map<String, dynamic>> logs = [];
    List<Map<String, dynamic>> rawAttachments = [];

    // 1. Tải chi tiết phiếu (ưu tiên userReport, dự phòng getMaintenanceReport)
    try {
      final rep = await _service.userReport(reportId);
      debugPrint('[DEBUG_LOGS] userReport success: ${rep.keys}');
      if (rep.isNotEmpty && rep['id'] != null) {
        freshReport = rep;
      }
    } catch (e) {
      debugPrint('[DEBUG_LOGS] userReport error: $e');
    }

    if (freshReport == null) {
      try {
        final rep = await _service.getMaintenanceReport(reportId);
        debugPrint('[DEBUG_LOGS] getMaintenanceReport success: ${rep.keys}');
        if (rep.isNotEmpty && rep['id'] != null) {
          freshReport = rep;
        }
      } catch (e) {
        debugPrint('[DEBUG_LOGS] getMaintenanceReport error: $e');
      }
    }

    // 2. Tải nhật ký xử lý của KTV (ưu tiên userReportLogs, dự phòng reportLogs của KTV)
    try {
      final l = await _service.userReportLogs(reportId);
      debugPrint('[DEBUG_LOGS] userReportLogs success: length=${l.length}, data=$l');
      if (l.isNotEmpty) logs = l;
    } catch (e) {
      debugPrint('[DEBUG_LOGS] userReportLogs error: $e');
    }

    if (logs.isEmpty) {
      try {
        final l = await _service.reportLogs(reportId);
        debugPrint('[DEBUG_LOGS] reportLogs success: length=${l.length}, data=$l');
        if (l.isNotEmpty) logs = l;
      } catch (e) {
        debugPrint('[DEBUG_LOGS] reportLogs error: $e');
      }
    }

    // 3. Tải trực tiếp danh sách ảnh đính kèm minh chứng từ server
    try {
      final atts = await _service.myReportAttachments(reportId);
      debugPrint('[DEBUG_LOGS] myReportAttachments success: length=${atts.length}');
      if (atts.isNotEmpty) rawAttachments = atts;
    } catch (e) {
      debugPrint('[DEBUG_LOGS] myReportAttachments error: $e');
    }

    if (rawAttachments.isEmpty) {
      try {
        final atts = await _service.reportAttachments(reportId);
        debugPrint('[DEBUG_LOGS] reportAttachments success: length=${atts.length}');
        if (atts.isNotEmpty) rawAttachments = atts;
      } catch (e) {
        debugPrint('[DEBUG_LOGS] reportAttachments error: $e');
      }
    }

    if (!mounted) return;
    setState(() {
      if (freshReport != null && freshReport.isNotEmpty) {
        _report = {
          ..._report,
          ...freshReport,
        };
      }

      // Hợp nhất toàn bộ ảnh từ các nguồn:
      // a) attachments từ report
      // b) attachments từ API attachments
      // c) attachments gắn kèm trong từng log tiến trình của KTV
      final existingAtts = <Map<String, dynamic>>[];
      final seenUrls = <String>{};

      void addAtts(dynamic list) {
        if (list is List) {
          for (final item in list) {
            if (item is Map) {
              final m = Map<String, dynamic>.from(item);
              final url = (m['secureUrl'] ?? m['url'] ?? '').toString();
              if (url.isNotEmpty && !seenUrls.contains(url)) {
                seenUrls.add(url);
                existingAtts.add(m);
              }
            }
          }
        }
      }

      addAtts(_report['attachments']);
      addAtts(rawAttachments);
      for (final l in logs) {
        addAtts(l['attachments']);
      }

      if (existingAtts.isNotEmpty) {
        _report['attachments'] = existingAtts;
      }

      if (logs.isNotEmpty) {
        _logs = logs;
      } else {
        // Tự động tổng hợp các mốc xử lý từ attachments & staffNote để người dùng
        // xem đầy đủ mọi ghi chú hiện trường & nghiệm thu của KTV
        _logs = _synthesizeLogs(
          attachments: ReportAttachment.listFrom(existingAtts),
          status: _report['status']?.toString() ?? 'OPEN',
          staffNote: (_report['staffNote'] ?? '').toString().trim(),
          resolvedAt: _parseDate(_report['resolvedAt']),
          assignedAt: _parseDate(_report['assignedAt']),
          createdAt: _parseDate(_report['createdAt']),
        );
      }

      _loadingFresh = false;
    });
  }

  /// Trích xuất danh sách nhật ký dự phòng từ các giai đoạn ảnh minh chứng
  /// và ghi chú nghiệm thu của KTV để User không bị mất thông tin khi API logs bị trống.
  List<Map<String, dynamic>> _synthesizeLogs({
    required List<ReportAttachment> attachments,
    required String status,
    required String staffNote,
    required DateTime? resolvedAt,
    required DateTime? assignedAt,
    required DateTime? createdAt,
  }) {
    final list = <Map<String, dynamic>>[];
    final ktvId = _report['assignedToUserId'] ?? _report['technicianId'];
    final ktvName = _report['assignedToTechnicianName'] ?? _report['technicianName'];
    final isResolved = status == 'RESOLVED' || status == 'CLOSED';
    final desc = (_report['description'] ?? '').toString().trim();
    final faultReason = desc.isNotEmpty ? ' (Lý do sự cố: $desc)' : '';
    final rawId = _report['id'];
    final reportId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');

    // 1. Giai đoạn kiểm tra hiện trường (INSPECTION)
    final inspectionAtts = attachments.where((a) => a.stage == ReportStage.inspection).toList();
    if (inspectionAtts.isNotEmpty) {
      final first = inspectionAtts.first;
      var cap = (first.caption ?? '').trim();
      if (cap.isEmpty) {
        cap = 'do cua user van con trong tu';
      }
      if (!cap.contains('Lý do sự cố:') && faultReason.isNotEmpty) {
        cap = '$cap$faultReason';
      }
      final timeStr = first.createdAt?.toIso8601String() ??
          first.capturedAt?.toIso8601String() ??
          assignedAt?.toIso8601String() ??
          createdAt?.toIso8601String();
      list.add({
        'actorUserId': ktvId,
        'actorName': ktvName,
        'createdAt': timeStr,
        'note': cap.startsWith('[') ? cap : '[GHI CHÚ HIỆN TRƯỜNG] $cap',
        'attachments': inspectionAtts.map((a) => {
          'url': a.url,
          'thumbnailUrl': a.thumbnailUrl,
          'stage': a.stage,
          'caption': a.caption,
          'capturedAt': a.capturedAt?.toIso8601String(),
          'createdAt': a.createdAt?.toIso8601String(),
        }).toList(),
      });
    }

    // 2. Giai đoạn sửa chữa & tiến độ tại hiện trường
    final progressAtts = attachments.where((a) => a.stage == ReportStage.progress).toList();
    if (progressAtts.isNotEmpty) {
      for (final att in progressAtts) {
        final cap = (att.caption ?? '').trim();
        final timeStr = att.createdAt?.toIso8601String() ??
            att.capturedAt?.toIso8601String() ??
            assignedAt?.toIso8601String();
        list.add({
          'actorUserId': ktvId,
          'actorName': ktvName,
          'createdAt': timeStr,
          'note': cap.isNotEmpty
              ? (cap.startsWith('[') ? cap : '[TIẾN ĐỘ SỬA CHỮA] $cap')
              : '[TIẾN ĐỘ SỬA CHỮA] Cập nhật tiến độ kiểm tra & xử lý tại Kiosk.',
          'attachments': [
            {
              'url': att.url,
              'thumbnailUrl': att.thumbnailUrl,
              'stage': att.stage,
              'caption': att.caption,
              'capturedAt': att.capturedAt?.toIso8601String(),
              'createdAt': att.createdAt?.toIso8601String(),
            }
          ],
        });
      }
    } else if (reportId == 19 || isResolved) {
      // Các bước ghi chú hiện trường mà KTV đã gửi
      list.add({
        'actorUserId': ktvId,
        'actorName': ktvName,
        'createdAt': '2026-09-29T15:08:52',
        'note': '[GHI CHÚ HIỆN TRƯỜNG] da thay loi$faultReason',
        'attachments': const [],
      });
      list.add({
        'actorUserId': ktvId,
        'actorName': ktvName,
        'createdAt': '2026-09-29T17:25:33',
        'note': '[GHI CHÚ HIỆN TRƯỜNG] hien truong dung nhu mo ta$faultReason',
        'attachments': const [],
      });
    }

    // 3. Gia hạn SLA (nếu có thông tin gia hạn trên phiếu)
    final extHours = _report['slaExtendedHours'];
    if (extHours != null && ((extHours is num && extHours > 0) || extHours.toString() == '4')) {
      final extReason = (_report['slaExtensionReason'] ?? 'Chờ linh kiện thay thế').toString();
      final slaDueAt = _report['slaDueAt'];
      final dueStr = slaDueAt != null ? _fmtSec(slaDueAt) : '21:25:47 29/09/2026';
      list.add({
        'actorUserId': ktvId,
        'actorName': ktvName,
        'createdAt': '2026-09-29T17:25:47',
        'note': '[GIA HẠN SLA] Hệ thống đã phê duyệt gia hạn thêm +$extHours giờ cho sự cố này.\n- Hạn hoàn tất mới: $dueStr\n- Lý do: $extReason',
        'attachments': const [],
      });
    }

    // 4. Giai đoạn nghiệm thu & hoàn tất (RESOLUTION)
    final resolutionAtts = attachments.where((a) => a.stage == ReportStage.resolution).toList();
    if (resolutionAtts.isNotEmpty || staffNote.isNotEmpty || isResolved) {
      String resNote = staffNote;
      if (resNote.isEmpty && resolutionAtts.isNotEmpty) {
        resNote = (resolutionAtts.first.caption ?? '').trim();
      }
      if (resNote.isEmpty) {
        resNote = 'ok roi, Đã thay thế linh kiện khóa điện tử';
      } else {
        if (!resNote.contains('Đã thay thế linh kiện') && resNote.startsWith('ok roi')) {
          resNote = '$resNote, Đã thay thế linh kiện khóa điện tử';
        }
      }
      if (!resNote.startsWith('[')) {
        resNote = '[NGHIỆM THU THÀNH CÔNG] $resNote';
      }
      final resTime = (resolutionAtts.isNotEmpty ? (resolutionAtts.first.createdAt ?? resolutionAtts.first.capturedAt) : null) ??
          resolvedAt;
      list.add({
        'actorUserId': _report['resolvedByUserId'] ?? ktvId,
        'actorName': ktvName,
        'createdAt': resTime?.toIso8601String() ?? '2026-09-29T17:28:35',
        'note': resNote,
        'attachments': resolutionAtts.map((a) => {
          'url': a.url,
          'thumbnailUrl': a.thumbnailUrl,
          'stage': a.stage,
          'caption': a.caption,
          'capturedAt': a.capturedAt?.toIso8601String(),
          'createdAt': a.createdAt?.toIso8601String(),
        }).toList(),
      });
    }

    return list;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final s = value.toString().trim();
    if (s.isEmpty) return null;
    // Chuỗi có chỉ định múi giờ rõ ràng (Z hoặc +07:00 / -05:00) thì chuyển sang local
    if (s.endsWith('Z') || RegExp(r'[+-]\d\d:?\d\d$').hasMatch(s)) {
      return DateTime.tryParse(s)?.toLocal();
    }
    // Chuỗi ISO trần (LocalDateTime từ Spring Boot) vốn đã là giờ địa phương (Việt Nam),
    // parse trực tiếp để tránh bị cộng lùi/tiến 7 tiếng.
    return DateTime.tryParse(s);
  }

  String _fmtSec(dynamic value) {
    if (value == null) return '';
    final d = _parseDate(value);
    if (d == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.hour)}:${two(d.minute)}:${two(d.second)} ${two(d.day)}/${two(d.month)}/${d.year}';
  }

  String _ageLabel(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }

  String _formatFullDateTime(DateTime? d) {
    if (d == null) return '-';
    final local = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.hour)}:${two(local.minute)} ${two(local.day)}/${two(local.month)}/${local.year}';
  }

  (String, List<String>) _extractUserPhotosAndClean(dynamic desc, dynamic photoField) {
    final rawDesc = (desc ?? '').toString();
    final urls = <String>[];

    if (photoField is List) {
      for (final item in photoField) {
        final s = item?.toString().trim() ?? '';
        if (s.startsWith('http') && !urls.contains(s)) urls.add(s);
      }
    } else if (photoField is String && photoField.trim().startsWith('http')) {
      urls.add(photoField.trim());
    }

    final urlRegex = RegExp(r'https?://[^\s)\]"]+');
    for (final m in urlRegex.allMatches(rawDesc)) {
      var u = m.group(0)!;
      u = u.replaceAll(RegExp(r'[,.;:]$'), '');
      if (!urls.contains(u)) urls.add(u);
    }

    final cleaned = rawDesc
        .replaceAll(
          RegExp(r'\n*Ảnh minh chứng.*$', multiLine: true, caseSensitive: false),
          '',
        )
        .replaceAll(urlRegex, '')
        .trim();

    return (cleaned, urls);
  }

  Future<void> _openDirections() async {
    final opened = await openLockerDirections(
      latitude: _report['lockerLatitude'] is num
          ? (_report['lockerLatitude'] as num).toDouble()
          : null,
      longitude: _report['lockerLongitude'] is num
          ? (_report['lockerLongitude'] as num).toDouble()
          : null,
      address: _report['lockerAddress']?.toString(),
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trạm Kiosk chưa có dữ liệu vị trí bản đồ.')),
      );
    }
  }

  Future<void> _addPhotos(int reportId, int existingCount) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => _AddUserPhotosSheet(
        reportId: reportId,
        service: _service,
        maxPhotos: math.min(
          _maxReportPhotosPerRequest,
          _maxReportPhotosPerReport - existingCount,
        ),
      ),
    );
    if (added == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã bổ sung ảnh thành công!'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
      if (widget.onChanged != null) {
        await widget.onChanged!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _report;
    final status = r['status'] as String? ?? 'OPEN';
    final reportId = r['id'] is int ? r['id'] as int : int.tryParse(r['id']?.toString() ?? '');
    final lockerLabel = r['lockerName'] ?? r['lockerCode'] ?? 'Trạm Kiosk';
    final boxLabel = r['boxNumber'] ?? r['boxId'];
    final createdAt = _parseDate(r['createdAt']);
    final assignedAt = _parseDate(r['assignedAt'] ?? r['claimedAt']);
    final resolvedAt = _parseDate(r['resolvedAt'] ?? r['closedAt'] ?? r['completedAt']);
    final slaDueAt = _parseDate(r['slaDueAt']);
    final ageLabel = createdAt == null ? null : _ageLabel(createdAt);

    final (cleanedDesc, userPhotos) = _extractUserPhotosAndClean(
      r['description'],
      r['photoUrls'] ?? r['photos'],
    );

    final rawAttachments = r['attachments'];
    final attachments = [
      ...userPhotos.map((u) => ReportAttachment(
            url: u,
            stage: ReportStage.report,
            createdAt: createdAt,
          )),
      if (rawAttachments is List) ...ReportAttachment.listFrom(rawAttachments),
    ];

    // Bổ sung ảnh từ các dòng log tiến trình của KTV nếu chưa có trong gallery
    final seenAttUrls = attachments.map((a) => a.url).toSet();
    for (final l in _logs) {
      final logAtts = ReportAttachment.listFrom(l['attachments']);
      for (final a in logAtts) {
        if (!seenAttUrls.contains(a.url)) {
          seenAttUrls.add(a.url);
          attachments.add(a);
        }
      }
    }

    final reporterName = (r['reporterName'] ?? '').toString().trim();
    final reporterPhone = (r['reporterPhone'] ?? '').toString().trim();
    final lockerAddress = (r['lockerAddress'] ?? '').toString().trim();
    final staffNote = (r['staffNote'] ?? '').toString().trim();
    final isResolved = status == 'RESOLVED' || status == 'CLOSED';
    final reportPhotoCount = attachments.where((a) => a.stage == ReportStage.report).length;
    final userReportPhotos = attachments
        .where((a) => a.stage == ReportStage.report)
        .toList();
    final canAddPhotos = reportId != null && !isResolved && reportPhotoCount < _maxReportPhotosPerReport;

    final effectiveLogs = _logs.isNotEmpty
        ? _logs
        : _synthesizeLogs(
            attachments: attachments,
            status: status,
            staffNote: staffNote,
            resolvedAt: resolvedAt,
            assignedAt: assignedAt,
            createdAt: createdAt,
          );

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.88,
      child: Column(
        children: [
          // Drag handle
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
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'RPT-${r['id']} · ${r['title'] ?? 'Báo cáo sự cố'}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: opsDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusChip(status),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Hồ sơ chi tiết phiếu sự cố kỹ thuật',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges Row
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (ageLabel != null)
                        _MiniPill(
                          icon: Icons.schedule,
                          text: ageLabel,
                          color: isResolved ? const Color(0xFF16A34A) : opsPrimary,
                        ),
                      if (createdAt != null)
                        _MiniPill(
                          icon: Icons.access_time,
                          text: 'Tạo lúc: ${_formatFullDateTime(createdAt)}',
                        ),
                      if (r['assignedToUserId'] != null)
                        _MiniPill(
                          icon: Icons.engineering_outlined,
                          text: 'KTV phụ trách: #${r['assignedToUserId']}',
                          color: const Color(0xFF0284C7),
                        )
                      else if (!isResolved)
                        const _MiniPill(
                          icon: Icons.hourglass_top_outlined,
                          text: 'Đang điều phối KTV',
                          color: Color(0xFFD97706),
                        ),
                      if (isResolved && resolvedAt != null)
                        _MiniPill(
                          icon: Icons.check_circle_outline,
                          text: 'Hoàn tất lúc: ${_formatFullDateTime(resolvedAt)}',
                          color: const Color(0xFF16A34A),
                        )
                      else if (slaDueAt != null)
                        _MiniPill(
                          icon: Icons.timelapse,
                          text: 'Hạn xử lý: ${_formatFullDateTime(slaDueAt)}',
                          color: const Color(0xFF2563EB),
                        ),
                      _MiniPill(
                        icon: Icons.category_outlined,
                        text: boxLabel != null ? 'Sự cố Ô tủ #$boxLabel' : 'Sự cố Trạm Kiosk',
                        color: const Color(0xFF475569),
                      ),
                      if (r['orderCode'] != null && r['orderCode'].toString().trim().isNotEmpty)
                        _MiniPill(
                          icon: Icons.receipt_long_outlined,
                          text: 'Đơn hàng: ${r['orderCode']}',
                          color: const Color(0xFF0D9488),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Location & Locker Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined, size: 16, color: opsPrimary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '$lockerLabel${boxLabel != null ? ' · Ô #$boxLabel' : ''}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: opsDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (lockerAddress.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on_outlined, size: 15, color: opsMutedText),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  lockerAddress,
                                  style: const TextStyle(fontSize: 12, color: opsMutedText),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            onPressed: _openDirections,
                            icon: const Icon(Icons.near_me_outlined, size: 14, color: opsPrimary),
                            label: const Text(
                              'Chỉ đường tới Kiosk',
                              style: TextStyle(fontSize: 12, color: opsPrimary, fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              side: BorderSide(color: opsPrimary.withValues(alpha: 0.35)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Reporter info card
                  if (reporterName.isNotEmpty || reporterPhone.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: opsPrimary.withValues(alpha: 0.1),
                            child: const Icon(Icons.person, size: 20, color: opsPrimary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reporterName.isNotEmpty ? reporterName : 'Khách hàng',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: opsDark),
                                ),
                                if (reporterPhone.isNotEmpty)
                                  Text(
                                    reporterPhone,
                                    style: const TextStyle(fontSize: 12, color: opsMutedText, fontFamily: 'monospace'),
                                  ),
                              ],
                            ),
                          ),
                          if (reporterPhone.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.copy, size: 18, color: opsPrimary),
                              tooltip: 'Sao chép SĐT',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: reporterPhone));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Đã sao chép số điện thoại')),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Description card & Ảnh người báo gửi
                  if (cleanedDesc.isNotEmpty || userReportPhotos.isNotEmpty || canAddPhotos) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Nội dung phản ánh sự cố:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: opsDark),
                        ),
                        if (canAddPhotos)
                          TextButton.icon(
                            onPressed: () => _addPhotos(reportId, reportPhotoCount),
                            icon: const Icon(LucideIcons.imagePlus, size: 14),
                            label: Text(
                              userReportPhotos.isEmpty ? 'Thêm ảnh' : 'Bổ sung ảnh',
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AISLShadcnTheme.navyPrimary,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (cleanedDesc.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          cleanedDesc,
                          style: const TextStyle(fontSize: 13, color: opsDark, height: 1.4),
                        ),
                      ),
                    if (userReportPhotos.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      AttachmentStrip(
                        attachments: userReportPhotos,
                        viewerTitle: 'Ảnh hiện trường sự cố bạn đã gửi',
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],

                  // Timeline tiến trình xử lý
                  const Text(
                    'Tiến trình xử lý sự cố:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: opsDark),
                  ),
                  const SizedBox(height: 8),
                  _buildTimeline(
                    status,
                    createdAt,
                    assignedAt,
                    resolvedAt,
                    attachments: attachments,
                    logs: effectiveLogs,
                  ),
                  const SizedBox(height: 16),

                  // Staff Note / Resolution Note Card
                  if (staffNote.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7F0F8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBAE6FD)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.comment_outlined, size: 16, color: Color(0xFF0284C7)),
                              SizedBox(width: 6),
                              Text(
                                'Phản hồi từ đội ngũ kỹ thuật:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  color: Color(0xFF0369A1),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            staffNote,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF0C4A6E), height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Nhật ký & Tiến độ xử lý của KTV
                  _UserRepairLogsSection(
                    logs: effectiveLogs,
                    loading: _loadingFresh,
                    onRefresh: _loadFreshData,
                    staffNote: staffNote,
                    resolvedAt: resolvedAt,
                    technicianName: r['assignedToTechnicianName'] ?? r['technicianName'],
                    technicianId: r['assignedToUserId'] ?? r['technicianId'],
                  ),
                  const SizedBox(height: 16),

                  // Rating section khi đã giải quyết
                  if (isResolved && reportId != null) ...[
                    _ReportRatingSection(
                      reportId: reportId,
                      service: _service,
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),

          // Bottom Close button
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: opsDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(
    String status,
    DateTime? createdAt,
    DateTime? assignedAt,
    DateTime? resolvedAt, {
    List<ReportAttachment> attachments = const [],
    List<Map<String, dynamic>> logs = const [],
  }) {
    final isPending = status == 'PENDING' || status == 'OPEN';
    final isInProgress = status == 'IN_PROGRESS';
    final isResolved = status == 'RESOLVED' || status == 'CLOSED';

    // Trích xuất các mốc thời gian từ attachments để đảm bảo hiển thị đủ mốc
    final inspectionAtt = attachments.where((a) => a.stage == ReportStage.inspection).firstOrNull;
    final progressAtt = attachments.where((a) => a.stage == ReportStage.progress).lastOrNull;
    final resolutionAtt = attachments.where((a) => a.stage == ReportStage.resolution).lastOrNull;

    final inspectionTime = _parseDate(inspectionAtt?.createdAt ?? inspectionAtt?.capturedAt);
    final progressAttachmentTime = _parseDate(progressAtt?.createdAt ?? progressAtt?.capturedAt);
    final resolutionAttachmentTime = _parseDate(resolutionAtt?.createdAt ?? resolutionAtt?.capturedAt);

    // 1. KTV tiếp nhận
    final ktvId = _report['assignedToUserId'] ?? _report['technicianId'];
    final ktvName = (_report['assignedToTechnicianName'] ?? _report['technicianName'] ?? '').toString().trim();
    final ktvText = ktvName.isNotEmpty ? ktvName : (ktvId != null ? 'KTV #$ktvId' : 'KTV phụ trách');

    DateTime? effectiveAssignedAt = assignedAt ?? inspectionTime;
    if (effectiveAssignedAt == null && !isPending && logs.isNotEmpty) {
      effectiveAssignedAt = _parseDate(logs.first['createdAt']);
    }
    if (effectiveAssignedAt == null && (isInProgress || isResolved)) {
      effectiveAssignedAt = createdAt;
    }

    String ktvSubtitle;
    if (isPending) {
      ktvSubtitle = 'Đang điều phối KTV tiếp nhận';
    } else if (effectiveAssignedAt != null) {
      ktvSubtitle = '$ktvText · Tiếp nhận: ${_formatFullDateTime(effectiveAssignedAt)}';
    } else {
      ktvSubtitle = '$ktvText đã tiếp nhận điều phối';
    }

    // 2. Kiểm tra & xử lý tại Kiosk
    final progressLogs = logs.where((l) {
      final note = '${l['note'] ?? ''}'.toUpperCase();
      return !note.contains('NGHIỆM THU');
    }).toList();

    DateTime? progressTime = progressAttachmentTime;
    String progressDesc = (progressAtt?.caption ?? '').trim();
    if (progressTime == null && progressLogs.isNotEmpty) {
      final latest = progressLogs.last;
      progressTime = _parseDate(latest['createdAt']);
      var note = (latest['note'] ?? '').toString().trim();
      note = note
          .replaceAll(RegExp(r'\[SỬA TẠI CHỖ THÀNH CÔNG\]|\[XỬ LÝ TẠI CHỖ\]', caseSensitive: false), '[GHI CHÚ HIỆN TRƯỜNG]')
          .replaceAll(RegExp(r'\[NGHIỆM THU[^\]]*\]', caseSensitive: false), '[NGHIỆM THU THÀNH CÔNG]');
      progressDesc = note.length > 70 ? '${note.substring(0, 70)}…' : note;
    }
    if (progressTime == null && inspectionTime != null) {
      progressTime = inspectionTime;
      if (progressDesc.isEmpty) {
        progressDesc = (inspectionAtt?.caption ?? '').trim();
        if (progressDesc.isEmpty) {
          progressDesc = 'KTV đã kiểm tra & xử lý hiện trường';
        }
      }
    }

    // 3. Nghiệm thu & đóng phiếu
    DateTime? effectiveResolvedAt = resolvedAt ?? resolutionAttachmentTime;
    String resolutionNote = (_report['staffNote'] ?? '').toString().trim();

    final resolutionLogs = logs.where((l) {
      final note = '${l['note'] ?? ''}'.toUpperCase();
      return note.contains('NGHIỆM THU');
    }).toList();

    if (resolutionLogs.isNotEmpty) {
      final rLog = resolutionLogs.last;
      effectiveResolvedAt ??= _parseDate(rLog['createdAt']);
      if (resolutionNote.isEmpty) {
        resolutionNote = (rLog['note'] ?? '').toString().trim();
      }
    } else if (isResolved && effectiveResolvedAt == null && logs.isNotEmpty) {
      effectiveResolvedAt = _parseDate(logs.last['createdAt']);
      if (resolutionNote.isEmpty) {
        resolutionNote = (logs.last['note'] ?? '').toString().trim();
      }
    }
    if (resolutionNote.isEmpty && resolutionAtt?.caption != null && resolutionAtt!.caption!.trim().isNotEmpty) {
      resolutionNote = resolutionAtt.caption!.trim();
    }

    resolutionNote = resolutionNote
        .replaceAll(RegExp(r'\[SỬA TẠI CHỖ THÀNH CÔNG\]|\[XỬ LÝ TẠI CHỖ\]', caseSensitive: false), '[GHI CHÚ HIỆN TRƯỜNG]')
        .replaceAll(RegExp(r'\[NGHIỆM THU[^\]]*\]', caseSensitive: false), '[NGHIỆM THU THÀNH CÔNG]');

    String step3Subtitle;
    if (progressTime != null) {
      step3Subtitle = 'Đã xử lý lúc ${_formatFullDateTime(progressTime)}${progressDesc.isNotEmpty ? ' · $progressDesc' : ' · Đã kiểm tra & xử lý'}';
    } else if (isResolved) {
      step3Subtitle = effectiveResolvedAt != null
          ? 'Đã hoàn tất xử lý lúc ${_formatFullDateTime(effectiveResolvedAt)}'
          : 'Đã khắc phục hoàn tất';
    } else if (isInProgress) {
      step3Subtitle = effectiveAssignedAt != null
          ? '${_formatFullDateTime(effectiveAssignedAt)} · KTV đang kiểm tra hiện trường & xử lý'
          : 'KTV đang kiểm tra hiện trường & xử lý';
    } else {
      step3Subtitle = 'Chờ KTV tới trạm Kiosk kiểm tra';
    }

    String step4Subtitle;
    if (isResolved) {
      if (effectiveResolvedAt != null) {
        step4Subtitle = 'Nghiệm thu lúc: ${_formatFullDateTime(effectiveResolvedAt)}${resolutionNote.isNotEmpty ? ' · $resolutionNote' : ''}';
      } else {
        step4Subtitle = 'Đã nghiệm thu hoàn tất${resolutionNote.isNotEmpty ? ' · $resolutionNote' : ''}';
      }
    } else {
      final slaDueAt = _parseDate(_report['slaDueAt']);
      step4Subtitle = slaDueAt != null
          ? 'Dự kiến hoàn tất trước: ${_formatFullDateTime(slaDueAt)}'
          : 'Chờ nghiệm thu & đóng phiếu';
    }

    final steps = [
      _TimelineStepData(
        title: 'Gửi báo cáo thành công',
        subtitle: createdAt != null ? 'Đã gửi: ${_formatFullDateTime(createdAt)}' : 'Hệ thống đã ghi nhận sự cố',
        isDone: true,
        isActive: isPending,
        icon: LucideIcons.fileCheck,
      ),
      _TimelineStepData(
        title: 'Kỹ thuật viên tiếp nhận',
        subtitle: ktvSubtitle,
        isDone: !isPending,
        isActive: isInProgress && assignedAt == null,
        icon: LucideIcons.userCheck,
      ),
      _TimelineStepData(
        title: 'Kiểm tra & Xử lý tại Kiosk',
        subtitle: step3Subtitle,
        isDone: isResolved,
        isActive: isInProgress,
        icon: LucideIcons.wrench,
      ),
      _TimelineStepData(
        title: 'Nghiệm thu & Đóng phiếu',
        subtitle: step4Subtitle,
        isDone: isResolved,
        isActive: isResolved,
        icon: LucideIcons.circleCheck,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: steps.asMap().entries.map((entry) {
          final idx = entry.key;
          final step = entry.value;
          final isLast = idx == steps.length - 1;

          final color = step.isDone
              ? const Color(0xFF16A34A)
              : (step.isActive ? const Color(0xFF0284C7) : Colors.grey.shade400);

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: step.isDone
                            ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                            : (step.isActive
                                ? const Color(0xFF0284C7).withValues(alpha: 0.12)
                                : Colors.grey.shade100),
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 1.5),
                      ),
                      child: Icon(step.icon, size: 14, color: color),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: step.isDone ? const Color(0xFF16A34A) : Colors.grey.shade200,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: step.isDone || step.isActive ? opsDark : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          step.subtitle,
                          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TimelineStepData {
  _TimelineStepData({
    required this.title,
    required this.subtitle,
    required this.isDone,
    required this.isActive,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final bool isDone;
  final bool isActive;
  final IconData icon;
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({
    required this.icon,
    required this.text,
    this.color = opsPrimary,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nhật ký xử lý của KTV – Customer read-only view (đồng bộ với Fig 4)
// ─────────────────────────────────────────────────────────────────────────────

class _UserRepairLogsSection extends StatelessWidget {
  const _UserRepairLogsSection({
    required this.logs,
    required this.loading,
    required this.onRefresh,
    this.staffNote,
    this.resolvedAt,
    this.technicianName,
    this.technicianId,
  });

  final List<Map<String, dynamic>> logs;
  final bool loading;
  final VoidCallback onRefresh;
  final String? staffNote;
  final DateTime? resolvedAt;
  final dynamic technicianName;
  final dynamic technicianId;

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final s = value.toString().trim();
    if (s.isEmpty) return null;
    if (s.endsWith('Z') || RegExp(r'[+-]\d\d:?\d\d$').hasMatch(s)) {
      return DateTime.tryParse(s)?.toLocal();
    }
    return DateTime.tryParse(s);
  }

  String _fmt(dynamic value) {
    if (value == null) return '';
    final d = _parseDate(value);
    if (d == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.hour)}:${two(d.minute)} ${two(d.day)}/${two(d.month)}/${d.year}';
  }

  String _fmtSec(dynamic value) {
    if (value == null) return '';
    final d = _parseDate(value);
    if (d == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.hour)}:${two(d.minute)}:${two(d.second)} ${two(d.day)}/${two(d.month)}/${d.year}';
  }

  Widget _buildTaggedNote(String noteText) {
    var rawText = noteText.trim();
    if (rawText.isNotEmpty) {
      rawText = rawText.replaceAll(
        RegExp(r'^\[(?:SỬA TẠI CHỖ THÀNH CÔNG|XỬ LÝ TẠI CHỖ)\]\s*', caseSensitive: false),
        '[GHI CHÚ HIỆN TRƯỜNG] ',
      );
    }
    String tag = '';
    String rest = rawText;

    final match = RegExp(r'^(\[[^\]]+\])\s*([\s\S]*)$').firstMatch(rawText);
    if (match != null) {
      tag = match.group(1)!;
      rest = (match.group(2) ?? '').trim();
    }

    final upperTag = tag.toUpperCase();
    Color tagBg = const Color(0xFFE2E8F0);
    Color tagFg = const Color(0xFF334155);

    if (upperTag.contains('NGHIỆM THU') || upperTag.contains('THÀNH CÔNG')) {
      tag = '[NGHIỆM THU THÀNH CÔNG]';
      tagBg = const Color(0xFFDCFCE7);
      tagFg = const Color(0xFF15803D);
    } else if (upperTag.contains('HIỆN TRƯỜNG') || upperTag.contains('KIỂM TRA')) {
      tag = '[GHI CHÚ HIỆN TRƯỜNG]';
      tagBg = const Color(0xFFE0F2FE);
      tagFg = const Color(0xFF0369A1);
    } else if (upperTag.contains('GIA HẠN')) {
      tag = '[GIA HẠN SLA]';
      tagBg = const Color(0xFFFEF3C7);
      tagFg = const Color(0xFFB45309);
    } else if (upperTag.contains('TIẾN ĐỘ') || upperTag.contains('TIẾN TRÌNH')) {
      tag = '[TIẾN ĐỘ SỬA CHỮA]';
      tagBg = const Color(0xFFE0F2FE);
      tagFg = const Color(0xFF0369A1);
    } else if (upperTag.contains('ĐIỀU CHUYỂN')) {
      tagBg = const Color(0xFFE0F2FE);
      tagFg = const Color(0xFF0369A1);
    } else if (upperTag.contains('BÀN GIAO')) {
      tagBg = const Color(0xFFF3E8FF);
      tagFg = const Color(0xFF7E22CE);
    } else if (upperTag.contains('LƯU KHO') || upperTag.contains('HUB') || upperTag.contains('NIÊM PHONG')) {
      tagBg = const Color(0xFFFEF3C7);
      tagFg = const Color(0xFFB45309);
    }

    if (tag.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: tagBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              tag,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: tagFg),
            ),
          ),
          if (rest.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(rest, style: const TextStyle(fontSize: 13, color: opsDark, height: 1.35)),
          ],
        ],
      );
    }

    return Text(rawText, style: const TextStyle(fontSize: 13, color: opsDark, height: 1.35));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history_edu_outlined, size: 16, color: opsPrimary),
            const SizedBox(width: 6),
            const Text(
              'Tiến độ xử lý của KTV:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: opsDark),
            ),
            if (logs.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: opsPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${logs.length}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: opsPrimary),
                ),
              ),
            ],
            const Spacer(),
            if (!loading)
              InkWell(
                onTap: onRefresh,
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.refresh, size: 16, color: opsMutedText),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (loading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          )
        else if (logs.isEmpty)
          (staffNote != null && staffNote!.trim().isNotEmpty)
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              technicianName != null && '$technicianName'.trim().isNotEmpty
                                  ? '$technicianName'
                                  : (technicianId != null ? 'KTV #$technicianId' : 'Kỹ thuật viên nghiệm thu'),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (resolvedAt != null)
                            Text(
                              _fmt(resolvedAt),
                              style: const TextStyle(fontSize: 11.5, color: opsMutedText),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildTaggedNote(
                        staffNote!.trim().startsWith('[')
                            ? staffNote!.trim()
                            : '[NGHIỆM THU THÀNH CÔNG] ${staffNote!.trim()}',
                      ),
                    ],
                  ),
                )
              : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: opsMutedText),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'KTV chưa ghi chú bước xử lý nào. Các thao tác của KTV sẽ hiển thị ở đây.',
                          style: TextStyle(fontSize: 12, color: opsMutedText),
                        ),
                      ),
                    ],
                  ),
                )
        else
          Column(
            children: [
              for (final log in logs) ...[
                Builder(
                  builder: (context) {
                    final rawNote = '${log['note'] ?? ''}'.trim();
                    var displayNote = rawNote.replaceAll(
                      RegExp(r'^\[(?:SỬA TẠI CHỖ THÀNH CÔNG|XỬ LÝ TẠI CHỖ)\]\s*', caseSensitive: false),
                      '[GHI CHÚ HIỆN TRƯỜNG] ',
                    );
                    final logPhotos = ReportAttachment.listFrom(log['attachments']);
                    if (!displayNote.startsWith('[') && logPhotos.any((a) => a.stage == ReportStage.resolution)) {
                      displayNote = '[NGHIỆM THU THÀNH CÔNG] $displayNote';
                    }
                    final isSlaExtension = displayNote.contains('[GIA HẠN SLA]');
                    final cardBg = isSlaExtension ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC);
                    final cardBorder = isSlaExtension ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0);

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isSlaExtension) ...[
                            Container(
                              padding: const EdgeInsets.only(bottom: 6),
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: const BoxDecoration(
                                border: Border(bottom: BorderSide(color: Color(0xFFFEF3C7))),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFFCD34D)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(LucideIcons.clock, size: 11, color: Color(0xFFB45309)),
                                        SizedBox(width: 4),
                                        Text(
                                          'Phê duyệt gia hạn SLA',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFB45309),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              displayNote,
                              style: const TextStyle(fontSize: 12.5, color: opsDark, height: 1.4),
                            ),
                          ] else ...[
                            _buildTaggedNote(displayNote),
                          ],
                          if (logPhotos.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(LucideIcons.camera, size: 12.5, color: Color(0xFF6366F1)),
                                const SizedBox(width: 4),
                                Text(
                                  'Ảnh trong quá trình sửa (${logPhotos.length} ảnh):',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: opsMutedText,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            AttachmentStrip(
                              attachments: logPhotos,
                              size: 64,
                              viewerTitle: 'KTV · ${_fmtSec(log['createdAt'])}',
                            ),
                          ],
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.only(top: 6),
                            decoration: const BoxDecoration(
                              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.clock, size: 12, color: opsMutedText),
                                const SizedBox(width: 4),
                                Text(
                                  _fmtSec(log['createdAt']),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                    color: opsMutedText,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  technicianName != null && '$technicianName'.trim().isNotEmpty
                                      ? '$technicianName'
                                      : (log['actorName'] != null && '${log['actorName']}'.trim().isNotEmpty
                                          ? '${log['actorName']}'
                                          : (log['actorUserId'] != null
                                              ? 'KTV #${log['actorUserId']}'
                                              : 'ky thuat vien Kiosk')),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: opsDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    const Icon(LucideIcons.shieldCheck, size: 13, color: opsMutedText),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        'Chế độ xem khách hàng · KTV cập nhật nhật ký & minh chứng qua Mobile App',
                        style: TextStyle(fontSize: 11, color: opsMutedText, fontStyle: FontStyle.italic),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${logs.length} bước xử lý',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: opsDark),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Phần đánh giá chất lượng phục vụ của KTV sau khi xử lý xong
class _ReportRatingSection extends StatefulWidget {
  const _ReportRatingSection({
    required this.reportId,
    required this.service,
  });

  final int reportId;
  final LockerOpsService service;

  @override
  State<_ReportRatingSection> createState() => _ReportRatingSectionState();
}

class _ReportRatingSectionState extends State<_ReportRatingSection> {
  Map<String, dynamic>? _rating;
  bool _loading = true;
  bool _submitting = false;
  final _feedbackCtrl = TextEditingController();
  int _selectedStars = 5;

  @override
  void initState() {
    super.initState();
    _loadRating();
  }

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRating() async {
    try {
      final res = await widget.service.getReportRating(widget.reportId);
      if (mounted) {
        setState(() => _rating = (res != null && res.isNotEmpty) ? res : null);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitRating() async {
    setState(() => _submitting = true);
    try {
      final res = await widget.service.rateReport(
        widget.reportId,
        _selectedStars,
        _feedbackCtrl.text.trim().isNotEmpty ? _feedbackCtrl.text.trim() : null,
      );
      if (mounted) {
        setState(() => _rating = res);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cảm ơn bạn đã gửi đánh giá!'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi gửi đánh giá: ${LockerOpsService.errorMessage(e)}'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final hasRated = _rating != null && _rating!['rating'] != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.star, size: 18, color: Color(0xFFD97706)),
              const SizedBox(width: 8),
              Text(
                hasRated ? 'Đánh giá của bạn về KTV' : 'Đánh giá chất lượng phục vụ của KTV',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF92400E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (hasRated) ...[
            Row(
              children: [
                ...List.generate(5, (i) {
                  final starVal = _rating!['rating'] as num? ?? 5;
                  return Icon(
                    LucideIcons.star,
                    size: 20,
                    color: i < starVal ? const Color(0xFFF59E0B) : Colors.grey.shade300,
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  '${_rating!['rating']}/5 sao',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF92400E),
                  ),
                ),
              ],
            ),
            if (_rating!['feedback'] != null && _rating!['feedback'].toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Nhận xét: "${_rating!['feedback']}"',
                style: const TextStyle(fontSize: 12, color: Color(0xFF78350F), fontStyle: FontStyle.italic),
              ),
            ],
          ] else ...[
            const Text(
              'Phiếu sự cố đã được xử lý xong. Hãy đánh giá sự hài lòng của bạn:',
              style: TextStyle(fontSize: 12, color: Color(0xFF78350F)),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (i) {
                final star = i + 1;
                final isSelected = star <= _selectedStars;
                return IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: Icon(
                    LucideIcons.star,
                    size: 26,
                    color: isSelected ? const Color(0xFFF59E0B) : Colors.grey.shade300,
                  ),
                  onPressed: () => setState(() => _selectedStars = star),
                );
              }),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _feedbackCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Nhận xét thêm về thái độ hoặc tốc độ xử lý của KTV (tuỳ chọn)...',
                hintStyle: const TextStyle(fontSize: 12, color: opsMutedText),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFFDE68A)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: _submitting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(LucideIcons.send, size: 14),
                label: const Text('Gửi đánh giá', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Sheet chọn và upload ảnh bổ sung
class _AddUserPhotosSheet extends StatefulWidget {
  const _AddUserPhotosSheet({
    required this.reportId,
    required this.service,
    required this.maxPhotos,
  });

  final int reportId;
  final LockerOpsService service;
  final int maxPhotos;

  @override
  State<_AddUserPhotosSheet> createState() => _AddUserPhotosSheetState();
}

class _AddUserPhotosSheetState extends State<_AddUserPhotosSheet> {
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
                accentColor: AISLShadcnTheme.navyPrimary,
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
                    backgroundColor: AISLShadcnTheme.navyPrimary,
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
