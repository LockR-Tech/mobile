import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:smart_laundry_locker/core/network/dio_client.dart';

import 'models/assistant_models.dart';

/// Client của trợ lý hỏi đáp (assistant-service qua gateway, cần JWT — đã
/// được [DioClient]/AuthInterceptor gắn sẵn). Mọi lỗi được đổi thành
/// [AssistantException] mang `code` và thông báo tiếng Việt.
class AssistantService {
  AssistantService({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;

  /// Truy xuất tài liệu + gọi mô hình có thể mất vài chục giây: riêng
  /// request hỏi được chờ lâu hơn mặc định 30 s của [DioClient]. Server chờ
  /// Claude tối đa 55 s × 2 lần (một lần thử lại) nên app chờ 120 s.
  static const Duration askReceiveTimeout = Duration(seconds: 120);

  /// Giới hạn độ dài câu hỏi của backend (`@Size(max = 2000)`).
  static const int maxQuestionLength = 2000;

  static const _base = '/api/assistant';

  Future<AssistantStatus> status() => _guard(() async {
    final res = await _dio.get<dynamic>('$_base/status');
    return AssistantStatus.fromJson(_dataMap(res));
  });

  /// Hỏi một câu. [conversationId] null ⇒ backend mở hội thoại mới và trả
  /// `conversationId` để hỏi tiếp trong cùng hội thoại.
  Future<AssistantAnswer> ask(String question, {int? conversationId}) =>
      _guard(() async {
        final text = question.trim();
        if (text.isEmpty || text.length > maxQuestionLength) {
          throw const AssistantException(
            'Câu hỏi cần từ 1 đến $maxQuestionLength ký tự.',
            code: 'VALIDATION_ERROR',
          );
        }
        final res = await _dio.post<dynamic>(
          '$_base/ask',
          data: {
            if (conversationId != null) 'conversationId': conversationId,
            'question': text,
          },
          options: Options(receiveTimeout: askReceiveTimeout),
        );
        return AssistantAnswer.fromJson(_dataMap(res));
      });

  /// Hội thoại của tôi, mới nhất trước.
  Future<List<AssistantConversation>> conversations() => _guard(() async {
    final res = await _dio.get<dynamic>('$_base/conversations');
    final body = res.data;
    final data = body is Map ? body['data'] : null;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map(
          (c) => AssistantConversation.fromJson(Map<String, dynamic>.from(c)),
        )
        .toList(growable: false);
  });

  Future<AssistantConversationDetail> conversation(int id) => _guard(() async {
    final res = await _dio.get<dynamic>('$_base/conversations/$id');
    return AssistantConversationDetail.fromJson(_dataMap(res));
  });

  Future<void> deleteConversation(int id) => _guard(() async {
    await _dio.delete<dynamic>('$_base/conversations/$id');
  });

  static Map<String, dynamic> _dataMap(Response<dynamic> res) {
    final body = res.data;
    if (body is Map && body['success'] == false) {
      throw AssistantException.fromBody(body, res.statusCode);
    }
    final data = body is Map ? body['data'] : null;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const AssistantException(
      'Phản hồi từ máy chủ không hợp lệ.',
      code: 'BAD_RESPONSE',
    );
  }

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on AssistantException {
      rethrow;
    } on DioException catch (e) {
      throw AssistantException.fromDio(e);
    } catch (_) {
      throw const AssistantException(
        'Đã xảy ra lỗi, vui lòng thử lại.',
        code: 'UNKNOWN',
      );
    }
  }
}

/// Lỗi của trợ lý: [code] theo `ApiResponse.code` của backend
/// (`ASSISTANT_RATE_LIMITED`, `ASSISTANT_DISABLED`, `ASSISTANT_NOT_CONFIGURED`,
/// `ASSISTANT_UNAVAILABLE`, `NOT_FOUND`…) hoặc mã phía app (`TIMEOUT`,
/// `NETWORK`…); [message] luôn là câu tiếng Việt hiển thị được.
class AssistantException implements Exception {
  const AssistantException(this.message, {this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;

  bool get isRateLimited =>
      code == 'ASSISTANT_RATE_LIMITED' || statusCode == 429;

  bool get isNotFound => code == 'NOT_FOUND' || statusCode == 404;

  /// Mã chung của backend có thông báo tiếng Anh ⇒ thay bằng câu tiếng Việt.
  static const _genericMessages = {
    'NOT_FOUND': 'Không tìm thấy cuộc hội thoại này, có thể nó đã bị xoá.',
    'VALIDATION_ERROR': 'Câu hỏi cần từ 1 đến 2000 ký tự.',
    'INTERNAL_ERROR': 'Máy chủ gặp lỗi, vui lòng thử lại sau.',
  };

  factory AssistantException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
        return const AssistantException(
          'Kết nối tới máy chủ quá lâu, vui lòng thử lại.',
          code: 'TIMEOUT',
        );
      case DioExceptionType.receiveTimeout:
        return const AssistantException(
          'Trợ lý phản hồi quá lâu, vui lòng thử lại.',
          code: 'TIMEOUT',
        );
      case DioExceptionType.connectionError:
        return const AssistantException(
          'Không thể kết nối máy chủ. Kiểm tra kết nối mạng.',
          code: 'NETWORK',
        );
      case DioExceptionType.cancel:
        return const AssistantException('Đã huỷ yêu cầu.', code: 'CANCELLED');
      default:
        break;
    }
    var body = e.response?.data;
    if (body is String) {
      try {
        body = jsonDecode(body);
      } catch (_) {}
    }
    return AssistantException.fromBody(body, e.response?.statusCode);
  }

  /// Từ thân lỗi `ApiResponse{success, code, message, …}`. Thân không theo
  /// chuẩn (vd. gateway trả 503 khi service chưa chạy) ⇒ thông báo theo mã HTTP.
  factory AssistantException.fromBody(dynamic body, int? statusCode) {
    final code = body is Map ? body['code']?.toString() : null;
    final raw = body is Map ? body['message'] : null;
    final serverMessage = code != null && raw is String && raw.trim().isNotEmpty
        ? raw.trim()
        : null;
    return AssistantException(
      _genericMessages[code] ?? serverMessage ?? _statusMessage(statusCode),
      code: code,
      statusCode: statusCode,
    );
  }

  static String _statusMessage(int? status) {
    switch (status) {
      case 401:
        return 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
      case 403:
        return 'Bạn không có quyền dùng trợ lý hỏi đáp.';
      case 404:
        return _genericMessages['NOT_FOUND']!;
      case 429:
        return 'Bạn đã hỏi quá nhiều câu, vui lòng thử lại sau.';
      case 502:
      case 503:
      case 504:
        return 'Trợ lý đang bận hoặc gặp sự cố, vui lòng thử lại sau.';
      default:
        return status != null && status >= 500
            ? 'Máy chủ gặp lỗi, vui lòng thử lại sau.'
            : 'Đã xảy ra lỗi, vui lòng thử lại.';
    }
  }

  @override
  String toString() => message;
}
