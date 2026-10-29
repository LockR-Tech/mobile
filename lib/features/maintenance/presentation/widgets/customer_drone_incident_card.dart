import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/utils/app_date_time.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_incident_labels.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/drone_error_messages.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/payment/data/payment_service.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
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
      if (mounted) setState(() => _loading = false);
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
          title: const Text('Chưa tải được thông tin sự cố của đơn'),
          subtitle: Text(_error!),
          trailing: IconButton(
            tooltip: 'Thử lại',
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
    final reason = '${incident['reason'] ?? ''}'.trim();
    final awaitingResponse =
        latest != null &&
        '${latest['status']}'.toUpperCase() == 'AWAITING_CUSTOMER_ACCEPTANCE';
    // Chỉ cho "Yêu cầu xem xét" khi chính sách của đơn cho phép.
    final disputeAllowed = incident['disputeAllowed'] == true;
    final hasCompensation = latest != null &&
        (latest['resolutionType'] == 'COMPENSATION_ONLY' ||
            latest['resolutionType'] == 'REDELIVERY_PARTIAL_COMPENSATION' ||
            (_asInt(latest['compensationAmount']) ?? 0) > 0);
    final compensationActive = hasCompensation ||
        ['AWAITING_APPROVAL', 'PAYMENT_PENDING', 'PENDING', 'ACCEPTED']
            .contains('${incident['compensationStatus']}'.toUpperCase());
    final showBankWarning = compensationActive && !_hasBankAccount;
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
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFEA580C)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sự cố rơi kiện đang được xử lý',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (incident['incidentCode'] != null)
              _Line('Mã sự cố', '${incident['incidentCode']}'),
            _Line('Trạng thái', droneIncidentStatusLabel(incident['status'])),
            _Line(
              'Thu hồi kiện',
              droneRecoveryStatusLabel(incident['recoveryStatus']),
            ),
            _Line(
              'Tình trạng kiện',
              droneParcelStateLabel(
                incident['parcelStatus'],
                incident['parcelCondition'],
              ),
            ),
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                reason,
                style: const TextStyle(fontSize: 13, color: Color(0xFF7C2D12)),
              ),
            ],
            if (timeline.isNotEmpty) ...[
              const Divider(height: 24),
              const Text(
                'Cập nhật gần nhất',
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
                'Phương án xử lý'
                '${_asInt(latest['version'] ?? latest['proposalVersion']) == null ? '' : ' (lần ${_asInt(latest['version'] ?? latest['proposalVersion'])})'}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              Text(_proposalText(latest), style: const TextStyle(fontSize: 13)),
              if ('${latest['resolutionNote'] ?? ''}'.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Nội dung: ${'${latest['resolutionNote']}'.trim()}',
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
                  'Áp dụng chính sách sự cố tại thời điểm bạn đặt đơn',
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
                      const Row(
                        children: [
                          Icon(
                            Icons.account_balance_outlined,
                            size: 20,
                            color: Color(0xFFDC2626),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Chưa có tài khoản ngân hàng nhận bồi thường',
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
                      const Text(
                        'Phương án giải quyết có khoản hoàn tiền/bồi thường. Bạn cần liên kết tài khoản ngân hàng để hệ thống thực hiện chuyển khoản.',
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
                          label: const Text(
                            'Cập nhật tài khoản ngân hàng',
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
                          child: const Text('Yêu cầu xem xét'),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: FilledButton(
                        key: const ValueKey('drone-incident-accept'),
                        onPressed: _responding ? null : () => _respond('ACCEPT'),
                        child: const Text('Đồng ý'),
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
            accept ? 'Đồng ý phương án?' : 'Yêu cầu Lock.R xem xét lại?',
          ),
          content: TextField(
            controller: note,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: accept
                  ? 'Ghi chú (không bắt buộc)'
                  : 'Lý do cần xem xét *',
              errorText: noteError,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                // Lý do bắt buộc khi xin xem xét: báo ngay trong hộp, không đóng hộp rồi mới báo.
                if (!accept && note.text.trim().isEmpty) {
                  setDialogState(
                    () => noteError = 'Vui lòng nhập lý do cần xem xét.',
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Xác nhận'),
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
                  ? 'Đã ghi nhận phương án bạn chọn.'
                  : 'Đã gửi yêu cầu xem xét lại.',
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
      if (amount > 0) 'Bồi thường $money',
      // "Giao lại miễn phí" đã là tên loại phương án ⇒ không lặp lại.
      if (proposal['redeliveryOffered'] == true &&
          proposal['resolutionType'] != 'FREE_REDELIVERY')
        'giao lại miễn phí',
      if (proposal['refundShippingFee'] == true) 'hoàn phí giao',
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
