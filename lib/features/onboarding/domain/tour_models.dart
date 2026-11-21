/// Mô hình nội dung hướng dẫn lần đầu trên màn hình (F3-G13). Nguồn: `frontend/fe/public/onboarding/tours.json`
/// (bản kèm app: `assets/onboarding/tours.json`, chép bằng `tool/sync_onboarding.sh`).
class TourStep {
  const TourStep({
    required this.id,
    required this.platforms,
    this.anchor,
    this.webRoute,
    this.mobileRoute,
    this.placement = 'auto',
    this.optional = false,
    this.openNav = false,
    this.via,
  });

  final String id;

  /// Phần tử cần khoanh (`TourAnchor` trên mobile, `data-tour` trên web). null = bước giới thiệu ở giữa.
  final String? anchor;
  final String? webRoute;
  final String? mobileRoute;
  final String placement;

  /// true = phần tử có thể không có (dữ liệu rỗng, quyền…) ⇒ bỏ qua lặng lẽ.
  final bool optional;
  final List<String> platforms;

  /// Mở menu ngăn kéo trước khi khoanh.
  final bool openNav;

  /// Neo cần chạm trước khi tìm phần tử của bước (mục đầu danh sách, tab, nút "Chi tiết"…) để mở màn hình chi tiết,
  /// tab hay bảng chứa phần tử. Chỉ chạm khi chưa thấy phần tử; đã ở đúng chỗ thì không đổi trang.
  final String? via;

  factory TourStep.fromJson(Map<String, dynamic> j) => TourStep(
        id: j['id'] as String,
        anchor: j['anchor'] as String?,
        webRoute: j['webRoute'] as String?,
        mobileRoute: j['mobileRoute'] as String?,
        placement: (j['placement'] as String?) ?? 'auto',
        optional: j['optional'] == true,
        openNav: j['openNav'] == true,
        via: j['via'] as String?,
        platforms: ((j['platforms'] as List?) ?? const []).map((e) => '$e').toList(),
      );
}

class TourGroup {
  const TourGroup({
    required this.id,
    required this.version,
    required this.roles,
    required this.steps,
    this.order = 0,
    this.manualOnly = false,
    this.signedOut = false,
  });

  final String id;
  final int version;
  final int order;
  final List<String> roles;
  final List<TourStep> steps;

  /// Chỉ có ở trang HDSD: không tự mở, không chạy trên màn hình.
  final bool manualOnly;

  /// Màn hình trước khi đăng nhập (đăng nhập, đăng ký, OTP…); luôn kèm [manualOnly].
  final bool signedOut;

  List<TourStep> stepsFor(String platform) => steps.where((s) => s.platforms.contains(platform)).toList();

  factory TourGroup.fromJson(Map<String, dynamic> j) => TourGroup(
        id: j['id'] as String,
        version: (j['version'] as num).toInt(),
        order: (j['order'] as num?)?.toInt() ?? 0,
        manualOnly: j['manualOnly'] == true,
        signedOut: j['signedOut'] == true,
        roles: ((j['roles'] as List?) ?? const []).map((e) => '$e').toList(),
        steps: ((j['steps'] as List?) ?? const [])
            .map((e) => TourStep.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class TourContent {
  const TourContent({required this.schemaVersion, required this.groups});

  final int schemaVersion;
  final List<TourGroup> groups;

  factory TourContent.fromJson(Map<String, dynamic> j) => TourContent(
        schemaVersion: (j['schemaVersion'] as num?)?.toInt() ?? 0,
        groups: ((j['groups'] as List?) ?? const [])
            .map((e) => TourGroup.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

/// Trạng thái lưu ở user-service (`GET /api/user/onboarding`), dùng chung với web.
class OnboardingState {
  const OnboardingState({this.autoShow = true, this.seenGroups = const {}});

  final bool autoShow;
  final Map<String, int> seenGroups;

  factory OnboardingState.fromJson(Map<String, dynamic>? j) => OnboardingState(
        autoShow: j?['autoShow'] != false,
        seenGroups: {
          for (final e in ((j?['seenGroups'] as Map?) ?? const {}).entries) '${e.key}': (e.value as num).toInt(),
        },
      );
}

/// Một ô khoanh trên ảnh HDSD: số in trên ảnh ↔ mã bước (file `hdsd/<nhóm>.json` cạnh ảnh).
class ManualMark {
  const ManualMark(this.n, this.stepId);

  final int n;
  final String stepId;
}
