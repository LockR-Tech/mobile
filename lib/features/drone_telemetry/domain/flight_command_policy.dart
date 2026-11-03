import 'flight_modes.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// Lệnh màn Flight Data gửi tới flight controller.
enum FlightCommand { arm, disarm, rtl, loiter, guided, auto, takeoff }

/// Trần độ cao cất cánh từ app (mét, so với điểm cất cánh).
const double kMaxTakeoffAltitudeM = 30;

/// Độ cao cất cánh tối thiểu (mét) — tránh lệnh 0 m vô nghĩa.
const double kMinTakeoffAltitudeM = 1;

/// Hết thời gian chờ COMMAND_ACK (hoặc heartbeat xác nhận đổi chế độ).
const Duration kCommandAckTimeout = Duration(seconds: 5);

extension FlightCommandText on FlightCommand {
  String get label => switch (this) {
    FlightCommand.arm => 'ARM',
    FlightCommand.disarm => 'DISARM',
    FlightCommand.rtl => 'RTL',
    FlightCommand.loiter => 'LOITER',
    FlightCommand.guided => 'GUIDED',
    FlightCommand.auto => 'AUTO',
    FlightCommand.takeoff => 'TAKEOFF',
  };

  /// Câu hỏi xác nhận — MỌI lệnh đều phải xác nhận trước khi gửi.
  String get confirmMessage => switch (this) {
    FlightCommand.arm => L10n.current.dtFcConfirmArm,
    FlightCommand.disarm => L10n.current.dtFcConfirmDisarm,
    FlightCommand.rtl => L10n.current.dtFcConfirmRtl,
    FlightCommand.loiter => L10n.current.dtFcConfirmLoiter,
    FlightCommand.guided => L10n.current.dtFcConfirmGuided,
    FlightCommand.auto => L10n.current.dtFcConfirmAuto,
    FlightCommand.takeoff => L10n.current.dtFcConfirmTakeoff,
  };

  /// `custom_mode` ArduCopter cho lệnh đổi chế độ; `null` với lệnh khác.
  int? get targetMode => switch (this) {
    FlightCommand.rtl => ArduCopterMode.rtl,
    FlightCommand.loiter => ArduCopterMode.loiter,
    FlightCommand.guided => ArduCopterMode.guided,
    FlightCommand.auto => ArduCopterMode.auto,
    _ => null,
  };
}

/// Trạng thái link/drone dùng để quyết định có cho gửi lệnh hay không.
class FlightCommandState {
  const FlightCommandState({
    required this.connected,
    required this.peerKnown,
    required this.heartbeatSeen,
    required this.linkAlive,
    required this.armed,
    required this.modeName,
    this.commandPending = false,
    this.missionLocked = false,
  });

  /// Transport đã mở (UDP bind / TCP connect).
  final bool connected;

  /// Đã biết địa chỉ drone để gửi gói tin tới (UDP học từ gói đầu tiên).
  final bool peerKnown;

  /// Đã nhận ít nhất một HEARTBEAT từ drone.
  final bool heartbeatSeen;

  /// HEARTBEAT gần nhất còn mới (< 3 giây).
  final bool linkAlive;
  final bool armed;
  final String modeName;

  /// Đang chờ drone phản hồi lệnh trước.
  final bool commandPending;

  /// Drone mình phụ trách đang có nhiệm vụ giao hàng và chưa xác nhận kết nối
  /// này không phải drone đó.
  final bool missionLocked;
}

/// Lý do chặn [command]; `null` = được gửi (vẫn phải xác nhận).
String? flightCommandBlockReason(
  FlightCommand command,
  FlightCommandState state,
) {
  if (!state.connected) return L10n.current.dtFcNotConnected;
  if (!state.peerKnown) {
    return L10n.current.dtFcPeerUnknown;
  }
  if (!state.heartbeatSeen) return L10n.current.dtFcNoHeartbeat;
  if (!state.linkAlive) return L10n.current.dtFcHeartbeatLost;
  if (state.missionLocked) {
    return L10n.current.dtFcMissionLocked;
  }
  if (state.commandPending) return L10n.current.dtFcPending;
  switch (command) {
    case FlightCommand.arm:
      if (state.armed) return L10n.current.dtFcAlreadyArmed;
    case FlightCommand.disarm:
      if (!state.armed) return L10n.current.dtFcNotArmed;
    case FlightCommand.takeoff:
      if (!state.armed) return L10n.current.dtFcTakeoffNeedsArm;
      if (state.modeName != 'GUIDED') {
        return L10n.current.dtFcTakeoffNeedsGuided(state.modeName);
      }
    case FlightCommand.rtl:
    case FlightCommand.loiter:
    case FlightCommand.guided:
    case FlightCommand.auto:
      break;
  }
  return null;
}

/// Lỗi độ cao cất cánh nhập tay; `null` = hợp lệ.
String? takeoffAltitudeError(double? altitudeM) {
  if (altitudeM == null || altitudeM.isNaN) return L10n.current.dtFcEnterAltitude;
  if (altitudeM < kMinTakeoffAltitudeM) {
    return L10n.current.dtFcMinAltitude(kMinTakeoffAltitudeM.toStringAsFixed(0));
  }
  if (altitudeM > kMaxTakeoffAltitudeM) {
    return L10n.current.dtFcMaxAltitude(kMaxTakeoffAltitudeM.toStringAsFixed(0));
  }
  return null;
}

/// MAV_RESULT của COMMAND_ACK ⇒ chữ hiển thị.
String mavResultLabel(int result) => switch (result) {
  0 => L10n.current.dtFcResultAccepted,
  1 => L10n.current.dtFcResultTempRejected,
  2 => L10n.current.dtFcResultDenied,
  3 => L10n.current.dtFcResultUnsupported,
  4 => L10n.current.dtFcResultFailed,
  5 => L10n.current.dtFcResultInProgress,
  6 => L10n.current.dtFcResultCancelled,
  _ => L10n.current.dtFcResultCode(result),
};
