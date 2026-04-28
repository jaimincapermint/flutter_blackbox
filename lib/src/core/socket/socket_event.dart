/// Direction of the socket communication.
enum SocketDirection {
  /// Data received from the server.
  incoming,

  /// Data sent to the server.
  outgoing
}

/// Snapshot of a single Socket.IO event.
class SocketEvent {
  const SocketEvent({
    required this.id,
    required this.eventName,
    required this.data,
    required this.timestamp,
    required this.direction,
  });

  /// Unique identifier for the socket event.
  final String id;

  /// Name of the event (e.g., 'message', 'typing').
  final String eventName;

  /// Payload data received or sent.
  final dynamic data;

  /// When the event occurred.
  final DateTime timestamp;

  /// Whether the event was incoming or outgoing.
  final SocketDirection direction;

  Map<String, dynamic> toJson() => {
        'id': id,
        'eventName': eventName,
        if (data != null) 'data': data,
        'timestamp': timestamp.toIso8601String(),
        'direction': direction.name,
      };
}
