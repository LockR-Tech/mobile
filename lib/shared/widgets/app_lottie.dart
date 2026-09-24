import 'package:flutter/widgets.dart';
import 'package:lottie/lottie.dart';

/// Đường dẫn tới bộ minh hoạ 3D dạng Lottie trong `assets/animations/`.
///
/// Tên file giữ nguyên theo tên gốc của bộ icon để dễ đối chiếu với nút
/// chức năng tương ứng ở trang chủ.
abstract final class AppLottieAssets {
  static const String _dir = 'assets/animations';

  /// Thùng hàng xếp chồng - thay cho `box_stack_3d.png`.
  static const String box = '$_dir/box.json';

  /// Máy bay + kiện hàng - thay cho `air_delivery_3d.png`.
  static const String airplaneBox = '$_dir/airplane_box.json';

  /// Icon nút "Cửa hàng".
  static const String cuaHang = '$_dir/cuahang.json';

  /// Icon nút "Thuê tủ".
  static const String thueTu = '$_dir/thuetu.json';

  /// Icon nút "Đơn tủ".
  static const String donTu = '$_dir/dontu.json';

  /// Icon nút "Ưu đãi".
  static const String uuDai = '$_dir/uudai.json';

  /// Icon nút "Báo sự cố".
  static const String baoSuCo = '$_dir/baosuco.json';

  /// Icon nút "Báo cáo".
  static const String baoCao = '$_dir/baocao.json';

  /// Icon nút "Nạp ví".
  static const String napVi = '$_dir/napvi.json';

  /// Minh hoạ "Đã thanh toán" (thành công).
  static const String daThanhToan = '$_dir/dathanhtoan.json';

  /// Minh hoạ "Thanh toán thất bại".
  static const String thatBaiThanhToan = '$_dir/thatbaithanhtoan.json';

  /// Hiệu ứng loading giao vận kiện hàng (Delivery-05).
  static const String deliveryLoading = '$_dir/delivery_animation.json';

  /// Minh hoạ mua sắm & giao vận nhanh ("10- Fast Shopping Delivery").
  static const String fastDelivery = '$_dir/fast_shopping_delivery.json';
}

/// Hiển thị một file Lottie trong `assets/animations/`.
///
/// Bộ icon hiện tại là ảnh 3D đóng gói dạng Lottie một khung hình, nên
/// [animate] mặc định `false`: vẽ đúng một khung và không chạy ticker, tránh
/// repaint liên tục. Đặt `animate: true` nếu sau này thay bằng file có
/// chuyển động thật.
///
/// [fallback] giữ lại hành vi `errorBuilder` của `Image.asset` trước đây để
/// UI không vỡ nếu thiếu asset.
class AppLottie extends StatelessWidget {
  const AppLottie(
    this.asset, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.animate = false,
    this.repeat,
    this.fallback,
  });

  final String asset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final bool animate;
  final bool? repeat;
  final WidgetBuilder? fallback;

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      asset,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      animate: animate,
      repeat: repeat,
      errorBuilder: (context, error, stackTrace) =>
          fallback?.call(context) ?? const SizedBox.shrink(),
    );
  }
}
