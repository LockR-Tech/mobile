import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/core/media/media.dart';
import 'package:smart_laundry_locker/core/utils/app_date_time.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/complete_inspection_sheet.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value');
}

/// Modal BottomSheet hiển thị 100% đầy đủ thông tin chi tiết của lịch kiểm tra định kỳ:
/// 1. Tất cả các trường thông tin Admin thiết lập khi tạo lịch (Thiết bị Kiosk, Mã lịch,
///    Tên kế hoạch, Ưu tiên, Vị trí toà nhà, Ca/khung giờ, Chu kỳ lặp lại, KTV phụ trách,
///    Bộ tiêu chí checklist SOP, Hướng dẫn nghiệp vụ SOP).
/// 2. Chi tiết kết quả kiểm tra lần trước (Đạt/Không đạt, chi tiết từng hạng mục checklist
///    kèm ghi chú riêng từng mục, ghi chú hiện trường KTV, ảnh minh chứng hiện trường KTV đã chụp,
///    phiếu sự cố kỹ thuật liên quan phát sinh nếu không đạt).
class ScheduleDetailModalSheet extends StatefulWidget {
  const ScheduleDetailModalSheet({
    required this.schedule,
    required this.service,
    required this.isMine,
    required this.onOpenDirections,
    required this.onOpenReport,
    required this.onStartInspection,
    super.key,
  });

  final Map<String, dynamic> schedule;
  final LockerOpsService service;
  final bool isMine;
  final void Function(Map<String, dynamic> item) onOpenDirections;
  final void Function(int reportId) onOpenReport;
  final void Function(Map<String, dynamic> schedule) onStartInspection;

  @override
  State<ScheduleDetailModalSheet> createState() =>
      _ScheduleDetailModalSheetState();
}

class _ScheduleDetailModalSheetState extends State<ScheduleDetailModalSheet> {
  bool _loadingLogs = true;
  Map<String, dynamic>? _latestLog;
  List<Map<String, dynamic>> _checklistEvaluations = [];

  @override
  void initState() {
    super.initState();
    _loadInspectionLogs();
  }

  Future<void> _loadInspectionLogs() async {
    final id = _asInt(widget.schedule['id']);
    if (id == null) {
      if (mounted) setState(() => _loadingLogs = false);
      return;
    }
    try {
      final logs = await widget.service.scheduleInspectionLogs(id);
      if (mounted && logs.isNotEmpty) {
        final first = logs.first;
        List<Map<String, dynamic>> parsedEvaluations = [];
        if (first['checklistResults'] != null) {
          try {
            final decoded = jsonDecode(first['checklistResults'].toString());
            if (decoded is List) {
              parsedEvaluations = decoded
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList();
            }
          } catch (_) {}
        }

        setState(() {
          _latestLog = first;
          _checklistEvaluations = parsedEvaluations;
          _loadingLogs = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingLogs = false);
  }

  String _formatDateTime(dynamic value) {
    if (value == null) return 'Chưa xác định';
    final dt = parseServerDateTime(value);
    if (dt == null) return '$value';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)} ${two(dt.day)}/${two(dt.month)}/${dt.year}';
  }

  String _formatDateOnly(dynamic value) {
    if (value == null) return 'Chưa xác định';
    final dt = parseServerDateTime(value);
    if (dt == null) return '$value';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year}';
  }

  String _formatTimeOnly(dynamic value) {
    if (value == null) return '';
    final dt = parseServerDateTime(value);
    if (dt == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    final h = dt.hour;
    final ampm = h >= 12 ? 'PM' : 'AM';
    final displayH = h % 12 == 0 ? 12 : h % 12;
    return '${two(displayH)}:${two(dt.minute)} $ampm (${two(dt.hour)}:${two(dt.minute)})';
  }

  String _withItemEmoji(String label) {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return '';
    final firstRune = trimmed.runes.first;
    if (firstRune > 0x2000) return trimmed;
    final lower = trimmed.toLowerCase();
    if (lower.contains('khóa') || lower.contains('khoa')) return '🔒 $trimmed';
    if (lower.contains('cảm biến') || lower.contains('cam bien')) {
      return '⚡ $trimmed';
    }
    if (lower.contains('nguồn') ||
        lower.contains('pin') ||
        lower.contains('ups')) {
      return '🔋 $trimmed';
    }
    if (lower.contains('màn hình') ||
        lower.contains('camera') ||
        lower.contains('qr')) {
      return '📱 $trimmed';
    }
    if (lower.contains('kết nối') ||
        lower.contains('iot') ||
        lower.contains('wifi') ||
        lower.contains('4g')) {
      return '📶 $trimmed';
    }
    if (lower.contains('vệ sinh') ||
        lower.contains('ngoại quan') ||
        lower.contains('sạch sẽ')) {
      return '🧹 $trimmed';
    }
    return '📋 $trimmed';
  }

  (String, bool) _remainingInfo(dynamic nextDueAtValue) {
    final nextDue = parseServerDateTime(nextDueAtValue);
    if (nextDue == null) return ('', false);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(nextDue.year, nextDue.month, nextDue.day);
    final dayDiff = targetDate.difference(today).inDays;

    if (dayDiff < 0) {
      return ('Quá hạn ${-dayDiff} ngày', true);
    } else if (dayDiff == 0) {
      return ('Đến hạn hôm nay', true);
    } else if (dayDiff == 1) {
      return ('Còn 1 ngày nữa đến hạn', false);
    } else {
      return ('Còn $dayDiff ngày nữa đến hạn', false);
    }
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? highlightColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: highlightColor ?? opsMutedText),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, color: opsMutedText),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: highlightColor ?? opsDark,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.schedule;
    final isDrone = s['droneUnitId'] != null;
    final lockerCode = s['lockerCode'];
    final lockerName = s['lockerName'];
    final targetLabel = isDrone
        ? 'Drone ${s['droneCode'] ?? s['droneUnitId'] ?? '—'}'
        : '${lockerName ?? "Trạm Kiosk"}${lockerCode != null ? " ($lockerCode)" : ""}';
    final lastDone = s['lastDoneAt'] != null
        ? _formatDateTime(s['lastDoneAt'])
        : null;
    final id = _asInt(s['id']);
    final rem = _remainingInfo(s['nextDueAt']);
    final due = s['due'] == true;
    final pendingReportId = _asInt(s['pendingReportId']);
    final assignedId = s['assignedTechnicianId']?.toString();
    final assignedToMe = widget.isMine;
    final blockedReason = pendingReportId != null
        ? 'Lần trước không đạt — hoàn tất phiếu RPT-$pendingReportId trước khi kiểm tra lại.'
        : assignedId != null && !assignedToMe
        ? 'Lịch do KTV khác phụ trách.'
        : null;

    final rawPriority = (s['priority'] ?? 'NORMAL').toString().toUpperCase();
    final (priorityLabel, priorityColor) = switch (rawPriority) {
      'URGENT' => ('Khẩn cấp', const Color(0xFFDC2626)),
      'HIGH' => ('Cao', const Color(0xFFEA580C)),
      'LOW' => ('Thấp', const Color(0xFF64748B)),
      _ => (
        isDrone
            ? 'Bình thường (Drone tiêu chuẩn)'
            : 'Bình thường (Trạm tiêu chuẩn)',
        const Color(0xFF0284C7),
      ),
    };

    final checklistItems = inspectionChecklistItems(s);
    final sopDescription = (s['description'] ?? '').toString().trim();
    final locationNote = (s['locationNote'] ?? '').toString().trim();
    final timeSlot = (s['scheduledTimeSlot'] ?? '').toString().trim();

    // Dữ liệu đánh giá của lần kiểm tra trước (từ log hoặc trực tiếp từ lịch)
    final hasPreviousRecord =
        s['lastDoneAt'] != null ||
        s['lastResult'] != null ||
        _latestLog != null;
    final rawLogStatus = (_latestLog?['status'] ?? s['lastResult'] ?? 'PASSED')
        .toString()
        .toUpperCase();
    final isPassed = rawLogStatus != 'FAILED' && rawLogStatus != 'FAIL';
    final logCreatedAt = _latestLog?['createdAt'] ?? s['lastDoneAt'];
    final logTechName =
        _latestLog?['technicianName'] ??
        s['assignedTechnicianName'] ??
        (isDrone ? 'Kỹ thuật viên Drone' : 'Kỹ thuật viên Kiosk');

    // Checklist 6 hạng mục SOP tiêu chuẩn trạm tủ Kiosk
    const defaultKioskChecklist = [
      '🧹 Vệ sinh tủ & ngoại quan sạch sẽ',
      '🔒 Kiểm tra khóa điện tử & tiếp điểm cửa',
      '⚡ Kiểm tra cảm biến nhận diện ô tủ',
      '🔋 Kiểm tra nguồn cấp & pin lưu điện UPS',
      '📱 Màn hình cảm ứng & camera / quét QR',
      '📶 Tín hiệu kết nối IoT 4G / WiFi ổn định',
    ];
    const defaultDroneChecklist = [
      '🛩️ Kiểm tra thân vỏ, càng đáp và cánh quạt',
      '🔋 Kiểm tra pin, đầu nối và chu kỳ sạc',
      '⚙️ Kiểm tra động cơ và độ rung bất thường',
      '🧭 Kiểm tra GPS, IMU và cảm biến độ cao',
      '📡 Kiểm tra kết nối điều khiển và telemetry',
      '📷 Kiểm tra camera, tải trọng và cơ cấu thả hàng',
    ];

    // Xây dựng danh sách chi tiết từng hạng mục để hiển thị trong mục Kết quả kiểm tra lần trước
    final List<Map<String, dynamic>> itemsToShow = [];
    if (_checklistEvaluations.isNotEmpty) {
      itemsToShow.addAll(_checklistEvaluations);
      final evaluatedLabels = _checklistEvaluations
          .map((e) => (e['label'] ?? '').toString().trim().toLowerCase())
          .toSet();
      for (final baseItem in checklistItems) {
        final norm = baseItem.trim().toLowerCase();
        if (!evaluatedLabels.contains(norm)) {
          itemsToShow.add({
            'label': baseItem,
            'result': isPassed ? 'PASS' : 'FAIL',
            'note': '',
          });
        }
      }
    } else if (hasPreviousRecord) {
      final baseItems = checklistItems.isNotEmpty
          ? checklistItems
          : (isDrone ? defaultDroneChecklist : defaultKioskChecklist);
      for (final item in baseItems) {
        itemsToShow.add({
          'label': item,
          'result': isPassed ? 'PASS' : 'FAIL',
          'note': '',
        });
      }
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.88,
      child: Column(
        children: [
          // Thanh kéo drag handle
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

          // Header Modal
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF7C3AED,
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(
                                  0xFF7C3AED,
                                ).withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              '#${id ?? "N/A"}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              s['title'] ?? 'Lịch kiểm tra định kỳ',
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF0284C7,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isDrone ? 'Định kỳ Drone' : 'Định kỳ Kiosk',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Hồ sơ chi tiết kế hoạch kiểm tra bảo trì định kỳ',
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

          // Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner phân biệt rõ ràng: Lịch định kỳ KHÔNG PHẢI sự cố
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDDD6FE)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.event_repeat,
                          size: 20,
                          color: Color(0xFF7C3AED),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isDrone
                                    ? 'Kế hoạch bảo trì định kỳ Drone'
                                    : 'Kế hoạch kiểm tra bảo trì định kỳ Kiosk',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF5B21B6),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isDrone
                                    ? 'Đây là lịch bảo trì Drone theo chu kỳ do Quản trị viên thiết lập; kết quả checklist được lưu vào hồ sơ vận hành.'
                                    : 'Đây là lịch kiểm tra bảo dưỡng định kỳ tự động theo chu kỳ cho trạm Kiosk do Quản trị viên thiết lập (không phải là phiếu báo hỏng sự cố).',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF6D28D9),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Dải Badges tổng quan các thuộc tính admin tạo
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (due)
                        _buildMiniPill(
                          icon: Icons.warning_amber_rounded,
                          text: 'Đến hạn kiểm tra',
                          color: const Color(0xFFDC2626),
                        )
                      else if (rem.$1.isNotEmpty)
                        _buildMiniPill(
                          icon: Icons.timer_outlined,
                          text: rem.$1,
                          color: const Color(0xFF2563EB),
                        ),
                      _buildMiniPill(
                        icon: Icons.flag_outlined,
                        text: 'Ưu tiên: $priorityLabel',
                        color: priorityColor,
                      ),
                      _buildMiniPill(
                        icon: Icons.repeat,
                        text: 'Chu kỳ: Mỗi ${s['intervalDays']} ngày',
                        color: const Color(0xFF475569),
                      ),
                      if (timeSlot.isNotEmpty)
                        _buildMiniPill(
                          icon: Icons.access_time_filled,
                          text: 'Ca: $timeSlot',
                          color: const Color(0xFFD97706),
                        ),
                      _buildMiniPill(
                        icon: Icons.engineering_outlined,
                        text: assignedId == null
                            ? 'Chưa giao KTV'
                            : assignedToMe
                            ? 'KTV phụ trách: Bạn'
                            : 'KTV phụ trách: ${s['assignedTechnicianName'] ?? '#$assignedId'}',
                        color: assignedToMe
                            ? const Color(0xFF16A34A)
                            : opsMutedText,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 1. THIẾT BỊ KIOSK & VỊ TRÍ ĐẶT CỤ THỂ TRONG TOÀ NHÀ (Ảnh 1)
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
                            const Icon(
                              Icons.inventory_2_outlined,
                              size: 16,
                              color: opsPrimary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                targetLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                  color: opsDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (locationNote.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.push_pin_outlined,
                                size: 15,
                                color: Color(0xFF4F46E5),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Vị trí đặt trong toà nhà: $locationNote',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF4F46E5),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if ((s['address']?.toString() ?? '')
                            .trim()
                            .isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 15,
                                color: opsMutedText,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  s['address'].toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: opsMutedText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              widget.onOpenDirections(s);
                            },
                            icon: const Icon(
                              Icons.near_me_outlined,
                              size: 14,
                              color: opsPrimary,
                            ),
                            label: Text(
                              isDrone
                                  ? 'Chỉ đường tới trạm Drone'
                                  : 'Chỉ đường tới tủ',
                              style: const TextStyle(
                                fontSize: 12,
                                color: opsPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              side: BorderSide(
                                color: opsPrimary.withValues(alpha: 0.35),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. KẾ HOẠCH & THỜI HẠN KIỂM TRA (TẤT CẢ FIELDS ADMIN TẠO)
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
                        const Text(
                          'Kế hoạch & Thời hạn kiểm tra:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: opsDark,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildDetailRow(
                          icon: Icons.event,
                          label: 'Hạn kiểm tra tới (Ngày hẹn):',
                          value: _formatDateOnly(s['nextDueAt']),
                          highlightColor: due
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF16A34A),
                        ),
                        if (_formatTimeOnly(s['nextDueAt']).isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            icon: Icons.access_time,
                            label: 'Giờ hẹn bắt đầu cụ thể:',
                            value: _formatTimeOnly(s['nextDueAt']),
                          ),
                        ],
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          icon: Icons.hourglass_top_outlined,
                          label: 'Khung giờ / Ca kiểm tra:',
                          value: timeSlot.isNotEmpty
                              ? timeSlot
                              : 'Khung giờ linh hoạt',
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          icon: Icons.repeat,
                          label: 'Chu kỳ lặp lại:',
                          value:
                              'Mỗi ${s['intervalDays']} ngày thực hiện 1 lần',
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          icon: Icons.flag_outlined,
                          label: 'Mức độ ưu tiên:',
                          value: priorityLabel,
                          highlightColor: priorityColor,
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          icon: Icons.engineering_outlined,
                          label: 'Kỹ thuật viên phụ trách:',
                          value: assignedId == null
                              ? 'Chưa phân công (Chờ nhận)'
                              : assignedToMe
                              ? 'Bạn (Được giao cho tôi)'
                              : (s['assignedTechnicianName'] ??
                                    'KTV #$assignedId'),
                          highlightColor: assignedToMe
                              ? const Color(0xFF16A34A)
                              : null,
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          icon: Icons.history,
                          label: 'Lần kiểm tra trước:',
                          value: lastDone ?? 'Chưa có lịch sử kiểm tra',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. BỘ TIÊU CHÍ KIỂM ĐỊNH KTV CẦN THỰC HIỆN (CHECKLIST SOP ADMIN TẠO)
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
                            const Icon(
                              Icons.checklist_rounded,
                              size: 16,
                              color: Color(0xFFEA580C),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Bộ tiêu chí kiểm định (${checklistItems.length} mục KTV cần thực hiện):',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: opsDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (checklistItems.isNotEmpty)
                          for (var i = 0; i < checklistItems.length; i++) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 3.5,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFEA580C,
                                      ).withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${i + 1}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFEA580C),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _withItemEmoji(checklistItems[i]),
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: opsDark,
                                        fontWeight: FontWeight.w500,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ]
                        else
                          Text(
                            isDrone
                                ? 'Kiểm tra toàn diện tình trạng vận hành của Drone.'
                                : 'Kiểm tra toàn diện hoạt động của trạm tủ Kiosk.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: opsMutedText,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. HƯỚNG DẪN NGHIỆP VỤ CHO KTV (GHI CHÚ SOP TỪ ADMIN - Ảnh 1)
                  if (sopDescription.isNotEmpty) ...[
                    Container(
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
                            children: const [
                              Icon(
                                Icons.lightbulb_outline,
                                size: 16,
                                color: Color(0xFFD97706),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Hướng dẫn nghiệp vụ (Ghi chú SOP từ Quản trị viên):',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            sopDescription,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF78350F),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 5. KẾT QUẢ KIỂM TRA LẦN TRƯỚC (HIỂN THỊ CHI TIẾT BIÊN BẢN KTV LÀM - HÌNH 2)
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
                            const Icon(
                              Icons.assignment_turned_in_outlined,
                              size: 16,
                              color: opsPrimary,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Kết quả kiểm tra lần trước:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: opsDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        if (_loadingLogs) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                        ] else if (hasPreviousRecord) ...[
                          // Banner tổng quan kết quả lần trước
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isPassed
                                  ? const Color(0xFFF0FDF4)
                                  : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isPassed
                                    ? const Color(0xFFBBF7D0)
                                    : const Color(0xFFFECACA),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isPassed
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_rounded,
                                  size: 20,
                                  color: isPassed
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFDC2626),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isPassed
                                            ? 'ĐẠT — Toàn bộ tiêu chí đạt yêu cầu'
                                            : 'KHÔNG ĐẠT — Có hạng mục bị lỗi cần xử lý',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.5,
                                          color: isPassed
                                              ? const Color(0xFF166534)
                                              : const Color(0xFF991B1B),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Thời gian: ${_formatDateTime(logCreatedAt)} · KTV: $logTechName',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: opsMutedText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // CHI TIẾT TỪNG HẠNG MỤC KIỂM ĐỊNH (Checklist items)
                          if (itemsToShow.isNotEmpty) ...[
                            Row(
                              children: [
                                const Icon(
                                  Icons.checklist_rtl_rounded,
                                  size: 15,
                                  color: Color(0xFF0284C7),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Chi tiết đánh giá từng hạng mục (${itemsToShow.length} mục):',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            for (var i = 0; i < itemsToShow.length; i++) ...[
                              Builder(
                                builder: (_) {
                                  final item = itemsToShow[i];
                                  final itemLabel = (item['label'] ?? '')
                                      .toString();
                                  final itemResult =
                                      (item['result'] ??
                                              (isPassed ? 'PASS' : 'FAIL'))
                                          .toString()
                                          .toUpperCase();
                                  final itemNote = (item['note'] ?? '')
                                      .toString()
                                      .trim();
                                  final (
                                    resText,
                                    resBg,
                                    resFg,
                                    resBorder,
                                  ) = switch (itemResult) {
                                    'PASS' => (
                                      '✓ Đạt',
                                      const Color(0xFFDCFCE7),
                                      const Color(0xFF166534),
                                      const Color(0xFF86EFAC),
                                    ),
                                    'FAIL' => (
                                      '✕ Không đạt',
                                      const Color(0xFFFEE2E2),
                                      const Color(0xFF991B1B),
                                      const Color(0xFFFCA5A5),
                                    ),
                                    _ => (
                                      '— Không áp dụng',
                                      const Color(0xFFF1F5F9),
                                      const Color(0xFF475569),
                                      const Color(0xFFCBD5E1),
                                    ),
                                  };

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: itemResult == 'FAIL'
                                            ? const Color(0xFFFCA5A5)
                                            : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 20,
                                              height: 20,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color:
                                                    (itemResult == 'FAIL'
                                                            ? const Color(
                                                                0xFFDC2626,
                                                              )
                                                            : const Color(
                                                                0xFF0284C7,
                                                              ))
                                                        .withValues(alpha: 0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                '${i + 1}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: itemResult == 'FAIL'
                                                      ? const Color(0xFFDC2626)
                                                      : const Color(0xFF0284C7),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _withItemEmoji(itemLabel),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: itemResult == 'FAIL'
                                                      ? const Color(0xFF991B1B)
                                                      : opsDark,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 7,
                                                    vertical: 2.5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: resBg,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: resBorder,
                                                ),
                                              ),
                                              child: Text(
                                                resText,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: resFg,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (itemNote.isNotEmpty) ...[
                                          const SizedBox(height: 5),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 28,
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.edit_note_outlined,
                                                  size: 13,
                                                  color: Color(0xFFDC2626),
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    'Ghi chú KTV: $itemNote',
                                                    style: const TextStyle(
                                                      fontSize: 11.5,
                                                      color: Color(0xFFB91C1C),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                            const SizedBox(height: 6),
                          ],

                          // Ghi chú chung của KTV khi kiểm tra
                          if (_latestLog?['note'] != null &&
                              _latestLog!['note']
                                  .toString()
                                  .trim()
                                  .isNotEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.comment_outlined,
                                    size: 14,
                                    color: opsDark,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Ghi chú KTV: "${_latestLog!['note']}"',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: opsDark,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],

                          // Ảnh minh chứng hiện trường KTV đã chụp
                          if (_latestLog?['photoUrls'] is List &&
                              (_latestLog!['photoUrls'] as List)
                                  .isNotEmpty) ...[
                            Builder(
                              builder: (_) {
                                final rawPhotos =
                                    _latestLog!['photoUrls'] as List;
                                final attachments = rawPhotos
                                    .map(
                                      (u) => ReportAttachment(
                                        url: u.toString(),
                                        stage: ReportStage.inspection,
                                        createdAt: parseServerDateTime(
                                          _latestLog!['createdAt'],
                                        ),
                                      ),
                                    )
                                    .toList();
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ảnh hiện trường KTV đã chụp (${attachments.length} ảnh):',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    AttachmentStrip(
                                      attachments: attachments,
                                      viewerTitle:
                                          'Ảnh kiểm tra định kỳ lần trước',
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                );
                              },
                            ),
                          ],

                          // Phiếu sự cố liên quan nếu lần trước không đạt
                          if (pendingReportId != null ||
                              _latestLog?['createdReportId'] != null) ...[
                            Builder(
                              builder: (_) {
                                final repId =
                                    pendingReportId ??
                                    _asInt(_latestLog?['createdReportId']);
                                if (repId == null) {
                                  return const SizedBox.shrink();
                                }
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF7ED),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFFED7AA),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.assignment_turned_in_outlined,
                                            size: 16,
                                            color: Color(0xFFEA580C),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Phiếu sự cố kỹ thuật liên quan: RPT-$repId',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12.5,
                                              color: Color(0xFFC2410C),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Do lần kiểm tra trước không đạt, hệ thống đã mở phiếu sự cố kỹ thuật. Bạn cần xử lý và nghiệm thu hoàn tất phiếu này để lịch định kỳ mở lại cho lần kiểm tra tiếp theo.',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: Color(0xFF9A3412),
                                          height: 1.35,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 36,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            widget.onOpenReport(repId);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFFEA580C,
                                            ),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          icon: const Icon(
                                            Icons.assignment_turned_in_outlined,
                                            size: 15,
                                          ),
                                          label: Text(
                                            'Mở phiếu sự cố RPT-$repId để xử lý',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ] else ...[
                          const Text(
                            'Chưa có dữ liệu kiểm tra lần trước (Lịch kiểm tra mới được thiết lập).',
                            style: TextStyle(
                              fontSize: 12,
                              color: opsMutedText,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Buttons
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (pendingReportId != null)
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onOpenReport(pendingReportId);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEA580C),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(
                          Icons.assignment_turned_in_outlined,
                          size: 16,
                        ),
                        label: Text(
                          'Xử lý phiếu sự cố RPT-$pendingReportId',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: id == null || blockedReason != null
                            ? null
                            : () {
                                Navigator.pop(context);
                                widget.onStartInspection(s);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.fact_check_outlined, size: 16),
                        label: Text(
                          blockedReason != null
                              ? 'Lịch do KTV khác phụ trách'
                              : (due
                                    ? 'Bắt đầu kiểm tra ngay (Đến hạn)'
                                    : 'Kiểm tra ngay'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPill({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
