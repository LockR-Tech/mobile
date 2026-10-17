import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smart_laundry_locker/core/utils/app_date_time.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';

/// Thẻ hiển thị và điều khiển Ca làm việc & Vị trí GPS hiện tại của Kỹ thuật viên
/// (dùng chung cho cả KTV Kiosk/Tủ và KTV Drone).
class TechnicianShiftCard extends StatefulWidget {
  const TechnicianShiftCard({
    super.key,
    this.service,
    this.isDrone = false,
    this.margin,
    this.onPresenceChanged,
  });

  final LockerOpsService? service;
  final bool isDrone;
  final EdgeInsetsGeometry? margin;
  final ValueChanged<Map<String, dynamic>>? onPresenceChanged;

  @override
  State<TechnicianShiftCard> createState() => _TechnicianShiftCardState();
}

class _TechnicianShiftCardState extends State<TechnicianShiftCard> {
  late final LockerOpsService _service = widget.service ?? LockerOpsService();
  bool _loading = true;
  bool _updating = false;
  bool _onDuty = false;
  double? _latitude;
  double? _longitude;
  double? _accuracyM;
  double? _altitudeM;
  double? _speedMs;
  String? _deviceInfo;
  DateTime? _lastLocatedAt;
  DateTime? _shiftStartedAt;
  Timer? _periodicLocationTimer;

  @override
  void initState() {
    super.initState();
    _fetchPresence();
  }

  @override
  void dispose() {
    _periodicLocationTimer?.cancel();
    super.dispose();
  }

  /// Lấy trạng thái hiện tại từ backend
  Future<void> _fetchPresence() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final data = await _service.getTechnicianPresence();
      if (!mounted) return;
      _applyPresenceData(data);
      setState(() => _loading = false);

      // Nếu đang trong ca trực, khởi động timer định kỳ cập nhật toạ độ GPS
      if (_onDuty) {
        _startPeriodicLocationSync();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _applyPresenceData(Map<String, dynamic> data) {
    _onDuty = data['onDuty'] == true;
    _latitude = (data['latitude'] as num?)?.toDouble();
    _longitude = (data['longitude'] as num?)?.toDouble();
    _accuracyM = (data['accuracyM'] as num?)?.toDouble();
    _altitudeM = (data['altitudeM'] as num?)?.toDouble();
    _speedMs = (data['speedMs'] as num?)?.toDouble();
    final infoRaw = data['deviceInfo']?.toString().trim();
    if (infoRaw != null && infoRaw.isNotEmpty) {
      _deviceInfo = infoRaw;
    }
    final locatedRaw = data['lastLocatedAt']?.toString();
    _lastLocatedAt = (locatedRaw != null && locatedRaw.isNotEmpty)
        ? parseServerDateTime(locatedRaw)
        : null;
    final shiftRaw = data['shiftStartedAt']?.toString();
    _shiftStartedAt = (shiftRaw != null && shiftRaw.isNotEmpty)
        ? parseServerDateTime(shiftRaw)
        : null;

    widget.onPresenceChanged?.call(data);
  }

  /// Bật hẹn giờ định kỳ đồng bộ vị trí mỗi 2 phút khi đang trong ca trực
  void _startPeriodicLocationSync() {
    _periodicLocationTimer?.cancel();
    _periodicLocationTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (_onDuty && mounted) {
        _syncLocationOnly();
      }
    });
  }

  void _stopPeriodicLocationSync() {
    _periodicLocationTimer?.cancel();
    _periodicLocationTimer = null;
  }

  /// Lấy vị trí GPS thực tế từ thiết bị
  Future<Position?> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        _showSnackBar(
          'Dịch vụ định vị GPS đang tắt. Vui lòng bật GPS trên thiết bị.',
          isError: true,
        );
      }
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          _showSnackBar(
            'Quyền truy cập vị trí bị từ chối.',
            isError: true,
          );
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        _showSnackBar(
          'Quyền truy cập vị trí bị chặn vĩnh viễn. Vui lòng mở Cài đặt để cấp quyền.',
          isError: true,
        );
      }
      return null;
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  Future<void> _syncDroneOrderPresenceIfNeeded({
    required bool onDuty,
    double? latitude,
    double? longitude,
  }) async {
    if (!widget.isDrone) return;
    try {
      await _service.updateDroneTechnicianPresence(
        onDuty: onDuty,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (_) {
      // Không chặn luồng chính nếu order-service chưa sẵn sàng
    }
  }

  /// Chỉ làm mới vị trí GPS và gửi lên backend
  Future<void> _syncLocationOnly() async {
    if (_updating) return;
    setState(() => _updating = true);
    try {
      final pos = await _determinePosition();
      if (pos != null) {
        final res = await _service.updateTechnicianPresence(
          onDuty: _onDuty,
          latitude: pos.latitude,
          longitude: pos.longitude,
          accuracyM: pos.accuracy,
          altitudeM: pos.altitude,
          speedMs: pos.speed,
          headingDeg: pos.heading,
        );
        await _syncDroneOrderPresenceIfNeeded(
          onDuty: _onDuty,
          latitude: pos.latitude,
          longitude: pos.longitude,
        );
        if (!mounted) return;
        setState(() {
          _applyPresenceData(res);
          _updating = false;
        });
        _showSnackBar('Đã cập nhật vị trí GPS thành công.');
      } else {
        if (mounted) setState(() => _updating = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _updating = false);
      _showSnackBar(
        'Không thể cập nhật vị trí: ${LockerOpsService.errorMessage(e)}',
        isError: true,
      );
    }
  }

  /// Chuyển đổi trạng thái ca trực (Bắt đầu ca / Kết thúc ca)
  Future<void> _toggleDuty(bool nextOnDuty) async {
    setState(() => _updating = true);
    try {
      Position? pos;
      if (nextOnDuty) {
        // Vào ca thì bắt buộc cố gắng lấy GPS
        pos = await _determinePosition();
      }

      final res = await _service.updateTechnicianPresence(
        onDuty: nextOnDuty,
        latitude: pos?.latitude,
        longitude: pos?.longitude,
        accuracyM: pos?.accuracy,
        altitudeM: pos?.altitude,
        speedMs: pos?.speed,
        headingDeg: pos?.heading,
      );
      await _syncDroneOrderPresenceIfNeeded(
        onDuty: nextOnDuty,
        latitude: pos?.latitude,
        longitude: pos?.longitude,
      );

      if (!mounted) return;
      setState(() {
        _applyPresenceData(res);
        _updating = false;
      });

      if (nextOnDuty) {
        _startPeriodicLocationSync();
        _showSnackBar('Đã bắt đầu ca làm việc và ghi nhận vị trí.');
      } else {
        _stopPeriodicLocationSync();
        _showSnackBar('Đã kết thúc ca làm việc.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _updating = false);
      _showSnackBar(
        'Lỗi cập nhật ca trực: ${LockerOpsService.errorMessage(e)}',
        isError: true,
      );
    }
  }

  void _showSnackBar(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatLocationTime(DateTime? time) {
    if (time == null) return 'Chưa có vị trí';
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return formatDateTimeVn(time);
  }

  String _formatShiftDuration(DateTime? start, {bool compact = false}) {
    if (start == null) return '';
    final diff = DateTime.now().difference(start);
    final hours = diff.inHours;
    final mins = diff.inMinutes % 60;
    if (hours > 0) {
      return compact ? '${hours}h ${mins}p' : '$hours giờ $mins phút';
    }
    return '$mins phút';
  }

  void _openLocationDetailsModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _onDuty
                          ? const Color(0xFF10B981).withValues(alpha: 0.12)
                          : const Color(0xFF64748B).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _onDuty ? Icons.work_history_rounded : Icons.work_off_outlined,
                      color: _onDuty ? const Color(0xFF10B981) : const Color(0xFF64748B),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _onDuty ? 'Đang trong ca làm việc' : 'Ngoài ca làm việc',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (_onDuty && _shiftStartedAt != null)
                          Text(
                            'Bắt đầu lúc: ${formatDateTimeVn(_shiftStartedAt)} (${_formatShiftDuration(_shiftStartedAt)})',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'TỌA ĐỘ VỊ TRÍ HIỆN TẠI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 10),
              if (_latitude != null && _longitude != null) ...[
                if (_deviceInfo != null && _deviceInfo!.isNotEmpty)
                  _infoRow(
                    Icons.place_outlined,
                    'Khu vực trực',
                    _deviceInfo!,
                  ),
                _infoRow(
                  Icons.pin_drop_outlined,
                  'Tọa độ GPS',
                  '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                ),
                if (_accuracyM != null)
                  _infoRow(
                    Icons.gps_fixed_rounded,
                    'Độ chính xác GPS',
                    '±${_accuracyM!.toStringAsFixed(1)} mét',
                  ),
                if (_altitudeM != null && _altitudeM! > 0)
                  _infoRow(
                    Icons.height_rounded,
                    'Độ cao',
                    '${_altitudeM!.toStringAsFixed(1)} mét',
                  ),
                if (_speedMs != null && _speedMs! > 0)
                  _infoRow(
                    Icons.speed_rounded,
                    'Tốc độ di chuyển',
                    '${(_speedMs! * 3.6).toStringAsFixed(1)} km/h',
                  ),
                _infoRow(
                  Icons.access_time_rounded,
                  'Cập nhật lần cuối',
                  _lastLocatedAt != null
                      ? formatDateTimeVn(_lastLocatedAt)
                      : 'Chưa có',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.map_outlined, size: 18),
                        label: const Text('Mở Google Maps'),
                        onPressed: () async {
                          final uri = Uri.parse(
                            'https://www.google.com/maps/search/?api=1&query=$_latitude,$_longitude',
                          );
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Cập nhật GPS'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0077B6),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _syncLocationOnly();
                        },
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.location_off_outlined, color: Color(0xFF94A3B8)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Chưa ghi nhận tọa độ GPS. Hãy bật ca trực hoặc nhấn Cập nhật vị trí.',
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.my_location_rounded),
                    label: const Text('Lấy vị trí hiện tại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0077B6),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _syncLocationOnly();
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
            ),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                'Đang tải trạng thái ca trực...',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
          ],
        ),
      );
    }

    final hasLocation = _latitude != null && _longitude != null;

    return Container(
      margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: _onDuty
            ? const Color(0xFF064E3B).withValues(alpha: 0.35)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _onDuty
              ? const Color(0xFF10B981).withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.12),
          width: 1.2,
        ),
        boxShadow: _onDuty
            ? [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openLocationDetailsModal,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                // Pulse dot or duty indicator
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _onDuty
                        ? const Color(0xFF10B981).withValues(alpha: 0.22)
                        : Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _onDuty
                          ? const Color(0xFF34D399)
                          : Colors.white.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: _updating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _onDuty ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
                          size: 20,
                          color: _onDuty ? const Color(0xFF34D399) : Colors.white70,
                        ),
                ),
                const SizedBox(width: 8),
                // Center info: Shift Status & GPS coordinates
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            flex: 3,
                            fit: FlexFit.loose,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: _onDuty
                                    ? const Color(0xFF10B981).withValues(alpha: 0.25)
                                    : Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: _onDuty
                                          ? const Color(0xFF34D399)
                                          : Colors.white60,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      _onDuty ? 'ĐANG TRONG CA' : 'NGOÀI CA TRỰC',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: _onDuty
                                            ? const Color(0xFFA7F3D0)
                                            : Colors.white70,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_onDuty && _shiftStartedAt != null) ...[
                            const SizedBox(width: 5),
                            Flexible(
                              flex: 2,
                              fit: FlexFit.loose,
                              child: Text(
                                _formatShiftDuration(_shiftStartedAt, compact: true),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        hasLocation
                            ? '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)} (${_accuracyM != null ? '±${_accuracyM!.toStringAsFixed(0)}m · ' : ''}${_formatLocationTime(_lastLocatedAt)})'
                            : (_onDuty ? 'Đang xác định GPS...' : 'Chưa bật định vị GPS'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: hasLocation ? Colors.white : Colors.white60,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                // Right action: Quick Refresh GPS or Toggle Shift
                if (_onDuty) ...[
                  IconButton(
                    icon: const Icon(Icons.my_location_rounded, size: 20),
                    tooltip: 'Cập nhật lại GPS',
                    color: const Color(0xFF38BDF8),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    visualDensity: VisualDensity.compact,
                    onPressed: _updating ? null : _syncLocationOnly,
                  ),
                  const SizedBox(width: 4),
                ],
                // Toggle Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _onDuty
                        ? const Color(0xFFEF4444).withValues(alpha: 0.85)
                        : const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _updating ? null : () => _toggleDuty(!_onDuty),
                  child: Text(
                    _onDuty ? 'Hết ca' : 'Vào ca',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
