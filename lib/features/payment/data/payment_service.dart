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
    String? customerAttachmentUrl,
    String? bankName,
    String? bankCode,
    String? accountNumber,
    String? accountHolderName,
    bool? saveAsDefault,
  }) async {
    try {
      final payload = <String, dynamic>{
        'orderId': orderId,
        'amount': amount,
        'reason': reason,
      };
      if (customerAttachmentUrl != null && customerAttachmentUrl.isNotEmpty) {
        payload['customerAttachmentUrl'] = customerAttachmentUrl;
      }
      if (bankName != null) payload['bankName'] = bankName;
      if (bankCode != null) payload['bankCode'] = bankCode;
      if (accountNumber != null) payload['accountNumber'] = accountNumber;
      if (accountHolderName != null) payload['accountHolderName'] = accountHolderName;
      if (saveAsDefault != null) payload['saveAsDefault'] = saveAsDefault;

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

  /// Lấy danh sách các yêu cầu hoàn tiền của tôi
  Future<List<Map<String, dynamic>>> myRefunds({List<int>? orderIds}) async {
    try {
      final response = await _apiClient.get<dynamic>('/api/payments/my-refunds');
      final body = response.data;
      List? rawList;
      if (body is Map<String, dynamic> && body['data'] is List) {
        rawList = body['data'] as List;
      } else if (body is List) {
        rawList = body;
      }
      if (rawList != null && rawList.isNotEmpty) {
        return rawList
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (e) {
      developer.log('API /my-refunds fallback: $e', name: 'PaymentService');
    }

    // Fallback qua /api/payments/order/{id}/refunds (có sẵn trên live backend)
    if (orderIds != null && orderIds.isNotEmpty) {
      final List<Map<String, dynamic>> allRefunds = [];
      await Future.wait(orderIds.take(25).map((oId) async {
        try {
          final res = await _apiClient.get<dynamic>('/api/payments/order/$oId/refunds');
          final b = res.data;
          List list = [];
          if (b is Map<String, dynamic> && b['data'] is List) {
            list = b['data'] as List;
          } else if (b is List) {
            list = b;
          }
          for (final item in list) {
            if (item is Map) {
              allRefunds.add(Map<String, dynamic>.from(item));
            }
          }
        } catch (_) {}
      }));
      allRefunds.sort((a, b) => ((b['id'] as num?) ?? 0).compareTo((a['id'] as num?) ?? 0));
      return allRefunds;
    }

    return [];
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
