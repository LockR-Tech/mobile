import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_booking.dart';
import 'package:smart_laundry_locker/features/drone_delivery/infrastructure/services/pickup_geocoder.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_base_tile_layer.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// Lấy vị trí hiện tại của thiết bị; null khi GPS tắt hoặc bị từ chối quyền (kèm lý do).
typedef CurrentPositionReader = Future<(LatLng?, String?)> Function();

Future<(LatLng?, String?)> readDevicePosition() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return (null, L10n.current.plServiceOff);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      return (null, L10n.current.plDenied);
    }
    if (permission == LocationPermission.deniedForever) {
      return (
        null,
        L10n.current.plDeniedForever,
      );
    }
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } catch (_) {
      position = await Geolocator.getLastKnownPosition();
    }
    if (position == null) {
      return (null, L10n.current.plNoLocation);
    }
    return (LatLng(position.latitude, position.longitude), null);
  } catch (_) {
    return (
      null,
      L10n.current.plNoLocationHint,
    );
  }
}

/// Chọn điểm lấy hàng cho đơn drone: dùng vị trí hiện tại, gõ địa chỉ (gợi ý hiện ngay khi
/// gõ), hoặc chạm lên bản đồ để ghim. Trả về [PickupLocation] qua `Navigator.pop`.
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
  int _searchSeq = 0;
  Timer? _debounce;

  static const _debounceDelay = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _point = LatLng(initial.latitude, initial.longitude);
      _addressController.text = initial.address;
    } else {
      // Mở lần đầu: thử lấy luôn vị trí hiện tại cho người gửi.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _useCurrentLocation(),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
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
  Future<void> _moveTo(
    LatLng point, {
    double? zoom,
    String? knownAddress,
  }) async {
    final lookup = ++_lookup;
    _debounce?.cancel();
    _searchSeq++;
    setState(() {
      _searching = false;
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
            context.l10n.plNoAddressForPoint;
      }
    });
  }

  /// Gõ tới đâu gợi ý tới đó: chờ người dùng ngừng gõ một nhịp rồi mới tra, để không
  /// gửi một yêu cầu cho mỗi phím.
  void _onQueryChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 3) {
      _searchSeq++;
      setState(() {
        _searching = false;
        _results = const [];
        _message = null;
      });
      return;
    }
    _debounce = Timer(_debounceDelay, _search);
  }

  Future<void> _search() async {
    _debounce?.cancel();
    final query = _searchController.text.trim();
    if (query.length < 3) {
      setState(() => _message = context.l10n.plMin3Chars);
      return;
    }
    final seq = ++_searchSeq;
    setState(() {
      _searching = true;
      _message = null;
    });
    final results = await _geocoder.search(query);
    // Người dùng đã gõ tiếp hoặc đã chọn điểm: bỏ kết quả cũ.
    if (!mounted || seq != _searchSeq) return;
    setState(() {
      _searching = false;
      _results = results;
      if (results.isEmpty) {
        _message =
            context.l10n.plNotFound;
      }
    });
  }

  void _clearQuery() {
    _searchController.clear();
    _onQueryChanged('');
  }

  void _confirm() {
    final point = _point;
    final address = _addressController.text.trim();
    if (point == null) {
      setState(() => _message = context.l10n.plNoPoint);
      return;
    }
    if (address.length < 5) {
      setState(
        () => _message = context.l10n.plEnterAddress,
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
      appBar: AppBar(title: Text(context.l10n.plTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: TextField(
              key: const ValueKey('pickup-search'),
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: _onQueryChanged,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: context.l10n.plSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _searchController,
                        builder: (context, value, _) => value.text.isEmpty
                            ? const SizedBox.shrink()
                            : IconButton(
                                key: const ValueKey('pickup-search-clear'),
                                tooltip: context.l10n.plClear,
                                icon: const Icon(Icons.close),
                                onPressed: _clearQuery,
                              ),
                      ),
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          // Flexible (tối đa 220): mở bàn phím thì danh sách gợi ý co lại theo chỗ
          // còn trống thay vì đẩy tràn khung địa chỉ ở đáy.
          if (_results.isNotEmpty)
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
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
                    subtitle: Text(
                      '${result.latitude.toStringAsFixed(5)}, '
                      '${context.l10n.plTapToSeePin(result.longitude.toStringAsFixed(5))}',
                    ),
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      _moveTo(
                        LatLng(result.latitude, result.longitude),
                        zoom: 17,
                        knownAddress: result.address,
                      );
                    },
                  );
                },
                ),
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
                      droneBaseTileLayer(),
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
                    label: Text(context.l10n.plCurrentLocation),
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
                        labelText: context.l10n.plAddressField,
                        helperText: point == null
                            ? context.l10n.plTapMapToPin
                  : context.l10n.plPinInfo(
                      point.latitude.toStringAsFixed(5),
                      point.longitude.toStringAsFixed(5),
                    ),
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
                      label: Text(context.l10n.plPickupHere),
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
