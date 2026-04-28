import 'dart:collection';

import 'journey_event.dart';

/// Records a sequence of user actions and navigation events.
class JourneyStore {
  /// Creates a journey store with a fixed [capacity].
  JourneyStore({this.capacity = 50});

  /// Maximum number of journey events to retain.
  final int capacity;

  final _events = ListQueue<JourneyEvent>();

  /// Unmodifiable list of all recorded journey events.
  List<JourneyEvent> get events => _events.toList(growable: false);

  List<String> get numberedSteps {
    return _events.toList().asMap().entries.map((e) {
      final index = e.key + 1;
      return '$index. ${e.value.description}';
    }).toList();
  }

  void record(JourneyEvent event) {
    if (_events.length >= capacity) _events.removeFirst();
    _events.addLast(event);
  }

  void clear() {
    _events.clear();
  }
}
