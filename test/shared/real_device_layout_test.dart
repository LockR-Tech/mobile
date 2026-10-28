import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/promotions/data/models/promotion_model.dart';
import 'package:smart_laundry_locker/features/promotions/presentation/pages/promotion_detail_page.dart';
import 'package:smart_laundry_locker/features/vouchers/data/models/voucher_model.dart';
import 'package:smart_laundry_locker/features/vouchers/presentation/pages/voucher_detail_page.dart';
import 'package:smart_laundry_locker/shared/widgets/adaptive_viewport.dart';

/// Font test mặc định vẽ mọi ký tự rộng 1em (gấp ~1.8 lần chữ thật) nên báo
/// tràn sai. Nạp đúng bộ Roboto app đóng gói (pubspec `fonts:`) để đo như máy.
Future<void> _loadAppFonts() async {
  final loader = FontLoader('Roboto');
  for (final weight in [
    'Thin', 'ExtraLight', 'Light', 'Regular', 'Medium', //
    'SemiBold', 'Bold', 'ExtraBold', 'Black',
  ]) {
    loader.addFont(rootBundle.load('assets/fonts/Roboto-$weight.ttf'));
  }
  await loader.load();
}

/// Dựng trang như trên OPPO A77s thật: 720×1612 px, dpr 2 (360×806 dp), cỡ chữ
/// hệ thống to (ColorOS) — mọi lỗi tràn bố cục sẽ làm test fail.
Future<void> pumpOnRealPhone(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(720, 1612);
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.textScaleFactorTestValue = 1.3;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => AdaptiveViewport(child: child!),
      home: page,
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));
}

const _longLocker =
    'Tủ khoá thông minh Ký túc xá khu B — Đại học FPT TP. Hồ Chí Minh';

void main() {
  setUpAll(_loadAppFonts);

  testWidgets('chi tiết khuyến mãi với dữ liệu dài không tràn', (tester) async {
    await pumpOnRealPhone(
      tester,
      PromotionDetailPage(
        promo: PromotionModel(
          id: 1,
          code: 'GIAMGIA-KTX-KHU-B-2026',
          name: 'Giảm 30% cho đơn gửi đồ giặt ủi tại tủ ký túc xá khu B '
              'trong tháng khai giảng',
          description: 'Áp dụng cho mọi kích cỡ ô tủ, mỗi tài khoản dùng một '
              'lần, không cộng dồn với ưu đãi khác.',
          discountType: 'PERCENTAGE',
          discountValue: 30,
          maxDiscountAmount: 1500000,
          minOrderAmount: 250000,
          status: 'ACTIVE',
          startAt: DateTime(2026, 9, 1),
          endAt: DateTime(2026, 12, 31, 23, 59),
          lockerId: 7,
          lockerCode: 'KTX-B-LOCKER-0007',
          lockerName: _longLocker,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('chi tiết voucher với dữ liệu dài không tràn', (tester) async {
    await pumpOnRealPhone(
      tester,
      VoucherDetailPage(
        voucher: VoucherModel(
          id: '12',
          code: 'GIAMGIA-KTX-KHU-B-2026',
          status: 'UNUSED',
          expiresAt: DateTime(2026, 12, 31),
          rewardValue: 1500000,
          campaignId: '1',
          campaignTitle: 'Ưu đãi khai giảng cho sinh viên ký túc xá khu B '
              'Đại học FPT',
          rewardType: 'DISCOUNT_FIXED',
          giftDescription: '',
          lockerId: 7,
          lockerCode: 'KTX-B-LOCKER-0007',
          lockerName: _longLocker,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
