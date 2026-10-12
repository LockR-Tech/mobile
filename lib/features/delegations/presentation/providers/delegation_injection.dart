import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/delegations/presentation/providers/delegation_provider.dart';

class DelegationInjection {
  /// [apiClient] giữ lại cho nơi gọi hiện có; dữ liệu ủy quyền đi qua
  /// `LockerOpsService` (các endpoint `/api/orders/*`, `/api/iot/*`).
  static DelegationProvider provideDelegationProvider([ApiClient? apiClient]) =>
      DelegationProvider();
}
