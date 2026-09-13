import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';

class LocationResult {
  final String address;
  final double latitude;
  final double longitude;

  LocationResult({
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

class LocationPicker extends StatefulWidget {
  final String? initialAddress;
  final double? initialLat;
  final double? initialLon;

  const LocationPicker({
    super.key,
    this.initialAddress,
    this.initialLat,
    this.initialLon,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng _selectedLocation = const LatLng(10.762622, 106.660172); // Default HCM
  String _selectedAddress = '';

  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLon != null) {
      _selectedLocation = LatLng(widget.initialLat!, widget.initialLon!);
    }
    _selectedAddress = widget.initialAddress ?? '';
    _searchController.text = _selectedAddress;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchAddress(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&addressdetails=1&countrycodes=vn',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'AISL_App_Flutter'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _searchResults = data as List<dynamic>;
          _isSearching = false;
        });
      } else {
        setState(() => _isSearching = false);
      }
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchAddress(query);
    });
  }

  void _selectResult(dynamic result) {
    final lat = double.parse(result['lat'].toString());
    final lon = double.parse(result['lon'].toString());
    final displayName = (result['display_name'] ?? '').toString();

    setState(() {
      _selectedLocation = LatLng(lat, lon);
      _selectedAddress = displayName;
      _searchController.text = displayName;
      _searchResults = [];
    });

    _mapController.move(_selectedLocation, 16);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chọn vị trí',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: 16,
              onTap: (tapPosition, latLng) {
                setState(() {
                  _selectedLocation = latLng;
                });
                _reverseGeocode(latLng);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.aisl.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLocation,
                    width: 80,
                    height: 80,
                    child: const Icon(
                      Icons.location_on,
                      size: 40,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Search UI
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(color: Colors.black, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm địa chỉ...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: const Icon(
                        LucideIcons.search,
                        size: 20,
                        color: Colors.grey,
                      ),
                      suffixIcon: _isSearching
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
                          : _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchResults = []);
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),

                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _searchResults.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          title: Text(
                            (result['display_name'] ?? '').toString(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                          onTap: () => _selectResult(result),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Confirm Button
          Positioned(
            bottom: 32,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  LocationResult(
                    address: _selectedAddress,
                    latitude: _selectedLocation.latitude,
                    longitude: _selectedLocation.longitude,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AISLShadcnTheme.navyPrimary,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Xác nhận vị trí',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=${latLng.latitude}&lon=${latLng.longitude}&format=json&addressdetails=1',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'AISL_App_Flutter'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final displayName = (data['display_name'] ?? '').toString();
        setState(() {
          _selectedAddress = displayName;
          _searchController.text = displayName;
        });
      }
    } catch (e) {
      // Handle error
    }
  }
}
