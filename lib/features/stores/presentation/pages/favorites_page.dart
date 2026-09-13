import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/features/stores/domain/entities/store.dart';
import 'package:smart_laundry_locker/features/stores/infrastructure/services/favorite_stores_service.dart';
import 'package:smart_laundry_locker/features/stores/infrastructure/services/store_service.dart';
import 'package:smart_laundry_locker/features/stores/presentation/widgets/store_card.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

/// Favourite stores (device-only). Ported from the legacy RN `user/favorites`
/// screen: resolves the saved favourite ids against the live store catalogue.
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final StoreService _service = StoreService(ApiClient());
  final FavoriteStoresService _favService = FavoriteStoresService();

  List<Store> _favorites = const [];
  Set<int> _favoriteIds = <int>{};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ids = await _favService.getFavoriteIds();
      final stores = await _service.getStores();
      if (!mounted) return;
      setState(() {
        _favoriteIds = ids;
        _favorites = stores.where((s) => ids.contains(s.id)).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Không tải được danh sách yêu thích.';
        _loading = false;
      });
    }
  }

  Future<void> _remove(Store store) async {
    await _favService.toggle(store.id);
    if (!mounted) return;
    setState(() {
      _favoriteIds.remove(store.id);
      _favorites = _favorites.where((s) => s.id != store.id).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      body: Column(
        children: [
          BrandHeroHeader(
            title: 'Yêu thích',
            subtitle: 'Cửa hàng bạn đã lưu',
            onBack: () => context.pop(),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AislBrand.navy),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.triangleAlert,
              color: Colors.redAccent,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _load,
              style: FilledButton.styleFrom(backgroundColor: AislBrand.navy),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }
    if (_favorites.isEmpty) {
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
                  color: AislBrand.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_border,
                  size: 38,
                  color: AislBrand.navy,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chưa có cửa hàng yêu thích',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AislBrand.textTitle,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Nhấn vào biểu tượng trái tim ở một cửa hàng để lưu lại đây.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AislBrand.textMuted),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => context.go(AppRouter.stores),
                style: FilledButton.styleFrom(backgroundColor: AislBrand.navy),
                icon: const Icon(LucideIcons.store, size: 16),
                label: const Text('Khám phá cửa hàng'),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: AislBrand.navy,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        itemCount: _favorites.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final store = _favorites[index];
          return StoreCard(
            store: store,
            isFavorite: _favoriteIds.contains(store.id),
            onToggleFavorite: () => _remove(store),
            onTap: () async {
              await context.push(AppRouter.storeDetail, extra: store);
              if (mounted) _load();
            },
          );
        },
      ),
    );
  }
}
