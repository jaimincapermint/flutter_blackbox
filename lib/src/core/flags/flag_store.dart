import 'dart:async';

import 'flag_config.dart';

/// Holds registered feature flags and their current runtime values.
///
/// Values can be overridden at runtime from the BlackBox overlay panel.
/// All changes are broadcast via [stream] and per-key [streamFor].
class FlagStore {
  final _configs = <String, FlagConfig>{};
  final _overrides = <String, dynamic>{};
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  final _keyControllers = <String, StreamController<dynamic>>{};

  // ── Registration ────────────────────────────────────────────────────

  void register(Map<String, FlagConfig> configs) {
    _configs.addAll(configs);
    for (final key in configs.keys) {
      _keyControllers.putIfAbsent(
        key,
        () => StreamController<dynamic>.broadcast(),
      );
    }
  }

  // ── Reading ─────────────────────────────────────────────────────────

  Map<String, FlagConfig> get configs => Map.unmodifiable(_configs);

  /// Current value: override if set, else default.
  T value<T>(String key) {
    assert(_configs.containsKey(key),
        'Flag "$key" not registered. Call BlackBox.setup() first.');
    return (_overrides[key] ?? _configs[key]!.defaultValue) as T;
  }

  /// Stream of value changes for a specific flag key.
  Stream<T> streamFor<T>(String key) {
    _keyControllers.putIfAbsent(
      key,
      () => StreamController<dynamic>.broadcast(),
    );
    return _keyControllers[key]!.stream.cast<T>();
  }

  /// Broadcast stream of the full overrides map.
  Stream<Map<String, dynamic>> get stream => _controller.stream;

  Map<String, dynamic> get allCurrentValues => {
        for (final key in _configs.keys)
          key: _overrides[key] ?? _configs[key]!.defaultValue,
      };

  // ── Writing (overlay panel) ─────────────────────────────────────────

  void override(String key, dynamic value) {
    _overrides[key] = value;
    _notify(key, value);
  }

  void reset(String key) {
    _overrides.remove(key);
    _notify(key, _configs[key]!.defaultValue);
  }

  void resetAll() {
    final keys = List.of(_overrides.keys);
    _overrides.clear();
    for (final key in keys) {
      _notify(key, _configs[key]!.defaultValue);
    }
  }

  // ── Export ──────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => allCurrentValues;

  void dispose() {
    _controller.close();
    for (final c in _keyControllers.values) {
      c.close();
    }
  }

  // ── Private ─────────────────────────────────────────────────────────

  void _notify(String key, dynamic value) {
    if (!_controller.isClosed) _controller.add(allCurrentValues);
    final kc = _keyControllers[key];
    if (kc != null && !kc.isClosed) kc.add(value);
  }
}
