import 'dart:convert';

import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/features/locker/domain/entities/locker_location.dart';
import 'package:smart_laundry_locker/features/locker/presentation/pages/locker_detail_map_page.dart';
import 'package:smart_laundry_locker/features/locker/presentation/providers/locker_provider.dart';
import 'package:smart_laundry_locker/features/locker/presentation/providers/locker_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LockerMapPage extends ConsumerStatefulWidget {
  const LockerMapPage({super.key});

  @override
  ConsumerState<LockerMapPage> createState() => _LockerMapPageState();
}

class _LockerMapPageState extends ConsumerState<LockerMapPage>
    with SingleTickerProviderStateMixin {
  LockerLocation? _selectedLocation;
  LatLng? _currentUserLocation;
  String? _currentAddress;
  bool _isLocating = false;
  late final MapController _mapController;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    // Fetch locations nếu chưa có
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final LockerProvider provider = ref.read<LockerProvider>(
        lockerNotifierProvider,
      );
      if (provider.state.locations.isEmpty) {
        provider.getLocations();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LockerProvider provider = ref.watch<LockerProvider>(
      lockerNotifierProvider,
    );
    final LockerState state = provider.state;

    if (state.isLoading && state.locations.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bản đồ tủ khóa')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null && state.locations.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bản đồ tủ khóa')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                state.error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref
                    .read<LockerProvider>(lockerNotifierProvider)
                    .getLocations(),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.locations.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bản đồ tủ khóa')),
        body: Center(
          child: Text(
            'Hiện tại chưa có tủ nào!',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final List<LockerLocation> activeLocations = state.locations
        .where((LockerLocation loc) => loc.hasValidCoordinate)
        .toList();

    // tính từ locations hợp lệ, nếu ko thì dùng mặc định
    final LatLng centerPoint;
    if (activeLocations.isEmpty) {
      centerPoint = const LatLng(10.8231, 106.6297);
    } else {
      final avgLat =
          activeLocations
              .map((LockerLocation loc) => loc.latitude)
              .reduce((double a, double b) => a + b) /
          activeLocations.length;
      final avgLng =
          activeLocations
              .map((LockerLocation loc) => loc.longitude)
              .reduce((double a, double b) => a + b) /
          activeLocations.length;

      final safeLat = avgLat.clamp(-90.0, 90.0);
      final safeLng = avgLng.clamp(-180.0, 180.0);
      centerPoint = LatLng(safeLat, safeLng);
    }

    Widget mapBody;
    try {
      final innerMap = Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: centerPoint,
              initialZoom: 12.0,
              minZoom: 3.0,
              maxZoom: 18.0,
              onTap: (_, __) {
                setState(() => _selectedLocation = null);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.aisl_app',
              ),
              MarkerLayer(
                markers: activeLocations.map((LockerLocation location) {
                  return Marker(
                    point: location.coordinate,
                    width: 50,
                    height: 50,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedLocation = location);
                      },
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 50,
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_currentUserLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentUserLocation!,
                      width: 60,
                      height: 60,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final value = _pulseController.value; // 0..1
                          final double outerSize = 40 + 20 * value;
                          final double outerOpacity = (1 - value) * 0.5;
                          return Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: outerSize,
                                  height: outerSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.blue.withOpacity(
                                      outerOpacity,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (_selectedLocation != null)
            _buildPreviewCard(context, _selectedLocation!),
        ],
      );

      mapBody = Stack(
        children: [
          innerMap,
          Positioned(
            bottom: 24,
            right: 16,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              elevation: 4,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: _isLocating ? null : _getCurrentLocation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isLocating) ...[
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Đang lấy vị trí...',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ] else ...[
                        const Icon(
                          Icons.my_location,
                          color: const Color(0xFF0A2342),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Sử dụng vị trí của bạn',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } catch (e) {
      mapBody = Center(
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
                'Không thể tải bản đồ. Toạ độ có thể không hợp lệ.',
                style: TextStyle(color: Colors.grey[800], fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                e.toString(),
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    context.go(AppRouter.lockers);
                  }
                },
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      );
    }

    final int invalidCount = state.locations.length - activeLocations.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            // Ưu tiên pop stack hiện tại (được mở từ LockerPage bằng Navigator.push)
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // Fallback: điều hướng cứng về trang danh sách locker
              context.go(AppRouter.lockers);
            }
          },
          splashRadius: 24,
        ),
        title: const Text('Bản đồ tủ khóa'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          if (_isLocating || (_currentAddress ?? '').isNotEmpty)
            _buildAddressBar(context),
          if (invalidCount > 0)
            Material(
              color: const Color(0xFFD8E8F4),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: const Color(0xFF061A30),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$invalidCount địa điểm có toạ độ không hợp lệ đã được ẩn.',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF061A30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(child: mapBody),
        ],
      ),
    );
  }

  Widget _buildAddressBar(BuildContext context) {
    final theme = Theme.of(context);
    final text =
        (_isLocating && (_currentAddress == null || _currentAddress!.isEmpty))
        ? 'Đang xác định vị trí...'
        : (_currentAddress ?? '');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.place, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(BuildContext context, LockerLocation location) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomPadding = MediaQuery.of(context).padding.bottom + 20;
    final cardWidth = screenWidth * 0.92;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      bottom: bottomPadding,
      left: (screenWidth - cardWidth) / 2,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: 1.0,
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LockerDetailMapPage(location: location),
              ),
            );
          },
          child: Container(
            width: cardWidth,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.mapPin,
                  color: const Color(0xFF0A2342),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        location.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        location.address,
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(LucideIcons.scanLine, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Reverse geocoding qua OpenStreetMap Nominatim
  Future<String> _getAddressFromLatLng(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
      );

      final response = await http.get(
        uri,
        headers: const {'User-Agent': 'aisl_app/1.0 (https://aisl.app)'},
      );

      if (response.statusCode != 200) {
        return 'Không thể xác định địa chỉ, vui lòng thử lại';
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      final displayName = data['display_name'] as String?;
      if (displayName != null && displayName.isNotEmpty) {
        return displayName;
      }

      final address = data['address'] as Map<String, dynamic>?;
      if (address != null && address.isNotEmpty) {
        final parts = <String>[];
        for (final key in [
          'road',
          'neighbourhood',
          'suburb',
          'city_district',
          'city',
          'state',
          'postcode',
          'country',
        ]) {
          final value = address[key] as String?;
          if (value != null && value.isNotEmpty) {
            parts.add(value);
          }
        }
        if (parts.isNotEmpty) {
          return parts.join(', ');
        }
      }

      return 'Không thể xác định địa chỉ, vui lòng thử lại';
    } catch (_) {
      return 'Không thể xác định địa chỉ, vui lòng thử lại';
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocating = true;
    });

    try {
      // check gps
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        SmartDialog.showToast('Dịch vụ vị trí đang tắt. Vui lòng bật GPS.');
        setState(() {
          _isLocating = false;
        });
        return;
      }

      // xin quyền truy cập
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          SmartDialog.showToast('Quyền truy cập vị trí bị từ chối.');
          setState(() {
            _isLocating = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        SmartDialog.showToast(
          'Quyền vị trí bị từ chối vĩnh viễn. Hãy bật lại trong cài đặt.',
        );
        setState(() {
          _isLocating = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final userLatLng = LatLng(position.latitude, position.longitude);

      // cập nhật marker, reset địa chỉ
      setState(() {
        _currentUserLocation = userLatLng;
        _currentAddress = null;
      });

      final address = await _getAddressFromLatLng(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _currentAddress = address;
        _isLocating = false;
      });

      _mapController.move(userLatLng, 15.0);
    } catch (e) {
      SmartDialog.showToast('Không thể xác định địa chỉ, vui lòng thử lại: $e');
      setState(() {
        _isLocating = false;
      });
    }
  }
}
