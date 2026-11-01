import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/presentation/pages/directions_map_page.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/pages/rent_locker_page.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/pages/send_parcel_page.dart';
import 'package:smart_laundry_locker/features/stores/domain/entities/store.dart';
import 'package:smart_laundry_locker/features/maintenance/presentation/pages/create_report_page.dart';
import 'package:smart_laundry_locker/features/locker/domain/entities/locker_location.dart';
import 'package:smart_laundry_locker/features/locker/domain/utils/locker_layout_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_laundry_locker/shared/shared.dart';
import 'dart:async';
import 'package:smart_laundry_locker/core/services/app_event_bus.dart';
import 'package:smart_laundry_locker/features/notifications/infrastructure/services/realtime_notification_service.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// Hiển thị lưới ô tủ locker.
///
/// - Có [lockerId] (mở từ danh sách tủ / trang chủ / bản đồ): chỉ tải đúng tủ đó
///   qua `GET /api/lockers/{id}`.
/// - Không có [lockerId] (mở từ cửa hàng): tải các tủ của cửa hàng qua
///   `GET /api/lockers?storeId=`.
///
/// Không đoán tủ theo tên hay mã: lỗi tải thì báo lỗi + Thử lại. Layout từng tủ
/// được tải khi khách mở rộng thẻ tủ.
class StoreLockerGridPage extends StatefulWidget {
  const StoreLockerGridPage({
    super.key,
    required this.store,
    this.lockerId,
    this.service,
    this.droneHint = false,
    this.initialLocation,
  });

  /// Thông tin location ban đầu (nếu mở từ LockerLocation)
  final LockerLocation? initialLocation;

  /// Mở thẳng một tủ từ danh sách tủ (`GET /api/lockers`): `location.id` là id
  /// TỦ, `location.storeId` là cửa hàng chứa tủ.
  factory StoreLockerGridPage.forLocation(
    LockerLocation location, {
    Key? key,
    bool droneHint = false,
  }) {
    final hasLockerCoord = location.hasValidCoordinate;
    final hasStoreCoord =
        location.storeLatitude != null &&
        location.storeLongitude != null &&
        location.storeLatitude!.isFinite &&
        location.storeLongitude!.isFinite;

    return StoreLockerGridPage(
      key: key,
      lockerId: int.tryParse(location.id),
      droneHint: droneHint,
      initialLocation: location,
      store: Store(
        id: int.tryParse(location.storeId ?? '') ?? 0,
        name: location.storeName?.isNotEmpty == true
            ? location.storeName!
            : location.name,
        address: location.storeAddress?.isNotEmpty == true
            ? location.storeAddress
            : (location.address.isEmpty ? null : location.address),
        latitude: hasStoreCoord
            ? location.storeLatitude
            : (hasLockerCoord ? location.latitude : null),
        longitude: hasStoreCoord
            ? location.storeLongitude
            : (hasLockerCoord ? location.longitude : null),
        active: location.isActive,
      ),
    );
  }

  /// Cửa hàng chứa tủ — tên/địa chỉ/toạ độ để hiển thị và chỉ đường. `store.id`
  /// là id CỬA HÀNG (0 khi không rõ), không bao giờ là id tủ.
  final Store store;

  /// Id tủ cần mở thẳng; null ⇒ liệt kê các tủ của [store].
  final int? lockerId;
  final LockerOpsService? service;

  /// Mở từ lối vào "Gửi bằng drone": nhắc khách chạm ô drone để đặt.
  final bool droneHint;

  @override
  State<StoreLockerGridPage> createState() => _StoreLockerGridPageState();
}

class _StoreLockerGridPageState extends State<StoreLockerGridPage> {
  late final LockerOpsService _service = widget.service ?? LockerOpsService();
  List<Map<String, dynamic>> _lockers = const [];
  bool _loading = true;
  String? _error;
  StreamSubscription<AppEvent>? _eventSub;

  @override
  void initState() {
    super.initState();
    _load();
    // Admin sửa/tắt tủ hoặc sửa cửa hàng ⇒ tải lại danh sách tủ (ngầm).
    _eventSub = AppEventBus.instance.events.listen((event) {
      if (mounted &&
          !_loading &&
          event is CatalogChangedEvent &&
          (event.isLocker || event.isStore)) {
        _load(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final List<Map<String, dynamic>> lockers;
      final lockerId = widget.lockerId;
      if (lockerId != null && lockerId > 0) {
        final locker = await _service.locker(lockerId);
        lockers = locker['id'] == null ? const [] : [locker];
      } else if (widget.store.id > 0) {
        lockers = await _service.lockersByStore(widget.store.id);
      } else {
        lockers = const [];
      }
      if (!mounted) return;
      setState(() {
        // Đồng bộ với Admin: hiển thị mọi tủ (kể cả bảo trì, mất kết nối, tạm
        // đóng); trạng thái kết nối lấy từ `online` của server.
        _lockers = lockers;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || silent) return;
      setState(() {
        _error = LockerOpsService.errorMessage(e);
        _loading = false;
      });
    }
  }

  Map<String, dynamic>? get _primaryLocker =>
      _lockers.isNotEmpty ? _lockers.first : null;

  String? get _currentLockerName {
    final locker = _primaryLocker;
    if (locker != null) {
      final n = locker['name'] as String?;
      final c = locker['code'] as String?;
      if (n != null && n.isNotEmpty) return n;
      if (c != null && c.isNotEmpty) return c;
    }
    return widget.initialLocation?.name;
  }

  String? get _currentLockerAddress {
    final locker = _primaryLocker;
    if (locker != null) {
      final addr = locker['address'] as String?;
      if (addr != null && addr.isNotEmpty) return addr;
    }
    final initAddr = widget.initialLocation?.address;
    if (initAddr != null && initAddr.isNotEmpty) return initAddr;
    return null;
  }

  double? get _currentLockerLat {
    final locker = _primaryLocker;
    if (locker != null) {
      final lat = (locker['latitude'] as num?)?.toDouble();
      if (lat != null && lat.isFinite) return lat;
    }
    if (widget.initialLocation != null &&
        widget.initialLocation!.hasValidCoordinate) {
      return widget.initialLocation!.latitude;
    }
    return null;
  }

  double? get _currentLockerLng {
    final locker = _primaryLocker;
    if (locker != null) {
      final lng = (locker['longitude'] as num?)?.toDouble();
      if (lng != null && lng.isFinite) return lng;
    }
    if (widget.initialLocation != null &&
        widget.initialLocation!.hasValidCoordinate) {
      return widget.initialLocation!.longitude;
    }
    return null;
  }

  void _openDirections() {
    // 1. Ưu tiên tuyệt đối toạ độ chính xác của tủ (đồng bộ với http://localhost:3000/admin/lockers/5)
    final lat =
        _currentLockerLat ??
        (widget.store.hasLocation ? widget.store.latitude : null);
    final lng =
        _currentLockerLng ??
        (widget.store.hasLocation ? widget.store.longitude : null);
    if (lat == null || lng == null) return;

    Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        builder: (_) => DirectionsMapPage(
          destination: LatLng(lat, lng),
          title: _currentLockerName ?? widget.store.name,
          subtitle: _currentLockerAddress ?? widget.store.address,
        ),
      ),
    );
  }

  void _openKioskDirections() {
    if (!widget.store.hasLocation) return;
    Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        builder: (_) => DirectionsMapPage(
          destination: LatLng(widget.store.latitude!, widget.store.longitude!),
          title: widget.store.name,
          subtitle: widget.store.address,
        ),
      ),
    );
  }

  void _openReportLocker([Map<String, dynamic>? locker]) {
    final target = locker ?? (_lockers.length == 1 ? _lockers.first : null);
    if (target == null || target['id'] == null) {
      // Nhiều tủ (hoặc chưa tải xong): để trang báo sự cố tự cho khách chọn tủ.
      Navigator.of(context, rootNavigator: true).push<void>(
        MaterialPageRoute(
          builder: (_) => CreateReportPage(
            cabinetId: '',
            lockerId: '',
            locationName: widget.store.name,
          ),
        ),
      );
      return;
    }
    final lockerId = target['id'].toString();
    final lockerName =
        (target['name'] as String?) ??
        (target['code'] as String?) ??
        context.l10n.lockerHash(lockerId);

    Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        builder: (_) => CreateReportPage(
          cabinetId: lockerId,
          lockerId: lockerId,
          cabinetName: lockerName,
          lockerName: lockerName,
          locationName: widget.store.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lockerAddr = _currentLockerAddress ?? widget.store.address;
    final hasLockerCoord =
        _currentLockerLat != null && _currentLockerLng != null;
    final hasCoord = hasLockerCoord || widget.store.hasLocation;
    final hasKioskInfo =
        widget.store.name.isNotEmpty &&
        widget.store.name.trim().toLowerCase() !=
            (_currentLockerName ?? '').trim().toLowerCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      body: Column(
        children: [
          BrandHeroHeader(
            title: context.l10n.lockerLockerTitle,
            subtitle: _currentLockerName ?? widget.store.name,
            onBack: () => Navigator.pop(context),
            trailing: BrandCircleIconButton(
              child: const AppLottie(
                AppLottieAssets.baoSuCo,
                width: 22,
                height: 22,
              ),
              onTap: () => _openReportLocker(),
            ),
          ),
          // 1. Thanh vị trí chính xác của tủ (đồng bộ từ admin/lockers/5)
          if (lockerAddr != null && lockerAddr.isNotEmpty)
            _AddressBar(
              label: context.l10n.lockerPhysicalLocation,
              address: lockerAddr,
              onDirections: hasCoord ? _openDirections : null,
            ),
          // 2. Thanh vị trí điểm đặt Kiosk (vị trí hiện tại được giữ lại nhưng đặt riêng biệt)
          if (hasKioskInfo)
            _KioskLocationBar(
              kioskName: widget.store.name,
              kioskAddress: widget.store.address,
              onDirections: widget.store.hasLocation
                  ? _openKioskDirections
                  : null,
            ),
          if (!_loading && _error == null && _lockers.isNotEmpty)
            _SummaryBanner(count: _lockers.length),
          if (widget.droneHint && !_loading && _error == null)
            const _DroneHintBanner(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: AppLoadingIndicator(message: context.l10n.lockerListLoading),
      );
    }
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _load);
    }
    if (_lockers.isEmpty) {
      return const _EmptyView();
    }
    return RefreshIndicator(
      color: AislBrand.navy,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _lockers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _LockerCard(
          // Khoá theo id + lần tải để kéo làm mới thì thẻ tải lại layout.
          key: ValueKey(
            'locker-${_lockers[i]['id']}-${identityHashCode(_lockers)}',
          ),
          locker: _lockers[i],
          storeName: widget.store.name,
          service: _service,
          initiallyExpanded: _lockers.length == 1,
          storeLatLng: widget.store.hasLocation
              ? LatLng(widget.store.latitude!, widget.store.longitude!)
              : const LatLng(10.762622, 106.660172),
        ),
      ),
    );
  }
}

/// Nhắc khách vào từ lối "Gửi bằng drone": ô drone là ô màu tím.
class _DroneHintBanner extends StatelessWidget {
  const _DroneHintBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.flight_rounded, color: Color(0xFF4F46E5), size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.lockerDroneCellHint,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF4338CA),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Address + directions bar ──────────────────────────────────────────────────

class _AddressBar extends StatelessWidget {
  const _AddressBar({this.label, this.address, this.onDirections});

  final String? label;
  final String? address;
  final VoidCallback? onDirections;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AislBrand.navy.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AislBrand.navy.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AislBrand.navy.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              LucideIcons.mapPin,
              color: AislBrand.navy,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (label != null && label!.isNotEmpty) ...[
                  Text(
                    label!.toUpperCase(),
                    style: const TextStyle(
                      color: AislBrand.navy,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  address ?? context.l10n.lockerViewOnMap,
                  style: const TextStyle(
                    color: AislBrand.navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onDirections != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDirections,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AislBrand.navy,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AislBrand.navy.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.directions_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      context.l10n.commonDirections,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Kiosk Location Bar ────────────────────────────────────────────────────────

class _KioskLocationBar extends StatelessWidget {
  const _KioskLocationBar({
    required this.kioskName,
    this.kioskAddress,
    this.onDirections,
  });

  final String kioskName;
  final String? kioskAddress;
  final VoidCallback? onDirections;

  @override
  Widget build(BuildContext context) {
    final showAddress =
        kioskAddress != null &&
        kioskAddress!.isNotEmpty &&
        kioskAddress!.trim().toLowerCase() != kioskName.trim().toLowerCase();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              LucideIcons.store,
              color: Color(0xFF4F46E5),
              size: 15,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      context.l10n.lockerKioskPoint,
                      style: TextStyle(
                        color: Color(0xFF4F46E5),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  kioskName,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (showAddress) ...[
                  const SizedBox(height: 1),
                  Text(
                    kioskAddress!,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (onDirections != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDirections,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      color: Color(0xFF4F46E5),
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      context.l10n.commonDirections,
                      style: TextStyle(
                        color: Color(0xFF4F46E5),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Summary banner ────────────────────────────────────────────────────────────

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AislBrand.navy.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.server, color: AislBrand.navy, size: 16),
          const SizedBox(width: 8),
          Text(
            context.l10n.lockerCount(count),
            style: const TextStyle(
              color: AislBrand.navy,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AislBrand.cyan.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                context.l10n.lockerTapToSeeFree,
                style: TextStyle(
                  color: AislBrand.blue,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Locker Card ───────────────────────────────────────────────────────────────

class _LockerCard extends StatefulWidget {
  const _LockerCard({
    super.key,
    required this.locker,
    required this.storeName,
    required this.service,
    required this.storeLatLng,
    this.initiallyExpanded = false,
  });

  final Map<String, dynamic> locker;
  final String storeName;
  final LockerOpsService service;
  final LatLng storeLatLng;
  final bool initiallyExpanded;

  @override
  State<_LockerCard> createState() => _LockerCardState();
}

class _LockerCardState extends State<_LockerCard> {
  bool _expanded = false;
  Map<String, dynamic>? _layout;
  bool _loadingLayout = false;
  String? _layoutError;
  StreamSubscription<AppEvent>? _busSub;
  StreamSubscription<int>? _availabilitySub;

  int get _lockerId => (widget.locker['id'] as num?)?.toInt() ?? 0;

  String get _lockerName {
    final n = widget.locker['name'] as String?;
    final c = widget.locker['code'] as String?;
    return (n?.isNotEmpty == true) ? n! : (c ?? context.l10n.lockerDefaultName);
  }

  List<Map<String, dynamic>> get _currentCells =>
      (_layout?['cells'] as List?)?.cast<Map<String, dynamic>>() ??
      const <Map<String, dynamic>>[];

  /// Trạng thái vận hành: layout mới nhất, chưa có thì theo danh sách tủ.
  String get _statusStr =>
      ((_layout?['status'] ?? widget.locker['status']) as String?)
          ?.toUpperCase() ??
      'ACTIVE';

  /// Cờ `online` của server (layout mới nhất, chưa có thì danh sách tủ); null
  /// khi server cũ chưa trả.
  bool? get _online {
    final fromLayout = _layout?['online'];
    if (fromLayout is bool) return fromLayout;
    final fromList = widget.locker['online'];
    return fromList is bool ? fromList : null;
  }

  @override
  void initState() {
    super.initState();
    if (widget.initiallyExpanded) {
      _expanded = true;
      _loadLayout();
    }
    _busSub = AppEventBus.instance.events.listen((event) {
      if (!mounted) return;
      if (event is LockerLayoutUpdatedEvent) {
        if (event.lockerId == null || event.lockerId == _lockerId.toString()) {
          if (_expanded) {
            _loadLayout(force: true);
          } else {
            setState(() => _layout = null);
          }
        }
      } else if (event is OrderChangedEvent) {
        if (_expanded) {
          _loadLayout(force: true);
        } else {
          setState(() => _layout = null);
        }
      }
    });
    // Người khác đặt/trả ô, KTV khoá/mở ô của tủ này ⇒ cập nhật lưới ngay.
    _availabilitySub = RealtimeNotificationService.instance.lockerAvailability
        .listen((lockerId) {
      if (!mounted || lockerId != _lockerId) return;
      if (_expanded) {
        _loadLayout(force: true, silent: true);
      } else if (_layout != null) {
        setState(() => _layout = null);
      }
    });
  }

  @override
  void dispose() {
    _busSub?.cancel();
    _availabilitySub?.cancel();
    super.dispose();
  }

  /// Tải layout tủ. [force] = tải lại dù đã có (mở lại thẻ, quay về từ màn đặt,
  /// có sự kiện đổi layout). Lỗi ⇒ hiện lỗi thật + Thử lại, không vẽ lưới giả.
  /// [silent] (tin ô trống realtime): giữ lưới đang hiện tới khi có lưới mới,
  /// lỗi thì giữ lưới cũ.
  Future<void> _loadLayout({bool force = false, bool silent = false}) async {
    if (_loadingLayout || (_layout != null && !force)) return;
    final quiet = silent && _layout != null;
    if (!quiet) {
      setState(() {
        _loadingLayout = true;
        _layoutError = null;
      });
    }
    try {
      final layout = await widget.service.layout(_lockerId);
      if (mounted) {
        setState(() {
          _layout = LockerLayoutHelper.enrichLayout(layout);
          _loadingLayout = false;
        });
      }
    } catch (e) {
      if (mounted && !quiet) {
        setState(() {
          _layoutError = LockerOpsService.errorMessage(e);
          _loadingLayout = false;
        });
      }
    }
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    // Mở lại thẻ thì tải lại để thấy ô vừa có người đặt.
    if (_expanded) _loadLayout(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final cells = _currentCells;
    final totalCells =
        (_layout?['totalCells'] as num?)?.toInt() ?? cells.length;
    final available = cells.where((c) => c['status'] == 'AVAILABLE').length;

    final statusStr = _statusStr;
    final bool isDisconnected = _online == false || statusStr == 'DISCONNECTED';
    final bool isMaintenance = statusStr == 'MAINTENANCE';
    final bool isActive = statusStr == 'ACTIVE' && !isDisconnected;
    final blockReason = LockerLayoutHelper.bookingBlockReason(
      status: statusStr,
      online: _online,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(
            isActive: isActive,
            isMaintenance: isMaintenance,
            isDisconnected: isDisconnected,
            available: available,
            totalCells: totalCells,
          ),
          if (isDisconnected)
            _StateNotice(
              icon: LucideIcons.wifiOff,
              text:
                  context.l10n.lockerOfflineCantBook,
              color: Color(0xFFB91C1C),
              background: Color(0xFFFEF2F2),
              border: Color(0xFFFECACA),
            )
          else if (isMaintenance)
            _StateNotice(
              icon: LucideIcons.wrench,
              text: context.l10n.lockerUnderMaintenance,
              color: Color(0xFFB45309),
              background: Color(0xFFFFFBEB),
              border: Color(0xFFFDE68A),
            )
          else if (!isActive)
            _StateNotice(
              icon: LucideIcons.ban,
              text: context.l10n.lockerSuspended,
              color: Color(0xFF475569),
              background: Color(0xFFF1F5F9),
              border: Color(0xFFE2E8F0),
            ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _expanded
                ? _buildExpandedContent(
                    cells,
                    isOnline: !isDisconnected,
                    blockReason: blockReason,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader({
    required bool isActive,
    required bool isMaintenance,
    required bool isDisconnected,
    required int available,
    required int totalCells,
  }) {
    return InkWell(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      onTap: _toggle,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Cabinet icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AislBrand.brandGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                LucideIcons.server,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Name + badges
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _lockerName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AislBrand.textTitle,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (_layout != null)
                        _Pill(
                          label: context.l10n.lockerFreeOfTotal(available, totalCells),
                          bg: available > 0
                              ? AislBrand.cyan
                              : const Color(0xFFE2E8F0),
                          fg: available > 0 ? Colors.white : Colors.grey,
                        ),
                      if (isDisconnected)
                        _Pill(
                          label: context.l10n.commonDisconnected,
                          bg: Color(0xFFFDE8E8),
                          fg: Color(0xFF9B1C1C),
                        )
                      else if (isMaintenance)
                        _Pill(
                          label: context.l10n.enumMaintenance,
                          bg: Color(0xFFFEF3C7),
                          fg: Color(0xFFD97706),
                        )
                      else if (isActive)
                        _Pill(
                          label: context.l10n.commonStatusActive,
                          bg: Color(0xFFDEF7EC),
                          fg: Color(0xFF046C4E),
                        )
                      else
                        _Pill(
                          label: context.l10n.commonStatusSuspended,
                          bg: Color(0xFFF1F5F9),
                          fg: Color(0xFF64748B),
                        ),
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Navigator.of(context, rootNavigator: true).push<void>(
                            MaterialPageRoute(
                              builder: (_) => CreateReportPage(
                                cabinetId: '$_lockerId',
                                lockerId: '$_lockerId',
                                cabinetName: _lockerName,
                                lockerName: _lockerName,
                                locationName: widget.storeName,
                                initialLayout: _layout,
                                initialCells: _currentCells,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFECDD3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppLottie(
                                AppLottieAssets.baoSuCo,
                                width: 14,
                                height: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                context.l10n.commonReportIssue,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE11D48),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Chevron
            AnimatedRotation(
              turns: _expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: const Icon(
                LucideIcons.chevronDown,
                color: AislBrand.navy,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent(
    List<Map<String, dynamic>> cells, {
    required bool isOnline,
    required String? blockReason,
  }) {
    return Column(
      children: [
        const Divider(height: 1, color: Color(0xFFF0F4F8)),
        if (_loadingLayout)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: CircularProgressIndicator(
                color: AislBrand.navy,
                strokeWidth: 2.5,
              ),
            ),
          )
        else if (_layoutError != null)
          _LayoutErrorRow(
            message: _layoutError!,
            onRetry: () => _loadLayout(force: true),
          )
        else if (cells.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: Text(
                context.l10n.lockerNoCellsConfigured,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          _CellGrid(
            cells: cells,
            isOnline: isOnline,
            lockerId: _lockerId,
            lockerName: _lockerName,
            lockerCode: widget.locker['code']?.toString(),
            storeName: widget.storeName,
            onCellTap: (cell) {
              // Tủ mất kết nối / bảo trì / tạm ngưng: không mở đặt ô, báo lý do.
              if (blockReason != null) {
                _showBlocked(context, blockReason);
                return;
              }
              _showBookingSheet(context, cell);
            },
            onFaultTap: (cell) => _showFaultHint(context, cell),
          ),
      ],
    );
  }

  void _showBlocked(BuildContext ctx, String reason) {
    ScaffoldMessenger.of(ctx)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(reason)));
  }

  void _showFaultHint(BuildContext ctx, Map<String, dynamic> cell) {
    final boxLabel = _boxLabel(cell);
    final reason = (cell['faultReason'] as String?)?.trim();
    final pending =
        (cell['status'] as String?)?.toUpperCase() == 'PENDING_CHECK';
    // Ô khách vừa báo: chưa chắc hỏng, KTV sẽ kiểm tra — tạm không nhận đơn mới.
    final state = pending
        ? context.l10n.lockerBoxPendingCheck
        : context.l10n.lockerBoxBroken;
    final message = reason == null || reason.isEmpty
        ? context.l10n.lockerBoxUnavailable(boxLabel, state)
        : context.l10n.lockerBoxUnavailableReason(boxLabel, state, reason);

    ScaffoldMessenger.of(ctx)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: SnackBarAction(
            label: context.l10n.commonReportIssue,
            textColor: Colors.amberAccent,
            onPressed: () {
              Navigator.of(ctx, rootNavigator: true).push<void>(
                MaterialPageRoute(
                  builder: (_) => CreateReportPage(
                    cabinetId: '$_lockerId',
                    lockerId: '$_lockerId',
                    cabinetName: _lockerName,
                    lockerName: _lockerName,
                    locationName: widget.storeName,
                    initialBoxId: (cell['id'] as num?)?.toInt(),
                    initialLayout: _layout,
                    initialCells: (_layout?['cells'] as List?)
                        ?.cast<Map<String, dynamic>>(),
                  ),
                ),
              );
            },
          ),
        ),
      );
  }

  String _boxLabel(Map<String, dynamic> cell) {
    final boxNum = (cell['boxNumber'] as num?)?.toInt();
    if (boxNum != null) return context.l10n.boxNumberLabel(boxNum);
    final r = (cell['rowIndex'] as num?)?.toInt() ?? 0;
    final c = (cell['colIndex'] as num?)?.toInt() ?? 0;
    return context.l10n.boxRowCol(r + 1, c + 1);
  }

  void _showBookingSheet(BuildContext ctx, Map<String, dynamic> cell) {
    // DRONE cells use home pickup booking; XL cells use locker rental.
    if (LockerLayoutHelper.isDrone(cell)) {
      // Ô drone là nơi NHẬN hàng: khách gửi hàng bằng drone tới tủ này. Kiện được kỹ
      // thuật viên tới lấy tận nhà người gửi, nên form đặt đơn mở với tủ này chọn sẵn
      // làm tủ nhận. Quay lại thì nạp lại sơ đồ để ô vừa giữ chuyển xám.
      ctx
          .push(
            AppRouter.droneBooking,
            extra: {
              'destinationLockerId': _lockerId,
              'preferredBoxId': (cell['id'] as num?)?.toInt(),
            },
          )
          .then((_) {
            if (!mounted) return;
            setState(() => _layout = null);
            _loadLayout();
          });
      return;
    }

    final isXl = LockerLayoutHelper.isXl(cell);
    final boxId = (cell['id'] as num?)?.toInt();
    final boxNumber = (cell['boxNumber'] as num?)?.toInt();

    // Mở trang đặt chồng lên sheet (không đóng sheet trước) để bấm quay lại thì
    // về đúng sheet chọn dịch vụ. Quay về: tải lại sơ đồ; ô đã bị giữ/đặt thì
    // đóng sheet vì nó không còn "trống".
    Future<void> openOnTopOfSheet(BuildContext sheetCtx, Widget page) async {
      await Navigator.push<void>(
        sheetCtx,
        MaterialPageRoute(builder: (_) => page),
      );
      if (!mounted || !_expanded) return;
      await _loadLayout(force: true);
      if (!mounted || !sheetCtx.mounted) return;
      if (!_cellStillAvailable(boxId) &&
          (ModalRoute.of(sheetCtx)?.isCurrent ?? false)) {
        Navigator.pop(sheetCtx);
      }
    }

    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _BookingSheet(
        cell: cell,
        lockerId: _lockerId,
        lockerName: _lockerName,
        storeName: widget.storeName,
        onRent: () => openOnTopOfSheet(
          sheetCtx,
          RentLockerPage(
            initialLockerId: _lockerId,
            initialLockerName: _lockerName,
            locationName: widget.storeName,
            initialCellType: isXl ? 'XL' : 'STANDARD',
            initialBoxId: boxId,
            initialBoxNumber: boxNumber,
          ),
        ),
        // Ô vali XL chỉ để thuê giữ đồ, không gửi hàng C2C (CellType.XL).
        onSend: isXl
            ? null
            : () => openOnTopOfSheet(
                  sheetCtx,
                  SendParcelPage(
                    initialLockerId: _lockerId,
                    initialLockerName: _lockerName,
                    locationName: widget.storeName,
                    // Giữ đúng ô khách vừa chọn trên sơ đồ.
                    initialBoxId: boxId,
                    initialBoxNumber: boxNumber,
                    initialBoxSize: cell['size'] as String?,
                  ),
                ),
      ),
    );
  }

  /// Ô [boxId] còn trống trên sơ đồ mới nhất? Không tìm thấy ⇒ coi như còn.
  bool _cellStillAvailable(int? boxId) {
    final match =
        _currentCells.where((c) => (c['id'] as num?)?.toInt() == boxId);
    return match.isEmpty || match.first['status'] == 'AVAILABLE';
  }
}

class _StateNotice extends StatelessWidget {
  const _StateNotice({
    required this.icon,
    required this.text,
    required this.color,
    required this.background,
    required this.border,
  });

  final IconData icon;
  final String text;
  final Color color;
  final Color background;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sơ đồ ô theo đúng `rowIndex`/`colIndex`/`cellType` backend trả. Ô vali XL
/// chiếm 2 hàng. Màn hình kiosk (không có trong layout) vẽ vào ô trống đầu tiên
/// của cột ngoài cùng bên trái, nếu cột đó có chỗ trống.
class _CellGrid extends StatelessWidget {
  const _CellGrid({
    required this.cells,
    required this.onCellTap,
    required this.onFaultTap,
    required this.lockerId,
    required this.lockerName,
    required this.storeName,
    this.lockerCode,
    this.isOnline = true,
  });
  final List<Map<String, dynamic>> cells;
  final ValueChanged<Map<String, dynamic>> onCellTap;
  final ValueChanged<Map<String, dynamic>> onFaultTap;
  final bool isOnline;
  final int lockerId;
  final String lockerName;
  final String? lockerCode;
  final String storeName;

  static const double _rowHeight = 80;
  static const double _gap = 6;

  VoidCallback? _tapFor(Map<String, dynamic> cell) =>
      switch ((cell['status'] as String?)?.toUpperCase()) {
        'AVAILABLE' => () => onCellTap(cell),
        'FAULT' || 'PENDING_CHECK' => () => onFaultTap(cell),
        _ => null,
      };

  Widget _sized(double height, Widget? child) => Padding(
    padding: const EdgeInsets.only(bottom: _gap),
    child: SizedBox(height: height, child: child),
  );

  @override
  Widget build(BuildContext context) {
    if (cells.isEmpty) return const SizedBox.shrink();

    final positioned = cells.every(
      (c) => c['rowIndex'] is num && c['colIndex'] is num,
    );
    if (!positioned) return _buildFlow(context);

    var minRow = 1 << 30, maxRow = -1, minCol = 1 << 30, maxCol = -1;
    final grid = <int, Map<int, Map<String, dynamic>>>{};
    for (final c in cells) {
      final r = (c['rowIndex'] as num).toInt();
      final col = (c['colIndex'] as num).toInt();
      if (r < minRow) minRow = r;
      if (r > maxRow) maxRow = r;
      if (col < minCol) minCol = col;
      if (col > maxCol) maxCol = col;
      grid.putIfAbsent(col, () => {})[r] = c;
    }

    var screenPlaced = false;
    final columns = <Widget>[];
    for (var col = minCol; col <= maxCol; col++) {
      final colChildren = <Widget>[];
      var skip = 0;
      for (var row = minRow; row <= maxRow; row++) {
        if (skip > 0) {
          skip--;
          continue;
        }
        final cell = grid[col]?[row];
        if (cell == null) {
          final showScreen = !screenPlaced && col == minCol;
          if (showScreen) screenPlaced = true;
          colChildren.add(
            _sized(
              _rowHeight,
              showScreen
                  ? _ScreenTile(
                      isOnline: isOnline,
                      onTap: () => _showScreenDetailSheet(
                        context,
                        isOnline: isOnline,
                        lockerId: lockerId,
                        lockerName: lockerName,
                        lockerCode: lockerCode,
                        storeName: storeName,
                      ),
                    )
                  : null,
            ),
          );
          continue;
        }
        // Ô vali XL chiếm 2 hàng nếu ô ngay dưới đang trống.
        final span =
            LockerLayoutHelper.isXl(cell) &&
                row < maxRow &&
                grid[col]?[row + 1] == null
            ? 2
            : 1;
        skip = span - 1;
        colChildren.add(
          _sized(
            _rowHeight * span + _gap * (span - 1),
            _CellTile(cell: cell, onTap: _tapFor(cell)),
          ),
        );
      }
      columns.add(
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(children: colChildren),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _GridLegend(),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: columns,
          ),
        ),
      ],
    );
  }

  /// Layout thiếu toạ độ ô (dữ liệu cũ): xếp theo số ô, 3 cột.
  Widget _buildFlow(BuildContext context) {
    const perRow = 3;
    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += perRow) {
      final slice = cells.skip(i).take(perRow).toList();
      rows.add(
        Row(
          children: [
            for (var j = 0; j < perRow; j++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _sized(
                    _rowHeight,
                    j < slice.length
                        ? _CellTile(cell: slice[j], onTap: _tapFor(slice[j]))
                        : null,
                  ),
                ),
              ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _GridLegend(),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
          child: Column(children: rows),
        ),
      ],
    );
  }
}

class _GridLegend extends StatelessWidget {
  const _GridLegend();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _LegendChip(
            color: Color(0xFF0284C7),
            label: context.l10n.lockerScreen7,
            icon: LucideIcons.monitor,
          ),
          _LegendChip(color: _CellPalette.available, label: context.l10n.commonEmpty),
          _LegendChip(color: _CellPalette.occupied, label: context.l10n.commonInUseShort),
          _LegendChip(color: _CellPalette.reserved, label: context.l10n.commonReservedShort),
          _LegendChip(color: _CellPalette.fault, label: context.l10n.lockerFaultBroken),
          _LegendChip(color: _CellPalette.cleaning, label: context.l10n.enumMaintenance),
          _LegendChip(
            color: _CellPalette.drone,
            label: 'Drone',
            icon: Icons.flight_rounded,
          ),
          _LegendChip(
            color: _CellPalette.available,
            label: 'Vali (XL)',
            icon: LucideIcons.luggage,
          ),
          _LegendChip(
            color: Color(0xFFD97706),
            label: context.l10n.lockerDoorOpen,
            icon: LucideIcons.doorOpen,
          ),
          _LegendChip(
            color: Color(0xFF64748B),
            label: context.l10n.lockerDoorClosed,
            icon: LucideIcons.doorClosed,
          ),
        ],
      ),
    );
  }
}

void _showScreenDetailSheet(
  BuildContext context, {
  required bool isOnline,
  required int lockerId,
  required String lockerName,
  required String storeName,
  String? lockerCode,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _KioskScreenDetailSheet(
      isOnline: isOnline,
      lockerId: lockerId,
      lockerName: lockerName,
      lockerCode: lockerCode,
      storeName: storeName,
    ),
  );
}

class _ScreenTile extends StatelessWidget {
  const _ScreenTile({required this.onTap, this.isOnline = true});
  final VoidCallback onTap;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isOnline
                ? const Color(0xFF38BDF8).withValues(alpha: 0.6)
                : const Color(0xFFEF4444).withValues(alpha: 0.5),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isOnline
                  ? const Color(0xFF0284C7).withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Ánh phản chiếu màn hình gương
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 28,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(9),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Hàng tiêu đề: Icon Monitor + Tên + Badge 7"
                  Row(
                    children: [
                      Icon(
                        LucideIcons.monitor,
                        size: 11,
                        color: isOnline
                            ? const Color(0xFF38BDF8)
                            : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          context.l10n.lockerScreen,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 0.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF0369A1,
                          ).withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: const Color(
                              0xFF38BDF8,
                            ).withValues(alpha: 0.4),
                            width: 0.6,
                          ),
                        ),
                        child: const Text(
                          '7"',
                          style: TextStyle(
                            color: Color(0xFFBAE6FD),
                            fontSize: 7.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Giữa: Icon Tablet Kiosk
                  Center(
                    child: Icon(
                      LucideIcons.tablet,
                      size: 20,
                      color: isOnline
                          ? const Color(0xFF67E8F9)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  // Đáy: Trạng thái Online / Offline dạng capsule
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: isOnline
                            ? const Color(0xFF065F46).withValues(alpha: 0.35)
                            : const Color(0xFF7F1D1D).withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isOnline
                              ? const Color(0xFF10B981).withValues(alpha: 0.4)
                              : const Color(0xFFEF4444).withValues(alpha: 0.4),
                          width: 0.6,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFFEF4444),
                              shape: BoxShape.circle,
                              boxShadow: isOnline
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF22C55E,
                                        ).withValues(alpha: 0.9),
                                        blurRadius: 4,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 3.5),
                          Text(
                            isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              color: isOnline
                                  ? const Color(0xFF86EFAC)
                                  : const Color(0xFFFCA5A5),
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thông tin màn hình kiosk của tủ: trạng thái kết nối do server báo và cách
/// dùng. Không ghi thông số phần cứng cứng trong app (mỗi tủ có thể khác).
class _KioskScreenDetailSheet extends StatelessWidget {
  const _KioskScreenDetailSheet({
    required this.isOnline,
    required this.lockerId,
    required this.lockerName,
    required this.storeName,
    this.lockerCode,
  });

  final bool isOnline;
  final int lockerId;
  final String lockerName;
  final String? lockerCode;
  final String storeName;

  @override
  Widget build(BuildContext context) {
    final code = (lockerCode ?? '').trim();
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thanh kéo handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Icon(
                    LucideIcons.monitor,
                    color: Color(0xFF38BDF8),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.lockerKioskScreen,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        code.isEmpty ? lockerName : '$lockerName ($code)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isOnline
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isOnline
                          ? const Color(0xFFA7F3D0)
                          : const Color(0xFFFECACA),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isOnline
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isOnline ? context.l10n.commonOnline : context.l10n.commonDisconnected,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isOnline
                              ? const Color(0xFF047857)
                              : const Color(0xFFB91C1C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Khung hướng dẫn khách hàng
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.info, size: 18, color: Color(0xFF16A34A)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.l10n.lockerKioskHelp,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF15803D),
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!isOnline) ...[
              const SizedBox(height: 10),
              Text(
                context.l10n.lockerKioskOffline,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFB91C1C),
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFFECACA)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context, rootNavigator: true).push<void>(
                    MaterialPageRoute(
                      builder: (_) => CreateReportPage(
                        cabinetId: '$lockerId',
                        lockerId: '$lockerId',
                        cabinetName: lockerName,
                        lockerName: lockerName,
                        locationName: storeName,
                      ),
                    ),
                  );
                },
                icon: const Icon(LucideIcons.alertCircle, size: 16),
                label: Text(
                  context.l10n.lockerReportKioskIssue,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  context.l10n.commonClose,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label, this.icon});
  final Color color;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon != null
              ? Icon(icon, color: color, size: 12)
              : Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cell Tile ─────────────────────────────────────────────────────────────────

abstract class _CellPalette {
  static const Color available = AislBrand.cyan;
  static const Color occupied = Color(0xFFCBD5E1);
  static const Color reserved = Color(0xFFFBBF24);
  static const Color fault = Color(0xFFEF4444);
  static const Color cleaning = Color(0xFF60A5FA);
  // Ô drone: tím indigo — phân biệt rõ với ô thường dù status AVAILABLE
  static const Color drone = Color(0xFF6366F1);
}

class _CellTile extends StatelessWidget {
  const _CellTile({required this.cell, this.onTap});
  final Map<String, dynamic> cell;
  final VoidCallback? onTap;

  String get _status => ((cell['status'] as String?) ?? '').toUpperCase();
  int? get _boxNumber => (cell['boxNumber'] as num?)?.toInt();

  // Loại ô lấy đúng `cellType` backend trả: XL = ô vali (thuê giữ đồ), DRONE =
  // ô nhận hàng drone. Không suy theo vị trí cột hay số ô.
  bool get _isXl => LockerLayoutHelper.isXl(cell);
  bool get _isDrone => LockerLayoutHelper.isDrone(cell);

  bool get _isAvailable => _status == 'AVAILABLE';
  bool get _isFault => _status == 'FAULT';
  bool get _isPendingCheck => _status == 'PENDING_CHECK';
  bool get _isCleaning => _status == 'CLEANING';

  bool get _isDoorOpen =>
      cell['doorOpen'] == true ||
      ((cell['hwState'] as String?)?.toUpperCase() == 'OPEN');

  Gradient get _bgGradient {
    // Ô drone chỉ tô tím khi còn nhận đơn. Đã có đơn giữ ô (RESERVED/OCCUPIED)
    // hoặc ô đang hỏng/bảo trì thì theo màu trạng thái như mọi ô khác.
    if (_isDrone && _isAvailable) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF818CF8), Color(0xFF4F46E5)],
      );
    }
    return switch (_status) {
      'AVAILABLE' => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AislBrand.cyan.withValues(alpha: 0.8), AislBrand.cyan],
      ),
      'OCCUPIED' || 'IN_USE' => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF1F5F9), Color(0xFFCBD5E1)],
      ),
      // Ô drone đã có đơn: xám, không phân biệt đang giữ chỗ hay đã có hàng.
      'RESERVED' when _isDrone => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF1F5F9), Color(0xFFCBD5E1)],
      ),
      'RESERVED' => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)],
      ),
      'FAULT' => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFCA5A5), Color(0xFFDC2626)],
      ),
      'PENDING_CHECK' => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFDBA74), Color(0xFFEA580C)],
      ),
      'CLEANING' => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF93C5FD), Color(0xFF3B82F6)],
      ),
      _ => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE5E7EB), Color(0xFF9CA3AF)],
      ),
    };
  }

  bool get _isGreyedOut =>
      _status == 'OCCUPIED' ||
      _status == 'IN_USE' ||
      (_isDrone && _status == 'RESERVED');

  Color get _fg {
    if (_isGreyedOut) {
      return const Color(0xFF64748B);
    }
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: _bgGradient,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isDoorOpen
              ? const Color(0xFFFBBF24)
              : Colors.white.withValues(alpha: 0.3),
          width: _isDoorOpen ? 1.5 : 1,
        ),
        boxShadow: (_isAvailable && !_isDrone)
            ? [
                BoxShadow(
                  color: _CellPalette.available.withValues(alpha: 0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : (_isDrone && _isAvailable)
            ? [
                BoxShadow(
                  color: _CellPalette.drone.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: _buildCellContent()),
          if (_isFault || _isPendingCheck)
            Positioned(
              left: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _isFault ? context.l10n.lockerBrokenUpper : context.l10n.lockerPendingCheckUpper,
                  style: TextStyle(
                    color: _isFault
                        ? const Color(0xFFDC2626)
                        : const Color(0xFFEA580C),
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          // Tay nắm cửa
          Positioned(
            right: 5,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                width: 3.5,
                height: 22,
                decoration: BoxDecoration(
                  color: _fg.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 2,
                      offset: const Offset(-1, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (_isAvailable) {
      content = content
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .shimmer(
            duration: 2000.ms,
            color: Colors.white.withValues(alpha: 0.2),
          )
          .scaleXY(end: 1.015, curve: Curves.easeInOutSine, duration: 1500.ms);
    }

    return GestureDetector(onTap: onTap, child: content);
  }

  Widget _buildCellContent() {
    final isXl = _isXl;
    final icon = _isDrone
        ? Icons.flight_rounded
        : (isXl ? LucideIcons.luggage : LucideIcons.box);
    final iconSize = _isDrone ? 20.0 : (isXl ? 20.0 : 16.0);

    final String statusText;
    if (_isFault) {
      statusText = L10n.current.commonBroken;
    } else if (_isPendingCheck) {
      statusText = L10n.current.lockerPendingCheck;
    } else if (_isCleaning) {
      statusText = L10n.current.lockerCleaning;
    } else if (_status == 'OCCUPIED' || _status == 'IN_USE') {
      statusText = L10n.current.commonInUseShort;
    } else if (_status == 'RESERVED') {
      statusText = L10n.current.commonReservedShort;
    } else if (_isDrone && _isAvailable) {
      statusText = L10n.current.lockerDroneReceive;
    } else if (_isAvailable) {
      statusText = L10n.current.lockerReady;
    } else {
      statusText = _status;
    }

    final boxEmoji = _isDrone ? ' 🛸' : (isXl ? ' 🧳' : '');

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Hàng trên: Số ô & Trạng thái cửa
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '${L10n.current.boxHash(_boxNumber ?? '?')}$boxEmoji',
                  style: TextStyle(
                    color: _fg,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              _buildDoorBadge(),
            ],
          ),
          // Giữa: Icon loại ô
          Center(
            child: Icon(
              icon,
              color: _fg.withValues(alpha: 0.95),
              size: iconSize,
            ),
          ),
          // Hàng dưới: Trạng thái ô (Sẵn sàng / Đang dùng / Báo hỏng / ...)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: _isAvailable
                    ? Colors.white.withValues(alpha: 0.22)
                    : Colors.black.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: _fg,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoorBadge() {
    if (_isDoorOpen) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 3.5, vertical: 1),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF08A),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: const Color(0xFFEAB308), width: 0.8),
        ),
        child: const Icon(
          LucideIcons.doorOpen,
          size: 9,
          color: Color(0xFF854D0E),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3.5, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Icon(
        LucideIcons.doorClosed,
        size: 9,
        color: _fg.withValues(alpha: 0.8),
      ),
    );
  }
}

// ── Booking Bottom Sheet ──────────────────────────────────────────────────────

class _BookingSheet extends StatelessWidget {
  const _BookingSheet({
    required this.cell,
    required this.lockerId,
    required this.lockerName,
    required this.storeName,
    required this.onRent,
    this.onSend,
  });

  final Map<String, dynamic> cell;
  final int lockerId;
  final String lockerName;
  final String storeName;
  final VoidCallback onRent;

  /// null ⇒ ô này không gửi hàng được (ô vali XL chỉ để thuê giữ đồ).
  final VoidCallback? onSend;

  bool get _isXl => LockerLayoutHelper.isXl(cell);

  String get _sizeVi => switch ((cell['size'] as String?) ?? '') {
    'SMALL' => L10n.current.sizeSmall,
    'MEDIUM' => L10n.current.sizeMedium,
    'LARGE' => L10n.current.sizeLarge,
    _ => _isXl ? L10n.current.sizeXlSuitcase : ((cell['cellType'] as String?) ?? '—'),
  };

  String get _boxLabel {
    final boxNum = (cell['boxNumber'] as num?)?.toInt();
    if (boxNum != null) return L10n.current.boxNumberLabel(boxNum);
    final r = (cell['rowIndex'] as num?)?.toInt() ?? 0;
    final c = (cell['colIndex'] as num?)?.toInt() ?? 0;
    return L10n.current.rowCol(r + 1, c + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header row
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AislBrand.cyan.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _isXl
                    ? const Icon(
                        LucideIcons.luggage,
                        color: AislBrand.navy,
                        size: 28,
                      )
                    : AppLottie(
                        AppLottieAssets.box,
                        fallback: (context) => const Icon(
                          LucideIcons.box,
                          color: AislBrand.navy,
                          size: 26,
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isXl ? context.l10n.lockerEmptySuitcaseBox : context.l10n.lockerEmptyBox,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AislBrand.textTitle,
                      ),
                    ),
                    Text(
                      '$lockerName · $storeName',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AislBrand.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Cell info card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AislBrand.chipBorder),
            ),
            child: Row(
              children: [
                _SheetInfoTile(
                  icon: Icons.straighten_rounded,
                  label: context.l10n.commonSize,
                  value: _sizeVi,
                ),
                const _VerticalDivider(),
                _SheetInfoTile(
                  icon: Icons.tag_rounded,
                  label: context.l10n.commonLocation,
                  value: _boxLabel,
                ),
                const _VerticalDivider(),
                _SheetInfoTile(
                  icon: Icons.check_circle_outline_rounded,
                  label: context.l10n.commonStatus,
                  value: context.l10n.commonEmpty,
                  valueColor: AislBrand.cyan,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            context.l10n.lockerWhatToDo,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 14),

          // Service buttons
          Row(
            children: [
              Expanded(
                child: _ServiceButton(
                  lottieAsset: AppLottieAssets.box,
                  label: context.l10n.homeRentLocker,
                  sublabel: context.l10n.lockerRentSubtitle,
                  gradient: const LinearGradient(
                    colors: [AislBrand.navy, AislBrand.blue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: onRent,
                ),
              ),
              if (onSend != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _ServiceButton(
                    lottieAsset: AppLottieAssets.box,
                    label: context.l10n.lockerSendParcel,
                    sublabel: context.l10n.lockerSendSubtitle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1D4ED8), Color(0xFF0284C7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: onSend!,
                  ),
                ),
              ],
            ],
          ),
          if (onSend == null) ...[
            const SizedBox(height: 10),
            Text(
              context.l10n.lockerSuitcaseRentOnly,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AislBrand.textMuted),
            ),
          ],
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context, rootNavigator: true).push<void>(
                MaterialPageRoute(
                  builder: (_) => CreateReportPage(
                    cabinetId: '$lockerId',
                    lockerId: '$lockerId',
                    cabinetName: lockerName,
                    lockerName: lockerName,
                    locationName: storeName,
                    initialBoxId: (cell['id'] as num?)?.toInt(),
                    initialCells: [cell],
                  ),
                ),
              );
            },
            icon: const Icon(
              LucideIcons.alertTriangle,
              size: 14,
              color: Color(0xFFEF4444),
            ),
            label: Text(
              context.l10n.lockerReportBoxIssue,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetInfoTile extends StatelessWidget {
  const _SheetInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: AislBrand.navy),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AislBrand.textMuted),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AislBrand.textTitle,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 44,
      color: AislBrand.chipBorder,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

class _ServiceButton extends StatelessWidget {
  const _ServiceButton({
    required this.lottieAsset,
    required this.label,
    required this.sublabel,
    required this.gradient,
    required this.onTap,
  });

  final String lottieAsset;
  final String label;
  final String sublabel;
  final LinearGradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shadowColor: gradient.colors.first.withValues(alpha: 0.35),
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(gradient: gradient),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: AppLottie(
                    lottieAsset,
                    fallback: (context) => Icon(
                      lottieAsset == AppLottieAssets.airplaneBox
                          ? LucideIcons.send
                          : LucideIcons.box,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  sublabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
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

// ── Helper widgets ────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.bg, required this.fg});
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class _LayoutErrorRow extends StatelessWidget {
  const _LayoutErrorRow({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          const Icon(
            LucideIcons.triangleAlert,
            color: Colors.redAccent,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(LucideIcons.refreshCcw, size: 14),
            label: Text(context.l10n.commonRetry),
            style: TextButton.styleFrom(foregroundColor: AislBrand.navy),
          ),
        ],
      ),
    );
  }
}

// ── Full-page error / empty states ────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                LucideIcons.triangleAlert,
                color: Color(0xFFEF4444),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.commonLoadFailedData,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AislBrand.textTitle,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: AislBrand.textMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCcw, size: 16),
              label: Text(context.l10n.commonRetry),
              style: FilledButton.styleFrom(backgroundColor: AislBrand.navy),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AislBrand.navy.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.server,
                color: AislBrand.navy,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.l10n.lockerNoLockers,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AislBrand.textTitle,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.lockerStoreNoActiveLockers,
              style: TextStyle(fontSize: 14, color: AislBrand.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
