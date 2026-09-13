import 'package:smart_laundry_locker/features/delegations/infrastructure/data_sources/delegation_remote_data_source.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:dio/dio.dart';

class DelegationRemoteDataSourceImpl implements DelegationRemoteDataSource {
  final ApiClient _apiClient;

  DelegationRemoteDataSourceImpl(this._apiClient);

  Map<String, dynamic> _extractData(Response<dynamic> response) {
    final responseData = response.data as Map<String, dynamic>;
    return responseData['data'] as Map<String, dynamic>? ?? responseData;
  }

  @override
  Future<Map<String, dynamic>> createDelegation(
    String orderId,
    String delegateeEmail,
  ) async {
    final response = await _apiClient.post<dynamic>(
      '/delegations',
      data: {
        'orderDetailId':
            orderId, // The doc says orderId in 'orderId' field or orderDetailId? Doc: { "orderId": "..." } wait! Let me check the doc.
        // Doc says request has "orderId"
        'orderId': orderId,
        'delegateeEmail': delegateeEmail,
      },
    );
    return _extractData(response);
  }

  @override
  Future<Map<String, dynamic>> getDelegationById(String id) async {
    final response = await _apiClient.get<dynamic>('/delegations/$id');
    return _extractData(response);
  }

  @override
  Future<Map<String, dynamic>> revokeDelegation(String id) async {
    final response = await _apiClient.delete<dynamic>('/delegations/$id');
    return _extractData(response);
  }

  @override
  Future<Map<String, dynamic>> getMyDelegations() async {
    final response = await _apiClient.get<dynamic>('/delegations/me/delegatee');
    return _extractData(response);
  }

  @override
  Future<Map<String, dynamic>> getDelegationsByPhone(String phoneNumber) async {
    final response = await _apiClient.get<dynamic>(
      '/delegations/phone/$phoneNumber',
    );
    return _extractData(response);
  }

  @override
  Future<Map<String, dynamic>> getDelegationByOrderId(String orderId) async {
    final response = await _apiClient.get<dynamic>(
      '/delegations/order/$orderId',
    );
    return _extractData(response);
  }

  @override
  Future<Map<String, dynamic>> findUserByPhone(String phoneNumber) async {
    final response = await _apiClient.get<dynamic>('/users/phone/$phoneNumber');
    return _extractData(response);
  }

  @override
  Future<Map<String, dynamic>> openLocker({required String accessCode}) async {
    final response = await _apiClient.post<dynamic>(
      '/delegations/open',
      data: {'accessCode': accessCode},
    );
    return _extractData(response);
  }
}
