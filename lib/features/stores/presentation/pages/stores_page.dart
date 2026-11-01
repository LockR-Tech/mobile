import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/core/services/app_event_bus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/config/business_config_service.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/features/stores/domain/entities/store.dart';
import 'package:smart_laundry_locker/features/stores/infrastructure/services/favorite_stores_service.dart';
import 'package:smart_laundry_locker/features/stores/infrastructure/services/store_service.dart';
import 'package:smart_laundry_locker/features/stores/presentation/widgets/store_card.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';
import 'package:smart_laundry_locker/shared/shared.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// Customer-facing list of stores. Supports text search and "near me"
/// sorting by distance. Mirrors the legacy RN `user/stores` screen.
class StoresPage extends StatefulWidget {
  const StoresPage({super.key});

  @override
  State<StoresPage> createState() => _StoresPageState();
}

class _StoresPageState extends State<StoresPage> {
  final StoreService _service = StoreService(ApiClient());
  final FavoriteStoresService _favService = FavoriteStoresService();
  final TextEditingController _searchCtrl = TextEditingController();

  /// Điểm gửi yêu thích (lưu trên máy) — để vẽ nút tim trên từng thẻ.
  Set<int> _favoriteIds = <int>{};

  List<Store> _all = const [];
  List<Store> _visible = const [];
  bool _loading = true;
  bool _nearbyLoading = false;
  String? _error;
  double? _lastLatitude;
  double? _lastLongitude;
  StreamSubscription<AppEvent>? _eventSub;

  @override
  void initState() {
    super.initState();
    _load();
    _loadFavorites();
    // Admin thêm/sửa/tắt cửa hàng ⇒ tải lại ngầm (giữ bộ lọc "gần tôi").
    _eventSub = AppEventBus.instance.events.listen((event) {
      if (mounted && !_loading && event is CatalogChangedEvent && event.isStore) {
        _load(latitude: _lastLatitude, longitude: _lastLongitude, silent: true);
      }
    });
  }

  Future<void> _loadFavorites() async {
    try {
      final ids = await _favService.getFavoriteIds();
      if (mounted) setState(() => _favoriteIds = ids);
    } catch (_) {
      // Không đọc được bộ nhớ máy: vẫn hiện danh sách, chỉ thiếu trạng thái tim.
    }
  }

  Future<void> _toggleFavorite(Store store) async {
    try {
      final now = await _favService.toggle(store.id);
      if (!mounted) return;
      setState(() {
        _favoriteIds = {..._favoriteIds};
        if (now) {
          _favoriteIds.add(store.id);
        } else {
          _favoriteIds.remove(store.id);
        }
      });
      _toast(now ? context.l10n.storeAddedFavorite : context.l10n.storeRemovedFavorite);
    } catch (_) {
      _toast(context.l10n.storeFavoriteSaveFailed);
    }
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({
    double? latitude,
    double? longitude,
    bool silent = false,
  }) async {
    _lastLatitude = latitude;
    _lastLongitude = longitude;
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final stores = await _service.getStores(
        latitude: latitude,
        longitude: longitude,
        // Bán kính "gần tôi" do admin cấu hình (app.store.nearby-default-radius-km).
        radiusKm: latitude != null && longitude != null
            ? BusinessConfigService.instance.current.nearbyDefaultRadiusKm
            : null,
      );
      if (!mounted) return;
      setState(() {
        _all = stores;
        _loading = false;
      });
      _applyFilter();
    } catch (e) {
      if (!mounted || silent) return;
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
    BusinessConfigService.instance.refresh();
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _toast(L10n.current.storeEnableLocation);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _toast(L10n.current.storeNeedLocation);
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      await _load(latitude: position.latitude, longitude: position.longitude);
    } catch (_) {
      _toast(L10n.current.storeNoCurrentLocation);
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
    return context.l10n.storeListLoadFailed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AISLShadcnTheme.navySurface,
      body: Column(
        children: [
          BrandHeroHeader(
            title: context.l10n.homeDropPoints,
            subtitle: context.l10n.storeListSubtitle,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                BrandCircleIconButton(
                  icon: LucideIcons.heart,
                  onTap: () async {
                    await context.push(AppRouter.favoriteStores);
                    if (mounted) _loadFavorites();
                  },
                  iconSize: 18,
                ),
                const SizedBox(width: 8),
                BrandCircleIconButton(
                  icon: LucideIcons.refreshCw,
                  onTap: _load,
                  iconSize: 18,
                ),
              ],
            ),
          ),
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
                hintText: context.l10n.storeSearchHint,
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
      return AppLoadingIndicator(
        fullScreen: true,
        message: context.l10n.storeListLoading,
      );
    }
    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _load);
    }
    if (_visible.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            SizedBox(height: 120),
            Center(
              child: Text(
                context.l10n.storeNone,
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
            isFavorite: _favoriteIds.contains(store.id),
            onToggleFavorite: () => _toggleFavorite(store),
            onTap: () async {
              await context.push(AppRouter.storeDetail, extra: store);
              if (mounted) _loadFavorites();
            },
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
              label: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}
