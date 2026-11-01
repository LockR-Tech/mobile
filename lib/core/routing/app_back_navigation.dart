import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_laundry_locker/core/routing/role_routes.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// Nút / cử chỉ quay lại của điện thoại đi theo lịch sử trang như trình duyệt, không thoát app.
///
/// * Còn trang chồng lên (chi tiết, hộp thoại…) ⇒ đóng trang đó như cũ.
/// * Đang ở trang gốc của một tab ⇒ về trang / tab đã xem ngay trước đó (trước đây thoát app).
/// * Không còn lịch sử ⇒ về trang chủ của vai trò; đã ở trang chủ ⇒ bấm lần nữa trong 2 giây mới thoát.
/// * Vuốt từ cạnh PHẢI vào (Android 14+, cử chỉ điều hướng) ⇒ đi tới trang vừa quay lại; cạnh TRÁI ⇒ quay lại.
///
/// Cạnh vuốt lấy từ predictive back (`android:enableOnBackInvokedCallback="true"`); app luôn báo hệ thống
/// là tự xử lý nút quay lại (xem [onNavigationNotification]) để mọi lần quay lại đều tới đây.
class AppBackNavigation with WidgetsBindingObserver {
  AppBackNavigation._();

  static final AppBackNavigation instance = AppBackNavigation._();

  static const int _maxHistory = 40;
  static const Duration _exitWindow = Duration(seconds: 2);
  static const Duration _edgeWindow = Duration(seconds: 3);

  /// Trang không ghi vào lịch sử (khởi động, đăng nhập): vào đó là xoá lịch sử.
  static const Set<String> _resetPaths = {'/', '/onboarding', '/otp', '/forgot-password'};

  GoRouter? _router;
  ChildBackButtonDispatcher? _dispatcher;

  final List<_Entry> _back = [];
  final List<_ForwardEntry> _forward = [];
  _Entry? _pendingForward;
  bool _pendingGoBack = false;
  DateTime? _lastExitPress;
  SwipeEdge? _edge;
  DateTime? _edgeAt;

  /// Gắn vào router một lần lúc khởi động app.
  void attach(GoRouter router) {
    if (_router != null) return;
    _router = router;
    WidgetsBinding.instance.addObserver(this);
    router.routerDelegate.addListener(_onLocationChanged);
    TokenService.authState.addListener(_reset);
    // Bộ nhận nút quay lại của router chỉ có sau khi widget Router dựng xong ⇒ gắn sau khung hình đầu.
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureDispatcher());
  }

  void _ensureDispatcher() {
    final router = _router;
    if (router == null || _dispatcher != null) return;
    final root = router.backButtonDispatcher;
    // ignore: invalid_use_of_protected_member
    if (!root.hasCallbacks) return;
    _dispatcher = root.createChildBackButtonDispatcher()
      ..addCallback(handleBack)
      ..takePriority();
  }

  @visibleForTesting
  void detach() {
    final router = _router;
    if (router == null) return;
    WidgetsBinding.instance.removeObserver(this);
    router.routerDelegate.removeListener(_onLocationChanged);
    _dispatcher?.removeCallback(handleBack);
    TokenService.authState.removeListener(_reset);
    _router = null;
    _dispatcher = null;
    _reset();
  }

  /// Truyền cho `onNavigationNotification` của app: luôn nhận nút quay lại, kể cả khi không còn trang để
  /// đóng — nếu không, Android tự thoát app trước khi tới [handleBack].
  static bool onNavigationNotification(NavigationNotification notification) {
    SystemNavigator.setFrameworkHandlesBack(true);
    return true;
  }

  @visibleForTesting
  List<String> get backHistory => [for (final e in _back) e.uri.toString()];

  @visibleForTesting
  List<String> get forwardHistory => [for (final e in _forward) e.entry.uri.toString()];

  void _reset() {
    _back.clear();
    _forward.clear();
    _pendingForward = null;
    _pendingGoBack = false;
  }

  void _onLocationChanged() {
    final router = _router;
    if (router == null) return;
    _ensureDispatcher();
    if (router.routerDelegate.currentConfiguration.isEmpty) return;
    // Trang trên cùng, kể cả trang đẩy chồng bằng push (currentConfiguration.uri chỉ là trang gốc).
    final state = router.state;
    final entry = _Entry(state.uri, state.extra);
    if (_resetPaths.contains(entry.uri.path)) {
      _reset();
      return;
    }
    if (_back.isNotEmpty && _back.last.sameAs(entry)) return;

    final forward = _pendingForward;
    if (forward != null && forward.sameAs(entry)) {
      _pendingForward = null;
      _back.add(entry);
      return;
    }
    _pendingForward = null;

    if (_back.length >= 2 && _back[_back.length - 2].sameAs(entry)) {
      // Về đúng trang trước đó (nút quay lại, mũi tên trên thanh tiêu đề, tab trước…).
      final left = _back.removeLast();
      _forward.add(_ForwardEntry(left, push: !_pendingGoBack));
      _pendingGoBack = false;
      return;
    }
    _pendingGoBack = false;
    _back.add(entry);
    _forward.clear();
    if (_back.length > _maxHistory) _back.removeAt(0);
  }

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    _edge = backEvent.swipeEdge;
    _edgeAt = DateTime.now();
    return false; // không giành cử chỉ: lúc thả tay hệ thống vẫn gửi "quay lại" bình thường.
  }

  @override
  void handleCancelBackGesture() {
    _edge = null;
    _edgeAt = null;
  }

  SwipeEdge? _takeEdge() {
    final edge = _edge;
    final at = _edgeAt;
    _edge = null;
    _edgeAt = null;
    if (edge == null || at == null) return null;
    return DateTime.now().difference(at) <= _edgeWindow ? edge : null;
  }

  /// Trả `false` để router tự đóng trang trên cùng; `true` khi đã tự xử lý.
  @visibleForTesting
  Future<bool> handleBack() async {
    final router = _router;
    if (router == null) return false;
    if (_takeEdge() == SwipeEdge.right) {
      goForward();
      return true;
    }
    if (router.canPop()) return false;

    if (_back.length >= 2) {
      final previous = _back[_back.length - 2];
      _pendingGoBack = true;
      router.go(previous.uri.toString(), extra: previous.extra);
      return true;
    }

    final roles = await TokenService.getCurrentRoles();
    final home = TokenService.authState.value ? homeForRoles(roles) : '/onboarding';
    if (router.state.uri.path != home) {
      router.go(home);
      return true;
    }

    final now = DateTime.now();
    final last = _lastExitPress;
    if (last != null && now.difference(last) <= _exitWindow) {
      _lastExitPress = null;
      await SystemNavigator.pop();
      return true;
    }
    _lastExitPress = now;
    SmartDialog.showToast(L10n.current.backPressAgainToExit);
    return true;
  }

  /// Mở lại trang vừa quay lại (như nút "tới" của trình duyệt). Không có ⇒ không làm gì.
  bool goForward() {
    final router = _router;
    if (router == null || _forward.isEmpty) return false;
    final next = _forward.removeLast();
    // [_onLocationChanged] nhận ra trang này là "đi tới" nên không xoá phần "tới" còn lại.
    _pendingForward = next.entry;
    if (next.push) {
      router.push(next.entry.uri.toString(), extra: next.entry.extra);
    } else {
      router.go(next.entry.uri.toString(), extra: next.entry.extra);
    }
    return true;
  }
}

class _Entry {
  const _Entry(this.uri, this.extra);

  final Uri uri;
  final Object? extra;

  bool sameAs(_Entry other) => uri == other.uri;
}

class _ForwardEntry {
  const _ForwardEntry(this.entry, {required this.push});

  final _Entry entry;

  /// Trang này lúc trước được đẩy chồng (đóng bằng pop) ⇒ đi tới bằng push; còn lại (tab, `go`) ⇒ go.
  final bool push;
}
