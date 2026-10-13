/// Thông tin chuyển khoản của MỘT giao dịch SePay (VietQR), đọc từ response
/// `POST /api/payments/checkout {orderId, method: 'SEPAY'}`.
///
/// Nguồn theo thứ tự ưu tiên:
/// 1. `bankTransfer {bankBin, accountNo, accountName, amount, transferContent}`
///    (backend PR #65);
/// 2. tham số của ảnh `qrCodeUrl` (`img.vietqr.io/image/{bin}-{stk}-{mẫu}.jpg
///    ?amount=&addInfo=&accountName=`) khi backend cũ chưa trả `bankTransfer`;
/// 3. `amount` / `content` của chính payment.
///
/// KHÔNG bao giờ dùng tài khoản ngân hàng viết sẵn trong app.
library;

/// URL ảnh VietQR trong response checkout SePay (`qrCodeUrl`, bản cũ `qr`).
/// `null` khi server không trả — KHÔNG tự dựng mã từ tài khoản viết sẵn trong app.
String? checkoutQrUrl(Map<String, dynamic> checkout) {
  for (final key in const ['qrCodeUrl', 'qr']) {
    final value = checkout[key]?.toString().trim();
    if (value != null &&
        (value.startsWith('https://') || value.startsWith('http://'))) {
      return value;
    }
  }
  return null;
}

class SepayTransfer {
  const SepayTransfer({
    this.qrImageUrl,
    this.bankBin,
    this.accountNo,
    this.accountName,
    this.amount,
    this.transferContent,
  });

  /// Ảnh mã VietQR do server sinh cho đúng giao dịch này.
  final String? qrImageUrl;

  /// Mã BIN NAPAS 6 số của ngân hàng nhận (vd. `970422`).
  final String? bankBin;
  final String? accountNo;
  final String? accountName;

  /// Số tiền cần chuyển (VND).
  final int? amount;

  /// Nội dung chuyển khoản — SePay dựa vào đây để khớp giao dịch với đơn.
  final String? transferContent;

  /// Có gì để khách chuyển khoản: ảnh QR, hoặc đủ ngân hàng + số tài khoản.
  bool get isUsable =>
      qrImageUrl != null || (bankBin != null && accountNo != null);

  /// Đủ dữ liệu để mở app ngân hàng điền sẵn STK, số tiền, nội dung.
  bool get canOpenBankApp =>
      bankBin != null &&
      accountNo != null &&
      (amount ?? 0) > 0 &&
      transferContent != null;

  factory SepayTransfer.fromCheckout(
    Map<String, dynamic> checkout, {
    num? fallbackAmount,
    int? orderId,
    String? orderCode,
  }) {
    final raw = checkout['bankTransfer'];
    final bank = raw is Map ? raw : const {};
    var qrUrl = checkoutQrUrl(checkout);
    final qr = _VietQrImageInfo.parse(qrUrl);

    final resolvedOrderId = orderId ??
        (checkout['orderId'] is num ? (checkout['orderId'] as num).toInt() : null);
    final resolvedOrderCode = _text(orderCode) ??
        _text(checkout['orderCode']);

    var content = _text(bank['transferContent']) ??
        qr?.addInfo ??
        _text(checkout['content']);

    // Đảm bảo nội dung chuyển khoản cho đơn hàng chứa cả orderId và mã đơn (nếu có)
    if (resolvedOrderId != null && resolvedOrderId > 0) {
      if (content != null && content.toUpperCase().startsWith('PAY-$resolvedOrderId-ORD')) {
        // Đã có dạng chuẩn PAY-{orderId}-{orderCode} từ server, giữ nguyên
      } else if (content != null && content.toUpperCase().startsWith('PAY')) {
        if (resolvedOrderCode != null && resolvedOrderCode.isNotEmpty) {
          content = 'PAY-$resolvedOrderId-$resolvedOrderCode';
        } else {
          content = 'PAY-$resolvedOrderId';
        }
      } else if (content == null || content.isEmpty) {
        if (resolvedOrderCode != null && resolvedOrderCode.isNotEmpty) {
          content = 'PAY-$resolvedOrderId-$resolvedOrderCode';
        } else {
          content = 'PAY-$resolvedOrderId';
        }
      }
      // Nếu content là nội dung tùy biến / test mock khác không bắt đầu bằng PAY (ví dụ 'LKR81', 'CU'), giữ nguyên
    } else if (content != null) {
      final payMatch = RegExp(r'^PAY[-_\s]?(\d+)(?:[-_]\d+)?$', caseSensitive: false).firstMatch(content);
      if (payMatch != null) {
        content = 'PAY-${payMatch.group(1)}';
      }
    }

    // Nếu qrUrl chứa addInfo cũ (ví dụ PAY-83 hoặc PAY-83-1791877232939), cập nhật lại addInfo cho đúng content
    if (qrUrl != null && content != null && content.toUpperCase().startsWith('PAY-') && qrUrl.contains('addInfo=')) {
      final payQrParamRegex = RegExp(r'addInfo=PAY[-_\s]?\d+(?:[-_]\d+)?(?=&|$)', caseSensitive: false);
      if (payQrParamRegex.hasMatch(qrUrl)) {
        qrUrl = qrUrl.replaceAll(payQrParamRegex, 'addInfo=${Uri.encodeComponent(content)}');
      }
    }

    return SepayTransfer(
      qrImageUrl: qrUrl,
      bankBin: _text(bank['bankBin']) ?? qr?.bankBin,
      accountNo: _text(bank['accountNo']) ?? qr?.accountNo,
      accountName: _text(bank['accountName']) ?? qr?.accountName,
      amount:
          _money(bank['amount']) ??
          qr?.amount ??
          _money(checkout['amount']) ??
          _money(fallbackAmount),
      transferContent: content,
    );
  }

  static String? _text(Object? value) {
    final s = value?.toString().trim();
    return s == null || s.isEmpty || s == 'null' ? null : s;
  }

  static int? _money(Object? value) {
    if (value == null) return null;
    final n = value is num ? value : num.tryParse(value.toString().trim());
    if (n == null || n <= 0) return null;
    return n.round();
  }
}

/// Phần đọc được từ URL ảnh img.vietqr.io do backend sinh.
class _VietQrImageInfo {
  const _VietQrImageInfo({
    this.bankBin,
    this.accountNo,
    this.amount,
    this.addInfo,
    this.accountName,
  });

  final String? bankBin;
  final String? accountNo;
  final int? amount;
  final String? addInfo;
  final String? accountName;

  static _VietQrImageInfo? parse(String? url) {
    if (url == null) return null;
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.host.endsWith('vietqr.io')) return null;

    String? bin;
    String? account;
    if (uri.pathSegments.isNotEmpty) {
      // `970422-0123456789-compact2.jpg` → BIN, STK, mẫu ảnh.
      var name = uri.pathSegments.last;
      final dot = name.lastIndexOf('.');
      if (dot > 0) name = name.substring(0, dot);
      final parts = name.split('-');
      if (parts.length >= 2 && RegExp(r'^\d{6}$').hasMatch(parts[0])) {
        bin = parts[0];
        account = parts[1].isEmpty ? null : parts[1];
      }
    }
    final q = uri.queryParameters;
    return _VietQrImageInfo(
      bankBin: bin,
      accountNo: account,
      amount: SepayTransfer._money(q['amount']),
      addInfo: SepayTransfer._text(q['addInfo']),
      accountName: SepayTransfer._text(q['accountName']),
    );
  }
}
