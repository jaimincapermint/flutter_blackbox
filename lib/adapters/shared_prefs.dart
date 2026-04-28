/// SharedPreferences storage adapter for BlackBox.
///
/// Requires `shared_preferences: ^2.5.0` in your pubspec.yaml.
///
/// ```dart
/// import 'package:flutter_blackbox/adapters/shared_prefs.dart';
///
/// BlackBox.setup(
///   storageAdapters: [SharedPrefsStorageAdapter()],
/// );
/// ```
library;

export 'package:flutter_blackbox/src/adapters/storage/shared_prefs_storage_adapter.dart';
