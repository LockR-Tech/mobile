/// MAVLink checksum (CRC-16/MCRF4XX) and the per-message `CRC_EXTRA` seeds.
///
/// MAVLink protects every frame with an X.25 / MCRF4XX 16-bit CRC computed over
/// the frame fields (everything after the start byte, excluding the checksum
/// itself) seeded with a message-specific `CRC_EXTRA` byte. The `CRC_EXTRA`
/// values come straight from the upstream `common.xml` dialect and must match
/// exactly, otherwise a real ArduPilot/PX4 autopilot rejects our outgoing
/// commands and we would reject its telemetry.
class MavlinkCrc {
  const MavlinkCrc._();

  static const int _seed = 0xFFFF;

  /// Accumulates a single byte into [crc] using the MAVLink CRC-16 algorithm.
  static int accumulate(int data, int crc) {
    var tmp = data ^ (crc & 0xFF);
    tmp = (tmp ^ (tmp << 4)) & 0xFF;
    return ((crc >> 8) ^ (tmp << 8) ^ (tmp << 3) ^ (tmp >> 4)) & 0xFFFF;
  }

  /// Computes the checksum over [bytes] (a frame slice) finishing with the
  /// message's [crcExtra] seed byte.
  static int compute(List<int> bytes, int crcExtra) {
    var crc = _seed;
    for (final b in bytes) {
      crc = accumulate(b, crc);
    }
    return accumulate(crcExtra, crc);
  }

  /// `CRC_EXTRA` per MAVLink message id (common.xml). Only the subset the app
  /// sends or decodes is listed; ids absent here are treated as unknown.
  static const Map<int, int> crcExtra = {
    0: 50, // HEARTBEAT
    1: 124, // SYS_STATUS
    11: 89, // SET_MODE
    24: 24, // GPS_RAW_INT
    30: 39, // ATTITUDE
    33: 104, // GLOBAL_POSITION_INT
    66: 148, // REQUEST_DATA_STREAM
    74: 20, // VFR_HUD
    76: 152, // COMMAND_LONG
    77: 143, // COMMAND_ACK
    253: 83, // STATUSTEXT
  };

  static int? extraFor(int messageId) => crcExtra[messageId];
}
