import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/flight_mission.dart';
import 'mission_codec.dart';

/// Persists flight missions on-device and exchanges them with real ground
/// stations via files.
///
/// * **Library** — a named set of saved plans kept in `shared_preferences`
///   (one JSON blob per mission), so a maintenance user can build, store and
///   reopen plans without any backend.
/// * **Files** — export to a QGC WPL 110 `.waypoints` file (Mission Planner /
///   QGroundControl compatible) or internal `.json`, and import either back.
class MissionRepository {
  MissionRepository({MissionCodec? codec}) : _codec = codec ?? const MissionCodec();

  final MissionCodec _codec;

  static const String _libraryKey = 'drone_mission_library';

  /// Generates a new unique mission id.
  String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  // ── Local library ────────────────────────────────────────────────────────

  /// Loads all saved missions, most-recently-updated first.
  Future<List<FlightMission>> loadLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_libraryKey) ?? const <String>[];
    final missions = <FlightMission>[];
    for (final entry in raw) {
      try {
        missions.add(_codec.decodeJson(entry));
      } catch (_) {
        // Skip corrupt entries rather than breaking the whole library.
      }
    }
    missions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return missions;
  }

  /// Inserts or replaces [mission] in the library (matched by id).
  Future<void> saveToLibrary(FlightMission mission) async {
    final prefs = await SharedPreferences.getInstance();
    final missions = await loadLibrary();
    final next = [
      mission,
      for (final m in missions)
        if (m.id != mission.id) m,
    ];
    await prefs.setStringList(
      _libraryKey,
      next.map(_codec.encodeJson).toList(),
    );
  }

  /// Removes the mission with [id] from the library.
  Future<void> deleteFromLibrary(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final missions = await loadLibrary();
    await prefs.setStringList(
      _libraryKey,
      missions.where((m) => m.id != id).map(_codec.encodeJson).toList(),
    );
  }

  // ── File export / import ─────────────────────────────────────────────────

  /// Writes [mission] as a QGC WPL 110 `.waypoints` file via the system file
  /// picker. Returns the saved path, or `null` if the user cancelled.
  Future<String?> exportWaypointsFile(FlightMission mission) {
    return _saveText(
      content: _codec.encodeWaypoints(mission),
      fileName: '${_safeName(mission.name)}.waypoints',
    );
  }

  /// Writes [mission] as an internal `.json` file via the system file picker.
  /// Returns the saved path, or `null` if the user cancelled.
  Future<String?> exportJsonFile(FlightMission mission) {
    return _saveText(
      content: _codec.encodeJson(mission),
      fileName: '${_safeName(mission.name)}.json',
    );
  }

  /// Lets the user pick a `.waypoints` / `.json` mission file and parses it.
  /// Returns `null` if the user cancelled. Throws [MissionParseException] when
  /// the chosen file is not a recognised mission.
  Future<FlightMission?> importFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      throw MissionParseException('Không đọc được nội dung file đã chọn.');
    }
    final content = utf8.decode(bytes, allowMalformed: true).trim();
    final id = newId();
    final name = _stripExtension(file.name);

    if (content.startsWith('QGC WPL')) {
      return _codec.decodeWaypoints(content, id: id, name: name);
    }
    if (content.startsWith('{')) {
      // Re-id imported JSON so it never clobbers an existing library entry.
      return _codec.decodeJson(content).withId(id);
    }
    throw MissionParseException(
      'Định dạng không nhận diện được (cần QGC WPL hoặc JSON mission).',
    );
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  Future<String?> _saveText({
    required String content,
    required String fileName,
  }) async {
    final bytes = Uint8List.fromList(utf8.encode(content));
    return FilePicker.platform.saveFile(
      dialogTitle: 'Lưu file mission',
      fileName: fileName,
      bytes: bytes,
    );
  }

  String _safeName(String name) {
    final cleaned = name.trim().replaceAll(RegExp(r'[^\w\-. ]'), '_');
    return cleaned.isEmpty ? 'mission' : cleaned;
  }

  String _stripExtension(String fileName) {
    final dot = fileName.lastIndexOf('.');
    return dot > 0 ? fileName.substring(0, dot) : fileName;
  }
}
