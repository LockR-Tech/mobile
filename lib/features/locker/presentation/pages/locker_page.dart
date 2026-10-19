import 'package:geolocator/geolocator.dart';
import 'package:smart_laundry_locker/features/locker/domain/entities/locker_location.dart';
import 'package:smart_laundry_locker/features/locker/presentation/pages/locker_map_page.dart';
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
  String _selectedKiosk = 'ALL';

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

  static String _kioskNameOf(LockerLocation loc) {
    final name = loc.storeName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Kiosk khác';
  }

  Map<String, int> _getKioskCounts(List<LockerLocation> list) {
    final counts = <String, int>{};
    for (final loc in list) {
      final k = _kioskNameOf(loc);
      counts[k] = (counts[k] ?? 0) + 1;
    }
    return counts;
  }

  bool _isMostUsedLocation(LockerLocation loc) {
    return loc.id == _mostUsedLocationId ||
        (_mostUsedLocationName != null &&
            loc.name.trim().toLowerCase() ==
                _mostUsedLocationName!.trim().toLowerCase());
  }

  List<MapEntry<String, List<LockerLocation>>> _groupLocationsByKiosk(
    List<LockerLocation> locations,
  ) {
    if (locations.isEmpty) return const [];

    final map = <String, List<LockerLocation>>{};
    for (final loc in locations) {
      final kiosk = _kioskNameOf(loc);
      (map[kiosk] ??= []).add(loc);
    }

    final entries = map.entries.toList();
    if (_mostUsedLocationId != null || _mostUsedLocationName != null) {
      entries.sort((a, b) {
        final aHasMostUsed = a.value.any(_isMostUsedLocation);
        final bHasMostUsed = b.value.any(_isMostUsedLocation);
        if (aHasMostUsed && !bHasMostUsed) return -1;
        if (!aHasMostUsed && bHasMostUsed) return 1;
        return a.key.compareTo(b.key);
      });
    } else {
      entries.sort((a, b) => a.key.compareTo(b.key));
    }

    for (final entry in entries) {
      if (_mostUsedLocationId != null || _mostUsedLocationName != null) {
        entry.value.sort((a, b) {
          final aIs = _isMostUsedLocation(a);
          final bIs = _isMostUsedLocation(b);
          if (aIs && !bIs) return -1;
          if (!aIs && bIs) return 1;
          return 0;
        });
      }
    }

    return entries;
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
          }
          bestId = id;
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
        // `location.id` là id tủ — mở đúng tủ đó, không coi là id cửa hàng.
        builder: (_) => StoreLockerGridPage.forLocation(location),
      ),
    );
  }

  Widget _buildKioskHeader(String kioskName, int count) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              LucideIcons.store,
              size: 14,
              color: Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Kiosk: $kioskName',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: context.isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : const Color(0xFFCBD5E1),
              ),
            ),
            child: Text(
              '$count tủ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: context.isDark ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKioskFilterChips(List<LockerLocation> allLocations) {
    final kioskCounts = _getKioskCounts(allLocations);
    if (kioskCounts.isEmpty) return const SizedBox.shrink();

    final activeKiosk =
        (_selectedKiosk != 'ALL' && !kioskCounts.containsKey(_selectedKiosk))
            ? 'ALL'
            : _selectedKiosk;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Row(
        children: [
          _KioskChip(
            label: 'Tất cả',
            count: allLocations.length,
            selected: activeKiosk == 'ALL',
            onTap: () => setState(() => _selectedKiosk = 'ALL'),
          ),
          for (final entry in kioskCounts.entries) ...[
            const SizedBox(width: 8),
            _KioskChip(
              label: entry.key,
              count: entry.value,
              selected: activeKiosk == entry.key,
              onTap: () {
                setState(() {
                  _selectedKiosk = activeKiosk == entry.key ? 'ALL' : entry.key;
                });
              },
            ),
          ],
        ],
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
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
              if (state.locations.isNotEmpty) ...[
                _buildKioskFilterChips(state.locations),
              ],
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

    final allLocations = state.locations;
    final kioskCounts = _getKioskCounts(allLocations);
    final activeKiosk =
        (_selectedKiosk != 'ALL' && !kioskCounts.containsKey(_selectedKiosk))
            ? 'ALL'
            : _selectedKiosk;

    final filteredLocations = activeKiosk == 'ALL'
        ? allLocations
        : allLocations.where((loc) => _kioskNameOf(loc) == activeKiosk).toList();

    if (filteredLocations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.store,
                  size: 32,
                  color: context.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Không tìm thấy tủ tại địa điểm này',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Thử chọn địa điểm khác hoặc xem tất cả địa điểm khả dụng.',
                style: TextStyle(fontSize: 13, color: context.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () => setState(() => _selectedKiosk = 'ALL'),
                icon: const Icon(LucideIcons.rotateCcw, size: 15),
                label: const Text('Xem tất cả địa điểm'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F172A),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final groups = _groupLocationsByKiosk(filteredLocations);
    final items = <_LockerListItem>[];
    for (final entry in groups) {
      items.add(_LockerListItem.header(entry.key, entry.value.length));
      for (final loc in entry.value) {
        items.add(_LockerListItem.location(loc));
      }
    }

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
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 100),
        itemCount: items.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _LockerItemSkeleton(),
            );
          }

          final item = items[index];
          if (item.isHeader) {
            return _buildKioskHeader(item.header!, item.count ?? 0);
          }

          final location = item.location!;
          final isMostUsed = _isMostUsedLocation(location);

          final isNextAlsoLocation =
              index + 1 < items.length && !items[index + 1].isHeader;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: LockerItem(
                  location: location,
                  isMostUsed: isMostUsed,
                  userPosition: _userPosition,
                  onTap: () => _navigateToMap(location),
                ),
              ),
              if (isNextAlsoLocation)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(height: 1, color: context.dividerColor),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LockerListItem {
  const _LockerListItem._({this.header, this.count, this.location});
  factory _LockerListItem.header(String h, int count) =>
      _LockerListItem._(header: h, count: count);
  factory _LockerListItem.location(LockerLocation loc) =>
      _LockerListItem._(location: loc);

  final String? header;
  final int? count;
  final LockerLocation? location;

  bool get isHeader => header != null;
}

class _KioskChip extends StatelessWidget {
  const _KioskChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final activeBg = isDark ? Colors.white : const Color(0xFF0F172A);
    final activeFg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final inactiveBg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFF1F5F9);
    final inactiveBorder = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFE2E8F0);
    final inactiveFg = context.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : const Color(0xFF0F172A).withValues(alpha: 0.08),
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
          decoration: BoxDecoration(
            color: selected ? activeBg : inactiveBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? activeBg : inactiveBorder,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? activeFg : inactiveFg,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 5),
                Text(
                  '($count)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? activeFg.withValues(alpha: 0.75)
                        : context.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
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
