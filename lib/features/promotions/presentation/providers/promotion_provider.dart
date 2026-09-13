import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:smart_laundry_locker/features/locker/presentation/providers/locker_providers.dart';
import 'package:smart_laundry_locker/features/promotions/data/models/promotion_model.dart';
import 'package:smart_laundry_locker/features/promotions/data/repositories/promotion_repository.dart';

class PromotionProvider extends ChangeNotifier {
  final PromotionRepository _repository;

  List<PromotionModel> _promotions = [];
  bool _isLoading = false;
  String? _error;

  List<PromotionModel> get promotions => _promotions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  PromotionProvider(this._repository);

  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _promotions = await _repository.getActivePromotions();
    } catch (e) {
      _error = 'Không tải được ưu đãi';
      debugPrint('[PROMOTION] load error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

final promotionNotifierProvider = ChangeNotifierProvider<PromotionProvider>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PromotionProvider(PromotionRepository(apiClient));
});
