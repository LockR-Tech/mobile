import 'package:smart_laundry_locker/features/subscription/domain/entities/plan_entity.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/subscription/infrastructure/data_sources/subscription_remote_data_source.dart';
import 'package:smart_laundry_locker/features/subscription/infrastructure/models/plan_model.dart';
import 'package:smart_laundry_locker/features/subscription/infrastructure/models/subscription_model.dart';

class SubscriptionRemoteDataSourceImpl implements SubscriptionRemoteDataSource {
  final ApiClient _apiClient;

  SubscriptionRemoteDataSourceImpl(this._apiClient);

  Map<String, dynamic> _extractMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    return <dynamic>[];
  }

  @override
  Future<List<PlanModel>> getPlans() async {
    final response = await _apiClient.get<dynamic>('/plans/customer');
    final root = response.data;

    List<dynamic> list = <dynamic>[];
    if (root is Map<String, dynamic>) {
      final data = root['data'];
      if (data is Map<String, dynamic>) {
        list = _extractList(data['plans'] ?? data['items'] ?? data['data']);
      } else if (data is List) {
        list = _extractList(data);
      } else {
        list = _extractList(root['plans'] ?? root['items'] ?? root['data']);
      }
    } else {
      list = _extractList(root);
    }

    return list
        .whereType<Map>()
        .map((e) => PlanModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<List<PricingEntity>> getPricings({String? orderType}) async {
    final response = await _apiClient.get<dynamic>(
      '/pricings',
      queryParameters: {if (orderType != null) 'orderType': orderType},
    );
    final root = response.data;

    List<dynamic> list = <dynamic>[];
    if (root is Map<String, dynamic>) {
      final data = root['data'];
      if (data is Map<String, dynamic>) {
        list = _extractList(data['items'] ?? data['data'] ?? data['pricings']);
      } else if (data is List) {
        list = _extractList(data);
      } else {
        list = _extractList(root['items'] ?? root['data'] ?? root['pricings']);
      }
    } else {
      list = _extractList(root);
    }

    return list
        .whereType<Map<String, dynamic>>()
        .map<PricingEntity>((e) => PricingModel.fromJson(e))
        .toList();
  }

  @override
  Future<PlanModel> getPlanDetail(String planId) async {
    final response = await _apiClient.get<dynamic>('/plans/customer/$planId');
    final root = response.data;
    final payload = root is Map<String, dynamic>
        ? _extractMap(root['data'] ?? root)
        : _extractMap(root);
    return PlanModel.fromJson(payload);
  }

  @override
  Future<SubscriptionModel> getActiveSubscription() async {
    final response = await _apiClient.get<dynamic>('/subscriptions/active');
    final root = response.data;
    final payload = root is Map<String, dynamic>
        ? _extractMap(root['data'] ?? root)
        : _extractMap(root);
    return SubscriptionModel.fromJson(payload);
  }

  @override
  Future<SubscriptionModel> purchaseSubscription({
    required String planId,
    int durationMonths = 1,
  }) async {
    final response = await _apiClient.post<dynamic>(
      '/subscriptions/purchase',
      data: <String, dynamic>{
        'planId': planId,
        'durationMonths': durationMonths,
      },
    );
    final root = response.data;
    final payload = root is Map<String, dynamic>
        ? _extractMap(root['data'] ?? root)
        : _extractMap(root);
    return SubscriptionModel.fromJson(payload);
  }
}
