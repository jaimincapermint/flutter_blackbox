import '../../core/flags/flag_config.dart';
import 'devkit_flag_adapter.dart';

/// Simple in-memory flag adapter.
///
/// Accepts a plain map of key → [FlagConfig] (or raw default values
/// which are auto-wrapped).
///
/// Example:
/// ```dart
/// LocalFlagAdapter(flags: {
///   'new_checkout': FlagConfig(defaultValue: false, group: 'Checkout'),
///   'api_url': FlagConfig(defaultValue: 'https://api.prod.com'),
/// })
/// ```
class LocalFlagAdapter extends BlackBoxFlagAdapter {
  LocalFlagAdapter({required Map<String, Object> flags})
      : _flags = _normalise(flags);

  final Map<String, FlagConfig> _flags;

  @override
  String get name => 'local';

  @override
  Map<String, FlagConfig> get flags => Map.unmodifiable(_flags);

  /// Accepts either [FlagConfig] values or raw primitives (bool, String,
  /// int, double) which are auto-wrapped.
  static Map<String, FlagConfig> _normalise(Map<String, Object> raw) => {
        for (final e in raw.entries)
          e.key: e.value is FlagConfig
              ? e.value as FlagConfig
              : FlagConfig(defaultValue: e.value),
      };
}
