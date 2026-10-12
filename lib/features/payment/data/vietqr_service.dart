import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Một app ngân hàng trong danh sách deeplink của VietQR
/// (`GET https://api.vietqr.io/v2/{android|ios}-app-deeplinks`).
class VietQrBankApp {
  const VietQrBankApp({
    required this.appId,
    required this.appName,
    this.appLogo,
    this.deeplink,
    this.autofill = false,
  });

  final String appId;
  final String appName;
  final String? appLogo;
  final String? deeplink;

  /// App tự điền STK, số tiền, nội dung từ link `dl.vietqr.io/pay`.
  final bool autofill;

  static VietQrBankApp? fromJson(Object? json) {
    if (json is! Map) return null;
    final appId = json['appId']?.toString().trim() ?? '';
    if (appId.isEmpty) return null;
    final name = json['appName']?.toString().trim();
    final autofill = json['autofill'];
    return VietQrBankApp(
      appId: appId,
      appName: name == null || name.isEmpty ? appId : name,
      appLogo: json['appLogo']?.toString(),
      deeplink: json['deeplink']?.toString(),
      autofill: autofill == 1 || autofill == true || autofill == '1',
    );
  }
}

/// Link mở app ngân hàng [appId] với tài khoản nhận, số tiền và nội dung đã
/// điền sẵn — khách chỉ cần xác nhận chuyển khoản.
///
/// `https://dl.vietqr.io/pay?app=<appId>&ba=<stk>@<mã ngân hàng>&am=<số tiền>&tn=<nội dung>`
String buildVietQrPayDeeplink({
  required String appId,
  required String accountNo,
  required String bankCode,
  required int amount,
  required String transferContent,
}) {
  String enc(String v) => Uri.encodeComponent(v.trim());
  return 'https://dl.vietqr.io/pay'
      '?app=${enc(appId)}'
      '&ba=${enc(accountNo)}@${enc(bankCode.toLowerCase())}'
      '&am=$amount'
      '&tn=${enc(transferContent)}';
}

/// Gọi API công khai của VietQR (danh sách app ngân hàng, bảng BIN → mã ngân
/// hàng). Dùng Dio riêng, KHÔNG gắn token đăng nhập của Lock.R. Kết quả được
/// nhớ trong phiên chạy app; lỗi thì không nhớ để lần sau thử lại.
class VietQrService {
  VietQrService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          );

  static final VietQrService instance = VietQrService();

  static const String _apiBase = 'https://api.vietqr.io/v2';

  final Dio _dio;
  final Map<String, List<VietQrBankApp>> _appsByPlatform = {};
  Map<String, String>? _binToCode;

  /// BIN NAPAS → mã ngân hàng VietQR (viết thường) của các ngân hàng phổ biến,
  /// dùng khi không gọi được `GET /v2/banks` (mạng lỗi, API đổi). Chỉ là mã
  /// ngân hàng — không chứa tài khoản nào.
  @visibleForTesting
  static const Map<String, String> fallbackBankCodes = {
    '970415': 'icb', // VietinBank
    '970436': 'vcb', // Vietcombank
    '970418': 'bidv', // BIDV
    '970405': 'vba', // Agribank
    '970422': 'mb', // MB Bank
    '970407': 'tcb', // Techcombank
    '970416': 'acb', // ACB
    '970432': 'vpb', // VPBank
    '970423': 'tpb', // TPBank
    '970403': 'stb', // Sacombank
    '970437': 'hdb', // HDBank
    '970441': 'vib', // VIB
    '970443': 'shb', // SHB
    '970448': 'ocb', // OCB
  };

  /// App ngân hàng hỗ trợ tự điền (`autofill == 1`), theo nền tảng.
  Future<List<VietQrBankApp>> bankApps({required bool ios}) async {
    final platform = ios ? 'ios' : 'android';
    final cached = _appsByPlatform[platform];
    if (cached != null) return cached;

    final response = await _dio.get<dynamic>('$_apiBase/$platform-app-deeplinks');
    final data = response.data;
    final Object? list = data is Map ? (data['apps'] ?? data['data']) : data;
    final apps = <VietQrBankApp>[
      if (list is List)
        for (final item in list)
          if (VietQrBankApp.fromJson(item) case final app? when app.autofill)
            app,
    ];
    if (apps.isNotEmpty) _appsByPlatform[platform] = apps;
    return apps;
  }

  /// Mã ngân hàng VietQR (viết thường, vd. `mb`) của [bin] để dựng link
  /// `dl.vietqr.io`. Tra `GET /v2/banks` (nhớ lại), lỗi hoặc không thấy thì
  /// dùng [fallbackBankCodes]; vẫn không có ⇒ `null`.
  Future<String?> bankCodeForBin(String bin) async {
    final key = bin.trim();
    var table = _binToCode;
    if (table == null) {
      try {
        table = await _loadBanks();
        if (table.isNotEmpty) _binToCode = table;
      } catch (e) {
        debugPrint('VietQR banks lookup failed: $e');
      }
    }
    return table?[key] ?? fallbackBankCodes[key];
  }

  Future<Map<String, String>> _loadBanks() async {
    final response = await _dio.get<dynamic>('$_apiBase/banks');
    final data = response.data;
    final Object? list = data is Map ? data['data'] : data;
    final table = <String, String>{};
    if (list is List) {
      for (final item in list) {
        if (item is! Map) continue;
        final bin = item['bin']?.toString().trim();
        final code = item['code']?.toString().trim();
        if (bin != null && bin.isNotEmpty && code != null && code.isNotEmpty) {
          table[bin] = code.toLowerCase();
        }
      }
    }
    return table;
  }
}
