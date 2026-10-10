import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smart_laundry_locker/core/media/photo_picker_controller.dart';
import 'package:smart_laundry_locker/core/media/widgets/photo_picker_field.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:url_launcher/url_launcher.dart';

class DroneRecoveryQueue extends StatelessWidget {
  const DroneRecoveryQueue({
    super.key,
    required this.items,
    required this.service,
    required this.onRefresh,
  });

  final List<Map<String, dynamic>> items;
  final LockerOpsService service;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onRefresh,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      children: [
        const _Banner(),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 64),
            child: Column(
              children: [
                Icon(
                  Icons.travel_explore_outlined,
                  size: 48,
                  color: Color(0xFF94A3B8),
                ),
                SizedBox(height: 10),
                Text(
                  'Chưa có nhiệm vụ thu hồi kiện',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 4),
                Text(
                  'Nhiệm vụ được phân công sẽ xuất hiện tại đây.',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          )
        else
          for (final item in items) ...[
            _RecoveryCard(
              item: item,
              onTap: () async {
                await showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  backgroundColor: const Color(0xFFF8FAFC),
                  builder: (_) => FractionallySizedBox(
                    heightFactor: .92,
                    child: DroneRecoveryDetail(
                      incidentId: (item['id'] as num).toInt(),
                      service: service,
                    ),
                  ),
                );
                await onRefresh();
              },
            ),
            const SizedBox(height: 10),
          ],
      ],
    ),
  );
}

class _Banner extends StatelessWidget {
  const _Banner();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFFE0F2FE),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFBAE6FD)),
    ),
    child: const Row(
      children: [
        Icon(Icons.info_outline, color: Color(0xFF0369A1)),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Thu hồi kiện theo vị trí rơi đã xác minh. Phải chụp ảnh thật, ghi GPS và tình trạng kiện trước khi gửi Admin duyệt.',
            style: TextStyle(fontSize: 12, color: Color(0xFF075985)),
          ),
        ),
      ],
    ),
  );
}

class _RecoveryCard extends StatelessWidget {
  const _RecoveryCard({required this.item, required this.onTap});
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final status = '${item['recoveryStatus'] ?? 'OPEN'}';
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item['incidentCode'] ?? 'Sự cố #${item['id']}'}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  _Pill(status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${item['orderCode'] ?? 'Đơn #${item['orderId']}'} · ${item['droneCode'] ?? 'Drone'}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 5),
              Text(
                '${item['reason'] ?? ''}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Color(0xFF0284C7),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _location(item),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _location(Map<String, dynamic> item) => item['dropLatitude'] == null
      ? 'Không có GPS · kiểm tra bằng chứng trước khi đi'
      : '${item['dropLatitude']}, ${item['dropLongitude']}';
}

class DroneRecoveryDetail extends StatefulWidget {
  const DroneRecoveryDetail({
    super.key,
    required this.incidentId,
    required this.service,
  });
  final int incidentId;
  final LockerOpsService service;
  @override
  State<DroneRecoveryDetail> createState() => _DroneRecoveryDetailState();
}

class _DroneRecoveryDetailState extends State<DroneRecoveryDetail> {
  Map<String, dynamic>? _item;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final item = await widget.service.droneRecovery(widget.incidentId);
      if (mounted) {
        setState(() {
          _item = item;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = LockerOpsService.errorMessage(error));
      }
    }
  }

  Future<void> _action(String action) async {
    setState(() => _busy = true);
    try {
      await widget.service.updateDroneRecovery(widget.incidentId, action);
      await _load();
    } catch (error) {
      if (mounted) _message(LockerOpsService.errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final item = _item;
    if (item == null) {
      return Center(
        child: _error == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!),
                  TextButton(onPressed: _load, child: const Text('Thử lại')),
                ],
              ),
      );
    }
    final status = '${item['recoveryStatus']}';
    final evidence =
        (item['evidence'] as List?)?.whereType<Map>().toList() ?? const [];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
      children: [
        Text(
          '${item['incidentCode']}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          '${item['orderCode']} · ${item['droneCode']}',
          style: const TextStyle(color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [_Pill(status), _Pill('${item['parcelStatus']}')],
        ),
        const SizedBox(height: 14),
        _Info(title: 'Tình huống', value: '${item['reason']}'),
        const SizedBox(height: 10),
        _Info(
          title: 'Độ chính xác dữ liệu',
          value:
              'Nguồn GPS: ${item['gpsSource']} · sai số ${item['gpsAccuracyM'] ?? 'không rõ'} m · telemetry ${item['telemetryStale'] == true ? 'đã cũ' : 'trực tuyến'}',
        ),
        if (item['dropLatitude'] != null) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => launchUrl(
              Uri.parse(
                'https://www.google.com/maps/search/?api=1&query=${item['dropLatitude']},${item['dropLongitude']}',
              ),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.directions_outlined),
            label: const Text('Mở chỉ đường tới vị trí rơi'),
          ),
        ],
        if (evidence.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text(
            'Bằng chứng hiện có',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: evidence.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final value = evidence[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    '${value['secureUrl']}',
                    width: 120,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 18),
        if (status == 'ASSIGNED')
          FilledButton(
            onPressed: _busy ? null : () => _action('ACCEPT'),
            child: const Text('Nhận nhiệm vụ'),
          ),
        if (status == 'ACCEPTED')
          FilledButton(
            onPressed: _busy ? null : () => _action('START_SEARCHING'),
            child: const Text('Bắt đầu tìm kiếm'),
          ),
        if (status == 'SEARCHING')
          FilledButton.icon(
            onPressed: _busy ? null : () => _submitSheet(item),
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('Ghi nhận kết quả tìm kiếm'),
          ),
        if (status == 'VERIFIED' && item['recoveryOutcome'] == 'FOUND')
          FilledButton(
            onPressed: _busy ? null : _handover,
            child: const Text('Xác nhận bàn giao kiện về Hub / kho'),
          ),
        if (['SUBMITTED', 'CLOSED'].contains(status))
          const _Info(
            title: 'Kết quả đã gửi',
            value: 'Admin sẽ xác minh bằng chứng và quyết định bước tiếp theo.',
          ),
      ],
    );
  }

  Future<void> _handover() async {
    setState(() => _busy = true);
    try {
      await widget.service.confirmDroneRecoveryHubHandover(widget.incidentId);
      await _load();
      _message('Đã xác nhận kiện về Hub / kho.');
    } catch (error) {
      _message(LockerOpsService.errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitSheet(Map<String, dynamic> item) async {
    final photos = PhotoPickerController(maxPhotos: 5);
    final note = TextEditingController();
    var outcome = 'FOUND';
    var condition = 'INTACT';
    var sending = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setLocal) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Kết quả thu hồi',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: outcome,
                  decoration: const InputDecoration(
                    labelText: 'Kết quả',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'FOUND',
                      child: Text('Đã tìm thấy'),
                    ),
                    DropdownMenuItem(
                      value: 'NOT_FOUND',
                      child: Text('Không tìm thấy'),
                    ),
                    DropdownMenuItem(
                      value: 'UNSAFE',
                      child: Text('Khu vực không an toàn'),
                    ),
                  ],
                  onChanged: (value) =>
                      setLocal(() => outcome = value ?? outcome),
                ),
                if (outcome == 'FOUND') ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: condition,
                    decoration: const InputDecoration(
                      labelText: 'Tình trạng kiện',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'INTACT',
                        child: Text('Nguyên vẹn'),
                      ),
                      DropdownMenuItem(
                        value: 'MINOR_DAMAGE',
                        child: Text('Hư hại nhẹ'),
                      ),
                      DropdownMenuItem(
                        value: 'MAJOR_DAMAGE',
                        child: Text('Hư hại nặng'),
                      ),
                      DropdownMenuItem(
                        value: 'UNUSABLE',
                        child: Text('Không thể sử dụng'),
                      ),
                      DropdownMenuItem(
                        value: 'UNKNOWN',
                        child: Text('Chưa xác định'),
                      ),
                    ],
                    onChanged: (value) =>
                        setLocal(() => condition = value ?? condition),
                  ),
                ],
                const SizedBox(height: 10),
                TextField(
                  controller: note,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú hiện trường',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedBuilder(
                  animation: photos,
                  builder: (_, __) => PhotoPickerField(
                    controller: photos,
                    enabled: !sending,
                    helperText: 'Bắt buộc ít nhất 1 ảnh thật kèm GPS.',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: sending
                      ? null
                      : () async {
                          if (photos.isEmpty) {
                            _message(
                              'Vui lòng chụp ít nhất 1 ảnh hiện trường.',
                            );
                            return;
                          }
                          setLocal(() => sending = true);
                          try {
                            final uploaded = await photos.uploadAll(
                              caption: 'Bằng chứng thu hồi kiện',
                            );
                            Position? position;
                            try {
                              position = await Geolocator.getCurrentPosition(
                                locationSettings: const LocationSettings(
                                  accuracy: LocationAccuracy.high,
                                ),
                              );
                            } catch (_) {}
                            final evidence = uploaded
                                .map(
                                  (value) => {
                                    'media': {
                                      for (final key in [
                                        'publicId',
                                        'version',
                                        'signature',
                                        'format',
                                        'bytes',
                                        'width',
                                        'height',
                                      ])
                                        if (value[key] != null) key: value[key],
                                    },
                                    'caption': value['caption'],
                                    'capturedAt': DateTime.now()
                                        .toUtc()
                                        .toIso8601String(),
                                    if (position != null) ...{
                                      'latitude': position.latitude,
                                      'longitude': position.longitude,
                                      'gpsAccuracyM': position.accuracy,
                                    },
                                  },
                                )
                                .toList();
                            await widget.service.submitDroneRecovery(
                              widget.incidentId,
                              outcome: outcome,
                              parcelCondition: outcome == 'FOUND'
                                  ? condition
                                  : 'UNKNOWN',
                              note: note.text,
                              latitude: position?.latitude,
                              longitude: position?.longitude,
                              gpsAccuracyM: position?.accuracy,
                              evidence: evidence,
                            );
                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                            }
                            await _load();
                          } catch (error) {
                            _message(LockerOpsService.errorMessage(error));
                            setLocal(() => sending = false);
                          }
                        },
                  child: sending
                      ? const CircularProgressIndicator()
                      : const Text('Gửi Admin xác minh'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    photos.dispose();
    note.dispose();
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.title, required this.value});
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 4),
        Text(value),
      ],
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill(this.value);
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFE0F2FE),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      value.replaceAll('_', ' '),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0369A1),
      ),
    ),
  );
}
