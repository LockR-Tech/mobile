import 'package:dio/dio.dart';
import 'package:smart_laundry_locker/core/network/dio_client.dart';
import 'package:smart_laundry_locker/core/utils/app_date_time.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/drone_error_messages.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// Thông tin nhận hàng của một đơn mà tài khoản hiện tại là NGƯỜI NHẬN
/// (`ReceiverOrderResponse` của `GET /api/orders/incoming`).
class DronePickupInfo {
  const DronePickupInfo({
    required this.orderId,
    this.orderCode,
    this.lockerId,
    this.lockerName,
    this.lockerAddress,
    this.lockerLatitude,
    this.lockerLongitude,
    this.boxNumber,
    this.pickupDeadline,
    this.readyForPickup = false,
    this.pickupPin,
    this.delegated = false,
    this.delegateName,
    this.senderName,
  });

  factory DronePickupInfo.fromJson(Map<String, dynamic> json) {
    String? text(Object? v) {
      final t = v?.toString().trim() ?? '';
      return t.isEmpty ? null : t;
    }

    int? asInt(Object? v) => v is num ? v.toInt() : int.tryParse('$v');
    double? asDouble(Object? v) =>
        v is num ? v.toDouble() : double.tryParse('$v');

    return DronePickupInfo(
      orderId: asInt(json['id']) ?? 0,
      orderCode: text(json['orderCode']),
      lockerId: asInt(json['lockerId']),
      lockerName: text(json['lockerName']) ?? text(json['lockerCode']),
      lockerAddress: text(json['lockerAddress']),
      lockerLatitude: asDouble(json['lockerLatitude']),
      lockerLongitude: asDouble(json['lockerLongitude']),
      boxNumber: asInt(json['boxNumber']),
      pickupDeadline: parseServerDateTime(json['pickupDeadline']),
      readyForPickup: json['readyForPickup'] == true,
      pickupPin: text(json['pickupPin']),
      delegated: json['delegated'] == true,
      delegateName: text(json['delegateName']),
      senderName: text(json['senderName']),
    );
  }

  final int orderId;
  final String? orderCode;
  final int? lockerId;
  final String? lockerName;
  final String? lockerAddress;
  final double? lockerLatitude;
  final double? lockerLongitude;
  final int? boxNumber;
  final DateTime? pickupDeadline;
  final bool readyForPickup;

  /// Chỉ có khi đơn sẵn sàng lấy và chưa ủy quyền cho người khác.
  final String? pickupPin;

  /// Người nhận gốc đã ủy quyền lấy hộ ⇒ không còn PIN.
  final bool delegated;
  final String? delegateName;
  final String? senderName;

  bool get hasCoordinates {
    final lat = lockerLatitude;
    final lng = lockerLongitude;
    return lat != null && lng != null && lat.isFinite && lng.isFinite;
  }
}

class DronePickupException implements Exception {
  const DronePickupException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Tra mã nhận hàng cho người nhận đơn drone.
class DronePickupRemoteDataSource {
  DronePickupRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;

  /// Đơn [orderId] trong danh sách hàng chờ nhận của tôi; null khi không có
  /// (tôi không phải người nhận hoặc đơn đã xong).
  Future<DronePickupInfo?> findIncoming(int orderId) async {
    try {
      final res = await _dio.get<dynamic>(
        '/api/orders/incoming',
        queryParameters: const {'activeOnly': false, 'limit': 50},
      );
      final body = res.data;
      var data = body is Map ? body['data'] : null;
      if (data is Map && data['content'] is List) data = data['content'];
      if (data is! List) return null;
      for (final item in data.whereType<Map>()) {
        final info = DronePickupInfo.fromJson(Map<String, dynamic>.from(item));
        if (info.orderId == orderId) return info;
      }
      return null;
    } on DioException catch (error) {
      final data = error.response?.data;
      final hasCode = data is Map && data['code'] != null;
      if (error.response?.statusCode == 404 && !hasCode) {
        throw DronePickupException(
          L10n.current.dronePickupCodeNotSupported,
        );
      }
      throw DronePickupException(droneCustomerErrorMessage(error));
    }
  }
}
