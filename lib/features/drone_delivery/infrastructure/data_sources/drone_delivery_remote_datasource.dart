import 'package:smart_laundry_locker/core/config/feature_flags.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/drone_delivery/infrastructure/models/drone_delivery_response.dart';

abstract class DroneDeliveryRemoteDataSource {
  Future<DroneDeliveryResponse> getDeliveryStatus(String orderId);
}

class DroneDeliveryRemoteDataSourceImpl implements DroneDeliveryRemoteDataSource {
  final ApiClient _apiClient;

  DroneDeliveryRemoteDataSourceImpl({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  @override
  Future<DroneDeliveryResponse> getDeliveryStatus(String orderId) async {
    // Backend chưa chắc đã có endpoint này (Phase 1 = push-only). Khi cờ tắt →
    // trả mock để UI timeline vẫn chạy được, KHÔNG gọi endpoint chết (tránh 404
    // làm bẩn log). Khi backend sẵn sàng chỉ cần bật cờ droneDeliveryEnabled.
    if (!FeatureFlags.droneDeliveryEnabled) {
      return _mock(orderId);
    }

    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/orders/$orderId/drone-delivery',
    );

    final rawData = response.data as Map<String, dynamic>;
    final innerData = rawData['data'] as Map<String, dynamic>? ?? rawData;

    return DroneDeliveryResponse.fromJson(innerData);
  }

  DroneDeliveryResponse _mock(String orderId) => DroneDeliveryResponse(
    status: 'dispatched',
    orderId: orderId,
    orderCode: orderId,
    droneCode: 'DRONE-MOCK',
    etaMinutes: 10,
    updatedAt: DateTime.now().toUtc().toIso8601String(),
  );
}
