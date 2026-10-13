import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smart_laundry_locker/features/locker_ops/domain/pickup_code_share.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// Mở bảng chia sẻ của máy với [text]; [origin] là vị trí nút (iPad cần để
/// neo popover).
typedef PickupShareTextLauncher = Future<void> Function(String text, Rect? origin);

/// Mở ứng dụng SMS theo link `sms:`; trả `false` khi máy không mở được.
typedef PickupSmsLauncher = Future<bool> Function(Uri uri);

/// Khối "Chia sẻ mã cho người nhận" đặt dưới mã PIN mà NGƯỜI GỬI đang xem.
///
/// Chỉ dùng ở màn của người gửi (kết quả gửi hàng, chi tiết "Đơn của tôi").
/// Màn của người nhận hoặc nhân viên không gắn khối này. Nơi gọi tự quyết định
/// có hiện hay không, thường qua [pickupCodeShareForOrder].
class PickupCodeShareActions extends StatelessWidget {
  const PickupCodeShareActions({
    super.key,
    required this.share,
    this.shareText,
    this.launchSms,
    this.smsSupported,
  });

  final PickupCodeShare share;

  /// Thay bảng chia sẻ thật (test). Mặc định dùng `share_plus`.
  final PickupShareTextLauncher? shareText;

  /// Thay việc mở ứng dụng SMS (test). Mặc định dùng `url_launcher`.
  final PickupSmsLauncher? launchSms;

  /// Có hiện nút "Nhắn SMS" không. Mặc định ẩn trên web: trình duyệt máy tính
  /// không có ứng dụng SMS để mở.
  final bool? smsSupported;

  static Future<void> _platformShare(String text, Rect? origin) async {
    // Không truyền `subject`: một số ứng dụng tin nhắn Android coi tiêu đề là
    // tin MMS.
    await SharePlus.instance.share(
      ShareParams(text: text, sharePositionOrigin: origin),
    );
  }

  static Future<bool> _platformSms(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _copyMessage(BuildContext context, {String? reason}) async {
    await Clipboard.setData(ClipboardData(text: share.message));
    if (!context.mounted) return;
    _snack(
      context,
      '${reason == null ? '' : '$reason — '}Đã sao chép tin nhắn, dán vào '
      'Zalo, Messenger hoặc SMS để gửi cho người nhận.',
    );
  }

  Future<void> _share(BuildContext buttonContext) async {
    final box = buttonContext.findRenderObject();
    final origin = box is RenderBox && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    try {
      await (shareText ?? _platformShare)(share.message, origin);
    } catch (error) {
      debugPrint('PickupCodeShareActions share failed: $error');
      if (!buttonContext.mounted) return;
      await _copyMessage(
        buttonContext,
        reason: 'Không mở được bảng chia sẻ',
      );
    }
  }

  Future<void> _sms(BuildContext context, Uri uri) async {
    var opened = false;
    try {
      opened = await (launchSms ?? _platformSms)(uri);
    } catch (error) {
      debugPrint('PickupCodeShareActions sms failed: $error');
    }
    if (opened || !context.mounted) return;
    await _copyMessage(context, reason: 'Không mở được ứng dụng tin nhắn');
  }

  @override
  Widget build(BuildContext context) {
    final iosStyle = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);
    final smsUri = (smsSupported ?? !kIsWeb)
        ? share.smsUri(iosStyle: iosStyle)
        : null;
    final receiverName = share.receiverName?.trim();
    final who = receiverName == null || receiverName.isEmpty
        ? 'người nhận'
        : receiverName;

    return Container(
      key: const ValueKey('pickup-code-share'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: opsPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: opsPrimary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.send, size: 16, color: opsPrimary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Gửi mã cho người nhận',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: opsDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Người nhận nhập mã tại màn hình tủ để mở ô. Gửi tin nhắn soạn sẵn '
            'cho $who qua Zalo, Messenger hoặc SMS.',
            style: const TextStyle(
              fontSize: 12.5,
              color: opsMutedText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (buttonContext) => OpsPrimaryButton(
              key: const ValueKey('pickup-code-share-button'),
              label: 'Chia sẻ mã cho người nhận',
              icon: LucideIcons.share2,
              color: opsPrimary,
              onPressed: () => _share(buttonContext),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (smsUri != null) ...[
                Expanded(
                  child: _ShareMiniAction(
                    key: const ValueKey('pickup-code-share-sms'),
                    icon: LucideIcons.messageSquareText,
                    label: 'Nhắn SMS',
                    onTap: () => _sms(context, smsUri),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: _ShareMiniAction(
                  key: const ValueKey('pickup-code-share-copy'),
                  icon: LucideIcons.copy,
                  label: 'Sao chép tin nhắn',
                  onTap: () => _copyMessage(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Nút phụ dạng nền nhạt, cùng kiểu với [OpsSheetAction] nhưng gọn để đặt hai
/// nút một hàng.
class _ShareMiniAction extends StatelessWidget {
  const _ShareMiniAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: opsPrimary.withValues(alpha: 0.22)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: opsPrimary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: opsPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
