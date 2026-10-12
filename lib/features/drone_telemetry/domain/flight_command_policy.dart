import 'flight_modes.dart';

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
    FlightCommand.arm => 'Arm động cơ? Cánh quạt sẽ quay.',
    FlightCommand.disarm =>
      'Disarm động cơ? Nếu drone đang bay, drone sẽ rơi.',
    FlightCommand.rtl => 'Chuyển sang RTL: drone tự bay về điểm xuất phát?',
    FlightCommand.loiter => 'Chuyển sang LOITER: drone giữ nguyên vị trí?',
    FlightCommand.guided =>
      'Chuyển sang GUIDED: drone nhận lệnh điều khiển từ ứng dụng?',
    FlightCommand.auto => 'Chuyển sang AUTO: drone chạy mission đã nạp?',
    FlightCommand.takeoff => 'Cất cánh tới độ cao đã nhập?',
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
  if (!state.connected) return 'Chưa kết nối flight controller.';
  if (!state.peerKnown) {
    return 'Chưa biết địa chỉ drone — chờ drone gửi gói tin đầu tiên.';
  }
  if (!state.heartbeatSeen) return 'Chưa nhận heartbeat từ drone.';
  if (!state.linkAlive) return 'Mất heartbeat từ drone (quá 3 giây).';
  if (state.missionLocked) {
    return 'Drone bạn phụ trách đang có nhiệm vụ giao hàng — lệnh tay đang bị khoá.';
  }
  if (state.commandPending) return 'Đang chờ drone phản hồi lệnh trước.';
  switch (command) {
    case FlightCommand.arm:
      if (state.armed) return 'Drone đã ARM.';
    case FlightCommand.disarm:
      if (!state.armed) return 'Drone chưa ARM.';
    case FlightCommand.takeoff:
      if (!state.armed) return 'Chỉ cất cánh khi drone đã ARM.';
      if (state.modeName != 'GUIDED') {
        return 'Chỉ cất cánh ở chế độ GUIDED (hiện tại: ${state.modeName}).';
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
  if (altitudeM == null || altitudeM.isNaN) return 'Nhập độ cao (m).';
  if (altitudeM < kMinTakeoffAltitudeM) {
    return 'Độ cao tối thiểu ${kMinTakeoffAltitudeM.toStringAsFixed(0)} m.';
  }
  if (altitudeM > kMaxTakeoffAltitudeM) {
    return 'Độ cao tối đa ${kMaxTakeoffAltitudeM.toStringAsFixed(0)} m.';
  }
  return null;
}

/// MAV_RESULT của COMMAND_ACK ⇒ chữ hiển thị.
String mavResultLabel(int result) => switch (result) {
  0 => 'Đã nhận (ACCEPTED)',
  1 => 'Tạm từ chối (TEMPORARILY_REJECTED)',
  2 => 'Từ chối (DENIED)',
  3 => 'Không hỗ trợ (UNSUPPORTED)',
  4 => 'Thất bại (FAILED)',
  5 => 'Đang thực hiện (IN_PROGRESS)',
  6 => 'Đã huỷ (CANCELLED)',
  _ => 'Mã kết quả $result',
};
