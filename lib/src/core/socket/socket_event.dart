enum SocketDirection { incoming, outgoing }

class SocketEvent {
  const SocketEvent({
    required this.id,
    required this.eventName,
    required this.data,
    required this.timestamp,
    required this.direction,
  });

  final String id;
  final String eventName;
  final dynamic data;
  final DateTime timestamp;
  final SocketDirection direction;

  Map<String, dynamic> toJson() => {
        'id': id,
        'eventName': eventName,
        if (data != null) 'data': data,
        'timestamp': timestamp.toIso8601String(),
        'direction': direction.name,
      };
}
