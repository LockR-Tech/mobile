import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/core/utils/app_date_time.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_incident_labels.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/drone_technician_errors.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/maintenance/presentation/widgets/drone_recovery_queue.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

// Sự cố rơi kiện phía KTV drone: thẻ trong tab Điều phối và sheet chi tiết
// (`GET /api/drone-technician/drone-incidents[/{id}]`).

const _danger = Color(0xFFDC2626);
const _dark = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);

Map<String, String> get _incidentStatusLabels => <String, String>{
  'REPORTED': L10n.current.incStReported,
  'EVIDENCE_PENDING': L10n.current.incStEvidencePending,
  'INVESTIGATING': L10n.current.incStInvestigating,
  'RECOVERY_IN_PROGRESS': L10n.current.incStRecoveryInProgress,
  'AWAITING_ADMIN_REVIEW': L10n.current.incStAwaitingAdmin,
  'RESOLUTION_PROPOSED': L10n.current.incStResolutionProposed,
  'AWAITING_CUSTOMER_RESPONSE': L10n.current.incStAwaitingCustomer,
  'RESOLUTION_IN_PROGRESS': L10n.current.incStResolutionInProgress,
  'DISPUTED': L10n.current.incStDisputed,
  'RESOLVED': L10n.current.incStResolved,
  'CLOSED': L10n.current.incStClosed,
  'MANUAL_INTERVENTION_REQUIRED': L10n.current.incStManual,
};

Map<String, String> get _returnFlightLabels => <String, String>{
  'RETURN_REQUESTED': L10n.current.dtRtlRequested,
  'COMMAND_ACCEPTED': L10n.current.dtRtlAccepted,
  'RETURNING': L10n.current.dtRtlReturning,
  'COMPLETED': L10n.current.dtRtlCompleted,
  'FAILED': L10n.current.dtRtlFailed,
  'MANUAL_INTERVENTION_REQUIRED': L10n.current.dtRtlManual,
};

Map<String, String> get _parcelStatusLabels => <String, String>{
  'IN_TRANSIT': L10n.current.parStInTransit,
  'DROP_REPORTED': L10n.current.parStDropReported,
  'RECOVERY_PENDING': L10n.current.parStRecoveryPending,
  'FOUND': L10n.current.parStFound,
  'RECOVERED': L10n.current.parStRecovered,
  'DAMAGED': L10n.current.parStDamaged,
  'LOST': L10n.current.parStLost,
  'RETURNED_TO_HUB': L10n.current.parStReturnedToHub,
  'REDELIVERY_PENDING': L10n.current.parStRedeliveryPending,
  'REDELIVERED': L10n.current.parStRedelivered,
  'COMPENSATED': L10n.current.parStCompensated,
};

Map<String, String> get _recoveryStatusLabels => <String, String>{
  'OPEN': L10n.current.recStOpen,
  'AWAITING_ASSIGNMENT': L10n.current.recStAwaitingAssignment,
  'ASSIGNED': L10n.current.recStAssigned,
  'ACCEPTED': L10n.current.recStAccepted,
  'SEARCHING': L10n.current.recStSearching,
  'PARCEL_FOUND': L10n.current.recStFound,
  'PARCEL_NOT_FOUND': L10n.current.recStNotFound,
  'RECOVERED': L10n.current.recStRecovered,
  'SUBMITTED': L10n.current.recStSubmitted,
  'VERIFIED': L10n.current.recStVerified,
  'CLOSED': L10n.current.recStClosed,
  'CANCELLED': L10n.current.recStCancelled,
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
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.pan_tool_alt_outlined, color: _danger, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            context.l10n.dtManualReturnBanner,
            style: const TextStyle(
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
    final code = '${incident['incidentCode'] ?? context.l10n.dtIncidentNumber('${incident['id']}')}';
    final orderCode = incident['orderCode'] ?? context.l10n.dtOrderNumber('${incident['orderId']}');
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
                  context.l10n.dtIncDroneStatus('$drone', droneIncidentStatusLabel(incident['status'])),
                  style: const TextStyle(fontSize: 12, color: _muted),
                ),
                if (incident['returnFlightStatus'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.dtIncReturn(droneReturnFlightLabel(incident['returnFlightStatus'])),
                    style: const TextStyle(fontSize: 12, color: _muted),
                  ),
                ],
                if (createdAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.dtIncReportedAt(formatDateTimeVn(createdAt)),
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
  int? _myUserId;

  @override
  void initState() {
    super.initState();
    TokenService.getUserId().then((id) {
      if (mounted) setState(() => _myUserId = int.tryParse(id ?? ''));
    });
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
          unsupported: L10n.current.dtIncDetailUnsupported,
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
            context.l10n.dtIncSheetTitle('${incident['incidentCode'] ?? ''}').trim(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            '${incident['orderCode'] ?? context.l10n.dtOrderNumber('${incident['orderId']}')} · '
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
                label: Text(context.l10n.commonRetry),
              ),
            ),
          ],
          if (droneIncidentNeedsManualReturn(incident)) ...[
            const SizedBox(height: 12),
            const DroneManualReturnBanner(),
          ],
          const SizedBox(height: 14),
          _row(context.l10n.dtIncStatusRow, droneIncidentStatusLabel(incident['status'])),
          _row(context.l10n.dtIncReturnRow, droneReturnFlightLabel(incident['returnFlightStatus'])),
          _row(
            context.l10n.dtIncParcelRow,
            incident['parcelCondition'] != null
                ? droneParcelStateLabel(
                    incident['parcelStatus'],
                    incident['parcelCondition'],
                  )
                : _label(_parcelStatusLabels, incident['parcelStatus']),
          ),
          _row(
            context.l10n.dtIncRecoveryRow,
            _label(_recoveryStatusLabels, incident['recoveryStatus']),
          ),
          _row(context.l10n.dtIncDescriptionRow, '${incident['reason'] ?? '—'}'),
          _row(
            context.l10n.dtIncDropLocationRow,
            lat is num && lng is num && (lat != 0 || lng != 0)
                ? '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}'
                      '${incident['telemetryStale'] == true ? context.l10n.dtIncTelemetryStale : ''}'
                : context.l10n.dtIncNoCoordinates,
          ),
          _row('Camera', '${incident['cameraStatus'] ?? '—'}'),
          if ('${incident['recoveryStationName'] ?? ''}'.trim().isNotEmpty &&
              '${incident['recoveryStationName']}' != 'null')
            _row(
              context.l10n.dtIncRecoveryStationRow,
              '${incident['recoveryStationName']}'
                  '${incident['recoveryStationDroneAvailable'] == false ? context.l10n.dtIncWaitingDrone : ''}',
            ),
          // Chỉ KTV được giao thu hồi mới thao tác được nhiệm vụ (server trả 403 cho người khác).
          if (incident['id'] != null &&
              _myUserId != null &&
              '${incident['recoveryAssignedToUserId']}' == '$_myUserId' &&
              ['ASSIGNED', 'ACCEPTED', 'SEARCHING', 'PARCEL_FOUND', 'VERIFIED']
                  .contains('${incident['recoveryStatus']}'.toUpperCase())) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                final id = int.tryParse('${incident['id']}');
                if (id == null) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(
                        title: Text(
                          context.l10n.dtIncRecoveryTitle('${incident['incidentCode'] ?? '#$id'}'),
                        ),
                      ),
                      body: SafeArea(
                        child: DroneRecoveryDetail(
                          incidentId: id,
                          service: widget.service,
                        ),
                      ),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.travel_explore_outlined),
              label: Text(
                context.l10n.dtIncOpenRecovery,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
          if (timeline.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              context.l10n.dtIncTimeline,
              style: const TextStyle(fontWeight: FontWeight.w800),
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
