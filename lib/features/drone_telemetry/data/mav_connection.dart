import 'dart:async';
import 'dart:io';

/// Transport for a MAVLink byte stream. Concrete subclasses move bytes over
/// UDP or TCP; the protocol/codec layer sits on top and is transport-agnostic.
///
/// USB-serial and Bluetooth are deliberately not implemented yet (they need
/// platform plugins + Android USB-host config); the abstraction is here so they
/// can be added without touching the codec or UI.
abstract class MavConnection {
  /// Raw inbound bytes from the link.
  Stream<List<int>> get inbound;

  /// Human-readable endpoint description for the UI.
  String get label;

  /// Opens the link. Throws on failure.
  Future<void> connect();

  /// Sends a framed MAVLink packet to the vehicle.
  void send(List<int> bytes);

  Future<void> close();
}

/// MAVLink over UDP — the most common link for ArduPilot/PX4 over WiFi and for
/// the SITL simulator. Binds a local port, learns the vehicle's address from
/// the first datagram (or from [remoteHost] if given), and replies there.
class UdpMavConnection implements MavConnection {
  UdpMavConnection({this.remoteHost, this.remotePort = 14550, this.localPort = 14550});

  /// Vehicle address; when null we wait to learn it from the first inbound
  /// datagram (SITL "broadcast to GCS" style).
  final String? remoteHost;
  final int remotePort;
  final int localPort;

  RawDatagramSocket? _socket;
  InternetAddress? _peer;
  int _peerPort = 0;
  final _controller = StreamController<List<int>>.broadcast();

  @override
  Stream<List<int>> get inbound => _controller.stream;

  @override
  String get label => 'UDP ${remoteHost ?? '*'}:$remotePort (local $localPort)';

  @override
  Future<void> connect() async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, localPort);
    _socket = socket;
    if (remoteHost != null) {
      _peer = (await InternetAddress.lookup(remoteHost!)).first;
      _peerPort = remotePort;
    }
    socket.listen((event) {
      if (event == RawSocketEvent.read) {
        final dg = socket.receive();
        if (dg == null) return;
        _peer = dg.address;
        _peerPort = dg.port;
        _controller.add(dg.data);
      }
    });
  }

  @override
  void send(List<int> bytes) {
    final socket = _socket;
    final peer = _peer;
    if (socket == null || peer == null) return; // address not learned yet
    socket.send(bytes, peer, _peerPort);
  }

  @override
  Future<void> close() async {
    _socket?.close();
    _socket = null;
    await _controller.close();
  }
}

/// MAVLink over TCP — used by SITL (`tcp:127.0.0.1:5760`) and some telemetry
/// bridges that expose a TCP server.
class TcpMavConnection implements MavConnection {
  TcpMavConnection({required this.host, this.port = 5760});

  final String host;
  final int port;

  Socket? _socket;
  final _controller = StreamController<List<int>>.broadcast();

  @override
  Stream<List<int>> get inbound => _controller.stream;

  @override
  String get label => 'TCP $host:$port';

  @override
  Future<void> connect() async {
    final socket = await Socket.connect(
      host,
      port,
      timeout: const Duration(seconds: 8),
    );
    _socket = socket;
    socket.listen(
      _controller.add,
      onDone: () => _controller.close(),
      onError: (Object e) => _controller.addError(e),
      cancelOnError: true,
    );
  }

  @override
  void send(List<int> bytes) => _socket?.add(bytes);

  @override
  Future<void> close() async {
    await _socket?.close();
    _socket = null;
    if (!_controller.isClosed) await _controller.close();
  }
}
