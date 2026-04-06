import '../../core/socket/socket_event.dart';

/// Implement this interface to connect any Socket/WebSocket client to BlackBox.
///
/// Your adapter silently intercepts all socket events — the developer's
/// existing socket code stays **completely untouched**.
///
/// ## How it works
///
/// 1. You pass your socket instance to the adapter.
/// 2. The adapter hooks into the socket's event system (e.g. `onAny`,
///    `addListener`, etc.) to capture events automatically.
/// 3. BlackBox receives events via [onEventCallback] and displays them
///    in the Socket IO panel.
///
/// ## Contract
///
/// Your adapter must:
/// 1. Override [attach] to hook into the socket's event system.
/// 2. Call [onEvent] whenever a socket event is captured.
/// 3. Override [detach] to remove the hooks.
///
/// BlackBox wires the callback via [BlackBox.setup].
///
/// See [SocketIOBlackBoxAdapter] for a built-in Socket.IO implementation.
abstract class BlackBoxSocketAdapter {
  /// Unique identifier for this adapter (e.g. 'socket_io', 'web_socket').
  String get name;

  // ── Callback set by BlackBox.setup() ─────────────────────────────────

  /// Invoked when a socket event is captured (incoming or outgoing).
  void Function(SocketEvent)? onEventCallback;

  void onEvent(SocketEvent event) => onEventCallback?.call(event);

  /// Called by BlackBox when the adapter should start observing.
  /// Override to hook into your socket client (e.g., call `socket.onAny()`).
  void attach() {}

  /// Called when BlackBox is disposed or the adapter is replaced.
  /// Override to remove hooks from the socket client.
  void detach() {}
}
