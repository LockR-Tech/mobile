import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

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

  /// Chỉ lấy dự báo thời tiết 30 phút khi đơn đang chuẩn bị bay hoặc đang trong chuyến bay.
  bool get needsRouteWeather =>
      !isTerminal && !isIncident && this != DroneDeliveryStage.unknown;

  String get title {
    switch (this) {
      case DroneDeliveryStage.awaitingDispatch:
        return L10n.current.stgTitleAwaitingTech;
      case DroneDeliveryStage.pickupAssigned:
        return L10n.current.stgTitleTechOnWay;
      case DroneDeliveryStage.pickedUp:
        return L10n.current.stgTitlePickedUp;
      case DroneDeliveryStage.accepted:
        return L10n.current.stgTitleLoading;
      case DroneDeliveryStage.launching:
        return L10n.current.stgTitleLaunching;
      case DroneDeliveryStage.departed:
        return L10n.current.stgTitleDeparted;
      case DroneDeliveryStage.enRoute:
        return L10n.current.stgTitleEnRoute;
      case DroneDeliveryStage.approaching:
        return L10n.current.stgTitleApproaching;
      case DroneDeliveryStage.arrived:
        return L10n.current.stgTitleArrived;
      case DroneDeliveryStage.readyForPickup:
        return L10n.current.stgTitleReady;
      case DroneDeliveryStage.delayed:
        return L10n.current.stgTitleDelayed;
      case DroneDeliveryStage.failed:
        return L10n.current.stgTitleFailed;
      case DroneDeliveryStage.dropReported:
        return L10n.current.stgTitleDrop;
      case DroneDeliveryStage.canceled:
        return L10n.current.stgTitleCancelled;
      case DroneDeliveryStage.completed:
        return L10n.current.stgTitleReceived;
      case DroneDeliveryStage.expired:
        return L10n.current.stgTitleExpired;
      case DroneDeliveryStage.unknown:
        return L10n.current.stgTitleUpdate;
    }
  }

  String body(String? eta) {
    switch (this) {
      case DroneDeliveryStage.awaitingDispatch:
        // Đúng cả khi đơn chưa trả tiền (hệ thống chỉ mời KTV sau khi thanh toán).
        return L10n.current.stgDescAwaitingTech;
      case DroneDeliveryStage.pickupAssigned:
        return L10n.current.stgDescTechOnWay;
      case DroneDeliveryStage.pickedUp:
        return L10n.current.stgDescPickedUp;
      case DroneDeliveryStage.accepted:
        return L10n.current.stgDescLoading;
      case DroneDeliveryStage.launching:
        return L10n.current.stgDescLaunching;
      case DroneDeliveryStage.departed:
        return L10n.current.stgDescDeparted;
      case DroneDeliveryStage.enRoute:
        return eta == null
            ? L10n.current.stgDescEnRoute
            : L10n.current.stgDescEnRouteEta(eta);
      case DroneDeliveryStage.approaching:
        return L10n.current.stgDescApproaching;
      case DroneDeliveryStage.arrived:
        return L10n.current.stgDescArrived;
      case DroneDeliveryStage.readyForPickup:
        return L10n.current.stgDescReady;
      case DroneDeliveryStage.delayed:
        return eta == null
            ? L10n.current.stgDescDelayed
            : L10n.current.stgDescDelayedEta(eta);
      case DroneDeliveryStage.failed:
        return L10n.current.stgDescFailed;
      case DroneDeliveryStage.dropReported:
        return L10n.current.stgDescDrop;
      case DroneDeliveryStage.canceled:
        return L10n.current.stgDescCancelled;
      case DroneDeliveryStage.completed:
        return L10n.current.stgDescReceived;
      case DroneDeliveryStage.expired:
        return L10n.current.stgDescExpired;
      case DroneDeliveryStage.unknown:
        return L10n.current.stgDescUpdate;
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
