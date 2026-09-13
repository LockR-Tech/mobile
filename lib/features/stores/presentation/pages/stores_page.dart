import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/features/stores/domain/entities/store.dart';
import 'package:smart_laundry_locker/features/stores/infrastructure/services/store_service.dart';
import 'package:smart_laundry_locker/features/stores/presentation/widgets/store_card.dart';

/// Customer-facing list of stores. Supports text search and "near me"
/// sorting by distance. Mirrors the legacy RN `user/stores` screen.
class StoresPage extends StatefulWidget {
  const StoresPage({super.key});

  @override
  State<StoresPage> createState() => _StoresPageState();
}

class _StoresPageState extends State<StoresPage> {
  final StoreService _service = StoreService(ApiClient());
  final TextEditingController _searchCtrl = TextEditingController();

  List<Store> _all = const [];
  List<Store> _visible = const [];
  bool _loading = true;
  bool _nearbyLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({double? latitude, double? longitude}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stores = await _service.getStores(
        latitude: latitude,
        longitude: longitude,
      );
      if (!mounted) return;
      setState(() {
        _all = stores;
        _loading = false;
      });
      _applyFilter();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _messageFor(e);
        _loading = false;
      });
    }
  }

  void _applyFilter() {
    final query = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _visible = query.isEmpty
          ? _all
          : _all
                .where(
                  (store) =>
                      store.name.toLowerCase().contains(query) ||
                      (store.address ?? '').toLowerCase().contains(query),
                )
                .toList();
    });
  }

  Future<void> _useMyLocation() async {
    setState(() => _nearbyLoading = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _toast('Vui lòng bật dịch vụ định vị.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _toast('Cần quyền vị trí để tìm cửa hàng gần bạn.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      await _load(latitude: position.latitude, longitude: position.longitude);
    } catch (_) {
      _toast('Không lấy được vị trí hiện tại.');
    } finally {
      if (mounted) setState(() => _nearbyLoading = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _messageFor(Object error) {
    if (error is NetworkException) return error.message;
    if (error is ServerException) return error.message;
    if (error is ValidationException) return error.message;
    return 'Không tải được danh sách cửa hàng.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AISLShadcnTheme.navySurface,
      appBar: AppBar(
        title: const Text('Cửa hàng'),
        backgroundColor: AISLShadcnTheme.navyPrimary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => _applyFilter(),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên hoặc địa chỉ',
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AISLShadcnTheme.navyPrimary,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _nearbyLoading ? null : _useMyLocation,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _nearbyLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        LucideIcons.locateFixed,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _load);
    }
    if (_visible.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(
              child: Text(
                'Không có cửa hàng nào',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _visible.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final store = _visible[index];
          return StoreCard(
            store: store,
            onTap: () => context.push(AppRouter.storeDetail, extra: store),
          );
        },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.triangleAlert,
              color: Colors.redAccent,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
