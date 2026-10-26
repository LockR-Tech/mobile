import 'dart:async';

import 'package:smart_laundry_locker/core/services/app_event_bus.dart';
import 'package:smart_laundry_locker/features/notifications/infrastructure/services/realtime_notification_service.dart';
import 'package:smart_laundry_locker/features/locker/domain/entities/locker_location.dart';
import 'package:smart_laundry_locker/features/locker/domain/utils/locker_layout_helper.dart';
import 'package:smart_laundry_locker/features/locker/presentation/widgets/locker_info_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/location_services.dart';
import 'package:smart_laundry_locker/features/promotions/presentation/widgets/locker_offers_section.dart';
import 'package:smart_laundry_locker/features/stores/presentation/pages/store_lockers_page.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

/// Chi tiết một tủ trên bản đồ: vị trí, trạng thái kết nối và số ô trống theo
/// loại ô (tải từ `GET /api/lockers/{id}/layout`).
class LockerDetailMapPage extends StatefulWidget {
  final LockerLocation location;
  final LockerOpsService? service;

  const LockerDetailMapPage({super.key, required this.location, this.service});

  @override
  State<LockerDetailMapPage> createState() => _LockerDetailMapPageState();
}

class _LockerDetailMapPageState extends State<LockerDetailMapPage> {
  late final DraggableScrollableController _draggableScrollableController;
  late final LockerOpsService _service = widget.service ?? LockerOpsService();

  List<LockerCellGroupCount>? _cellGroups;
  bool _loadingCells = false;
  String? _cellsError;
  bool? _layoutOnline;
  String? _layoutStatus;
  StreamSubscription<int>? _availabilitySub;
  StreamSubscription<AppEvent>? _eventSub;

  @override
  void initState() {
    super.initState();
    _draggableScrollableController = DraggableScrollableController();
    _loadCells();
    // Số ô trống đổi (người khác đặt/trả ô, KTV khoá ô) hoặc admin đổi trạng
    // thái tủ ⇒ cập nhật ngay, giữ số đang hiện trong lúc tải.
    final lockerId = int.tryParse(widget.location.id);
    _availabilitySub = RealtimeNotificationService.instance.lockerAvailability
        .listen((changed) {
      if (mounted && changed == lockerId) _loadCells(silent: true);
    });
    _eventSub = AppEventBus.instance.events.listen((event) {
      if (mounted &&
          event is CatalogChangedEvent &&
          event.isLocker &&
          event.id == widget.location.id) {
        _loadCells(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _availabilitySub?.cancel();
    _eventSub?.cancel();
    _draggableScrollableController.dispose();
    super.dispose();
  }

  Future<void> _loadCells({bool silent = false}) async {
    final lockerId = int.tryParse(widget.location.id);
    if (lockerId == null) return;
    final quiet = silent && _cellGroups != null;
    if (!quiet) {
      setState(() {
        _loadingCells = true;
        _cellsError = null;
      });
    }
    try {
      final layout = await _service.layout(lockerId);
      if (!mounted) return;
      final cells = layout['cells'];
      setState(() {
        _cellGroups = LockerLayoutHelper.summarizeCells(
          cells is List ? cells : const [],
        );
        _layoutOnline = layout['online'] is bool ? layout['online'] as bool : null;
        _layoutStatus = layout['status']?.toString();
        _loadingCells = false;
      });
    } catch (e) {
      if (!mounted || quiet) return;
      setState(() {
        _cellsError = LockerOpsService.errorMessage(e);
        _loadingCells = false;
      });
    }
  }

  bool? get _online => _layoutOnline ?? widget.location.online;

  String? get _blockReason => LockerLayoutHelper.bookingBlockReason(
    status: _layoutStatus ?? widget.location.status,
    online: _online,
  );

  void _openGrid() {
    Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        builder: (_) => StoreLockerGridPage.forLocation(widget.location),
      ),
    );
  }

  /// "Ưu đãi tại tủ này" — mã giảm giá chỉ dùng ở tủ này; tự ẩn khi không có.
  Widget? _offersSection({EdgeInsetsGeometry padding = const EdgeInsets.only(bottom: 8)}) {
    final lockerId = int.tryParse(widget.location.id);
    if (lockerId == null) return null;
    return LockerOffersSection(
      lockerId: lockerId,
      service: _service,
      padding: padding,
    );
  }

  void _onMapTap() {
    _draggableScrollableController.animateTo(
      0.15,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // ko render map nếu toạ độ ko hợp lệ
    if (!widget.location.hasValidCoordinate) {
      final reason = _blockReason;
      return Scaffold(
        body: Column(
          children: [
            BrandHeroHeader(
              title: widget.location.name,
              subtitle: 'Chi tiết vị trí tủ Lock.R',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_off,
                        size: 64,
                        color: Color(0xFF0A2342),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tủ chưa có toạ độ nên chưa hiển thị được bản đồ '
                        'và chỉ đường.',
                        style: TextStyle(color: Colors.grey[800], fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      if (reason != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          reason,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFB91C1C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: reason != null
                            ? null
                            : () => showLocationServicesSheet(
                                context,
                                widget.location,
                              ),
                        icon: const Icon(Icons.add_box_outlined, size: 18),
                        label: const Text('Đặt dịch vụ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AislBrand.navy,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _openGrid,
                        child: const Text('Xem sơ đồ ô tủ'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.maybePop(context),
                        child: const Text('Quay lại'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final mapStack = Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: widget.location.coordinate,
            initialZoom: 15.0,
            minZoom: 3.0,
            maxZoom: 18.0,
            onTap: (tapPosition, point) => _onMapTap(),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.aisl_app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: widget.location.coordinate,
                  width: 50,
                  height: 50,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 50,
                  ),
                ),
              ],
            ),
          ],
        ),
        DraggableScrollableSheet(
          controller: _draggableScrollableController,
          initialChildSize: 0.45,
          minChildSize: 0.15,
          maxChildSize: 0.8,
          builder: (context, scrollController) {
            return LockerInfoModal(
              location: widget.location,
              scrollController: scrollController,
              cellGroups: _cellGroups,
              loadingCells: _loadingCells,
              cellsError: _cellsError,
              onRetryCells: _loadCells,
              online: _online,
              bookingBlockReason: _blockReason,
              onOpenGrid: _openGrid,
              offers: _offersSection(),
            );
          },
        ),
      ],
    );

    return Scaffold(
      body: Column(
        children: [
          BrandHeroHeader(
            title: widget.location.name,
            subtitle: 'Chi tiết vị trí tủ Lock.R',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(child: mapStack),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(
          AppRouter.directions,
          extra: {
            'lat': widget.location.coordinate.latitude,
            'lng': widget.location.coordinate.longitude,
            'title': widget.location.name,
          },
        ),
        backgroundColor: const Color(0xFF14171F),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.directions_rounded),
        label: const Text('Chỉ đường'),
      ),
    );
  }
}
