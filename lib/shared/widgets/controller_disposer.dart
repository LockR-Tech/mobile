import 'package:flutter/material.dart';

/// Huỷ [controllers] khi widget bị gỡ khỏi cây — dùng cho controller tạo tạm
/// trong `showDialog` / `showModalBottomSheet`.
///
/// Future của `showDialog` hoàn tất ngay khi `Navigator.pop` chạy, nhưng route
/// vẫn còn trong cây cho tới hết hiệu ứng đóng. Huỷ controller ngay sau `await`
/// ⇒ dialog rebuild giữa lúc animate (bàn phím thu lại đổi viewport là đủ) sẽ
/// chạm vào controller đã huỷ: "A TextEditingController was used after being
/// disposed", kéo theo `_dependents.isEmpty` và "dirty widget in the wrong
/// build scope". Bọc bằng widget này thì controller sống đúng bằng vòng đời
/// route.
///
/// Đọc `.text` ngay sau `await showDialog(...)` vẫn an toàn: lúc đó route mới
/// bắt đầu thoát nên controller còn sống.
class ControllerDisposer extends StatefulWidget {
  const ControllerDisposer({
    super.key,
    required this.controllers,
    required this.child,
  });

  final List<ChangeNotifier> controllers;
  final Widget child;

  @override
  State<ControllerDisposer> createState() => _ControllerDisposerState();
}

class _ControllerDisposerState extends State<ControllerDisposer> {
  @override
  void dispose() {
    for (final controller in widget.controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
