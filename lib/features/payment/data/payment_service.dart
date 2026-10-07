import 'dart:developer' as developer;
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/payment/data/user_bank_account.dart';

class PaymentService {
  final ApiClient _apiClient;

  PaymentService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Lấy thông tin STK ngân hàng đã lưu của khách hàng
  Future<UserBankAccount?> getSavedBankAccount() async {
    try {
      final response = await _apiClient.get<dynamic>('/api/payments/bank-account');
      final body = response.data;
      if (body is Map<String, dynamic>) {
        final data = body['data'];
        if (data != null && data is Map<String, dynamic>) {
          return UserBankAccount.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      developer.log('Error fetching saved bank account: $e', name: 'PaymentService');
      return null;
    }
  }

  /// Lưu / Cập nhật STK ngân hàng mặc định nhận hoàn tiền
  Future<UserBankAccount> saveBankAccount(UserBankAccount account) async {
    try {
      final response = await _apiClient.put<dynamic>(
        '/api/payments/bank-account',
        data: account.toJson(),
      );
      final body = response.data;
      if (body is Map<String, dynamic>) {
        final data = body['data'];
        if (data != null && data is Map<String, dynamic>) {
          return UserBankAccount.fromJson(data);
        }
      }
      return account;
    } catch (e) {
      developer.log('Error saving bank account: $e', name: 'PaymentService');
      rethrow;
    }
  }

  /// Gửi yêu cầu hoàn tiền (do tủ hỏng, sự cố máy, huỷ đơn...)
  Future<Map<String, dynamic>> requestRefund({
    required int orderId,
    required num amount,
    required String reason,
    String? bankName,
    String? bankCode,
    String? accountNumber,
    String? accountHolderName,
  }) async {
    try {
      final payload = <String, dynamic>{
        'orderId': orderId,
        'amount': amount,
        'reason': reason,
      };
      if (bankName != null) payload['bankName'] = bankName;
      if (bankCode != null) payload['bankCode'] = bankCode;
      if (accountNumber != null) payload['accountNumber'] = accountNumber;
      if (accountHolderName != null) payload['accountHolderName'] = accountHolderName;

      final response = await _apiClient.post<dynamic>(
        '/api/payments/refund-request',
        data: payload,
      );
      final body = response.data;
      if (body is Map<String, dynamic>) {
        return body['data'] as Map<String, dynamic>? ?? body;
      }
      return {};
    } catch (e) {
      developer.log('Error requesting refund: $e', name: 'PaymentService');
      rethrow;
    }
  }

  /// Lấy cấu hình quy tắc hoàn tiền từ Admin (ADR-0005 public settings - không hardcode)
  Future<Map<String, dynamic>> getRefundPublicSettings() async {
    try {
      final response = await _apiClient.get<dynamic>('/api/settings/payment/public');
      final body = response.data;
      if (body is Map<String, dynamic>) {
        return body['data'] as Map<String, dynamic>? ?? body;
      }
      return {};
    } catch (e) {
      developer.log('Error fetching refund public settings: $e', name: 'PaymentService');
      return {};
    }
  }
}
