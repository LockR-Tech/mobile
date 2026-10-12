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
    // Cờ tắt ⇒ báo rõ, không dựng trạng thái giả.
    if (!FeatureFlags.droneDeliveryEnabled) {
      throw ServerException('Tính năng theo dõi giao drone đang tạm tắt.');
    }

    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/orders/$orderId/drone-delivery',
    );

    final rawData = response.data as Map<String, dynamic>;
    final innerData = rawData['data'] as Map<String, dynamic>? ?? rawData;

    return DroneDeliveryResponse.fromJson(innerData);
  }
}
