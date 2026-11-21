// Logic thuần của hướng dẫn lần đầu (F3-G13) — bản Dart của `frontend/fe/src/onboarding/engine.ts`, chạy cùng
// bộ ca `test/onboarding/fixtures/onboarding-cases.json` để hai nền tảng hành xử giống hệt nhau.
import 'tour_models.dart';

const tourRoles = ['ADMIN', 'CUSTOMER', 'LOCKER_TECHNICIAN', 'DRONE_TECHNICIAN'];
/// kiosk = màn hình cảm ứng tại tủ (repo iot) — chỉ có trong trang HDSD (nhóm manualOnly).
const tourPlatforms = ['web', 'mobile', 'kiosk'];
const tourPlacements = ['auto', 'top', 'bottom', 'left', 'right'];
const autoOpenDelay = Duration(milliseconds: 1000);
final idPattern = RegExp(r'^[a-z0-9][a-z0-9-]{0,63}$');

/// Vai trò từ JWT/hồ sơ (chuỗi "ADMIN, DRONE_TECHNICIAN", danh sách, tiền tố ROLE_…) ⇒ tập vai trò của tour.
List<String> normalizeRoles(Object? raw) {
  final List<Object?> list;
  if (raw is List) {
    list = raw;
  } else if (raw is String) {
    list = raw.split(',');
  } else {
    list = const [];
  }
  final out = <String>[];
  for (final item in list) {
    var r = '${item ?? ''}'.trim().toUpperCase();
    if (r.startsWith('ROLE_')) r = r.substring(5);
    if (r == 'SUPER_ADMIN') r = 'ADMIN';
    if (tourRoles.contains(r) && !out.contains(r)) out.add(r);
  }
  return out;
}

int _byOrder(TourGroup a, TourGroup b) {
  final c = a.order.compareTo(b.order);
  return c != 0 ? c : a.id.compareTo(b.id);
}

/// Chạy được trên màn hình ở nền tảng này: có bước ở nền tảng đó và không phải nhóm chỉ có trong HDSD.
bool runnable(TourGroup group, String platform) => !group.manualOnly && group.stepsFor(platform).isNotEmpty;

/// Nhóm người dùng tự chạy được trên nền tảng này: đúng vai trò và chạy được trên màn hình.
List<TourGroup> ownGroups(TourContent content, List<String> roles, String platform) =>
    content.groups.where((g) => g.roles.any(roles.contains) && runnable(g, platform)).toList()
      ..sort(_byOrder);

/// Nhóm được XEM (danh sách, HDSD): ADMIN xem mọi vai trò, người khác chỉ vai trò mình.
List<TourGroup> browseGroups(TourContent content, List<String> roles) {
  final admin = roles.contains('ADMIN');
  return content.groups.where((g) => admin || g.roles.any(roles.contains)).toList()..sort(_byOrder);
}

/// "new" | "updated" | "seen"
String groupStatus(TourGroup group, Map<String, int>? seen) {
  final v = seen?[group.id];
  if (v == null || v < 1) return 'new';
  return group.version > v ? 'updated' : 'seen';
}

List<TourGroup> pendingGroups(List<TourGroup> groups, Map<String, int>? seen) =>
    groups.where((g) => groupStatus(g, seen) != 'seen').toList();

class AutoOpenDecision {
  const AutoOpenDecision.none(this.reason)
      : kind = 'none',
        groups = const [];
  const AutoOpenDecision(this.kind, this.groups) : reason = null;

  /// "none" | "welcome" | "whatsNew"
  final String kind;
  final List<TourGroup> groups;
  final String? reason;
}

AutoOpenDecision decideAutoOpen({
  required bool signedIn,
  required bool inWorkspace,
  required bool mandatoryDone,
  required bool autoShow,
  required bool sessionSkipped,
  required bool shownThisSession,
  required List<TourGroup> groups,
  Map<String, int>? seen,
}) {
  if (!signedIn) return const AutoOpenDecision.none('signed-out');
  if (!inWorkspace) return const AutoOpenDecision.none('not-in-workspace');
  if (!mandatoryDone) return const AutoOpenDecision.none('mandatory-steps-pending');
  if (!autoShow) return const AutoOpenDecision.none('skipped-forever');
  if (sessionSkipped) return const AutoOpenDecision.none('skipped-this-session');
  if (shownThisSession) return const AutoOpenDecision.none('already-shown');
  final pending = pendingGroups(groups, seen);
  if (pending.isEmpty) return const AutoOpenDecision.none('nothing-new');
  final seenAny = groups.any((g) => (seen?[g.id] ?? 0) > 0);
  return seenAny ? AutoOpenDecision('whatsNew', pending) : AutoOpenDecision('welcome', List.of(groups));
}

/// "show" | "center" | "skip" | "missing"
String resolveStep(TourStep step, bool anchorFound) {
  if (step.anchor == null) return 'center';
  if (anchorFound) return 'show';
  return step.optional ? 'skip' : 'missing';
}

List<String> textKeys(TourGroup group) => [
      'groups.${group.id}.title',
      'groups.${group.id}.summary',
      for (final s in group.steps) ...['steps.${s.id}.title', 'steps.${s.id}.body'],
    ];

Object? lookupText(Object? data, String dotted) {
  Object? cur = data;
  for (final k in dotted.split('.')) {
    if (cur is Map) {
      cur = cur[k];
    } else {
      return null;
    }
  }
  return cur;
}
