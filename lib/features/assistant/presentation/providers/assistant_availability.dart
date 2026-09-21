import 'package:flutter/foundation.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';

import '../../data/assistant_service.dart';
import '../../data/models/assistant_models.dart';

/// Trạng thái bật/tắt của trợ lý, dùng chung cho các lối vào (Hồ sơ → Trợ giúp,
/// trang chủ kỹ thuật viên). `value == null` khi chưa biết — chưa đăng nhập,
/// service chưa deploy hoặc mất mạng — và lối vào coi như đang tắt.
class AssistantAvailability extends ValueNotifier<AssistantStatus?> {
  AssistantAvailability({
    AssistantService Function()? serviceFactory,
    bool Function()? isSignedIn,
    this.maxAge = const Duration(minutes: 5),
  }) : _serviceFactory = serviceFactory ?? AssistantService.new,
       _isSignedIn = isSignedIn ?? (() => TokenService.authState.value),
       super(null);

  /// Bản dùng chung của app; test có thể thay bằng bản giả.
  static AssistantAvailability instance = AssistantAvailability();

  final Duration maxAge;
  final AssistantService Function() _serviceFactory;
  final bool Function() _isSignedIn;
  AssistantService? _service;
  DateTime? _checkedAt;
  Future<AssistantStatus?>? _inFlight;

  bool get enabled => value?.enabled == true;

  /// Hỏi lại `GET /api/assistant/status` (dùng kết quả cũ nếu còn mới hơn
  /// [maxAge], trừ khi [force]). Không bao giờ ném lỗi.
  Future<AssistantStatus?> refresh({bool force = false}) {
    // Endpoint cần JWT: gọi khi chưa đăng nhập sẽ bị 401 ⇒ AuthInterceptor
    // đăng xuất người dùng. Chưa đăng nhập thì không hỏi.
    if (!_isSignedIn()) return Future.value(value);
    final checkedAt = _checkedAt;
    final fresh =
        checkedAt != null && DateTime.now().difference(checkedAt) < maxAge;
    if (fresh && !force) return Future.value(value);
    return _inFlight ??= _fetch().whenComplete(() => _inFlight = null);
  }

  Future<AssistantStatus?> _fetch() async {
    try {
      final status = await (_service ??= _serviceFactory()).status();
      value = status;
      _checkedAt = DateTime.now();
    } catch (_) {
      // Giữ giá trị cũ; lần sau hỏi lại.
    }
    return value;
  }
}
