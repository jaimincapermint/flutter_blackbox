import 'dart:async';
import 'dart:collection';

import 'network_request.dart';
import 'network_response.dart';

/// Paired request/response record displayed in the network panel.
class NetworkEntry {
  NetworkEntry({required this.request}) : response = null;

  final NetworkRequest request;
  NetworkResponse? response;

  bool get isPending => response == null;
  int get durationMs => response?.durationMs ?? 0;
}

/// Stores the last [capacity] network entries and exposes them as a
/// broadcast [Stream].
class NetworkStore {
  NetworkStore({this.capacity = 50});

  final int capacity;
  final _entries = ListQueue<NetworkEntry>();
  final _controller = StreamController<List<NetworkEntry>>.broadcast();

  // ── Public API ──────────────────────────────────────────────────────

  List<NetworkEntry> get entries => List.unmodifiable(_entries);

  Stream<List<NetworkEntry>> get stream => _controller.stream;

  /// Called by [BlackBoxHttpAdapter] when a request is dispatched.
  void onRequest(NetworkRequest request) {
    if (_entries.length >= capacity) _entries.removeFirst();
    _entries.addLast(NetworkEntry(request: request));
    _notify();
  }

  /// Called by [BlackBoxHttpAdapter] when a response arrives.
  void onResponse(NetworkResponse response) {
    final entry = _entries.cast<NetworkEntry?>().firstWhere(
        (e) => e!.request.id == response.requestId,
        orElse: () => null);
    if (entry != null) {
      entry.response = response;
      _notify();
    }
  }

  void clear() {
    _entries.clear();
    _notify();
  }

  List<Map<String, dynamic>> toJson() => _entries
      .map((e) => {
            'request': e.request.toJson(),
            if (e.response != null) 'response': e.response!.toJson(),
          })
      .toList();

  void dispose() {
    _throttleTimer?.cancel();
    _controller.close();
  }

  // ── Private ─────────────────────────────────────────────────────────

  Timer? _throttleTimer;

  void _notify() {
    if (_controller.isClosed) return;
    if (_throttleTimer?.isActive ?? false) return;

    _throttleTimer = Timer(const Duration(milliseconds: 250), () {
      if (!_controller.isClosed) {
        _controller.add(List.unmodifiable(_entries));
      }
    });
  }
}
