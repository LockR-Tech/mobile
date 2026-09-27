import 'package:geolocator/geolocator.dart';
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
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
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
  final LockerOpsService _opsService = LockerOpsService();
  String? _mostUsedLocationId;
  String? _mostUsedLocationName;
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    TokenService.authState.addListener(_onAuthStateChanged);
    _onAuthStateChanged();
    _loadMostUsedLocation();
    _fetchUserPosition();
  }

  void _onAuthStateChanged() {
    if (TokenService.authState.value && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read<LockerProvider>(lockerNotifierProvider).getLocations();
          _loadMostUsedLocation();
          _fetchUserPosition();
        }
      });
    }
  }

  Future<void> _loadMostUsedLocation() async {
    if (!TokenService.authState.value) return;
    try {
      final orders = await _opsService.myOrders();
      if (!mounted || orders.isEmpty) return;

      final counts = <String, int>{};
      final names = <String, String>{};
      for (final order in orders) {
        final lid = '${order['lockerId'] ?? order['destinationLockerId'] ?? order['senderLockerId'] ?? ''}'.trim();
        if (lid.isNotEmpty) {
          counts[lid] = (counts[lid] ?? 0) + 1;
          final name = order['lockerName']?.toString();
          if (name != null && name.isNotEmpty) {
            names[lid] = name;
          }
        }
      }

      if (counts.isNotEmpty) {
        var bestId = '';
        var maxCount = 0;
        counts.forEach((id, count) {
          if (count > maxCount) {
            maxCount = count;
            bestId = id;
          }
        });
        if (bestId.isNotEmpty && mounted) {
          setState(() {
            _mostUsedLocationId = bestId;
            _mostUsedLocationName = names[bestId];
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchUserPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null && mounted) {
        setState(() {
          _userPosition = lastPos;
        });
      }

      final currentPos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 4),
        ),
      ).timeout(const Duration(seconds: 5));

      if (mounted) {
        setState(() {
          _userPosition = currentPos;
        });
      }
    } catch (_) {}
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
                  title: 'Danh sách địa điểm',
                  subtitle: 'Đăng nhập để xem các địa điểm khả dụng',
                ),
                Expanded(
                  child: UnauthenticatedPlaceholder(
                    message: 'Bạn cần đăng nhập để xem danh sách địa điểm',
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
                title: 'Danh sách địa điểm',
                subtitle: 'Chọn địa điểm để xem chi tiết',
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm địa điểm...',
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
          'Hiện tại chưa có địa điểm nào!',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      );
    }

    // Rearrange locations so most-used location is at index 0
    final locations = List<LockerLocation>.of(state.locations);
    if (_mostUsedLocationId != null && locations.isNotEmpty) {
      final mostUsedIdx = locations.indexWhere(
        (loc) =>
            loc.id == _mostUsedLocationId ||
            (_mostUsedLocationName != null &&
                loc.name.trim().toLowerCase() ==
                    _mostUsedLocationName!.trim().toLowerCase()),
      );
      if (mostUsedIdx > 0) {
        final topItem = locations.removeAt(mostUsedIdx);
        locations.insert(0, topItem);
      }
    }

    // List of locations
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref
              .read<LockerProvider>(lockerNotifierProvider)
              .getLocations(refresh: true),
          _loadMostUsedLocation(),
          _fetchUserPosition(),
        ]);
      },
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        itemCount: locations.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, index) {
          final isTopMostUsed = index == 0 &&
              _mostUsedLocationId != null &&
              locations.isNotEmpty &&
              (locations[0].id == _mostUsedLocationId ||
                  (_mostUsedLocationName != null &&
                      locations[0].name.trim().toLowerCase() ==
                          _mostUsedLocationName!.trim().toLowerCase()));
          if (isTopMostUsed) {
            return const SizedBox(height: 6);
          }
          return Divider(height: 1, color: context.dividerColor);
        },
        itemBuilder: (context, index) {
          // Loading more indicator - show skeleton row
          if (index >= locations.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: _LockerItemSkeleton(),
            );
          }

          final location = locations[index];
          final isMostUsed = location.id == _mostUsedLocationId ||
              (_mostUsedLocationName != null &&
                  location.name.trim().toLowerCase() ==
                      _mostUsedLocationName!.trim().toLowerCase());
          return LockerItem(
            location: location,
            isMostUsed: isMostUsed,
            userPosition: _userPosition,
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
