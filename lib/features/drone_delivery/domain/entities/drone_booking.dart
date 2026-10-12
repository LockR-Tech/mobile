/// Đặt giao hàng bằng drone, lấy hàng tận nhà — khớp
/// `CreateDroneDeliveryOrderRequest` và `DroneDeliveryQuoteResponse` của order-service.
library;

import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_parcel.dart';

/// Điểm KTV drone tới lấy kiện: vị trí hiện tại của người gửi hoặc điểm họ ghim/tìm
/// trên bản đồ, kèm địa chỉ đọc được.
class PickupLocation {
  const PickupLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  final double latitude;
  final double longitude;
  final String address;

  PickupLocation copyWith({String? address}) => PickupLocation(
    latitude: latitude,
    longitude: longitude,
    address: address ?? this.address,
  );
}

/// Tên, số điện thoại và email — bắt buộc cho cả người gửi lẫn người nhận: thư báo
/// đơn đã phóng, mã mở ô và thư "giao không hoàn tất" đều đi qua email.
class DroneContact {
  const DroneContact({
    required this.name,
    required this.phone,
    required this.email,
  });

  final String name;
  final String phone;
  final String email;
}

class DroneBookingRequest {
  const DroneBookingRequest({
    required this.destinationLockerId,
    this.preferredBoxId,
    required this.pickup,
    this.pickupNote,
    required this.sender,
    required this.receiver,
    required this.parcelWeightGrams,
    this.description,
    required this.parcel,
  });

  final int destinationLockerId;

  /// Ô DRONE khách đã chạm ở tủ nhận; null thì hệ thống tự giữ một ô trống.
  final int? preferredBoxId;
  final PickupLocation pickup;

  /// Chỉ dẫn cho KTV (tầng, cổng, giờ có nhà…).
  final String? pickupNote;
  final DroneContact sender;
  final DroneContact receiver;
  final int parcelWeightGrams;
  final String? description;
  final DroneParcelDeclaration parcel;

  Map<String, dynamic> toJson() => {
    'destinationLockerId': destinationLockerId,
    if (preferredBoxId != null) 'preferredBoxId': preferredBoxId,
    'pickupAddress': pickup.address,
    'pickupLatitude': pickup.latitude,
    'pickupLongitude': pickup.longitude,
    if (pickupNote != null) 'pickupNote': pickupNote,
    'senderName': sender.name,
    'senderPhone': sender.phone,
    'senderEmail': sender.email,
    'receiverName': receiver.name,
    'receiverPhone': receiver.phone,
    'receiverEmail': receiver.email,
    'parcelWeightGrams': parcelWeightGrams,
    if (description != null) 'description': description,
    ...parcel.toJson(),
  };
}

/// Báo trước cho người gửi: drone cất cánh ở tủ nào, bao xa, phí bao nhiêu.
class DroneQuote {
  const DroneQuote({
    required this.sourceLockerName,
    this.sourceLockerAddress,
    required this.pickupDistanceMeters,
    required this.routeDistanceMeters,
    required this.fee,
  });

  final String sourceLockerName;
  final String? sourceLockerAddress;

  /// Điểm lấy hàng → tủ gửi.
  final int pickupDistanceMeters;

  /// Tủ gửi → tủ nhận.
  final int routeDistanceMeters;
  final double fee;

  static DroneQuote fromJson(Map<String, dynamic> json) {
    final source = json['sourceLocker'];
    final map = source is Map ? source : const {};
    final name = '${map['name'] ?? map['code'] ?? ''}'.trim();
    final address = '${map['address'] ?? ''}'.trim();
    return DroneQuote(
      sourceLockerName: name.isEmpty ? 'Tủ #${map['lockerId'] ?? '?'}' : name,
      sourceLockerAddress: address.isEmpty ? null : address,
      pickupDistanceMeters: _int(json['pickupDistanceMeters']),
      routeDistanceMeters: _int(json['routeDistanceMeters']),
      fee: json['fee'] is num
          ? (json['fee'] as num).toDouble()
          : double.tryParse('${json['fee']}') ?? 0,
    );
  }

  static int _int(dynamic value) =>
      value is num ? value.round() : int.tryParse('$value') ?? 0;
}

/// `850 m`, `2,4 km`.
String droneDistanceLabel(int? meters) {
  if (meters == null) return '—';
  if (meters < 1000) return '$meters m';
  return '${(meters / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
}

/// Mã lý do của backend (`DroneFailureReasons`) → nhãn tiếng Việt; mã lạ trả nguyên văn.
String droneFailureReasonLabel(String? code) =>
    switch ((code ?? '').toUpperCase()) {
      '' => '—',
      'WEATHER' => 'Tạm dừng bay do thời tiết hoặc lệnh điều hành',
      'DRONE_FAULT' => 'Drone gặp sự cố',
      'NO_DRONE_AVAILABLE' => 'Tủ gửi không còn drone sẵn sàng',
      'SOURCE_LOCKER_FAULT' => 'Tủ gửi gặp sự cố',
      'DESTINATION_LOCKER_FAULT' => 'Tủ nhận gặp sự cố',
      'LANDING_PAD_FAULT' => 'Bãi đáp drone không sẵn sàng',
      'NO_TECHNICIAN_AVAILABLE' => 'Không có kỹ thuật viên nhận lấy hàng',
      'LAUNCH_OVERDUE' => 'Quá hạn phóng drone sau khi lấy hàng',
      'PICKUP_CUSTOMER_ABSENT' => 'Không gặp được người gửi tại điểm lấy hàng',
      'PICKUP_PARCEL_REJECTED' => 'Kiện hàng không đúng khai báo',
      'PICKUP_ADDRESS_NOT_FOUND' => 'Không tìm thấy địa chỉ lấy hàng',
      'FLIGHT_INCIDENT' => 'Sự cố trong lúc bay',
      'OPERATIONAL' => 'Lý do vận hành',
      'OTHER' => 'Lý do khác',
      _ => code!,
    };

/// Lý do KTV chọn khi tới nơi mà không lấy được kiện (mã, nhãn, có bắt buộc ghi chú).
const dronePickupFailureReasons = <(String, String, bool)>[
  ('PICKUP_CUSTOMER_ABSENT', 'Không gặp được người gửi', false),
  ('PICKUP_PARCEL_REJECTED', 'Kiện không đúng khai báo', false),
  ('PICKUP_ADDRESS_NOT_FOUND', 'Không tìm thấy địa chỉ', false),
  ('OTHER', 'Khác', true),
];

/// Lý do điều phối viên chọn khi xác nhận đơn giao không hoàn tất.
const droneDeliveryFailureReasons = <(String, String, bool)>[
  ('WEATHER', 'Thời tiết xấu', false),
  ('DRONE_FAULT', 'Drone lỗi', false),
  ('NO_DRONE_AVAILABLE', 'Không còn drone', false),
  ('LANDING_PAD_FAULT', 'Bãi đáp không sẵn sàng', false),
  ('SOURCE_LOCKER_FAULT', 'Tủ gửi lỗi', false),
  ('DESTINATION_LOCKER_FAULT', 'Tủ nhận lỗi', false),
  ('FLIGHT_INCIDENT', 'Sự cố lúc bay', false),
  ('OPERATIONAL', 'Lý do vận hành', false),
  ('OTHER', 'Khác', true),
];
