import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/core/media/photo_picker_controller.dart';
import 'package:smart_laundry_locker/core/media/widgets/photo_picker_field.dart';
import 'package:smart_laundry_locker/core/utils/app_date_time.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/drone_technician_errors.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:video_player/video_player.dart';

/// Camera thật của Journey. Khi backend không có camera gateway, widget thể hiện
/// UNAVAILABLE và vẫn cho phép báo thủ công; không dựng video/evidence giả.
class DroneJourneyCameraPanel extends StatefulWidget {
  const DroneJourneyCameraPanel({
    super.key,
    required this.orderId,
    required this.service,
    required this.onIncidentReported,
  });

  final int orderId;
  final LockerOpsService service;
  final Future<void> Function() onIncidentReported;

  @override
  State<DroneJourneyCameraPanel> createState() =>
      _DroneJourneyCameraPanelState();
}

class _DroneJourneyCameraPanelState extends State<DroneJourneyCameraPanel> {
  Map<String, dynamic>? _camera;
  VideoPlayerController? _player;
  String _state = 'CONNECTING';
  String? _error;
  // Giữ một Idempotency-Key cho lần báo rơi kiện tới khi server xác nhận: bấm
  // lại sau lỗi mạng không tạo thêm sự cố/phiếu trùng.
  String? _dropIdempotencyKey;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    unawaited(_player?.dispose());
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _state = 'CONNECTING';
      _error = null;
    });
    try {
      final camera = await widget.service.droneOrderCamera(widget.orderId);
      if (!mounted) return;
      await _player?.dispose();
      _player = null;
      final available = camera['integrationAvailable'] == true;
      final url = camera['streamUrl']?.toString();
      if (available && url != null && url.isNotEmpty) {
        final player = VideoPlayerController.networkUrl(Uri.parse(url));
        _player = player;
        await player.initialize();
        await player.setLooping(true);
        await player.play();
        _state = 'LIVE';
      } else {
        _state = 'UNAVAILABLE';
      }
      if (mounted) setState(() => _camera = camera);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _state = 'ERROR';
        _error = droneTechnicianErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final camera = _camera;
    final player = _player;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFBAE6FD)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.videocam_outlined, color: Color(0xFF0369A1)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Giám sát camera trực tiếp',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                _StatePill(state: _state),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(minHeight: 180),
              decoration: BoxDecoration(
                color: const Color(0xFF020617),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: player != null && player.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: player.value.aspectRatio,
                      child: VideoPlayer(player),
                    )
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_state == 'CONNECTING')
                              const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            else
                              const Icon(
                                Icons.videocam_off_outlined,
                                color: Colors.white54,
                                size: 36,
                              ),
                            const SizedBox(height: 10),
                            Text(
                              _error ??
                                  'Camera gateway chưa khả dụng. Có thể báo sự cố thủ công và chụp ảnh thật.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            TextButton(
                              onPressed: _load,
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            if (camera != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  _Metric('Telemetry', _telemetryState(camera)),
                  _Metric('Pin', _battery(camera)),
                  _Metric('Chế độ bay', _flightMode(camera)),
                  _Metric('GPS', _gps(camera)),
                  if (_num(camera['altitudeM']) != null)
                    _Metric(
                      'Độ cao',
                      '${_num(camera['altitudeM'])!.toStringAsFixed(1)} m',
                    ),
                  if (_num(camera['groundSpeedMs']) != null)
                    _Metric(
                      'Tốc độ',
                      '${_num(camera['groundSpeedMs'])!.toStringAsFixed(1)} m/s',
                    ),
                  if (_num(camera['headingDeg']) != null)
                    _Metric('Hướng', '${_num(camera['headingDeg'])!.round()}°'),
                  if (parseServerDateTime(camera['observedAt']) != null)
                    _Metric(
                      'Số đo lúc',
                      formatDateTimeVn(
                        parseServerDateTime(camera['observedAt']),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
              ),
              onPressed: () => _showReportDialog(camera),
              icon: const Icon(Icons.warning_amber_rounded),
              label: const Text('Báo rơi kiện'),
            ),
          ],
        ),
      ),
    );
  }

  // Backend luôn kèm số đo bay mới nhất; giá trị thiếu theo quy ước -1 /
  // "UNKNOWN" / 0 / "" ⇒ "Không có dữ liệu".
  String _battery(Map<String, dynamic> value) {
    final battery = value['batteryPercent'];
    return battery is num && battery >= 0
        ? '${battery.toInt()}%'
        : 'Không có dữ liệu';
  }

  String _telemetryState(Map<String, dynamic> value) {
    if (value['telemetryAvailable'] == false) return 'Chưa nhận telemetry';
    return value['telemetryLive'] == true ? 'Trực tuyến' : 'Cũ / mất kết nối';
  }

  String _flightMode(Map<String, dynamic> value) {
    final mode = '${value['flightMode'] ?? ''}'.trim();
    return mode.isEmpty || mode.toUpperCase() == 'UNKNOWN'
        ? 'Không có dữ liệu'
        : mode;
  }

  String _gps(Map<String, dynamic> value) {
    final lat = value['latitude'];
    final lng = value['longitude'];
    if (lat is! num || lng is! num || (lat == 0 && lng == 0)) {
      return 'Không có dữ liệu';
    }
    final fix = _num(value['gpsFixType'])?.toInt();
    final satellites = _num(value['satellites'])?.toInt();
    return [
      '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
      if (fix != null) _fixLabel(fix),
      if (satellites != null) '$satellites vệ tinh',
    ].join(' · ');
  }

  static String _fixLabel(int fixType) => switch (fixType) {
    0 || 1 => 'chưa có fix',
    2 => 'fix 2D',
    3 => 'fix 3D',
    4 => 'DGPS',
    5 => 'RTK float',
    6 => 'RTK fixed',
    _ => 'fix $fixType',
  };

  static num? _num(dynamic value) => value is num ? value : null;

  Future<void> _showReportDialog(Map<String, dynamic>? camera) async {
    final reason = TextEditingController();
    final photos = PhotoPickerController(maxPhotos: 1);
    var sending = false;
    String? dialogError;
    final reported = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Xác nhận báo rơi kiện'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Thao tác này dừng luồng giao hiện tại. RTL chỉ được yêu cầu khi telemetry và điều kiện an toàn hợp lệ.',
                  style: TextStyle(color: Color(0xFF92400E), fontSize: 12),
                ),
                const SizedBox(height: 12),
                _DropIncidentSnapshot(
                  orderId: widget.orderId,
                  camera: camera,
                  cameraState: _state,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reason,
                  maxLength: 1000,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả quan sát *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedBuilder(
                  animation: photos,
                  builder: (_, __) => PhotoPickerField(
                    controller: photos,
                    enabled: !sending,
                    addLabel: 'Ảnh camera / hiện trường',
                    helperText:
                        'Không bắt buộc khi camera mất kết nối; không dùng ảnh giả.',
                  ),
                ),
                if (dialogError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    dialogError!,
                    key: const ValueKey('drop-report-error'),
                    style: const TextStyle(color: Color(0xFFB91C1C)),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: sending ? null : () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: sending
                  ? null
                  : () async {
                      if (reason.text.trim().isEmpty) {
                        setDialogState(
                          () => dialogError = 'Nhập mô tả điều bạn quan sát được.',
                        );
                        return;
                      }
                      setDialogState(() => dialogError = null);
                      setDialogState(() => sending = true);
                      try {
                        if (photos.isNotEmpty) await photos.uploadAll();
                        final lat = camera?['latitude'];
                        final lng = camera?['longitude'];
                        final idempotencyKey = _dropIdempotencyKey ??=
                            'drop-${widget.orderId}-${DateTime.now().microsecondsSinceEpoch}';
                        await widget.service.reportDroppedParcel(
                          widget.orderId,
                          idempotencyKey: idempotencyKey,
                          reason: reason.text,
                          latitude:
                              camera?['telemetryLive'] == true && lat is num
                              ? lat.toDouble()
                              : null,
                          longitude:
                              camera?['telemetryLive'] == true && lng is num
                              ? lng.toDouble()
                              : null,
                          cameraStatus: _state,
                          cameraSnapshot: photos.isNotEmpty
                              ? photos.photos.first.upload?.toJson()
                              : null,
                          snapshotCapturedAt: photos.isNotEmpty
                              ? photos.photos.first.capturedAt
                                    .toUtc()
                                    .toIso8601String()
                              : null,
                        );
                        _dropIdempotencyKey = null;
                        if (context.mounted) Navigator.pop(context, true);
                      } catch (error) {
                        // Lỗi hiện ngay trong hộp thoại: SnackBar của trang nằm sau lớp phủ, KTV không thấy.
                        if (context.mounted) {
                          setDialogState(() {
                            sending = false;
                            dialogError = droneTechnicianErrorMessage(error);
                          });
                        }
                      }
                    },
              child: sending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );
    // `showDialog` hoàn tất Future trước khi route dialog tháo xong khỏi cây.
    // PhotoPickerField vẫn đang lắng nghe `photos` ở frame animation cuối; dispose
    // ngay tại đây sẽ làm Flutter báo `_dependents.isEmpty`.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      reason.dispose();
      photos.dispose();
    });
    if (reported == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã tạo sự cố rơi kiện và dừng luồng giao. Theo dõi tiếp ở mục '
            '"Sự cố rơi kiện" trong tab Điều phối.',
          ),
        ),
      );
      await widget.onIncidentReported();
    }
  }
}

class _StatePill extends StatelessWidget {
  const _StatePill({required this.state});
  final String state;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: state == 'LIVE'
          ? const Color(0xFFDCFCE7)
          : const Color(0xFFFFF7ED),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      state.replaceAll('_', ' '),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: state == 'LIVE'
            ? const Color(0xFF15803D)
            : const Color(0xFF9A3412),
      ),
    ),
  );
}

/// Ngữ cảnh bất biến được lưu cùng sự cố. KTV nhìn lại đúng telemetry đang có
/// trước khi mô tả, nhưng không thể sửa/suy diễn vị trí hay số liệu bay.
class _DropIncidentSnapshot extends StatelessWidget {
  const _DropIncidentSnapshot({
    required this.orderId,
    required this.camera,
    required this.cameraState,
  });

  final int orderId;
  final Map<String, dynamic>? camera;
  final String cameraState;

  static num? _num(dynamic value) => value is num ? value : null;

  @override
  Widget build(BuildContext context) {
    final telemetryLive = camera?['telemetryLive'] == true;
    final simulatedLocation = camera?['locationSource'] == 'SIMULATION_FPT_HCM';
    final lat = _num(camera?['latitude']);
    final lng = _num(camera?['longitude']);
    final hasLocation =
        (telemetryLive || simulatedLocation) &&
        lat != null &&
        lng != null &&
        (lat != 0 || lng != 0);
    final observedAt = parseServerDateTime(camera?['observedAt']);
    final battery = _num(camera?['batteryPercent']);
    final altitude = _num(camera?['altitudeM']);
    final speed = _num(camera?['groundSpeedMs']);
    final flightMode = '${camera?['flightMode'] ?? ''}'.trim();

    final rows = <_SnapshotValue>[
      _SnapshotValue('Đơn', '#$orderId'),
      _SnapshotValue('Drone', '${camera?['droneCode'] ?? 'Chưa có dữ liệu'}'),
      _SnapshotValue(
        'Chặng bay',
        _journeyLabel(camera?['journeyStatus']?.toString()),
      ),
      _SnapshotValue(
        'Telemetry',
        telemetryLive ? 'Trực tuyến' : 'Cũ / chưa kết nối',
      ),
      _SnapshotValue(
        'Vị trí lưu vào phiếu',
        hasLocation
            ? '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}'
                  '${simulatedLocation ? ' · Mô phỏng FPT HCM' : ''}'
            : 'Chưa có vị trí GPS tin cậy',
        warning: !hasLocation,
      ),
      if (observedAt != null)
        _SnapshotValue('Số đo lúc', formatDateTimeVn(observedAt)),
      if (battery != null && battery >= 0)
        _SnapshotValue('Pin', '${battery.toInt()}%'),
      if (flightMode.isNotEmpty && flightMode.toUpperCase() != 'UNKNOWN')
        _SnapshotValue('Chế độ bay', flightMode),
      if (altitude != null)
        _SnapshotValue('Độ cao', '${altitude.toStringAsFixed(1)} m'),
      if (speed != null)
        _SnapshotValue('Tốc độ', '${speed.toStringAsFixed(1)} m/s'),
      _SnapshotValue('Camera', _cameraLabel(cameraState)),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        border: Border.all(color: const Color(0xFFFED7AA)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.location_searching,
                size: 17,
                color: Color(0xFF9A3412),
              ),
              SizedBox(width: 7),
              Text(
                'Dữ liệu tự ghi vào phiếu',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF7C2D12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final row in rows) ...[
            _SnapshotRow(value: row),
            if (row != rows.last) const SizedBox(height: 4),
          ],
          if (!hasLocation) ...[
            const SizedBox(height: 7),
            const Text(
              'Hệ thống không tự tạo toạ độ khi telemetry không trực tuyến.',
              style: TextStyle(fontSize: 11, color: Color(0xFF9A3412)),
            ),
          ],
        ],
      ),
    );
  }

  static String _cameraLabel(String state) => switch (state) {
    'LIVE' => 'Đang trực tiếp',
    'UNAVAILABLE' => 'Chưa khả dụng',
    'ERROR' => 'Lỗi kết nối',
    _ => 'Đang kết nối',
  };

  static String _journeyLabel(String? status) =>
      switch ((status ?? '').toUpperCase()) {
        'LAUNCHING' => 'Đang khởi phóng',
        'DEPARTED' => 'Đã rời trạm',
        'EN_ROUTE' => 'Đang bay tới tủ nhận',
        'APPROACHING' => 'Đang tiếp cận tủ nhận',
        'ARRIVED' => 'Đã đến tủ nhận',
        _ => status?.trim().isNotEmpty == true ? status! : 'Chưa có dữ liệu',
      };
}

class _SnapshotValue {
  const _SnapshotValue(this.label, this.value, {this.warning = false});

  final String label;
  final String value;
  final bool warning;
}

class _SnapshotRow extends StatelessWidget {
  const _SnapshotRow({required this.value});

  final _SnapshotValue value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 126,
        child: Text(
          value.label,
          style: const TextStyle(fontSize: 11.5, color: Color(0xFF78716C)),
        ),
      ),
      Expanded(
        child: Text(
          value.value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: value.warning
                ? const Color(0xFF9A3412)
                : const Color(0xFF292524),
          ),
        ),
      ),
    ],
  );
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      '$label: $value',
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
    ),
  );
}
