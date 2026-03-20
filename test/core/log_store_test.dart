import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_blackbox/src/core/log/log_entry.dart';
import 'package:flutter_blackbox/src/core/log/log_level.dart';
import 'package:flutter_blackbox/src/core/log/log_store.dart';

void main() {
  group('LogStore', () {
    late LogStore store;

    setUp(() => store = LogStore(capacity: 5));
    tearDown(() => store.dispose());

    LogEntry entry(String msg, {LogLevel level = LogLevel.info, String? tag}) =>
        LogEntry(
          id: msg,
          level: level,
          message: msg,
          timestamp: DateTime.now(),
          tag: tag,
        );

    test('adds entries and respects capacity', () {
      for (var i = 0; i < 7; i++) {
        store.add(entry('msg_$i'));
      }
      expect(store.entries.length, 5);
      expect(store.entries.first.message, 'msg_2'); // oldest dropped
    });

    test('clear removes all entries', () {
      store.add(entry('a'));
      store.clear();
      expect(store.entries, isEmpty);
    });

    test('filter by level', () {
      store.add(entry('info msg', level: LogLevel.info));
      store.add(entry('error msg', level: LogLevel.error));

      final errors = store.filter(level: LogLevel.error);
      expect(errors.length, 1);
      expect(errors.first.message, 'error msg');
    });

    test('filter by query', () {
      store.add(entry('payment failed'));
      store.add(entry('user logged in'));

      final results = store.filter(query: 'payment');
      expect(results.length, 1);
    });

    test('filter by tag', () {
      store.add(entry('tagged', tag: 'AuthBloc'));
      store.add(entry('untagged'));

      expect(store.filter(tag: 'AuthBloc').length, 1);
    });

    test('stream emits on add', () async {
      final emissions = <int>[];
      final sub = store.stream.listen((e) => emissions.add(e.length));

      store.add(entry('a'));
      store.add(entry('b'));

      await Future<void>.delayed(Duration.zero);
      expect(emissions, [1, 2]);
      await sub.cancel();
    });

    test('toJson returns serialisable list', () {
      store.add(entry('hello', level: LogLevel.warning));
      final json = store.toJson();
      expect(json.first['message'], 'hello');
      expect(json.first['level'], 'WARN');
    });
  });
}
