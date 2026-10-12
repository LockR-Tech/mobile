import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/core/utils/app_date_time.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/drone_technician_errors.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';

// Sự cố rơi kiện phía KTV drone: thẻ trong tab Điều phối và sheet chi tiết
// (`GET /api/drone-technician/drone-incidents[/{id}]`).

const _danger = Color(0xFFDC2626);
const _dark = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);

const _incidentStatusLabels = <String, String>{
  'REPORTED': 'Đã báo sự cố',
  'EVIDENCE_PENDING': 'Chờ bổ sung bằng chứng',
  'INVESTIGATING': 'Đang xác minh',
  'RECOVERY_IN_PROGRESS': 'Đang thu hồi kiện',
  'AWAITING_ADMIN_REVIEW': 'Chờ quản trị xem xét',
  'RESOLUTION_PROPOSED': 'Đã đề xuất cách xử lý',
  'AWAITING_CUSTOMER_RESPONSE': 'Chờ khách phản hồi',
  'RESOLUTION_IN_PROGRESS': 'Đang thực hiện xử lý',
  'DISPUTED': 'Khách yêu cầu xem xét lại',
  'RESOLVED': 'Đã giải quyết',
  'CLOSED': 'Đã đóng',
  'MANUAL_INTERVENTION_REQUIRED': 'Cần can thiệp tay',
};

const _returnFlightLabels = <String, String>{
  'RETURN_REQUESTED': 'Đã yêu cầu drone quay về (RTL)',
  'COMMAND_ACCEPTED': 'Drone đã nhận lệnh RTL',
  'RETURNING': 'Drone đang bay về trạm',
  'COMPLETED': 'Drone đã về trạm',
  'FAILED': 'RTL thất bại',
  'MANUAL_INTERVENTION_REQUIRED': 'Cần can thiệp tay / RTL thủ công',
};

const _parcelStatusLabels = <String, String>{
  'IN_TRANSIT': 'Đang vận chuyển',
  'DROP_REPORTED': 'Đã báo rơi kiện',
  'RECOVERY_PENDING': 'Chờ thu hồi',
  'FOUND': 'Đã tìm thấy',
  'RECOVERED': 'Đã thu hồi',
  'DAMAGED': 'Hư hỏng',
  'LOST': 'Thất lạc',
  'RETURNED_TO_HUB': 'Đã về kho',
  'REDELIVERY_PENDING': 'Chờ giao lại',
  'REDELIVERED': 'Đã giao lại',
  'COMPENSATED': 'Đã bồi thường',
};

const _recoveryStatusLabels = <String, String>{
  'OPEN': 'Chờ xử lý',
  'AWAITING_ASSIGNMENT': 'Chờ phân công KTV tủ',
  'ASSIGNED': 'Đã phân công',
  'ACCEPTED': 'KTV đã nhận',
  'SEARCHING': 'Đang tìm kiện',
  'PARCEL_FOUND': 'Đã tìm thấy kiện',
  'PARCEL_NOT_FOUND': 'Không tìm thấy kiện',
  'RECOVERED': 'Đã thu hồi',
  'SUBMITTED': 'Đã nộp kết quả',
  'VERIFIED': 'Đã xác minh',
  'CLOSED': 'Đã đóng',
  'CANCELLED': 'Đã huỷ',
};

String _label(Map<String, String> labels, dynamic raw) {
  final key = '${raw ?? ''}'.trim().toUpperCase();
  if (key.isEmpty) return '—';
  return labels[key] ?? key;
}

String droneIncidentStatusLabel(dynamic raw) =>
    _label(_incidentStatusLabels, raw);
String droneReturnFlightLabel(dynamic raw) => _label(_returnFlightLabels, raw);

/// Sự cố còn việc phải theo dõi (chưa giải quyết/đóng).
bool droneIncidentActive(Map<String, dynamic> incident) {
  final status = '${incident['status'] ?? ''}'.toUpperCase();
  return status != 'RESOLVED' && status != 'CLOSED';
}

/// Drone không tự quay về được: KTV phải đưa drone về bằng tay.
bool droneIncidentNeedsManualReturn(Map<String, dynamic> incident) =>
    '${incident['returnFlightStatus']}'.toUpperCase() ==
        'MANUAL_INTERVENTION_REQUIRED' ||
    '${incident['status']}'.toUpperCase() == 'MANUAL_INTERVENTION_REQUIRED';

class DroneManualReturnBanner extends StatelessWidget {
  const DroneManualReturnBanner({super.key});

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('drone-incident-manual-return'),
    width: double.infinity,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: _danger.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _danger.withValues(alpha: 0.4)),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.pan_tool_alt_outlined, color: _danger, size: 18),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Cần can thiệp tay / RTL thủ công: hệ thống không đưa drone về được. '
            'Điều khiển drone về trạm bằng kênh điều khiển riêng của đội bay rồi '
            'báo quản trị.',
            style: TextStyle(
              fontSize: 12,
              color: _danger,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class DroneParcelIncidentCard extends StatelessWidget {
  const DroneParcelIncidentCard({
    super.key,
    required this.incident,
    required this.onTap,
  });

  final Map<String, dynamic> incident;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final code = '${incident['incidentCode'] ?? 'Sự cố #${incident['id']}'}';
    final orderCode = incident['orderCode'] ?? 'Đơn #${incident['orderId']}';
    final drone = incident['droneCode'] ?? '—';
    final createdAt = parseServerDateTime(incident['createdAt']);
    final manual = droneIncidentNeedsManualReturn(incident);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _danger.withValues(alpha: manual ? 0.6 : 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.report_gmailerrorred_outlined,
                      color: _danger,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$code · $orderCode',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: _dark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Drone $drone · ${droneIncidentStatusLabel(incident['status'])}',
                  style: const TextStyle(fontSize: 12, color: _muted),
                ),
                if (incident['returnFlightStatus'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Quay về: ${droneReturnFlightLabel(incident['returnFlightStatus'])}',
                    style: const TextStyle(fontSize: 12, color: _muted),
                  ),
                ],
                if (createdAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Báo lúc ${formatDateTimeVn(createdAt)}',
                    style: const TextStyle(fontSize: 11, color: _muted),
                  ),
                ],
                if (manual) ...[
                  const SizedBox(height: 8),
                  const DroneManualReturnBanner(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Chi tiết một sự cố rơi kiện: trạng thái từng mảng, vị trí báo rơi, dòng thời gian.
class DroneParcelIncidentSheet extends StatefulWidget {
  const DroneParcelIncidentSheet({
    super.key,
    required this.incident,
    required this.service,
  });

  final Map<String, dynamic> incident;
  final LockerOpsService service;

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> incident,
    required LockerOpsService service,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) => DroneParcelIncidentSheet(incident: incident, service: service),
  );

  @override
  State<DroneParcelIncidentSheet> createState() =>
      _DroneParcelIncidentSheetState();
}

class _DroneParcelIncidentSheetState extends State<DroneParcelIncidentSheet> {
  late Map<String, dynamic> _incident = widget.incident;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = int.tryParse('${widget.incident['id']}');
    if (id == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await widget.service.droneIncident(id);
      if (!mounted) return;
      setState(() {
        if (detail.isNotEmpty) _incident = detail;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = droneTechnicianErrorMessage(
          error,
          unsupported: 'Máy chủ chưa hỗ trợ xem chi tiết sự cố.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final incident = _incident;
    final lat = incident['dropLatitude'];
    final lng = incident['dropLongitude'];
    final timeline = (incident['timeline'] is List)
        ? (incident['timeline'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList(growable: false)
        : const <Map<String, dynamic>>[];
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .8,
      maxChildSize: .95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        children: [
          Text(
            'Sự cố rơi kiện ${incident['incidentCode'] ?? ''}'.trim(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            '${incident['orderCode'] ?? 'Đơn #${incident['orderId']}'} · '
            'Drone ${incident['droneCode'] ?? '—'}',
            style: const TextStyle(fontSize: 12, color: _muted),
          ),
          if (_loading) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(minHeight: 2),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(fontSize: 12, color: _danger)),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Thử lại'),
              ),
            ),
          ],
          if (droneIncidentNeedsManualReturn(incident)) ...[
            const SizedBox(height: 12),
            const DroneManualReturnBanner(),
          ],
          const SizedBox(height: 14),
          _row('Trạng thái', droneIncidentStatusLabel(incident['status'])),
          _row('Quay về', droneReturnFlightLabel(incident['returnFlightStatus'])),
          _row('Kiện hàng', _label(_parcelStatusLabels, incident['parcelStatus'])),
          _row(
            'Thu hồi kiện',
            _label(_recoveryStatusLabels, incident['recoveryStatus']),
          ),
          _row('Mô tả', '${incident['reason'] ?? '—'}'),
          _row(
            'Vị trí báo rơi',
            lat is num && lng is num && (lat != 0 || lng != 0)
                ? '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}'
                      '${incident['telemetryStale'] == true ? ' (telemetry cũ)' : ''}'
                : 'Không có toạ độ',
          ),
          _row('Camera', '${incident['cameraStatus'] ?? '—'}'),
          if (timeline.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Dòng thời gian',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            for (final event in timeline) _timelineRow(event),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: _muted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: _dark,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _timelineRow(Map<String, dynamic> event) {
    final at = parseServerDateTime(event['createdAt']);
    final note = '${event['note'] ?? ''}'.trim();
    final change = [
      event['fromStatus'],
      event['toStatus'],
    ].where((value) => value != null && '$value'.isNotEmpty).join(' → ');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              if (at != null) formatDateTimeVn(at),
              if (change.isNotEmpty) change,
            ].join(' · '),
            style: const TextStyle(fontSize: 11, color: _muted),
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(note, style: const TextStyle(fontSize: 12.5, color: _dark)),
          ],
        ],
      ),
    );
  }
}
