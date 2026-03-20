import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_blackbox/src/core/flags/flag_config.dart';
import 'package:flutter_blackbox/src/core/flags/flag_store.dart';

void main() {
  group('FlagStore', () {
    late FlagStore store;

    setUp(() {
      store = FlagStore();
      store.register({
        'show_banner': const FlagConfig(defaultValue: true),
        'api_url': const FlagConfig(defaultValue: 'https://api.prod.com'),
        'retry_count': const FlagConfig(defaultValue: 3),
      });
    });

    tearDown(() => store.dispose());

    test('returns default value when no override set', () {
      expect(store.value<bool>('show_banner'), isTrue);
      expect(store.value<String>('api_url'), 'https://api.prod.com');
      expect(store.value<int>('retry_count'), 3);
    });

    test('override replaces default', () {
      store.override('show_banner', false);
      expect(store.value<bool>('show_banner'), isFalse);
    });

    test('reset restores default', () {
      store.override('api_url', 'https://api.staging.com');
      store.reset('api_url');
      expect(store.value<String>('api_url'), 'https://api.prod.com');
    });

    test('resetAll restores all defaults', () {
      store.override('show_banner', false);
      store.override('retry_count', 10);
      store.resetAll();
      expect(store.value<bool>('show_banner'), isTrue);
      expect(store.value<int>('retry_count'), 3);
    });

    test('streamFor emits on override', () async {
      final values = <bool>[];
      final sub = store.streamFor<bool>('show_banner').listen(values.add);

      store.override('show_banner', false);
      store.override('show_banner', true);

      await Future<void>.delayed(Duration.zero);
      expect(values, [false, true]);
      await sub.cancel();
    });

    test('allCurrentValues contains overrides', () {
      store.override('retry_count', 5);
      final all = store.allCurrentValues;
      expect(all['retry_count'], 5);
      expect(all['show_banner'], true); // not overridden
    });

    test('asserts on unregistered key access', () {
      expect(() => store.value<bool>('unknown_flag'), throwsAssertionError);
    });

    test('auto-detects FlagType.boolean', () {
      const cfg = FlagConfig(defaultValue: true);
      expect(cfg.type, FlagType.boolean);
    });

    test('auto-detects FlagType.integer', () {
      const cfg = FlagConfig(defaultValue: 42);
      expect(cfg.type, FlagType.integer);
    });

    test('auto-detects FlagType.string', () {
      const cfg = FlagConfig(defaultValue: 'hello');
      expect(cfg.type, FlagType.string);
    });
  });
}
