import 'package:flutter/widgets.dart';

/// Neo cho hướng dẫn lần đầu (F3-G13) — tương đương `data-tour="<id>"` trên web. Bọc phần tử cần khoanh:
///
/// ```dart
/// TourAnchor('home-scan', child: scanButton)
/// ```
///
/// Đăng ký GlobalKey vào [TourAnchorRegistry] để lớp khoanh tìm được vị trí, và gắn
/// `Semantics(identifier: 'tour:<id>')` để script chụp ảnh HDSD tìm được phần tử trên bản Flutter web.
class TourAnchor extends StatefulWidget {
  const TourAnchor(this.id, {super.key, required this.child});

  final String id;
  final Widget child;

  @override
  State<TourAnchor> createState() => _TourAnchorState();
}

class _TourAnchorState extends State<TourAnchor> {
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    TourAnchorRegistry.register(widget.id, _key);
  }

  @override
  void didUpdateWidget(TourAnchor old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id) {
      TourAnchorRegistry.unregister(old.id, _key);
      TourAnchorRegistry.register(widget.id, _key);
    }
  }

  @override
  void dispose() {
    TourAnchorRegistry.unregister(widget.id, _key);
    super.dispose();
  }

  @override
  // explicitChildNodes: phần tử con bấm được (InkWell…) không gộp vào nút neo — nếu gộp, bản web coi nút là
  // "group" và bỏ mất identifier (thẻ ca làm của KTV từng không tìm thấy vì vậy).
  Widget build(BuildContext context) => Semantics(
        identifier: 'tour:${widget.id}',
        container: true,
        explicitChildNodes: true,
        child: KeyedSubtree(key: _key, child: widget.child),
      );
}

/// Bảng neo đang có trên màn hình. Cùng mã ở nhiều trang (vd. `app-guide-button`) ⇒ trang dựng sau cùng thắng.
class TourAnchorRegistry {
  TourAnchorRegistry._();

  static final Map<String, List<GlobalKey>> _anchors = {};

  static void register(String id, GlobalKey key) => (_anchors[id] ??= []).add(key);

  static void unregister(String id, GlobalKey key) {
    _anchors[id]?.remove(key);
    if (_anchors[id]?.isEmpty ?? false) _anchors.remove(id);
  }

  /// RenderBox đang hiển thị của neo (bỏ qua neo đã tháo hoặc chưa có kích thước).
  static RenderBox? find(String id) {
    final keys = _anchors[id];
    if (keys == null) return null;
    for (final key in keys.reversed) {
      final ro = key.currentContext?.findRenderObject();
      if (ro is RenderBox && ro.attached && ro.hasSize && !ro.size.isEmpty) return ro;
    }
    return null;
  }

  static BuildContext? contextOf(String id) {
    final keys = _anchors[id];
    if (keys == null) return null;
    for (final key in keys.reversed) {
      final ctx = key.currentContext;
      if (ctx != null) return ctx;
    }
    return null;
  }
}

/// Trang có menu ngăn kéo đăng ký cách mở menu, để bước `openNav` mở trước khi khoanh mục trong đó.
class TourNav {
  TourNav._();

  static final List<VoidCallback> _openers = [];

  static void register(VoidCallback open) => _openers.add(open);

  static void unregister(VoidCallback open) => _openers.remove(open);

  static void openDrawer() {
    for (final open in List.of(_openers)) {
      open();
    }
  }
}
