import 'dart:async';

/// Tracks widget rebuild counts and exposes them as a broadcast stream.
class RebuildStore {
  final _counts = <String, int>{};
  final _controller = StreamController<Map<String, int>>.broadcast();

  Timer? _throttleTimer;

  Map<String, int> get counts => Map.unmodifiable(_counts);

  Stream<Map<String, int>> get stream => _controller.stream;

  /// Record a single rebuild for [widgetName].
  void record(String widgetName) {
    _counts[widgetName] = (_counts[widgetName] ?? 0) + 1;
    _notify();
  }

  /// Sorted entries, highest rebuild count first.
  List<MapEntry<String, int>> get sortedEntries {
    final entries = _counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  void reset() {
    _counts.clear();
    _notify();
  }

  void dispose() {
    _throttleTimer?.cancel();
    _controller.close();
  }

  void _notify() {
    if (_controller.isClosed) return;
    if (_throttleTimer?.isActive ?? false) return;
    _throttleTimer = Timer(const Duration(milliseconds: 500), () {
      if (!_controller.isClosed) {
        _controller.add(Map.unmodifiable(_counts));
      }
    });
  }
}
