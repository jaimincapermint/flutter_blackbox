import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/socket/socket_event.dart';
import 'blackbox_socket_adapter.dart';

/// Built-in adapter for the `socket_io_client` package.
///
/// Automatically intercepts **all incoming** socket events with **zero
/// changes** to your existing socket code.
///
/// ## Usage
///
/// ```dart
/// final socket = io.io('http://localhost:3000');
///
/// BlackBox.setup(
///   socketAdapters: [SocketIOBlackBoxAdapter(socket)],
/// );
///
/// // Continue using socket exactly as before — BlackBox observes silently:
/// socket.on('message', (data) => handleMessage(data));
/// // ↑ Incoming events appear in the Socket IO panel automatically.
/// ```
///
/// ## How it works
///
/// - **Incoming events**: Captured automatically via `socket.onAny()` —
///   this hooks into socket_io_client's built-in event system without
///   modifying any of your `.on()` handlers.
///
/// - **Outgoing events**: For `socket.emit()` calls, use
///   `BlackBox.logSocketEvent()` as a lightweight fallback — the
///   socket_io_client library does not provide an emit interceptor API.
class SocketIOBlackBoxAdapter extends BlackBoxSocketAdapter {
  SocketIOBlackBoxAdapter(this._socket);

  final io.Socket _socket;

  @override
  String get name => 'socket_io';

  @override
  void attach() {
    // socket_io_client's `onAny` captures ALL incoming events
    // without touching any of the developer's `.on()` handlers.
    _socket.onAny((String event, dynamic data) {
      onEvent(SocketEvent(
        id: 'soc_${DateTime.now().microsecondsSinceEpoch}',
        eventName: event,
        data: data,
        timestamp: DateTime.now(),
        direction: SocketDirection.incoming,
      ));
    });
  }

  @override
  void detach() {
    _socket.offAny();
  }
}
