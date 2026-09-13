import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// Reusable in-app directions screen: draws a driving route from the user's
/// current location to [destination] on an OpenStreetMap map (via the public
/// OSRM router), with a fallback to the native maps app for turn-by-turn.
///
/// Used by the stores and locker flows when the user taps "Chỉ đường".
class DirectionsMapPage extends StatefulWidget {
  const DirectionsMapPage({
    required this.destination,
    required this.title,
    this.subtitle,
    super.key,
  });

  final LatLng destination;
  final String title;
  final String? subtitle;

  @override
  State<DirectionsMapPage> createState() => _DirectionsMapPageState();
}

class _DirectionsMapPageState extends State<DirectionsMapPage> {
  final MapController _mapController = MapController();

  LatLng? _me;
  List<LatLng> _routePoints = const [];
  double? _distanceMeters;
  double? _durationSeconds;
  bool _loading = true;
  String? _hint;

  bool _isNavigating = false;
  double? _remainingMeters;
  StreamSubscription<Position>? _positionSub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    final me = await _currentLocation();
    if (!mounted) return;
    setState(() => _me = me);
    if (me != null) {
      await _fetchRoute(me, widget.destination);
      _fitBounds(me, widget.destination);
    } else {
      setState(
        () => _hint = 'Không lấy được vị trí của bạn — chỉ hiển thị tủ.',
      );
    }
    if (mounted) setState(() => _loading = false);
  }

  void _startNavigation() {
    if (_me == null) return;
    setState(() {
      _isNavigating = true;
      _remainingMeters = _distanceMeters;
    });
    _mapController.move(_me!, 16);
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) {
      if (!mounted) return;
      final newMe = LatLng(pos.latitude, pos.longitude);
      const calc = Distance();
      final remaining = calc(newMe, widget.destination);
      setState(() {
        _me = newMe;
        _remainingMeters = remaining;
      });
      _mapController.move(newMe, _mapController.camera.zoom.clamp(15.0, 18.0));
    });
  }

  void _stopNavigation() {
    _positionSub?.cancel();
    _positionSub = null;
    setState(() => _isNavigating = false);
    if (_me != null) _fitBounds(_me!, widget.destination);
  }

  Future<void> _retryLocation() async {
    setState(() {
      _loading = true;
      _hint = null;
    });
    final me = await _currentLocation();
    if (!mounted) return;
    setState(() => _me = me);
    if (me != null) {
      await _fetchRoute(me, widget.destination);
      _fitBounds(me, widget.destination);
    } else {
      setState(
        () => _hint = 'Không lấy được vị trí của bạn — chỉ hiển thị tủ.',
      );
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<LatLng?> _currentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      final pos = await Geolocator.getCurrentPosition();
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchRoute(LatLng start, LatLng end) async {
    try {
      final url =
          'https://router.project-osrm.org/route/v1/driving/'
          '${start.longitude},${start.latitude};'
          '${end.longitude},${end.latitude}'
          '?overview=full&geometries=polyline';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final route = routes.first as Map<String, dynamic>;
          final points = _decodePolyline(route['geometry'] as String);
          if (!mounted) return;
          setState(() {
            _routePoints = points;
            _distanceMeters = (route['distance'] as num?)?.toDouble();
            _durationSeconds = (route['duration'] as num?)?.toDouble();
          });
        }
      }
    } catch (_) {
      // Route is best-effort; the destination marker still shows.
    }
  }

  Future<void> _openExternal() async {
    final lat = widget.destination.latitude;
    final lng = widget.destination.longitude;
    final googleMaps = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$lat,$lng&travelmode=driving',
    );
    final appleMaps = Uri.parse(
      'https://maps.apple.com/?daddr=$lat,$lng&dirflg=d',
    );
    if (await canLaunchUrl(googleMaps)) {
      await launchUrl(googleMaps, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(appleMaps)) {
      await launchUrl(appleMaps, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được ứng dụng bản đồ.')),
      );
    }
  }

  void _fitBounds(LatLng a, LatLng b) {
    final bounds = LatLngBounds(
      LatLng(
        a.latitude < b.latitude ? a.latitude : b.latitude,
        a.longitude < b.longitude ? a.longitude : b.longitude,
      ),
      LatLng(
        a.latitude > b.latitude ? a.latitude : b.latitude,
        a.longitude > b.longitude ? a.longitude : b.longitude,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          // ── Map fills full screen ──────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.destination,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.aisl.app',
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: AISLShadcnTheme.navyPrimary,
                      strokeWidth: 5,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (_me != null)
                    Marker(
                      point: _me!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        LucideIcons.navigation,
                        color: Colors.blue,
                        size: 28,
                      ),
                    ),
                  Marker(
                    point: widget.destination,
                    width: 44,
                    height: 44,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Floating header ────────────────────────────────────────────────
          Positioned(
            top: topPad + 10,
            left: 12,
            right: 12,
            child: Row(
              children: [
                // Back button
                _MapFab(
                  onTap: () => Navigator.maybePop(context),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: AISLShadcnTheme.navyPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                // Title chip
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.mapPin,
                          color: AISLShadcnTheme.navyPrimary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AISLShadcnTheme.navyPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Loading chip ───────────────────────────────────────────────────
          if (_loading)
            Positioned(
              top: topPad + 66,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AISLShadcnTheme.navyPrimary,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Đang tìm đường...',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Re-center FAB ─────────────────────────────────────────────────
          if (_me != null && !_isNavigating)
            Positioned(
              right: 14,
              bottom: 220 + bottomPad,
              child: _MapFab(
                onTap: () => _mapController.move(_me!, 16),
                child: const Icon(
                  LucideIcons.locate,
                  color: AISLShadcnTheme.navyPrimary,
                  size: 20,
                ),
              ),
            ),

          // ── Bottom info card ───────────────────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildInfoCard(bottomPad),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(double bottomPad) {
    return Container(
      margin: EdgeInsets.fromLTRB(12, 12, 12, 12 + bottomPad),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          if ((widget.subtitle ?? '').isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              widget.subtitle!,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
          const SizedBox(height: 8),

          // ── Route info / hint ────────────────────────────────────────────
          if (_isNavigating && _remainingMeters != null)
            _RouteInfoRow(
              icon: LucideIcons.navigation,
              iconColor: Colors.green,
              text: _remainingMeters! >= 1000
                  ? '${(_remainingMeters! / 1000).toStringAsFixed(1)} km còn lại'
                  : '${_remainingMeters!.round()} m còn lại',
            )
          else if (_distanceMeters != null && _durationSeconds != null)
            _RouteInfoRow(
              icon: LucideIcons.route,
              iconColor: AISLShadcnTheme.navyAccent,
              text:
                  '${(_distanceMeters! / 1000).toStringAsFixed(1)} km'
                  '  ·  ~${(_durationSeconds! / 60).round()} phút',
            )
          else if (_hint != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                _hint!,
                style: const TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ),

          const SizedBox(height: 12),

          // ── Primary action button ────────────────────────────────────────
          if (_isNavigating)
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _stopNavigation,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.stop_rounded, size: 18),
                    label: const Text('Dừng dẫn đường'),
                  ),
                ),
                const SizedBox(width: 8),
                _MapFab(
                  onTap: () => _mapController.move(_me!, 16),
                  child: const Icon(
                    LucideIcons.locate,
                    color: AISLShadcnTheme.navyPrimary,
                    size: 20,
                  ),
                ),
              ],
            )
          else ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _me != null ? _startNavigation : _retryLocation,
                style: FilledButton.styleFrom(
                  backgroundColor: AISLShadcnTheme.navyPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: Icon(
                  _me != null
                      ? LucideIcons.navigation
                      : LucideIcons.locateFixed,
                  size: 18,
                ),
                label: Text(
                  _me != null ? 'Bắt đầu dẫn đường' : 'Lấy vị trí của bạn',
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openExternal,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
                icon: Icon(
                  Icons.open_in_new,
                  size: 15,
                  color: Colors.grey.shade500,
                ),
                label: Text(
                  'Mở trên Google Maps',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    var index = 0;
    final len = encoded.length;
    var lat = 0;
    var lng = 0;

    while (index < len) {
      int b;
      var shift = 0;
      var result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }
}

class _RouteInfoRow extends StatelessWidget {
  const _RouteInfoRow({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  final IconData icon;
  final Color iconColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _MapFab extends StatelessWidget {
  const _MapFab({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
