import 'dart:async';
import 'dart:collection';

import 'socket_event.dart';

/// Manages the history of Socket.IO events.
class SocketStore {
  /// Creates a store with a fixed [capacity].
  SocketStore({this.capacity = 100});

  /// Maximum number of events to retain in memory.
  final int capacity;

  final _events = ListQueue<SocketEvent>();
  final _controller = StreamController<List<SocketEvent>>.broadcast();

  /// Unmodifiable list of all recorded socket events.
  List<SocketEvent> get events => List.unmodifiable(_events);

  /// Broadcast stream of the event list, throttled to 250ms.
  Stream<List<SocketEvent>> get stream => _controller.stream;

  void onEvent(SocketEvent event) {
    if (_events.length >= capacity) _events.removeFirst();
    _events.addLast(event);
    _notify();
  }

  void clear() {
    _events.clear();
    _notify();
  }

  List<Map<String, dynamic>> toJson() =>
      _events.map((e) => e.toJson()).toList();

  void dispose() {
    _throttleTimer?.cancel();
    _controller.close();
  }

  Timer? _throttleTimer;
  void _notify() {
    if (_controller.isClosed) return;
    if (_throttleTimer?.isActive ?? false) return;
    _throttleTimer = Timer(const Duration(milliseconds: 250), () {
      if (!_controller.isClosed) {
        _controller.add(List.unmodifiable(_events));
      }
    });
  }
}
