import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/shadcn_theme.dart';
import '../../locker_ops/presentation/widgets/ops_widgets.dart';
import '../data/mission_codec.dart';
import '../data/mission_repository.dart';
import '../domain/flight_mission.dart';
import '../domain/mission_item.dart';
import 'widgets/waypoint_edit_sheet.dart';

/// Mission Planner — Flight Plan editor (Mảng 1). Draw waypoints on a map, set
/// altitude/command per point, chain them into a route, then save/export to a
/// mission file. Pure frontend + data model; no drone or backend involved.
class MissionPlannerPage extends StatefulWidget {
  const MissionPlannerPage({super.key});

  @override
  State<MissionPlannerPage> createState() => _MissionPlannerPageState();
}

class _MissionPlannerPageState extends State<MissionPlannerPage> {
  final MissionRepository _repo = MissionRepository();
  final MapController _map = MapController();

  late FlightMission _mission = FlightMission.empty(id: _repo.newId());

  /// Index (in `items`) of the waypoint awaiting relocation; the next map tap
  /// moves it instead of adding a new point.
  int? _moveIndex;
  bool _located = false;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _locate();
  }

  // ── location ──────────────────────────────────────────────────────────────

  Future<void> _locate() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      final me = LatLng(pos.latitude, pos.longitude);
      setState(() {
        // Only relocate home if the user has not started planning yet.
        if (_mission.items.isEmpty) {
          _mission = _mission.copyWith(home: me);
        }
        _located = true;
      });
      // If the map has not rendered yet, MapOptions.initialCenter (= home) will
      // already centre on `me`; otherwise recentre now.
      if (_mapReady) _map.move(me, 16);
    } catch (_) {
      // Best-effort: planner still works centred on the default location.
    }
  }

  // ── map interaction ───────────────────────────────────────────────────────

  void _onMapTap(TapPosition _, LatLng point) {
    if (_moveIndex != null) {
      final index = _moveIndex!;
      setState(() {
        _mission = _mission.updateItem(index, _mission.items[index].movedTo(point));
        _moveIndex = null;
      });
      return;
    }
    setState(() {
      _mission = _mission.addItem(
        MissionItem.waypoint(point, _mission.defaultAltitude),
      );
    });
  }

  Future<void> _editWaypoint(int index) async {
    final result = await WaypointEditSheet.show(
      context,
      item: _mission.items[index],
      index: index + 1,
      total: _mission.items.length,
    );
    if (result == null || !mounted) return;
    switch (result.action) {
      case WaypointEditAction.save:
        if (result.item != null) {
          setState(() => _mission = _mission.updateItem(index, result.item!));
        }
      case WaypointEditAction.delete:
        setState(() => _mission = _mission.removeItem(index));
      case WaypointEditAction.move:
        setState(() => _moveIndex = index);
        _toast('Chạm lên bản đồ để đặt lại vị trí điểm ${index + 1}.');
    }
  }

  // ── camera helpers ─────────────────────────────────────────────────────────

  void _fitToMission() {
    final points = _mission.pathPoints;
    if (points.length < 2) {
      _map.move(_mission.home, 16);
      return;
    }
    var minLat = points.first.latitude, maxLat = points.first.latitude;
    var minLng = points.first.longitude, maxLng = points.first.longitude;
    for (final p in points) {
      minLat = p.latitude < minLat ? p.latitude : minLat;
      maxLat = p.latitude > maxLat ? p.latitude : maxLat;
      minLng = p.longitude < minLng ? p.longitude : minLng;
      maxLng = p.longitude > maxLng ? p.longitude : maxLng;
    }
    _map.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng)),
        padding: const EdgeInsets.all(70),
      ),
    );
  }

  // ── mission menu actions ───────────────────────────────────────────────────

  Future<void> _rename() async {
    final ctrl = TextEditingController(text: _mission.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tên kế hoạch bay'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'VD: Tuần tra khu A'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      setState(() => _mission = _mission.copyWith(name: name));
    }
  }

  Future<void> _openSettings() async {
    final altCtrl = TextEditingController(text: _numText(_mission.defaultAltitude));
    final spdCtrl = TextEditingController(text: _numText(_mission.cruiseSpeed));
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom +
            MediaQuery.of(ctx).padding.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cài đặt kế hoạch',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AISLShadcnTheme.navyPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _settingField('Độ cao mặc định cho điểm mới (m)', altCtrl),
              const SizedBox(height: 14),
              _settingField('Tốc độ bay ước tính (m/s)', spdCtrl),
              const SizedBox(height: 18),
              OpsPrimaryButton(
                label: 'Áp dụng',
                icon: LucideIcons.check,
                onPressed: () {
                  setState(() {
                    _mission = _mission.copyWith(
                      defaultAltitude:
                          double.tryParse(altCtrl.text.trim()) ??
                              _mission.defaultAltitude,
                      cruiseSpeed: double.tryParse(spdCtrl.text.trim()) ??
                          _mission.cruiseSpeed,
                    );
                  });
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveToLibrary() async {
    setState(() => _mission = _mission.copyWith(updatedAt: DateTime.now()));
    await _repo.saveToLibrary(_mission);
    _toast('Đã lưu "${_mission.name}" vào thư viện.');
  }

  Future<void> _openLibrary() async {
    final missions = await _repo.loadLibrary();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Column(
              children: [
                const SizedBox(height: 12),
                const Text(
                  'Thư viện kế hoạch bay',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AISLShadcnTheme.navyPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: missions.isEmpty
                      ? const Center(
                          child: OpsEmptyState(
                            icon: Icons.map_outlined,
                            title: 'Chưa có kế hoạch đã lưu',
                            subtitle: 'Lưu kế hoạch hiện tại để mở lại sau.',
                          ),
                        )
                      : ListView.builder(
                          controller: controller,
                          padding: const EdgeInsets.all(12),
                          itemCount: missions.length,
                          itemBuilder: (_, i) => _libraryTile(ctx, missions[i]),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _libraryTile(BuildContext sheetCtx, FlightMission m) {
    return OpsCard(
      onTap: () {
        Navigator.pop(sheetCtx);
        setState(() => _mission = m);
        _fitToMission();
        _toast('Đã mở "${m.name}".');
      },
      child: Row(
        children: [
          const Icon(LucideIcons.route, color: AISLShadcnTheme.navyAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${m.waypointCount} điểm · ${_km(m.totalDistanceMeters)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2, size: 18, color: Color(0xFFDC2626)),
            onPressed: () async {
              await _repo.deleteFromLibrary(m.id);
              if (sheetCtx.mounted) Navigator.pop(sheetCtx);
              _toast('Đã xoá "${m.name}".');
            },
          ),
        ],
      ),
    );
  }

  Future<void> _importFile() async {
    try {
      final mission = await _repo.importFromFile();
      if (mission == null || !mounted) return;
      setState(() => _mission = mission);
      _fitToMission();
      _toast('Đã nhập "${mission.name}" (${mission.waypointCount} điểm).');
    } on MissionParseException catch (e) {
      _toast(e.message, error: true);
    }
  }

  Future<void> _export({required bool waypoints}) async {
    if (_mission.items.isEmpty) {
      _toast('Chưa có điểm bay nào để xuất.', error: true);
      return;
    }
    try {
      final path = waypoints
          ? await _repo.exportWaypointsFile(_mission)
          : await _repo.exportJsonFile(_mission);
      if (path == null) return; // cancelled
      _toast('Đã xuất file: $path');
    } catch (e) {
      _toast('Không xuất được file: $e', error: true);
    }
  }

  void _setHomeAtCenter() {
    setState(() => _mission = _mission.copyWith(home: _map.camera.center));
    _toast('Đã đặt điểm xuất phát (HOME) tại tâm bản đồ.');
  }

  Future<void> _clearAll() async {
    if (_mission.items.isEmpty) return;
    final ok = await _confirm('Xoá tất cả điểm bay của kế hoạch hiện tại?');
    if (ok) setState(() => _mission = _mission.copyWith(items: const []));
  }

  Future<void> _newMission() async {
    final ok = await _confirm('Tạo kế hoạch mới? Thay đổi chưa lưu sẽ mất.');
    if (!ok) return;
    setState(() {
      _mission = FlightMission.empty(id: _repo.newId(), home: _map.camera.center);
      _moveIndex = null;
    });
  }

  Future<void> _openMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).padding.bottom;
        Widget action(IconData icon, String label, VoidCallback onTap,
            {bool danger = false}) {
          return ListTile(
            leading: Icon(icon,
                color: danger ? const Color(0xFFDC2626) : AISLShadcnTheme.navyAccent),
            title: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: danger ? const Color(0xFFDC2626) : null)),
            onTap: () {
              Navigator.pop(ctx);
              onTap();
            },
          );
        }

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                action(LucideIcons.pencil, 'Đổi tên kế hoạch', _rename),
                action(LucideIcons.settings2, 'Cài đặt (độ cao/tốc độ)', _openSettings),
                action(LucideIcons.house, 'Đặt HOME tại tâm bản đồ', _setHomeAtCenter),
                const Divider(height: 1),
                action(LucideIcons.save, 'Lưu vào thư viện', _saveToLibrary),
                action(LucideIcons.folderOpen, 'Mở từ thư viện', _openLibrary),
                action(LucideIcons.fileDown, 'Xuất file .waypoints (QGC)',
                    () => _export(waypoints: true)),
                action(LucideIcons.fileJson, 'Xuất file JSON',
                    () => _export(waypoints: false)),
                action(LucideIcons.fileUp, 'Nhập từ file', _importFile),
                const Divider(height: 1),
                action(LucideIcons.filePlus, 'Tạo kế hoạch mới', _newMission),
                action(LucideIcons.eraser, 'Xoá tất cả điểm', _clearAll, danger: true),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openWaypointList() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.55,
              maxChildSize: 0.92,
              builder: (_, controller) {
                final items = _mission.items;
                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.listOrdered,
                            size: 18, color: AISLShadcnTheme.navyPrimary),
                        const SizedBox(width: 8),
                        Text(
                          'Danh sách điểm bay (${items.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AISLShadcnTheme.navyPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: items.isEmpty
                          ? const Center(
                              child: OpsEmptyState(
                                icon: Icons.add_location_alt_outlined,
                                title: 'Chưa có điểm bay',
                                subtitle: 'Chạm lên bản đồ để thêm điểm.',
                              ),
                            )
                          : ReorderableListView.builder(
                              scrollController: controller,
                              padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                              itemCount: items.length,
                              onReorderItem: (oldI, newI) {
                                setState(() =>
                                    _mission = _mission.reorder(oldI, newI));
                                setSheet(() {});
                              },
                              itemBuilder: (_, i) => _waypointTile(ctx, setSheet, i),
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _waypointTile(BuildContext sheetCtx, StateSetter setSheet, int i) {
    final item = _mission.items[i];
    final cmd = item.command;
    final subtitleParts = <String>[
      if (cmd.hasAltitude) '↑ ${_numText(item.altitude)} m',
      if (cmd.hasExtraParam)
        '${cmd.extraLabel}: ${_numText(item.extraValue ?? 0)} ${cmd.extraUnit}',
      if (cmd.hasPosition)
        '${item.latitude.toStringAsFixed(5)}, ${item.longitude.toStringAsFixed(5)}',
    ];
    return Padding(
      key: ValueKey('wp_$i'),
      padding: const EdgeInsets.only(bottom: 8),
      child: OpsCard(
        onTap: () async {
          Navigator.pop(sheetCtx);
          await _editWaypoint(i);
        },
        child: Row(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: AISLShadcnTheme.navyPrimary,
              child: Text('${i + 1}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cmd.label,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (subtitleParts.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtitleParts.join('  ·  '),
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ],
              ),
            ),
            ReorderableDragStartListener(
              index: i,
              child: const Icon(LucideIcons.gripVertical,
                  size: 18, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }

  // ── build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _mission.home,
              initialZoom: 15,
              onTap: _onMapTap,
              onMapReady: () => _mapReady = true,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.aisl.app',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _mission.pathPoints,
                    color: AISLShadcnTheme.navyAccent,
                    strokeWidth: 4,
                  ),
                ],
              ),
              MarkerLayer(markers: _markers()),
            ],
          ),
          _topBar(topPad),
          if (_moveIndex != null) _moveBanner(topPad),
          Positioned(
            right: 12,
            bottom: 150,
            child: Column(
              children: [
                _MapFab(
                  icon: _located ? LucideIcons.locateFixed : LucideIcons.locate,
                  onTap: _locate,
                ),
                const SizedBox(height: 10),
                _MapFab(icon: LucideIcons.maximize, onTap: _fitToMission),
              ],
            ),
          ),
          Align(alignment: Alignment.bottomCenter, child: _summaryBar()),
        ],
      ),
    );
  }

  List<Marker> _markers() {
    final markers = <Marker>[
      Marker(
        point: _mission.home,
        width: 44,
        height: 44,
        child: Tooltip(
          message: 'Điểm xuất phát (HOME)',
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF16A34A),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.house, color: Colors.white, size: 22),
          ),
        ),
      ),
    ];
    var n = 0;
    for (var i = 0; i < _mission.items.length; i++) {
      final point = _mission.items[i].point;
      if (point == null) continue;
      n += 1;
      final isMoving = _moveIndex == i;
      markers.add(
        Marker(
          point: point,
          width: 38,
          height: 38,
          child: GestureDetector(
            onTap: () => _editWaypoint(i),
            child: Container(
              decoration: BoxDecoration(
                color: isMoving
                    ? const Color(0xFFF59E0B)
                    : AISLShadcnTheme.navyPrimary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2)),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '$n',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return markers;
  }

  Widget _topBar(double topPad) {
    return Positioned(
      top: topPad + 10,
      left: 12,
      right: 12,
      child: Row(
        children: [
          _MapFab(icon: Icons.arrow_back_rounded, onTap: () => Navigator.maybePop(context)),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: _rename,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.route,
                        size: 16, color: AISLShadcnTheme.navyPrimary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _mission.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AISLShadcnTheme.navyPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(LucideIcons.pencil, size: 13, color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _MapFab(icon: LucideIcons.menu, onTap: _openMenu),
        ],
      ),
    );
  }

  Widget _moveBanner(double topPad) {
    return Positioned(
      top: topPad + 66,
      left: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.move, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Chạm lên bản đồ để đặt lại vị trí điểm bay.',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12.5),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _moveIndex = null),
              child: const Text('Huỷ',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryBar() {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      margin: EdgeInsets.fromLTRB(12, 12, 12, 12 + bottomPad),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _stat(LucideIcons.mapPin, '${_mission.waypointCount}', 'điểm'),
              _statDivider(),
              _stat(LucideIcons.route, _km(_mission.totalDistanceMeters), 'quãng đường'),
              _statDivider(),
              _stat(LucideIcons.clock, _duration(_mission.estimatedSeconds), 'ước tính'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openWaypointList,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AISLShadcnTheme.navyPrimary,
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(LucideIcons.listOrdered, size: 16),
                  label: const Text('Danh sách'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _export(waypoints: true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AISLShadcnTheme.navyPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(LucideIcons.fileDown, size: 16),
                  label: const Text('Xuất mission'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: AISLShadcnTheme.navyAccent),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _statDivider() =>
      Container(width: 1, height: 34, color: const Color(0xFFEDF1F6));

  // ── small helpers ─────────────────────────────────────────────────────────

  Widget _settingField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Future<bool> _confirm(String message) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Đồng ý')),
        ],
      ),
    );
    return ok ?? false;
  }

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? const Color(0xFFDC2626) : AISLShadcnTheme.navyPrimary,
        ),
      );
  }

  String _numText(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  String _km(double meters) => meters >= 1000
      ? '${(meters / 1000).toStringAsFixed(2)} km'
      : '${meters.round()} m';

  String _duration(double seconds) {
    if (seconds <= 0) return '0 phút';
    final mins = seconds / 60;
    if (mins < 1) return '<1 phút';
    if (mins < 60) return '${mins.round()} phút';
    final h = mins ~/ 60;
    final m = (mins % 60).round();
    return '${h}h ${m}m';
  }
}

/// Circular floating map button matching the directions screen style.
class _MapFab extends StatelessWidget {
  const _MapFab({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 3)),
          ],
        ),
        child: Icon(icon, color: AISLShadcnTheme.navyPrimary, size: 21),
      ),
    );
  }
}
