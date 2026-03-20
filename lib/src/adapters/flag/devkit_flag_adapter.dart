import '../../core/flags/flag_config.dart';

/// Implement to source feature flag default values from any backend
/// (Firebase Remote Config, LaunchDarkly, local JSON, etc.).
abstract class BlackBoxFlagAdapter {
  String get name;

  /// Called by BlackBox to get the registered flags and their defaults.
  Map<String, FlagConfig> get flags;

  void attach() {}
  void detach() {}
}
