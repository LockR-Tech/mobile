import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';
import 'package:smart_laundry_locker/core/utils/app_date_time.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/technician_location_permission_sheet.dart';

/// Thẻ hiển thị và điều khiển Ca trực & Vị trí GPS hiện tại của Kỹ thuật viên.
///
/// Nguyên tắc thiết kế:
/// - Khi VÀO CA: kích hoạt truy cập vị trí (bao gồm chạy ngầm) để phục vụ điều phối sự cố/drone.
/// - Khi HẾT CA: ngắt hoàn toàn quyền truy cập vị trí để đảm bảo quyền riêng tư.
/// - Không quản lý chấm công ca trực (không đếm giờ/hiển thị thời gian chấm công).
/// - Chỉ hiển thị trạng thái GPS thân thiện trên thanh chính (không hiện số toạ độ thô hay tên khu vực).
/// - Thông tin toạ độ chi tiết được xem trong Modal khi cần kiểm tra kỹ thuật.
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
  DateTime? _lastLocatedAt;
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
    final locatedRaw = data['lastLocatedAt']?.toString();
    _lastLocatedAt = (locatedRaw != null && locatedRaw.isNotEmpty)
        ? parseServerDateTime(locatedRaw)
        : null;

    widget.onPresenceChanged?.call(data);
  }

  /// Bật hẹn giờ định kỳ đồng bộ vị trí mỗi 2 phút khi đang trong ca trực.
  /// Sử dụng silent: true để không hiện SnackBar làm gián đoạn trải nghiệm KTV.
  void _startPeriodicLocationSync() {
    _periodicLocationTimer?.cancel();
    _periodicLocationTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (_onDuty && mounted) {
        _syncLocationOnly(silent: true);
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
          context.l10n.techUiGpsServiceOff,
          isError: true,
        );
      }
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      if (mounted) {
        final granted = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (ctx) => const TechnicianLocationPermissionSheet(),
        );
        if (granted != true) return null;
      }
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        if (mounted) {
          _showSnackBar(
            context.l10n.lockerLocationDenied,
            isError: true,
          );
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        _showSnackBar(
          context.l10n.techUiLocationBlockedForever,
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

  /// Làm mới vị trí GPS và gửi lên backend.
  /// [silent] = true: cập nhật ngầm không hiện SnackBar giật màn hình.
  Future<void> _syncLocationOnly({bool silent = false}) async {
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
        if (!silent) {
          _showSnackBar(context.l10n.techUiGpsUpdated);
        }
      } else {
        if (mounted) setState(() => _updating = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _updating = false);
      if (!silent) {
        _showSnackBar(
          context.l10n.techUiLocationUpdateFailed(
            LockerOpsService.errorMessage(e),
          ),
          isError: true,
        );
      }
    }
  }

  /// Chuyển đổi trạng thái ca trực (Vào ca / Hết ca).
  /// Khi Hết ca: hiển thị hộp thoại xác nhận trước khi ngắt vị trí.
  Future<void> _toggleDuty(bool nextOnDuty) async {
    if (!nextOnDuty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            context.l10n.techUiEndShiftQuestion,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          ),
          content: Text(
            context.l10n.techUiEndShiftBody,
            style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                context.l10n.commonCancel,
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                context.l10n.techUiEndShift,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _updating = true);
    try {
      Position? pos;
      if (nextOnDuty) {
        // Vào ca: bắt buộc lấy vị trí GPS
        pos = await _determinePosition();
        if (pos == null) {
          if (mounted) setState(() => _updating = false);
          return;
        }
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
        _showSnackBar(context.l10n.techUiShiftStarted);
      } else {
        _stopPeriodicLocationSync();
        _showSnackBar(context.l10n.techUiShiftEnded);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _updating = false);
      _showSnackBar(
        context.l10n.techUiShiftUpdateFailed(LockerOpsService.errorMessage(e)),
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
        backgroundColor:
            isError ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatLocationTime(DateTime? time) {
    if (time == null) return context.l10n.techUiNoLocationYet;
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return context.l10n.nlJustNow;
    if (diff.inMinutes < 60) return context.l10n.nlMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return context.l10n.nlHoursAgo(diff.inHours);
    return formatDateTimeVn(time);
  }

  /// Mở Modal hiển thị chi tiết thông tin kỹ thuật GPS & Quyền riêng tư
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
              // Header
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
                      _onDuty
                          ? Icons.gps_fixed_rounded
                          : Icons.location_off_outlined,
                      color: _onDuty
                          ? const Color(0xFF10B981)
                          : const Color(0xFF64748B),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _onDuty
                              ? context.l10n.techUiOnShift
                              : context.l10n.techUiOffShift,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _onDuty
                              ? context.l10n.techUiOnShiftLocationNote
                              : context.l10n.techUiOffShiftLocationNote,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                context.l10n.techUiDeviceGpsInfo,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 10),
              if (_latitude != null && _longitude != null) ...[
                _infoRow(
                  Icons.pin_drop_outlined,
                  context.l10n.techUiGpsCoordinates,
                  '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                ),
                if (_accuracyM != null)
                  _infoRow(
                    Icons.gps_fixed_rounded,
                    context.l10n.techUiGpsAccuracy,
                    context.l10n.techUiAccuracyMeters(
                      _accuracyM!.toStringAsFixed(1),
                    ),
                  ),
                _infoRow(
                  Icons.access_time_rounded,
                  context.l10n.recvUpdatedAt,
                  _lastLocatedAt != null
                      ? formatDateTimeVn(_lastLocatedAt)
                      : context.l10n.techUiNotYet,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.map_outlined, size: 18),
                        label: Text(context.l10n.techUiOpenGoogleMaps),
                        onPressed: () async {
                          final uri = Uri.parse(
                            'https://www.google.com/maps/search/?api=1&query=$_latitude,$_longitude',
                          );
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(context.l10n.techUiUpdateGps),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0077B6),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _syncLocationOnly(silent: false);
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
                  child: Row(
                    children: [
                      const Icon(Icons.location_off_outlined, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          context.l10n.techUiNoGpsYet,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
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
                    label: Text(context.l10n.techUiGetCurrentLocation),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0077B6),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _syncLocationOnly(silent: false);
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.l10n.techUiPrivacyCommitment,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
        margin: widget.margin ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white70,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                context.l10n.techUiLoadingShift,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
          ],
        ),
      );
    }

    final hasLocation = _latitude != null && _longitude != null;

    // Giao diện tinh gọn, không hiện toạ độ số thô hay khu vực trực
    return Container(
      margin: widget.margin ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                // Icon trạng thái GPS
                Container(
                  width: 36,
                  height: 36,
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
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _onDuty
                              ? Icons.gps_fixed_rounded
                              : Icons.location_off_outlined,
                          size: 19,
                          color: _onDuty
                              ? const Color(0xFF34D399)
                              : Colors.white70,
                        ),
                ),
                const SizedBox(width: 10),
                // Center info: Trạng thái ca trực & Trạng thái GPS
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            fit: FlexFit.loose,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
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
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      _onDuty
                                          ? context.l10n.techUiOnShiftBadge
                                          : context.l10n.techUiOffShiftBadge,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: _onDuty
                                            ? const Color(0xFFA7F3D0)
                                            : Colors.white70,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      // Hiển thị trạng thái GPS thân thiện thay vì số toạ độ thô
                      Text(
                        _onDuty
                            ? (hasLocation
                                ? context.l10n.techUiGpsActive(
                                    _accuracyM != null
                                        ? ' (±${_accuracyM!.toStringAsFixed(0)}m)'
                                        : '',
                                    _formatLocationTime(_lastLocatedAt),
                                  )
                                : context.l10n.techUiGpsSearching)
                            : context.l10n.techUiGpsOffHint,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: _onDuty ? Colors.white : Colors.white60,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                // Nút Cập nhật GPS nhanh khi đang trong ca
                if (_onDuty) ...[
                  IconButton(
                    icon: const Icon(Icons.my_location_rounded, size: 19),
                    tooltip: context.l10n.techUiRefreshGps,
                    color: const Color(0xFF38BDF8),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 30, minHeight: 30),
                    visualDensity: VisualDensity.compact,
                    onPressed: _updating ? null : () => _syncLocationOnly(silent: false),
                  ),
                  const SizedBox(width: 4),
                ],
                // Toggle Button (Vào ca / Hết ca)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _onDuty
                        ? const Color(0xFFEF4444).withValues(alpha: 0.9)
                        : const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _updating ? null : () => _toggleDuty(!_onDuty),
                  child: Text(
                    _onDuty
                        ? context.l10n.techUiEndShiftShort
                        : context.l10n.techUiStartShift,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
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
