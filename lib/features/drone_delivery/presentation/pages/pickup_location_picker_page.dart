import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_booking.dart';
import 'package:smart_laundry_locker/features/drone_delivery/infrastructure/services/pickup_geocoder.dart';

/// Lấy vị trí hiện tại của thiết bị; null khi GPS tắt hoặc bị từ chối quyền (kèm lý do).
typedef CurrentPositionReader = Future<(LatLng?, String?)> Function();

Future<(LatLng?, String?)> readDevicePosition() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return (null, 'Dịch vụ vị trí đang tắt. Vui lòng bật GPS.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      return (null, 'Quyền truy cập vị trí bị từ chối.');
    }
    if (permission == LocationPermission.deniedForever) {
      return (
        null,
        'Quyền vị trí bị từ chối vĩnh viễn. Hãy bật lại trong cài đặt.',
      );
    }
    final position = await Geolocator.getCurrentPosition();
    return (LatLng(position.latitude, position.longitude), null);
  } catch (_) {
    return (null, 'Không lấy được vị trí hiện tại.');
  }
}

/// Chọn điểm lấy hàng cho đơn drone: dùng vị trí hiện tại, gõ địa chỉ để tìm, hoặc chạm
/// lên bản đồ để ghim. Trả về [PickupLocation] qua `Navigator.pop`.
class PickupLocationPickerPage extends StatefulWidget {
  const PickupLocationPickerPage({
    super.key,
    this.initial,
    this.geocoder,
    this.readPosition = readDevicePosition,
    this.showMap = true,
  });

  final PickupLocation? initial;
  final PickupGeocoder? geocoder;
  final CurrentPositionReader readPosition;

  /// Tắt lớp bản đồ (tải ô ảnh qua mạng) trong widget test.
  final bool showMap;

  @override
  State<PickupLocationPickerPage> createState() =>
      _PickupLocationPickerPageState();
}

class _PickupLocationPickerPageState extends State<PickupLocationPickerPage> {
  // Trung tâm TP.HCM — chỉ để bản đồ có chỗ mở khi chưa có vị trí nào.
  static const _fallbackCenter = LatLng(10.7769, 106.7009);

  late final PickupGeocoder _geocoder = widget.geocoder ?? PickupGeocoder();
  final _mapController = MapController();
  final _addressController = TextEditingController();
  final _searchController = TextEditingController();

  LatLng? _point;
  bool _locating = false;
  bool _resolving = false;
  bool _searching = false;
  List<PickupLocation> _results = const [];
  String? _message;
  int _lookup = 0;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _point = LatLng(initial.latitude, initial.longitude);
      _addressController.text = initial.address;
    } else {
      // Mở lần đầu: thử lấy luôn vị trí hiện tại cho người gửi.
      WidgetsBinding.instance.addPostFrameCallback((_) => _useCurrentLocation());
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    if (_locating) return;
    setState(() {
      _locating = true;
      _message = null;
    });
    final (position, problem) = await widget.readPosition();
    if (!mounted) return;
    setState(() => _locating = false);
    if (position == null) {
      setState(() => _message = problem);
      return;
    }
    await _moveTo(position, zoom: 17);
  }

  /// Ghim điểm mới và tra địa chỉ của nó. Người dùng có thể đã ghim điểm khác trong lúc
  /// chờ — chỉ lượt tra mới nhất được ghi vào ô địa chỉ.
  Future<void> _moveTo(LatLng point, {double? zoom, String? knownAddress}) async {
    final lookup = ++_lookup;
    setState(() {
      _point = point;
      _results = const [];
      _message = null;
      _resolving = knownAddress == null;
    });
    if (widget.showMap) {
      try {
        _mapController.move(point, zoom ?? _mapController.camera.zoom);
      } catch (_) {
        // Bản đồ chưa dựng xong; `initialCenter` sẽ lo.
      }
    }
    if (knownAddress != null) {
      _addressController.text = knownAddress;
      return;
    }
    final address = await _geocoder.addressOf(point.latitude, point.longitude);
    if (!mounted || lookup != _lookup) return;
    setState(() {
      _resolving = false;
      if (address != null) {
        _addressController.text = address;
      } else if (_addressController.text.trim().isEmpty) {
        _message =
            'Chưa tra được địa chỉ của điểm này. Hãy tự nhập địa chỉ bên dưới.';
      }
    });
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.length < 3) {
      setState(() => _message = 'Nhập ít nhất 3 ký tự để tìm địa chỉ.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _searching = true;
      _message = null;
    });
    final results = await _geocoder.search(query);
    if (!mounted) return;
    setState(() {
      _searching = false;
      _results = results;
      if (results.isEmpty) {
        _message =
            'Không tìm thấy địa chỉ này. Thử gõ rõ hơn hoặc chạm lên bản đồ để ghim.';
      }
    });
  }

  void _confirm() {
    final point = _point;
    final address = _addressController.text.trim();
    if (point == null) {
      setState(() => _message = 'Chưa chọn vị trí lấy hàng trên bản đồ.');
      return;
    }
    if (address.length < 5) {
      setState(
        () => _message = 'Nhập địa chỉ lấy hàng (số nhà, đường, phường…).',
      );
      return;
    }
    Navigator.pop(
      context,
      PickupLocation(
        latitude: point.latitude,
        longitude: point.longitude,
        address: address,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final point = _point;
    return Scaffold(
      appBar: AppBar(title: const Text('Chọn điểm lấy hàng')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('pickup-search'),
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: const InputDecoration(
                      hintText: 'Tìm địa chỉ (số nhà, đường, phường…)',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  key: const ValueKey('pickup-search-button'),
                  onPressed: _searching ? null : _search,
                  child: _searching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Tìm'),
                ),
              ],
            ),
          ),
          if (_results.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _results.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final result = _results[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.place_outlined),
                    title: Text(
                      result.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _moveTo(
                      LatLng(result.latitude, result.longitude),
                      zoom: 17,
                      knownAddress: result.address,
                    ),
                  );
                },
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                if (widget.showMap)
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: point ?? _fallbackCenter,
                      initialZoom: point == null ? 13 : 17,
                      onTap: (_, tapped) => _moveTo(tapped),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.smart_laundry_locker',
                      ),
                      if (point != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: point,
                              width: 44,
                              height: 44,
                              alignment: Alignment.topCenter,
                              child: const Icon(
                                Icons.location_on,
                                color: Color(0xFFDC2626),
                                size: 44,
                              ),
                            ),
                          ],
                        ),
                    ],
                  )
                else
                  const ColoredBox(color: Color(0xFFE2E8F0)),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: FloatingActionButton.extended(
                    key: const ValueKey('pickup-current-location'),
                    heroTag: 'pickup-current-location',
                    onPressed: _locating ? null : _useCurrentLocation,
                    icon: _locating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label: const Text('Vị trí hiện tại'),
                  ),
                ),
              ],
            ),
          ),
          Material(
            elevation: 8,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      key: const ValueKey('pickup-address'),
                      controller: _addressController,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Địa chỉ lấy hàng',
                        helperText: point == null
                            ? 'Chạm lên bản đồ để ghim điểm lấy hàng'
                            : 'Vĩ độ ${point.latitude.toStringAsFixed(5)} · '
                                  'kinh độ ${point.longitude.toStringAsFixed(5)}'
                                  ' · sửa lại địa chỉ nếu chưa đúng',
                        suffixIcon: _resolving
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : null,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _message!,
                        key: const ValueKey('pickup-message'),
                        style: const TextStyle(
                          color: Color(0xFFB45309),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      key: const ValueKey('pickup-confirm'),
                      onPressed: _confirm,
                      icon: const Icon(Icons.check),
                      label: const Text('Lấy hàng tại đây'),
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
}
