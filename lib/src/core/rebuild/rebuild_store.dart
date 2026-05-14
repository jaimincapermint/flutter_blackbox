import 'dart:async';

/// Tracks widget rebuild counts and exposes them as a broadcast stream.
class RebuildStore {
  final _counts = <String, int>{};
  final _controller = StreamController<Map<String, int>>.broadcast();

  Timer? _throttleTimer;

  /// Maximum number of unique widgets to track to prevent memory leaks.
  int capacity = 500;

  /// Current rebuild count for each tracked widget label.
  Map<String, int> get counts => Map.unmodifiable(_counts);

  /// Broadcast stream of the current rebuild counts, throttled to 500ms.
  Stream<Map<String, int>> get stream => _controller.stream;

  /// Record a single rebuild for [widgetName].
  void record(String widgetName) {
    if (!_counts.containsKey(widgetName) && _counts.length >= capacity) {
      // Find the entry with the lowest rebuild count and remove it to prevent memory leaks
      String? lowestKey;
      int lowestCount = 2147483647; // Max int
      for (final entry in _counts.entries) {
        if (entry.value < lowestCount) {
          lowestCount = entry.value;
          lowestKey = entry.key;
        }
      }
      if (lowestKey != null) _counts.remove(lowestKey);
    }
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
