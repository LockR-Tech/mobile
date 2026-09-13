import 'package:smart_laundry_locker/features/locker/domain/entities/locker_location.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/models/responses/lockers_response.dart';
import 'package:smart_laundry_locker/features/locker/presentation/providers/locker_provider.dart';
import 'package:smart_laundry_locker/features/locker/presentation/providers/locker_providers.dart';
import 'package:smart_laundry_locker/features/locker/presentation/widgets/locker_info_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/location_services.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

class LockerDetailMapPage extends ConsumerStatefulWidget {
  final LockerLocation location;

  const LockerDetailMapPage({super.key, required this.location});

  @override
  ConsumerState<LockerDetailMapPage> createState() =>
      _LockerDetailMapPageState();
}

class _LockerDetailMapPageState extends ConsumerState<LockerDetailMapPage> {
  late DraggableScrollableController _draggableScrollableController;

  @override
  void initState() {
    super.initState();
    _draggableScrollableController = DraggableScrollableController();

    // // Fetch locker counts cho location này
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   ref
    //       .read<LockerProvider>(lockerNotifierProvider)
    //       .getLockerCountBySize(
    //         cabinetId: widget.location.id, // This is wrong now, needs cabinetId
    //       );
    // });
  }

  @override
  void dispose() {
    _draggableScrollableController.dispose();
    super.dispose();
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
    final LockerProvider provider = ref.watch<LockerProvider>(
      lockerNotifierProvider,
    );
    final List<LockerSizeCount> lockerSizeItems =
        provider.state.lockerSizeItems;

    // ko render map nếu toạ độ ko hợp lệ
    if (!widget.location.hasValidCoordinate) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.location.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: AislBrand.navy,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_off,
                  size: 64,
                  color: const Color(0xFF0A2342),
                ),
                const SizedBox(height: 16),
                Text(
                  'Toạ độ địa điểm không hợp lệ.\nKhông thể hiển thị bản đồ.',
                  style: TextStyle(color: Colors.grey[800], fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () =>
                      showLocationServicesSheet(context, widget.location),
                  icon: const Icon(Icons.add_box_outlined, size: 18),
                  label: const Text('Đặt dịch vụ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AislBrand.navy,
                    foregroundColor: Colors.white,
                  ),
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
      );
    }

    Widget mapStack;
    try {
      mapStack = Stack(
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
            initialChildSize: 0.4,
            minChildSize: 0.15,
            maxChildSize: 0.7,
            builder: (context, scrollController) {
              return LockerInfoModal(
                location: widget.location,
                lockerSizeItems: lockerSizeItems,
                scrollController: scrollController,
              );
            },
          ),
        ],
      );
    } catch (e) {
      mapStack = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: const Color(0xFF0A2342),
              ),
              const SizedBox(height: 16),
              Text(
                'Không thể tải bản đồ.',
                style: TextStyle(color: Colors.grey[800], fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.maybePop(context),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.location.name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        backgroundColor: AislBrand.navy,
        foregroundColor: Colors.white,
        elevation: 0,
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
        backgroundColor: AislBrand.navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.directions_rounded),
        label: const Text('Chỉ đường'),
      ),
      body: mapStack,
    );
  }
}
