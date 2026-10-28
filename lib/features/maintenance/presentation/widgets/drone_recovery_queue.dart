import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smart_laundry_locker/core/media/photo_picker_controller.dart';
import 'package:smart_laundry_locker/core/media/widgets/photo_picker_field.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_incident_labels.dart';
import 'package:url_launcher/url_launcher.dart';

class DroneRecoveryQueue extends StatelessWidget {
  const DroneRecoveryQueue({
    super.key,
    required this.items,
    required this.service,
    required this.onRefresh,
    this.error,
  });

  final List<Map<String, dynamic>> items;
  final LockerOpsService service;
  final Future<void> Function() onRefresh;

  /// Lỗi tải danh sách (câu tiếng Việt) — hiện kèm "Thử lại", không coi là
  /// "chưa có nhiệm vụ".
  final String? error;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onRefresh,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      children: [
        const _Banner(),
        const SizedBox(height: 12),
        if (error != null) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 18,
                  color: Color(0xFFDC2626),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Không tải được nhiệm vụ thu hồi: $error',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF991B1B),
                    ),
                  ),
                ),
                TextButton(onPressed: onRefresh, child: const Text('Thử lại')),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (items.isEmpty && error == null)
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
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 15,
                      color: Color(0xFFDC2626),
                    ),
                    SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'Nhiệm vụ tìm kiếm khẩn cấp · Drone rơi',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item['incidentCode'] ?? 'Sự cố #${item['id']}'}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  _Pill(droneRecoveryStatusLabel(status)),
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
          children: [
            _Pill(droneRecoveryStatusLabel(status)),
            _Pill(droneParcelStatusLabel(item['parcelStatus'])),
          ],
        ),
        const SizedBox(height: 14),
        _Info(title: 'Tình huống', value: '${item['reason']}'),
        const SizedBox(height: 10),
        _Info(
          title: 'Độ chính xác dữ liệu',
          value:
              'Nguồn vị trí: ${_gpsSourceLabel(item['gpsSource'])} · sai số ${item['gpsAccuracyM'] == null ? 'không rõ' : '±${item['gpsAccuracyM']} m'} · telemetry ${item['telemetryStale'] == true ? 'đã cũ' : 'trực tuyến'}',
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
                final rawUrl = (value['secureUrl'] ?? value['url'])
                    ?.toString()
                    .trim();
                final isValidUrl =
                    rawUrl != null &&
                    rawUrl.isNotEmpty &&
                    rawUrl != 'null' &&
                    (rawUrl.startsWith('http://') ||
                        rawUrl.startsWith('https://'));
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: isValidUrl
                      ? Image.network(
                          rawUrl,
                          width: 120,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 120,
                            height: 100,
                            color: const Color(0xFFE2E8F0),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image_outlined,
                                  color: Color(0xFF94A3B8),
                                  size: 24,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Lỗi tải ảnh',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Container(
                          width: 120,
                          height: 100,
                          color: const Color(0xFFE2E8F0),
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            color: Color(0xFF94A3B8),
                          ),
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
        if (status == 'SUBMITTED')
          const _Info(
            title: 'Kết quả đã gửi',
            value: 'Admin sẽ xác minh bằng chứng và quyết định bước tiếp theo.',
          ),
        if (status == 'CLOSED')
          const _Info(
            title: 'Đã hoàn tất thu hồi',
            value: 'Admin đã xác minh và kiện đã về Hub / kho. Bạn không cần làm gì thêm.',
          ),
      ],
    );
  }

  /// Vị trí hiện tại (xin quyền nếu cần); `null` khi tắt định vị / từ chối /
  /// hết giờ chờ.
  Future<Position?> _currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Không lấy được GPS ⇒ hỏi KTV có gửi không kèm toạ độ hay không.
  Future<bool> _confirmWithoutGps() async {
    if (!mounted) return false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Không lấy được vị trí GPS'),
        content: const Text(
          'Kết quả thu hồi cần toạ độ nơi chụp để Admin đối chiếu. Hãy bật định vị '
          'và cấp quyền vị trí rồi thử lại. Chỉ gửi không kèm GPS khi thật sự không '
          'thể định vị — Admin sẽ thấy bằng chứng thiếu toạ độ.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Thử lại sau'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Vẫn gửi không kèm GPS'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _handover() async {
    // Bàn giao là mốc trách nhiệm (kiện rời tay KTV) và không hoàn tác được ⇒ hỏi lại trước khi gửi.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bàn giao kiện về Hub / kho?'),
        content: const Text(
          'Chỉ xác nhận khi kiện đã nằm ở Hub / kho và đã có người nhận bàn giao. '
          'Sau bước này kiện thuộc trách nhiệm của Hub.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Chưa'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Đã bàn giao'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
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
    String? formError;
    Position? confirmedPosition;
    bool checkingGps = false;
    double? distanceMeters;

    final dropLat = (item['dropLatitude'] as num?)?.toDouble();
    final dropLng = (item['dropLongitude'] as num?)?.toDouble();

    const quickNoteTags = [
      'Kiện còn nguyên vẹn, niêm phong tốt',
      'Bao bì rách/móp nhẹ do va đập',
      'Drone gãy cánh, kẹt cành cây',
      'Đã tìm khắp khu vực không thấy kiện',
      'Khu vực không an toàn, không tiếp cận được',
    ];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      // Ảnh và ghi chú chỉ được huỷ khi sheet đã gỡ hẳn khỏi cây (sau animation đóng): huỷ ngay khi
      // `showModalBottomSheet` trả về làm ô nhập còn đang vẽ dùng controller đã huỷ ⇒ crash màn đỏ.
      builder: (sheetContext) => _DisposeOnUnmount(
        onDispose: () {
          photos.dispose();
          note.dispose();
        },
        child: StatefulBuilder(
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
                    'Báo cáo hiện trường & Kết quả thu hồi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'KTV kiosk phải bấm xác nhận tọa độ thực tế tại điểm tìm kiếm, nhập ghi chú tình trạng và chụp ảnh bằng chứng.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 14),

                  // ---- Phần 1: Bấm xác nhận tọa độ hiện trường ----
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: confirmedPosition != null
                          ? const Color(0xFFF0FDF4)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: confirmedPosition != null
                            ? const Color(0xFFBBF7D0)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              confirmedPosition != null
                                  ? Icons.check_circle_outline
                                  : Icons.my_location,
                              size: 18,
                              color: confirmedPosition != null
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFF0284C7),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                confirmedPosition != null
                                    ? 'Đã xác nhận tọa độ hiện trường'
                                    : 'Xác nhận tọa độ GPS tại hiện trường',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: confirmedPosition != null
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (confirmedPosition == null) ...[
                          const Text(
                            'Bấm nút bên dưới để lấy toạ độ GPS chính xác nơi bạn đang đứng đối chiếu với điểm drone rơi.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: checkingGps
                                  ? null
                                  : () async {
                                      setLocal(() => checkingGps = true);
                                      try {
                                        final pos = await _currentPosition();
                                        if (pos != null) {
                                          double? dist;
                                          if (dropLat != null &&
                                              dropLng != null) {
                                            dist = Geolocator.distanceBetween(
                                              pos.latitude,
                                              pos.longitude,
                                              dropLat,
                                              dropLng,
                                            );
                                          }
                                          setLocal(() {
                                            confirmedPosition = pos;
                                            distanceMeters = dist;
                                          });
                                        } else {
                                          _message(
                                            'Không lấy được toạ độ GPS. Vui lòng bật định vị và cấp quyền vị trí.',
                                          );
                                        }
                                      } finally {
                                        if (sheetContext.mounted) {
                                          setLocal(() => checkingGps = false);
                                        }
                                      }
                                    },
                              icon: checkingGps
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.gps_fixed, size: 16),
                              label: Text(
                                checkingGps
                                    ? 'Đang đọc tín hiệu GPS...'
                                    : 'Bấm xác nhận tọa độ hiện trường',
                              ),
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Tọa độ: ${confirmedPosition!.latitude.toStringAsFixed(6)}, ${confirmedPosition!.longitude.toStringAsFixed(6)} (Sai số: ±${confirmedPosition!.accuracy.toStringAsFixed(1)} m)',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          if (distanceMeters != null) ...[
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: distanceMeters! <= 100
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                distanceMeters! <= 100
                                    ? '✓ Trong phạm vi hiện trường (~${distanceMeters!.round()} m từ điểm rơi)'
                                    : '⚠️ Cách điểm rơi ~${distanceMeters!.round()} m (Tiến lại gần hơn nếu có thể)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: distanceMeters! <= 100
                                      ? const Color(0xFF166534)
                                      : const Color(0xFF92400E),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: checkingGps
                                  ? null
                                  : () async {
                                      setLocal(() => checkingGps = true);
                                      try {
                                        final pos = await _currentPosition();
                                        if (pos != null) {
                                          double? dist;
                                          if (dropLat != null &&
                                              dropLng != null) {
                                            dist = Geolocator.distanceBetween(
                                              pos.latitude,
                                              pos.longitude,
                                              dropLat,
                                              dropLng,
                                            );
                                          }
                                          setLocal(() {
                                            confirmedPosition = pos;
                                            distanceMeters = dist;
                                          });
                                        }
                                      } finally {
                                        if (sheetContext.mounted) {
                                          setLocal(() => checkingGps = false);
                                        }
                                      }
                                    },
                              icon: const Icon(Icons.refresh, size: 14),
                              label: const Text(
                                'Cập nhật lại GPS',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ---- Phần 2: Kết quả & Tình trạng kiện ----
                  DropdownButtonFormField<String>(
                    initialValue: outcome,
                    decoration: const InputDecoration(
                      labelText: 'Kết quả tìm kiếm',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'FOUND',
                        child: Text('Đã tìm thấy kiện hàng'),
                      ),
                      DropdownMenuItem(
                        value: 'NOT_FOUND',
                        child: Text('Không tìm thấy kiện hàng'),
                      ),
                      DropdownMenuItem(
                        value: 'UNSAFE',
                        child: Text('Khu vực không an toàn để tìm'),
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
                  const SizedBox(height: 12),

                  // ---- Phần 3: Ghi chú hiện trường ----
                  TextField(
                    controller: note,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú hiện trường (Bắt buộc nhập mô tả)',
                      hintText:
                          'Mô tả vị trí phát hiện, hiện trạng drone, tình trạng kiện, nơi lưu trữ tạm...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final tag in quickNoteTags)
                        InkWell(
                          onTap: () {
                            setLocal(() {
                              final current = note.text.trim();
                              note.text = current.isEmpty
                                  ? tag
                                  : '$current. $tag';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Text(
                              '+ $tag',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ---- Phần 4: Hình ảnh hiện trường ----
                  AnimatedBuilder(
                    animation: photos,
                    builder: (_, __) => PhotoPickerField(
                      controller: photos,
                      enabled: !sending,
                      cameraOnly: true,
                      helperText:
                          'Bắt buộc ít nhất 1 ảnh chụp trực tiếp tại hiện trường (kèm toạ độ).',
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (formError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        formError!,
                        key: const ValueKey('recovery-form-error'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  FilledButton(
                    onPressed: sending
                        ? null
                        : () async {
                            if (photos.isEmpty) {
                              setLocal(
                                () => formError =
                                    'Vui lòng chụp ít nhất 1 ảnh hiện trường.',
                              );
                              return;
                            }
                            if (note.text.trim().isEmpty) {
                              setLocal(
                                () => formError =
                                    'Vui lòng nhập ghi chú hiện trường.',
                              );
                              return;
                            }
                            setLocal(() {
                              formError = null;
                              sending = true;
                            });
                            try {
                              var position = confirmedPosition;
                              if (position == null) {
                                position = await _currentPosition();
                                if (position == null) {
                                  final proceed = await _confirmWithoutGps();
                                  if (!proceed) {
                                    if (sheetContext.mounted) {
                                      setLocal(() => sending = false);
                                    }
                                    return;
                                  }
                                }
                              }
                              final uploaded = await photos.uploadAll(
                                caption: 'Bằng chứng thu hồi kiện',
                              );
                              final evidence = buildRecoveryEvidence(
                                uploaded,
                                photos.photos,
                                latitude: position?.latitude,
                                longitude: position?.longitude,
                                gpsAccuracyM: position?.accuracy,
                              );
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
                              if (sheetContext.mounted) {
                                setLocal(() {
                                  formError = LockerOpsService.errorMessage(
                                    error,
                                  );
                                  sending = false;
                                });
                              }
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
      ),
    );
  }
}

/// Gọi [onDispose] khi phần tử bị gỡ khỏi cây — lúc đó mọi widget con (ô nhập, lưới ảnh) đã được gỡ trước.
class _DisposeOnUnmount extends StatefulWidget {
  const _DisposeOnUnmount({required this.onDispose, required this.child});

  final VoidCallback onDispose;
  final Widget child;

  @override
  State<_DisposeOnUnmount> createState() => _DisposeOnUnmountState();
}

class _DisposeOnUnmountState extends State<_DisposeOnUnmount> {
  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Dựng `evidence[]` gửi kèm kết quả thu hồi: `capturedAt` = lúc chụp từng
/// ảnh (UTC ISO); toạ độ ưu tiên toạ độ gắn với ảnh lúc chụp, rồi tới vị trí
/// lúc gửi. [uploaded] và [photos] cùng thứ tự (`PhotoPickerController.uploadAll`).
@visibleForTesting
List<Map<String, dynamic>> buildRecoveryEvidence(
  List<Map<String, dynamic>> uploaded,
  List<PendingPhoto> photos, {
  double? latitude,
  double? longitude,
  double? gpsAccuracyM,
}) {
  final result = <Map<String, dynamic>>[];
  for (var i = 0; i < uploaded.length; i++) {
    final value = uploaded[i];
    final photo = i < photos.length ? photos[i] : null;
    final photoLat = photo?.latitude;
    final photoLng = photo?.longitude;
    final hasPhotoGps = photoLat != null && photoLng != null;
    final lat = hasPhotoGps ? photoLat : latitude;
    final lng = hasPhotoGps ? photoLng : longitude;
    result.add({
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
      'capturedAt': (photo?.capturedAt ?? DateTime.now())
          .toUtc()
          .toIso8601String(),
      if (lat != null && lng != null) ...{
        'latitude': lat,
        'longitude': lng,
        if (!hasPhotoGps && gpsAccuracyM != null) 'gpsAccuracyM': gpsAccuracyM,
      },
    });
  }
  return result;
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
      value,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0369A1),
      ),
    ),
  );
}

/// Toạ độ điểm rơi lấy từ đâu: GPS drone thật hay ước theo tuyến bay.
String _gpsSourceLabel(Object? source) => switch ('${source ?? ''}'.toUpperCase()) {
  'TELEMETRY' || 'DRONE_GPS' || 'GPS' => 'GPS drone',
  'FLIGHT_PATH' => 'ước theo tuyến bay',
  'UNAVAILABLE' => 'chưa có',
  '' => 'không rõ',
  final other => other.toLowerCase(),
};
