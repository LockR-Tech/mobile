import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Business stages exposed by the order-based drone delivery read model.
enum DroneDeliveryStage {
  awaitingDispatch,

  /// KTV drone đã nhận và đang tới nhà người gửi lấy kiện.
  pickupAssigned,

  /// KTV đã cầm kiện, đang mang tới drone tại tủ bay để nạp trực tiếp lên drone.
  pickedUp,
  accepted,
  launching,
  departed,
  enRoute,
  approaching,
  arrived,
  readyForPickup,
  delayed,
  failed,

  /// Đội bay báo kiện rơi trong chuyến bay — sự cố đang được xử lý
  /// (`deliveryStage = DROP_REPORTED`, xem thẻ sự cố của đơn).
  dropReported,

  /// Đơn đã huỷ trước khi bay (khách huỷ lúc chờ điều phối hoặc đội bay huỷ).
  canceled,

  /// Người nhận đã lấy hàng khỏi tủ đích.
  completed,

  /// Quá hạn nhận hàng, ô đã được thu hồi.
  expired,
  unknown;

  static DroneDeliveryStage fromRaw(String? raw) {
    switch ((raw ?? '').trim().toUpperCase()) {
      case 'AWAITING_DISPATCH':
        return DroneDeliveryStage.awaitingDispatch;
      case 'PICKUP_ASSIGNED':
        return DroneDeliveryStage.pickupAssigned;
      case 'PICKED_UP':
        return DroneDeliveryStage.pickedUp;
      case 'ACCEPTED':
      case 'LOADING_CONFIRMED':
        return DroneDeliveryStage.accepted;
      case 'LAUNCHING':
        return DroneDeliveryStage.launching;
      case 'DEPARTED':
      case 'DISPATCHED':
        return DroneDeliveryStage.departed;
      case 'EN_ROUTE':
        return DroneDeliveryStage.enRoute;
      case 'APPROACHING':
        return DroneDeliveryStage.approaching;
      case 'ARRIVED':
        return DroneDeliveryStage.arrived;
      case 'READY_FOR_PICKUP':
      case 'DELIVERED':
        return DroneDeliveryStage.readyForPickup;
      case 'DELAYED':
        return DroneDeliveryStage.delayed;
      case 'FAILED':
        return DroneDeliveryStage.failed;
      case 'DROP_REPORTED':
        return DroneDeliveryStage.dropReported;
      case 'CANCELED':
      case 'CANCELLED':
        return DroneDeliveryStage.canceled;
      case 'COMPLETED':
        return DroneDeliveryStage.completed;
      case 'EXPIRED':
        return DroneDeliveryStage.expired;
      default:
        return DroneDeliveryStage.unknown;
    }
  }

  static const List<DroneDeliveryStage> timeline = [
    DroneDeliveryStage.awaitingDispatch,
    DroneDeliveryStage.pickupAssigned,
    DroneDeliveryStage.pickedUp,
    DroneDeliveryStage.accepted,
    DroneDeliveryStage.launching,
    DroneDeliveryStage.departed,
    DroneDeliveryStage.enRoute,
    DroneDeliveryStage.approaching,
    DroneDeliveryStage.arrived,
    DroneDeliveryStage.readyForPickup,
  ];

  /// Đơn cũ không lấy hàng tận nhà thì bỏ hai chặng lấy hàng.
  static List<DroneDeliveryStage> timelineFor({required bool homePickup}) =>
      homePickup
      ? timeline
      : timeline
            .where((step) => step != pickupAssigned && step != pickedUp)
            .toList(growable: false);

  int get order => timeline.indexOf(this);

  bool get isTerminal =>
      this == DroneDeliveryStage.readyForPickup ||
      this == DroneDeliveryStage.completed ||
      isFailure;

  /// Hành trình dừng mà hàng không tới tay người nhận.
  bool get isFailure =>
      this == DroneDeliveryStage.failed ||
      this == DroneDeliveryStage.canceled ||
      this == DroneDeliveryStage.expired;

  /// Drone đang ở trên không — các chặng do telemetry/bộ giả lập đẩy.
  bool get isInFlight =>
      this == DroneDeliveryStage.launching ||
      this == DroneDeliveryStage.departed ||
      this == DroneDeliveryStage.enRoute ||
      this == DroneDeliveryStage.approaching ||
      this == DroneDeliveryStage.arrived;
  bool get isDelayed => this == DroneDeliveryStage.delayed;

  /// Kiện gặp sự cố (rơi) giữa chuyến — chưa kết thúc, đang xử lý.
  bool get isIncident => this == DroneDeliveryStage.dropReported;

  String get title {
    switch (this) {
      case DroneDeliveryStage.awaitingDispatch:
        return 'Chờ kỹ thuật viên nhận lấy hàng';
      case DroneDeliveryStage.pickupAssigned:
        return 'Kỹ thuật viên đang tới lấy hàng';
      case DroneDeliveryStage.pickedUp:
        return 'Đã lấy hàng, đang mang tới drone';
      case DroneDeliveryStage.accepted:
        return 'Đang nạp hàng lên drone';
      case DroneDeliveryStage.launching:
        return 'Drone đang khởi phóng';
      case DroneDeliveryStage.departed:
        return 'Drone đã rời trạm';
      case DroneDeliveryStage.enRoute:
        return 'Drone đang trên đường';
      case DroneDeliveryStage.approaching:
        return 'Drone sắp đến';
      case DroneDeliveryStage.arrived:
        return 'Drone đã đến tủ';
      case DroneDeliveryStage.readyForPickup:
        return 'Sẵn sàng nhận hàng';
      case DroneDeliveryStage.delayed:
        return 'Đơn hàng bị chậm';
      case DroneDeliveryStage.failed:
        return 'Giao không hoàn tất';
      case DroneDeliveryStage.dropReported:
        return 'Kiện hàng gặp sự cố rơi';
      case DroneDeliveryStage.canceled:
        return 'Đơn drone đã huỷ';
      case DroneDeliveryStage.completed:
        return 'Đã nhận hàng';
      case DroneDeliveryStage.expired:
        return 'Quá hạn nhận hàng';
      case DroneDeliveryStage.unknown:
        return 'Cập nhật đơn hàng';
    }
  }

  String body(String? eta) {
    switch (this) {
      case DroneDeliveryStage.awaitingDispatch:
        return 'Hệ thống đang tìm kỹ thuật viên drone rảnh gần bạn nhất';
      case DroneDeliveryStage.pickupAssigned:
        return 'Kỹ thuật viên đang tới điểm lấy hàng, chuẩn bị kiện và mã lấy hàng';
      case DroneDeliveryStage.pickedUp:
        return 'Kiện đang được mang tới drone để nạp trực tiếp; không bỏ vào ô tủ bay';
      case DroneDeliveryStage.accepted:
        return 'Drone đã được gán, kỹ thuật viên đang cân và nạp kiện';
      case DroneDeliveryStage.launching:
        return 'Đội bay đang thực hiện quy trình khởi phóng';
      case DroneDeliveryStage.departed:
        return 'Drone đã cất cánh khỏi trạm nguồn';
      case DroneDeliveryStage.enRoute:
        return eta == null
            ? 'Drone đang bay tới tủ nhận'
            : 'Drone dự kiến đến trong $eta';
      case DroneDeliveryStage.approaching:
        return 'Drone đang tiếp cận tủ nhận của bạn';
      case DroneDeliveryStage.arrived:
        return 'Drone đã đến và đang gửi kiện hàng vào tủ';
      case DroneDeliveryStage.readyForPickup:
        return 'Kiện hàng đã nằm trong tủ nhận, dùng mã PIN/QR của đơn để mở ô';
      case DroneDeliveryStage.delayed:
        return eta == null
            ? 'Đơn đang bị chậm so với dự kiến'
            : 'Đơn đang bị chậm, dự kiến tới $eta';
      case DroneDeliveryStage.failed:
        return 'Đơn giao không hoàn tất';
      case DroneDeliveryStage.dropReported:
        return 'Đội bay đã báo kiện rơi trong chuyến bay và đang thu hồi. '
            'Lock.R sẽ gửi phương án xử lý cho bạn.';
      case DroneDeliveryStage.canceled:
        return 'Đơn đã dừng trước khi drone cất cánh';
      case DroneDeliveryStage.completed:
        return 'Người nhận đã lấy kiện hàng khỏi tủ';
      case DroneDeliveryStage.expired:
        return 'Đã quá hạn nhận hàng, vui lòng liên hệ hỗ trợ';
      case DroneDeliveryStage.unknown:
        return 'Đơn hàng của bạn có cập nhật mới';
    }
  }

  IconData get icon {
    switch (this) {
      case DroneDeliveryStage.awaitingDispatch:
        return LucideIcons.clock;
      case DroneDeliveryStage.pickupAssigned:
        return LucideIcons.bike;
      case DroneDeliveryStage.pickedUp:
        return LucideIcons.packageCheck;
      case DroneDeliveryStage.accepted:
        return LucideIcons.circleCheck;
      case DroneDeliveryStage.launching:
      case DroneDeliveryStage.departed:
        return LucideIcons.planeTakeoff;
      case DroneDeliveryStage.enRoute:
      case DroneDeliveryStage.approaching:
        return LucideIcons.navigation;
      case DroneDeliveryStage.arrived:
        return LucideIcons.mapPin;
      case DroneDeliveryStage.readyForPickup:
        return LucideIcons.packageCheck;
      case DroneDeliveryStage.delayed:
        return LucideIcons.clock;
      case DroneDeliveryStage.failed:
      case DroneDeliveryStage.expired:
        return LucideIcons.circleAlert;
      case DroneDeliveryStage.dropReported:
        return LucideIcons.triangleAlert;
      case DroneDeliveryStage.canceled:
        return LucideIcons.circleX;
      case DroneDeliveryStage.completed:
        return LucideIcons.circleCheck;
      case DroneDeliveryStage.unknown:
        return LucideIcons.package;
    }
  }

  Color get color {
    switch (this) {
      case DroneDeliveryStage.readyForPickup:
      case DroneDeliveryStage.completed:
        return const Color(0xFF16A34A);
      case DroneDeliveryStage.delayed:
        return const Color(0xFFF59E0B);
      case DroneDeliveryStage.dropReported:
        return const Color(0xFFEA580C);
      case DroneDeliveryStage.failed:
      case DroneDeliveryStage.canceled:
      case DroneDeliveryStage.expired:
        return const Color(0xFFDC2626);
      case DroneDeliveryStage.unknown:
        return const Color(0xFF64748B);
      case DroneDeliveryStage.awaitingDispatch:
      case DroneDeliveryStage.pickupAssigned:
      case DroneDeliveryStage.pickedUp:
      case DroneDeliveryStage.accepted:
      case DroneDeliveryStage.launching:
      case DroneDeliveryStage.departed:
      case DroneDeliveryStage.enRoute:
      case DroneDeliveryStage.approaching:
      case DroneDeliveryStage.arrived:
        return const Color(0xFF1E5A8A);
    }
  }
}
