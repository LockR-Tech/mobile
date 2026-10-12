import 'package:flutter/foundation.dart';

import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/receiver_order.dart';

/// "Đơn ủy quyền": đơn người khác ủy quyền cho tôi lấy hộ
/// (`GET /api/orders/delegated-to-me`). Ủy quyền đơn của mình làm trong chi tiết
/// đơn (`POST /api/orders/{id}/delegate`); lấy hàng bằng mã qua
/// `POST /api/iot/unlock-with-code`.
class DelegationProvider extends ChangeNotifier {
  DelegationProvider({LockerOpsService? service})
    : _service = service ?? LockerOpsService();

  final LockerOpsService _service;

  LockerOpsService get service => _service;

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) super.notifyListeners();
  }

  List<ReceiverOrder> _myDelegations = const [];

  /// Đơn được ủy quyền cho tôi (mới nhất trước theo server).
  List<ReceiverOrder> get myDelegations => _myDelegations;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> fetchMyDelegations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final raw = await _service.delegatedToMe();
      _myDelegations = ReceiverOrder.listFrom(raw);
    } catch (e) {
      _error = LockerOpsService.isEndpointUnavailable(e)
          ? 'Máy chủ chưa hỗ trợ mục Đơn ủy quyền. Vui lòng thử lại sau.'
          : LockerOpsService.errorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
