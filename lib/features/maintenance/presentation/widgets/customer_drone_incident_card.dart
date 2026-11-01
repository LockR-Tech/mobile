import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/core/utils/app_date_time.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_incident_labels.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/drone_error_messages.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/payment/data/payment_service.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// Thẻ sự cố rơi kiện của một đơn drone trên màn theo dõi của khách: trạng
/// thái xử lý, nhật ký gần nhất và phương án Lock.R đề xuất để khách phản hồi.
class CustomerDroneIncidentCard extends StatefulWidget {
  const CustomerDroneIncidentCard({
    super.key,
    required this.orderId,
    this.refreshKey,
    this.expectIncident = false,
    this.service,
  });

  final int orderId;

  /// Đổi giá trị (vd. chặng giao của đơn) ⇒ tải lại thẻ.
  final Object? refreshKey;

  /// Đơn đang ở chặng sự cố: lỗi tải thì báo rõ; ngược lại lỗi tải được bỏ
  /// qua để đơn bình thường không hiện thẻ lỗi thừa.
  final bool expectIncident;
  final LockerOpsService? service;

  @override
  State<CustomerDroneIncidentCard> createState() =>
      _CustomerDroneIncidentCardState();
}

class _CustomerDroneIncidentCardState extends State<CustomerDroneIncidentCard> {
  late final LockerOpsService _service = widget.service ?? LockerOpsService();
  Map<String, dynamic>? _incident;
  bool _loading = true;
  bool _responding = false;
  bool _hasBankAccount = true;
  String? _error;
  int? _myUserId;
  Timer? _poll;

  /// Chặng đơn đứng yên ở DROP_REPORTED suốt lúc xử lý sự cố nên [refreshKey] không đổi khi KTV báo kết quả,
  /// admin gửi phương án… ⇒ tự tải lại định kỳ khi sự cố còn mở.
  static const _pollInterval = Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    TokenService.getUserId().then((id) {
      if (mounted) setState(() => _myUserId = int.tryParse(id ?? ''));
    });
    _load();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  bool _incidentOpen(Map<String, dynamic>? incident) {
    if (incident == null) return widget.expectIncident;
    final status = '${incident['status'] ?? ''}'.toUpperCase();
    return status != 'RESOLVED' && status != 'CLOSED';
  }

  void _schedulePoll() {
    final open = _incidentOpen(_incident);
    if (!open) {
      _poll?.cancel();
      _poll = null;
      return;
    }
    _poll ??= Timer.periodic(_pollInterval, (_) {
      if (mounted && !_responding) _load(quiet: true);
    });
  }

  @override
  void didUpdateWidget(covariant CustomerDroneIncidentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshKey != widget.refreshKey ||
        oldWidget.orderId != widget.orderId) {
      _load(quiet: true);
    }
  }

  Future<void> _load({bool quiet = false}) async {
    if (mounted && !quiet) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final all = await _service.myDroneIncidents();
      final incident = all.cast<Map<String, dynamic>?>().firstWhere(
        (item) => '${item?['orderId']}' == '${widget.orderId}',
        orElse: () => null,
      );
      bool hasBank = true;
      try {
        final bankAcc = await PaymentService().getSavedBankAccount();
        hasBank = bankAcc != null && bankAcc.accountNumber.trim().isNotEmpty;
      } catch (_) {
        hasBank = true;
      }
      if (mounted) {
        setState(() {
          _incident = incident;
          _hasBankAccount = hasBank;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = droneCustomerErrorMessage(error));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _schedulePoll();
      }
    }
  }

  /// Phương án mới nhất theo `version` (server cũ: `proposalVersion`).
  static Map? _latestProposal(List<Map> proposals) {
    Map? latest;
    var best = -1;
    for (final p in proposals) {
      final v = _asInt(p['version'] ?? p['proposalVersion']) ?? 0;
      if (latest == null || v >= best) {
        latest = p;
        best = v;
      }
    }
    return latest;
  }

  static int? _asInt(Object? v) => v is num ? v.toInt() : int.tryParse('$v');

  @override
  Widget build(BuildContext context) {
    if (_loading && _incident == null) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }
    if (_error != null && _incident == null) {
      if (!widget.expectIncident) return const SizedBox.shrink();
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: ListTile(
          leading: const Icon(Icons.cloud_off_outlined),
          title: Text(context.l10n.cdiLoadFailed),
          subtitle: Text(_error!),
          trailing: IconButton(
            tooltip: context.l10n.commonRetry,
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ),
      );
    }
    if (_incident == null) return const SizedBox.shrink();
    final incident = _incident!;
    final proposals =
        (incident['proposals'] as List?)?.whereType<Map>().toList() ?? const [];
    final latest = _latestProposal(proposals);
    final timeline =
        (incident['timeline'] as List?)?.whereType<Map>().toList() ?? const [];
    // Không hiện `reason`: đó là lời báo nội bộ của đội bay / admin (test 2026-10-29 khách đọc được
    // "Admin quan sat thay kien roi … (test E2E …)"). Khách cần ghi chú hiện trường và ảnh thu hồi để
    // chọn phương án.
    final fieldNote = '${incident['recoveryNote'] ?? ''}'.trim();
    final recoveryPhotos = ((incident['evidence'] as List?) ?? const [])
        .whereType<Map>()
        .where((e) => '${e['stage']}'.toUpperCase() == 'RECOVERY')
        .map((e) => '${e['secureUrl'] ?? e['url'] ?? ''}')
        .where((url) => url.startsWith('http'))
        .toList();
    // Chỉ người gửi (chủ đơn) quyết định phương án — tiền bồi thường về tài khoản người gửi; server cũng chặn.
    final isSender =
        _myUserId != null && _asInt(incident['customerUserId']) == _myUserId;
    final awaitingResponse =
        isSender &&
        latest != null &&
        '${latest['status']}'.toUpperCase() == 'AWAITING_CUSTOMER_ACCEPTANCE';
    final awaitingSender = !isSender &&
        latest != null &&
        '${latest['status']}'.toUpperCase() == 'AWAITING_CUSTOMER_ACCEPTANCE';
    final open = _incidentOpen(incident);
    // Chỉ cho "Yêu cầu xem xét" khi chính sách của đơn cho phép.
    final disputeAllowed = incident['disputeAllowed'] == true;
    final hasCompensation = latest != null &&
        (latest['resolutionType'] == 'COMPENSATION_ONLY' ||
            latest['resolutionType'] == 'REDELIVERY_PARTIAL_COMPENSATION' ||
            (_asInt(latest['compensationAmount']) ?? 0) > 0);
    final compensationActive = hasCompensation ||
        ['AWAITING_APPROVAL', 'PAYMENT_PENDING', 'PENDING', 'ACCEPTED']
            .contains('${incident['compensationStatus']}'.toUpperCase());
    final showBankWarning = isSender && compensationActive && !_hasBankAccount;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: const Color(0xFFFFF7ED),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFFED7AA)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  open
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline,
                  color: open
                      ? const Color(0xFFEA580C)
                      : const Color(0xFF16A34A),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    open
                        ? context.l10n.cdiInProgress
                      : context.l10n.cdiResolved,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (incident['incidentCode'] != null)
              _Line(context.l10n.cdiCode, '${incident['incidentCode']}'),
            _Line(context.l10n.commonStatus, droneIncidentStatusLabel(incident['status'])),
            _Line(
              context.l10n.cdiRecovery,
              droneRecoveryStatusLabel(incident['recoveryStatus']),
            ),
            _Line(
              context.l10n.cdiParcelState,
              droneParcelStateLabel(
                incident['parcelStatus'],
                incident['parcelCondition'],
              ),
            ),
            if (fieldNote.isNotEmpty)
              _Line(context.l10n.cdiFieldNote, fieldNote),
            if (recoveryPhotos.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                context.l10n.cdiRecoveryPhotos,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final url in recoveryPhotos)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        url,
                        width: 96,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox(
                          width: 96,
                          height: 72,
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if (timeline.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                context.l10n.cdiLastUpdate,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              for (final event in timeline.reversed.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    '• ${droneIncidentEventLabel(event['eventType'])} · ${_time(event['createdAt'])}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
            if (latest != null) ...[
              const Divider(height: 24),
              Text(
                '${context.l10n.cdiProposal}'
                '${_asInt(latest['version'] ?? latest['proposalVersion']) == null ? '' : context.l10n.cdiProposalVersion(_asInt(latest['version'] ?? latest['proposalVersion'])!)}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              Text(_proposalText(latest), style: const TextStyle(fontSize: 13)),
              if ('${latest['resolutionNote'] ?? ''}'.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  context.l10n.cdiContent('${latest['resolutionNote']}'.trim()),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
              const SizedBox(height: 2),
              Text(
                droneProposalStatusLabel(latest['status']),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF9A3412),
                ),
              ),
              if ('${latest['policyVersion'] ?? ''}'.trim().isNotEmpty)
                Text(
                  context.l10n.cdiPolicy,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              if (showBankWarning) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_outlined,
                            size: 20,
                            color: Color(0xFFDC2626),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.l10n.cdiNoBank,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF991B1B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.cdiNoBankBody,
                        style: TextStyle(fontSize: 12, color: Color(0xFF7F1D1D)),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          key: const ValueKey('drone-incident-add-bank-btn'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () async {
                            await context.push(AppRouter.refundBankAccount);
                            _load(quiet: true);
                          },
                          icon: const Icon(Icons.arrow_forward, size: 16),
                          label: Text(
                            context.l10n.cdiUpdateBank,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (awaitingSender) ...[
                const SizedBox(height: 10),
                Text(
                  context.l10n.cdiSenderDecides,
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
              if (awaitingResponse) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (disputeAllowed) ...[
                      Expanded(
                        child: OutlinedButton(
                          key: const ValueKey('drone-incident-review'),
                          onPressed: _responding
                              ? null
                              : () => _respond('REQUEST_REVIEW'),
                          child: Text(context.l10n.cdiRequestReview),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: FilledButton(
                        key: const ValueKey('drone-incident-accept'),
                        onPressed: _responding ? null : () => _respond('ACCEPT'),
                        child: Text(context.l10n.cdiAccept),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _respond(String decision) async {
    final note = TextEditingController();
    final accept = decision == 'ACCEPT';
    String? noteError;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            accept ? context.l10n.cdiAcceptQuestion : context.l10n.cdiReviewQuestion,
          ),
          content: TextField(
            controller: note,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: accept
                  ? context.l10n.cdiNoteOptional
                  : context.l10n.cdiReviewReason,
              errorText: noteError,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () {
                // Lý do bắt buộc khi xin xem xét: báo ngay trong hộp, không đóng hộp rồi mới báo.
                if (!accept && note.text.trim().isEmpty) {
                  setDialogState(
                    () => noteError = context.l10n.cdiEnterReason,
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              child: Text(context.l10n.commonConfirm),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) {
      WidgetsBinding.instance.addPostFrameCallback((_) => note.dispose());
      return;
    }
    final incidentId = _asInt(_incident?['id']);
    if (incidentId == null) {
      note.dispose();
      return;
    }
    setState(() => _responding = true);
    try {
      await _service.respondDroneIncident(
        incidentId,
        decision: decision,
        note: note.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accept
                  ? context.l10n.cdiAccepted
                  : context.l10n.cdiReviewSent,
            ),
          ),
        );
      }
      await _load(quiet: true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(droneCustomerErrorMessage(error))),
        );
      }
    } finally {
      note.dispose();
      if (mounted) setState(() => _responding = false);
    }
  }

  static String _proposalText(Map proposal) {
    final amount = (proposal['compensationAmount'] as num?)?.toDouble() ?? 0;
    final money = '${NumberFormat.decimalPattern('vi_VN').format(amount)}đ';
    final parts = <String>[
      droneResolutionTypeLabel(proposal['resolutionType']),
      if (amount > 0) L10n.current.cdiCompensation(money),
      // "Giao lại miễn phí" đã là tên loại phương án ⇒ không lặp lại.
      if (proposal['redeliveryOffered'] == true &&
          proposal['resolutionType'] != 'FREE_REDELIVERY')
        L10n.current.cdiFreeRedelivery,
      if (proposal['refundShippingFee'] == true) L10n.current.cdiRefundShipping,
    ];
    return parts.join(' · ');
  }

  static String _time(dynamic value) {
    final parsed = parseServerDateTime(value);
    return parsed == null ? '—' : DateFormat('dd/MM HH:mm').format(parsed);
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF9A3412)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
