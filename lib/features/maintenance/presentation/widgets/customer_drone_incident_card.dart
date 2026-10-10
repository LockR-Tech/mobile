import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';

class CustomerDroneIncidentCard extends StatefulWidget {
  const CustomerDroneIncidentCard({super.key, required this.orderId});
  final int orderId;
  @override
  State<CustomerDroneIncidentCard> createState() =>
      _CustomerDroneIncidentCardState();
}

class _CustomerDroneIncidentCardState extends State<CustomerDroneIncidentCard> {
  final _service = LockerOpsService();
  Map<String, dynamic>? _incident;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
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
      if (mounted) setState(() => _incident = incident);
    } catch (error) {
      if (mounted) {
        setState(() => _error = LockerOpsService.errorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }
    if (_error != null) {
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: ListTile(
          leading: const Icon(Icons.cloud_off_outlined),
          title: const Text('Chưa tải được trạng thái sự cố drone'),
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
    final latest = proposals.isEmpty ? null : proposals.last;
    final timeline =
        (incident['timeline'] as List?)?.whereType<Map>().toList() ?? const [];
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
            _Line('Mã sự cố', '${incident['incidentCode']}'),
            _Line('Trạng thái', _label('${incident['status']}')),
            _Line('Thu hồi kiện', _label('${incident['recoveryStatus']}')),
            _Line('Tình trạng kiện', _label('${incident['parcelStatus']}')),
            const SizedBox(height: 8),
            Text(
              '${incident['reason']}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF7C2D12)),
            ),
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
                    '• ${_label('${event['eventType']}')} · ${_time(event['createdAt'])}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
            if (latest != null) ...[
              const Divider(height: 24),
              Text(
                'Phương án #${latest['proposalVersion']}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              Text(_proposalText(latest), style: const TextStyle(fontSize: 13)),
              Text(
                'Chính sách áp dụng khi đặt đơn: ${latest['policyVersion']}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              if (latest['status'] == 'AWAITING_CUSTOMER_ACCEPTANCE') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _respond('REQUEST_REVIEW'),
                        child: const Text('Yêu cầu xem xét'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _respond('ACCEPT'),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          accept ? 'Đồng ý phương án?' : 'Yêu cầu Admin xem xét lại?',
        ),
        content: TextField(
          controller: note,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: accept
                ? 'Ghi chú (không bắt buộc)'
                : 'Lý do cần xem xét *',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (confirmed != true || (!accept && note.text.trim().isEmpty)) {
      note.dispose();
      return;
    }
    try {
      await _service.respondDroneIncident(
        (_incident!['id'] as num).toInt(),
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
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LockerOpsService.errorMessage(error))),
        );
      }
    } finally {
      note.dispose();
    }
  }

  static String _proposalText(Map proposal) {
    final amount = (proposal['compensationAmount'] as num?)?.toDouble() ?? 0;
    final money = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    ).format(amount);
    return '${_label('${proposal['resolutionType']}')} · Bồi thường $money${proposal['redeliveryOffered'] == true ? ' · giao lại miễn phí' : ''}';
  }

  static String _label(String value) => value
      .replaceAll('_', ' ')
      .toLowerCase()
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
  static String _time(dynamic value) {
    final parsed = DateTime.tryParse('$value');
    return parsed == null
        ? '$value'
        : DateFormat('dd/MM HH:mm').format(parsed.toLocal());
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
