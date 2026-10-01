import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Business stages exposed by the order-based drone delivery read model.
enum DroneDeliveryStage {
  awaitingDispatch,
  accepted,
  launching,
  departed,
  enRoute,
  approaching,
  arrived,
  readyForPickup,
  delayed,
  failed,

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
    DroneDeliveryStage.accepted,
    DroneDeliveryStage.launching,
    DroneDeliveryStage.departed,
    DroneDeliveryStage.enRoute,
    DroneDeliveryStage.approaching,
    DroneDeliveryStage.arrived,
    DroneDeliveryStage.readyForPickup,
  ];

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

  String get title {
    switch (this) {
      case DroneDeliveryStage.awaitingDispatch:
        return 'Chờ đội bay tiếp nhận';
      case DroneDeliveryStage.accepted:
        return 'Đội bay đã tiếp nhận';
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
        return 'Giao hàng không thành công';
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
        return 'Đơn đang chờ đội bay kiểm tra và nhận nhiệm vụ';
      case DroneDeliveryStage.accepted:
        return 'Drone đã được gán và sẵn sàng khởi hành';
      case DroneDeliveryStage.launching:
        return 'Đội bay đang thực hiện quy trình khởi phóng';
      case DroneDeliveryStage.departed:
        return 'Drone đã cất cánh khỏi trạm nguồn';
      case DroneDeliveryStage.enRoute:
        return eta == null ? 'Drone đang bay tới tủ nhận' : 'Drone dự kiến đến trong $eta';
      case DroneDeliveryStage.approaching:
        return 'Drone đang tiếp cận tủ nhận của bạn';
      case DroneDeliveryStage.arrived:
        return 'Drone đã đến và đang gửi kiện hàng vào tủ';
      case DroneDeliveryStage.readyForPickup:
        return 'Kiện hàng đã nằm trong tủ nhận, dùng mã PIN/QR của đơn để mở ô';
      case DroneDeliveryStage.delayed:
        return eta == null ? 'Đơn đang bị chậm so với dự kiến' : 'Đơn đang bị chậm, dự kiến tới $eta';
      case DroneDeliveryStage.failed:
        return 'Nhiệm vụ không thành công, đội bay sẽ hỗ trợ bạn';
      case DroneDeliveryStage.canceled:
        return 'Nhiệm vụ đã dừng trước khi drone cất cánh';
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
      case DroneDeliveryStage.failed:
      case DroneDeliveryStage.canceled:
      case DroneDeliveryStage.expired:
        return const Color(0xFFDC2626);
      case DroneDeliveryStage.unknown:
        return const Color(0xFF64748B);
      case DroneDeliveryStage.awaitingDispatch:
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
