import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Tiện ích quyền thông báo: kiểm tra/xin quyền và hướng dẫn người dùng bật lại
/// trong Settings khi đã từ chối (đặc biệt khi bị từ chối vĩnh viễn — lúc đó
/// gọi `request()` sẽ không hiện được hộp thoại hệ thống nữa).
///
/// Tách riêng khỏi UI: chỉ [showEnableGuide] cần `BuildContext`, phần còn lại
/// thuần logic quyền.
class NotificationPermissionHelper {
  const NotificationPermissionHelper._();

  /// Quyền thông báo hiện đã được cấp chưa.
  static Future<bool> isGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Đã bị từ chối vĩnh viễn (chỉ có thể bật lại qua Settings).
  static Future<bool> isPermanentlyDenied() {
    return Permission.notification.isPermanentlyDenied;
  }

  /// Xin quyền thông báo; trả `true` nếu được cấp.
  static Future<bool> request() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Mở trang cài đặt ứng dụng để người dùng tự bật quyền.
  static Future<bool> openSettings() => openAppSettings();

  /// Đảm bảo có quyền: nếu chưa, xin quyền; nếu bị từ chối vĩnh viễn thì hiện
  /// hộp thoại hướng dẫn mở Settings. Trả `true` nếu cuối cùng đã có quyền.
  static Future<bool> ensurePermission(BuildContext context) async {
    if (await isGranted()) return true;

    final granted = await request();
    if (granted) return true;

    if (await isPermanentlyDenied() && context.mounted) {
      await showEnableGuide(context);
    }
    return isGranted();
  }

  /// Hộp thoại hướng dẫn người dùng vào Settings bật lại thông báo.
  static Future<void> showEnableGuide(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bật thông báo'),
        content: const Text(
          'Bạn đã tắt quyền thông báo nên sẽ không nhận được cập nhật trạng '
          'thái giao hàng. Hãy vào Cài đặt để bật lại thông báo cho ứng dụng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Để sau'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              openSettings();
            },
            child: const Text('Mở Cài đặt'),
          ),
        ],
      ),
    );
  }
}
