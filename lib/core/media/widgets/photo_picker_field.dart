import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_laundry_locker/core/media/photo_picker_controller.dart';

const _defaultAccent = Color(0xFF1E5A8A);
const _mutedText = Color(0xFF64748B);

/// Huỷ [controller] khi widget bị gỡ khỏi cây — dùng cho controller tạo tạm
/// trong `showDialog` (dialog còn chạy hiệu ứng đóng sau khi future trả về).
class ControllerDisposer extends StatefulWidget {
  const ControllerDisposer({
    super.key,
    required this.controller,
    required this.child,
  });

  final ChangeNotifier controller;
  final Widget child;

  @override
  State<ControllerDisposer> createState() => _ControllerDisposerState();
}

class _ControllerDisposerState extends State<ControllerDisposer> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Hàng ảnh chờ gửi: thumbnail + nút xoá + tiến độ upload từng ảnh, kèm ô
/// "Thêm ảnh" (camera / thư viện). Trạng thái nằm trong [controller].
class PhotoPickerField extends StatelessWidget {
  const PhotoPickerField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.showAddTile = true,
    this.thumbSize = 72,
    this.accentColor = _defaultAccent,
    this.addLabel = 'Thêm ảnh',
    this.helperText,
  });

  final PhotoPickerController controller;
  final bool enabled;
  final bool showAddTile;
  final double thumbSize;
  final Color accentColor;
  final String addLabel;

  /// Dòng mô tả nhỏ phía dưới (vd. "Tối đa 5 ảnh").
  final String? helperText;

  /// Bottom sheet chọn nguồn ảnh rồi thêm vào [controller]; lỗi hiện SnackBar.
  static Future<void> pickWithSourceSheet(
    BuildContext context,
    PhotoPickerController controller, {
    Color accentColor = _defaultAccent,
  }) async {
    if (!controller.canAddMore) {
      _snack(context, 'Tối đa ${controller.maxPhotos} ảnh');
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt_outlined, color: accentColor),
              title: const Text('Chụp ảnh từ máy ảnh'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: accentColor),
              title: Text(
                controller.remaining > 1
                    ? 'Chọn ảnh từ thư viện (tối đa ${controller.remaining})'
                    : 'Chọn ảnh từ thư viện',
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      await controller.pick(source);
    } catch (e) {
      if (context.mounted) {
        _snack(
          context,
          source == ImageSource.camera
              ? 'Không mở được máy ảnh. Hãy cấp quyền camera trong cài đặt.'
              : 'Không mở được thư viện ảnh. Hãy cấp quyền ảnh trong cài đặt.',
        );
      }
    }
  }

  static void _snack(BuildContext context, String message) {
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final photos = controller.photos;
        final canAdd = enabled && showAddTile && controller.canAddMore;
        if (photos.isEmpty && !canAdd) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // SingleChildScrollView + Row (không dùng ListView) để đặt được
            // trong AlertDialog — dialog đo intrinsic width.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 8,
                children: [
                  for (var i = 0; i < photos.length; i++)
                    _PendingThumb(
                      photo: photos[i],
                      index: i,
                      size: thumbSize,
                      color: accentColor,
                      onRemove: enabled && !controller.isUploading
                          ? () => controller.remove(photos[i])
                          : null,
                    ),
                  if (canAdd)
                    _AddTile(
                      size: thumbSize,
                      color: accentColor,
                      label: addLabel,
                      onTap: () => pickWithSourceSheet(
                        context,
                        controller,
                        accentColor: accentColor,
                      ),
                    ),
                ],
              ),
            ),
            if (helperText != null) ...[
              const SizedBox(height: 4),
              Text(
                helperText!,
                style: const TextStyle(fontSize: 11, color: _mutedText),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({
    required this.size,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final double size;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingThumb extends StatelessWidget {
  const _PendingThumb({
    required this.photo,
    required this.index,
    required this.size,
    required this.color,
    this.onRemove,
  });

  final PendingPhoto photo;
  final int index;
  final double size;
  final Color color;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final status = photo.status;
    Widget image = kIsWeb
        ? Image.network(photo.file.path, fit: BoxFit.cover)
        : Image.file(
            File(photo.file.path),
            fit: BoxFit.cover,
            cacheWidth: (size * 3).round(),
          );
    image = SizedBox(width: size, height: size, child: image);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(10), child: image),
          if (status == PendingPhotoStatus.uploading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    value: photo.progress > 0 ? photo.progress : null,
                    strokeWidth: 3,
                    color: Colors.white,
                    backgroundColor: Colors.white24,
                  ),
                ),
              ),
            ),
          if (status == PendingPhotoStatus.failed)
            Positioned.fill(
              child: Tooltip(
                message: photo.error ?? 'Tải ảnh thất bại',
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFDC2626)),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          if (status == PendingPhotoStatus.uploaded)
            const Positioned(
              bottom: 3,
              right: 3,
              child: CircleAvatar(
                radius: 9,
                backgroundColor: Color(0xFF16A34A),
                child: Icon(Icons.check, size: 12, color: Colors.white),
              ),
            ),
          Positioned(
            bottom: 3,
            left: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Ảnh ${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (onRemove != null)
            Positioned(
              top: 2,
              right: 2,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 13, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
