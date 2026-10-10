import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/core/media/photo_picker_controller.dart';
import 'package:smart_laundry_locker/core/media/widgets/photo_picker_field.dart';
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
        _error = LockerOpsService.errorMessage(error);
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
                  _Metric('Pin', _battery(camera)),
                  _Metric(
                    'Chế độ',
                    '${camera['flightMode'] ?? 'Không có dữ liệu'}',
                  ),
                  _Metric(
                    'Telemetry',
                    camera['telemetryLive'] == true
                        ? 'Trực tuyến'
                        : 'Cũ / mất kết nối',
                  ),
                  _Metric('GPS', _gps(camera)),
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

  String _battery(Map<String, dynamic> value) {
    final battery = value['batteryPercent'];
    return battery is num && battery >= 0
        ? '${battery.toInt()}%'
        : 'Không có dữ liệu';
  }

  String _gps(Map<String, dynamic> value) {
    final lat = value['latitude'];
    final lng = value['longitude'];
    return lat is num && lng is num && (lat != 0 || lng != 0)
        ? '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}'
        : 'Không có dữ liệu';
  }

  Future<void> _showReportDialog(Map<String, dynamic>? camera) async {
    final reason = TextEditingController();
    final photos = PhotoPickerController(maxPhotos: 1);
    var sending = false;
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
                      if (reason.text.trim().isEmpty) return;
                      setDialogState(() => sending = true);
                      try {
                        if (photos.isNotEmpty) await photos.uploadAll();
                        final lat = camera?['latitude'];
                        final lng = camera?['longitude'];
                        await widget.service.reportDroppedParcel(
                          widget.orderId,
                          idempotencyKey:
                              'drop-${widget.orderId}-${DateTime.now().microsecondsSinceEpoch}',
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
                        if (context.mounted) Navigator.pop(context, true);
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                LockerOpsService.errorMessage(error),
                              ),
                            ),
                          );
                          setDialogState(() => sending = false);
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
    reason.dispose();
    photos.dispose();
    if (reported == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã tạo sự cố và dừng luồng giao hiện tại.'),
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
