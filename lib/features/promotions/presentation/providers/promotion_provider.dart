import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:smart_laundry_locker/core/services/app_event_bus.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:smart_laundry_locker/features/locker/presentation/providers/locker_providers.dart';
import 'package:smart_laundry_locker/features/promotions/data/models/promotion_model.dart';
import 'package:smart_laundry_locker/features/promotions/data/repositories/promotion_repository.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

class PromotionProvider extends ChangeNotifier {
  final PromotionRepository _repository;

  List<PromotionModel> _promotions = [];
  bool _isLoading = false;
  String? _error;

  List<PromotionModel> get promotions => _promotions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  StreamSubscription<AppEvent>? _eventSub;
  bool _loadedOnce = false;
  bool _disposed = false;

  PromotionProvider(this._repository) {
    // Admin tạo/sửa/tắt/xoá khuyến mãi ⇒ trang chủ + trang Ưu đãi cập nhật
    // ngay (tải ngầm, giữ danh sách đang hiện).
    _eventSub = AppEventBus.instance.events.listen((event) {
      if (_loadedOnce && event is CatalogChangedEvent && event.isPromotion) {
        load(silent: true);
      }
    });
  }

  Future<void> load({bool silent = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    if (!silent) {
      _error = null;
      notifyListeners();
    }
    try {
      _promotions = await _repository.getActivePromotions();
      _loadedOnce = true;
      _error = null;
    } catch (e) {
      if (!silent) _error = L10n.current.promoLoadFailed;
      debugPrint('[PROMOTION] load error: $e');
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _eventSub?.cancel();
    super.dispose();
  }
}

final promotionNotifierProvider = ChangeNotifierProvider<PromotionProvider>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PromotionProvider(PromotionRepository(apiClient));
});
