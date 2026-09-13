import 'package:smart_laundry_locker/core/config/env_config.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/transactions/infrastructure/data_sources/top_up_remote_data_source.dart';
import 'package:smart_laundry_locker/features/transactions/infrastructure/models/top_up_request_dto.dart';
import 'package:smart_laundry_locker/features/transactions/infrastructure/models/top_up_response_dto.dart';
import 'package:flutter/foundation.dart';

class TopUpRemoteDataSourceImpl implements TopUpRemoteDataSource {
  final ApiClient _apiClient;
  static const String _path = '/api/payments/topup/create';

  TopUpRemoteDataSourceImpl(this._apiClient);

  @override
  Future<TopUpResponseDto> createTopUpUrl({required int amount}) async {
    // Ghi chú: Domain này bắt buộc PHẢI được whitelist (cấu hình) trong giao diện VNPay Sandbox Merchant.
    // Thông thường VNPay Sandbox sẽ cho phép 'http://localhost' đi qua mà không báo lỗi "Chưa phê duyệt".
    // Tránh sử dụng Uri.base.origin vì cổng (port) của Flutter Web thay đổi liên tục sẽ bị VNPay chặn.
    final returnUrl = '${EnvConfig.apiBaseUrl}/payments/vnpay/callback';

    final dto = TopUpRequestDto(amount: amount, returnUrl: returnUrl);
    debugPrint('[TOPUP][ds] POST $_path payload=${dto.toJson()}');

    final response = await _apiClient.post<dynamic>(_path, data: dto.toJson());
    final data = response.data;
    debugPrint('[TOPUP][ds] rawResponseType=${data.runtimeType}');

    if (data is Map<String, dynamic>) {
      final inner = (data['data'] is Map<String, dynamic>)
          ? (data['data'] as Map<String, dynamic>)
          : data;
      debugPrint('[TOPUP][ds] parsed keys=${inner.keys.toList()}');
      return TopUpResponseDto.fromJson(inner);
    }
    return const TopUpResponseDto(paymentUrl: '', txnRef: '');
  }
}
