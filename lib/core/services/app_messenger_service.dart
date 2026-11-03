import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

/// Thông báo nổi của app đi qua hai kênh: SnackBar (`ScaffoldMessenger`) và toast SmartDialog — cả hai
/// cùng nằm ở đáy màn hình. Luật chung: **mỗi lúc chỉ một thông báo**, thông báo mới thay ngay thông báo cũ
/// (trước đây toast xếp hàng hiện lần lượt và SnackBar hiện chồng lên toast).
class AppMessengerService {
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Toast SmartDialog: toast mới đẩy toast đang hiện đi, không xếp hàng.
  static void configureToasts() {
    SmartDialog.config.toast = SmartConfigToast(
      displayType: SmartToastType.last,
    );
  }

  /// Gọi khi một toast SmartDialog vừa hiện: bỏ SnackBar đang hiện.
  static void onToastShown() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => scaffoldMessengerKey.currentState?.removeCurrentSnackBar(),
    );
  }
}

/// `ScaffoldMessenger` gốc của app: hiện SnackBar mới thì tắt ngay SnackBar cũ và toast SmartDialog
/// đang hiện, thay vì chờ cái cũ hết giờ.
class AppScaffoldMessenger extends ScaffoldMessenger {
  const AppScaffoldMessenger({super.key, required super.child});

  @override
  ScaffoldMessengerState createState() => _AppScaffoldMessengerState();
}

class _AppScaffoldMessengerState extends ScaffoldMessengerState {
  @override
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar(
    SnackBar snackBar, {
    AnimationStyle? snackBarAnimationStyle,
  }) {
    // SmartDialog chưa khởi tạo (test dựng app rút gọn) thì bỏ qua.
    SmartDialog.dismiss(status: SmartStatus.allToast).catchError((_) {});
    // Mọi SnackBar đều qua đây nên hàng đợi tối đa một cái: bỏ nó là sạch hàng đợi.
    removeCurrentSnackBar();
    return super.showSnackBar(
      snackBar,
      snackBarAnimationStyle: snackBarAnimationStyle,
    );
  }
}

/// Bọc widget toast (`toastBuilder` của SmartDialog) để báo [AppMessengerService.onToastShown].
class AppToastSlot extends StatefulWidget {
  const AppToastSlot({super.key, required this.child});

  final Widget child;

  @override
  State<AppToastSlot> createState() => _AppToastSlotState();
}

class _AppToastSlotState extends State<AppToastSlot> {
  @override
  void initState() {
    super.initState();
    AppMessengerService.onToastShown();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
