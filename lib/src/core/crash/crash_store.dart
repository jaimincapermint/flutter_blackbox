import 'dart:async';
import 'dart:collection';

import 'crash_entry.dart';

/// Manages a collection of captured application crashes and errors.
class CrashStore {
  /// Creates a crash store with a fixed [capacity].
  CrashStore({this.capacity = 20});

  /// Maximum number of crashes to retain.
  final int capacity;

  final _entries = ListQueue<CrashEntry>();
  final _controller = StreamController<List<CrashEntry>>.broadcast();

  /// Broadcast stream that emits whenever a new crash is recorded.
  Stream<List<CrashEntry>> get stream => _controller.stream;

  /// Unmodifiable list of all recorded crash entries.
  List<CrashEntry> get entries => _entries.toList(growable: false);

  void add(CrashEntry entry) {
    if (_entries.length >= capacity) _entries.removeFirst();
    _entries.addLast(entry);
    _notify();
  }

  void clear() {
    _entries.clear();
    _notify();
  }

  void _notify() {
    if (!_controller.isClosed) {
      _controller.add(entries);
    }
  }

  List<Map<String, dynamic>> toJson() =>
      _entries.map((e) => e.toJson()).toList();

  void dispose() {
    _controller.close();
  }
}
