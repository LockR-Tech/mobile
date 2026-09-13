import 'package:smart_laundry_locker/features/locker/domain/entities/locker_location.dart';
import 'package:smart_laundry_locker/features/locker/presentation/pages/locker_map_page.dart';
import 'package:smart_laundry_locker/features/stores/domain/entities/store.dart';
import 'package:smart_laundry_locker/features/stores/presentation/pages/store_lockers_page.dart';
import 'package:smart_laundry_locker/features/locker/presentation/providers/locker_provider.dart';
import 'package:smart_laundry_locker/features/locker/presentation/providers/locker_providers.dart';
import 'package:smart_laundry_locker/features/locker/presentation/widgets/locker_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/location_services.dart';
import 'package:smart_laundry_locker/shared/widgets/unauthenticated_placeholder.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

class LockerPage extends ConsumerStatefulWidget {
  const LockerPage({super.key});

  @override
  ConsumerState<LockerPage> createState() => _LockerPageState();
}

class _LockerPageState extends ConsumerState<LockerPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    TokenService.authState.addListener(_onAuthStateChanged);
    _onAuthStateChanged();
  }

  void _onAuthStateChanged() {
    if (TokenService.authState.value && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read<LockerProvider>(lockerNotifierProvider).getLocations();
        }
      });
    }
  }

  @override
  void dispose() {
    TokenService.authState.removeListener(_onAuthStateChanged);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    ref
        .read<LockerProvider>(lockerNotifierProvider)
        .getLocations(search: query);
  }

  void _onScroll() {
    // Load more khi scroll gần cuối
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final LockerProvider provider = ref.read<LockerProvider>(
        lockerNotifierProvider,
      );
      if (provider.state.canLoadMoreLocations &&
          !provider.state.isLoadingMore) {
        provider.loadMoreLocations(search: _searchController.text);
      }
    }
  }

  void _navigateToMap(LockerLocation location) {
    Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        builder: (_) => StoreLockerGridPage(
          store: Store(
            id: int.tryParse(location.id) ?? 0,
            name: location.name,
            address: location.address,
            latitude: location.latitude,
            longitude: location.longitude,
            active: location.isActive,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LockerProvider provider = ref.watch<LockerProvider>(
      lockerNotifierProvider,
    );
    final LockerState state = provider.state;

    return ValueListenableBuilder<bool>(
      valueListenable: TokenService.authState,
      builder: (context, isLoggedIn, child) {
        if (!isLoggedIn) {
          return Scaffold(
            backgroundColor: context.pageBg,
            body: Column(
              children: const [
                BrandHeroHeader(
                  title: 'Danh sách tủ',
                  subtitle: 'Đăng nhập để xem các tủ khả dụng',
                ),
                Expanded(
                  child: UnauthenticatedPlaceholder(
                    message: 'Bạn cần đăng nhập để xem danh sách tủ',
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: context.pageBg,
          body: Column(
            children: [
              BrandHeroHeader(
                title: 'Danh sách tủ',
                subtitle: 'Chọn tủ để xem chi tiết',
                trailing: BrandCircleIconButton(
                  icon: LucideIcons.mapPin,
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).push<void>(
                      MaterialPageRoute(
                        builder: (context) => const LockerMapPage(),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm tủ...',
                    prefixIcon: Icon(LucideIcons.search,
                        size: 18, color: context.textMuted),
                    filled: true,
                    fillColor: context.cardBg,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: context.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: context.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AislBrand.blue),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 10),
                child: LockerUtilitiesRow(),
              ),
              Expanded(child: _buildLocationsList(state)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationsList(LockerState state) {
    // Loading state
    if (state.isLoading && state.locations.isEmpty) {
      // Skeleton loading for list
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        itemCount: 6,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: context.dividerColor),
        itemBuilder: (context, index) => const _LockerItemSkeleton(),
      );
    }

    // Error state
    if (state.error != null && state.locations.isEmpty) {
      return Center(
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
      );
    }

    // Empty state
    if (state.locations.isEmpty) {
      return Center(
        child: Text(
          'Hiện tại chưa có tủ nào!',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      );
    }

    // List of locations
    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read<LockerProvider>(lockerNotifierProvider)
            .getLocations(refresh: true);
      },
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        itemCount: state.locations.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: context.dividerColor),
        itemBuilder: (context, index) {
          // Loading more indicator - show skeleton row
          if (index >= state.locations.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: _LockerItemSkeleton(),
            );
          }

          final location = state.locations[index];
          return LockerItem(
            location: location,
            onTap: () => _navigateToMap(location),
          );
        },
      ),
    );
  }
}

/// Skeleton placeholder for LockerItem while loading
class _LockerItemSkeleton extends StatelessWidget {
  const _LockerItemSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: SizedBox(
              height: 110,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 14,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 14,
                        width: 160,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 12,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
