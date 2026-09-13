import 'package:smart_laundry_locker/core/network/api_client.dart';
import '../models/promotion_model.dart';

class PromotionRepository {
  final ApiClient _apiClient;

  PromotionRepository(this._apiClient);

  Future<List<PromotionModel>> getActivePromotions() async {
    final response = await _apiClient.get('/api/promotions/active');
    final raw = response.data;
    final List<dynamic> items;
    if (raw is List) {
      items = raw;
    } else if (raw is Map) {
      final inner = raw['data'] ?? raw['items'] ?? raw['content'];
      items = inner is List ? inner : [];
    } else {
      items = [];
    }
    return items
        .whereType<Map<String, dynamic>>()
        .map(PromotionModel.fromJson)
        .toList();
  }
}
