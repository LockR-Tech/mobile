import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'business_config.dart';
import 'business_config_service.dart';

export 'business_config.dart';
export 'business_config_service.dart';

/// Service cấu hình nghiệp vụ dùng chung (override được trong test).
final businessConfigServiceProvider = Provider<BusinessConfigService>(
  (ref) => BusinessConfigService.instance,
);

/// Cấu hình nghiệp vụ hiện tại cho widget Riverpod (`ref.watch`).
/// Tự cập nhật khi service tải được giá trị mới.
final businessConfigProvider =
    NotifierProvider<BusinessConfigNotifier, BusinessConfig>(
      BusinessConfigNotifier.new,
    );

class BusinessConfigNotifier extends Notifier<BusinessConfig> {
  @override
  BusinessConfig build() {
    final service = ref.watch(businessConfigServiceProvider);
    void listener() => state = service.current;
    service.listenable.addListener(listener);
    ref.onDispose(() => service.listenable.removeListener(listener));
    return service.current;
  }

  /// Làm mới từ server (trong TTL thì không gọi mạng, trừ khi [force]).
  Future<void> refresh({bool force = false}) =>
      ref.read(businessConfigServiceProvider).refresh(force: force);
}

/// Mixin cho `State` (các màn hình locker_ops/transactions dùng StatefulWidget):
/// đọc [businessConfig], tự `setState` khi cấu hình đổi và làm mới khi mở màn.
mixin BusinessConfigStateMixin<T extends StatefulWidget> on State<T> {
  BusinessConfigService get businessConfigService =>
      BusinessConfigService.instance;

  late BusinessConfigService _subscribedService;

  /// Cấu hình hiện tại.
  BusinessConfig get businessConfig => _subscribedService.current;

  /// Gọi sau khi cấu hình đổi (trước `setState`) — ghi đè để đồng bộ state
  /// phụ thuộc (vd. số giờ mặc định khi người dùng chưa chọn).
  @protected
  void onBusinessConfigChanged(BusinessConfig config) {}

  @override
  void initState() {
    super.initState();
    _subscribedService = businessConfigService;
    _subscribedService.listenable.addListener(_handleBusinessConfigChanged);
    _subscribedService.refresh();
  }

  @override
  void dispose() {
    _subscribedService.listenable.removeListener(_handleBusinessConfigChanged);
    super.dispose();
  }

  void _handleBusinessConfigChanged() {
    if (!mounted) return;
    final config = _subscribedService.current;
    setState(() => onBusinessConfigChanged(config));
  }
}
