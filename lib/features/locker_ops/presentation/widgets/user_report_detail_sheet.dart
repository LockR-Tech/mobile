import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:smart_laundry_locker/core/config/business_config_service.dart';
import 'package:smart_laundry_locker/core/services/app_event_bus.dart';
import 'package:smart_laundry_locker/core/utils/app_date_time.dart';
import 'package:smart_laundry_locker/core/media/media.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/utils/locker_maps.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

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
  StreamSubscription<AppEvent>? _eventSub;

  @override
  void initState() {
    super.initState();
    _report = Map<String, dynamic>.from(widget.report);
    // KTV nhận/xử lý/từ chối phiếu khi sheet đang mở ⇒ tải lại tiến trình.
    _eventSub = AppEventBus.instance.events.listen((event) {
      if (!mounted || _loadingFresh || event is! ReportUpdatedEvent) return;
      final id = event.reportId;
      if (id == null || id == '${_report['id']}') _loadFreshData();
    });
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

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }

  Future<void> _loadFreshData() async {
    final rawId = _report['id'];
    final reportId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
    if (reportId == null) return;
    setState(() => _loadingFresh = true);

    // Chỉ dùng endpoint của chính chủ phiếu (token của khách). Lỗi phần nào thì
    // giữ dữ liệu đang có của phần đó; nhật ký rỗng = phiếu chưa có nhật ký.
    Map<String, dynamic>? freshReport;
    var logs = const <Map<String, dynamic>>[];
    var rawAttachments = const <Map<String, dynamic>>[];

    try {
      final rep = await _service.userReport(reportId);
      if (rep.isNotEmpty && rep['id'] != null) freshReport = rep;
    } catch (_) {}
    try {
      logs = await _service.userReportLogs(reportId);
    } catch (_) {}
    try {
      rawAttachments = await _service.myReportAttachments(reportId);
    } catch (_) {}

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
        // Chưa có nhật ký: chỉ dựng các mốc có thật từ ảnh theo giai đoạn và ghi
        // chú nghiệm thu của KTV (không thêm nội dung nào server không trả).
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

  /// Các mốc xử lý dựng từ dữ liệu thật của phiếu khi server chưa có nhật ký:
  /// ảnh theo giai đoạn (kèm chú thích KTV ghi), gia hạn SLA và ghi chú nghiệm
  /// thu. Không có dữ liệu thì không có mốc — màn hiện "chưa có nhật ký".
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
    final isResolved = isReportClosed(status);

    Map<String, dynamic> attJson(ReportAttachment a) => {
      'url': a.url,
      'thumbnailUrl': a.thumbnailUrl,
      'stage': a.stage,
      'caption': a.caption,
      'capturedAt': a.capturedAt?.toIso8601String(),
      'createdAt': a.createdAt?.toIso8601String(),
    };

    // 1. Kiểm tra hiện trường (INSPECTION)
    final inspectionAtts = attachments.where((a) => a.stage == ReportStage.inspection).toList();
    if (inspectionAtts.isNotEmpty) {
      final first = inspectionAtts.first;
      final cap = (first.caption ?? '').trim();
      list.add({
        'actorUserId': ktvId,
        'actorName': ktvName,
        'createdAt': (first.createdAt ?? first.capturedAt ?? assignedAt)
            ?.toIso8601String(),
        'note': cap.isEmpty
            ? '[GHI CHÚ HIỆN TRƯỜNG] ${L10n.current.urdInspectionPhotos}'
            : (cap.startsWith('[') ? cap : '[GHI CHÚ HIỆN TRƯỜNG] $cap'),
        'attachments': inspectionAtts.map(attJson).toList(),
      });
    }

    // 2. Tiến độ sửa chữa (PROGRESS)
    for (final att in attachments.where((a) => a.stage == ReportStage.progress)) {
      final cap = (att.caption ?? '').trim();
      list.add({
        'actorUserId': ktvId,
        'actorName': ktvName,
        'createdAt': (att.createdAt ?? att.capturedAt)?.toIso8601String(),
        'note': cap.isEmpty
            ? '[TIẾN ĐỘ SỬA CHỮA] ${L10n.current.urdProgressPhotos}'
            : (cap.startsWith('[') ? cap : '[TIẾN ĐỘ SỬA CHỮA] $cap'),
        'attachments': [attJson(att)],
      });
    }

    // 3. Gia hạn SLA (chỉ khi phiếu có thông tin gia hạn)
    final extHours = _report['slaExtendedHours'];
    if (extHours is num && extHours > 0) {
      final extReason = (_report['slaExtensionReason'] ?? '').toString().trim();
      final slaDueAt = _report['slaDueAt'];
      list.add({
        'actorUserId': ktvId,
        'actorName': ktvName,
        'createdAt': null,
        'note': [
          '[GIA HẠN SLA] ${L10n.current.urdSlaExtended(extHours)}',
          if (slaDueAt != null) L10n.current.urdNewDeadline(_fmtSec(slaDueAt)),
          if (extReason.isNotEmpty) L10n.current.urdReason(extReason),
        ].join('\n'),
        'attachments': const [],
      });
    }

    // 4. Nghiệm thu & hoàn tất (RESOLUTION)
    final resolutionAtts = attachments.where((a) => a.stage == ReportStage.resolution).toList();
    if (resolutionAtts.isNotEmpty || staffNote.isNotEmpty || isResolved) {
      var resNote = staffNote;
      if (resNote.isEmpty && resolutionAtts.isNotEmpty) {
        resNote = (resolutionAtts.first.caption ?? '').trim();
      }
      if (resNote.isEmpty) {
        resNote = isResolved
            ? L10n.current.urdTechResolved
            : L10n.current.urdTechSentAcceptance;
      }
      if (!resNote.startsWith('[')) {
        resNote = '[NGHIỆM THU THÀNH CÔNG] $resNote';
      }
      final resTime = (resolutionAtts.isNotEmpty
              ? (resolutionAtts.first.createdAt ?? resolutionAtts.first.capturedAt)
              : null) ??
          resolvedAt;
      list.add({
        'actorUserId': _report['resolvedByUserId'] ?? ktvId,
        'actorName': ktvName,
        'createdAt': resTime?.toIso8601String(),
        'note': resNote,
        'attachments': resolutionAtts.map(attJson).toList(),
      });
    }

    return list;
  }

  // locker-service chạy giờ UTC: chuỗi trần là UTC, không phải giờ VN (trước đây
  // phiếu hiện sớm 7 tiếng so với app KTV).
  DateTime? _parseDate(dynamic value) => parseServerDateTime(value);

  String _fmtSec(dynamic value) {
    if (value == null) return '';
    final d = _parseDate(value);
    if (d == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.hour)}:${two(d.minute)}:${two(d.second)} ${two(d.day)}/${two(d.month)}/${d.year}';
  }

  String _ageLabel(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return L10n.current.nlJustNow;
    if (diff.inMinutes < 60) return L10n.current.nlMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return L10n.current.nlHoursAgo(diff.inHours);
    return L10n.current.nlDaysAgo(diff.inDays);
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
        SnackBar(content: Text(context.l10n.urdKioskNoLocation)),
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
        SnackBar(
          content: Text(context.l10n.urdPhotosAdded),
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
    final lockerLabel = r['lockerName'] ?? r['lockerCode'] ?? context.l10n.urdKioskStation;
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
    final isResolved = isReportClosed(status);
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
                        context.l10n.urdRecordTitle,
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
                          text: context.l10n.urdCreatedAt(_formatFullDateTime(createdAt)),
                        ),
                      if (r['assignedToUserId'] != null)
                        _MiniPill(
                          icon: Icons.engineering_outlined,
                          text: context.l10n.urdTechInCharge(
                      (r['assignedToTechnicianName'] ?? '').toString().trim().isNotEmpty
                          ? '${r['assignedToTechnicianName']}'
                          : '#${r['assignedToUserId']}',
                    ),
                          color: const Color(0xFF0284C7),
                        )
                      else if (!isResolved)
                        _MiniPill(
                          icon: Icons.hourglass_top_outlined,
                          text: context.l10n.urdDispatching,
                          color: Color(0xFFD97706),
                        ),
                      if (isResolved && resolvedAt != null)
                        _MiniPill(
                          icon: Icons.check_circle_outline,
                          text: context.l10n.urdResolvedAt(_formatFullDateTime(resolvedAt)),
                          color: const Color(0xFF16A34A),
                        )
                      else if (slaDueAt != null)
                        _MiniPill(
                          icon: Icons.timelapse,
                          text: context.l10n.urdDeadline(_formatFullDateTime(slaDueAt)),
                          color: const Color(0xFF2563EB),
                        ),
                      _MiniPill(
                        icon: Icons.category_outlined,
                        text: boxLabel != null
                        ? context.l10n.urdBoxIncident(boxLabel)
                        : context.l10n.urdKioskIncident,
                        color: const Color(0xFF475569),
                      ),
                      if (r['orderCode'] != null && r['orderCode'].toString().trim().isNotEmpty)
                        _MiniPill(
                          icon: Icons.receipt_long_outlined,
                          text: context.l10n.urdOrder('${r['orderCode']}'),
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
                            label: Text(
                              context.l10n.urdDirectionsKiosk,
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
                                  reporterName.isNotEmpty ? reporterName : context.l10n.storeCustomer,
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
                              tooltip: context.l10n.urdCopyPhone,
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: reporterPhone));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(context.l10n.urdPhoneCopied)),
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
                        Text(
                          context.l10n.urdReportContent,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: opsDark),
                        ),
                        if (canAddPhotos)
                          TextButton.icon(
                            onPressed: () => _addPhotos(reportId, reportPhotoCount),
                            icon: const Icon(LucideIcons.imagePlus, size: 14),
                            label: Text(
                              userReportPhotos.isEmpty ? context.l10n.photoAdd : context.l10n.urdMorePhotos,
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
                        viewerTitle: context.l10n.urdYourPhotos,
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],

                  // Timeline tiến trình xử lý
                  Text(
                    context.l10n.urdProgressTitle,
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
                          Row(
                            children: [
                              Icon(Icons.comment_outlined, size: 16, color: Color(0xFF0284C7)),
                              SizedBox(width: 6),
                              Text(
                                context.l10n.urdTeamResponse,
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
                  child: Text(context.l10n.commonClose, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
    final isResolved = isReportClosed(status);
    // KTV kiểm tra thấy không đúng mô tả: phiếu đóng kèm phản hồi cho người báo.
    final isRejected = status == 'REJECTED';

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
    final ktvText = ktvName.isNotEmpty
        ? ktvName
        : (ktvId != null ? context.l10n.urdTechId(ktvId) : context.l10n.ordTechInCharge);

    DateTime? effectiveAssignedAt = assignedAt ?? inspectionTime;
    if (effectiveAssignedAt == null && !isPending && logs.isNotEmpty) {
      effectiveAssignedAt = _parseDate(logs.first['createdAt']);
    }
    if (effectiveAssignedAt == null && (isInProgress || isResolved)) {
      effectiveAssignedAt = createdAt;
    }

    String ktvSubtitle;
    if (isPending) {
      ktvSubtitle = context.l10n.urdDispatchingAccept;
    } else if (effectiveAssignedAt != null) {
      ktvSubtitle = context.l10n.urdTechAcceptedAt(ktvText, _formatFullDateTime(effectiveAssignedAt));
    } else {
      ktvSubtitle = context.l10n.urdTechAccepted(ktvText);
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
          progressDesc = context.l10n.urdTechInspected;
        }
      }
    }

    // 3. Nghiệm thu & đóng phiếu
    DateTime? effectiveResolvedAt = resolvedAt ?? resolutionAttachmentTime;
    String resolutionNote = (_report['staffNote'] ?? '').toString().trim();

    final resolutionLogs = logs.where((l) {
      final note = '${l['note'] ?? ''}'.toUpperCase();
      return note.contains('NGHIỆM THU') ||
          (isRejected && note.contains('KHÔNG XÁC NHẬN'));
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
      step3Subtitle = context.l10n.urdHandledAt(
        _formatFullDateTime(progressTime),
        progressDesc.isNotEmpty ? ' · $progressDesc' : ' · ${context.l10n.urdCheckedHandled}',
      );
    } else if (isResolved) {
      step3Subtitle = effectiveResolvedAt != null
          ? context.l10n.urdFixedAt(_formatFullDateTime(effectiveResolvedAt))
          : context.l10n.urdFixed;
    } else if (isInProgress) {
      step3Subtitle = effectiveAssignedAt != null
          ? '${_formatFullDateTime(effectiveAssignedAt)} · ${context.l10n.urdTechInspecting}'
          : context.l10n.urdTechInspecting;
    } else {
      step3Subtitle = context.l10n.urdWaitingTech;
    }

    String step4Subtitle;
    if (isRejected) {
      final feedback = resolutionNote
          .replaceAll(RegExp(r'^\[KHÔNG XÁC NHẬN SỰ CỐ\]\s*', caseSensitive: false), '')
          .trim();
      step4Subtitle = effectiveResolvedAt != null
          ? context.l10n.urdClosedAt(
              _formatFullDateTime(effectiveResolvedAt),
              feedback.isNotEmpty ? ' · ${context.l10n.urdFeedback(feedback)}' : '',
            )
          : (feedback.isNotEmpty
              ? context.l10n.urdFeedback(feedback)
              : context.l10n.urdCheckedNormal);
    } else if (isResolved) {
      if (effectiveResolvedAt != null) {
        step4Subtitle = context.l10n.urdAcceptedAt(
        _formatFullDateTime(effectiveResolvedAt),
        resolutionNote.isNotEmpty ? ' · $resolutionNote' : '',
      );
      } else {
        step4Subtitle = context.l10n.urdAcceptedDone(
        resolutionNote.isNotEmpty ? ' · $resolutionNote' : '',
      );
      }
    } else {
      final slaDueAt = _parseDate(_report['slaDueAt']);
      step4Subtitle = slaDueAt != null
          ? context.l10n.urdExpectedBy(_formatFullDateTime(slaDueAt))
          : context.l10n.urdAwaitingAcceptance;
    }

    final steps = [
      _TimelineStepData(
        title: context.l10n.crSent,
        subtitle: createdAt != null
              ? context.l10n.urdSentAt(_formatFullDateTime(createdAt))
              : context.l10n.urdRecorded,
        isDone: true,
        isActive: isPending,
        icon: LucideIcons.fileCheck,
      ),
      _TimelineStepData(
        title: context.l10n.urdStepTechAccepts,
        subtitle: ktvSubtitle,
        isDone: !isPending,
        isActive: isInProgress && assignedAt == null,
        icon: LucideIcons.userCheck,
      ),
      _TimelineStepData(
        title: context.l10n.urdStepInspect,
        subtitle: step3Subtitle,
        isDone: isResolved,
        isActive: isInProgress,
        icon: LucideIcons.wrench,
      ),
      _TimelineStepData(
        title: isRejected ? context.l10n.urdStepRejected : context.l10n.urdStepAccept,
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

  DateTime? _parseDate(dynamic value) => parseServerDateTime(value);

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

  /// Thẻ ghi chú viết bằng tiếng Việt (dùng để so khớp ở trên) — hiển thị theo
  /// ngôn ngữ đang chọn.
  static String _localizedTag(String tag) => switch (tag) {
    '[NGHIỆM THU THÀNH CÔNG]' => L10n.current.tagAccepted,
    '[GHI CHÚ HIỆN TRƯỜNG]' => L10n.current.tagFieldNote,
    '[GIA HẠN SLA]' => L10n.current.tagSlaExtended,
    '[TIẾN ĐỘ SỬA CHỮA]' => L10n.current.tagRepairProgress,
    _ => tag,
  };

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

    if (upperTag.contains('KHÔNG XÁC NHẬN')) {
      tagBg = const Color(0xFFF1F5F9);
      tagFg = const Color(0xFF475569);
    } else if (upperTag.contains('NGHIỆM THU') || upperTag.contains('THÀNH CÔNG')) {
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
              _localizedTag(tag),
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
            Text(
              context.l10n.urdTechProgress,
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
                                  : (technicianId != null ? context.l10n.urdTechId(technicianId) : context.l10n.urdAcceptingTech),
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
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: opsMutedText),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.l10n.urdNoTechNotes,
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
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(LucideIcons.clock, size: 11, color: Color(0xFFB45309)),
                                        SizedBox(width: 4),
                                        Text(
                                          context.l10n.urdSlaApproval,
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
                                Expanded(
                                  child: Text(
                                    context.l10n.urdRepairPhotos(logPhotos.length),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: opsMutedText,
                                    ),
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
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    technicianName != null && '$technicianName'.trim().isNotEmpty
                                        ? '$technicianName'
                                        : (log['actorName'] != null && '${log['actorName']}'.trim().isNotEmpty
                                            ? '${log['actorName']}'
                                            : (log['actorUserId'] != null
                                                ? 'KTV #${log['actorUserId']}'
                                                : context.l10n.urdKioskTech)),
                                    textAlign: TextAlign.right,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: opsDark,
                                    ),
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
                    Expanded(
                      child: Text(
                        context.l10n.urdCustomerView,
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
                        context.l10n.urdSteps(logs.length),
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
          SnackBar(
            content: Text(context.l10n.urdThanksRating),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.urdRatingError(LockerOpsService.errorMessage(e))),
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
              Expanded(
                child: Text(
                  hasRated ? context.l10n.urdYourRating : context.l10n.urdRateTech,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF92400E),
                  ),
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
                context.l10n.urdComment('${_rating!['feedback']}'),
                style: const TextStyle(fontSize: 12, color: Color(0xFF78350F), fontStyle: FontStyle.italic),
              ),
            ],
          ] else ...[
            Text(
              context.l10n.urdRatePrompt,
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
                hintText: context.l10n.urdRateHint,
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
                label: Text(context.l10n.urdSendRating, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
      setState(() => _error = context.l10n.urdChoosePhoto);
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
              Text(
                context.l10n.urdAddPhotosTitle,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: opsDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.urdAddPhotosHint(widget.maxPhotos),
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
                  label: Text(_submitting ? context.l10n.ordUploadingPhotos : context.l10n.urdSendPhotos),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
